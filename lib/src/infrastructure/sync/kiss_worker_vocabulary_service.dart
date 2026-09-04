import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;

import '../../domain/learning_models.dart';

class KissWorkerSettings {
  const KissWorkerSettings({
    required this.endpoint,
    required this.syncKey,
    required this.encryptionPassphrase,
  });

  final String endpoint;
  final String? syncKey;
  final String? encryptionPassphrase;

  bool get isConfigured =>
      endpoint.trim().isNotEmpty &&
      syncKey?.trim().isNotEmpty == true &&
      encryptionPassphrase?.isNotEmpty == true;
}

abstract interface class KissVocabularyService {
  Future<List<ImportedVocabularyCandidate>> fetchWords(
    KissWorkerSettings settings,
  );

  void close();
}

class KissWorkerException implements Exception {
  const KissWorkerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class KissWorkerVocabularyService implements KissVocabularyService {
  KissWorkerVocabularyService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const _wordBookKey = 'kiss-words.json';
  static const _authorizationSalt = 'KISS-Translator-SYNC';
  static const _iterations = 100000;

  final http.Client _client;
  final bool _ownsClient;

  @override
  Future<List<ImportedVocabularyCandidate>> fetchWords(
    KissWorkerSettings settings,
  ) async {
    if (!settings.isConfigured) {
      throw const KissWorkerException('请先完整配置同步地址、同步密钥和加密口令。');
    }
    final base = Uri.tryParse(settings.endpoint.trim());
    if (base == null || base.scheme != 'https' || base.host.isEmpty) {
      throw const KissWorkerException('KISS-Worker 同步地址必须是有效的 HTTPS 地址。');
    }
    final endpoint = base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/+$'), '')}/sync',
      query: null,
      fragment: null,
    );
    final authorization = hashes.sha256
        .convert(utf8.encode('${settings.syncKey!.trim()}$_authorizationSalt'))
        .toString();

    late final http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer $authorization',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'key': _wordBookKey,
              'value': '{}',
              'updateAt': 0,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on http.ClientException catch (error) {
      throw KissWorkerException('KISS-Worker 请求失败：${error.message}');
    } on TimeoutException {
      throw const KissWorkerException('KISS-Worker 请求超时，请稍后重试。');
    } on FormatException {
      throw const KissWorkerException('KISS-Worker 同步地址格式不正确。');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw KissWorkerException(
        'KISS-Worker 返回 HTTP ${response.statusCode}，请检查同步地址和同步密钥。',
      );
    }

    try {
      final record = jsonDecode(utf8.decode(response.bodyBytes));
      if (record is! Map<String, dynamic> ||
          record['key'] != _wordBookKey ||
          record['value'] is! String) {
        throw const FormatException('Unexpected sync response');
      }
      final plaintext = await decryptEnvelope(
        record['value'] as String,
        settings.encryptionPassphrase!,
      );
      return parseWordBook(plaintext);
    } on SecretBoxAuthenticationError {
      throw const KissWorkerException('解密失败，请检查加密口令是否正确。');
    } on KissWorkerException {
      rethrow;
    } catch (_) {
      throw const KissWorkerException('云端生词本格式无法识别。');
    }
  }

  static Future<String> decryptEnvelope(
    String encodedEnvelope,
    String passphrase,
  ) async {
    final envelope = jsonDecode(encodedEnvelope);
    if (envelope is! Map<String, dynamic> ||
        envelope['encrypted'] != true ||
        envelope['version'] != 1 ||
        envelope['alg'] != 'AES-GCM' ||
        envelope['kdf'] != 'PBKDF2-SHA-256' ||
        envelope['iterations'] != _iterations) {
      throw const KissWorkerException('不支持的简约翻译加密格式。');
    }
    final salt = base64Decode(envelope['salt'] as String);
    final nonce = base64Decode(envelope['iv'] as String);
    final sealed = base64Decode(envelope['data'] as String);
    if (nonce.length != 12 || sealed.length < 17) {
      throw const FormatException('Invalid AES-GCM envelope');
    }
    final kdf = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    );
    final secretKey = await kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
    final cipherText = sealed.sublist(0, sealed.length - 16);
    final mac = Mac(sealed.sublist(sealed.length - 16));
    final clearBytes = await AesGcm.with256bits().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: secretKey,
    );
    return utf8.decode(clearBytes);
  }

  static List<ImportedVocabularyCandidate> parseWordBook(String plaintext) {
    final decoded = jsonDecode(plaintext);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Word book must be an object');
    }
    final words = <ImportedVocabularyCandidate>[];
    for (final entry in decoded.entries) {
      final term = entry.key.trim();
      if (term.isEmpty) continue;
      final metadata = entry.value;
      final map = metadata is Map<String, dynamic>
          ? metadata
          : const <String, dynamic>{};
      final examples = switch (map['examples']) {
        final List<dynamic> values =>
          values
              .map((value) => value is String ? value : jsonEncode(value))
              .where((value) => value.trim().isNotEmpty)
              .toList(growable: false),
        _ => const <String>[],
      };
      words.add(
        ImportedVocabularyCandidate(
          term: term,
          definition: map['definition'] is String
              ? map['definition'] as String
              : '',
          phonetic: map['phonetic'] is String
              ? map['phonetic'] as String
              : null,
          examples: examples,
          sourceTimestamp: _parseTimestamp(map['timestamp']),
        ),
      );
    }
    return words;
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is num) {
      final milliseconds = value < 100000000000 ? value * 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds.round());
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}
