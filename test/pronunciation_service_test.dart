import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vocab/src/data/repositories/ai_settings_repository.dart';
import 'package:vocab/src/data/repositories/pronunciation_settings_repository.dart';
import 'package:vocab/src/infrastructure/pronunciation/pronunciation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('builds Merriam-Webster audio URLs using the documented rules', () {
    expect(
      DictionaryPronunciationService.audioUri('pajama02').path,
      '/audio/prons/en/us/mp3/p/pajama02.mp3',
    );
    expect(
      DictionaryPronunciationService.audioUri('bixdod04').path,
      '/audio/prons/en/us/mp3/bix/bixdod04.mp3',
    );
    expect(
      DictionaryPronunciationService.audioUri('ggtest01').path,
      '/audio/prons/en/us/mp3/gg/ggtest01.mp3',
    );
    expect(
      DictionaryPronunciationService.audioUri('3d000001').path,
      '/audio/prons/en/us/mp3/number/3d000001.mp3',
    );
  });

  test('downloads once and reuses the local pronunciation cache', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'vocab-pronunciation-test-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));

    final secretStore = MemoryAiSecretStore();
    final settings = PronunciationSettingsRepository(secretStore);
    await settings.saveApiKey('test-key');
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      if (request.url.host == 'www.dictionaryapi.com') {
        expect(request.url.queryParameters['key'], 'test-key');
        return http.Response(
          jsonEncode([
            {
              'hwi': {
                'prs': [
                  {
                    'sound': {'audio': 'nuance01'},
                  },
                ],
              },
            },
          ]),
          200,
        );
      }
      expect(request.url.path, '/audio/prons/en/us/mp3/n/nuance01.mp3');
      return http.Response.bytes([1, 2, 3, 4], 200);
    });
    final player = _FakeAudioPlayer();
    final service = DictionaryPronunciationService(
      systemSpeech: _FakeSpeech(),
      settingsRepository: settings,
      client: client,
      player: player,
      cacheDirectory: () async => temporaryDirectory,
    );

    await service.play('Nuance');
    await service.play(' nuance ');

    expect(requests, hasLength(2));
    expect(player.playedPaths, hasLength(2));
    expect(player.playedPaths.first, player.playedPaths.last);
    expect(await File(player.playedPaths.first).readAsBytes(), [1, 2, 3, 4]);
    await service.dispose();
  });

  test(
    'no key uses system speech without HTTP or cache; key takes priority',
    () async {
      final directory = await Directory.systemTemp.createTemp('vocab-tts-');
      addTearDown(() => directory.delete(recursive: true));
      final secrets = MemoryAiSecretStore();
      final settings = PronunciationSettingsRepository(secrets);
      final speech = _FakeSpeech();
      final requests = <Uri>[];
      final service = DictionaryPronunciationService(
        settingsRepository: settings,
        systemSpeech: speech,
        player: _FakeAudioPlayer(),
        cacheDirectory: () async => directory,
        client: MockClient((request) async {
          requests.add(request.url);
          if (request.url.host == 'www.dictionaryapi.com') {
            return http.Response('[{"sound":{"audio":"test01"}}]', 200);
          }
          return http.Response.bytes([1], 200);
        }),
      );
      addTearDown(service.dispose);
      await service.play(' TEST ');
      expect(speech.words, ['test']);
      expect(requests, isEmpty);
      expect(await directory.list().toList(), isEmpty);
      await settings.saveApiKey('key');
      await service.play('test');
      await service.play('test');
      expect(requests, hasLength(2));
      expect(speech.words, ['test']);
      await service.play('british', accent: PronunciationAccent.british);
      expect(requests, hasLength(2));
      expect(speech.accents.last, PronunciationAccent.british);
      expect(speech.words.last, 'british');
      await secrets.write('pronunciation.merriam_webster.api_key', '');
      await service.play('test');
      expect(speech.words, ['test', 'british', 'test']);
      expect(requests, hasLength(2));
    },
  );

  for (final status in [401, 429, 500, 200]) {
    test(
      'MW $status or missing recording falls back to system speech',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'vocab-fallback-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final settings = PronunciationSettingsRepository(MemoryAiSecretStore());
        await settings.saveApiKey('key');
        final speech = _FakeSpeech();
        final service = DictionaryPronunciationService(
          settingsRepository: settings,
          systemSpeech: speech,
          player: _FakeAudioPlayer(),
          cacheDirectory: () async => directory,
          client: MockClient((request) async {
            expect(request.url.host, 'www.dictionaryapi.com');
            return http.Response('[]', status);
          }),
        );
        addTearDown(service.dispose);
        await service.play('hello');
        expect(speech.words, ['hello']);
      },
    );
  }

  test('system speech selects English voice and awaits completion', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('flutter_tts');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getVoices') {
            return [
              {'name': 'Online', 'locale': 'en-US', 'network_required': '1'},
              {'name': 'English', 'locale': 'en-US', 'network_required': '0'},
            ];
          }
          return 1;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final service = SystemPronunciationService();
    await service.play('hello');
    expect(calls.map((c) => c.method), [
      'stop',
      'getVoices',
      'setVoice',
      'awaitSpeakCompletion',
      'speak',
    ]);
    expect(calls[2].arguments['name'], 'English');
    expect(calls.last.arguments, 'hello');
    await service.dispose();
  });

  test('British speech can use a system-provided network voice', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('flutter_tts');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getVoices') {
            return [
              {
                'name': 'US offline',
                'locale': 'en-US',
                'network_required': '0',
              },
              {
                'name': 'UK network',
                'locale': 'en-GB',
                'network_required': '1',
              },
            ];
          }
          return 1;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final service = SystemPronunciationService();
    await service.play('schedule', accent: PronunciationAccent.british);
    final setVoice = calls.singleWhere((call) => call.method == 'setVoice');
    expect(setVoice.arguments['name'], 'UK network');
    expect(calls.last.method, 'speak');
    await service.dispose();
  });

  test('British speech does not substitute an American voice', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('flutter_tts');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getVoices') {
            return [
              {
                'name': 'US offline',
                'locale': 'en-US',
                'network_required': '0',
              },
            ];
          }
          return 1;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final service = SystemPronunciationService();
    await expectLater(
      service.play('schedule', accent: PronunciationAccent.british),
      throwsA(
        isA<PronunciationException>().having(
          (error) => error.message,
          'message',
          contains('英式英文离线语音包'),
        ),
      ),
    );
    expect(calls.where((call) => call.method == 'setVoice'), isEmpty);
    expect(calls.where((call) => call.method == 'speak'), isEmpty);
    await service.dispose();
  });

  test('missing English voice gives installation guidance', () async {
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'getVoices' ? [] : 1,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final service = SystemPronunciationService();
    await expectLater(
      service.play('hello'),
      throwsA(
        isA<PronunciationException>().having(
          (e) => e.message,
          'message',
          contains('英文离线语音包'),
        ),
      ),
    );
    await service.dispose();
  });
}

class _FakeSpeech implements PronunciationService {
  final words = <String>[];
  final accents = <PronunciationAccent>[];
  @override
  Future<void> play(
    String term, {
    PronunciationAccent accent = PronunciationAccent.automatic,
  }) async {
    words.add(term);
    accents.add(accent);
  }

  @override
  Future<void> dispose() async {}
}

class _FakeAudioPlayer implements PronunciationAudioPlayer {
  final List<String> playedPaths = [];

  @override
  Future<void> playFile(String path) async {
    playedPaths.add(path);
  }

  @override
  Future<void> dispose() async {}
}
