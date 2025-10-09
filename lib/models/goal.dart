import 'dart:convert';

class Goal {
  final String id;
  final String category; // Пример: "Музыка", "Здоровье"
  final String title; // Название цели
  final String? firstStep; // Первый шаг
  final double progress; // 0.0 .. 1.0
  final bool isCompleted;

  const Goal({
    required this.id,
    required this.category,
    required this.title,
    this.firstStep,
    this.progress = 0.0,
    this.isCompleted = false,
  });

  Goal copyWith({
    String? id,
    String? category,
    String? title,
    String? firstStep,
    double? progress,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      firstStep: firstStep ?? this.firstStep,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'firstStep': firstStep,
    'progress': progress,
    'isCompleted': isCompleted,
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    category: json['category'] as String,
    title: json['title'] as String,
    firstStep: json['firstStep'] as String?,
    progress: (json['progress'] ?? 0.0).toDouble(),
    isCompleted: (json['isCompleted'] ?? false) as bool,
  );

  /// Для SharedPreferences (храним строкой)
  String toPrefs() => jsonEncode(toJson());
  factory Goal.fromPrefs(String s) =>
      Goal.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
