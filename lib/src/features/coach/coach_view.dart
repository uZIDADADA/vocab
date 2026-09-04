import 'package:flutter/material.dart';

import '../../theme/vocab_theme.dart';
import '../../widgets/vocab_ui.dart';

class CoachView extends StatelessWidget {
  const CoachView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            children: [
              VocabPageHeader(
                title: 'AI 口语教练',
                subtitle: '在真实话题里，把收藏的句式说出来。',
                actions: [
                  RoundActionButton(
                    icon: Icons.tune_rounded,
                    tooltip: '对练设置',
                    onPressed: noop,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  StatusPill(
                    label: 'OpenAI Compatible',
                    color: VocabColors.surface,
                    icon: Icons.hub_outlined,
                  ),
                  Spacer(),
                  StatusPill(
                    label: '生活规划',
                    color: VocabColors.coralSoft,
                    icon: Icons.forum_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _PracticeGoal(),
            ],
          ),
        ),
        const Expanded(child: _Conversation()),
        const _Composer(),
      ],
    );
  }
}

class _PracticeGoal extends StatelessWidget {
  const _PracticeGoal();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: VocabColors.cyanSoft,
      borderColor: VocabColors.cyan,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleIcon(
                icon: Icons.track_changes_rounded,
                background: VocabColors.surface,
                foreground: VocabColors.cyan,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '本轮目标：使用 3 次观点句式',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Text(
                '1 / 3',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(
              value: 1 / 3,
              minHeight: 6,
              backgroundColor: VocabColors.surface,
              valueColor: AlwaysStoppedAnimation(VocabColors.cyan),
            ),
          ),
        ],
      ),
    );
  }
}

class _Conversation extends StatelessWidget {
  const _Conversation();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('coach-conversation'),
      reverse: false,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      children: const [
        _UserBubble(text: '我最近在考虑换一份工作，但还不确定。'),
        SizedBox(height: 10),
        _AssistantBubble(text: '很有意思！什么因素让你开始考虑换工作？'),
        SizedBox(height: 10),
        _AssistantPatternBubble(),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: const BoxDecoration(
          color: VocabColors.limeSoft,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(5),
          ),
        ),
        child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}

class _AssistantPatternBubble extends StatelessWidget {
  const _AssistantPatternBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SoftCard(
        padding: const EdgeInsets.all(15),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '你刚才提到“不确定”，可以试试这个观点句式，让表达更具体：',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: VocabColors.coralSoft,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: VocabColors.coral),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'What I find most important is finding a role that truly aligns with my values.',
                        style: TextStyle(
                          height: 1.45,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF9C3B26),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.volume_up_outlined,
                      size: 19,
                      color: VocabColors.coral,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text('试着用这个句式说一说你的想法吧！'),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _MessageAction(
                    icon: Icons.star_border_rounded,
                    label: '收藏句式',
                  ),
                  _MessageAction(icon: Icons.swap_horiz_rounded, label: '换个说法'),
                  _MessageAction(icon: Icons.mic_none_rounded, label: '跟读'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageAction extends StatelessWidget {
  const _MessageAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VocabColors.softSurface,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: noop,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: VocabColors.surface,
        border: Border(top: BorderSide(color: VocabColors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: noop,
            icon: const Icon(Icons.keyboard_alt_outlined),
            style: IconButton.styleFrom(
              side: const BorderSide(color: VocabColors.line),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '说点什么或输入文字',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: noop,
            icon: const Icon(Icons.mic_rounded),
            style: IconButton.styleFrom(
              backgroundColor: VocabColors.lime,
              foregroundColor: VocabColors.ink,
              minimumSize: const Size.square(52),
            ),
          ),
        ],
      ),
    );
  }
}
