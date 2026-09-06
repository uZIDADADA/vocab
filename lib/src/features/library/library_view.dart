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
    required this.selectedSegment,
    required this.onSegmentChanged,
    super.key,
  });

  final LearningRepository repository;
  final PronunciationService pronunciationService;
  final int selectedSegment;
  final ValueChanged<int> onSegmentChanged;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  String _query = '';
  bool _favoritesOnly = false;
  bool _alphabetical = false;
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
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          builder: (sheetContext) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('全部词句'),
                                  trailing: !_favoritesOnly
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () {
                                    setState(() => _favoritesOnly = false);
                                    Navigator.pop(sheetContext);
                                  },
                                ),
                                ListTile(
                                  title: const Text('仅看收藏'),
                                  trailing: _favoritesOnly
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () {
                                    setState(() => _favoritesOnly = true);
                                    Navigator.pop(sheetContext);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SegmentedTabs(
                    selected: widget.selectedSegment,
                    onChanged: widget.onSegmentChanged,
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
                    key: ValueKey('${widget.selectedSegment}:$_query'),
                    repository: widget.repository,
                    playingWordId: _playingWordId,
                    onPronounce: _playPronunciation,
                    segment: widget.selectedSegment,
                    query: _query,
                    favoritesOnly: _favoritesOnly,
                    alphabetical: _alphabetical,
                    onSortChanged: (value) =>
                        setState(() => _alphabetical = value),
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
            tooltip: widget.selectedSegment == 0 ? '添加单词' : '添加句式',
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
    var primary = '';
    var secondary = '';
    var example = '';
    final isWord = widget.selectedSegment == 0;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(isWord ? '添加单词' : '添加句式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: isWord ? '单词或短语' : '英文句式'),
              onChanged: (value) => primary = value,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: '中文释义'),
              minLines: 1,
              maxLines: 3,
              onChanged: (value) => secondary = value,
            ),
            if (!isWord) ...[
              const SizedBox(height: 12),
              TextField(
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: '英文例句（可选）',
                  hintText: '例如：What I find most useful is daily practice.',
                ),
                minLines: 1,
                maxLines: 3,
                onChanged: (value) => example = value,
              ),
            ],
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
                  primary.trim().isNotEmpty && secondary.trim().isNotEmpty;
              if (valid) Navigator.pop(context, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      if (isWord) {
        await widget.repository.addWord(term: primary, definition: secondary);
      } else {
        await widget.repository.addPattern(
          pattern: primary,
          meaning: secondary,
          example: example,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isWord ? '单词已保存到本机' : '句式已保存到本机')),
        );
      }
    }
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({
    required this.repository,
    required this.playingWordId,
    required this.onPronounce,
    required this.segment,
    required this.query,
    required this.favoritesOnly,
    required this.alphabetical,
    required this.onSortChanged,
    super.key,
  });

  final LearningRepository repository;
  final String? playingWordId;
  final ValueChanged<WordItem> onPronounce;
  final int segment;
  final String query;
  final bool favoritesOnly;
  final bool alphabetical;
  final ValueChanged<bool> onSortChanged;

  @override
  Widget build(BuildContext context) {
    if (segment == 0) {
      return StreamBuilder<List<WordItem>>(
        stream: repository.watchWords(query: query),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const _DatabaseError();
          if (!snapshot.hasData) return const _LoadingList();
          final items = snapshot.data!
              .where((item) => !favoritesOnly || item.isFavorite)
              .toList();
          items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          if (alphabetical) {
            items.sort(
              (a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()),
            );
          }
          return _ResultList(
            count: items.length,
            favoritesOnly: favoritesOnly,
            alphabetical: alphabetical,
            onSortChanged: onSortChanged,
            emptyLabel: favoritesOnly
                ? '没有符合条件的收藏单词'
                : query.isEmpty
                ? '还没有单词，先添加一个吧'
                : '没有找到匹配的单词',
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
        final items = snapshot.data!
            .where((item) => !favoritesOnly || item.isFavorite)
            .toList();
        items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (alphabetical) {
          items.sort(
            (a, b) =>
                a.pattern.toLowerCase().compareTo(b.pattern.toLowerCase()),
          );
        }
        return _ResultList(
          count: items.length,
          favoritesOnly: favoritesOnly,
          alphabetical: alphabetical,
          onSortChanged: onSortChanged,
          emptyLabel: favoritesOnly
              ? '没有符合条件的收藏句式'
              : query.isEmpty
              ? '还没有句式，先添加一个吧'
              : '没有找到匹配的句式',
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
                  example: item.example,
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
    required this.favoritesOnly,
    required this.alphabetical,
    required this.onSortChanged,
    required this.emptyLabel,
    required this.children,
  });

  final int count;
  final bool favoritesOnly;
  final bool alphabetical;
  final ValueChanged<bool> onSortChanged;
  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '${favoritesOnly ? '收藏' : '全部'} $count',
              style: const TextStyle(fontSize: 12, color: VocabColors.muted),
            ),
            const Spacer(),
            PopupMenuButton<bool>(
              tooltip: '排序',
              initialValue: alphabetical,
              onSelected: onSortChanged,
              itemBuilder: (context) => const [
                PopupMenuItem(value: false, child: Text('最近更新')),
                PopupMenuItem(value: true, child: Text('字母顺序')),
              ],
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Text(alphabetical ? '字母顺序' : '最近更新'),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ],
                ),
              ),
            ),
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
    this.example,
    this.showAudio = false,
    this.isAudioBusy = false,
    this.onAudio,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? example;
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
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(subtitle),
                if (example?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Text('例句', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  SelectableText(example!),
                ],
                const SizedBox(height: 16),
                Text('$tag · 掌握度 $mastery/5'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
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
                                tooltip: '播放单词发音',
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
                if (example?.isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    '例句：${example!}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: VocabColors.ink,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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
