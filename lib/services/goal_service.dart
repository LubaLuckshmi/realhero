/// goal_service.dart — Firestore: цели пользователя в users/{uid}/goals
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';

class GoalService {
  CollectionReference<Map<String, dynamic>> _userGoals(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('goals');

  Future<List<Goal>> fetchGoals(String uid) async {
    final snap = await _userGoals(uid).orderBy('title').get();
    return snap.docs.map((d) => Goal.fromMap(d.data(), d.id)).toList();
  }

  Future<void> addGoal(String uid, String title) async {
    await _userGoals(uid).add({'title': title, 'isCompleted': false});
  }

  Future<void> toggle(String uid, String id, bool newValue) async {
    await _userGoals(uid).doc(id).update({'isCompleted': newValue});
  }

  Future<void> remove(String uid, String id) async {
    await _userGoals(uid).doc(id).delete();
  }

  Future<void> addMany(String uid, List<String> titles) async {
    final batch = FirebaseFirestore.instance.batch();
    final col = _userGoals(uid);
    for (final t in titles) {
      batch.set(col.doc(), {'title': t, 'isCompleted': false});
    }
    await batch.commit();
  }
}
