import 'package:flutter/material.dart';

import '../../theme/vocab_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: '今天',
    ),
    NavigationDestination(
      icon: Icon(Icons.style_outlined),
      selectedIcon: Icon(Icons.style_rounded),
      label: '词句',
    ),
    NavigationDestination(
      icon: Icon(Icons.auto_awesome_outlined),
      selectedIcon: Icon(Icons.auto_awesome),
      label: 'AI 练习',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: '我的',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: const [
            _TodayView(),
            _ComingSoonView(icon: Icons.style_rounded, title: '我的词句'),
            _ComingSoonView(icon: Icons.auto_awesome, title: 'AI 口语训练'),
            _ComingSoonView(icon: Icons.person_rounded, title: '个人与同步'),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        destinations: _destinations,
        onDestinationSelected: (value) => setState(() => _tabIndex = value),
      ),
    );
  }
}

class _TodayView extends StatelessWidget {
  const _TodayView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          sliver: SliverList.list(
            children: const [
              _TopBar(),
              SizedBox(height: 28),
              Text(
                '早上好，继续开口。',
                style: TextStyle(fontSize: 13, color: VocabColors.muted),
              ),
              SizedBox(height: 4),
              Text(
                'Build your\nown English.',
                style: TextStyle(
                  fontSize: 36,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.8,
                ),
              ),
              SizedBox(height: 24),
              _DailyGoalCard(),
              SizedBox(height: 14),
              _AiCoachCard(),
              SizedBox(height: 14),
              _SyncCard(),
              SizedBox(height: 24),
              _SectionTitle(title: '今天的复习', action: '查看全部'),
              SizedBox(height: 12),
              _ReviewRow(
                word: 'serendipity',
                meaning: '意外发现美好事物',
                color: VocabColors.coral,
              ),
              SizedBox(height: 10),
              _ReviewRow(
                word: 'What I find most useful is…',
                meaning: '我觉得最实用的是……',
                color: VocabColors.coral,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: VocabColors.cream,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Text(
            'vo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
        ),
        const SizedBox(width: 11),
        const Text(
          'Vocab',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const Spacer(),
        _RoundButton(icon: Icons.search_rounded, onPressed: _noop),
        SizedBox(width: 8),
        _RoundButton(icon: Icons.notifications_none_rounded, onPressed: _noop),
      ],
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VocabColors.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: VocabColors.coral,
                size: 20,
              ),
              SizedBox(width: 7),
              Text(
                '连续学习 16 天',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                '18 / 25',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '今日目标',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            '再练 7 个词句',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              value: .72,
              minHeight: 9,
              backgroundColor: Color(0xFF343431),
              valueColor: AlwaysStoppedAnimation(VocabColors.coral),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _noop,
            style: FilledButton.styleFrom(
              backgroundColor: VocabColors.cream,
              foregroundColor: VocabColors.ink,
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              '开始今日复习',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCoachCard extends StatelessWidget {
  const _AiCoachCard();

  @override
  Widget build(BuildContext context) {
    return const _FeatureCard(
      color: Color(0xFFFFE6DE),
      iconColor: VocabColors.coral,
      icon: Icons.graphic_eq_rounded,
      eyebrow: 'AI COACH',
      title: '把收藏句式真正说出来',
      subtitle: 'AI 根据你的词库生成一轮 3 分钟情景对话',
      trailing: Icons.arrow_outward_rounded,
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard();

  @override
  Widget build(BuildContext context) {
    return const _FeatureCard(
      color: Color(0xFFE8F2FF),
      iconColor: Color(0xFF2678FF),
      icon: Icons.cloud_done_outlined,
      eyebrow: 'PRIVATE SYNC',
      title: 'WebDAV 已连接',
      subtitle: '学习进度保存在你的私有空间 · 刚刚同步',
      trailing: Icons.sync_rounded,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final Color color;
  final Color iconColor;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: VocabColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Icon(trailing, size: 20, color: VocabColors.ink),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const Spacer(),
        Text(
          action,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: VocabColors.muted,
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.word,
    required this.meaning,
    required this.color,
  });

  final String word;
  final String meaning;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VocabColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meaning,
                  style: const TextStyle(
                    color: VocabColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: VocabColors.muted),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: VocabColors.ink,
      ),
    );
  }
}

class _ComingSoonView extends StatelessWidget {
  const _ComingSoonView({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: VocabColors.cream,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 34),
          ),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('模块边界已预留，下一阶段接入真实数据。'),
        ],
      ),
    );
  }
}

void _noop() {}
