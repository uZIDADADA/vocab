import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/kiss_worker_settings_repository.dart';
import '../../data/repositories/learning_repository.dart';
import '../../domain/learning_models.dart';
import '../../infrastructure/dictionary/dictionary_service.dart';
import '../../infrastructure/pronunciation/pronunciation_service.dart';
import '../../theme/vocab_theme.dart';
import '../../widgets/vocab_ui.dart';
import '../calendar/learning_calendar_page.dart';
import '../reminders/reminder_page.dart';
import '../review/review_session_page.dart';

class TodayView extends StatelessWidget {
  const TodayView({
    required this.repository,
    required this.dictionaryService,
    required this.pronunciationService,
    required this.onOpenCoach,
    required this.onOpenInbox,
    required this.onOpenWords,
    required this.onOpenPatterns,
    required this.kissWorkerSettingsRepository,
    required this.onOpenWordSync,
    super.key,
  });

  final LearningRepository repository;
  final DictionaryService dictionaryService;
  final PronunciationService pronunciationService;
  final VoidCallback onOpenCoach;
  final VoidCallback onOpenInbox;
  final VoidCallback onOpenWords;
  final VoidCallback onOpenPatterns;
  final KissWorkerSettingsRepository kissWorkerSettingsRepository;
  final VoidCallback onOpenWordSync;

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
                  _TodayHeader(repository: repository),
                  const SizedBox(height: 18),
                  _DictionarySearch(
                    repository: repository,
                    dictionaryService: dictionaryService,
                    pronunciationService: pronunciationService,
                  ),
                  const SizedBox(height: 18),
                  _OverviewCard(stats: stats, repository: repository),
                  const SizedBox(height: 16),
                  _ReviewCard(
                    stats: stats,
                    repository: repository,
                    pronunciationService: pronunciationService,
                  ),
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
                  const SizedBox(height: 14),
                  _WordSyncEntry(
                    settingsRepository: kissWorkerSettingsRepository,
                    onTap: onOpenWordSync,
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

class _DictionarySearch extends StatefulWidget {
  const _DictionarySearch({
    required this.repository,
    required this.dictionaryService,
    required this.pronunciationService,
  });

  final LearningRepository repository;
  final DictionaryService dictionaryService;
  final PronunciationService pronunciationService;

  @override
  State<_DictionarySearch> createState() => _DictionarySearchState();
}

class _DictionarySearchState extends State<_DictionarySearch> {
  final _controller = TextEditingController();
  Timer? _debounce;
  DictionaryEntry? _entry;
  String? _message;
  bool _isLoading = false;
  bool _isSpeaking = false;
  int _requestVersion = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _clearResult();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _lookup(value));
  }

  void _clear() {
    _controller.clear();
    _clearResult();
  }

  void _clearResult() {
    _requestVersion++;
    if (!mounted) return;
    setState(() {
      _entry = null;
      _message = null;
      _isLoading = false;
    });
  }

  Future<void> _lookup(String rawTerm) async {
    _debounce?.cancel();
    final term = rawTerm.trim();
    if (term.isEmpty) {
      _clearResult();
      return;
    }
    if (!RegExp(r"^[A-Za-z][A-Za-z '\-]*$").hasMatch(term)) {
      setState(() {
        _entry = null;
        _message = '请输入英文单词或短语';
        _isLoading = false;
      });
      return;
    }

    final request = ++_requestVersion;
    setState(() {
      _entry = null;
      _message = null;
      _isLoading = true;
    });
    try {
      final entry = await widget.dictionaryService.lookup(term);
      if (!mounted || request != _requestVersion) return;
      setState(() {
        _entry = entry;
        _message = entry == null ? '本地词典暂未收录 “$term”' : null;
        _isLoading = false;
      });
    } on Object {
      if (!mounted || request != _requestVersion) return;
      setState(() {
        _entry = null;
        _message = '离线词典加载失败，请稍后重试';
        _isLoading = false;
      });
    }
  }

  Future<void> _speak() async {
    final entry = _entry;
    if (entry == null || _isSpeaking) return;
    setState(() => _isSpeaking = true);
    try {
      await widget.pronunciationService.play(entry.term);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('暂时无法播放发音')));
      }
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: const Key('home-dictionary-search'),
          controller: _controller,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: _onChanged,
          onSubmitted: _lookup,
          decoration: InputDecoration(
            hintText: '搜索英文单词',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: _clear,
                    tooltip: '清空搜索',
                    icon: const Icon(Icons.close_rounded),
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: VocabColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: VocabColors.ink, width: 1.4),
            ),
          ),
        ),
        if (_isLoading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(
            minHeight: 3,
            borderRadius: BorderRadius.all(Radius.circular(99)),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: 12),
          SoftCard(
            color: VocabColors.softSurface,
            borderColor: VocabColors.softSurface,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                _message!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
        if (_entry != null) ...[
          const SizedBox(height: 12),
          _DictionaryResultCard(
            entry: _entry!,
            repository: widget.repository,
            isSpeaking: _isSpeaking,
            onSpeak: _speak,
          ),
        ],
      ],
    );
  }
}

class _DictionaryResultCard extends StatelessWidget {
  const _DictionaryResultCard({
    required this.entry,
    required this.repository,
    required this.isSpeaking,
    required this.onSpeak,
  });

  final DictionaryEntry entry;
  final LearningRepository repository;
  final bool isSpeaking;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WordItem>>(
      stream: repository.watchWords(query: entry.term),
      builder: (context, snapshot) {
        WordItem? saved;
        for (final word in snapshot.data ?? const <WordItem>[]) {
          if (word.term.trim().toLowerCase() == entry.term.toLowerCase()) {
            saved = word;
            break;
          }
        }
        final isFavorite = saved?.isFavorite ?? false;
        return SoftCard(
          key: const Key('home-dictionary-result'),
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.term,
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isSpeaking ? null : onSpeak,
                    tooltip: '播放单词发音',
                    icon: isSpeaking
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.volume_up_outlined),
                  ),
                  IconButton.filledTonal(
                    onPressed: () async {
                      if (saved != null) {
                        await repository.toggleWordFavorite(saved);
                      } else {
                        final definition = entry.senses
                            .map(
                              (sense) =>
                                  '${sense.partOfSpeech} ${sense.definition}',
                            )
                            .join('\n');
                        final parts = entry.senses
                            .map((sense) => sense.partOfSpeech)
                            .toSet()
                            .join(' / ');
                        String? example;
                        for (final sense in entry.senses) {
                          if (sense.example != null) {
                            example = sense.example;
                            break;
                          }
                        }
                        await repository.favoriteDictionaryWord(
                          term: entry.term,
                          definition: definition,
                          partOfSpeech: parts,
                          source: entry.source,
                          example: example,
                        );
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isFavorite ? '已取消收藏' : '已收藏到词句库'),
                          ),
                        );
                      }
                    },
                    tooltip: isFavorite ? '取消收藏' : '收藏',
                    style: IconButton.styleFrom(
                      backgroundColor: VocabColors.limeSoft,
                    ),
                    icon: Icon(
                      isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isFavorite ? VocabColors.coral : VocabColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (saved != null &&
                  !saved.source.contains('Open English WordNet')) ...[
                Text('我的释义', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 3),
                Text(
                  saved.definition,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
              ],
              for (var index = 0; index < entry.senses.length; index++) ...[
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${entry.senses[index].partOfSpeech}  ',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      TextSpan(text: entry.senses[index].definition),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
                if (entry.senses[index].example case final example?) ...[
                  const SizedBox(height: 3),
                  Text(
                    example,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                if (index != entry.senses.length - 1)
                  const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              Text(
                '${entry.source} · 本地词典 · 无需 API Key',
                style: const TextStyle(fontSize: 10, color: VocabColors.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.repository});

  final LearningRepository repository;

  @override
  Widget build(BuildContext context) {
    return VocabPageHeader(
      title: '早上好，继续开口',
      subtitle: '把今天遇到的表达，变成你会说的话。',
      actions: [
        RoundActionButton(
          icon: Icons.calendar_today_outlined,
          tooltip: '学习日历',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LearningCalendarPage(repository: repository),
            ),
          ),
        ),
        const SizedBox(width: 8),
        RoundActionButton(
          icon: Icons.notifications_none_rounded,
          tooltip: '提醒',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const ReminderPage())),
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
  const _OverviewCard({required this.stats, required this.repository});

  final LearningRepository repository;

  final LearningStats stats;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<List<DateTime>>(
              stream: repository.watchReviewDates(),
              builder: (context, snapshot) => _OverviewMetric(
                icon: Icons.local_fire_department_rounded,
                iconColor: VocabColors.coral,
                label: '连续学习',
                value: snapshot.hasData
                    ? '${LearningRepository.streak(snapshot.data!, DateTime.now())} 天'
                    : '—',
              ),
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
  const _ReviewCard({
    required this.stats,
    required this.repository,
    required this.pronunciationService,
  });

  final LearningStats stats;
  final LearningRepository repository;
  final PronunciationService pronunciationService;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: VocabColors.lime,
      borderColor: VocabColors.lime,
      padding: const EdgeInsets.all(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReviewSessionPage(
            repository: repository,
            pronunciationService: pronunciationService,
          ),
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

class _WordSyncEntry extends StatelessWidget {
  const _WordSyncEntry({required this.settingsRepository, required this.onTap});

  final KissWorkerSettingsRepository settingsRepository;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: settingsRepository.load(),
      builder: (context, snapshot) {
        final configured = snapshot.data?.isConfigured == true;
        final subtitle = switch (snapshot.connectionState) {
          ConnectionState.waiting => '正在读取同步配置…',
          _ when configured => '已配置 · 手动导入与增量上传',
          _ => '未配置 · 点击完成 KISS-Worker 设置',
        };
        return SoftCard(
          key: const Key('home-word-sync'),
          onTap: onTap,
          child: Row(
            children: [
              CircleIcon(
                icon: configured
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_sync_outlined,
                background: VocabColors.limeSoft,
                foreground: configured ? VocabColors.green : VocabColors.muted,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '词汇同步',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: VocabColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        );
      },
    );
  }
}
