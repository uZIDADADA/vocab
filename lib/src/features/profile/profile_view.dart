import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/learning_repository.dart';
import '../../data/repositories/kiss_worker_settings_repository.dart';
import '../../data/repositories/pronunciation_settings_repository.dart';
import '../../domain/learning_models.dart';
import '../../infrastructure/sync/kiss_worker_vocabulary_service.dart';
import '../../theme/vocab_theme.dart';
import '../../widgets/vocab_ui.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    required this.onOpenAiSettings,
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

  final VoidCallback onOpenAiSettings;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _kissKey = GlobalKey<_KissWorkerCardState>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LearningStats>(
      stream: widget.repository.watchStats(),
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
                    key: _kissKey,
                    learningRepository: widget.repository,
                    settingsRepository: widget.kissWorkerSettingsRepository,
                    service: widget.kissVocabularyService,
                  ),
                  const SizedBox(height: 14),
                  _SyncStatusCard(stats: stats),
                  const SizedBox(height: 14),
                  _PronunciationSettingsCard(
                    repository: widget.pronunciationSettingsRepository,
                  ),
                  const SizedBox(height: 14),
                  const _PrivacyCard(),
                  const SizedBox(height: 24),
                  const SectionHeader(title: '更多设置'),
                  const SizedBox(height: 12),
                  _MoreSettingsCard(
                    onOpenAiSettings: widget.onOpenAiSettings,
                    onImport: () => _kissKey.currentState?._sync(),
                  ),
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
    super.key,
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
  bool _isConfiguring = false;
  String _syncStage = '读取中…';

  Future<bool> _configure() async {
    if (_isConfiguring) return false;
    setState(() => _isConfiguring = true);
    try {
      final current = await widget.settingsRepository.load();
      if (!mounted) return false;
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _KissWorkerConfigDialog(
          current: current,
          onSave: (input) async {
            await widget.settingsRepository.save(
              endpoint: input.endpoint,
              replacementSyncKey: input.syncKey,
              replacementEncryptionPassphrase: input.passphrase,
            );
            if (!mounted) return;
            setState(() {
              _settings = Future.value(
                KissWorkerSettings(
                  endpoint: input.endpoint,
                  syncKey: input.syncKey ?? current.syncKey,
                  encryptionPassphrase:
                      input.passphrase ?? current.encryptionPassphrase,
                ),
              );
            });
          },
        ),
      );
      if (saved != true || !mounted) return false;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('KISS-Worker 设置已保存并生效')));
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法读取同步设置，请重试。')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _isConfiguring = false);
    }
  }

  Future<void> _sync() async {
    if (_isSyncing || _isConfiguring) return;
    setState(() {
      _isSyncing = true;
      _syncStage = '读取中…';
    });
    try {
      var settings = await widget.settingsRepository.load();
      if (!mounted) return;
      if (!settings.isConfigured) {
        final saved = await _configure();
        if (!saved || !mounted) return;
        settings = await widget.settingsRepository.load();
      }
      if (!mounted) return;
      final candidates = await widget.service.fetchWords(settings);
      if (!mounted) return;
      setState(() => _syncStage = '待确认');
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
      if (confirmed != true || !mounted) return;
      setState(() => _syncStage = '写入中…');
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

  Future<void> _upload() async {
    if (_isSyncing || _isConfiguring) return;
    setState(() {
      _isSyncing = true;
      _syncStage = '读取中…';
    });
    try {
      var settings = await widget.settingsRepository.load();
      if (!mounted) return;
      if (!settings.isConfigured) {
        if (!await _configure() || !mounted) return;
        settings = await widget.settingsRepository.load();
      }
      final words = await widget.learningRepository.wordsForUpload();
      if (!mounted) return;
      setState(() => _syncStage = '待确认');
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认上传本机新增'),
          content: Text(
            '将检查 ${words.length} 个本机手动添加或 AI 对练保存的单词，只上传云端没有的词。内容在本机加密，同名词保留云端内容；不会同步删除、句式或学习进度。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认上传'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _syncStage = '上传中…');
      final count = await widget.service.uploadWords(settings, words);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传完成：新增 $count 个单词，其余词条已存在或无需上传')),
      );
    } on KissWorkerException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传未确认成功，请检查网络和配置后重试；本机单词仍保留。')),
        );
      }
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
                          'KISS-Worker 词汇同步',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          configured ? '手动导入与增量上传 · 本机加密' : '配置同步地址、密钥与本机加密口令',
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
                      onPressed: _isSyncing || _isConfiguring
                          ? null
                          : _configure,
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('同步设置'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSyncing || _isConfiguring ? null : _sync,
                      icon: _isSyncing && !_isConfiguring && _syncStage != '待确认'
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(_isSyncing ? _syncStage : '从 KISS 导入'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSyncing || _isConfiguring ? null : _upload,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('上传本机新增'),
                ),
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
  const _KissWorkerConfigDialog({required this.current, required this.onSave});

  final Future<void> Function(_KissConfigInput) onSave;

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
  bool _isSaving = false;

  @override
  void dispose() {
    _endpoint.dispose();
    _syncKey.dispose();
    _passphrase.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
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
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        _KissConfigInput(
          endpoint: _endpoint.text.trim(),
          syncKey: _syncKey.text.trim().isEmpty ? null : _syncKey.text.trim(),
          passphrase: _passphrase.text.isEmpty ? null : _passphrase.text,
        ),
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _error = '保存失败，请重试。设置尚未确认生效。');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: AlertDialog(
        title: const Text('KISS-Worker 同步设置'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '导入会在设备上解密 kiss-words.json；上传本机新增单词会先合并云端词库，再加密保存。',
                style: TextStyle(fontSize: 12, color: VocabColors.muted),
              ),
              const SizedBox(height: 14),
              TextField(
                enabled: !_isSaving,
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
                enabled: !_isSaving,
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
                enabled: !_isSaving,
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
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            child: Text(_isSaving ? '保存中…' : '保存'),
          ),
        ],
      ),
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
                      '单词发音',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      configured
                          ? '优先 Merriam-Webster · 失败时使用系统朗读'
                          : '系统朗读已启用 · 可选配置 Merriam-Webster',
                      style: const TextStyle(
                        fontSize: 11,
                        color: VocabColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: configured ? '优先 MW' : '免 Key',
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
            const Text(
              '默认使用设备英文语音，无需 Key 或在线词典。Android 需安装英文离线语音包。配置后优先使用 Merriam-Webster 真人录音（首次获取需联网），失败时回退系统朗读。密钥只保存在系统安全存储中。',
            ),
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
        setState(() {
          _apiKey = widget.repository.loadApiKey();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merriam-Webster API Key 已保存')),
        );
      }
    }
    controller.dispose();
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final VoidCallback onTap;

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
      onTap: () => _showPrivacy(context),
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
                  '使用系统安全存储，调用服务时用于鉴权',
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
  const _MoreSettingsCard({
    required this.onOpenAiSettings,
    required this.onImport,
  });

  final VoidCallback onOpenAiSettings;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingRow(
            icon: Icons.hub_outlined,
            label: 'AI 服务提供商',
            onTap: onOpenAiSettings,
          ),
          Divider(height: 1, indent: 54),
          _SettingRow(
            icon: Icons.download_outlined,
            label: '导入 KISS 词汇',
            value: 'KISS-Worker',
            onTap: onImport,
          ),
          Divider(height: 1, indent: 54),
          _SettingRow(
            icon: Icons.menu_book_outlined,
            label: '离线词典',
            value: '英汉双语',
            onTap: () => _showDictionaryLicense(context),
          ),
          Divider(height: 1, indent: 54),
          _SettingRow(
            icon: Icons.shield_outlined,
            label: '加密与恢复',
            value: '本机解密',
            onTap: () => _showPrivacy(context),
          ),
        ],
      ),
    );
  }
}

void _showDictionaryLicense(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('离线词典来源'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '中文释义：ECDICT 开放词典常用词子集（27,829 个词条），'
              '上游仓库以 MIT 许可发布。来源：https://github.com/skywind3000/ECDICT\n\n'
              '英文释义：Open English WordNet 2025（v2.3.2），CC BY 4.0。'
              '来源：https://en-word.net/\n\n'
              '全部在本机查询，无需网络或 API Key。中文搜索按中文释义匹配英文词，'
              '不翻译整句；未收录的中文释义会明确提示。\n\n'
              'ECDICT 为社区汇编词典，可能存在遗漏或错误，并非出版社审校词典。'
              '中文释义与 WordNet 英文词义分别展示，不作逐条对应；个人释义保留独立显示。',
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: rootBundle.loadString(
                'assets/dictionary/ECDICT-LICENSE.txt',
              ),
              builder: (context, snapshot) => Text(
                snapshot.data ?? 'ECDICT MIT 许可声明加载中…',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

void _showPrivacy(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('加密与恢复说明'),
      content: const SingleChildScrollView(
        child: Text(
          'API 密钥和 KISS 连接信息保存在系统安全存储中。调用服务时会使用相应凭据进行鉴权；AI 对话内容会发送给你配置的服务。\n\n学习词句和对话保存在本机数据库中。KISS 收藏词汇在设备上解密后导入；目前尚未提供完整数据备份、WebDAV 同步或恢复功能。',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}
