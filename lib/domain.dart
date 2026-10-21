import 'discovery.dart';

/// RealHero's serialisable, device-local domain. The game layer and changes in
/// the real world intentionally have different records.
enum MissionStatus { prepared, active, paused, deferred, declined, completed }

enum OutcomeKind { positive, negative, noReply, partial, unknown }

String outcomeLabel(OutcomeKind kind) => switch (kind) {
  OutcomeKind.positive => 'Получилось',
  OutcomeKind.negative => 'Получен отказ',
  OutcomeKind.noReply => 'Ответа пока нет',
  OutcomeKind.partial => 'Частичный результат',
  OutcomeKind.unknown => 'Другой результат',
};

Map<String, dynamic> jsonObject(dynamic value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};
String jsonString(dynamic value, [String fallback = '']) =>
    value is String ? value : fallback;
int jsonInt(dynamic value, [int fallback = 0]) =>
    value is num ? value.toInt() : fallback;
List<dynamic> jsonList(dynamic value) => value is List ? value : [];
DateTime jsonDate(dynamic value, [DateTime? fallback]) =>
    DateTime.tryParse(jsonString(value)) ?? fallback ?? DateTime.now().toUtc();
List<String> jsonStrings(dynamic value) => jsonList(
  value,
).whereType<String>().where((s) => s.trim().isNotEmpty).toList();
T jsonEnum<T extends Enum>(List<T> values, dynamic value, T fallback) =>
    values.where((e) => e.name == value).firstOrNull ?? fallback;
String newId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

class Goal {
  final String id;
  String title;
  String context;
  final DateTime createdAt;
  Goal({
    required this.id,
    required this.title,
    this.context = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();
  factory Goal.fromJson(dynamic value) {
    final j = jsonObject(value);
    return Goal(
      id: jsonString(j['id'], newId('goal')),
      title: jsonString(j['title']),
      context: jsonString(j['context']),
      createdAt: jsonDate(j['createdAt']),
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'context': context,
    'createdAt': createdAt.toIso8601String(),
  };
}

class PreparedMaterial {
  final String id;
  final String label;
  String text;
  final String kind;
  final String originalText;
  PreparedMaterial({
    required this.id,
    required this.label,
    required this.text,
    this.kind = 'draft',
    String? originalText,
  }) : originalText = originalText ?? text;
  bool get edited => text != originalText;
  factory PreparedMaterial.fromJson(dynamic value) {
    final j = jsonObject(value);
    final text = jsonString(j['text'], jsonString(j['content']));
    return PreparedMaterial(
      id: jsonString(j['id'], newId('material')),
      label: jsonString(j['label'], jsonString(j['title'], 'Материал')),
      text: text,
      kind: jsonString(j['kind'], jsonString(j['type'], 'draft')),
      originalText: jsonString(j['originalText'], text),
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'text': text,
    'kind': kind,
    'originalText': originalText,
  };
}

class MissionStep {
  final String id;
  final String title;
  final String hint;
  MissionStep({required this.id, required this.title, this.hint = ''});
  factory MissionStep.fromJson(dynamic value) {
    if (value is String) return MissionStep(id: newId('step'), title: value);
    final j = jsonObject(value);
    return MissionStep(
      id: jsonString(j['id'], newId('step')),
      title: jsonString(j['title']),
      hint: jsonString(j['hint']),
    );
  }
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'hint': hint};
}

class OutcomeRecord {
  final OutcomeKind kind;
  final String facts;
  final int actualMinutes;
  final int difficulty;
  final bool timeReported;
  final bool difficultyReported;
  final String observations;
  String learned;
  String goalImpact;
  String nextDirection;
  final int xpEarned;
  final bool actionTaken;
  final DateTime createdAt;
  OutcomeRecord({
    required this.kind,
    required this.facts,
    required this.actualMinutes,
    required this.difficulty,
    this.timeReported = true,
    this.difficultyReported = true,
    this.observations = '',
    this.learned = '',
    this.goalImpact = '',
    this.nextDirection = '',
    this.xpEarned = 0,
    this.actionTaken = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();
  String get whatHappened => facts;
  String get nextMove => nextDirection;
  @override
  String toString() =>
      'Результат: ${outcomeLabel(kind)}\n$facts\n\n'
      'Наблюдение: $learned\nВлияние на цель: $goalImpact\n'
      'Следующий ход: $nextDirection\n\n'
      'Время: ${timeReported ? '$actualMinutes мин' : 'не отмечено'} · Сложность: ${difficultyReported ? '$difficulty из 5' : 'не отмечена'}\n'
      'Игровой опыт: +$xpEarned XP';
  factory OutcomeRecord.fromJson(dynamic value) {
    final j = jsonObject(value);
    return OutcomeRecord(
      kind: jsonEnum(OutcomeKind.values, j['kind'], OutcomeKind.unknown),
      facts: jsonString(j['facts']),
      actualMinutes: jsonInt(j['actualMinutes']),
      timeReported: j['timeReported'] != false,
      difficultyReported: j['difficultyReported'] != false,
      difficulty: jsonInt(j['difficulty'], 2).clamp(1, 5),
      observations: jsonString(j['observations']),
      learned: jsonString(j['learned']),
      goalImpact: jsonString(j['goalImpact']),
      nextDirection: jsonString(j['nextDirection']),
      xpEarned: jsonInt(j['xpEarned']),
      actionTaken: j['actionTaken'] != false,
      createdAt: jsonDate(j['createdAt']),
    );
  }
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'facts': facts,
    'actualMinutes': actualMinutes,
    'timeReported': timeReported,
    'difficultyReported': difficultyReported,
    'difficulty': difficulty,
    'observations': observations,
    'learned': learned,
    'goalImpact': goalImpact,
    'nextDirection': nextDirection,
    'xpEarned': xpEarned,
    'actionTaken': actionTaken,
    'createdAt': createdAt.toIso8601String(),
  };
}

class Mission {
  final String id;
  final String goalId;
  String title;
  String why;
  int minutes;
  String oneAction;
  final String lightAction;
  final List<MissionStep> steps;
  final List<PreparedMaterial> materials;
  MissionStatus status;
  int currentStep;
  int currentQuestion;
  String note;
  final String chapter;
  final String ability;
  final List<String> contactNames;
  final List<String> evidence;
  final DateTime createdAt;
  DateTime? startedAt;
  DateTime? deferredUntil;
  String declineReason;
  bool isLight;
  bool actionConfirmed;
  OutcomeRecord? outcome;
  final List<Map<String, dynamic>> events;
  Mission({
    required this.id,
    required this.goalId,
    required this.title,
    required this.why,
    required this.minutes,
    required this.oneAction,
    required this.lightAction,
    required this.steps,
    required this.materials,
    this.status = MissionStatus.prepared,
    this.currentStep = 0,
    this.currentQuestion = 0,
    this.note = '',
    this.chapter = 'Первый шаг',
    this.ability = 'Инициатива',
    this.contactNames = const [],
    this.evidence = const [],
    DateTime? createdAt,
    this.startedAt,
    this.deferredUntil,
    this.declineReason = '',
    this.isLight = false,
    this.actionConfirmed = false,
    this.outcome,
    List<Map<String, dynamic>>? events,
  }) : createdAt = createdAt ?? DateTime.now().toUtc(),
       events = events ?? [];
  bool get isClosed =>
      status == MissionStatus.completed || status == MissionStatus.declined;
  MissionStep? get activeStep =>
      steps.isEmpty ? null : steps[currentStep.clamp(0, steps.length - 1)];
  List<String> get preparedQuestions => materials
      .where((material) => material.kind == 'questions')
      .firstOrNull?.text.split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList() ?? <String>[];
  void recordEvent(String type, [Map<String, dynamic> payload = const {}]) =>
      events.add({
        'type': type,
        'at': DateTime.now().toUtc().toIso8601String(),
        ...payload,
      });
  factory Mission.fromJson(dynamic value) {
    final j = jsonObject(value);
    final stepList = jsonList(j['steps']).map(MissionStep.fromJson).toList();
    return Mission(
      id: jsonString(j['id'], newId('mission')),
      goalId: jsonString(j['goalId']),
      title: jsonString(j['title']),
      why: jsonString(j['why']),
      minutes: jsonInt(j['minutes'], 10).clamp(1, 240),
      oneAction: jsonString(j['oneAction']),
      lightAction: jsonString(j['lightAction']),
      steps: stepList,
      materials: jsonList(
        j['materials'],
      ).map(PreparedMaterial.fromJson).toList(),
      status: jsonEnum(
        MissionStatus.values,
        j['status'],
        MissionStatus.prepared,
      ),
      currentStep: stepList.isEmpty
          ? 0
          : jsonInt(j['currentStep']).clamp(0, stepList.length - 1),
      currentQuestion: jsonInt(j['currentQuestion']).clamp(0, 100),
      note: jsonString(j['note']),
      chapter: jsonString(j['chapter'], 'Первый шаг'),
      ability: jsonString(j['ability'], 'Инициатива'),
      contactNames: jsonStrings(j['contactNames']),
      evidence: jsonList(j['evidence'])
          .map((e) => e is String ? e : jsonString(jsonObject(e)['quote']))
          .where((e) => e.isNotEmpty)
          .toList(),
      createdAt: jsonDate(j['createdAt']),
      startedAt: j['startedAt'] == null ? null : jsonDate(j['startedAt']),
      deferredUntil: j['deferredUntil'] == null
          ? null
          : jsonDate(j['deferredUntil']),
      declineReason: jsonString(j['declineReason']),
      isLight: j['isLight'] == true,
      actionConfirmed: j['actionConfirmed'] == true,
      outcome: j['outcome'] == null
          ? null
          : OutcomeRecord.fromJson(j['outcome']),
      events: jsonList(j['events']).map(jsonObject).toList(),
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'goalId': goalId,
    'title': title,
    'why': why,
    'minutes': minutes,
    'oneAction': oneAction,
    'lightAction': lightAction,
    'steps': steps.map((e) => e.toJson()).toList(),
    'materials': materials.map((e) => e.toJson()).toList(),
    'status': status.name,
    'currentStep': currentStep,
    'currentQuestion': currentQuestion,
    'note': note,
    'chapter': chapter,
    'ability': ability,
    'contactNames': contactNames,
    'evidence': evidence.map((e) => {'quote': e}).toList(),
    'createdAt': createdAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'deferredUntil': deferredUntil?.toIso8601String(),
    'declineReason': declineReason,
    'isLight': isLight,
    'actionConfirmed': actionConfirmed,
    'outcome': outcome?.toJson(),
    'events': events,
  };
}

class ChatMessage {
  final String role;
  final String text;
  final DateTime createdAt;
  ChatMessage({required this.role, required this.text, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now().toUtc();
  factory ChatMessage.fromJson(dynamic value) {
    final j = jsonObject(value);
    return ChatMessage(
      role: jsonString(j['role'], 'user'),
      text: jsonString(j['text']),
      createdAt: jsonDate(j['createdAt']),
    );
  }
  Map<String, dynamic> toJson() => {
    'role': role,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
}

class HeroProfile {
  String name;
  String avatar;
  int xp;
  int completedCount;
  final List<String> abilities;
  final List<String> achievements;
  HeroProfile({
    this.name = 'Герой',
    this.avatar = 'assets/images/avatar.png',
    this.xp = 0,
    this.completedCount = 0,
    List<String>? abilities,
    List<String>? achievements,
  }) : abilities = abilities ?? [],
       achievements = achievements ?? [];
  int get level => 1 + xp ~/ 200;
  int get levelXp => xp % 200;
  int get nextLevelXp => 200;
  double get levelProgress => levelXp / nextLevelXp;
  factory HeroProfile.fromJson(dynamic value) {
    final j = jsonObject(value);
    return HeroProfile(
      name: jsonString(j['name'], 'Герой'),
      avatar: jsonString(j['avatar'], 'assets/images/avatar.png'),
      xp: jsonInt(j['xp']).clamp(0, 10000000),
      completedCount: jsonInt(j['completedCount']).clamp(0, 1000000),
      abilities: jsonStrings(j['abilities']),
      achievements: jsonStrings(j['achievements']),
    );
  }
  Map<String, dynamic> toJson() => {
    'name': name,
    'avatar': avatar,
    'xp': xp,
    'completedCount': completedCount,
    'abilities': abilities,
    'achievements': achievements,
  };
}

class RealChange {
  final String text;
  final String missionId;
  final DateTime createdAt;
  RealChange({required this.text, required this.missionId, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now().toUtc();
  factory RealChange.fromJson(dynamic value) {
    final j = jsonObject(value);
    return RealChange(
      text: jsonString(j['text']),
      missionId: jsonString(j['missionId']),
      createdAt: jsonDate(j['createdAt']),
    );
  }
  Map<String, dynamic> toJson() => {
    'text': text,
    'missionId': missionId,
    'createdAt': createdAt.toIso8601String(),
  };
}

class ServerSettings {
  String url;
  String accessToken;
  ServerSettings({this.url = '', this.accessToken = ''});
  bool get configured => url.isNotEmpty && accessToken.isNotEmpty;
  factory ServerSettings.fromJson(dynamic value) {
    final j = jsonObject(value);
    return ServerSettings(
      url: jsonString(j['url']),
      accessToken: jsonString(j['accessToken']),
    );
  }
  Map<String, dynamic> toJson() => {'url': url, 'accessToken': accessToken};
}

class AppState {
  static const snapshotVersion = 1;
  Goal? goal;
  final List<Goal> goals;
  final List<Mission> missions;
  String? currentMissionId;
  final List<ChatMessage> chat;
  HeroProfile profile;
  final List<RealChange> realChanges;
  ServerSettings settings;
  bool isDemo;
  String understanding;
  final List<String> assumptions;
  final List<Map<String, dynamic>> contextUpdates;
  DiscoveryState discovery;
  bool needsClarification;
  final List<String> quickReplies;
  AppState({
    this.goal,
    List<Goal>? goals,
    List<Mission>? missions,
    this.currentMissionId,
    List<ChatMessage>? chat,
    HeroProfile? profile,
    List<RealChange>? realChanges,
    ServerSettings? settings,
    this.isDemo = false,
    this.understanding = '',
    List<String>? assumptions,
    List<Map<String, dynamic>>? contextUpdates,
    DiscoveryState? discovery,
    this.needsClarification = false,
    List<String>? quickReplies,
  }) : goals = goals ?? [],
       missions = missions ?? [],
       chat = chat ?? [],
       profile = profile ?? HeroProfile(),
       realChanges = realChanges ?? [],
       settings = settings ?? ServerSettings(),
       assumptions = assumptions ?? [],
       contextUpdates = contextUpdates ?? [],
       discovery = discovery ?? DiscoveryState(),
       quickReplies = quickReplies ?? [];
  Mission? get currentMission =>
      missions.where((e) => e.id == currentMissionId).firstOrNull;
  factory AppState.fromJson(dynamic value) {
    final j = jsonObject(value);
    if (j.isEmpty) throw const FormatException('Пустое состояние');
    final version = jsonInt(j['version'], 1);
    if (version > snapshotVersion) {
      throw const FormatException('Версия данных новее приложения');
    }
    return AppState(
      goal: j['goal'] == null ? null : Goal.fromJson(j['goal']),
      goals: jsonList(j['goals']).map(Goal.fromJson).toList(),
      missions: jsonList(j['missions']).map(Mission.fromJson).toList(),
      currentMissionId: j['currentMissionId'] is String
          ? j['currentMissionId']
          : null,
      chat: jsonList(j['chat']).map(ChatMessage.fromJson).toList(),
      profile: HeroProfile.fromJson(j['profile']),
      realChanges: jsonList(j['realChanges']).map(RealChange.fromJson).toList(),
      settings: ServerSettings.fromJson(j['settings']),
      isDemo: j['isDemo'] == true,
      understanding: jsonString(j['understanding']),
      assumptions: jsonStrings(j['assumptions']),
      contextUpdates: jsonList(j['contextUpdates']).map(jsonObject).toList(),
      discovery: DiscoveryState.fromJson(j['discovery']),
      needsClarification: j['needsClarification'] == true,
      quickReplies: jsonStrings(j['quickReplies']).where((text) => text.length <= 48).take(3).toList(),
    );
  }
  Map<String, dynamic> toJson({bool includeSettings = true}) => {
    'version': snapshotVersion,
    'goal': goal?.toJson(),
    'goals': goals.map((e) => e.toJson()).toList(),
    'missions': missions.map((e) => e.toJson()).toList(),
    'currentMissionId': currentMissionId,
    'chat': chat.map((e) => e.toJson()).toList(),
    'profile': profile.toJson(),
    'realChanges': realChanges.map((e) => e.toJson()).toList(),
    if (includeSettings) 'settings': settings.toJson(),
    'isDemo': isDemo,
    'understanding': understanding,
    'assumptions': assumptions,
    'contextUpdates': contextUpdates,
    'discovery': discovery.toJson(),
    'needsClarification': needsClarification,
    'quickReplies': quickReplies,
  };
}

/// All named people and circumstances below belong only to the labelled demo.
class DemoScenario {
  static const context =
      'Демонстрационный сценарий. Цель: проверить понятность прототипа. Андрей раньше просил показать прототип. Два экрана прототипа готовы. Пользователь может выделить 10 минут, расходы не нужны. Контакт Андрея существует только в этой вымышленной демонстрации.';
  static Goal goal() => Goal(
    id: 'demo_goal',
    title: 'Проверить идею на реальном отклике',
    context: context,
  );
  static Mission invitation(String goalId) => Mission(
    id: newId('demo_invite'),
    goalId: goalId,
    title: 'Пригласи Андрея на демо',
    why:
        'Андрей уже просил показать прототип. Два экрана готовы — короткий показ даст первый конкретный отклик без дополнительной подготовки.',
    minutes: 10,
    oneAction: 'Проверь приглашение и отправь Андрею в своём мессенджере.',
    lightAction:
        'Отправь только короткое приглашение. Дату можно согласовать после ответа.',
    chapter: 'Первый реальный отклик',
    ability: 'Инициатива',
    contactNames: ['Андрей'],
    evidence: [
      'Андрей раньше просил показать прототип.',
      'Два экрана прототипа готовы.',
    ],
    steps: [
      MissionStep(
        id: 'review',
        title: 'Проверь приглашение',
        hint: 'Проверь текст и при необходимости измени его под свой стиль.',
      ),
      MissionStep(
        id: 'send',
        title: 'Отправь в мессенджере',
        hint:
            'Скопируй сообщение. Отправку выполняешь ты; приложение не отправляет его автоматически.',
      ),
      MissionStep(
        id: 'answer',
        title: 'Зафиксируй ответ',
        hint:
            'Согласие, отказ и отсутствие ответа помогают выбрать следующий ход.',
      ),
    ],
    materials: [
      PreparedMaterial(
        id: 'invitation',
        label: 'Готовое приглашение',
        kind: 'message',
        text:
            'Андрей, привет! Ты просил показать прототип — два экрана уже готовы. Сможешь посмотреть короткое демо на 10 минут? Хочу проверить, понятна ли идея и что стоит улучшить. Если интересно, давай согласуем удобное время.',
      ),
      PreparedMaterial(
        id: 'questions',
        label: 'Три вопроса для демо',
        kind: 'questions',
        text:
            '1. Как ты понял, какую задачу решает этот прототип?\n2. Что на двух экранах показалось непонятным или лишним?\n3. В какой реальной ситуации ты бы этим воспользовался?',
      ),
      PreparedMaterial(
        id: 'show_plan',
        label: 'План короткого показа',
        kind: 'checklist',
        text:
            'Открой два готовых экрана прототипа.\nПокажи каждый без длинного объяснения.\nЗадай три подготовленных вопроса.\nЗапиши ответы словами Андрея; пока не защищай решение.',
      ),
      prototypeMaterial(),
    ],
  );

  static Mission followup(String goalId, OutcomeRecord result) {
    if (result.kind == OutcomeKind.positive) {
      return Mission(
        id: newId('demo_show'),
        goalId: goalId,
        title: 'Покажи два экрана и собери отклик',
        why:
            'В демосценарии получено согласие. Теперь полезнее увидеть, как человек понимает прототип, чем продолжать его дорабатывать без отклика.',
        minutes: 10,
        oneAction:
            'Проведи согласованный показ двух экранов и запиши ответы на три вопроса.',
        lightAction: 'Покажи один экран и спроси, какую задачу он решает.',
        chapter: 'Первый реальный отклик',
        ability: 'Наблюдение',
        contactNames: ['Андрей'],
        evidence: [result.facts],
        steps: [
          MissionStep(
            id: 'show',
            title: 'Покажи прототип',
            hint: 'Не объясняй за человека. Дай посмотреть самостоятельно.',
          ),
          MissionStep(
            id: 'ask',
            title: 'Задай три вопроса',
            hint: 'Запиши точные слова, особенно непонятные места.',
          ),
          MissionStep(
            id: 'record',
            title: 'Сохрани отклик',
            hint: 'Неоднозначный ответ — информация, а не провал.',
          ),
        ],
        materials: [
          prototypeMaterial(),
          PreparedMaterial(
            id: 'demo_questions',
            label: 'Три вопроса',
            kind: 'questions',
            text:
                '1. Какую задачу решает прототип?\n2. Что осталось непонятно?\n3. Когда это пригодилось бы в твоей жизни?',
          ),
          PreparedMaterial(
            id: 'demo_notes',
            label: 'Шаблон заметки',
            kind: 'draft',
            text:
                'Как понял идею:\nНепонятный момент:\nРеальная ситуация использования:\nДословная цитата:',
          ),
        ],
      );
    }
    if (result.kind == OutcomeKind.noReply) {
      return Mission(
        id: newId('demo_wait'),
        goalId: goalId,
        title: 'Оставь приглашению время',
        why:
            'Ответа пока нет. Это ещё не отказ и не повод повторять сообщение сразу. Подготовлен спокойный вариант одного напоминания, если позже ты решишь его отправить.',
        minutes: 2,
        oneAction:
            'Выбери подходящее время вернуться к приглашению и сохрани напоминание.',
        lightAction: 'Просто отложи миссию на удобный день.',
        chapter: 'Проверка гипотезы',
        ability: 'Выбор темпа',
        contactNames: ['Андрей'],
        evidence: [result.facts],
        steps: [
          MissionStep(
            id: 'date',
            title: 'Выбери время',
            hint: 'Назначь удобный день. Без штрафов за ожидание.',
          ),
          MissionStep(
            id: 'review',
            title: 'Проверь напоминание',
            hint: 'Отправляй только если сам решишь, что это уместно.',
          ),
        ],
        materials: [
          PreparedMaterial(
            id: 'reminder',
            label: 'Один вариант напоминания',
            kind: 'message',
            text:
                'Андрей, привет! Возвращаюсь к короткому показу прототипа. Если сейчас не до этого, всё нормально — скажи, и я не буду отвлекать.',
          ),
        ],
      );
    }
    return Mission(
      id: newId('demo_adjust'),
      goalId: goalId,
      title: result.difficulty >= 4
          ? 'Сократи показ до одного вопроса'
          : 'Уточни, что стоит проверить дальше',
      why:
          'В демосценарии ответ не подтверждает исходный план. Не нужно повторять то же приглашение или придумывать другого знакомого. Сначала уточним собственную гипотезу.',
      minutes: result.difficulty >= 4 ? 3 : 5,
      oneAction:
          'Прочитай подготовленную гипотезу и исправь одну фразу, которую хочешь проверить.',
      lightAction: 'Выбери один непонятный элемент прототипа.',
      chapter: 'Проверка гипотезы',
      ability: 'Адаптация',
      evidence: [result.facts],
      steps: [
        MissionStep(
          id: 'choose',
          title: 'Уточни гипотезу',
          hint: 'Не делай вывод обо всех пользователях из одного ответа.',
        ),
        MissionStep(
          id: 'save',
          title: 'Сохрани исправление',
          hint: 'Следующий контакт пока не выбран. Его нельзя выдумать.',
        ),
      ],
      materials: [
        PreparedMaterial(
          id: 'hypothesis',
          label: 'Черновик проверяемой гипотезы',
          kind: 'draft',
          text:
              'Гипотеза: человеку будет понятно, какое реальное действие помогает подготовить прототип.\nПроверить: может ли человек своими словами описать назначение одного экрана.\nПока неизвестно: кому ещё уместно показать прототип.',
        ),
      ],
    );
  }

  static PreparedMaterial prototypeMaterial() => PreparedMaterial(
    id: 'prototype',
    label: 'Прототип · 2 экрана',
    kind: 'prototype',
    text:
        'Два встроенных демонстрационных экрана RealHero: «Сегодня» с подготовленной миссией и «Твой путь» с развитием героя. Это доступный внутри приложения пример для демосценария; он не выдаётся за внешний проект пользователя.',
  );
}
