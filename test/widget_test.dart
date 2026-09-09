import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/app.dart';
import 'package:vocab/src/application/import/vocabulary_import_coordinator.dart';
import 'package:vocab/src/features/profile/profile_view.dart';
import 'package:vocab/src/data/repositories/kiss_worker_settings_repository.dart';
import 'package:vocab/src/data/repositories/pronunciation_settings_repository.dart';
import 'package:vocab/src/data/repositories/translator_settings_repository.dart';
import 'package:vocab/src/features/review/review_session_page.dart';
import 'package:vocab/src/data/repositories/learning_repository.dart';
import 'package:vocab/src/data/local/app_database.dart';
import 'package:vocab/src/data/repositories/ai_settings_repository.dart';
import 'package:vocab/src/domain/coach_models.dart';
import 'package:vocab/src/domain/learning_models.dart';
import 'package:vocab/src/infrastructure/ai/ai_chat_provider.dart';
import 'package:vocab/src/infrastructure/dictionary/dictionary_service.dart';
import 'package:vocab/src/infrastructure/pronunciation/pronunciation_service.dart';
import 'package:vocab/src/infrastructure/sync/kiss_worker_vocabulary_service.dart';
import 'package:vocab/src/theme/vocab_theme.dart';
import 'package:vocab/src/widgets/vocab_ui.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('vocab/reminders'),
          (call) async => {
            'enabled': false,
            'allowed': false,
            'hour': 20,
            'minute': 0,
          },
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('vocab/reminders'), null);
  });

  testWidgets('status pill keeps browser favorite text inside its highlight', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(
                  key: Key('browser-favorite-pill'),
                  label: '浏览器收藏',
                  color: VocabColors.limeSoft,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final pill = tester.getRect(find.byKey(const Key('browser-favorite-pill')));
    final label = tester.getRect(find.text('浏览器收藏'));
    final labelRender = tester.renderObject<RenderParagraph>(
      find.text('浏览器收藏'),
    );
    expect(pill.contains(label.topLeft), isTrue);
    expect(pill.contains(label.bottomRight), isTrue);
    expect(labelRender.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'phone upload requires confirmation and recovers after cancellation',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = _UploadTestRepository(database);

      final store = MemoryAiSecretStore();
      final settings = KissWorkerSettingsRepository(store);
      await settings.save(
        endpoint: 'https://example.com',
        replacementSyncKey: 'key',
        replacementEncryptionPassphrase: 'pass',
      );
      final service = _FakeKissVocabularyService();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileView(
              onOpenAiSettings: () {},
              repository: repository,
              pronunciationSettingsRepository: PronunciationSettingsRepository(
                store,
              ),
              translatorSettingsRepository: TranslatorSettingsRepository(store),
              kissWorkerSettingsRepository: settings,
              kissVocabularyService: service,
              vocabularyImportCoordinator: VocabularyImportCoordinator(
                repository,
                _FakeDictionaryService(),
              ),
            ),
          ),
        ),
      );
      await _pumpDatabaseFrames(tester);
      await tester.tap(find.text('上传本机新增'));
      await _pumpDatabaseFrames(tester);
      await tester.pumpAndSettle();
      expect(service.uploadCalls, 0);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(service.uploadCalls, 0);
      await tester.tap(find.text('上传本机新增'));
      await _pumpDatabaseFrames(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认上传'));
      await tester.pumpAndSettle();
      expect(service.uploadCalls, 1);
      expect(service.uploaded.single.term, 'phone');
      expect(find.textContaining('上传完成：新增 1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    },
  );

  testWidgets(
    'review exposes pronunciation before and after revealing answer',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final service = _FakePronunciationService();
      await database.customSelect('SELECT 1').get();
      final repository = LearningRepository(database);
      final queue = await repository.getDueReviews();
      for (final item in queue) {
        await repository.review(
          itemType: item.itemType,
          itemId: item.itemId,
          rating: 4,
          durationMs: 1,
        );
      }
      await repository.importVocabulary([
        ImportedVocabularyCandidate(
          term: 'hello',
          definition: List.filled(30, '这是一段用于检验长答案滚动位置的释义。').join(),
          phonetic: '/həˈləʊ/',
          examples: [
            List.filled(20, 'This is a long example sentence. ').join(),
          ],
        ),
        const ImportedVocabularyCandidate(term: 'world', definition: '世界'),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewSessionPage(
            repository: repository,
            pronunciationService: service,
          ),
        ),
      );
      await _pumpDatabaseFrames(tester);
      final current = (await repository.getDueReviews()).first;
      final initialProgress = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('review-progress')),
      );
      expect(initialProgress.value, 0.5);
      if (current.phonetic != null) {
        expect(find.text(current.phonetic!), findsOneWidget);
      }
      await tester.tap(find.text('美式 · 朗读'));
      await tester.pumpAndSettle();
      expect(service.lastTerm, current.prompt);
      expect(service.lastAccent, PronunciationAccent.american);
      await tester.tap(find.text('英式 · 朗读'));
      await tester.pumpAndSettle();
      expect(service.lastAccent, PronunciationAccent.british);
      expect(find.text(current.answer), findsNothing);
      await tester.tap(find.text('显示答案'));
      await tester.pumpAndSettle();
      expect(find.text(current.answer), findsOneWidget);
      expect(find.text('美式 · 朗读'), findsOneWidget);
      expect(find.text('选择后进入下一条'), findsOneWidget);
      expect(find.text('10 分钟'), findsOneWidget);
      expect(find.text('3 天'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('review-card-scroll')),
        const Offset(0, -350),
      );
      await tester.pumpAndSettle();
      var reviewScroll = tester.widget<SingleChildScrollView>(
        find.byKey(const Key('review-card-scroll')),
      );
      expect(reviewScroll.controller!.offset, greaterThan(0));
      await tester.tap(find.text('记得'));
      await tester.pumpAndSettle();
      reviewScroll = tester.widget<SingleChildScrollView>(
        find.byKey(const Key('review-card-scroll')),
      );
      expect(reviewScroll.controller!.offset, 0);
      final next = (await repository.getDueReviews()).first;
      if (next.phonetic != null) {
        expect(find.text(next.phonetic!), findsOneWidget);
      }
      await tester.tap(find.text('美式 · 朗读'));
      await tester.pumpAndSettle();
      expect(service.lastTerm, next.prompt);
      expect(find.text('结束本轮'), findsOneWidget);
      expect(find.text('暂不评分'), findsOneWidget);
      await tester.tap(find.byKey(const Key('review-skip')));
      await tester.pumpAndSettle();
      expect(find.text('本轮已浏览完'), findsOneWidget);
      expect(find.text('1 个未评分，仍会保留在待复习列表中。'), findsOneWidget);
      final remaining = await repository.getDueReviews();
      expect(remaining.map((item) => item.itemId), contains(next.itemId));
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    },
  );

  testWidgets(
    'KISS settings wait for storage, retry failures and refresh immediately',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final store = _DelayedSecretStore();
      final service = _ControlledKissService();
      await database.customSelect('SELECT 1').get();
      await tester.pumpWidget(
        VocabApp(
          database: database,
          aiSecretStore: store,
          aiChatProvider: _FakeAiChatProvider(),
          pronunciationService: _FakePronunciationService(),
          kissVocabularyService: service,
        ),
      );
      await _pumpDatabaseFrames(tester);
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('同步设置'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, '同步地址'),
        'https://example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '同步密钥'),
        'test-key',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '加密口令'),
        'test-passphrase',
      );
      await tester.tap(find.text('保存'));
      await tester.pump();
      expect(find.text('保存中…'), findsOneWidget);
      expect(find.text('已配置'), findsNothing);
      store.pending.completeError(StateError('storage unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('保存失败，请重试。设置尚未确认生效。'), findsOneWidget);
      expect(find.text('KISS-Worker 同步设置'), findsOneWidget);
      store.pending = Completer<void>();
      await tester.tap(find.text('保存'));
      await tester.pump();
      store.pending.complete();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('KISS-Worker 同步设置'), findsNothing);
      expect(find.text('已配置'), findsOneWidget);
      expect(service.calls, 0);
      await tester.tap(find.text('从 KISS 导入'));
      await tester.pump();
      expect(find.text('读取中…'), findsOneWidget);
      expect(service.settings?.endpoint, 'https://example.com');
      expect(service.settings?.syncKey, 'test-key');
      service.pending.complete([]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('确认导入收藏词汇'), findsOneWidget);
      expect(find.text('待确认'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('从 KISS 导入'), findsOneWidget);
      expect(service.calls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 20));
      await database.close();
    },
  );

  testWidgets('Microsoft Translator settings stay in secure storage', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final store = MemoryAiSecretStore();
    final settings = TranslatorSettingsRepository(store);
    await database.customSelect('SELECT 1').get();
    await tester.pumpWidget(
      VocabApp(
        database: database,
        aiSecretStore: store,
        aiChatProvider: _FakeAiChatProvider(),
        dictionaryService: _FakeDictionaryService(),
        pronunciationService: _FakePronunciationService(),
        kissVocabularyService: _FakeKissVocabularyService(),
      ),
    );
    await _pumpDatabaseFrames(tester);
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('microsoft-translator-settings'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('translator-api-key')),
      'translator-key',
    );
    await tester.enterText(
      find.byKey(const Key('translator-region')),
      'eastasia',
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    final saved = await settings.load();
    expect(saved.apiKey, 'translator-key');
    expect(saved.region, 'eastasia');
    expect(find.text('已配置'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    await database.close();
  });

  testWidgets('shows the dashboard and switches through the prototype', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final pronunciationService = _FakePronunciationService();
    final dictionaryService = _FakeDictionaryService();
    await database.customSelect('SELECT 1').get();

    await tester.pumpWidget(
      VocabApp(
        database: database,
        aiSecretStore: MemoryAiSecretStore(),
        aiChatProvider: _FakeAiChatProvider(),
        dictionaryService: dictionaryService,
        pronunciationService: pronunciationService,
        kissVocabularyService: _FakeKissVocabularyService(),
      ),
    );
    await _pumpDatabaseFrames(tester);

    expect(find.text('早上好，继续开口'), findsOneWidget);
    expect(find.textContaining('个待复习'), findsWidgets);
    _expectSelectedNavigationItem(tester, index: 0, label: '今日');

    for (final (index, label) in const [(1, '词句'), (2, '对练'), (0, '今日')]) {
      await tester.tap(find.text(label));
      await tester.pump();
      _expectSelectedNavigationItem(tester, index: index, label: label);
    }

    await tester.enterText(
      find.byKey(const Key('home-dictionary-search')),
      'serendipity',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(dictionaryService.lastTerm, 'serendipity');
    expect(find.byKey(const Key('home-dictionary-result')), findsOneWidget);
    expect(
      find.textContaining(
        'a fortunate accidental discovery',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('在线查询'), findsOneWidget);
    await tester.tap(find.byTooltip('播放单词发音'));
    await tester.pump();
    expect(pronunciationService.lastTerm, 'serendipity');
    await tester.tap(find.byTooltip('收藏'));
    await _pumpDatabaseFrames(tester);
    expect(find.byTooltip('取消收藏'), findsOneWidget);
    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pump();
    expect(find.byKey(const Key('home-dictionary-result')), findsNothing);

    await tester.tap(find.byTooltip('学习日历'));
    await tester.pumpAndSettle();
    await _pumpDatabaseFrames(tester);
    expect(find.textContaining('本月 0 次复习'), findsOneWidget);
    await tester.tap(find.byTooltip('上个月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('回到今天'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('提醒'));
    await tester.pumpAndSettle();
    expect(find.text('学习提醒'), findsOneWidget);
    expect(find.text('每日提醒'), findsOneWidget);
    await tester.pageBack();
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
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey<String>('today-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
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
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey<String>('today-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('metric-total-patterns')));
    await _pumpDatabaseFrames(tester);
    expect(find.text('What I find most useful is …'), findsOneWidget);
    await tester.tap(find.byTooltip('添加句式'));
    await tester.pumpAndSettle();
    expect(find.text('英文例句（可选）'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, '英文句式'),
      'What helps me most is …',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '中文释义'),
      '对我帮助最大的是……',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '英文例句（可选）'),
      'What helps me most is practicing every day.',
    );
    await tester.tap(find.text('保存'));
    await _pumpDatabaseFrames(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('例句：What helps me most is practicing every day.'),
      findsOneWidget,
    );
    await tester.tap(find.text('What helps me most is …'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('What helps me most is practicing every day.'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('今日'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('metric-review-count')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey<String>('today-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('metric-review-count')));
    await tester.pumpAndSettle();
    expect(find.text('复习记录'), findsOneWidget);
    expect(find.textContaining('还没有复习记录'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('home-word-sync')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey<String>('today-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('词汇同步'), findsOneWidget);
    expect(find.text('未配置 · 点击完成 KISS-Worker 设置'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-word-sync')));
    await _pumpDatabaseFrames(tester);
    expect(find.text('同步与数据'), findsOneWidget);
    expect(find.text('KISS-Worker 词汇同步'), findsOneWidget);

    await tester.tap(find.text('今日'));
    await tester.pump();

    await tester.tap(find.text('词句'));
    await _pumpDatabaseFrames(tester);
    _expectSelectedNavigationItem(tester, index: 1, label: '词句');
    expect(find.text('我的词句'), findsOneWidget);
    await tester.tap(find.text('单词'));
    await _pumpDatabaseFrames(tester);
    expect(find.text('serendipity'), findsOneWidget);
    await tester.tap(find.byTooltip('播放单词发音').first);
    await tester.pump();
    expect(pronunciationService.lastTerm, 'serendipity');

    await tester.tap(find.text('serendipity'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('筛选'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('仅看收藏'));
    await _pumpDatabaseFrames(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('收藏 '), findsOneWidget);
    await tester.tap(find.byTooltip('筛选'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部词句'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('排序'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('字母顺序').last);
    await tester.pumpAndSettle();
    expect(find.text('字母顺序'), findsOneWidget);

    await tester.tap(find.text('对练'));
    await tester.pump();
    expect(find.text('AI 口语教练'), findsOneWidget);
    expect(find.text('配置 Gemini 后开始对话'), findsOneWidget);

    await tester.tap(find.text('去设置'));
    await tester.pumpAndSettle();
    expect(find.text('AI 服务设置'), findsOneWidget);
    expect(find.text('gemini-3.1-flash-lite'), findsWidgets);
    await tester.tap(find.text('Gemini').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DeepSeek').last);
    await tester.pumpAndSettle();
    expect(find.text('https://api.deepseek.com'), findsOneWidget);
    expect(find.text('deepseek-v4-flash'), findsOneWidget);
    expect(find.text('切换提供商必须填写对应的 Key'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'gemini-test-key');
    await tester.tap(find.text('保存设置'));
    await tester.pumpAndSettle();
    expect(find.text('文本模式 · 已配置'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await _pumpDatabaseFrames(tester);
    expect(find.text('同步与数据'), findsOneWidget);
    expect(find.text('KISS-Worker 词汇同步'), findsOneWidget);
    expect(find.text('从 KISS 导入'), findsOneWidget);

    final profileScroll = find.descendant(
      of: find.byKey(const PageStorageKey<String>('profile-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('AI 服务提供商'),
      300,
      scrollable: profileScroll,
    );
    await tester.tap(find.text('AI 服务提供商'));
    await tester.pumpAndSettle();
    expect(find.text('AI 服务设置'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('加密与恢复'),
      200,
      scrollable: profileScroll,
    );
    await tester.tap(find.text('加密与恢复'));
    await tester.pumpAndSettle();
    expect(find.text('加密与恢复说明'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导入 KISS 词汇'));
    await tester.pumpAndSettle();
    expect(find.text('KISS-Worker 同步设置'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

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
  PronunciationAccent? lastAccent;

  @override
  Future<void> play(
    String term, {
    PronunciationAccent accent = PronunciationAccent.automatic,
  }) async {
    lastTerm = term;
    lastAccent = accent;
  }

  @override
  Future<void> dispose() async {}
}

class _FakeDictionaryService implements DictionaryService {
  String? lastTerm;

  @override
  Future<List<DictionaryMatch>> searchChinese(String query) async => const [];

  @override
  Future<DictionaryEntry?> lookup(String term) async {
    lastTerm = term;
    return DictionaryEntry(
      term: term,
      source: 'Open English WordNet 2025 · CC BY 4.0',
      senses: const [
        DictionarySense(
          partOfSpeech: 'n.',
          definition: 'a fortunate accidental discovery',
          example: 'a fortunate stroke of serendipity',
        ),
      ],
    );
  }

  @override
  Future<void> close() async {}
}

class _FakeKissVocabularyService implements KissVocabularyService {
  int uploadCalls = 0;
  List<ImportedVocabularyCandidate> uploaded = [];
  @override
  Future<int> uploadWords(
    KissWorkerSettings settings,
    List<ImportedVocabularyCandidate> words,
  ) async {
    uploadCalls++;
    uploaded = words;
    return words.length;
  }

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

void _expectSelectedNavigationItem(
  WidgetTester tester, {
  required int index,
  required String label,
}) {
  for (var itemIndex = 0; itemIndex < 4; itemIndex++) {
    final itemFinder = find.byKey(Key('bottom-navigation-item-$itemIndex'));
    final item = tester.widget<DecoratedBox>(itemFinder);
    final renderedItem = tester.renderObject<RenderDecoratedBox>(itemFinder);
    final expectedColor = itemIndex == index
        ? VocabColors.lime
        : Colors.transparent;
    expect((item.decoration as BoxDecoration).color, expectedColor);
    expect((renderedItem.decoration as BoxDecoration).color, expectedColor);
  }
  final itemFinder = find.byKey(Key('bottom-navigation-item-$index'));
  expect(
    find.descendant(of: itemFinder, matching: find.text(label)),
    findsOneWidget,
  );
}

class _DelayedSecretStore extends MemoryAiSecretStore {
  Completer<void> pending = Completer<void>();

  @override
  Future<void> write(String key, String value) async {
    await pending.future;
    await super.write(key, value);
  }
}

class _ControlledKissService implements KissVocabularyService {
  @override
  Future<int> uploadWords(
    KissWorkerSettings settings,
    List<ImportedVocabularyCandidate> words,
  ) async => words.length;

  final pending = Completer<List<ImportedVocabularyCandidate>>();
  int calls = 0;
  KissWorkerSettings? settings;

  @override
  Future<List<ImportedVocabularyCandidate>> fetchWords(
    KissWorkerSettings settings,
  ) {
    calls++;
    this.settings = settings;
    return pending.future;
  }

  @override
  void close() {}
}

class _UploadTestRepository extends LearningRepository {
  _UploadTestRepository(super.database);

  @override
  Stream<LearningStats> watchStats() =>
      Stream.value(const LearningStats.empty());

  @override
  Future<List<ImportedVocabularyCandidate>> wordsForUpload() async => const [
    ImportedVocabularyCandidate(term: 'phone', definition: '手机'),
  ];
}
