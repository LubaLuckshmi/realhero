import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'domain.dart';
import 'easy_flow.dart';

class LeiaException implements Exception {
  final String message;
  final String code;
  final bool retryable;
  const LeiaException(
    this.message, {
    this.code = 'unknown',
    this.retryable = false,
  });
  @override
  String toString() => message;
}

class LeiaHttpResponse {
  final int statusCode;
  final String body;
  const LeiaHttpResponse(this.statusCode, this.body);
}

typedef LeiaTransport =
    Future<LeiaHttpResponse> Function(
      Uri uri,
      Map<String, String> headers,
      String body,
    );

/// The Android client talks to the user's RealHero server. It never has an
/// OpenAI credential, never calls a model directly, and never substitutes demo
/// content when the connection fails.
class LeiaClient {
  final Duration timeout;
  final LeiaTransport? transport;
  final HttpClient? _httpClient;
  LeiaClient({
    this.timeout = const Duration(seconds: 70),
    this.transport,
    HttpClient? httpClient,
  }) : _httpClient = httpClient;

  Future<Map<String, dynamic>> respond({
    required AppState state,
    required String message,
    String operation = 'plan',
  }) async {
    if (state.isDemo) {
      throw const LeiaException(
        'В деморежиме используются только явно обозначенные демонстрационные ответы.',
        code: 'demo_mode',
      );
    }
    if (!state.settings.configured) {
      throw const LeiaException(
        'Подключи сервер RealHero в профиле. Цель и разговор уже сохранены.',
        code: 'not_configured',
      );
    }
    if (state.settings.accessToken.startsWith('sk-')) {
      throw const LeiaException(
        'OpenAI API-ключ нельзя передавать приложению. Укажи токен доступа RealHero.',
        code: 'invalid_token',
      );
    }
    final base = Uri.tryParse(state.settings.url);
    if (base == null ||
        !base.hasAuthority ||
        !['https', 'http'].contains(base.scheme) ||
        base.userInfo.isNotEmpty) {
      throw const LeiaException(
        'Проверь адрес сервера в профиле.',
        code: 'invalid_url',
      );
    }
    final uri = base.replace(
      path: '${base.path.replaceAll(RegExp(r'/+$'), '')}/v1/leia',
      query: null,
      fragment: null,
    );
    final headers = {
      'content-type': 'application/json; charset=utf-8',
      'accept': 'application/json',
      'authorization': 'Bearer ${state.settings.accessToken}',
    };
    final body = jsonEncode({
      'version': 1,
      'operation': operation,
      'message': message,
      'context': {...state.toJson(includeSettings: false), 'interaction': easyInteraction},
    });
    try {
      final response =
          await (transport != null
                  ? transport!(uri, headers, body)
                  : _send(uri, headers, body))
              .timeout(timeout);
      Map<String, dynamic> decoded;
      try {
        decoded = jsonObject(jsonDecode(response.body));
      } catch (_) {
        if (response.statusCode >= 400) {
          throw _statusError(response.statusCode, {});
        }
        throw const LeiaException(
          'Сервер вернул нечитаемый ответ. Данные сохранены; повтори запрос.',
          code: 'invalid_response',
          retryable: true,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _statusError(response.statusCode, decoded);
      }
      if (decoded['reply'] is! String ||
          (decoded['mission'] != null && decoded['mission'] is! Map)) {
        throw const LeiaException(
          'Ответ Леи неполный. Данные сохранены; повтори запрос.',
          code: 'invalid_response',
          retryable: true,
        );
      }
      return decoded;
    } on LeiaException {
      rethrow;
    } on TimeoutException {
      throw const LeiaException(
        'Лея не успела ответить. Цель и изменения сохранены. Можно повторить запрос.',
        code: 'timeout',
        retryable: true,
      );
    } on SocketException {
      throw const LeiaException(
        'Сервер недоступен. Проверь интернет и адрес подключения. Твои данные остаются на устройстве.',
        code: 'network',
        retryable: true,
      );
    } on HandshakeException {
      throw const LeiaException(
        'Не удалось установить защищённое соединение. Проверь HTTPS-сертификат сервера.',
        code: 'tls',
        retryable: true,
      );
    } on HttpException {
      throw const LeiaException(
        'Соединение прервалось. Изменения сохранены; повтори запрос.',
        code: 'connection',
        retryable: true,
      );
    }
  }

  Future<LeiaHttpResponse> _send(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    final client = _httpClient ?? HttpClient();
    client.connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.postUrl(uri);
      request.followRedirects =
          false; // Never forward the bearer token to another host.
      headers.forEach(request.headers.set);
      request.add(utf8.encode(body));
      final response = await request.close();
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > 1024 * 1024) {
          throw const LeiaException(
            'Ответ сервера слишком большой. Повтори запрос.',
            code: 'oversized_response',
            retryable: true,
          );
        }
      }
      return LeiaHttpResponse(response.statusCode, utf8.decode(bytes));
    } finally {
      if (_httpClient == null) client.close(force: true);
    }
  }

  LeiaException _statusError(int status, Map<String, dynamic> decoded) {
    final error = jsonObject(decoded['error']);
    final code = jsonString(
      error['code'],
      jsonString(decoded['code'], 'http_$status'),
    );
    if (code == 'budget_not_approved' || code == 'budget_exhausted') {
      return LeiaException(
        code == 'budget_not_approved'
            ? 'Тестовый бюджет ещё не согласован. Сервер не выполняет платные запросы. Цель сохранена.'
            : 'Тестовый бюджет исчерпан. Платные запросы остановлены; сохранённые миссии доступны.',
        code: code,
      );
    }
    if (status == 401 || status == 403) {
      return LeiaException(
        'Сервер не принял токен доступа. Проверь подключение в профиле.',
        code: code,
      );
    }
    if (status == 429) {
      return LeiaException(
        'Лея временно занята. Подожди немного и повтори запрос.',
        code: code,
        retryable: true,
      );
    }
    if (status == 413) {
      return LeiaException(
        'Контекст слишком большой для одного запроса. Сократи последний текст и повтори.',
        code: code,
      );
    }
    if (status == 400 || status == 422) {
      return LeiaException(
        'Сервер не смог принять запрос. Проверь цель и повтори. Все введённые данные сохранены.',
        code: code,
        retryable: true,
      );
    }
    if (code == 'api_key_missing' ||
        code == 'provider_not_configured' ||
        code == 'ai_not_configured') {
      return LeiaException(
        'ИИ пока не подключён на сервере. Цель сохранена; повтори запрос после подключения.',
        code: code,
        retryable: true,
      );
    }
    return LeiaException(
      'Лея сейчас недоступна. Данные сохранены; можно повторить запрос позже.',
      code: code,
      retryable: status >= 500,
    );
  }
}
