import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/app.dart';

void main() {
  testWidgets('shows the Vocab dashboard and switches tabs', (tester) async {
    await tester.pumpWidget(const VocabApp());

    expect(find.text('Vocab'), findsOneWidget);
    expect(find.text('Build your\nown English.'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('WebDAV 已连接'), findsOneWidget);

    await tester.tap(find.text('AI 练习'));
    await tester.pumpAndSettle();

    expect(find.text('AI 口语训练'), findsOneWidget);
  });
}
