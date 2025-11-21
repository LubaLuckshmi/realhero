import 'dart:convert';

/// Сырые ответы пользователя (что выбрал и что написал сам)
class DeepFocusInputRaw {
  final List<String> dislikeChoices;
  final List<String> priorityChoices;
  final List<String> meaningChoices;
  final List<String> noFearChoices;

  final String? dislikeCustom;
  final String? priorityCustom;
  final String? meaningCustom;
  final String? noFearCustom;

  const DeepFocusInputRaw({
    this.dislikeChoices = const [],
    this.priorityChoices = const [],
    this.meaningChoices = const [],
    this.noFearChoices = const [],
    this.dislikeCustom,
    this.priorityCustom,
    this.meaningCustom,
    this.noFearCustom,
  });

  /// Сводим всё к кратким строкам
  String get dislike => [
    ...dislikeChoices,
    if ((dislikeCustom ?? '').trim().isNotEmpty) dislikeCustom!.trim(),
  ].join(', ');
  String get priority => [
    ...priorityChoices,
    if ((priorityCustom ?? '').trim().isNotEmpty) priorityCustom!.trim(),
  ].join(', ');
  String get meaning => [
    ...meaningChoices,
    if ((meaningCustom ?? '').trim().isNotEmpty) meaningCustom!.trim(),
  ].join(', ');
  String get noFear => [
    ...noFearChoices,
    if ((noFearCustom ?? '').trim().isNotEmpty) noFearCustom!.trim(),
  ].join(', ');

  Map<String, dynamic> toJson() => {
    'dislikeChoices': dislikeChoices,
    'priorityChoices': priorityChoices,
    'meaningChoices': meaningChoices,
    'noFearChoices': noFearChoices,
    'dislikeCustom': dislikeCustom,
    'priorityCustom': priorityCustom,
    'meaningCustom': meaningCustom,
    'noFearCustom': noFearCustom,
  };

  factory DeepFocusInputRaw.fromJson(Map<String, dynamic> j) =>
      DeepFocusInputRaw(
        dislikeChoices:
            (j['dislikeChoices'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        priorityChoices:
            (j['priorityChoices'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        meaningChoices:
            (j['meaningChoices'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        noFearChoices:
            (j['noFearChoices'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        dislikeCustom: j['dislikeCustom'] as String?,
        priorityCustom: j['priorityCustom'] as String?,
        meaningCustom: j['meaningCustom'] as String?,
        noFearCustom: j['noFearCustom'] as String?,
      );
}

/// Итог профиля, который храним и показываем на Home
class DeepFocusResult {
  final String archetype;
  final String stage;
  final String summary;
  final String advice;
  final DateTime createdAt;
  final DeepFocusInputRaw raw;

  const DeepFocusResult({
    required this.archetype,
    required this.stage,
    required this.summary,
    required this.advice,
    required this.createdAt,
    required this.raw,
  });

  Map<String, dynamic> toJson() => {
    'archetype': archetype,
    'stage': stage,
    'summary': summary,
    'advice': advice,
    'createdAt': createdAt.toIso8601String(),
    'raw': raw.toJson(),
  };

  factory DeepFocusResult.fromJson(Map<String, dynamic> j) => DeepFocusResult(
    archetype: (j['archetype'] ?? '').toString(),
    stage: (j['stage'] ?? '').toString(),
    summary: (j['summary'] ?? '').toString(),
    advice: (j['advice'] ?? '').toString(),
    createdAt:
        DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
    raw: DeepFocusInputRaw.fromJson(
      (j['raw'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );

  static DeepFocusResult? tryParse(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DeepFocusResult.fromJson(json.decode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

/// Сигнал «создать цель на основе совета»
class DeepFocusCreateGoal {
  final String title;
  final String firstStep;

  const DeepFocusCreateGoal({required this.title, required this.firstStep});
}
