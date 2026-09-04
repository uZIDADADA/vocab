import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vocab/src/data/repositories/ai_settings_repository.dart';
import 'package:vocab/src/data/repositories/pronunciation_settings_repository.dart';
import 'package:vocab/src/infrastructure/pronunciation/pronunciation_service.dart';

void main() {
  test('builds Merriam-Webster audio URLs using the documented rules', () {
    expect(
      MerriamWebsterPronunciationService.audioUri('pajama02').path,
      '/audio/prons/en/us/mp3/p/pajama02.mp3',
    );
    expect(
      MerriamWebsterPronunciationService.audioUri('bixdod04').path,
      '/audio/prons/en/us/mp3/bix/bixdod04.mp3',
    );
    expect(
      MerriamWebsterPronunciationService.audioUri('ggtest01').path,
      '/audio/prons/en/us/mp3/gg/ggtest01.mp3',
    );
    expect(
      MerriamWebsterPronunciationService.audioUri('3d000001').path,
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
    final service = MerriamWebsterPronunciationService(
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

  test('requires a configured API key before the first lookup', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'vocab-pronunciation-no-key-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final client = MockClient((_) async => http.Response('', 500));
    final service = MerriamWebsterPronunciationService(
      settingsRepository: PronunciationSettingsRepository(
        MemoryAiSecretStore(),
      ),
      client: client,
      player: _FakeAudioPlayer(),
      cacheDirectory: () async => temporaryDirectory,
    );

    await expectLater(
      service.play('test'),
      throwsA(
        isA<PronunciationException>().having(
          (error) => error.message,
          'message',
          contains('API Key'),
        ),
      ),
    );
    await service.dispose();
  });
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
