import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';

/// Ключ в SharedPreferences
const _kGoalsKey = 'goals_v1';

/// Простой локальный репозиторий целей.
class GoalRepositoryLocal {
  GoalRepositoryLocal._();
  static final instance = GoalRepositoryLocal._();

  Future<List<Goal>> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_kGoalsKey) ?? <String>[];
    return raw
        .map((e) => Goal.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(Goal g) async {
    final list = await load();
    final idx = list.indexWhere((e) => e.id == g.id);
    if (idx >= 0) {
      list[idx] = g;
    } else {
      list.add(g);
    }
    await _persist(list);
  }

  Future<void> remove(String id) async {
    final list = await load();
    list.removeWhere((e) => e.id == id);
    await _persist(list);
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kGoalsKey);
  }

  Future<void> _persist(List<Goal> list) async {
    final sp = await SharedPreferences.getInstance();
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await sp.setStringList(_kGoalsKey, raw);
  }
}
