import 'dart:async';
import 'dart:convert';
import 'dart:math';

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

  Future<int> uploadWords(
    KissWorkerSettings settings,
    List<ImportedVocabularyCandidate> words,
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
    final record = await _exchange(settings, '{}', 0);
    return parseWordBook(await _plaintext(record, settings));
  }

  Future<String> _plaintext(
    Map<String, dynamic> record,
    KissWorkerSettings settings,
  ) async {
    if (record['value'] == '{}') return '{}';
    try {
      return await decryptEnvelope(
        record['value'] as String,
        settings.encryptionPassphrase!,
      );
    } on SecretBoxAuthenticationError {
      throw const KissWorkerException('解密失败，请检查加密口令是否正确。');
    }
  }

  @override
  Future<int> uploadWords(
    KissWorkerSettings settings,
    List<ImportedVocabularyCandidate> words,
  ) async {
    if (words.isEmpty) return 0;
    var record = await _exchange(settings, '{}', 0);
    for (var attempt = 0; attempt < 3; attempt++) {
      final decoded = jsonDecode(await _plaintext(record, settings));
      if (decoded is! Map<String, dynamic>) {
        throw const KissWorkerException('云端生词本格式无法识别，未上传。');
      }
      final existing = decoded.keys
          .map((key) => key.trim().toLowerCase())
          .toSet();
      var added = 0;
      for (final word in words) {
        final term = word.term.trim();
        if (term.isEmpty || !existing.add(term.toLowerCase())) continue;
        decoded[term] = {
          'definition': word.definition,
          'phonetic': word.phonetic ?? '',
          'examples': word.examples,
          'timestamp':
              (word.sourceTimestamp ?? DateTime.now()).millisecondsSinceEpoch,
        };
        added++;
      }
      if (added == 0) return 0;
      final timestamp = record['updateAt'];
      if (timestamp is! int || timestamp < 0 || timestamp >= 9007199254740991) {
        throw const KissWorkerException('云端版本无法识别，未上传。');
      }
      // Increment the observed version, rather than using the device clock.
      // A concurrent newer server record is returned and merged on the next attempt.
      final version = timestamp > 0 && timestamp < 100000000000
          ? timestamp * 1000 + 1
          : timestamp + 1;
      final envelope = await encryptEnvelope(
        jsonEncode(decoded),
        settings.encryptionPassphrase!,
      );
      record = await _exchange(settings, envelope, version);
      if (record['value'] == envelope) return added;
    }
    throw const KissWorkerException('云端词库正在变化，请稍后重新上传。');
  }

  static Future<String> encryptEnvelope(
    String plaintext,
    String passphrase,
  ) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final key = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(utf8.encode(passphrase)), nonce: salt);
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(plaintext),
      secretKey: key,
    );
    return jsonEncode({
      'encrypted': true,
      'version': 1,
      'alg': 'AES-GCM',
      'kdf': 'PBKDF2-SHA-256',
      'iterations': _iterations,
      'salt': base64Encode(salt),
      'iv': base64Encode(box.nonce),
      'data': base64Encode([...box.cipherText, ...box.mac.bytes]),
    });
  }

  Future<Map<String, dynamic>> _exchange(
    KissWorkerSettings settings,
    String value,
    int updateAt,
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
              'value': value,
              'updateAt': updateAt,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on http.ClientException {
      throw const KissWorkerException('KISS-Worker 请求失败，请检查网络。');
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
      return record;
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
