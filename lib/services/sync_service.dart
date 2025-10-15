import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'local_goal_store.dart';

class SyncService {
  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _local = LocalGoalStore();

  /// Отправляем локальные цели пользователя в облако.
  /// Структура: users/{uid}/goals/{goalId}
  Future<void> pushLocalToCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final items = await _local.load();
    final col = _fs.collection('users').doc(user.uid).collection('goals');

    // батчи по 400 чтобы не упёрться в лимит 500
    const chunk = 400;
    for (var i = 0; i < items.length; i += chunk) {
      final slice = items.sublist(
        i,
        i + chunk > items.length ? items.length : i + chunk,
      );
      final batch = _fs.batch();
      for (final g in slice) {
        batch.set(col.doc(g.id), g.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
    }
  }
}
