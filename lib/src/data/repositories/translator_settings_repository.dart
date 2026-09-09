import 'ai_settings_repository.dart';

class TranslatorSettings {
  const TranslatorSettings({required this.apiKey, required this.region});

  final String? apiKey;
  final String? region;

  bool get isConfigured => apiKey?.isNotEmpty == true;
}

class TranslatorSettingsRepository {
  TranslatorSettingsRepository(this._secretStore);

  static const _apiKeySecret = 'translator.microsoft.api_key';
  static const _regionSecret = 'translator.microsoft.region';

  final AiSecretStore _secretStore;

  Future<TranslatorSettings> load() async {
    final values = await Future.wait([
      _secretStore.read(_apiKeySecret),
      _secretStore.read(_regionSecret),
    ]);
    return TranslatorSettings(
      apiKey: _nonEmpty(values[0]),
      region: _nonEmpty(values[1]),
    );
  }

  Future<void> save({required String apiKey, String? region}) async {
    final key = apiKey.trim();
    if (key.isEmpty) throw const FormatException('API Key 不能为空。');
    await Future.wait([
      _secretStore.write(_apiKeySecret, key),
      _secretStore.write(_regionSecret, region?.trim() ?? ''),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _secretStore.write(_apiKeySecret, ''),
      _secretStore.write(_regionSecret, ''),
    ]);
  }
}

String? _nonEmpty(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
