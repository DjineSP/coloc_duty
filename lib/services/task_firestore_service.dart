import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/local/preferences_service.dart';

class TaskFirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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
}
