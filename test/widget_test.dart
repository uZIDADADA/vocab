import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/app.dart';
import 'package:vocab/src/data/local/app_database.dart';

void main() {
  testWidgets('shows the dashboard and switches through the prototype', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.customSelect('SELECT 1').get();

    await tester.pumpWidget(VocabApp(database: database));
    await _pumpDatabaseFrames(tester);

    expect(find.text('早上好，继续开口'), findsOneWidget);
    expect(find.textContaining('个待复习'), findsWidgets);

    await tester.tap(find.text('词句'));
    await _pumpDatabaseFrames(tester);
    expect(find.text('我的词句'), findsOneWidget);
    expect(find.text('serendipity'), findsOneWidget);

    await tester.tap(find.text('对练'));
    await tester.pump();
    expect(find.text('AI 口语教练'), findsOneWidget);
    expect(find.text('收藏句式'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await _pumpDatabaseFrames(tester);
    expect(find.text('同步与数据'), findsOneWidget);
    expect(find.text('WebDAV 已连接'), findsOneWidget);
    expect(find.text('立即同步'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    await database.close();
    await tester.pump(const Duration(milliseconds: 20));
  });
}

Future<void> _pumpDatabaseFrames(WidgetTester tester) async {
  for (var index = 0; index < 5; index++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
