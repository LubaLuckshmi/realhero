import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_event.dart';
import '../models/user_xp.dart';

class XpService {
  static const _kEvents = 'xp_events_v1';

  Future<List<ProgressEvent>> loadEvents() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_kEvents) ?? const [];
    return raw
        .map(
          (s) => ProgressEvent.fromJson(jsonDecode(s) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
  }

  Future<void> addEvent(ProgressEvent e) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_kEvents) ?? <String>[];
    raw.add(jsonEncode(e.toJson()));
    await sp.setStringList(_kEvents, raw);
  }

  Future<UserXp> loadUserXp() async {
    final events = await loadEvents();
    final total = events.fold<int>(0, (sum, e) => sum + e.xp);
    return UserXp.fromXp(total);
  }
}
