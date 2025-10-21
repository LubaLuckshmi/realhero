import 'package:flutter/material.dart';
import '../services/ai_service.dart';

/// Панель: пытается загрузить идеи через AIService.
/// Если ИИ вернул пусто/ошибку — показывает [fallback].
class AISuggestionsPanel extends StatefulWidget {
  const AISuggestionsPanel({
    super.key,
    required this.signals,
    required this.fallback,
    this.onTapSuggestion,
  });

  final OnboardingSignal signals;

  /// Виджет со старыми «шаблонными» подсказками.
  final Widget fallback;

  /// Колбэк при выборе подсказки.
  final void Function(GoalSuggestion idea)? onTapSuggestion;

  @override
  State<AISuggestionsPanel> createState() => _AISuggestionsPanelState();
}

class _AISuggestionsPanelState extends State<AISuggestionsPanel> {
  late Future<List<GoalSuggestion>> _future;

  @override
  void initState() {
    super.initState();
    _future = AIService.suggestGoals(widget.signals);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GoalSuggestion>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final ideas = snap.data ?? const <GoalSuggestion>[];
        if (ideas.isEmpty) return widget.fallback;

        return ListView.separated(
          primary: true, // важное: привязывает PrimaryScrollController
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: ideas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final g = ideas[i];
            return ListTile(
              tileColor: Colors.white.withOpacity(.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(g.title, style: const TextStyle(color: Colors.white)),
              subtitle: g.firstStep == null || g.firstStep!.isEmpty
                  ? null
                  : Text(
                      'Первый шаг: ${g.firstStep}',
                      style: const TextStyle(color: Colors.white70),
                    ),
              trailing: g.tags.isEmpty
                  ? null
                  : Wrap(
                      spacing: 6,
                      children: g.tags
                          .map(
                            (t) => Chip(
                              label: Text(t),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
              onTap: widget.onTapSuggestion == null
                  ? null
                  : () => widget.onTapSuggestion!(g),
            );
          },
        );
      },
    );
  }
}
