import 'package:flutter/material.dart';

import '../../data/repositories/learning_repository.dart';
import '../../data/repositories/kiss_worker_settings_repository.dart';
import '../../data/repositories/pronunciation_settings_repository.dart';
import '../../domain/learning_models.dart';
import '../../infrastructure/sync/kiss_worker_vocabulary_service.dart';
import '../../theme/vocab_theme.dart';
import '../../widgets/vocab_ui.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    required this.repository,
    required this.pronunciationSettingsRepository,
    required this.kissWorkerSettingsRepository,
    required this.kissVocabularyService,
    super.key,
  });

  final LearningRepository repository;
  final PronunciationSettingsRepository pronunciationSettingsRepository;
  final KissWorkerSettingsRepository kissWorkerSettingsRepository;
  final KissVocabularyService kissVocabularyService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LearningStats>(
      stream: repository.watchStats(),
      initialData: const LearningStats.empty(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const LearningStats.empty();
        return CustomScrollView(
          key: const PageStorageKey('profile-scroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: pagePadding,
              sliver: SliverList.list(
                children: [
                  const VocabPageHeader(
                    title: '同步与数据',
                    subtitle: '你的数据、连接和密钥都由你掌控。',
                  ),
                  const SizedBox(height: 20),
                  _KissWorkerCard(
                    learningRepository: repository,
                    settingsRepository: kissWorkerSettingsRepository,
                    service: kissVocabularyService,
                  ),
                  const SizedBox(height: 14),
                  _SyncStatusCard(stats: stats),
                  const SizedBox(height: 14),
                  _PronunciationSettingsCard(
                    repository: pronunciationSettingsRepository,
                  ),
                  const SizedBox(height: 14),
                  const _PrivacyCard(),
                  const SizedBox(height: 24),
                  const SectionHeader(title: '更多设置'),
                  const SizedBox(height: 12),
                  const _MoreSettingsCard(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KissWorkerCard extends StatefulWidget {
  const _KissWorkerCard({
    required this.learningRepository,
    required this.settingsRepository,
    required this.service,
  });

  final LearningRepository learningRepository;
  final KissWorkerSettingsRepository settingsRepository;
  final KissVocabularyService service;

  @override
  State<_KissWorkerCard> createState() => _KissWorkerCardState();
}

class _KissWorkerCardState extends State<_KissWorkerCard> {
  late Future<KissWorkerSettings> _settings = widget.settingsRepository.load();
  bool _isSyncing = false;

  Future<bool> _configure() async {
    final current = await widget.settingsRepository.load();
    if (!mounted) return false;
    final input = await showDialog<_KissConfigInput>(
      context: context,
      builder: (context) => _KissWorkerConfigDialog(current: current),
    );
    if (input == null) return false;
    await widget.settingsRepository.save(
      endpoint: input.endpoint,
      replacementSyncKey: input.syncKey,
      replacementEncryptionPassphrase: input.passphrase,
    );
    if (!mounted) return true;
    setState(() => _settings = widget.settingsRepository.load());
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('KISS-Worker 设置已保存在本机')));
    return true;
  }

  Future<void> _sync() async {
    var settings = await widget.settingsRepository.load();
    if (!settings.isConfigured) {
      final saved = await _configure();
      if (!saved) return;
      settings = await widget.settingsRepository.load();
    }
    if (!mounted) return;
    setState(() => _isSyncing = true);
    try {
      final candidates = await widget.service.fetchWords(settings);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认导入收藏词汇'),
          content: Text(
            '云端共读取到 ${candidates.length} 个词条。导入时会跳过本机已有单词，不会覆盖已有释义，也不会回写云端。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认导入'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final result = await widget.learningRepository.importVocabulary(
        candidates,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '导入 ${result.importedCount} 个单词，跳过 ${result.skippedCount} 个重复项',
          ),
        ),
      );
    } on KissWorkerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('导入失败，请检查网络和同步设置。')));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<KissWorkerSettings>(
      future: _settings,
      builder: (context, snapshot) {
        final configured = snapshot.data?.isConfigured == true;
        return SoftCard(
          color: configured ? VocabColors.limeSoft : VocabColors.surface,
          borderColor: configured ? VocabColors.lime : VocabColors.line,
          child: Column(
            children: [
              Row(
                children: [
                  CircleIcon(
                    icon: configured
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_outlined,
                    background: VocabColors.surface,
                    foreground: configured
                        ? VocabColors.green
                        : VocabColors.muted,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KISS-Worker 收藏词汇',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          configured ? '只读拉取 · 本机解密 · 不回写云端' : '配置简约翻译的同步地址与密钥',
                          style: const TextStyle(
                            fontSize: 12,
                            color: VocabColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: configured ? '已配置' : '未配置',
                    color: VocabColors.surface,
                    foreground: configured
                        ? VocabColors.green
                        : VocabColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSyncing ? null : _configure,
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('同步设置'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSyncing ? null : _sync,
                      icon: _isSyncing
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(_isSyncing ? '导入中…' : '只读导入'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KissConfigInput {
  const _KissConfigInput({
    required this.endpoint,
    this.syncKey,
    this.passphrase,
  });

  final String endpoint;
  final String? syncKey;
  final String? passphrase;
}

class _KissWorkerConfigDialog extends StatefulWidget {
  const _KissWorkerConfigDialog({required this.current});

  final KissWorkerSettings current;

  @override
  State<_KissWorkerConfigDialog> createState() =>
      _KissWorkerConfigDialogState();
}

class _KissWorkerConfigDialogState extends State<_KissWorkerConfigDialog> {
  late final TextEditingController _endpoint = TextEditingController(
    text: widget.current.endpoint,
  );
  final TextEditingController _syncKey = TextEditingController();
  final TextEditingController _passphrase = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _endpoint.dispose();
    _syncKey.dispose();
    _passphrase.dispose();
    super.dispose();
  }

  void _submit() {
    final endpoint = Uri.tryParse(_endpoint.text.trim());
    final missingSyncKey =
        widget.current.syncKey?.isNotEmpty != true &&
        _syncKey.text.trim().isEmpty;
    final missingPassphrase =
        widget.current.encryptionPassphrase?.isNotEmpty != true &&
        _passphrase.text.isEmpty;
    if (endpoint == null ||
        endpoint.scheme != 'https' ||
        endpoint.host.isEmpty) {
      setState(() => _error = '同步地址必须是有效的 HTTPS 地址。');
      return;
    }
    if (missingSyncKey || missingPassphrase) {
      setState(() => _error = '首次配置必须填写同步密钥和加密口令。');
      return;
    }
    Navigator.pop(
      context,
      _KissConfigInput(
        endpoint: _endpoint.text.trim(),
        syncKey: _syncKey.text.trim().isEmpty ? null : _syncKey.text.trim(),
        passphrase: _passphrase.text.isEmpty ? null : _passphrase.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('KISS-Worker 同步设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '应用只读取 kiss-words.json，并在设备上解密；不会修改 Cloudflare KV。',
              style: TextStyle(fontSize: 12, color: VocabColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _endpoint,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: '同步地址',
                hintText: 'https://your-worker.workers.dev',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _syncKey,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: '同步密钥',
                hintText: widget.current.syncKey?.isNotEmpty == true
                    ? '已保存；留空不修改'
                    : '首次配置必须填写',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passphrase,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: '加密口令',
                hintText:
                    widget.current.encryptionPassphrase?.isNotEmpty == true
                    ? '已保存；留空不修改'
                    : '首次配置必须填写',
              ),
            ),
            if (_error case final message?) ...[
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(color: VocabColors.coralInk),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

class _PronunciationSettingsCard extends StatefulWidget {
  const _PronunciationSettingsCard({required this.repository});

  final PronunciationSettingsRepository repository;

  @override
  State<_PronunciationSettingsCard> createState() =>
      _PronunciationSettingsCardState();
}

class _PronunciationSettingsCardState
    extends State<_PronunciationSettingsCard> {
  late Future<String?> _apiKey = widget.repository.loadApiKey();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _apiKey,
      builder: (context, snapshot) {
        final configured = snapshot.data?.isNotEmpty == true;
        return SoftCard(
          onTap: _showApiKeyDialog,
          color: configured ? VocabColors.limeSoft : VocabColors.surface,
          borderColor: configured ? VocabColors.lime : VocabColors.line,
          child: Row(
            children: [
              CircleIcon(
                icon: Icons.record_voice_over_outlined,
                background: VocabColors.surface,
                foreground: configured ? VocabColors.green : VocabColors.muted,
                size: 48,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Merriam-Webster 真人发音',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      configured
                          ? 'API Key 已安全保存在本机'
                          : '点击配置 Collegiate API Key',
                      style: const TextStyle(
                        fontSize: 11,
                        color: VocabColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: configured ? '已配置' : '未配置',
                color: configured
                    ? VocabColors.surface
                    : VocabColors.softSurface,
                foreground: configured ? VocabColors.green : VocabColors.muted,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showApiKeyDialog() async {
    final controller = TextEditingController();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配置 Merriam-Webster'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请输入 Collegiate Dictionary API Key。密钥只保存在系统安全存储中。'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'API Key'),
            ),
            const SizedBox(height: 10),
            const Text(
              '申请地址：dictionaryapi.com',
              style: TextStyle(fontSize: 11, color: VocabColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      await widget.repository.saveApiKey(controller.text);
      if (mounted) {
        setState(() => _apiKey = widget.repository.loadApiKey());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merriam-Webster API Key 已保存')),
        );
      }
    }
    controller.dispose();
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.label, this.value});

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: noop,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: VocabColors.muted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              value ?? '',
              style: const TextStyle(fontSize: 12, color: VocabColors.muted),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: VocabColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({required this.stats});

  final LearningStats stats;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: VocabColors.cyan,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '本机数据 · ${stats.wordCount} 个单词 · ${stats.patternCount} 个句式',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(33, 5, 0, 0),
            child: Text(
              'SQLite 是本地学习数据源；导入内容会进入复习队列。',
              style: TextStyle(fontSize: 11, color: VocabColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: VocabColors.cyanSoft,
      borderColor: VocabColors.cyanSoft,
      onTap: noop,
      child: Row(
        children: [
          const CircleIcon(
            icon: Icons.lock_outline_rounded,
            background: VocabColors.surface,
            foreground: VocabColors.cyan,
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API 密钥仅保存在本机',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  '密钥与敏感连接信息不会上传或同步',
                  style: TextStyle(fontSize: 11, color: VocabColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _MoreSettingsCard extends StatelessWidget {
  const _MoreSettingsCard();

  @override
  Widget build(BuildContext context) {
    return const SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingRow(
            icon: Icons.hub_outlined,
            label: 'AI 服务提供商',
            value: '1 个',
          ),
          Divider(height: 1, indent: 54),
          _SettingRow(
            icon: Icons.download_outlined,
            label: '导入 KISS 词汇',
            value: 'KISS-Worker',
          ),
          Divider(height: 1, indent: 54),
          _SettingRow(
            icon: Icons.shield_outlined,
            label: '加密与恢复',
            value: '本机解密',
          ),
        ],
      ),
    );
  }
}
