import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/features/reminders/reminder_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('reminder saves switch, reloads settings and sends test', (tester) async {
    const channel = MethodChannel('vocab/reminders');
    var enabled = false;
    var tests = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'load': return {'enabled': enabled, 'allowed': true, 'hour': 20, 'minute': 30};
        case 'save': enabled = (call.arguments as Map)['enabled'] as bool; return null;
        case 'test': tests++; return null;
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(const MaterialApp(home: ReminderPage()));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, false);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(enabled, true);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, true);
    await tester.tap(find.text('发送测试通知'));
    await tester.pumpAndSettle();
    expect(tests, 1);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(enabled, false);
  });
}
