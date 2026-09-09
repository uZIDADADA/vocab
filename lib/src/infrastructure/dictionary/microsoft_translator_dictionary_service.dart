import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/repositories/translator_settings_repository.dart';
import 'dictionary_service.dart';

class MicrosoftTranslatorDictionaryService implements DictionaryService {
  MicrosoftTranslatorDictionaryService({
    required this.settingsRepository,
    http.Client? client,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const _host = 'api.cognitive.microsofttranslator.com';
  static const _source = 'Microsoft Translator';
  static const _timeout = Duration(seconds: 12);

  final TranslatorSettingsRepository settingsRepository;
  final http.Client _client;
  final bool _ownsClient;

  @override
  Future<DictionaryEntry?> lookup(String term) async {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final translations = await _dictionaryLookup(
      normalized,
      from: 'en',
      to: 'zh-Hans',
    );
    if (translations.isNotEmpty) {
      final definitions = translations
          .map(
            (item) => [
              if (item.partOfSpeech != null) item.partOfSpeech!,
              item.text,
            ].join(' '),
          )
          .toSet()
          .take(8)
          .join('\n');
      return DictionaryEntry(
        term: normalized,
        senses: const [],
        source: _source,
        chineseDefinition: definitions,
        chineseSource: _source,
        partOfSpeech: translations
            .map((item) => item.partOfSpeech)
            .whereType<String>()
            .toSet()
            .join(' / '),
      );
    }

    final translation = await _translate(normalized, from: 'en', to: 'zh-Hans');
    if (translation == null) return null;
    return DictionaryEntry(
      term: normalized,
      senses: const [],
      source: _source,
      chineseDefinition: translation,
      chineseSource: _source,
    );
  }

  @override
  Future<List<DictionaryMatch>> searchChinese(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];
    final translations = await _dictionaryLookup(
      normalized,
      from: 'zh-Hans',
      to: 'en',
    );
    if (translations.isNotEmpty) {
      return List.unmodifiable(
        translations
            .take(20)
            .map(
              (item) => DictionaryMatch(
                term: item.text,
                chineseDefinition: [
                  if (item.partOfSpeech != null) item.partOfSpeech!,
                  if (item.backTranslations.isNotEmpty)
                    item.backTranslations.take(3).join('；')
                  else
                    normalized,
                ].join(' '),
              ),
            ),
      );
    }
    final translation = await _translate(normalized, from: 'zh-Hans', to: 'en');
    if (translation == null) return const [];
    return [DictionaryMatch(term: translation, chineseDefinition: normalized)];
  }

  Future<List<_TranslationCandidate>> _dictionaryLookup(
    String text, {
    required String from,
    required String to,
  }) async {
    final response = await _post(
      '/dictionary/lookup',
      query: {'api-version': '3.0', 'from': from, 'to': to},
      text: text,
    );
    final root = _decodeList(response.body);
    if (root.isEmpty) return const [];
    final translations = root.first['translations'];
    if (translations is! List) return const [];
    final result = <_TranslationCandidate>[];
    final seen = <String>{};
    for (final value in translations) {
      if (value is! Map) continue;
      final item = Map<String, dynamic>.from(value);
      final target = (item['displayTarget'] ?? item['normalizedTarget'])
          ?.toString()
          .trim();
      if (target == null || target.isEmpty || !seen.add(target.toLowerCase())) {
        continue;
      }
      final backTranslations = <String>[];
      if (item['backTranslations'] case final List<dynamic> backs) {
        for (final back in backs) {
          if (back is! Map) continue;
          final value = (back['displayText'] ?? back['normalizedText'])
              ?.toString()
              .trim();
          if (value != null && value.isNotEmpty) backTranslations.add(value);
        }
      }
      result.add(
        _TranslationCandidate(
          text: target,
          partOfSpeech: _partOfSpeech(item['posTag']?.toString()),
          backTranslations: List.unmodifiable(backTranslations),
        ),
      );
    }
    return List.unmodifiable(result);
  }

  Future<String?> _translate(
    String text, {
    required String from,
    required String to,
  }) async {
    final response = await _post(
      '/translate',
      query: {'api-version': '3.0', 'from': from, 'to': to},
      text: text,
    );
    final root = _decodeList(response.body);
    if (root.isEmpty || root.first['translations'] is! List) return null;
    final translations = root.first['translations'] as List;
    if (translations.isEmpty || translations.first is! Map) return null;
    final translated = (translations.first as Map)['text']?.toString().trim();
    return translated == null || translated.isEmpty ? null : translated;
  }

  Future<http.Response> _post(
    String path, {
    required Map<String, String> query,
    required String text,
  }) async {
    final settings = await settingsRepository.load();
    if (!settings.isConfigured) {
      throw const DictionaryServiceException(
        DictionaryFailureKind.notConfigured,
      );
    }
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Ocp-Apim-Subscription-Key': settings.apiKey!,
    };
    final region = settings.region;
    if (region != null) {
      headers['Ocp-Apim-Subscription-Region'] = region;
    }
    try {
      final response = await _client
          .post(
            Uri.https(_host, path, query),
            headers: headers,
            body: jsonEncode([
              {'Text': text},
            ]),
          )
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const DictionaryServiceException(
          DictionaryFailureKind.authentication,
        );
      }
      if (response.statusCode == 429) {
        throw const DictionaryServiceException(
          DictionaryFailureKind.rateLimited,
        );
      }
      throw const DictionaryServiceException(DictionaryFailureKind.service);
    } on DictionaryServiceException {
      rethrow;
    } on TimeoutException {
      throw const DictionaryServiceException(DictionaryFailureKind.network);
    } on http.ClientException {
      throw const DictionaryServiceException(DictionaryFailureKind.network);
    } on SocketException {
      throw const DictionaryServiceException(DictionaryFailureKind.network);
    }
  }

  List<Map<String, dynamic>> _decodeList(String body) {
    try {
      final value = jsonDecode(body);
      if (value is! List) throw const FormatException();
      return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
    } on FormatException {
      throw const DictionaryServiceException(DictionaryFailureKind.service);
    }
  }

  @override
  Future<void> close() async {
    if (_ownsClient) _client.close();
  }
}

class _TranslationCandidate {
  const _TranslationCandidate({
    required this.text,
    required this.partOfSpeech,
    required this.backTranslations,
  });

  final String text;
  final String? partOfSpeech;
  final List<String> backTranslations;
}

String? _partOfSpeech(String? tag) => switch (tag?.toUpperCase()) {
  'NOUN' => 'n.',
  'VERB' => 'v.',
  'ADJ' => 'adj.',
  'ADV' => 'adv.',
  'PRON' => 'pron.',
  'PREP' => 'prep.',
  _ => null,
};

Future<void> removeLegacyOfflineDictionaryCache({
  Future<Directory> Function()? supportDirectory,
}) async {
  final root = await (supportDirectory ?? getApplicationSupportDirectory)();
  final directory = Directory(p.join(root.path, 'dictionary'));
  for (final name in const [
    'oewn-2025-v2.3.2.sqlite',
    'oewn-2025-v2.3.2.sqlite.tmp',
    'ecdict-core-v1.sqlite',
    'ecdict-core-v1.sqlite.tmp',
  ]) {
    final file = File(p.join(directory.path, name));
    if (await file.exists()) await file.delete();
  }
  if (await directory.exists() && await directory.list().isEmpty) {
    await directory.delete();
  }
}
