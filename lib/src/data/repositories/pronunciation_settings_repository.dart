import 'ai_settings_repository.dart';

class PronunciationSettingsRepository {
  PronunciationSettingsRepository(this._secretStore);

  static const _apiKeySecret = 'pronunciation.merriam_webster.api_key';

  final AiSecretStore _secretStore;

  Future<String?> loadApiKey() async {
    final value = (await _secretStore.read(_apiKeySecret))?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> saveApiKey(String apiKey) async {
    final value = apiKey.trim();
    if (value.isEmpty) {
      throw const FormatException('API Key 不能为空。');
    }
    await _secretStore.write(_apiKeySecret, value);
  }
}
