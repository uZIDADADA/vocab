import 'package:flutter/material.dart';

import '../../data/repositories/learning_repository.dart';
import '../../domain/learning_models.dart';
import '../../theme/vocab_theme.dart';
import '../../widgets/vocab_ui.dart';

class ReviewSessionPage extends StatefulWidget {
  const ReviewSessionPage({required this.repository, super.key});

  final LearningRepository repository;

  @override
  State<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends State<ReviewSessionPage> {
  late Future<List<ReviewQueueItem>> _queue = widget.repository.getDueReviews();
  int _index = 0;
  bool _revealed = false;
  bool _isSaving = false;
  DateTime _startedAt = DateTime.now();

  Future<void> _rate(ReviewQueueItem item, int rating) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await widget.repository.review(
      itemType: item.itemType,
      itemId: item.itemId,
      rating: rating,
      durationMs: DateTime.now().difference(_startedAt).inMilliseconds,
    );
    if (!mounted) return;
    setState(() {
      _index++;
      _revealed = false;
      _isSaving = false;
      _startedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日复习')),
      body: FutureBuilder<List<ReviewQueueItem>>(
        future: _queue,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ReviewEmpty(
              icon: Icons.error_outline_rounded,
              title: '复习内容读取失败',
              actionLabel: '重试',
              onAction: () => setState(() {
                _queue = widget.repository.getDueReviews();
                _index = 0;
              }),
            );
          }
          final items = snapshot.data ?? const <ReviewQueueItem>[];
          if (_index >= items.length) {
            return _ReviewEmpty(
              icon: Icons.celebration_rounded,
              title: items.isEmpty ? '今天没有待复习内容' : '本轮复习完成',
              actionLabel: '返回',
              onAction: () => Navigator.pop(context),
            );
          }
          final item = items[_index];
          return SafeArea(
            child: Padding(
              padding: pagePadding,
              child: Column(
                children: [
                  Row(
                    children: [
                      StatusPill(
                        label: item.itemType == 'word' ? '单词' : '句式',
                        color: VocabColors.cyanSoft,
                        foreground: VocabColors.cyan,
                      ),
                      const Spacer(),
                      Text(
                        '${_index + 1} / ${items.length}',
                        style: const TextStyle(
                          color: VocabColors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Center(
                      child: SoftCard(
                        padding: const EdgeInsets.all(28),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.prompt,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: VocabColors.muted,
                                ),
                              ),
                              if (_revealed) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 22),
                                  child: Divider(),
                                ),
                                SelectableText(
                                  item.answer,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!_revealed)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => setState(() => _revealed = true),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('显示答案'),
                      ),
                    )
                  else
                    Row(
                      children: [
                        _RatingButton(
                          label: '忘记',
                          color: VocabColors.coralSoft,
                          onPressed: _isSaving ? null : () => _rate(item, 1),
                        ),
                        _RatingButton(
                          label: '困难',
                          color: const Color(0xFFFFE8B5),
                          onPressed: _isSaving ? null : () => _rate(item, 2),
                        ),
                        _RatingButton(
                          label: '记得',
                          color: VocabColors.cyanSoft,
                          onPressed: _isSaving ? null : () => _rate(item, 3),
                        ),
                        _RatingButton(
                          label: '简单',
                          color: VocabColors.limeSoft,
                          onPressed: _isSaving ? null : () => _rate(item, 4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: VocabColors.ink,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _ReviewEmpty extends StatelessWidget {
  const _ReviewEmpty({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: VocabColors.green),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
