import 'dart:convert';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vocab/src/infrastructure/sync/kiss_worker_vocabulary_service.dart';

void main() {
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
