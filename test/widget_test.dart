import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/app.dart';
import 'package:vocab/src/data/local/app_database.dart';
import 'package:vocab/src/data/repositories/ai_settings_repository.dart';
import 'package:vocab/src/domain/coach_models.dart';
import 'package:vocab/src/domain/learning_models.dart';
import 'package:vocab/src/infrastructure/ai/ai_chat_provider.dart';
import 'package:vocab/src/infrastructure/pronunciation/pronunciation_service.dart';
import 'package:vocab/src/infrastructure/sync/kiss_worker_vocabulary_service.dart';

void main() {
  testWidgets('shows the dashboard and switches through the prototype', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final pronunciationService = _FakePronunciationService();
    await database.customSelect('SELECT 1').get();

    await tester.pumpWidget(
      VocabApp(
        database: database,
        aiSecretStore: MemoryAiSecretStore(),
        aiChatProvider: _FakeAiChatProvider(),
        pronunciationService: pronunciationService,
        kissVocabularyService: _FakeKissVocabularyService(),
      ),
    );
    await _pumpDatabaseFrames(tester);

    expect(find.text('早上好，继续开口'), findsOneWidget);
    expect(find.textContaining('个待复习'), findsWidgets);

    await tester.tap(find.byTooltip('学习日历'));
    await tester.pumpAndSettle();
    expect(find.textContaining('完整的日期视图会在后续版本开放'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('提醒'));
    await tester.pumpAndSettle();
    expect(find.text('学习提醒'), findsOneWidget);
    expect(find.textContaining('提醒功能尚未开放'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('今日 3 个待复习'));
    await tester.pumpAndSettle();
    expect(find.text('今日复习'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('3 条待整理'));
    await tester.pumpAndSettle();
    expect(find.text('待整理示例 1'), findsOneWidget);
    expect(find.text('完成整理'), findsNWidgets(3));
    await tester.ensureVisible(find.text('完成整理').first);
    await tester.tap(find.text('完成整理').first);
    await _pumpDatabaseFrames(tester);
    expect(find.text('待整理示例 1'), findsNothing);
    await tester.pageBack();
    await _pumpDatabaseFrames(tester);
    expect(find.text('2 条待整理'), findsOneWidget);

    await tester.tap(find.text('继续对话'));
    await tester.pump();
    expect(find.text('AI 口语教练'), findsOneWidget);

    await tester.tap(find.text('今日'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('metric-total-words')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey<String>('today-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('metric-total-words')));
    await _pumpDatabaseFrames(tester);
    expect(find.text('我的词句'), findsOneWidget);
    expect(find.text('serendipity'), findsOneWidget);

    await tester.tap(find.text('今日'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('metric-total-patterns')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey<String>('today-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('metric-total-patterns')));
    await _pumpDatabaseFrames(tester);
    expect(find.text('What I find most useful is …'), findsOneWidget);

    await tester.tap(find.text('今日'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('metric-review-count')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey<String>('today-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('metric-review-count')));
    await tester.pumpAndSettle();
    expect(find.text('复习记录'), findsOneWidget);
    expect(find.textContaining('还没有复习记录'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('词句'));
    await _pumpDatabaseFrames(tester);
    expect(find.text('我的词句'), findsOneWidget);
    await tester.tap(find.text('单词'));
    await _pumpDatabaseFrames(tester);
    expect(find.text('serendipity'), findsOneWidget);
    await tester.tap(find.byTooltip('播放 Merriam-Webster 发音').first);
    await tester.pump();
    expect(pronunciationService.lastTerm, 'serendipity');

    await tester.tap(find.text('对练'));
    await tester.pump();
    expect(find.text('AI 口语教练'), findsOneWidget);
    expect(find.text('配置 Gemini 后开始对话'), findsOneWidget);

    await tester.tap(find.text('去设置'));
    await tester.pumpAndSettle();
    expect(find.text('AI 服务设置'), findsOneWidget);
    expect(find.text('gemini-3.1-flash-lite'), findsWidgets);
    await tester.enterText(find.byType(TextField).last, 'gemini-test-key');
    await tester.tap(find.text('保存设置'));
    await tester.pumpAndSettle();
    expect(find.text('文本模式 · 已配置'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await _pumpDatabaseFrames(tester);
    expect(find.text('同步与数据'), findsOneWidget);
    expect(find.text('KISS-Worker 收藏词汇'), findsOneWidget);
    expect(find.text('只读导入'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    await database.close();
    await tester.pump(const Duration(milliseconds: 20));
  });
}

class _FakeAiChatProvider implements AiChatProvider {
  @override
  Future<String> complete({
    required AiProviderConfig config,
    required String apiKey,
    required List<CoachMessage> messages,
    String? systemInstruction,
  }) async {
    return systemInstruction == null ? 'Test reply' : '[]';
  }
}

class _FakePronunciationService implements PronunciationService {
  String? lastTerm;

  @override
  Future<void> play(String term) async {
    lastTerm = term;
  }

  @override
  Future<void> dispose() async {}
}

class _FakeKissVocabularyService implements KissVocabularyService {
  @override
  Future<List<ImportedVocabularyCandidate>> fetchWords(
    KissWorkerSettings settings,
  ) async => const [];

  @override
  void close() {}
}

Future<void> _pumpDatabaseFrames(WidgetTester tester) async {
  for (var index = 0; index < 5; index++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
