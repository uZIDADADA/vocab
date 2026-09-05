import 'package:flutter/material.dart';

import '../../data/repositories/learning_repository.dart';

class LearningCalendarPage extends StatefulWidget {
  const LearningCalendarPage({required this.repository, super.key});
  final LearningRepository repository;
  @override
  State<LearningCalendarPage> createState() => _LearningCalendarPageState();
}

class _LearningCalendarPageState extends State<LearningCalendarPage> {
  DateTime selected = DateUtils.dateOnly(DateTime.now());
  late DateTime month = DateTime(selected.year, selected.month);
  late final dates = widget.repository.watchReviewDates();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('学习日历')),
    body: StreamBuilder<List<DateTime>>(
      stream: dates,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('复习记录读取失败，请返回重试'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final counts = <DateTime, int>{};
        for (final date in snapshot.data!) {
          final day = DateUtils.dateOnly(date);
          counts[day] = (counts[day] ?? 0) + 1;
        }
        final total = counts.entries
            .where(
              (e) => e.key.year == month.year && e.key.month == month.month,
            )
            .fold(0, (int sum, e) => sum + e.value);
        final offset = (month.weekday - 1) % 7;
        final length = DateTime(month.year, month.month + 1, 0).day;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '本月 $total 次复习 · 连续 ${LearningRepository.streak(snapshot.data!, DateTime.now())} 天',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: '上个月',
                  onPressed: () => setState(
                    () => month = DateTime(month.year, month.month - 1),
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${month.year} 年 ${month.month} 月',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  tooltip: '下个月',
                  onPressed: () => setState(
                    () => month = DateTime(month.year, month.month + 1),
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            TextButton(
              onPressed: () => setState(() {
                selected = DateUtils.dateOnly(DateTime.now());
                month = DateTime(selected.year, selected.month);
              }),
              child: const Text('回到今天'),
            ),
            Row(
              children: [
                for (final label in ['一', '二', '三', '四', '五', '六', '日'])
                  Expanded(child: Center(child: Text(label))),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: offset + length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox.shrink();
                final day = DateTime(
                  month.year,
                  month.month,
                  index - offset + 1,
                );
                final count = counts[day] ?? 0;
                return Semantics(
                  label: '${day.month}月${day.day}日，$count 次复习',
                  selected: day == selected,
                  child: Material(
                    color: day == selected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : count > 0
                        ? const Color(0xffeef3e3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => selected = day),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: day == selected
                                  ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                  : null,
                            ),
                          ),
                          if (count > 0)
                            Text(
                              '$count 次',
                              style: TextStyle(
                                fontSize: 10,
                                color: day == selected
                                    ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              '${selected.month} 月 ${selected.day} 日',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              (counts[selected] ?? 0) == 0
                  ? '当天暂无复习记录'
                  : '已完成 ${counts[selected]} 次复习',
            ),
            const SizedBox(height: 16),
            const Text('完成一次词汇或句式评分即记录一次复习；连续天数按本地日期计算。'),
          ],
        );
      },
    ),
  );
}
