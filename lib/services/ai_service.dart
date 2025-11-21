import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/deep_focus.dart';

/// Модель одной подсказки цели
/// 
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

class AIService {
  static final String _openaiKey =
      const String.fromEnvironment(
        'OPENAI_API_KEY',
        defaultValue: '',
      ).isNotEmpty
      ? const String.fromEnvironment('OPENAI_API_KEY')
      : (Platform.environment['OPENAI_API_KEY'] ?? '');

  static const bool _debugAI = true;
  static void _log(String msg) {
    if (_debugAI) print('[AI] $msg');
  }

  // -------- ЦЕЛИ ИЗ ОНБОРДИНГА --------
  static Future<List<GoalSuggestion>> suggestGoals(OnboardingSignal s) async {
    if (_openaiKey.isEmpty) {
      _log('EMPTY KEY -> fallback');
      return const [];
    }

    final system = '''
Ты — коуч по целям. На основе сигналов онбординга предложи 3–5 осмысленных целей.
Формат строго JSON-массив без пояснений. Каждый объект:
{ "title": "…", "firstStep": "…", "tags": ["…"] }
Язык: русский. Избегай банальностей.
''';

    final user = jsonEncode({
      'signals': s.toJson(),
      'examples': [
        {
          'title': 'Готовить «вечер тишины» раз в неделю',
          'firstStep': 'Выбрать вечер и отключить уведомления на 1 час',
          'tags': ['баланс'],
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
      if (choices.isEmpty) return const [];

      final content =
          (choices.first as Map)['message']?['content'] as String? ?? '[]';
      final jsonSlice = _extractFirstJsonArray(_stripCodeFences(content));
      final ideas = parseIdeas(jsonSlice);
      _log('ideas parsed: ${ideas.length}');
      return ideas;
    } catch (e) {
      _log('error: $e');
      return const [];
    }
  }

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

  static String _stripCodeFences(String s) =>
      s.replaceAll('```json', '').replaceAll('```', '').trim();

  static String _extractFirstJsonArray(String s) {
    final start = s.indexOf('[');
    final end = s.lastIndexOf(']');
    if (start >= 0 && end > start) return s.substring(start, end + 1);
    return '[]';
  }

  // -------- ПРЕДЛОЖИТЬ ПЕРВЫЙ ШАГ С УЧЁТОМ ПРОФИЛЯ --------
  static Future<String?> generateFirstStep({
    required String goalTitle,
    DeepFocusResult? profile,
  }) async {
    if (_openaiKey.isEmpty) return null;

    final system = '''
Ты — коуч по маленьким действиям. Дай ОДИН очень конкретный шаг на 10–20 минут,
чтобы продвинуть цель. Возвращай короткое предложение, без нумераций.
Язык — русский.
''';

    final context = {
      'goal': goalTitle,
      if (profile != null)
        'profile': {
          'archetype': profile.archetype,
          'stage': profile.stage,
          'summary': profile.summary,
          'advice': profile.advice,
          'raw': {
            'dislike': profile.raw.dislike,
            'priority': profile.raw.priority,
            'meaning': profile.raw.meaning,
            'noFear': profile.raw.noFear,
          },
        },
    };

    final user = jsonEncode(context);

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $_openaiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'temperature': 0.6,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'max_tokens': 150,
    });

    try {
      final resp = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = (data['choices'] as List?) ?? const [];
      if (choices.isEmpty) return null;
      final content = (choices.first as Map)['message']?['content'] as String?;
      return content?.trim();
    } catch (_) {
      return null;
    }
  }
    /// ИИ-предложения коротких целей по категории.
  /// Возвращает 2–4 идеи. Если ключ пустой/ошибка — вернёт [].
  static Future<List<GoalSuggestion>> suggestQuickGoals(
    String category, {
    int n = 3,
  }) async {
    if (_openaiKey.isEmpty) return const [];

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $_openaiKey',
      'Content-Type': 'application/json',
    };

    final system =
        '''
Ты — коуч по целям. Дай ${n.clamp(2, 4)} коротких, конкретных целей
в категории "$category". Для каждой — 1 первый шаг. Формат ответа строго:
[
  {"title":"...", "firstStep":"...", "tags":["$category"]},
  ...
]
Без пояснений вокруг. Язык: русский. Избегай банальностей, делай практично.
''';

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'temperature': 0.7,
      'max_tokens': 500,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': 'Только JSON-массив, пожалуйста.'},
      ],
    });

    try {
      final resp = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 35));

      if (resp.statusCode != 200) return const [];

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content =
          ((data['choices'] as List).first['message'] as Map)['content']
              as String? ??
          '[]';

      final clean = _stripCodeFences(content);
      final jsonSlice = _extractFirstJsonArray(clean);
      return parseIdeas(jsonSlice);
    } catch (_) {
      return const [];
    }
    
  }
    /// Предложения 1–3 мини-шагов на сегодня (учитывает фокус недели и активные цели).
  static Future<List<String>> suggestDailyActions({
    required DeepFocusResult? profile,
    required List<String> activeGoals,
  }) async {
    if (_openaiKey.isEmpty) return const [];

    final system = '''
Ты — ассистент "реального дня". Дай 1–3 очень коротких действия
(каждое до 100 символов), которые пользователь может сделать сегодня.
Учитывай его краткий профиль (аркетип/этап/совет) и активные цели.
Ответ строго JSON-массив строк, без текста вокруг.
''';

    final user = jsonEncode({
      'profile': profile == null
          ? null
          : {
              'archetype': profile.archetype,
              'stage': profile.stage,
              'summary': profile.summary,
              'advice': profile.advice,
            },
      'activeGoals': activeGoals,
      'constraints': ['простые', 'выполнимые за 5–20 минут', 'без воды'],
    });

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $_openaiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'temperature': 0.6,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'max_tokens': 300,
    });

    try {
      final resp = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) return const [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String? ??
          '[]';

      final clean = _stripCodeFences(content);
      final slice = _extractFirstJsonArray(clean);
      final parsed = jsonDecode(slice);
      if (parsed is List) {
        return parsed
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .take(3)
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

}
