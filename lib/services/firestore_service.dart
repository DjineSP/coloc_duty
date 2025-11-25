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
    if (storedColocId == null) return false;

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
            'role': 'admin',
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
      final now = DateTime.now();

      final snapshot = await _db
          .collection('colocations')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final currentMembers = List.from(doc.data()['members'] ?? []);

      // Si déjà membre, on renvoie l'ID et c'est tout
      if (currentMembers.any((m) => m['uid'] == user.uid)) {
        await PreferencesService.saveCurrentColocId(doc.id);
        return doc.id;
      }

      // Génération nom par défaut (ex: Colocataire 4)
      final newCount = (doc.data()['memberCount'] as int? ?? currentMembers.length) + 1;
      final defaultName = "Colocataire $newCount";

      final newMember = {
        'uid': user.uid,
        'displayName': defaultName,
        'photoUrl': null,
        'joinedAt': now.toIso8601String(),
        'role': 'member',
      };

      // Mise à jour transactionnelle (optimiste ici via arrayUnion)
      await doc.reference.update({
        'members': FieldValue.arrayUnion([newMember]),
        'memberCount': FieldValue.increment(1),
      });

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

        // Trouver l'index du user
        final index = members.indexWhere((m) => m['uid'] == user.uid);
        if (index == -1) throw Exception("User not in list");

        // Mise à jour des champs
        members[index]['displayName'] = displayName;
        members[index]['photoUrl'] = avatarPath;

        transaction.update(docRef, {'members': members});
        return true;
      });
    } catch (e) {
      print("Erreur update profile: $e");
      return false;
    }
  }

  static Future<String?> getCurrentColocId() => PreferencesService.getCurrentColocId();
}