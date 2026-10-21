/// User-selected answers, not a diagnosis or a generated life goal.
enum DiscoveryPhase { idle, entry, knownGoal, questions, direction, review }

enum DiscoveryAnswer { yes, no, unsure }

String discoveryAnswerLabel(DiscoveryAnswer answer) => switch (answer) {
  DiscoveryAnswer.yes => 'Да',
  DiscoveryAnswer.no => 'Нет',
  DiscoveryAnswer.unsure => 'Не знаю',
};

class DiscoveryQuestion {
  final String id;
  final String text;
  const DiscoveryQuestion(this.id, this.text);
}

class DiscoveryState {
  static const questions = [
    DiscoveryQuestion('energy', 'Сейчас есть силы на маленький шаг?'),
    DiscoveryQuestion('time', 'Найдётся пять минут без спешки?'),
    DiscoveryQuestion('people', 'Сейчас комфортно общаться с людьми?'),
  ];
  static const directions = [
    'Творчество', 'Учёба', 'Работа и дела', 'Общение', 'Личный проект', 'Отдых',
  ];

  DiscoveryPhase phase;
  String goalText;
  String direction;
  String? existingGoalId;
  int questionIndex;
  String answeredAt;
  bool paused;
  final Map<String, DiscoveryAnswer> answers;

  DiscoveryState({
    this.phase = DiscoveryPhase.idle,
    this.goalText = '',
    this.direction = '',
    this.existingGoalId,
    this.questionIndex = 0,
    this.answeredAt = '',
    this.paused = false,
    Map<String, DiscoveryAnswer>? answers,
  }) : answers = answers ?? {};

  bool get active => phase != DiscoveryPhase.idle && !paused;
  bool get hasIdea => goalText.trim().isNotEmpty;
  DiscoveryQuestion get question => questions[questionIndex.clamp(0, questions.length - 1)];
  bool get ready => questions.every((question) => answers.containsKey(question.id));
  int get minuteCeiling => answers['time'] == DiscoveryAnswer.yes &&
      answers['energy'] == DiscoveryAnswer.yes ? 5 : 2;
  String get reviewText => answers['energy'] == DiscoveryAnswer.no
      ? 'Подберём совсем лёгкую пробу. Можно остановиться в любой момент.'
      : 'Лея подготовит один шаг до $minuteCeiling минут. Большой план пока не нужен.';

  void answer(DiscoveryAnswer answer) {
    if (phase != DiscoveryPhase.questions) return;
    answers[question.id] = answer;
    answeredAt = DateTime.now().toUtc().toIso8601String();
    if (questionIndex < questions.length - 1) {
      questionIndex += 1;
    } else {
      phase = hasIdea ? DiscoveryPhase.review : DiscoveryPhase.direction;
    }
  }

  void back() {
    switch (phase) {
      case DiscoveryPhase.questions:
        if (questionIndex > 0) {
          questionIndex -= 1;
        } else {
          phase = DiscoveryPhase.entry;
        }
        break;
      case DiscoveryPhase.direction:
        questionIndex = questions.length - 1;
        phase = DiscoveryPhase.questions;
        break;
      case DiscoveryPhase.review:
        if (hasIdea) {
          questionIndex = questions.length - 1;
          phase = DiscoveryPhase.questions;
        } else {
          phase = DiscoveryPhase.direction;
        }
        break;
      case DiscoveryPhase.knownGoal:
        phase = DiscoveryPhase.entry;
        break;
      case DiscoveryPhase.entry:
      case DiscoveryPhase.idle:
        phase = DiscoveryPhase.idle;
        break;
    }
  }

  String brief() {
    if (!ready) throw StateError('Сначала закончи короткое знакомство.');
    return [
      if (hasIdea) 'Моя идея: ${goalText.trim()}'
      else 'Большой цели пока нет. Хочу найти посильный следующий шаг.',
      for (final question in questions)
        '${question.text} — ${discoveryAnswerLabel(answers[question.id]!)}',
      if (direction.isNotEmpty) 'Сейчас мне ближе: $direction.'
      else if (!hasIdea) 'С направлением пока не определено.',
      'Хочу идти к своему интересу одним лёгким шагом. Если интерес пока не выбран, предложи два конкретных варианта и «Пока ничего», чтобы я мог выбрать нажатием. Не назначай упражнение на внимательность вместо поиска интереса.',
    ].join('\n');
  }

  factory DiscoveryState.fromJson(dynamic value) {
    if (value is! Map) return DiscoveryState();
    final phase = DiscoveryPhase.values.where((item) => item.name == value['phase']).firstOrNull;
    final answers = <String, DiscoveryAnswer>{};
    final saved = value['answers'];
    if (saved is Map) {
      for (final question in questions) {
        final answer = DiscoveryAnswer.values.where((item) => item.name == saved[question.id]).firstOrNull;
        if (answer != null) answers[question.id] = answer;
      }
    }
    final result = DiscoveryState(
      phase: phase ?? DiscoveryPhase.idle,
      goalText: value['goalText'] is String ? value['goalText'] as String : '',
      direction: directions.contains(value['direction']) ? value['direction'] as String : '',
      existingGoalId: value['existingGoalId'] is String ? value['existingGoalId'] as String : null,
      questionIndex: value['questionIndex'] is int
          ? (value['questionIndex'] as int).clamp(0, questions.length - 1) : 0,
      answers: answers,
      answeredAt: value['answeredAt'] is String ? value['answeredAt'] as String : '',
      paused: value['paused'] == true,
    );
    // A partially written/corrupt review must never create fabricated answers.
    if ((result.phase == DiscoveryPhase.review || result.phase == DiscoveryPhase.direction) && !result.ready) {
      result.phase = DiscoveryPhase.questions;
      result.questionIndex = questions.indexWhere((question) => !answers.containsKey(question.id));
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'phase': phase.name,
    'goalText': goalText,
    'direction': direction,
    'existingGoalId': existingGoalId,
    'questionIndex': questionIndex,
    'answeredAt': answeredAt,
    'paused': paused,
    'answers': answers.map((key, value) => MapEntry(key, value.name)),
  };
}
