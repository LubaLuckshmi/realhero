import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:realhero/domain.dart';
import 'package:realhero/store.dart';
import 'package:realhero/leia_client.dart';

class MemoryStorage implements JsonStorage {
  final Map<String, String> values = {};
  bool fail = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw const FileSystemStorageException('disk full');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

void main() {
  test('question navigation survives restart without claiming a result or XP', () async {
    final disk = MemoryStorage();
    final store = RealHeroStore(storage: disk);
    await store.load();
    store.loadDemo();
    final mission = store.currentMission!;
    expect(mission.preparedQuestions, hasLength(3));
    store.beginMission();
    store.setQuestion(1);
    await store.flush();
    final reopened = RealHeroStore(storage: disk);
    await reopened.load();
    expect(reopened.currentMission!.currentQuestion, 1);
    expect(reopened.currentMission!.preparedQuestions[1], contains('непонятным'));
    expect(reopened.currentMission!.outcome, isNull);
    expect(reopened.currentMission!.actionConfirmed, false);
    expect(reopened.profile.xp, 0);
    reopened.editMaterial('questions', 'Один оставшийся вопрос?');
    expect(reopened.currentMission!.currentQuestion, 0);
    expect(reopened.currentMission!.preparedQuestions, ['Один оставшийся вопрос?']);
  });
  test(
    'declined demo mission can be replaced without changing its reason or awarding XP',
    () async {
      final disk = MemoryStorage();
      final store = RealHeroStore(storage: disk);
      await store.load();
      store.loadDemo();
      final previous = store.currentMission!;
      store.declineMission('Не хочу писать сейчас');
      final eventCount = previous.events.length;
      store.replaceDemoMission('Попробуем другой способ');
      await store.flush();
      expect(store.currentMission!.id, isNot(previous.id));
      expect(store.currentMission!.status, MissionStatus.prepared);
      expect(previous.status, MissionStatus.declined);
      expect(previous.declineReason, 'Не хочу писать сейчас');
      expect(previous.events.length, eventCount);
      expect(previous.outcome, null);
      expect(store.profile.xp, 0);
      expect(store.profile.completedCount, 0);
    },
  );
  test('demo preparation includes two available in-app prototype screens', () {
    final g = DemoScenario.goal();
    final first = DemoScenario.invitation(g.id);
    expect(
      first.materials.where((m) => m.kind == 'prototype').single.id,
      'prototype',
    );
    final next = DemoScenario.followup(
      g.id,
      OutcomeRecord(
        kind: OutcomeKind.positive,
        facts: 'Андрей согласился',
        actualMinutes: 2,
        difficulty: 2,
      ),
    );
    expect(
      next.materials.where((m) => m.kind == 'prototype').single.label,
      'Прототип · 2 экрана',
    );
  });
  test('stale response cannot change a newer goal', () async {
    final store = RealHeroStore(storage: MemoryStorage());
    await store.load();
    store.setGoal('Первая цель');
    final oldId = store.goal!.id;
    store.setGoal('Новая цель');
    expect(
      () => store.acceptPlan({
        'reply': 'Старый ответ',
        'goal': {'id': oldId, 'title': 'Первая цель'},
      }),
      throwsFormatException,
    );
    expect(store.goal!.title, 'Новая цель');
    expect(store.state.chat, isEmpty);
  });
  test('new goal reflections never rewrite previous goal results', () async {
    final disk = MemoryStorage();
    final store = RealHeroStore(storage: disk);
    await store.load();
    void prepare(String id) => store.acceptPlan({
      'reply': 'Подготовка готова',
      'mission': {
        'id': id,
        'goalId': store.goal!.id,
        'title': 'Первое действие',
        'why': 'Опирается на текущую цель',
        'minutes': 5,
        'oneAction': 'Выполнить подготовленное упражнение',
        'lightAction': 'Прочитать материал',
        'steps': [
          {'id': 'step', 'title': 'Прочитать'},
        ],
        'materials': [
          {
            'id': 'draft',
            'label': 'Материал',
            'text': 'Готовое упражнение',
            'kind': 'draft',
          },
        ],
      },
    });
    store.setGoal('Научиться рисовать');
    prepare('first-goal-mission');
    final first = store.completeMission(
      outcome: OutcomeKind.partial,
      facts: 'Сделан набросок',
      observations: 'Нужна практика перспективы',
    );
    final oldImpact = first.goalImpact;
    final oldDirection = first.nextDirection;
    expect(store.lastOutcome, same(first));

    store.setGoal('Освоить аккорды');
    expect(store.lastCompletedMission, isNull);
    expect(store.lastOutcome, isNull);
    store.acceptPlan({
      'reply': 'Уточним инструмент',
      'reflection': {
        'learned': 'Есть гитара',
        'goalImpact': 'Можно начать',
        'nextMove': 'Попробовать аккорд',
      },
    });
    expect(first.learned, 'Нужна практика перспективы');
    expect(first.goalImpact, oldImpact);
    expect(first.nextDirection, oldDirection);
    prepare('second-goal-mission');
    final second = store.completeMission(
      outcome: OutcomeKind.partial,
      facts: 'Попробовал первый аккорд',
      observations: 'Пальцы пока устают',
    );
    store.acceptPlan({
      'reply': 'Уменьшим нагрузку',
      'reflection': {
        'learned': 'Длинная попытка утомляет',
        'goalImpact': 'Получен первый опыт',
        'nextMove': 'Потренироваться 2 минуты',
      },
    });
    expect(store.lastOutcome, same(second));
    expect(second.nextDirection, 'Потренироваться 2 минуты');
    expect(first.learned, 'Нужна практика перспективы');
    expect(first.nextDirection, oldDirection);
    expect(store.history.length, 2);
    expect(store.profile.xp, 80);
    await store.flush();
    final reopened = RealHeroStore(storage: disk);
    await reopened.load();
    expect(reopened.lastOutcome!.facts, 'Попробовал первый аккорд');
    expect(
      reopened.state.missions.first.outcome!.learned,
      'Нужна практика перспективы',
    );
    expect(reopened.profile.xp, 80);
  });
  test(
    'fresh installation is personal onboarding, never an unlabelled demo',
    () async {
      final store = RealHeroStore(storage: MemoryStorage());
      await store.load();
      expect(store.isDemo, false);
      expect(store.currentMission, null);
      expect(store.profile.xp, 0);
    },
  );
  test(
    'restart restores edited material, current step, pause, note, goal and settings',
    () async {
      final disk = MemoryStorage();
      final first = RealHeroStore(storage: disk);
      await first.load();
      first.loadDemo();
      first.configureServer('https://example.test/', 'realhero-access-token');
      first.editMaterial('invitation', 'Исправленное приглашение');
      first.beginMission();
      first.setStep(1);
      first.saveNote('Проверить ответ вечером');
      first.pauseMission();
      await first.flush();
      final reopened = RealHeroStore(storage: disk);
      await reopened.load();
      expect(reopened.currentMission!.status, MissionStatus.paused);
      expect(reopened.currentMission!.currentStep, 1);
      expect(reopened.currentMission!.note, 'Проверить ответ вечером');
      expect(
        reopened.currentMission!.materials.first.text,
        'Исправленное приглашение',
      );
      expect(reopened.currentMission!.materials.first.edited, true);
      expect(reopened.goal!.id, 'demo_goal');
      expect(reopened.settings.url, 'https://example.test');
    },
  );
  test(
    'action with negative result gains attempt XP without inventing a life change',
    () async {
      final store = RealHeroStore(storage: MemoryStorage());
      await store.load();
      store.loadDemo();
      final id = store.currentMission!.id;
      store.beginMission();
      final out = store.completeMission(
        missionId: id,
        outcome: OutcomeKind.negative,
        facts: 'Андрей отказался: сейчас нет времени',
        actualMinutes: 4,
        difficulty: 5,
        observations: 'Для полноценного показа сейчас неудобный момент',
      );
      expect(out.kind, OutcomeKind.negative);
      expect(out.xpEarned, 40);
      expect(store.profile.completedCount, 1);
      expect(store.state.realChanges, isEmpty);
      expect(store.currentMission!.title, 'Сократи показ до одного вопроса');
      expect(store.currentMission!.contactNames, isEmpty);
      final again = store.completeMission(
        missionId: id,
        outcome: OutcomeKind.positive,
        facts: 'Повторный тап',
      );
      expect(identical(again, out), true);
      expect(store.profile.xp, 40);
      expect(store.state.missions.length, 2);
      await store.flush();
    },
  );
  test(
    'no action grants no XP, no completed count and no invented success',
    () async {
      final store = RealHeroStore(storage: MemoryStorage());
      await store.load();
      store.loadDemo();
      store.completeMission(
        outcome: OutcomeKind.unknown,
        facts: 'Не успел отправить',
        actualMinutes: 0,
        actionTaken: false,
      );
      expect(store.profile.xp, 0);
      expect(store.profile.completedCount, 0);
      expect(store.state.realChanges, isEmpty);
    },
  );
  test(
    'no reply proposes waiting rather than another immediate invitation',
    () async {
      final store = RealHeroStore(storage: MemoryStorage());
      await store.load();
      store.loadDemo();
      store.completeMission(
        outcome: OutcomeKind.noReply,
        facts: 'Приглашение отправлено, ответа пока нет',
        actualMinutes: 2,
      );
      expect(store.currentMission!.title, 'Оставь приглашению время');
      expect(store.currentMission!.oneAction, contains('время'));
      expect(store.lastOutcome!.goalImpact, contains('ни отказом, ни успехом'));
      expect(store.state.realChanges, isEmpty);
    },
  );
  test('defer and decline persist without penalties', () async {
    final disk = MemoryStorage();
    final store = RealHeroStore(storage: disk);
    await store.load();
    store.loadDemo();
    final date = DateTime.utc(2026, 10, 20);
    store.deferMission(date);
    await store.flush();
    final reopened = RealHeroStore(storage: disk);
    await reopened.load();
    expect(reopened.currentMission!.status, MissionStatus.deferred);
    expect(reopened.currentMission!.deferredUntil, date);
    reopened.declineMission('Этот способ не подходит');
    await reopened.flush();
    expect(reopened.profile.xp, 0);
    expect(reopened.history.first.declineReason, 'Этот способ не подходит');
  });
  test(
    'demo leaves personal goal and chat intact after restart and exit',
    () async {
      final disk = MemoryStorage();
      final store = RealHeroStore(storage: disk);
      await store.load();
      store.setGoal('Хочу научиться рисовать; есть 20 минут вечером');
      store.appendChat('user', 'Курсов пока не пробовал');
      store.loadDemo();
      await store.flush();
      final reopened = RealHeroStore(storage: disk);
      await reopened.load();
      reopened.exitDemo();
      await reopened.flush();
      expect(reopened.isDemo, false);
      expect(
        reopened.goal!.context,
        'Хочу научиться рисовать; есть 20 минут вечером',
      );
      expect(reopened.state.chat.single.text, 'Курсов пока не пробовал');
      expect(reopened.state.missions, isEmpty);
    },
  );
  test(
    'corrupt primary snapshot recovers complete secondary snapshot',
    () async {
      final disk = MemoryStorage();
      final store = RealHeroStore(storage: disk);
      await store.load();
      store.setGoal('Учить английский');
      await store.flush();
      disk.values[RealHeroStore.storageKey] = '{broken';
      final recovered = RealHeroStore(storage: disk);
      await recovered.load();
      expect(recovered.goal!.title, 'Учить английский');
      expect(recovered.recoveryMessage, contains('восстановлено'));
      expect(
        disk.values.keys.any((key) => key.startsWith('realhero.recovery.')),
        true,
      );
    },
  );
  test('save failure is visible and in-memory state survives retry', () async {
    final disk = MemoryStorage();
    final store = RealHeroStore(storage: disk);
    await store.load();
    disk.fail = true;
    store.setGoal('Освоить гитару');
    await store.flush();
    expect(store.persistenceError, isNotNull);
    expect(store.goal!.context, 'Освоить гитару');
    disk.fail = false;
    await store.retrySave();
    expect(store.persistenceError, null);
    final reopened = RealHeroStore(storage: disk);
    await reopened.load();
    expect(reopened.goal!.title, 'Освоить гитару');
  });
  test(
    'incomplete server mission cannot replace prepared user materials',
    () async {
      final store = RealHeroStore(storage: MemoryStorage());
      await store.load();
      store.setGoal('Написать рассказ');
      final id = store.goal!.id;
      store.acceptPlan({
        'reply': 'Подготовлен первый шаг',
        'mission': {
          'id': 'm1',
          'goalId': id,
          'title': 'Прочитай начало',
          'why': 'Проверим тон',
          'minutes': 5,
          'oneAction': 'Прочитай готовый абзац и исправь одну фразу',
          'lightAction': 'Прочитай одно предложение',
          'steps': [
            {'id': 's1', 'title': 'Прочитать'},
          ],
          'materials': [
            {
              'id': 'draft',
              'label': 'Начало',
              'text': 'Готовый первый абзац',
              'kind': 'draft',
            },
          ],
        },
      });
      final original = store.currentMission;
      expect(
        () => store.acceptPlan({
          'reply': 'Не будет добавлено',
          'mission': {'id': 'm2', 'goalId': id, 'title': 'Пустая'},
        }),
        throwsFormatException,
      );
      expect(identical(store.currentMission, original), true);
      expect(store.state.chat.length, 1);
    },
  );
  test(
    'context correction clears assumptions and remains user editable',
    () async {
      final store = RealHeroStore(storage: MemoryStorage());
      await store.load();
      store.setGoal('Публичное выступление');
      store.state.assumptions.add('Возможно, предпочитаешь письменное общение');
      store.updateContext('Предпочитаю устную репетицию; есть 15 минут');
      await store.flush();
      expect(store.state.assumptions, isEmpty);
      expect(store.goal!.context, contains('устную репетицию'));
      expect(store.state.contextUpdates.last['source'], 'user_correction');
    },
  );
  test('tolerant JSON roundtrip keeps result and material edits', () {
    final goal = DemoScenario.goal();
    final m = DemoScenario.invitation(goal.id);
    m.materials.first.text = 'Новый текст';
    m.status = MissionStatus.paused;
    final state = AppState(
      goal: goal,
      missions: [m],
      currentMissionId: m.id,
      isDemo: true,
    );
    final copy = AppState.fromJson(jsonDecode(jsonEncode(state.toJson())));
    expect(copy.currentMission!.status, MissionStatus.paused);
    expect(copy.currentMission!.materials.first.edited, true);
    expect(Mission.fromJson({'minutes': 'bad', 'steps': []}).minutes, 10);
  });
  test(
    'client strips settings from body and never accepts OpenAI key in app',
    () async {
      final state = AppState(
        goal: Goal(id: 'g', title: 'Гитара', context: 'Есть 10 минут'),
        settings: ServerSettings(
          url: 'https://example.test',
          accessToken: 'access-secret',
        ),
      );
      String sent = '';
      final client = LeiaClient(
        transport: (uri, headers, body) async {
          sent = body;
          expect(uri.path, '/v1/leia');
          expect(headers['authorization'], 'Bearer access-secret');
          return const LeiaHttpResponse(
            200,
            '{"reply":"Уточни, есть ли инструмент","mission":null,"needsClarification":true}',
          );
        },
      );
      final response = await client.respond(
        state: state,
        message: 'Хочу научиться играть',
      );
      expect(response['needsClarification'], true);
      expect(sent, isNot(contains('access-secret')));
      expect(sent, isNot(contains('settings')));
      state.settings.accessToken = 'sk-proj-forbidden';
      expect(
        () => client.respond(state: state, message: 'Привет'),
        throwsA(
          isA<LeiaException>().having((e) => e.code, 'code', 'invalid_token'),
        ),
      );
    },
  );
  test(
    'server failure preserves personal inputs and never falls back to demo',
    () async {
      final state = AppState(
        goal: Goal(id: 'g', title: 'Рисование', context: '20 минут вечером'),
        settings: ServerSettings(
          url: 'https://example.test',
          accessToken: 'access-token',
        ),
      );
      final client = LeiaClient(
        transport: (uri, headers, body) async => const LeiaHttpResponse(
          503,
          '{"error":{"code":"budget_not_approved"}}',
        ),
      );
      await expectLater(
        client.respond(state: state, message: 'Подготовь действие'),
        throwsA(
          isA<LeiaException>().having(
            (e) => e.code,
            'code',
            'budget_not_approved',
          ),
        ),
      );
      expect(state.goal!.context, '20 минут вечером');
      expect(state.isDemo, false);
      expect(state.missions, isEmpty);
    },
  );
  test('personal result remains recorded when next plan fails', () async {
    final store = RealHeroStore(storage: MemoryStorage());
    await store.load();
    store.setGoal('Рассказ');
    store.acceptPlan({
      'reply': 'Готово',
      'mission': {
        'id': 'write',
        'goalId': store.goal!.id,
        'title': 'Прочитай сцену',
        'why': 'Проверим тон',
        'minutes': 5,
        'oneAction': 'Отредактируй одну фразу',
        'lightAction': 'Прочитай вслух',
        'steps': [
          {'id': 'read', 'title': 'Прочитать'},
        ],
        'materials': [
          {
            'id': 'draft',
            'label': 'Сцена',
            'text': 'Утром дверь была открыта.',
            'kind': 'draft',
          },
        ],
      },
    });
    store.beginMission();
    store.completeMission(
      outcome: OutcomeKind.partial,
      facts: 'Исправил начало',
      observations: 'Слишком длинные предложения',
    );
    await store.flush();
    expect(store.requiresNextMission, true);
    expect(store.lastOutcome!.observations, 'Слишком длинные предложения');
    expect(store.state.missions.length, 1);
    expect(store.isDemo, false);
    expect(store.profile.xp, 40);
  });
}
