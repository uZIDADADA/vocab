import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vocab/src/data/repositories/ai_settings_repository.dart';
import 'package:vocab/src/data/repositories/translator_settings_repository.dart';
import 'package:vocab/src/infrastructure/dictionary/dictionary_service.dart';
import 'package:vocab/src/infrastructure/dictionary/microsoft_translator_dictionary_service.dart';

void main() {
  late MemoryAiSecretStore store;
  late TranslatorSettingsRepository settings;

  setUp(() async {
    store = MemoryAiSecretStore();
    settings = TranslatorSettingsRepository(store);
    await settings.save(apiKey: 'secret-key', region: 'eastasia');
  });

  test('looks up English words with Microsoft dictionary metadata', () async {
    late http.Request captured;
    final service = MicrosoftTranslatorDictionaryService(
      settingsRepository: settings,
      client: MockClient((request) async {
        captured = request;
        return _jsonResponse([
          {
            'displaySource': 'apple',
            'translations': [
              {
                'displayTarget': '苹果',
                'posTag': 'NOUN',
                'backTranslations': [
                  {'displayText': 'apple'},
                ],
              },
              {
                'displayTarget': '苹果公司',
                'posTag': 'NOUN',
                'backTranslations': [
                  {'displayText': 'Apple'},
                ],
              },
            ],
          },
        ]);
      }),
    );

    final entry = await service.lookup(' Apple ');

    expect(entry?.term, 'apple');
    expect(entry?.chineseDefinition, 'n. 苹果\nn. 苹果公司');
    expect(entry?.partOfSpeech, 'n.');
    expect(entry?.source, 'Microsoft Translator');
    expect(captured.url.path, '/dictionary/lookup');
    expect(captured.url.queryParameters['from'], 'en');
    expect(captured.url.queryParameters['to'], 'zh-Hans');
    expect(captured.headers['Ocp-Apim-Subscription-Key'], 'secret-key');
    expect(captured.headers['Ocp-Apim-Subscription-Region'], 'eastasia');
    expect(captured.body, isNot(contains('secret-key')));
    await service.close();
  });

  test('returns English candidates for a Chinese query', () async {
    final service = MicrosoftTranslatorDictionaryService(
      settingsRepository: settings,
      client: MockClient(
        (request) async => _jsonResponse([
          {
            'translations': [
              {
                'displayTarget': 'apple',
                'posTag': 'NOUN',
                'backTranslations': [
                  {'displayText': '苹果'},
                  {'displayText': '苹果公司'},
                ],
              },
            ],
          },
        ]),
      ),
    );

    final matches = await service.searchChinese('苹果');

    expect(matches.single.term, 'apple');
    expect(matches.single.chineseDefinition, 'n. 苹果；苹果公司');
    await service.close();
  });

  test(
    'falls back to text translation when dictionary has no result',
    () async {
      var calls = 0;
      final service = MicrosoftTranslatorDictionaryService(
        settingsRepository: settings,
        client: MockClient((request) async {
          calls++;
          if (request.url.path == '/dictionary/lookup') {
            return http.Response('[{"translations":[]}]', 200);
          }
          return _jsonResponse([
            {
              'translations': [
                {'text': '追求卓越'},
              ],
            },
          ]);
        }),
      );

      final entry = await service.lookup('strive for excellence');

      expect(entry?.chineseDefinition, '追求卓越');
      expect(calls, 2);
      await service.close();
    },
  );

  test('reports missing settings and authentication failures', () async {
    await settings.clear();
    final unconfigured = MicrosoftTranslatorDictionaryService(
      settingsRepository: settings,
      client: MockClient((_) async => http.Response('', 500)),
    );
    await expectLater(
      unconfigured.lookup('apple'),
      throwsA(
        isA<DictionaryServiceException>().having(
          (error) => error.kind,
          'kind',
          DictionaryFailureKind.notConfigured,
        ),
      ),
    );

    await settings.save(apiKey: 'wrong');
    final unauthorized = MicrosoftTranslatorDictionaryService(
      settingsRepository: settings,
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    await expectLater(
      unauthorized.lookup('apple'),
      throwsA(
        isA<DictionaryServiceException>().having(
          (error) => error.kind,
          'kind',
          DictionaryFailureKind.authentication,
        ),
      ),
    );
    await unconfigured.close();
    await unauthorized.close();
  });

  test('removes only legacy generated dictionary cache', () async {
    final root = await Directory.systemTemp.createTemp('vocab-dictionary-');
    addTearDown(() => root.delete(recursive: true));
    final directory = Directory('${root.path}/dictionary')..createSync();
    for (final name in const [
      'oewn-2025-v2.3.2.sqlite',
      'ecdict-core-v1.sqlite',
    ]) {
      File('${directory.path}/$name').writeAsStringSync('cache');
    }
    final keep = File('${directory.path}/keep.txt')..writeAsStringSync('keep');

    await removeLegacyOfflineDictionaryCache(
      supportDirectory: () async => root,
    );

    expect(keep.existsSync(), isTrue);
    expect(
      File('${directory.path}/oewn-2025-v2.3.2.sqlite').existsSync(),
      isFalse,
    );
    expect(
      File('${directory.path}/ecdict-core-v1.sqlite').existsSync(),
      isFalse,
    );
  });
}

http.Response _jsonResponse(Object value, {int statusCode = 200}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(value)),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
