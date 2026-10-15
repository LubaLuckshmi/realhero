import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:realhero/domain.dart';
import 'package:realhero/leia_client.dart';
import 'package:realhero/store.dart';

class _Disk implements JsonStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}

void main() {
  late Process server;
  late String serverUrl;
  late String accessToken;
  setUpAll(() async {
    server = await Process.start('node', ['test/support/leia_mock_server.mjs']);
    // Fixtures use only fictional data and a clearly non-secret test token.
    final first = await server.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first
        .timeout(const Duration(seconds: 10));
    final config = jsonDecode(first) as Map<String, dynamic>;
    serverUrl = 'http://127.0.0.1:${config['port']}';
    accessToken = config['accessToken'] as String;
    server.stderr.transform(utf8.decoder).listen((text) {
      if (text.trim().isNotEmpty) fail('Offline fixture failed: $text');
    });
  });
  tearDownAll(() async {
    server.kill(ProcessSignal.sigterm);
    await server.exitCode.timeout(const Duration(seconds: 5));
  });

  for (final noReply in [false, true]) {
    test(
      'native HTTP goal→preparation→result→next move restores ${noReply ? 'no reply' : 'creative attempt'}',
      () async {
        final disk = _Disk();
        final store = RealHeroStore(storage: disk);
        await store.load();
        store.configureServer(serverUrl, accessToken);
        final goal = noReply
            ? 'Хочу чаще общаться с друзьями. Подруга Ирина предложила как-нибудь погулять. Есть 10 минут, чтобы написать приглашение.'
            : 'Хочу научиться рисовать город. Есть бумага, карандаш и 10 минут. Пока не пробовал рисовать перспективу.';
        store.setGoal(goal);
        store.appendChat('user', goal);
        final client = LeiaClient();
        store.acceptPlan(
          await client.respond(
            state: store.state,
            message: goal,
            operation: 'onboard',
          ),
        );
        final first = store.currentMission!;
        expect(first.status, MissionStatus.prepared);
        expect(first.materials.first.text, isNotEmpty);
        expect(first.evidence, contains(goal));
        expect(store.isDemo, false);
        final edited =
            '${first.materials.first.text}\nМоя пометка: сделать вечером.';
        store.editMaterial(first.materials.first.id, edited);
        store.beginMission();
        store.saveNote('Действие выполнено вечером.');
        final facts = noReply
            ? 'Приглашение Ирине отправлено вчера, ответа пока нет.'
            : 'Сделал первый набросок за 6 минут. Линии домов пока не сходятся в одной точке.';
        store.completeMission(
          outcome: noReply ? OutcomeKind.noReply : OutcomeKind.partial,
          facts: facts,
          actualMinutes: 6,
          difficulty: 4,
          actionTaken: true,
        );
        final result = store.lastOutcome!;
        expect(store.requiresNextMission, true);
        expect(store.profile.xp, 40);
        expect(result.facts, facts);
        // A provider failure must leave saved action/result available.
        await expectLater(
          client.respond(
            state: store.state,
            message: 'Проверь ошибку сервера',
            operation: 'adapt',
          ),
          throwsA(isA<LeiaException>()),
        );
        expect(store.lastOutcome, same(result));
        expect(store.state.missions.length, 1);
        final continuation = 'Учти результат и подготовь следующий ход.';
        store.appendChat('user', continuation);
        store.acceptPlan(
          await client.respond(
            state: store.state,
            message: continuation,
            operation: 'adapt',
          ),
        );
        expect(store.currentMission!.id, isNot(first.id));
        expect(store.currentMission!.goalId, store.goal!.id);
        expect(
          result.nextMove,
          contains(noReply ? 'Дать приглашению время' : 'одной точки схода'),
        );
        if (noReply) {
          expect(store.state.realChanges, isEmpty);
          expect(store.currentMission!.contactNames, isEmpty);
          expect(
            store.currentMission!.materials.first.text,
            contains('не отправляй его повторно'),
          );
        }
        await store.flush();
        final reopened = RealHeroStore(storage: disk);
        await reopened.load();
        expect(reopened.currentMission!.id, store.currentMission!.id);
        expect(
          reopened.currentMission!.materials.first.text,
          store.currentMission!.materials.first.text,
        );
        expect(reopened.state.missions.first.materials.first.text, edited);
        expect(reopened.lastOutcome!.facts, facts);
        expect(reopened.lastOutcome!.nextMove, result.nextMove);
        expect(reopened.lastOutcome!.actualMinutes, 6);
        expect(reopened.lastOutcome!.difficulty, 4);
        expect(reopened.profile.xp, 40);
        expect(reopened.settings.url, serverUrl);
      },
    );
  }
}
