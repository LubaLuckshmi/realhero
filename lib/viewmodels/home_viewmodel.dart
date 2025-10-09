// lib/viewmodels/home_viewmodel.dart
import 'package:flutter/foundation.dart';

import '../models/goal.dart';
import '../services/local_goal_store.dart';

class HomeViewModel extends ChangeNotifier {
  final LocalGoalStore _local = LocalGoalStore();

  List<Goal> _items = <Goal>[];
  List<Goal> get items => _items;

  /// Загрузка из локального хранилища
  Future<void> load() async {
    _items = await _local.load();
    notifyListeners();
  }

  /// Базовое добавление цели
  Future<void> add({
    required String title,
    String? category,
    String? firstStep,
  }) async {
    final goal = Goal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: (category ?? '').trim(),
      title: title.trim(),
      firstStep: firstStep?.trim(),
      progress: 0.0,
    );
    await _local.add(goal);
    await load(); // перечитали и уведомили UI
  }

  /// Используется экранами «Подсказка цели» и «Своя цель»
  Future<void> addManualGoal({
    required String title,
    String? category,
    String? firstStep,
  }) async {
    await add(title: title, category: category, firstStep: firstStep);
  }

  /// Обновление прогресса по одной цели
  Future<void> setProgress(Goal g, double value) async {
    final idx = _items.indexWhere((e) => e.id == g.id);
    if (idx == -1) return;
    final clamped = value.clamp(0.0, 1.0);
    _items[idx] = Goal(
      id: g.id,
      category: g.category,
      title: g.title,
      firstStep: g.firstStep,
      progress: clamped,
    );
    await _local.save(_items);
    notifyListeners();
  }

  /// Удаление цели
  Future<void> remove(Goal g) async {
    _items.removeWhere((e) => e.id == g.id);
    await _local.save(_items);
    notifyListeners();
  }

  /// Удобный геттер для прогресс-бара на Home
  double get totalProgress {
    if (_items.isEmpty) return 0.0;
    final sum = _items.fold<double>(0.0, (acc, e) => acc + (e.progress));
    return (sum / _items.length).clamp(0.0, 1.0);
  }
}
