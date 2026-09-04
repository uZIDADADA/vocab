import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/coach_models.dart';

abstract interface class AiChatProvider {
  Future<String> complete({
    required AiProviderConfig config,
    required String apiKey,
    required List<CoachMessage> messages,
    String? systemInstruction,
  });
}

class AiChatException implements Exception {
  const AiChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenAiCompatibleChatProvider implements AiChatProvider {
  OpenAiCompatibleChatProvider({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const _systemPrompt = '''
You are Vocab, a friendly English conversation coach for a Chinese learner.
Continue the conversation naturally and ask at most one useful follow-up question.
Reply mainly in English. When the learner makes an important mistake, add one short Chinese explanation after the English reply.
Keep each turn concise and suitable for spoken practice. Never claim to have heard audio because this session is text-only.
''';

  final http.Client _client;
  final bool _ownsClient;

  @override
  Future<String> complete({
    required AiProviderConfig config,
    required String apiKey,
    required List<CoachMessage> messages,
    String? systemInstruction,
  }) async {
    final baseUrl = config.baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final endpoint = Uri.parse('$baseUrl/chat/completions');
    final requestMessages = <Map<String, String>>[
      {
        'role': 'system',
        'content': (systemInstruction ?? _systemPrompt).trim(),
      },
      for (final message in messages)
        {
          'role': message.role == CoachRole.user ? 'user' : 'assistant',
          'content': message.text,
        },
    ];

    late final http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer ${apiKey.trim()}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': config.model.trim(),
              'messages': requestMessages,
              'temperature': systemInstruction == null ? 0.7 : 0.2,
            }),
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const AiChatException('请求超时，请检查网络后重试。');
    } on http.ClientException catch (error) {
      throw AiChatException('网络请求失败：${error.message}');
    } on FormatException {
      throw const AiChatException('Base URL 格式不正确。');
    }

    final Object? payload;
    try {
      payload = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw AiChatException('服务返回了无法解析的内容（HTTP ${response.statusCode}）。');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiChatException(_readError(payload, response.statusCode));
    }

    final content = _readContent(payload);
    if (content == null || content.trim().isEmpty) {
      throw const AiChatException('模型没有返回文字内容，请换一个模型后重试。');
    }
    return content.trim();
  }

  String? _readContent(Object? payload) {
    if (payload case {'choices': final List<Object?> choices}
        when choices.isNotEmpty) {
      final first = choices.first;
      if (first case {'message': {'content': final String content}}) {
        return content;
      }
      if (first case {'message': {'content': final List<Object?> parts}}) {
        final texts = parts.whereType<Map<String, Object?>>().map(
          (part) => part['text'],
        );
        return texts.whereType<String>().join();
      }
    }
    return null;
  }

  String _readError(Object? payload, int statusCode) {
    if (payload case {'error': {'message': final String message}}) {
      return '请求失败（HTTP $statusCode）：$message';
    }
    return '请求失败（HTTP $statusCode），请检查 API Key、模型和 Base URL。';
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
