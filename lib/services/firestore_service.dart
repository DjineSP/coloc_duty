// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/code_generator.dart';
import '../../data/local/preferences_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Vérifie si l'utilisateur courant est bien dans la coloc stockée localement
  static Future<bool> verifyUserColocAccess() async {
    final storedColocId = await PreferencesService.getCurrentColocId();
    if (storedColocId == null || storedColocId.isEmpty) return false;

    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _db.collection('colocations').doc(storedColocId).get();
      if (!doc.exists) return false;

      final members = List.from(doc.data()?['members'] ?? []);
      final isMember = members.any((m) => m['uid'] == user.uid);

      return isMember;
    } catch (e) {
      return false;
    }
  }

  /// CRÉATION DE COLOCATION
  /// On ne demande pas encore le pseudo ici, on met "Admin" temporairement.
  static Future<String?> createColocation(String name) async {
    try {
      if (_auth.currentUser == null) await _auth.signInAnonymously();
      final user = _auth.currentUser!;

      final inviteCode = CodeGenerator.generateInviteCode();
      final now = DateTime.now();

      final ref = await _db.collection('colocations').add({
        'name': name.trim(),
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
        'members': [
          {
            'uid': user.uid,
            'displayName': "Admin", // Sera modifié à l'étape suivante
            'photoUrl': null,
            'joinedAt': now.toIso8601String(), // Plus sûr de stocker en String ISO pour parsing facile
            'active': true,
          }
        ],
      });

      await PreferencesService.saveCurrentColocId(ref.id);
      return ref.id;
    } catch (e) {
      print("Erreur création: $e");
      return null;
    }
  }

  /// REJOINDRE UNE COLOCATION
  /// Génère un nom par défaut "Colocataire N"
  static Future<String?> joinColocation(String inviteCode) async {
    try {
      if (_auth.currentUser == null) await _auth.signInAnonymously();
      final user = _auth.currentUser!;
      final code = inviteCode.trim().toUpperCase();

      final snapshot = await _db
          .collection('colocations')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      await PreferencesService.saveCurrentColocId(doc.id);
      return doc.id;
    } catch (e) {
      print("Erreur join: $e");
      return null;
    }
  }

  /// MISE À JOUR DU PROFIL (Appelé après Create ou Join)
  static Future<bool> updateUserProfile(String colocId, String displayName, String avatarPath) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final docRef = _db.collection('colocations').doc(colocId);

      // On doit lire, modifier le tableau localement, et réécrire.
      // Firestore ne permet pas de modifier un champ spécifique d'un objet dans un array facilement.
      return _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("Coloc not found");

        List<dynamic> members = List.from(snapshot.data()?['members'] ?? []);

        // 1) On cherche un membre par pseudo (displayName), insensible à la casse
        final normalizedNewName = displayName.trim().toLowerCase();
        int indexByName = members.indexWhere((m) {
          final existingName = (m['displayName'] ?? '').toString().trim().toLowerCase();
          return existingName == normalizedNewName;
        });

        // 2) Si trouvé → reconnexion : on garde ses infos, on ne fait que rattacher uid + active
        if (indexByName != -1) {
          members[indexByName]['uid'] = user.uid;
          members[indexByName]['active'] = true;
        }
        // 3) Si aucun membre ne correspond → on crée un nouveau membre
        else {
          final now = DateTime.now().toIso8601String();
          members.add({
            'uid': user.uid,
            'displayName': displayName,
            'photoUrl': avatarPath,
            'joinedAt': now,
            'active': true,
          });
        }

        transaction.update(docRef, {'members': members});
        return true;
      });
    } catch (e) {
      print("Erreur update profile: $e");
      return false;
    }
  }

  static Future<String?> getCurrentColocId() => PreferencesService.getCurrentColocId();

  static Future<bool> setCurrentMemberActive(bool isActive) async {
    final colocId = await PreferencesService.getCurrentColocId();
    if (colocId == null || colocId.isEmpty) return false;

    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final docRef = _db.collection('colocations').doc(colocId);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        List<dynamic> members = List.from(snapshot.data()?['members'] ?? []);
        final index = members.indexWhere((m) => m['uid'] == user.uid);
        if (index == -1) return;

        members[index]['active'] = isActive;
        transaction.update(docRef, {'members': members});
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // === DÉFINITIONS DE TÂCHES POUR UNE COLOCATION ===

  static CollectionReference<Map<String, dynamic>>? _currentTaskDefinitionsCollection(String? colocId) {
    if (colocId == null || colocId.isEmpty) return null;
    return _db.collection('colocations').doc(colocId).collection('taskDefinitions');
  }

  static Future<String?> createTaskDefinition({
    required String title,
    String? description,
    String recurrence = 'hebdo',
    String? iconKey,
  }) async {
    final colocId = await PreferencesService.getCurrentColocId();
    final colRef = _currentTaskDefinitionsCollection(colocId);
    if (colRef == null) return null;

    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final now = FieldValue.serverTimestamp();
      final docRef = await colRef.add({
        'title': title.trim(),
        'description': description?.trim(),
        'recurrence': recurrence,
        'iconKey': iconKey,
        'createdAt': now,
        'createdByUid': user.uid,
        'modifiedAt': now,
        'modifiedByUid': user.uid,
      });
      return docRef.id;
    } catch (e) {
      print('Erreur createTaskDefinition: $e');
      return null;
    }
  }

  static Future<bool> updateTaskDefinition(
    String taskId, {
    String? title,
    String? description,
    String? recurrence,
    String? iconKey,
  }) async {
    final colocId = await PreferencesService.getCurrentColocId();
    final colRef = _currentTaskDefinitionsCollection(colocId);
    if (colRef == null) return false;

    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    final user = _auth.currentUser;
    if (user == null) return false;

    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title.trim();
    if (description != null) updates['description'] = description.trim();
    if (recurrence != null) updates['recurrence'] = recurrence;
    if (iconKey != null) updates['iconKey'] = iconKey;

    if (updates.isEmpty) return true;

    updates['modifiedAt'] = FieldValue.serverTimestamp();
    updates['modifiedByUid'] = user.uid;

    try {
      await colRef.doc(taskId).update(updates);
      return true;
    } catch (e) {
      print('Erreur updateTaskDefinition: $e');
      return false;
    }
  }

  static Future<bool> deleteTaskDefinition(String taskId) async {
    final colocId = await PreferencesService.getCurrentColocId();
    final colRef = _currentTaskDefinitionsCollection(colocId);
    if (colRef == null) return false;

    try {
      await colRef.doc(taskId).delete();
      return true;
    } catch (e) {
      print('Erreur deleteTaskDefinition: $e');
      return false;
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>? taskDefinitionsStream() {
    // Attention: cette méthode doit être appelée depuis un contexte où les prefs sont déjà prêtes.
    // Pour un usage dans l'UI, il est préférable de récupérer d'abord le colocId puis de construire le stream.
    return null;
  }
}