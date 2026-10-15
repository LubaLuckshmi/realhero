import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realhero/backup.dart';
import 'package:realhero/domain.dart';
import 'package:realhero/store.dart';

class BackupDisk implements JsonStorage {
  final values = <String, String>{};
  bool fail = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw const FileSystemStorageException('disk full');
    values[key] = value;
  }
  @override
  Future<void> remove(String key) async => values.remove(key);
}

void main() {
  test('legacy preferences restore demo, personal history and server settings after restart', () async {
    final personal = AppState();
    personal.goal = Goal(id: 'personal', title: 'Учиться рисовать', context: 'Бумага и карандаш');
    personal.goals.add(personal.goal!);
    personal.chat.add(ChatMessage(role: 'user', text: 'Хочу попробовать рисунок'));
    personal.settings.url = 'https://example.invalid';
    personal.settings.accessToken = 'fixture-not-a-secret';
    final demo = AppState(isDemo: true, settings: personal.settings);
    final raw = jsonEncode({
      'format': 'realhero.backup', 'version': 1,
      'preferences': {
        'flutter.realhero.snapshot.v1': jsonEncode(demo.toJson()),
        'flutter.realhero.personal.v1': jsonEncode(personal.toJson()),
      },
    });
    final disk = BackupDisk();
    final store = RealHeroStore(storage: disk);
    await store.load();
    await store.restoreBackup(RealHeroBackup.decode(raw));
    final reopened = RealHeroStore(storage: disk);
    await reopened.load();
    expect(reopened.isDemo, true);
    reopened.exitDemo();
    await reopened.flush();
    expect(reopened.goal!.title, 'Учиться рисовать');
    expect(reopened.state.chat.single.text, 'Хочу попробовать рисунок');
    expect(reopened.settings.accessToken, 'fixture-not-a-secret');
    expect(reopened.settings.url, 'https://example.invalid');
    final copied = RealHeroBackup.decode(reopened.exportBackup());
    expect(copied.state.toJson(), reopened.state.toJson());
    expect(copied.personalState, isNull);
  });

  test('corrupt primary legacy preference uses complete backup', () {
    final state = AppState();
    final backup = RealHeroBackup.decode(jsonEncode({
      'format': 'realhero.backup', 'version': 1,
      'preferences': {
        'flutter.realhero.snapshot.v1': '{broken',
        'flutter.realhero.snapshot.backup.v1': jsonEncode(state.toJson()),
      },
    }));
    expect(backup.state.toJson(), state.toJson());
  });

  test('failed import cannot replace the existing history', () async {
    final disk = BackupDisk();
    final store = RealHeroStore(storage: disk);
    await store.load();
    store.setGoal('Существующая цель');
    await store.flush();
    final saved = disk.values[RealHeroStore.storageKey];
    disk.fail = true;
    await expectLater(store.restoreBackup(RealHeroBackup(AppState(), null)), throwsA(isA<FileSystemStorageException>()));
    expect(store.goal!.title, 'Существующая цель');
    expect(disk.values[RealHeroStore.storageKey], saved);
  });

  test('unrelated and future backup files are rejected', () {
    for (final raw in ['{}', '{broken', '{"format":"realhero.backup","version":2}',
      '{"format":"realhero.backup","version":1,"snapshot":{"hello":"world"}}']) {
      expect(() => RealHeroBackup.decode(raw), throwsFormatException);
    }
  });
}
