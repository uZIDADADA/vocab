import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/data/repositories/ai_settings_repository.dart';
import 'package:vocab/src/data/repositories/kiss_worker_settings_repository.dart';

void main() {
  test(
    'stores the KISS endpoint and credentials in the secret store',
    () async {
      final secrets = MemoryAiSecretStore();
      final repository = KissWorkerSettingsRepository(secrets);

      await repository.save(
        endpoint: 'https://example.workers.dev/',
        replacementSyncKey: 'sync-key',
        replacementEncryptionPassphrase: 'passphrase',
      );
      final settings = await repository.load();

      expect(settings.endpoint, 'https://example.workers.dev/');
      expect(settings.syncKey, 'sync-key');
      expect(settings.encryptionPassphrase, 'passphrase');
      expect(settings.isConfigured, isTrue);
    },
  );
}
