import 'dart:convert';

import 'domain.dart';

/// A local file only. Never sent to Leia or to an analytics service.
class RealHeroBackup {
  final AppState state;
  final AppState? personalState;
  RealHeroBackup(this.state, this.personalState);

  String get snapshot => jsonEncode({
    ...state.toJson(),
    'personalSnapshot': personalState?.toJson(),
  });

  String encode() => jsonEncode({
    'format': 'realhero.backup',
    'version': 1,
    'snapshot': jsonDecode(snapshot),
  });

  static AppState _state(dynamic value) {
    if (value is! Map<String, dynamic> ||
        value['version'] != 1 ||
        value['missions'] is! List ||
        value['goals'] is! List ||
        value['chat'] is! List ||
        value['profile'] is! Map) {
      throw const FormatException('Это не сохранение RealHero.');
    }
    return AppState.fromJson(value);
  }

  factory RealHeroBackup.decode(String text) {
    if (utf8.encode(text).length > 16 * 1024 * 1024) {
      throw const FormatException('Файл сохранения слишком большой.');
    }
    final root = jsonDecode(text);
    if (root is! Map<String, dynamic> ||
        root['format'] != 'realhero.backup' || root['version'] != 1) {
      throw const FormatException('Это не сохранение RealHero.');
    }
    dynamic snapshot = root['snapshot'];
    dynamic personal;
    // Native Android import can read the original SharedPreferences XML.
    if (root['preferences'] is Map) {
      final preferences = root['preferences'] as Map;
      dynamic decoded(String key) {
        final raw = preferences[key];
        if (raw is! String) return null;
        return jsonDecode(raw);
      }
      try {
        snapshot = decoded('flutter.realhero.snapshot.v1');
        _state(snapshot);
      } catch (_) {
        snapshot = decoded('flutter.realhero.snapshot.backup.v1');
      }
      if (snapshot is Map && !snapshot.containsKey('personalSnapshot')) {
        personal = decoded('flutter.realhero.personal.v1');
      }
    }
    final state = _state(snapshot);
    if (snapshot.containsKey('personalSnapshot')) {
      personal = snapshot['personalSnapshot'];
    }
    return RealHeroBackup(state, personal == null ? null : _state(personal));
  }
}
