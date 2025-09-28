/// local_goal_store.dart — локальное хранение целей до авторизации (SharedPreferences)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalGoal {
  final String id;
  final String title;
  final bool isCompleted;

  LocalGoal({required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'isCompleted': isCompleted};
  factory LocalGoal.fromMap(Map<String, dynamic> m) => LocalGoal(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        isCompleted: m['isCompleted'] as bool? ?? false,
      );
}

class LocalGoalStore {
  static const _key = 'local_goals';

  Future<List<LocalGoal>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(LocalGoal.fromMap).toList();
  }

  Future<void> _save(List<LocalGoal> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toMap()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> add(String title) async {
    final items = await load();
    items.add(LocalGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    ));
    await _save(items);
  }

  Future<void> toggle(String id) async {
    final items = await load();
    final idx = items.indexWhere((e) => e.id == id);
    if (idx != -1) items[idx] = LocalGoal(id: items[idx].id, title: items[idx].title, isCompleted: !items[idx].isCompleted);
    await _save(items);
  }

  Future<void> remove(String id) async {
    final items = await load();
    items.removeWhere((e) => e.id == id);
    await _save(items);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
