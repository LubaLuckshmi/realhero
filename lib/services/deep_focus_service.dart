import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import '../models/deep_focus.dart';
import 'profile_service.dart';

/// Набор для экрана результата — оставляем для совместимости с твоим UI
class DeepFocusAdvice {
  final String summary;
  final String advice;
  final String archetype;
  final String stage;

  const DeepFocusAdvice({
    required this.summary,
    required this.advice,
    required this.archetype,
    required this.stage,
  });
}

class DeepFocusService {
  static final String _openaiKey =
      const String.fromEnvironment(
        'OPENAI_API_KEY',
        defaultValue: '',
      ).isNotEmpty
      ? const String.fromEnvironment('OPENAI_API_KEY')
      : (Platform.environment['OPENAI_API_KEY'] ?? '');

  static const bool _debug = true;
  static void _log(String s) {
    if (_debug) print('[DeepFocus] $s');
  }

  /// Генерируем выжимку + совет и СРАЗУ сохраняем профиль локально
  static Future<DeepFocusAdvice> generate({
    required DeepFocusInputRaw raw,
  }) async {
    if (_openaiKey.isEmpty) {
      _log('EMPTY KEY — возвращаем дефолт');
      final advice = DeepFocusAdvice(
        summary: 'Ты стремишься к ясности и понимаемой системе действий.',
        advice:
            'На неделю — один маленький ритуал: 10 минут без экрана после пробуждения.',
        archetype: 'Исследователь',
        stage: 'Поиск фокуса',
      );
      await _saveProfile(advice, raw);
      return advice;
    }

    final system = '''
Ты — психолог и коуч. Ты даёшь короткую выжимку и один практичный совет на неделю.
Формат ответа: ЧИСТЫЙ JSON-объект без текста вокруг:
{
  "summary": "...",
  "advice": "...",
  "archetype": "...",
  "stage": "..."
}
Язык — русский. Кратко, без воды.
''';

    final user = jsonEncode({
      'answers': {
        'dislike': raw.dislike,
        'priority': raw.priority,
        'meaning': raw.meaning,
        'noFear': raw.noFear,
      },
      'note':
          'Ответы краткие: сделай выводы аккуратно. Совет — конкретное действие, выполнимое за 10–20 минут.',
    });

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $_openaiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'temperature': 0.5,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'max_tokens': 500,
    });

    try {
      final resp = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 40));

      _log('status=${resp.statusCode}, bytes=${resp.bodyBytes.length}');
      if (resp.statusCode != 200) {
        final snippet = utf8.decode(resp.bodyBytes);
        _log('resp: ${snippet.substring(0, math.min(600, snippet.length))}');
        // fallback
        final advice = DeepFocusAdvice(
          summary: 'Ты ищешь ясность и смысл в действиях.',
          advice: 'На неделю — введи «1 тихий час» без уведомлений.',
          archetype: 'Практик',
          stage: 'Сбор ресурсов',
        );
        await _saveProfile(advice, raw);
        return advice;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content =
          (((data['choices'] as List).first as Map)['message']
                  as Map)['content']
              as String? ??
          '{}';

      final jsonStr = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final obj = jsonDecode(jsonStr) as Map<String, dynamic>;

      final advice = DeepFocusAdvice(
        summary: (obj['summary'] ?? '').toString(),
        advice: (obj['advice'] ?? '').toString(),
        archetype: (obj['archetype'] ?? '').toString(),
        stage: (obj['stage'] ?? '').toString(),
      );

      await _saveProfile(advice, raw);
      return advice;
    } catch (e) {
      _log('error: $e');
      final advice = DeepFocusAdvice(
        summary: 'Ты стремишься к стабильности и контролю.',
        advice: 'На неделю — веди короткую заметку: 3 строки в конце дня.',
        archetype: 'Контролёр',
        stage: 'Стабилизация',
      );
      await _saveProfile(advice, raw);
      return advice;
    }
  }

  static Future<void> _saveProfile(
    DeepFocusAdvice a,
    DeepFocusInputRaw raw,
  ) async {
    final profile = DeepFocusResult(
      archetype: a.archetype,
      stage: a.stage,
      summary: a.summary,
      advice: a.advice,
      createdAt: DateTime.now(),
      raw: raw,
    );
    await ProfileService().save(profile);
  }
}
