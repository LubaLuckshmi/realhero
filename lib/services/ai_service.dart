import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// Модель одной подсказки цели
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
    title: (m['title'] ?? '').toString(),
    firstStep: (m['firstStep'] as String?)?.trim(),
    tags: (m['tags'] is List)
        ? (m['tags'] as List).map((e) => e.toString()).toList()
        : const <String>[],
  );
}

/// Сигналы из онбординга
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

/// Каркас ИИ-сервиса.
/// Ключ читаем из --dart-define=OPENAI_API_KEY=... или из переменных окружения.
class AIService {
  static final String _openaiKey =
      const String.fromEnvironment(
        'OPENAI_API_KEY',
        defaultValue: '',
      ).isNotEmpty
      ? const String.fromEnvironment('OPENAI_API_KEY')
      : (Platform.environment['OPENAI_API_KEY'] ?? '');

  // Отладочные логи в консоль (flutter run)
  static const bool _debugAI = true;
  static void _log(String msg) {
    if (_debugAI) {
      // ignore: avoid_print
      print('[AI] $msg');
    }
  }

  /// Основной метод: просим модель вернуть массив GoalSuggestion в JSON.
  /// Если что-то не так — возвращаем [], и UI берёт локальный fallback.
  static Future<List<GoalSuggestion>> suggestGoals(OnboardingSignal s) async {
    if (_openaiKey.isEmpty) {
      _log('EMPTY KEY -> fallback');
      return const [];
    }

    final system = '''
Ты — коуч по целям. На основе сигналов онбординга предложи 3–5 осмысленных целей.
Формат строго JSON-массив, без пояснений. Каждый объект:
{ "title": "…", "firstStep": "…", "tags": ["…", "…"] }
Теги — 1–2 коротких ярлыка (категория/настрой).
Избегай банальностей вроде "пить воду". Дай практичные и цепляющие формулировки.
Язык ответа: русский.
''';

    final user = jsonEncode({
      'signals': s.toJson(),
      'examples': [
        {
          'title': 'Готовить «вечер тишины» раз в неделю',
          'firstStep': 'Выбрать вечер и выключить все уведомления на 1 час',
          'tags': ['баланс'],
        },
        {
          'title': 'Собрать мини-портфолио из 3 работ',
          'firstStep': 'Выбрать 1 кейс и описать результат в 3 строках',
          'tags': ['карьера'],
        },
      ],
    });

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $_openaiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'temperature': 0.7,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'max_tokens': 600,
    });

    try {
      final resp = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 45));

      _log('status=${resp.statusCode}, bytes=${resp.bodyBytes.length}');
      if (resp.statusCode != 200) {
        final snippet = utf8.decode(resp.bodyBytes);
        _log('resp: ${snippet.substring(0, math.min(600, snippet.length))}');
        return const [];
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = (data['choices'] as List?) ?? const [];
      if (choices.isEmpty) {
        _log('no choices');
        return const [];
      }

      final content =
          (choices.first as Map)['message']?['content'] as String? ?? '[]';

      // иногда модель окружает JSON тройными кавычками ```json
      final jsonSlice = _extractFirstJsonArray(_stripCodeFences(content));
      final ideas = parseIdeas(jsonSlice);
      _log('ideas parsed: ${ideas.length}');
      return ideas;
    } catch (e) {
      _log('error: $e');
      return const [];
    }
  }

  /// Парсинг массива подсказок из JSON-строки
  static List<GoalSuggestion> parseIdeas(String jsonStr) {
    try {
      final data = json.decode(jsonStr);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(GoalSuggestion.fromJson)
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Удаляем ```json … ``` оболочку
  static String _stripCodeFences(String s) =>
      s.replaceAll('```json', '').replaceAll('```', '').trim();

  /// Вырезаем первый корректный JSON-массив из произвольной строки
  static String _extractFirstJsonArray(String s) {
    final start = s.indexOf('[');
    final end = s.lastIndexOf(']');
    if (start >= 0 && end > start) {
      return s.substring(start, end + 1);
    }
    return '[]';
  }
}
