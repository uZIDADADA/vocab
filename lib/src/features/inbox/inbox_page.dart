import 'package:flutter/material.dart';

import '../../data/repositories/learning_repository.dart';
import '../../domain/learning_models.dart';
import '../../theme/vocab_theme.dart';
import '../../widgets/vocab_ui.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({required this.repository, super.key});

  final LearningRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('待整理')),
      body: StreamBuilder<List<InboxItem>>(
        stream: repository.watchPendingInbox(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _InboxMessage(
              icon: Icons.error_outline_rounded,
              title: '待整理内容读取失败',
              message: '请返回后重试。',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const _InboxMessage(
              icon: Icons.task_alt_rounded,
              title: '已经整理完了',
              message: '从浏览器导入或 AI 收藏的待处理内容会出现在这里。',
            );
          }
          return ListView.separated(
            padding: pagePadding,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _InboxItemCard(
              item: items[index],
              onProcessed: () => _markProcessed(context, items[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markProcessed(BuildContext context, InboxItem item) async {
    await repository.markInboxProcessed(item.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已移出待整理列表')));
  }
}

class _InboxItemCard extends StatelessWidget {
  const _InboxItemCard({required this.item, required this.onProcessed});

  final InboxItem item;
  final VoidCallback onProcessed;

  @override
  Widget build(BuildContext context) {
    final isWord = item.kind == 'word';
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: isWord ? '单词' : '句式',
                color: isWord ? VocabColors.cyanSoft : VocabColors.coralSoft,
                foreground: isWord ? VocabColors.cyan : VocabColors.coralInk,
              ),
              const Spacer(),
              Text(
                item.source,
                style: const TextStyle(
                  color: VocabColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(item.content, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 13),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onProcessed,
              icon: const Icon(Icons.check_rounded),
              label: const Text('完成整理'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxMessage extends StatelessWidget {
  const _InboxMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: VocabColors.green),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
