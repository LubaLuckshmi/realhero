// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

/// Безопасная обёртка вокруг FirebaseAnalytics:
/// - в рантайме логирует события,
/// - в тестах/без инициализации Firebase — тихо ничего не делает.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  /// Пытаемся получить инстанс. Если Firebase не инициализирован —
  /// вернём null, чтобы методы стали no-op.
  FirebaseAnalytics? get _fa {
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> onboardingComplete({
    required int inspirations,
    required int energy,
    String? mood,
  }) async {
    final fa = _fa;
    if (fa == null) return;
    await fa.logEvent(
      name: 'onboarding_complete',
      parameters: {
        'inspirations_cnt': inspirations,
        'energy_cnt': energy,
        if (mood != null) 'mood': mood,
      },
    );
  }

  Future<void> aiSuggestionShow({
    required int total,
    required int index,
  }) async {
    final fa = _fa;
    if (fa == null) return;
    await fa.logEvent(
      name: 'ai_suggestion_show',
      parameters: {'total': total, 'index': index},
    );
  }

  Future<void> goalAdded({required String title, String? category}) async {
    final fa = _fa;
    if (fa == null) return;
    await fa.logEvent(
      name: 'goal_added',
      parameters: {
        'title_len': title.length,
        if (category != null) 'category': category,
      },
    );
  }
}
