import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vocab/src/domain/coach_models.dart';
import 'package:vocab/src/infrastructure/ai/ai_chat_provider.dart';

void main() {
  test('sends OpenAI-compatible chat history and reads the reply', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
      );
      expect(request.headers['authorization'], 'Bearer test-key');

      final body = jsonDecode(request.body) as Map<String, Object?>;
      expect(body['model'], 'gemini-3.1-flash-lite');
      final messages = body['messages']! as List<Object?>;
      expect(messages, hasLength(3));
      expect((messages[1] as Map<String, Object?>)['role'], 'assistant');
      expect((messages[2] as Map<String, Object?>)['role'], 'user');

      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'Nice to meet you!'},
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final provider = OpenAiCompatibleChatProvider(client: client);

    final reply = await provider.complete(
      config: const AiProviderConfig.gemini(),
      apiKey: 'test-key',
      messages: const [
        CoachMessage(role: CoachRole.assistant, text: 'Hello!'),
        CoachMessage(role: CoachRole.user, text: 'Hi!'),
      ],
    );

    expect(reply, 'Nice to meet you!');
  });

  test('surfaces provider error messages', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': {'message': 'API key not valid'},
        }),
        401,
      ),
    );
    final provider = OpenAiCompatibleChatProvider(client: client);

    expect(
      () => provider.complete(
        config: const AiProviderConfig.gemini(),
        apiKey: 'bad-key',
        messages: const [CoachMessage(role: CoachRole.user, text: 'Hello')],
      ),
      throwsA(
        isA<AiChatException>().having(
          (error) => error.message,
          'message',
          contains('API key not valid'),
        ),
      ),
    );
  });

  test('uses Kimi-compatible request parameters', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://api.moonshot.cn/v1/chat/completions',
      );
      final body = jsonDecode(request.body) as Map<String, Object?>;
      expect(body['model'], 'kimi-k2.6');
      expect(body, isNot(contains('temperature')));
      expect(body['thinking'], {'type': 'disabled'});
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'Hello from Kimi!'},
            },
          ],
        }),
        200,
      );
    });
    final provider = OpenAiCompatibleChatProvider(client: client);

    final reply = await provider.complete(
      config: const AiProviderConfig.kimi(),
      apiKey: 'test-key',
      messages: const [CoachMessage(role: CoachRole.user, text: 'Hello')],
    );

    expect(reply, 'Hello from Kimi!');
  });
}
