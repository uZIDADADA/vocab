import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/coach_models.dart';
import '../local/app_database.dart';

abstract interface class AiSecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class FlutterSecureAiSecretStore implements AiSecretStore {
  FlutterSecureAiSecretStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }
}

class MemoryAiSecretStore implements AiSecretStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

class AiSettingsRepository {
  AiSettingsRepository(this._database, this._secretStore);

  static const _providerKey = 'ai.provider';
  static const _baseUrlKey = 'ai.base_url';
  static const _modelKey = 'ai.model';
  static const _apiKeySecret = 'ai.api_key';

  final AppDatabase _database;
  final AiSecretStore _secretStore;

  Future<AiChatSettings> load() async {
    final values = await Future.wait([
      _database.getSetting(_providerKey),
      _database.getSetting(_baseUrlKey),
      _database.getSetting(_modelKey),
      _secretStore.read(_apiKeySecret),
    ]);
    final defaults = const AiProviderConfig.gemini();

    return AiChatSettings(
      config: AiProviderConfig(
        kind: AiProviderKindDetails.fromStorage(values[0]),
        baseUrl: values[1]?.trim().isNotEmpty == true
            ? values[1]!.trim()
            : defaults.baseUrl,
        model: values[2]?.trim().isNotEmpty == true
            ? values[2]!.trim()
            : defaults.model,
      ),
      apiKey: values[3],
    );
  }

  Future<void> save(
    AiProviderConfig config, {
    String? replacementApiKey,
  }) async {
    await Future.wait([
      _database.setSetting(_providerKey, config.kind.storageValue),
      _database.setSetting(_baseUrlKey, config.baseUrl.trim()),
      _database.setSetting(_modelKey, config.model.trim()),
      if (replacementApiKey?.trim().isNotEmpty == true)
        _secretStore.write(_apiKeySecret, replacementApiKey!.trim()),
    ]);
  }
}
