import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domain.dart';
import 'discovery.dart';

abstract class JsonStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class PreferencesStorage implements JsonStorage {
  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();
  @override
  Future<String?> read(String key) async => (await _preferences).getString(key);
  @override
  Future<void> write(String key, String value) async {
    if (!await (await _preferences).setString(key, value)) {
      throw const FileSystemStorageException(
        'Не удалось сохранить данные на устройстве.',
      );
    }
  }

  @override
  Future<void> remove(String key) async {
    await (await _preferences).remove(key);
  }
}

class FileSystemStorageException implements Exception {
  final String message;
  const FileSystemStorageException(this.message);
  @override
  String toString() => message;
}

/// Every visible change is saved in sequence. A second complete snapshot is
/// available if an interrupted/corrupt local write damages the primary one.
class RealHeroStore extends ChangeNotifier {
  static const storageKey = 'realhero.snapshot.v1';
  static const backupKey = 'realhero.snapshot.backup.v1';
  static const personalKey = 'realhero.personal.v1';
  final JsonStorage storage;
  AppState state = AppState();
  AppState? _personalState;
  Future<void> _writes = Future.value();
  String? persistenceError;
  String? recoveryMessage;
  bool loaded = false;
  bool _disposed = false;
  RealHeroStore({JsonStorage? storage})
    : storage = storage ?? PreferencesStorage();
  Mission? get currentMission => state.currentMission;
  Goal? get goal => state.goal;
  HeroProfile get profile => state.profile;
  ServerSettings get settings => state.settings;
  bool get isDemo => state.isDemo;
  List<Mission> get history =>
      state.missions.where((m) => m.isClosed).toList().reversed.toList();
  bool get requiresNextMission => currentMission?.isClosed ?? false;
  Mission? get lastCompletedMission => state.missions
      .where((m) => m.goalId == goal?.id && m.outcome != null)
      .lastOrNull;
  OutcomeRecord? get lastOutcome => lastCompletedMission?.outcome;

  Future<void> load() async {
    if (loaded) return;
    String? raw;
    try {
      raw = await storage.read(storageKey);
      if (raw != null) state = AppState.fromJson(jsonDecode(raw));
    } catch (_) {
      try {
        final backup = await storage.read(backupKey);
        if (backup != null) {
          state = AppState.fromJson(jsonDecode(backup));
          recoveryMessage =
              'Состояние восстановлено из последней сохранённой копии.';
        } else {
          recoveryMessage =
              'Сохранённые данные повреждены. Повреждённая копия сохранена, можно начать новый путь.';
        }
        if (raw != null) {
          await storage.write(
            'realhero.recovery.${DateTime.now().millisecondsSinceEpoch}',
            raw,
          );
        }
      } catch (_) {
        persistenceError =
            'Не удалось прочитать сохранение. Проверь доступное место и перезапусти приложение.';
      }
    }
    try {
      final savedPersonal = await storage.read(personalKey);
      if (savedPersonal != null) {
        _personalState = AppState.fromJson(jsonDecode(savedPersonal));
      }
    } catch (_) {
      /* Primary scenario remains readable if the optional demo backup fails. */
    }
    loaded = true;
    _emit();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _changed() {
    final snapshot = jsonEncode(state.toJson());
    final personal = _personalState == null
        ? null
        : jsonEncode(_personalState!.toJson());
    _writes = _writes.then((_) async {
      try {
        if (personal != null) await storage.write(personalKey, personal);
        await storage.write(backupKey, snapshot);
        await storage.write(storageKey, snapshot);
        if (persistenceError != null) {
          persistenceError = null;
          _emit();
        }
      } catch (_) {
        persistenceError =
            'Изменения пока не сохранены. Проверь свободное место и попробуй сохранить снова.';
        _emit();
      }
    });
    _emit();
  }

  Future<void> flush() => _writes;
  Future<void> retrySave() async {
    _changed();
    await flush();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void loadDemo() {
    if (state.isDemo) return;
    _personalState = AppState.fromJson(state.toJson());
    final demoGoal = DemoScenario.goal();
    final mission = DemoScenario.invitation(demoGoal.id);
    state = AppState(
      goal: demoGoal,
      goals: [demoGoal],
      missions: [mission],
      currentMissionId: mission.id,
      settings: ServerSettings.fromJson(_personalState!.settings.toJson()),
      isDemo: true,
      understanding: DemoScenario.context,
      chat: [
        ChatMessage(
          role: 'assistant',
          text:
              'Это демосценарий. Андрей и два готовых экрана — условный контекст макета. Я подготовила приглашение, три вопроса и план показа. В своей цели я использую только твои факты.',
        ),
      ],
    );
    _changed();
  }

  void exitDemo() {
    if (!state.isDemo) return;
    final config = ServerSettings.fromJson(state.settings.toJson());
    state = _personalState ?? AppState();
    state.settings = config;
    state.isDemo = false;
    _personalState = null;
    _writes = _writes.then((_) async {
      try {
        await storage.remove(personalKey);
      } catch (_) {}
    });
    _changed();
  }

  void setGoal(String text, {String? context}) {
    final input = text.trim();
    if (input.isEmpty) throw ArgumentError('Расскажи, чего хочешь достичь.');
    if (state.isDemo) exitDemo();
    final g = Goal(
      id: newId('goal'),
      title: input.length > 140 ? '${input.substring(0, 137)}…' : input,
      context: context ?? input,
    );
    state.goal = g;
    state.goals.add(g);
    state.currentMissionId = null;
    state.understanding = '';
    state.assumptions.clear();
    state.chat.clear();
    state.discovery = DiscoveryState();
    state.needsClarification = false;
    state.quickReplies.clear();
    _changed();
  }

  void openGoalEntry() {
    if (state.isDemo) exitDemo();
    state.discovery = DiscoveryState(phase: DiscoveryPhase.entry);
    _changed();
  }

  void chooseKnownGoal() {
    state.discovery.phase = DiscoveryPhase.knownGoal;
    _changed();
  }

  void saveGoalDraft(String value) {
    state.discovery.goalText = value;
    _changed();
  }

  void startDiscovery({bool keepGoal = false}) {
    if (state.isDemo) exitDemo();
    final draft = state.discovery.goalText;
    state.discovery = DiscoveryState(
      phase: DiscoveryPhase.questions,
      goalText: keepGoal ? goal?.title ?? draft : draft,
      existingGoalId: keepGoal ? goal?.id : null,
    );
    _changed();
  }

  void answerDiscovery(DiscoveryAnswer answer) {
    state.discovery.answer(answer);
    _changed();
  }

  void chooseDiscoveryDirection(String? value) {
    if (state.discovery.phase != DiscoveryPhase.direction) return;
    state.discovery.direction = DiscoveryState.directions.contains(value) ? value! : '';
    state.discovery.phase = DiscoveryPhase.review;
    _changed();
  }

  void backInDiscovery() {
    state.discovery.back();
    _changed();
  }

  void pauseDiscovery() {
    state.discovery.paused = true;
    _changed();
  }

  void resumeDiscovery() {
    state.discovery.paused = false;
    _changed();
  }

  String finishDiscovery() {
    final discovery = state.discovery;
    if (discovery.phase != DiscoveryPhase.review) {
      throw StateError('Сначала проверь короткое знакомство.');
    }
    final brief = discovery.brief();
    if (discovery.existingGoalId != null && discovery.existingGoalId == goal?.id) {
      goal!.context = '${goal!.context}\n\n$brief';
    } else {
      setGoal(discovery.hasIdea ? discovery.goalText.trim() : 'Найти посильный следующий шаг', context: brief);
    }
    discovery.phase = DiscoveryPhase.idle;
    discovery.paused = false;
    state.discovery = discovery;
    _changed();
    return brief;
  }

  void updateGoal(String title) {
    if (goal == null) {
      setGoal(title);
      return;
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('Название цели не должно быть пустым.');
    }
    goal!.title = title.trim();
    _changed();
  }

  void updateContext(String context) {
    if (goal == null) throw StateError('Сначала добавь цель.');
    goal!.context = context.trim();
    state.understanding = context.trim();
    // Explicit user corrections supersede earlier assumptions.
    state.assumptions.clear();
    state.contextUpdates.add({
      'text': context.trim(),
      'sourceQuote': context.trim(),
      'source': 'user_correction',
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    _changed();
  }

  void dismissAssumption(String assumption) {
    state.assumptions.remove(assumption);
    _changed();
  }

  void updateProfile({String? name, String? avatar}) {
    if (name != null && name.trim().isNotEmpty) profile.name = name.trim();
    if (avatar != null && avatar.isNotEmpty) profile.avatar = avatar;
    _changed();
  }

  void configureServer(String url, String accessToken) {
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(cleanUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError(
        'Укажи адрес сервера, например https://realhero.example.com.',
      );
    }
    if (accessToken.trim().startsWith('sk-')) {
      throw ArgumentError(
        'Здесь нужен токен доступа RealHero. OpenAI API-ключ должен оставаться только на сервере.',
      );
    }
    state.settings = ServerSettings(
      url: cleanUrl,
      accessToken: accessToken.trim(),
    );
    _changed();
  }

  void appendChat(String role, String text) {
    if (text.trim().isEmpty) return;
    state.chat.add(ChatMessage(role: role, text: text.trim()));
    _changed();
  }

  Mission _openMission() {
    final m = currentMission;
    if (m == null) throw StateError('Сначала подготовь миссию.');
    if (m.isClosed) throw StateError('Эта миссия уже закрыта.');
    return m;
  }

  void beginMission() {
    final m = _openMission();
    m.status = MissionStatus.active;
    m.startedAt ??= DateTime.now().toUtc();
    m.deferredUntil = null;
    m.recordEvent('begin');
    _changed();
  }

  void pauseMission() {
    final m = _openMission();
    m.status = MissionStatus.paused;
    m.recordEvent('pause');
    _changed();
  }

  void resumeMission() => beginMission();
  void deferMission(DateTime until) {
    final m = _openMission();
    m.status = MissionStatus.deferred;
    m.deferredUntil = until.toUtc();
    m.recordEvent('defer', {'until': until.toUtc().toIso8601String()});
    _changed();
  }

  void declineMission([String reason = '']) {
    final m = _openMission();
    m.status = MissionStatus.declined;
    m.declineReason = reason.trim();
    m.recordEvent('decline', {'reason': reason.trim()});
    _changed();
  }

  void lightenMission() {
    final m = _openMission();
    if (m.isLight) return;
    if (m.lightAction.trim().isNotEmpty) m.oneAction = m.lightAction;
    m.minutes = (m.minutes / 2).ceil().clamp(1, 240);
    m.isLight = true;
    m.recordEvent('lighten', {'oneAction': m.oneAction, 'minutes': m.minutes});
    _changed();
  }

  void shrinkMission() => lightenMission();

  void demoChat(String text) {
    if (!isDemo) {
      throw StateError('Демонстрационные ответы доступны только в деморежиме.');
    }
    appendChat('user', text);
    final input = text.toLowerCase();
    if (['меньше', 'легче', 'сил', 'тяжело', 'уменьш'].any(input.contains) &&
        currentMission != null &&
        !currentMission!.isClosed) {
      lightenMission();
      appendChat(
        'assistant',
        'Демо · Уменьшила действие: ${currentMission!.oneAction} Готовые материалы остаются доступны.',
      );
    } else {
      appendChat(
        'assistant',
        'Демо · Подготовка уже доступна в миссии: готовый текст, вопросы и план действия. В этом режиме я показываю механику; персональное продолжение для твоей цели создаётся подключённым ИИ.',
      );
    }
  }

  void replaceDemoMission(String reason) {
    if (!isDemo) {
      throw StateError('Замена персональной миссии требует ответа Леи.');
    }
    final current = currentMission;
    if (current == null) {
      throw StateError('Сначала подготовь миссию.');
    }
    if (!current.isClosed) {
      current.status = MissionStatus.declined;
      current.declineReason = reason.trim();
      current.recordEvent('decline', {'reason': reason.trim()});
    }
    final next = DemoScenario.followup(
      current.goalId,
      OutcomeRecord(
        kind: OutcomeKind.unknown,
        facts: reason.trim().isEmpty
            ? 'Пользователь попросил другой способ.'
            : reason.trim(),
        actualMinutes: 0,
        difficulty: 3,
        actionTaken: false,
      ),
    );
    state.missions.add(next);
    state.currentMissionId = next.id;
    _changed();
  }

  void editMaterial(String id, String text) {
    final m = _openMission();
    final material = m.materials.where((e) => e.id == id).firstOrNull;
    if (material == null) throw ArgumentError('Материал не найден.');
    material.text = text;
    if (material.kind == 'questions') {
      final count = m.preparedQuestions.length;
      m.currentQuestion = count == 0 ? 0 : m.currentQuestion.clamp(0, count - 1);
    }
    m.recordEvent('material_edited', {'id': id, 'text': text});
    _changed();
  }

  void setStep(int step) {
    final m = _openMission();
    m.currentStep = m.steps.isEmpty ? 0 : step.clamp(0, m.steps.length - 1);
    m.recordEvent('step', {'index': m.currentStep});
    _changed();
  }

  void saveNote(String note) {
    final m = _openMission();
    m.note = note;
    _changed();
  }

  void setQuestion(int index) {
    final m = _openMission();
    final questions = m.preparedQuestions;
    if (questions.isEmpty) return;
    m.currentQuestion = index.clamp(0, questions.length - 1);
    m.recordEvent('question_focus', {'index': m.currentQuestion});
    _changed();
  }

  void confirmAction() {
    final m = _openMission();
    m.actionConfirmed = true;
    m.recordEvent('action_confirmed');
    _changed();
  }

  OutcomeRecord completeMission({
    String? missionId,
    required OutcomeKind outcome,
    required String facts,
    int? actualMinutes,
    int difficulty = 2,
    String observations = '',
    bool actionTaken = true,
  }) {
    final m = missionId == null
        ? currentMission
        : state.missions.where((m) => m.id == missionId).firstOrNull;
    if (m == null) throw StateError('Миссия не найдена.');
    // A repeated button tap/retry cannot award XP or create another next mission.
    if (m.outcome != null) return m.outcome!;
    if (m.status == MissionStatus.declined) {
      throw StateError('Отклонённую миссию нельзя завершить.');
    }
    if (facts.trim().isEmpty) {
      throw ArgumentError('Опиши, что произошло на самом деле.');
    }
    final minutes = (actualMinutes ?? m.minutes).clamp(0, 1440);
    final attempted = actionTaken || m.actionConfirmed;
    final xp = attempted ? 40 : 0;
    final result = OutcomeRecord(
      kind: outcome,
      facts: facts.trim(),
      actualMinutes: minutes,
      difficulty: difficulty.clamp(1, 5),
      observations: observations.trim(),
      xpEarned: xp,
      actionTaken: attempted,
      learned: observations.trim().isEmpty
          ? 'Вывод пока не зафиксирован. Добавь наблюдение, когда оно появится.'
          : observations.trim(),
      goalImpact: outcome == OutcomeKind.positive
          ? 'Зафиксирован результат действия. Его влияние на цель уточним по твоим фактам.'
          : outcome == OutcomeKind.noReply
          ? 'Ответа пока нет. Не считаем ожидание ни отказом, ни успехом.'
          : 'Получена информация для изменения следующего хода.',
      nextDirection: state.isDemo
          ? _demoNext(outcome, difficulty)
          : 'Лея подготовит следующий ход с учётом этого результата.',
    );
    m.status = MissionStatus.completed;
    m.outcome = result;
    m.recordEvent('complete', result.toJson());
    profile.xp += xp;
    if (attempted) {
      profile.completedCount++;
      if (!profile.abilities.contains(m.ability)) {
        profile.abilities.add(m.ability);
      }
      if (profile.completedCount == 1 &&
          !profile.achievements.contains('Первое действие')) {
        profile.achievements.add('Первое действие');
      }
      if (profile.completedCount == 2 &&
          !profile.achievements.contains('Смелость в действии')) {
        profile.achievements.add('Смелость в действии');
      }
      if (profile.completedCount == 3 &&
          !profile.achievements.contains('Фокус на цели')) {
        profile.achievements.add('Фокус на цели');
      }
      if (profile.completedCount == 5 &&
          !profile.achievements.contains('Пять реальных попыток')) {
        profile.achievements.add('Пять реальных попыток');
      }
      if (difficulty >= 4 && !profile.abilities.contains('Адаптация')) {
        profile.abilities.add('Адаптация');
      }
    }
    // A factual event is recorded, never a success percentage or invented impact.
    if (attempted &&
        [OutcomeKind.positive, OutcomeKind.partial].contains(outcome)) {
      state.realChanges.add(RealChange(text: facts.trim(), missionId: m.id));
    }
    if (state.isDemo) {
      final next = DemoScenario.followup(m.goalId, result);
      state.missions.add(next);
      state.currentMissionId = next.id;
    }
    _changed();
    return result;
  }

  String _demoNext(OutcomeKind kind, int difficulty) => switch (kind) {
    OutcomeKind.positive =>
      'Показать два экрана и собрать ответы на три подготовленных вопроса.',
    OutcomeKind.noReply =>
      'Выбрать удобное время вернуться к приглашению; не повторять его сразу.',
    _ =>
      difficulty >= 4
          ? 'Уменьшить проверку до одного экрана и одного вопроса.'
          : 'Уточнить гипотезу без выдуманного нового контакта.',
  };

  /// Server answers are applied only after a complete response has arrived.
  /// Errors never erase the goal, chat, materials or an already recorded result.
  void acceptPlan(Map<String, dynamic> response) {
    final missionJson = response['mission'];
    Mission? proposed;
    if (missionJson != null) {
      proposed = Mission.fromJson(missionJson);
      if (proposed.title.trim().isEmpty ||
          proposed.oneAction.trim().isEmpty ||
          proposed.why.trim().isEmpty ||
          proposed.steps.isEmpty ||
          proposed.materials.isEmpty) {
        throw const FormatException(
          'Лея вернула неполную подготовку. Попробуй запрос ещё раз.',
        );
      }
      if (goal != null &&
          proposed.goalId.isNotEmpty &&
          proposed.goalId != goal!.id) {
        throw const FormatException(
          'Миссия относится к другой цели. Повтори запрос для текущей цели.',
        );
      }
    }
    final newGoal = response['goal'] == null
        ? null
        : Goal.fromJson(response['goal']);
    if (newGoal != null && goal != null && newGoal.id != goal!.id) {
      throw const FormatException(
        'Этот ответ относится к предыдущей цели. Повтори запрос для текущей цели.',
      );
    }
    if (newGoal != null && newGoal.title.trim().isNotEmpty) {
      if (goal != null) {
        goal!.title = newGoal.title;
        goal!.context = newGoal.context;
      } else {
        state.goal = newGoal;
        state.goals.add(newGoal);
      }
    }
    if (proposed != null) {
      final previous = currentMission;
      if (previous != null &&
          previous.id != proposed.id &&
          !previous.isClosed) {
        previous.status = MissionStatus.declined;
        previous.declineReason =
            'Миссия заменена после уточнения следующего хода.';
        previous.recordEvent('replaced', {'nextMissionId': proposed.id});
      }
      if (!state.missions.any((m) => m.id == proposed!.id)) {
        state.missions.add(proposed);
      }
      state.currentMissionId = proposed.id;
    }
    final reply = jsonString(response['reply']);
    state.needsClarification = response['needsClarification'] == true;
    state.quickReplies
      ..clear()
      ..addAll(jsonStrings(response['quickReplies']).where((text) => text.length <= 48).take(3));
    if (reply.isNotEmpty) {
      state.chat.add(ChatMessage(role: 'assistant', text: reply));
    }
    if (response['understanding'] is String) {
      state.understanding = response['understanding'] as String;
    }
    state.assumptions
      ..clear()
      ..addAll(jsonStrings(response['assumptions']));
    state.contextUpdates.addAll(
      jsonList(response['contextUpdates']).map(jsonObject),
    );
    final reflection = jsonObject(response['reflection']);
    if (reflection.isNotEmpty) {
      // A new goal can coexist with previous goals in history. Its reflection
      // must never rewrite a result belonging to another goal.
      final last = lastCompletedMission;
      if (last != null) {
        final out = last.outcome!;
        if (reflection['learned'] is String) {
          out.learned = reflection['learned'] as String;
        }
        if (reflection['goalImpact'] is String) {
          out.goalImpact = reflection['goalImpact'] as String;
        }
        if (reflection['nextMove'] is String) {
          out.nextDirection = reflection['nextMove'] as String;
        }
      }
    }
    _changed();
  }
}
