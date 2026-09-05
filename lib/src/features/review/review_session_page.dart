import 'package:flutter/material.dart';

import '../../data/repositories/learning_repository.dart';
import '../../domain/learning_models.dart';
import '../../theme/vocab_theme.dart';
import '../../infrastructure/pronunciation/pronunciation_service.dart';
import '../../widgets/vocab_ui.dart';

class ReviewSessionPage extends StatefulWidget {
  const ReviewSessionPage({
    required this.repository,
    required this.pronunciationService,
    super.key,
  });

  final LearningRepository repository;
  final PronunciationService pronunciationService;

  @override
  State<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends State<ReviewSessionPage> {
  late Future<List<ReviewQueueItem>> _queue = widget.repository.getDueReviews();
  int _index = 0;
  bool _revealed = false;
  bool _isSaving = false;
  bool _isPlaying = false;
  DateTime _startedAt = DateTime.now();

  Future<void> _playPronunciation(
    ReviewQueueItem item,
    PronunciationAccent accent,
  ) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    try {
      await widget.pronunciationService.play(item.prompt, accent: accent);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is PronunciationException ? error.message : '发音播放失败，请稍后重试。',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _index / items.length,
                      minHeight: 6,
                      backgroundColor: VocabColors.line,
                      color: VocabColors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: SizedBox(
                            width: double.infinity,
                            child: SoftCard(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RECALL & PRACTICE',
                                    style: TextStyle(
                                      color: VocabColors.green,
                                      fontSize: 10,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  SelectableText(
                                    item.prompt,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          height: 1.15,
                                        ),
                                  ),
                                  if (item.itemType == 'word') ...[
                                    if (item.phonetic != null) ...[
                                      const SizedBox(height: 12),
                                      SelectableText(
                                        item.phonetic!,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          color: VocabColors.muted,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 18),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _AccentButton(
                                          label: '英式',
                                          busy: _isPlaying,
                                          onPressed: () => _playPronunciation(
                                            item,
                                            PronunciationAccent.british,
                                          ),
                                        ),
                                        _AccentButton(
                                          label: '美式',
                                          busy: _isPlaying,
                                          onPressed: () => _playPronunciation(
                                            item,
                                            PronunciationAccent.american,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 22),
                                    child: Divider(height: 1),
                                  ),
                                  if (!_revealed) ...[
                                    const Icon(
                                      Icons.psychology_outlined,
                                      color: VocabColors.green,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      '先回想，再看答案',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '这个词是什么意思？试着用它说一句话。',
                                      style: TextStyle(
                                        color: VocabColors.muted,
                                        height: 1.6,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      item.itemType == 'word' ? '词义' : '表达含义',
                                      style: const TextStyle(
                                        color: VocabColors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (item.partOfSpeech?.isNotEmpty ==
                                        true) ...[
                                      Text(
                                        item.partOfSpeech!,
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: VocabColors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    SelectableText(
                                      item.answer,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        height: 1.65,
                                      ),
                                    ),
                                    if (item.example?.isNotEmpty == true) ...[
                                      const SizedBox(height: 24),
                                      const Text(
                                        '例句',
                                        style: TextStyle(
                                          color: VocabColors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SelectableText(
                                        item.example!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.65,
                                        ),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 28),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.bookmark_outline_rounded,
                                        size: 15,
                                        color: VocabColors.muted,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: VocabColors.muted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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

class _AccentButton extends StatelessWidget {
  const _AccentButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: VocabColors.limeSoft,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      icon: const Icon(Icons.volume_up_rounded, size: 18),
      label: Text('$label · ${busy ? '播放中…' : '朗读'}'),
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
