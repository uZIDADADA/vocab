import 'package:flutter/material.dart';

import '../../data/repositories/learning_repository.dart';
import '../../domain/learning_models.dart';
import '../../infrastructure/pronunciation/pronunciation_service.dart';
import '../../theme/vocab_theme.dart';
import '../../widgets/vocab_ui.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({
    required this.repository,
    required this.pronunciationService,
    super.key,
  });

  final LearningRepository repository;
  final PronunciationService pronunciationService;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  int _segment = 0;
  String _query = '';
  String? _playingWordId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          key: const PageStorageKey('library-scroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
              sliver: SliverList.list(
                children: [
                  VocabPageHeader(
                    title: '我的词句',
                    subtitle: '把遇见的表达，整理成自己的语言。',
                    actions: [
                      RoundActionButton(
                        icon: Icons.tune_rounded,
                        tooltip: '筛选',
                        onPressed: noop,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SegmentedTabs(
                    selected: _segment,
                    onChanged: (value) => setState(() => _segment = value),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: '搜索单词、句式或场景',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _LibraryContent(
                    key: ValueKey('$_segment:$_query'),
                    repository: widget.repository,
                    playingWordId: _playingWordId,
                    onPronounce: _playPronunciation,
                    segment: _segment,
                    query: _query,
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            heroTag: 'library-add',
            tooltip: _segment == 0 ? '添加单词' : '添加句式',
            onPressed: _showAddDialog,
            backgroundColor: VocabColors.lime,
            foregroundColor: VocabColors.ink,
            elevation: 4,
            child: const Icon(Icons.add_rounded, size: 30),
          ),
        ),
      ],
    );
  }

  Future<void> _playPronunciation(WordItem item) async {
    if (_playingWordId != null) return;
    setState(() => _playingWordId = item.id);
    try {
      await widget.pronunciationService.play(item.term);
    } on PronunciationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('发音播放失败，请稍后重试。')));
      }
    } finally {
      if (mounted) setState(() => _playingWordId = null);
    }
  }

  Future<void> _showAddDialog() async {
    final primaryController = TextEditingController();
    final secondaryController = TextEditingController();
    final isWord = _segment == 0;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWord ? '添加单词' : '添加句式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: primaryController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: isWord ? '单词或短语' : '英文句式'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: secondaryController,
              decoration: const InputDecoration(labelText: '中文释义'),
              minLines: 1,
              maxLines: 3,
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
              final valid =
                  primaryController.text.trim().isNotEmpty &&
                  secondaryController.text.trim().isNotEmpty;
              if (valid) Navigator.pop(context, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      if (isWord) {
        await widget.repository.addWord(
          term: primaryController.text,
          definition: secondaryController.text,
        );
      } else {
        await widget.repository.addPattern(
          pattern: primaryController.text,
          meaning: secondaryController.text,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isWord ? '单词已保存到本机' : '句式已保存到本机')),
        );
      }
    }

    primaryController.dispose();
    secondaryController.dispose();
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({
    required this.repository,
    required this.playingWordId,
    required this.onPronounce,
    required this.segment,
    required this.query,
    super.key,
  });

  final LearningRepository repository;
  final String? playingWordId;
  final ValueChanged<WordItem> onPronounce;
  final int segment;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (segment == 0) {
      return StreamBuilder<List<WordItem>>(
        stream: repository.watchWords(query: query),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const _DatabaseError();
          if (!snapshot.hasData) return const _LoadingList();
          final items = snapshot.data!;
          return _ResultList(
            count: items.length,
            emptyLabel: query.isEmpty ? '还没有单词，先添加一个吧' : '没有找到匹配的单词',
            children: [
              for (final (index, item) in items.indexed)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 10,
                  ),
                  child: _LibraryCard(
                    icon: Icons.auto_stories_rounded,
                    iconBackground: _softColor(index),
                    iconColor: _accentColor(index),
                    title: item.term,
                    subtitle: [
                      if (item.partOfSpeech != null) item.partOfSpeech!,
                      item.definition,
                    ].join(' '),
                    tag: item.tag,
                    tagColor: _softColor(index),
                    mastery: item.mastery,
                    accent: _accentColor(index),
                    isFavorite: item.isFavorite,
                    showAudio: true,
                    isAudioBusy: playingWordId == item.id,
                    onAudio: () => onPronounce(item),
                    onFavorite: () => repository.toggleWordFavorite(item),
                  ),
                ),
            ],
          );
        },
      );
    }

    return StreamBuilder<List<PatternItem>>(
      stream: repository.watchPatterns(query: query),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const _DatabaseError();
        if (!snapshot.hasData) return const _LoadingList();
        final items = snapshot.data!;
        return _ResultList(
          count: items.length,
          emptyLabel: query.isEmpty ? '还没有句式，先添加一个吧' : '没有找到匹配的句式',
          children: [
            for (final (index, item) in items.indexed)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == items.length - 1 ? 0 : 10,
                ),
                child: _LibraryCard(
                  icon: Icons.format_quote_rounded,
                  iconBackground: _softColor(index + 1),
                  iconColor: _accentColor(index + 1),
                  title: item.pattern,
                  subtitle: item.meaning,
                  tag: item.category,
                  tagColor: _softColor(index + 1),
                  mastery: item.mastery,
                  accent: _accentColor(index + 1),
                  isFavorite: item.isFavorite,
                  onFavorite: () => repository.togglePatternFavorite(item),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.count,
    required this.emptyLabel,
    required this.children,
  });

  final int count;
  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '全部 $count',
              style: const TextStyle(fontSize: 12, color: VocabColors.muted),
            ),
            const Spacer(),
            const Text(
              '最近使用',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
        const SizedBox(height: 12),
        if (children.isEmpty)
          SoftCard(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  emptyLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else
          ...children,
      ],
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: VocabColors.softSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: '单词',
              selected: selected == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: '句式',
              selected: selected == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? VocabColors.lime : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: selected ? VocabColors.ink : VocabColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.mastery,
    required this.accent,
    required this.isFavorite,
    required this.onFavorite,
    this.showAudio = false,
    this.isAudioBusy = false,
    this.onAudio,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final int mastery;
  final Color accent;
  final bool isFavorite;
  final bool showAudio;
  final bool isAudioBusy;
  final VoidCallback? onAudio;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: noop,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleIcon(
            icon: icon,
            background: iconBackground,
            foreground: iconColor,
            size: 48,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (showAudio)
                      Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: isAudioBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                onPressed: onAudio,
                                tooltip: '播放 Merriam-Webster 发音',
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 32,
                                  height: 32,
                                ),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.volume_up_outlined,
                                  size: 18,
                                ),
                              ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: StatusPill(label: tag, color: tagColor),
                    ),
                    const Spacer(),
                    Text(
                      '掌握度  $mastery/5',
                      style: const TextStyle(
                        fontSize: 10,
                        color: VocabColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 7),
                    ...List.generate(
                      5,
                      (index) => Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < mastery ? accent : VocabColors.line,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onFavorite,
            tooltip: isFavorite ? '取消收藏' : '收藏',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFavorite ? VocabColors.coral : VocabColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _DatabaseError extends StatelessWidget {
  const _DatabaseError();

  @override
  Widget build(BuildContext context) {
    return const SoftCard(
      color: VocabColors.coralSoft,
      borderColor: VocabColors.coral,
      child: Text('本地数据库读取失败，请重新启动应用。'),
    );
  }
}

Color _accentColor(int index) {
  return switch (index % 3) {
    0 => VocabColors.green,
    1 => VocabColors.coral,
    _ => VocabColors.cyan,
  };
}

Color _softColor(int index) {
  return switch (index % 3) {
    0 => VocabColors.limeSoft,
    1 => VocabColors.coralSoft,
    _ => VocabColors.cyanSoft,
  };
}
