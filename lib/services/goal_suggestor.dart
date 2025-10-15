// lib/services/goal_suggestor.dart
import 'ai_service.dart';

class GoalSuggestor {
  static List<GoalSuggestion> suggestLocal({
    String? fearChoice,
    Set<String> inspirations = const {},
    Set<String> energy = const {},
    String? mood,
  }) {
    final result = <GoalSuggestion>[];

    if (inspirations.contains('Красота') || energy.contains('Красивые вещи')) {
      result.add(
        GoalSuggestion(
          title: 'Микро-эстетика дня',
          firstStep: 'Найти и сфотографировать «красоту дня»',
          tags: const ['вкус к жизни'],
        ),
      );
    }
    if ((inspirations.contains('Музыка')) ||
        (fearChoice?.contains('музык') ?? false)) {
      result.add(
        GoalSuggestion(
          title: 'Вернуть музыку в день',
          firstStep: 'Собрать плейлист на неделю и слушать по 10 минут',
          tags: const ['эмоции'],
        ),
      );
    }

    result.addAll([
      GoalSuggestion(
        title: 'Двигаться каждый день',
        firstStep: '15 минут прогулки после ужина',
        tags: const ['здоровье'],
      ),
      GoalSuggestion(
        title: 'Забота о себе',
        firstStep: 'Назначить 1 «тихий час» без телефона',
        tags: const ['баланс'],
      ),
    ]);

    return result;
  }

  static Future<List<GoalSuggestion>> suggestWithAiFallback({
    String? fearChoice,
    required Set<String> inspirations,
    required Set<String> energy,
    String? mood,
  }) async {
    final signal = OnboardingSignal(
      fearChoice: fearChoice,
      inspirations: inspirations,
      energy: energy,
      mood: mood,
    );

    final fromAi = await AIService.suggestGoals(signal);
    if (fromAi.isNotEmpty) return fromAi;

    return suggestLocal(
      fearChoice: fearChoice,
      inspirations: inspirations,
      energy: energy,
      mood: mood,
    );
  }
}
