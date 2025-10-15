// lib/viewmodels/home_viewmodel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/goal.dart';
import '../services/local_goal_store.dart';

class HomeViewModel extends ChangeNotifier {
  final LocalGoalStore _local = LocalGoalStore();
  final Uuid _uuid = const Uuid();

  List<Goal> _items = <Goal>[];
  List<Goal> get items => _items;

  Timer? _saveDebounce; // для дебаунса

  /// Загрузка из локального хранилища
  Future<void> load() async {
    _items = await _local.load();
    notifyListeners();
    debugPrint(
      '[analytics] onboarding_done_or_open_home (items=${_items.length})',
    );
  }

  /// Базовое добавление цели
  Future<void> add({
    required String title,
    String? category,
    String? firstStep,
  }) async {
    final goal = Goal(
      id: _uuid.v4(),
      category: (category ?? '').trim(),
      title: title.trim(),
      firstStep: (firstStep ?? '').trim().isEmpty ? null : firstStep!.trim(),
      progress: 0.0,
      isCompleted: false,
    );
    _items = [..._items, goal];
    _scheduleSave(); // дебаунс-сохранение
    notifyListeners();
    debugPrint('[analytics] goal_added type=preset/custom? title="$title"');
  }

  /// Используется экранами «Подсказка цели» и «Своя цель»
  Future<void> addManualGoal({
    required String title,
    String? category,
    String? firstStep,
  }) => add(title: title, category: category, firstStep: firstStep);

  /// Обновление прогресса по одной цели + синхронизация с isCompleted
  Future<void> setProgress(Goal g, double value) async {
    final idx = _items.indexWhere((e) => e.id == g.id);
    if (idx == -1) return;
    final clamped = value.clamp(0.0, 1.0);
    _items[idx] = g.copyWith(progress: clamped, isCompleted: clamped >= 1.0);
    _scheduleSave(); // дебаунс-сохранение
    notifyListeners();
    debugPrint('[analytics] progress_changed id=${g.id} value=$clamped');
  }

  /// Удаление цели
  Future<void> remove(Goal g) async {
    _items.removeWhere((e) => e.id == g.id);
    _scheduleSave(); // дебаунс-сохранение
    notifyListeners();
    debugPrint('[analytics] goal_removed id=${g.id}');
  }

  /// Общий прогресс для верхнего ProgressBar
  double get totalProgress {
    if (_items.isEmpty) return 0.0;
    final sum = _items.fold<double>(0.0, (acc, e) => acc + (e.progress));
    return (sum / _items.length).clamp(0.0, 1.0);
  }

  /// Дебаунс-сохранение списка целей
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), () async {
      await _local.save(_items);
      debugPrint('[persist] LocalGoalStore.save(items=${_items.length})');
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    // финальный «быстрый» флаш без await — чтобы изменения не потерялись
    _local.save(_items);
    super.dispose();
  }
}
