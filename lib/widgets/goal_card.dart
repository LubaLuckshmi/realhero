
/// goal_card.dart — карточка цели
import 'package:flutter/material.dart';
import '../models/goal.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const GoalCard({super.key, required this.goal, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: ListTile(
          onTap: onToggle,
          title: Text(goal.title, style: TextStyle(
            decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
          )),
          trailing: Checkbox(value: goal.isCompleted, onChanged: (_) => onToggle()),
        ),
      ),
    );
  }
}
