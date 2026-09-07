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
  final ScrollController _cardScrollController = ScrollController();
  int _index = 0;
  bool _revealed = false;
  bool _isSaving = false;
  int? _savingRating;
  int _skippedCount = 0;
  bool _isPlaying = false;
  DateTime _startedAt = DateTime.now();

  @override
  void dispose() {
    _cardScrollController.dispose();
    super.dispose();
  }

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
    setState(() {
      _isSaving = true;
      _savingRating = rating;
    });
    try {
      await widget.repository.review(
        itemType: item.itemType,
        itemId: item.itemId,
        rating: rating,
        durationMs: DateTime.now().difference(_startedAt).inMilliseconds,
      );
      if (!mounted) return;
      if (_cardScrollController.hasClients) {
        _cardScrollController.jumpTo(0);
      }
      setState(() {
        _index++;
        _revealed = false;
        _isSaving = false;
        _savingRating = null;
        _startedAt = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _savingRating = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('评分保存失败，请重试。')));
    }
  }

  void _skip() {
    if (_isSaving) return;
    if (_cardScrollController.hasClients) {
      _cardScrollController.jumpTo(0);
    }
    setState(() {
      _index++;
      _skippedCount++;
      _revealed = false;
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
            final hasSkippedItems = _skippedCount > 0;
            return _ReviewEmpty(
              icon: Icons.celebration_rounded,
              title: items.isEmpty
                  ? '今天没有待复习内容'
                  : hasSkippedItems
                  ? '本轮已浏览完'
                  : '本轮复习完成',
              message: hasSkippedItems
                  ? '$_skippedCount 个未评分，仍会保留在待复习列表中。'
                  : null,
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
                      key: const Key('review-progress'),
                      value: (_index + 1) / items.length,
                      minHeight: 6,
                      backgroundColor: VocabColors.line,
                      color: VocabColors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const Key('review-card-scroll'),
                      controller: _cardScrollController,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: ConstrainedBox(
                            key: ValueKey('${item.itemType}-${item.itemId}'),
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
                                      padding: EdgeInsets.symmetric(
                                        vertical: 22,
                                      ),
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
                  ),
                  const SizedBox(height: 18),
                  if (!_revealed)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('review-skip'),
                            onPressed: _skip,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 56),
                              foregroundColor: VocabColors.ink,
                              side: const BorderSide(color: VocabColors.line),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _index + 1 == items.length ? '结束本轮' : '下一条',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Text(
                                  '暂不评分',
                                  style: TextStyle(
                                    color: VocabColors.muted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 56),
                            ),
                            onPressed: () => setState(() => _revealed = true),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('显示答案'),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              const Text(
                                '这次记得怎么样？',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isSaving
                                      ? '正在进入下一条…'
                                      : _index + 1 == items.length
                                      ? '选择后完成本轮'
                                      : '选择后进入下一条',
                                  key: const Key('review-rating-hint'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: VocabColors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _RatingButton(
                              rating: 1,
                              label: '忘记',
                              interval: '10 分钟',
                              color: VocabColors.coralSoft,
                              busy: _savingRating == 1,
                              onPressed: _isSaving
                                  ? null
                                  : () => _rate(item, 1),
                            ),
                            _RatingButton(
                              rating: 2,
                              label: '困难',
                              interval: '1 天',
                              color: const Color(0xFFFFE8B5),
                              busy: _savingRating == 2,
                              onPressed: _isSaving
                                  ? null
                                  : () => _rate(item, 2),
                            ),
                            _RatingButton(
                              rating: 3,
                              label: '记得',
                              interval: '3 天',
                              color: VocabColors.cyanSoft,
                              busy: _savingRating == 3,
                              onPressed: _isSaving
                                  ? null
                                  : () => _rate(item, 3),
                            ),
                            _RatingButton(
                              rating: 4,
                              label: '简单',
                              interval: '7 天',
                              color: VocabColors.limeSoft,
                              busy: _savingRating == 4,
                              onPressed: _isSaving
                                  ? null
                                  : () => _rate(item, 4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          key: const Key('review-skip'),
                          onPressed: _isSaving ? null : _skip,
                          icon: const Icon(Icons.skip_next_rounded, size: 20),
                          label: Text(
                            _index + 1 == items.length
                                ? '暂不评分，结束本轮'
                                : '暂不评分，下一条',
                          ),
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
    required this.rating,
    required this.label,
    required this.interval,
    required this.color,
    required this.busy,
    required this.onPressed,
  });

  final int rating;
  final String label;
  final String interval;
  final Color color;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FilledButton(
          key: Key('review-rating-$rating'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: VocabColors.ink,
            disabledBackgroundColor: busy ? color : VocabColors.softSurface,
            disabledForegroundColor: VocabColors.muted,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            child: busy
                ? const SizedBox.square(
                    key: ValueKey('busy'),
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Column(
                    key: const ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label),
                      const SizedBox(height: 2),
                      Text(
                        interval,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: VocabColors.muted,
                        ),
                      ),
                    ],
                  ),
          ),
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
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;
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
          if (message != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
