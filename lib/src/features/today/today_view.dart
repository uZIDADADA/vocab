import 'package:flutter/material.dart';

import '../../data/repositories/learning_repository.dart';
import '../../domain/learning_models.dart';
import '../../theme/vocab_theme.dart';
import '../../widgets/vocab_ui.dart';
import '../review/review_session_page.dart';

class TodayView extends StatelessWidget {
  const TodayView({
    required this.repository,
    required this.onOpenCoach,
    required this.onOpenInbox,
    required this.onOpenWords,
    required this.onOpenPatterns,
    super.key,
  });

  final LearningRepository repository;
  final VoidCallback onOpenCoach;
  final VoidCallback onOpenInbox;
  final VoidCallback onOpenWords;
  final VoidCallback onOpenPatterns;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LearningStats>(
      stream: repository.watchStats(),
      initialData: const LearningStats.empty(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const LearningStats.empty();
        return CustomScrollView(
          key: const PageStorageKey('today-scroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: pagePadding,
              sliver: SliverList.list(
                children: [
                  _TodayHeader(stats: stats),
                  const SizedBox(height: 22),
                  _OverviewCard(stats: stats),
                  const SizedBox(height: 16),
                  _ReviewCard(stats: stats, repository: repository),
                  const SizedBox(height: 14),
                  _ContinueCard(onTap: onOpenCoach),
                  const SizedBox(height: 14),
                  _InboxCard(count: stats.inboxCount, onTap: onOpenInbox),
                  const SizedBox(height: 24),
                  const SectionHeader(title: '今日概览'),
                  const SizedBox(height: 12),
                  _MetricsRow(
                    stats: stats,
                    onOpenWords: onOpenWords,
                    onOpenPatterns: onOpenPatterns,
                    onOpenReviewSummary: () => _showStatusSheet(
                      context,
                      icon: Icons.bar_chart_rounded,
                      title: '复习记录',
                      message: stats.reviewCount == 0
                          ? '还没有复习记录。完成一次复习后，这里会自动累计。'
                          : '已累计完成 ${stats.reviewCount} 次复习。完整的复习历史会在后续版本开放。',
                    ),
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

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.stats});

  final LearningStats stats;

  @override
  Widget build(BuildContext context) {
    return VocabPageHeader(
      title: '早上好，继续开口',
      subtitle: '把今天遇到的表达，变成你会说的话。',
      actions: [
        RoundActionButton(
          icon: Icons.calendar_today_outlined,
          tooltip: '学习日历',
          onPressed: () => _showStatusSheet(
            context,
            icon: Icons.calendar_month_outlined,
            title: '学习日历',
            message:
                '今天有 ${stats.dueCount} 项待复习，已累计完成 ${stats.reviewCount} 次复习。完整的日期视图会在后续版本开放。',
          ),
        ),
        const SizedBox(width: 8),
        RoundActionButton(
          icon: Icons.notifications_none_rounded,
          tooltip: '提醒',
          onPressed: () => _showStatusSheet(
            context,
            icon: Icons.notifications_none_rounded,
            title: '学习提醒',
            message: '提醒功能尚未开放。目前打开 Vocab 后，首页会自动显示当天到期的复习内容。',
          ),
        ),
      ],
    );
  }
}

void _showStatusSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
}) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: VocabColors.surface,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleIcon(
            icon: icon,
            background: VocabColors.limeSoft,
            foreground: VocabColors.green,
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.stats});

  final LearningStats stats;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          const Expanded(
            child: _OverviewMetric(
              icon: Icons.local_fire_department_rounded,
              iconColor: VocabColors.coral,
              label: '连续学习',
              value: '16 天',
            ),
          ),
          Container(width: 1, height: 52, color: VocabColors.line),
          Expanded(child: _ReviewProgress(stats: stats)),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIcon(
          icon: icon,
          background: VocabColors.coralSoft,
          foreground: iconColor,
          size: 42,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewProgress extends StatelessWidget {
  const _ReviewProgress({required this.stats});

  final LearningStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: stats.dueCount == 0 ? 1 : 0,
                strokeWidth: 6,
                backgroundColor: VocabColors.softSurface,
                valueColor: AlwaysStoppedAnimation(VocabColors.lime),
              ),
              Text(
                stats.dueCount == 0 ? '100%' : '0%',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('复习进度', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '${stats.dueCount} 待复习',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.stats, required this.repository});

  final LearningStats stats;
  final LearningRepository repository;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: VocabColors.lime,
      borderColor: VocabColors.lime,
      padding: const EdgeInsets.all(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReviewSessionPage(repository: repository),
        ),
      ),
      child: Row(
        children: [
          const CircleIcon(
            icon: Icons.style_rounded,
            background: VocabColors.ink,
            foreground: VocabColors.lime,
            size: 50,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日 ${stats.dueCount} 个待复习',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  '单词 ${stats.dueWordCount}  ·  句式 ${stats.duePatternCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const CircleIcon(
            icon: Icons.arrow_forward_rounded,
            background: VocabColors.surface,
            size: 42,
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: VocabColors.coralSoft,
      borderColor: VocabColors.coralSoft,
      onTap: onTap,
      child: Row(
        children: [
          const CircleIcon(
            icon: Icons.forum_outlined,
            background: VocabColors.surface,
            foreground: VocabColors.coral,
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '继续对话',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'Life goals and planning',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  '上次练到一半，继续聊聊',
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

class _InboxCard extends StatelessWidget {
  const _InboxCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          const CircleIcon(
            icon: Icons.mark_email_unread_outlined,
            background: VocabColors.cyanSoft,
            foreground: VocabColors.cyan,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count 条待整理',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                const Text(
                  '来自导入与 AI 收藏',
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

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.stats,
    required this.onOpenWords,
    required this.onOpenPatterns,
    required this.onOpenReviewSummary,
  });

  final LearningStats stats;
  final VoidCallback onOpenWords;
  final VoidCallback onOpenPatterns;
  final VoidCallback onOpenReviewSummary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            key: const Key('metric-total-words'),
            icon: Icons.auto_stories_outlined,
            label: '总单词',
            value: '${stats.wordCount}',
            onTap: onOpenWords,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            key: const Key('metric-total-patterns'),
            icon: Icons.star_outline_rounded,
            label: '总句式',
            value: '${stats.patternCount}',
            onTap: onOpenPatterns,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            key: const Key('metric-review-count'),
            icon: Icons.bar_chart_rounded,
            label: '复习次数',
            value: '${stats.reviewCount}',
            onTap: onOpenReviewSummary,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          Icon(icon, size: 21),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: VocabColors.muted),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
