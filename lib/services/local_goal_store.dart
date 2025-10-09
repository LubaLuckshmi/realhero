// lib/services/local_goal_store.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/goal.dart';

/// Локальное хранилище целей в SharedPreferences.
/// Храним список целей как JSON-массив.
class LocalGoalStore {
  static const _key = 'goals_v1';

  Future<List<Goal>> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null || raw.isEmpty) return <Goal>[];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(Goal.fromJson).toList();
    } catch (_) {
      return <Goal>[];
    }
  }

  /// Перезаписывает весь список.
  Future<void> save(List<Goal> goals) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(goals.map((g) => g.toJson()).toList());
    await sp.setString(_key, raw);
  }

  /// Добавляет одну цель (читает → добавляет → сохраняет).
  Future<void> add(Goal g) async {
    final items = await load();
    items.add(g);
    await save(items);
  }

  /// Удаляет цель по id.
  Future<void> remove(String id) async {
    final items = await load();
    items.removeWhere((e) => e.id == id);
    await save(items);
  }
}
