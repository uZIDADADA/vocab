import 'dart:convert';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vocab/src/domain/learning_models.dart';
import 'package:vocab/src/infrastructure/sync/kiss_worker_vocabulary_service.dart';

void main() {
  const settings = KissWorkerSettings(
    endpoint: 'https://example.com',
    syncKey: 'secret',
    encryptionPassphrase: 'passphrase',
  );
  const local = [
    ImportedVocabularyCandidate(term: 'new', definition: '新'),
    ImportedVocabularyCandidate(term: ' OLD ', definition: '本机'),
  ];

  test(
    'encrypted upload preserves remote metadata and is idempotent',
    () async {
      var record = <String, dynamic>{
        'key': 'kiss-words.json',
        'value': await _encryptedEnvelope(
          jsonEncode({
            'old': {
              'definition': '云端',
              'unknown': [1, 2],
            },
          }),
          'passphrase',
        ),
        'updateAt': 1700000000000,
      };
      var writes = 0;
      final service = KissWorkerVocabularyService(
        client: MockClient((request) async {
          final input = jsonDecode(request.body) as Map<String, dynamic>;
          if (input['updateAt'] > record['updateAt']) {
            expect(request.body, isNot(contains('本机')));
            expect(request.body, isNot(contains('definition')));
            record = input;
            writes++;
          }
          return http.Response(jsonEncode(record), 200);
        }),
      );
      expect(await service.uploadWords(settings, local), 1);
      final book = jsonDecode(
        await KissWorkerVocabularyService.decryptEnvelope(
          record['value'],
          'passphrase',
        ),
      );
      expect(book['old'], {
        'definition': '云端',
        'unknown': [1, 2],
      });
      expect(book['new']['definition'], '新');
      expect(await service.uploadWords(settings, local), 0);
      expect(writes, 1);
    },
  );

  test('merges a newer conflicting response before retrying', () async {
    var calls = 0;
    final initial = await _encryptedEnvelope('{}', 'passphrase');
    final newer = await _encryptedEnvelope(
      '{"browser":{"definition":"浏览器新增"}}',
      'passphrase',
    );
    final service = KissWorkerVocabularyService(
      client: MockClient((request) async {
        calls++;
        final input = jsonDecode(request.body);
        if (calls <= 2) {
          return http.Response(
            jsonEncode({
              'key': 'kiss-words.json',
              'value': calls == 1 ? initial : newer,
              'updateAt': 1700000000000 + calls,
            }),
            200,
          );
        }
        final book = jsonDecode(
          await KissWorkerVocabularyService.decryptEnvelope(
            input['value'],
            'passphrase',
          ),
        );
        expect(book.keys, containsAll(['browser', 'new', 'OLD']));
        return http.Response(jsonEncode(input), 200);
      }),
    );
    expect(await service.uploadWords(settings, local), 2);
    expect(calls, 3);
  });

  test('incorrect passphrase prevents an upload request', () async {
    var calls = 0;
    final envelope = await _encryptedEnvelope('{}', 'different');
    final service = KissWorkerVocabularyService(
      client: MockClient((request) async {
        calls++;
        return http.Response(
          jsonEncode({
            'key': 'kiss-words.json',
            'value': envelope,
            'updateAt': 1700000000000,
          }),
          200,
        );
      }),
    );
    await expectLater(
      service.uploadWords(settings, local),
      throwsA(isA<KissWorkerException>()),
    );
    expect(calls, 1);
  });

  test(
    'reads, decrypts, and parses the KISS word book without writing remotely',
    () async {
      final envelope = await _encryptedEnvelope(
        jsonEncode({
          'nuance': {
            'phonetic': '/ˈnuːɑːns/',
            'definition': '细微差别',
            'examples': ['There is a subtle nuance.'],
            'timestamp': 1700000000000,
          },
        }),
        'passphrase',
      );
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://example.workers.dev/sync');
        final expectedToken = hashes.sha256
            .convert(utf8.encode('sync-secretKISS-Translator-SYNC'))
            .toString();
        expect(request.headers['authorization'], 'Bearer $expectedToken');
        expect(jsonDecode(request.body), {
          'key': 'kiss-words.json',
          'value': '{}',
          'updateAt': 0,
        });
        return http.Response(
          jsonEncode({
            'key': 'kiss-words.json',
            'value': envelope,
            'updateAt': 1700000000000,
          }),
          200,
        );
      });
      final service = KissWorkerVocabularyService(client: client);

      final words = await service.fetchWords(
        const KissWorkerSettings(
          endpoint: 'https://example.workers.dev/',
          syncKey: 'sync-secret',
          encryptionPassphrase: 'passphrase',
        ),
      );

      expect(words, hasLength(1));
      expect(words.single.term, 'nuance');
      expect(words.single.definition, '细微差别');
      expect(words.single.examples, ['There is a subtle nuance.']);
      expect(words.single.sourceTimestamp, isNotNull);
    },
  );

  test('rejects an incorrect encryption passphrase', () async {
    final envelope = await _encryptedEnvelope('{}', 'correct');
    final service = KissWorkerVocabularyService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'key': 'kiss-words.json', 'value': envelope}),
          200,
        ),
      ),
    );

    expect(
      () => service.fetchWords(
        const KissWorkerSettings(
          endpoint: 'https://example.workers.dev',
          syncKey: 'sync-secret',
          encryptionPassphrase: 'wrong',
        ),
      ),
      throwsA(
        isA<KissWorkerException>().having(
          (error) => error.message,
          'message',
          contains('解密失败'),
        ),
      ),
    );
  });
}

Future<String> _encryptedEnvelope(String plaintext, String passphrase) async {
  final salt = List<int>.generate(16, (index) => index + 1);
  final nonce = List<int>.generate(12, (index) => index + 20);
  final key = await Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  ).deriveKey(secretKey: SecretKey(utf8.encode(passphrase)), nonce: salt);
  final secretBox = await AesGcm.with256bits().encrypt(
    utf8.encode(plaintext),
    secretKey: key,
    nonce: nonce,
  );
  return jsonEncode({
    'encrypted': true,
    'version': 1,
    'alg': 'AES-GCM',
    'kdf': 'PBKDF2-SHA-256',
    'iterations': 100000,
    'salt': base64Encode(salt),
    'iv': base64Encode(nonce),
    'data': base64Encode([...secretBox.cipherText, ...secretBox.mac.bytes]),
  });
}
