
/// goal.dart — модель цели
class Goal {
  final String id;
  final String title;
  final bool isCompleted;

  Goal({required this.id, required this.title, this.isCompleted = false});

  factory Goal.fromMap(Map<String, dynamic> data, String documentId) {
    return Goal(
      id: documentId,
      title: data['title'] ?? '',
      isCompleted: (data['isCompleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'isCompleted': isCompleted,
  };

  Goal copyWith({String? title, bool? isCompleted}) => Goal(
    id: id,
    title: title ?? this.title,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}
