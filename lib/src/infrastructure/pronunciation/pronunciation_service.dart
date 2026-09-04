import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/repositories/pronunciation_settings_repository.dart';

abstract interface class PronunciationService {
  Future<void> play(String term);

  Future<void> dispose();
}

abstract interface class PronunciationAudioPlayer {
  Future<void> playFile(String path);

  Future<void> dispose();
}

class JustAudioPronunciationPlayer implements PronunciationAudioPlayer {
  JustAudioPronunciationPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> playFile(String path) async {
    await _player.stop();
    await _player.setFilePath(path);
    await _player.play();
  }

  @override
  Future<void> dispose() => _player.dispose();
}

class PronunciationException implements Exception {
  const PronunciationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MerriamWebsterPronunciationService implements PronunciationService {
  MerriamWebsterPronunciationService({
    required this.settingsRepository,
    http.Client? client,
    PronunciationAudioPlayer? player,
    Future<Directory> Function()? cacheDirectory,
    this.maxCacheBytes = 50 * 1024 * 1024,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _player = player ?? JustAudioPronunciationPlayer(),
       _cacheDirectory = cacheDirectory ?? _defaultCacheDirectory;

  static const _dictionaryHost = 'www.dictionaryapi.com';
  static const _mediaHost = 'media.merriam-webster.com';
  static const _maxAudioBytes = 2 * 1024 * 1024;

  final PronunciationSettingsRepository settingsRepository;
  final http.Client _client;
  final bool _ownsClient;
  final PronunciationAudioPlayer _player;
  final Future<Directory> Function() _cacheDirectory;
  final int maxCacheBytes;

  @override
  Future<void> play(String term) async {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw const PronunciationException('单词不能为空。');
    }

    final directory = await _ensureCacheDirectory();
    final cachedFile = File(
      p.join(directory.path, '${_cacheKey(normalized)}.mp3'),
    );
    if (await cachedFile.exists() && await cachedFile.length() > 0) {
      await cachedFile.setLastModified(DateTime.now());
      await _player.playFile(cachedFile.path);
      return;
    }

    final apiKey = await settingsRepository.loadApiKey();
    if (apiKey == null) {
      throw const PronunciationException(
        '请先在“我的”页面配置 Merriam-Webster API Key。',
      );
    }

    final audioBase = await _lookupAudioBase(normalized, apiKey);
    final audioBytes = await _downloadAudio(audioUri(audioBase));
    await _writeAtomically(cachedFile, audioBytes);
    await _trimCache(directory, keepPath: cachedFile.path);
    await _player.playFile(cachedFile.path);
  }

  Future<String> _lookupAudioBase(String term, String apiKey) async {
    final endpoint = Uri(
      scheme: 'https',
      host: _dictionaryHost,
      pathSegments: ['api', 'v3', 'references', 'collegiate', 'json', term],
      queryParameters: {'key': apiKey},
    );

    late final http.Response response;
    try {
      response = await _client
          .get(endpoint)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const PronunciationException('词典查询超时，请检查网络后重试。');
    } on http.ClientException catch (error) {
      throw PronunciationException('词典查询失败：${error.message}');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const PronunciationException('Merriam-Webster API Key 无效或没有权限。');
    }
    if (response.statusCode == 429) {
      throw const PronunciationException('Merriam-Webster 今日查询额度已用完。');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PronunciationException(
        'Merriam-Webster 查询失败（HTTP ${response.statusCode}）。',
      );
    }

    final Object? payload;
    try {
      payload = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const PronunciationException('词典返回了无法解析的数据。');
    }
    final audioBase = findAudioBase(payload);
    if (audioBase == null) {
      throw PronunciationException('Merriam-Webster 暂无“$term”的真人录音。');
    }
    return audioBase;
  }

  Future<List<int>> _downloadAudio(Uri uri) async {
    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const PronunciationException('发音下载超时，请稍后重试。');
    } on http.ClientException catch (error) {
      throw PronunciationException('发音下载失败：${error.message}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PronunciationException('发音下载失败（HTTP ${response.statusCode}）。');
    }
    if (response.bodyBytes.isEmpty) {
      throw const PronunciationException('发音文件为空。');
    }
    if (response.bodyBytes.length > _maxAudioBytes) {
      throw const PronunciationException('发音文件大小异常，已停止下载。');
    }
    return response.bodyBytes;
  }

  static String? findAudioBase(Object? value) {
    if (value is Map) {
      final sound = value['sound'];
      if (sound is Map && sound['audio'] is String) {
        final audio = (sound['audio'] as String).trim();
        if (audio.isNotEmpty) return audio;
      }
      for (final child in value.values) {
        final result = findAudioBase(child);
        if (result != null) return result;
      }
    } else if (value is List) {
      for (final child in value) {
        final result = findAudioBase(child);
        if (result != null) return result;
      }
    }
    return null;
  }

  static Uri audioUri(String audioBase) {
    final audio = audioBase.trim();
    if (audio.isEmpty || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(audio)) {
      throw const PronunciationException('词典返回了无效的音频标识。');
    }
    final lower = audio.toLowerCase();
    final subdirectory = lower.startsWith('bix')
        ? 'bix'
        : lower.startsWith('gg')
        ? 'gg'
        : RegExp(r'^[a-z]').hasMatch(lower)
        ? lower[0]
        : 'number';
    return Uri(
      scheme: 'https',
      host: _mediaHost,
      pathSegments: [
        'audio',
        'prons',
        'en',
        'us',
        'mp3',
        subdirectory,
        '$audio.mp3',
      ],
    );
  }

  static String _cacheKey(String term) {
    return sha256.convert(utf8.encode(term)).toString();
  }

  static Future<Directory> _defaultCacheDirectory() async {
    final root = await getTemporaryDirectory();
    return Directory(p.join(root.path, 'pronunciation', 'merriam-webster-v1'));
  }

  Future<Directory> _ensureCacheDirectory() async {
    final directory = await _cacheDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<void> _writeAtomically(File destination, List<int> bytes) async {
    final temporary = File('${destination.path}.download');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(destination.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _trimCache(
    Directory directory, {
    required String keepPath,
  }) async {
    final files = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.mp3'))
        .cast<File>()
        .toList();
    final entries = await Future.wait(
      files.map((file) async => (file: file, stat: await file.stat())),
    );
    var totalBytes = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.stat.size,
    );
    entries.sort(
      (left, right) => left.stat.modified.compareTo(right.stat.modified),
    );
    for (final entry in entries) {
      if (totalBytes <= maxCacheBytes) break;
      if (entry.file.path == keepPath) continue;
      await entry.file.delete();
      totalBytes -= entry.stat.size;
    }
  }

  @override
  Future<void> dispose() async {
    if (_ownsClient) _client.close();
    await _player.dispose();
  }
}
