// lib/services/ai_service.dart
import 'dart:convert';
import 'dart:io';

class GoalSuggestion {
  final String title;
  final String? firstStep;
  final List<String> tags;

  GoalSuggestion({required this.title, this.firstStep, this.tags = const []});

  Map<String, dynamic> toJson() => {
    'title': title,
    'firstStep': firstStep,
    'tags': tags,
  };

  static GoalSuggestion fromJson(Map<String, dynamic> m) => GoalSuggestion(
    title: (m['title'] ?? '') as String,
    firstStep: m['firstStep'] as String?,
    tags: (m['tags'] as List?)?.cast<String>() ?? const [],
  );
}

class OnboardingSignal {
  final String? fearChoice;
  final Set<String> inspirations;
  final Set<String> energy;
  final String? mood;

  const OnboardingSignal({
    required this.fearChoice,
    required this.inspirations,
    required this.energy,
    required this.mood,
  });

  Map<String, dynamic> toJson() => {
    'fearChoice': fearChoice,
    'inspirations': inspirations.toList(),
    'energy': energy.toList(),
    'mood': mood,
  };
}

class AIService {
  AIService._();
  static final AIService instance = AIService._();

  /// Ключ передаём через --dart-define=OPENAI_API_KEY=xxxxx
  static String _apiKey = const String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => _apiKey.isNotEmpty;
  static void setApiKey(String key) => _apiKey = key;

  /// Основной вызов: просим строго JSON-массив подсказок.
  /// Возвращаем пустой список при любой ошибке (fallback произойдёт выше).
  static Future<List<GoalSuggestion>> suggestGoals(OnboardingSignal s) async {
    if (!isConfigured) return [];

    final prompt =
        '''
Ты — ассистент, который предлагает микро-цели (по-русски) с очень маленьким "первым шагом".
Дай 4 идеи. Каждая идея: JSON-объект { "title": string, "firstStep": string, "tags": string[] }.
Только ЧИСТЫЙ JSON-массив без текста до/после.

Контекст:
- Что бы сделал(а) без страха: ${s.fearChoice ?? '-'}
- Что вдохновляет: ${s.inspirations.join(', ')}
- Что даёт энергию: ${s.energy.join(', ')}
- Настроение сейчас: ${s.mood ?? '-'}

Правила:
- title <= 40 символов, мотивирующий.
- firstStep — действие на 5–15 минут.
- tags: 1–2 коротких тега ("здоровье", "эмоции", "навык", "баланс"...).
- Без нумерации, только JSON.
''';

    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

      final body = jsonEncode({
        'model': 'gpt-4o-mini',
        'temperature': 0.7,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content':
                'Ты генерируешь микро-цели на русском. Всегда отвечай ТОЛЬКО валидным JSON с ключом "items": Goal[].',
          },
          {'role': 'user', 'content': prompt},
        ],
      });

      final client = HttpClient()
        ..badCertificateCallback = (_, __, ___) => false;
      final req = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 20));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.add(utf8.encode(body));

      final res = await req.close().timeout(const Duration(seconds: 30));
      final text = await utf8.decodeStream(res);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        // Логи оставим в консоли и вернём пусто — UI уйдёт в локальный fallback.
        // ignore: avoid_print
        print('[AI] HTTP ${res.statusCode}: $text');
        return [];
      }

      final map = jsonDecode(text) as Map<String, dynamic>;
      final content =
          ((map['choices'] as List).first as Map)['message']['content']
              as String;

      // Мы запросили JSON с ключом items: [...]
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final list = (parsed['items'] as List?) ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(GoalSuggestion.fromJson)
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('[AI] error: $e');
      return [];
    }
  }

  /// Парсер если понадобится вручную.
  static List<GoalSuggestion> parseIdeas(String jsonStr) {
    final data = jsonDecode(jsonStr);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(GoalSuggestion.fromJson)
          .toList();
    }
    return const [];
  }
}
