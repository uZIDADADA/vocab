import 'package:flutter/material.dart';

import '../../data/repositories/learning_repository.dart';
import '../../domain/learning_models.dart';
import '../../theme/vocab_theme.dart';
import '../../widgets/vocab_ui.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({required this.repository, super.key});

  final LearningRepository repository;

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
                  const _ConnectionCard(),
                  const SizedBox(height: 14),
                  const _SettingsCard(),
                  const SizedBox(height: 14),
                  _SyncStatusCard(stats: stats),
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

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: VocabColors.limeSoft,
      borderColor: VocabColors.lime,
      child: Row(
        children: [
          const CircleIcon(
            icon: Icons.cloud_done_rounded,
            background: VocabColors.surface,
            foreground: VocabColors.green,
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'WebDAV 已连接',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: VocabColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '由 Cloudflare R2 提供私有存储',
                  style: TextStyle(fontSize: 12, color: VocabColors.muted),
                ),
              ],
            ),
          ),
          const StatusPill(
            label: '正常',
            color: VocabColors.surface,
            foreground: VocabColors.green,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return const SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingRow(icon: Icons.link_rounded, label: '服务器地址', value: '已配置'),
          Divider(height: 1, indent: 54),
          _SettingRow(
            icon: Icons.folder_outlined,
            label: '远程目录',
            value: '/vocab',
          ),
          Divider(height: 1, indent: 54),
          _SettingRow(
            icon: Icons.sync_alt_rounded,
            label: '同步策略',
            value: '双向同步',
          ),
          Divider(height: 1, indent: 54),
          _SettingRow(
            icon: Icons.wifi_rounded,
            label: '仅在 Wi-Fi 下同步',
            trailing: Switch(value: true, onChanged: null),
          ),
          Divider(height: 1, indent: 54),
          _SettingRow(
            icon: Icons.call_merge_rounded,
            label: '冲突处理',
            value: '保留本机版本',
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;

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
            if (trailing != null)
              trailing!
            else ...[
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
            padding: EdgeInsets.fromLTRB(33, 5, 0, 14),
            child: Text(
              '本机数据 32.4 MB',
              style: TextStyle(fontSize: 11, color: VocabColors.muted),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: noop,
              style: FilledButton.styleFrom(
                backgroundColor: VocabColors.lime,
                foregroundColor: VocabColors.ink,
              ),
              icon: const Icon(Icons.sync_rounded),
              label: const Text('立即同步'),
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
            value: 'WebDAV',
          ),
          Divider(height: 1, indent: 54),
          _SettingRow(
            icon: Icons.shield_outlined,
            label: '加密与恢复',
            value: '已开启',
          ),
        ],
      ),
    );
  }
}
