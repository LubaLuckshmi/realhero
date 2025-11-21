import 'package:flutter/foundation.dart';

/// Тип позитивного события, за которое даём XP.
enum ProgressKind {
  actionDone, // выполнен мини-шаг
  backFromProcrast, // возвращение после прокрастинации
  honestAdmit, // честно признался в проблеме
  healthCare, // забота о здоровье
  trainingDone, // завершена тренировка/занятие
  emotionalWin, // эмоциональная победа
}

@immutable
class ProgressEvent {
  final DateTime at;
  final ProgressKind kind;
  final int xp;

  const ProgressEvent({required this.at, required this.kind, required this.xp});

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'kind': kind.name,
    'xp': xp,
  };

  factory ProgressEvent.fromJson(Map<String, dynamic> m) => ProgressEvent(
    at: DateTime.parse(m['at'] as String),
    kind: ProgressKind.values.firstWhere(
      (k) => k.name == (m['kind'] as String),
      orElse: () => ProgressKind.actionDone,
    ),
    xp: (m['xp'] as num).toInt(),
  );
}
