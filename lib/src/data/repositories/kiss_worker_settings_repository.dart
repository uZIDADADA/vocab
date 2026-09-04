import '../../infrastructure/sync/kiss_worker_vocabulary_service.dart';
import 'ai_settings_repository.dart';

class KissWorkerSettingsRepository {
  KissWorkerSettingsRepository(this._secretStore);

  static const _endpointSecret = 'kiss_worker.endpoint';
  static const _syncKeySecret = 'kiss_worker.sync_key';
  static const _encryptionPassphraseSecret =
      'kiss_worker.encryption_passphrase';

  final AiSecretStore _secretStore;

  Future<KissWorkerSettings> load() async {
    final values = await Future.wait([
      _secretStore.read(_endpointSecret),
      _secretStore.read(_syncKeySecret),
      _secretStore.read(_encryptionPassphraseSecret),
    ]);
    return KissWorkerSettings(
      endpoint: values[0] ?? '',
      syncKey: values[1],
      encryptionPassphrase: values[2],
    );
  }

  Future<void> save({
    required String endpoint,
    String? replacementSyncKey,
    String? replacementEncryptionPassphrase,
  }) async {
    await Future.wait([
      _secretStore.write(_endpointSecret, endpoint.trim()),
      if (replacementSyncKey?.trim().isNotEmpty == true)
        _secretStore.write(_syncKeySecret, replacementSyncKey!.trim()),
      if (replacementEncryptionPassphrase?.isNotEmpty == true)
        _secretStore.write(
          _encryptionPassphraseSecret,
          replacementEncryptionPassphrase!,
        ),
    ]);
  }
}
