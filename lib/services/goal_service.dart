import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';

/// Работа с целями в Firestore: users/{uid}/goals
class GoalService {
  CollectionReference<Map<String, dynamic>> _userGoals(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('goals');

  Future<List<Goal>> fetchGoals(String uid) async {
    final snap = await _userGoals(uid).orderBy('title').get();
    return snap.docs
        .map(
          (d) => Goal.fromJson({
            ...d.data(),
            'id': d.id, // важно: подставляем id документа
          }),
        )
        .toList();
  }

  /// Добавить цель целиком (предпочтительно).
  Future<void> addGoal(String uid, Goal goal) async {
    await _userGoals(uid).doc(goal.id).set(goal.toJson());
  }

  /// Упростённый метод — если нужно быстро создать черновик.
  Future<String> addGoalTitle(
    String uid,
    String title, {
    String category = 'Без категории',
  }) async {
    final ref = await _userGoals(uid).add({
      'category': category,
      'title': title,
      'firstStep': null,
      'progress': 0.0,
      'isCompleted': false,
    });
    return ref.id;
  }

  Future<void> updateGoal(String uid, Goal goal) async {
    await _userGoals(uid).doc(goal.id).update(goal.toJson());
  }

  Future<void> removeGoal(String uid, String goalId) async {
    await _userGoals(uid).doc(goalId).delete();
  }
}
