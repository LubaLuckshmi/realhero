// lib/services/deep_focus_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Результат "Глубокого фокуса"
class DeepFocusAdvice {
  final String summary; // краткое описание пользователя (1–3 предложения)
  final String advice; // персональный совет (1–2 шага)

  DeepFocusAdvice({required this.summary, required this.advice});

  Map<String, dynamic> toJson() => {'summary': summary, 'advice': advice};

  static DeepFocusAdvice fromJson(Map<String, dynamic> m) => DeepFocusAdvice(
    summary: (m['summary'] ?? '').toString().trim(),
    advice: (m['advice'] ?? '').toString().trim(),
  );
}

/// Сервис ИИ для Deep Focus. Работает отдельно от общего AIService, чтобы не трогать
/// стабильный код генерации целей.
class DeepFocusService {
  static final String _openaiKey =
      const String.fromEnvironment(
        'OPENAI_API_KEY',
        defaultValue: '',
      ).isNotEmpty
      ? const String.fromEnvironment('OPENAI_API_KEY')
      : (Platform.environment['OPENAI_API_KEY'] ?? '');

  /// Главный метод. На вход — ответы на 4 вопроса. На выход — краткое описание и совет.
  static Future<DeepFocusAdvice> generate({
    required String dislike,
    required String priority,
    required String meaning,
    required String noFear,
  }) async {
    if (_openaiKey.isEmpty) {
      // Без ключа — мягкий фолбэк (чтобы не ломать UX)
      return DeepFocusAdvice(
        summary:
            'Ты стремишься к ясности и опоре на то, что по-настоящему важно, а лишнее уже хочется оставить позади.',
        advice:
            'Выбери 1 область, где ощутим эмоциональный “шум”, и убери из неё один раздражитель сегодня. Затем запланируй 1 конкретный шаг на завтра, который ведёт к “главному”.',
      );
    }

    final system = '''
Ты — практичный психолог-коуч. Пользователь ответил на 4 вопроса. 
Собери лаконичную выжимку и дай ясный совет действий на ближайшую неделю.
Важно:
- Не навешивай ярлыки, архетипы и диагнозы.
- Максимум конкретики и спокойного тона.
- Верни строго JSON-объект: {"summary":"...", "advice":"..."}.
Язык — русский.
''';

    final user = jsonEncode({
      'answers': {
        'what_dislike_now': dislike,
        'what_is_important': priority,
        'what_is_meaning': meaning,
        'if_no_fear': noFear,
      },
      'style': {
        'summary': '1–3 предложения, без клише',
        'advice': '2 коротких шага на неделю, максимально прикладные',
      },
    });

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $_openaiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'temperature': 0.7,
      'max_tokens': 500,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    });

    try {
      final resp = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 40));

      if (resp.statusCode != 200) {
        return _fallback(dislike, priority, meaning, noFear);
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content =
          ((data['choices'] as List).first['message']['content'] as String?) ??
          '{}';

      final jsonText = _extractFirstJsonObject(_stripCodeFences(content));
      final parsed = json.decode(jsonText);
      if (parsed is Map<String, dynamic>) {
        return DeepFocusAdvice.fromJson(parsed);
      }
      return _fallback(dislike, priority, meaning, noFear);
    } catch (_) {
      return _fallback(dislike, priority, meaning, noFear);
    }
  }

  // ————— helpers —————

  static String _stripCodeFences(String s) =>
      s.replaceAll('```json', '').replaceAll('```', '').trim();

  static String _extractFirstJsonObject(String s) {
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return s.substring(start, end + 1);
    }
    return '{}';
  }

  static DeepFocusAdvice _fallback(
    String dislike,
    String priority,
    String meaning,
    String noFear,
  ) {
    final s =
        'Ты хочешь больше опоры на "$priority" и смысла в "$meaning". '
        'Есть напряжение из-за "$dislike", а без страха ты бы сделал(а): "$noFear".';
    final a =
        '1) Убери один раздражитель из области "$dislike" уже сегодня.\n'
        '2) Запланируй на 30–45 минут конкретный шаг к "$noFear" в ближайшие 48 часов.';
    return DeepFocusAdvice(summary: s, advice: a);
  }
}
