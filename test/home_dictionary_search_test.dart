import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/data/local/app_database.dart';
import 'package:vocab/src/data/repositories/ai_settings_repository.dart';
import 'package:vocab/src/data/repositories/kiss_worker_settings_repository.dart';
import 'package:vocab/src/data/repositories/learning_repository.dart';
import 'package:vocab/src/features/today/today_view.dart';
import 'package:vocab/src/infrastructure/dictionary/dictionary_service.dart';
import 'package:vocab/src/infrastructure/pronunciation/pronunciation_service.dart';
import 'package:vocab/src/theme/vocab_theme.dart';

const apple = DictionaryEntry(
  term: 'apple',
  source: 'Microsoft Translator',
  chineseSource: 'Microsoft Translator',
  chineseDefinition: 'n. 苹果',
  partOfSpeech: 'n.',
  senses: [DictionarySense(partOfSpeech: 'n.', definition: 'an edible fruit')],
);

class TestDictionary implements DictionaryService {
  int lookupCalls = 0;
  int searchCalls = 0;
  Future<DictionaryEntry?> Function(String) lookupHandler = (_) async => apple;
  Future<List<DictionaryMatch>> Function(String) searchHandler = (_) async =>
      const [
        DictionaryMatch(term: 'apple', chineseDefinition: 'n. 苹果'),
        DictionaryMatch(term: 'apple tree', chineseDefinition: 'n. 苹果树'),
      ];
  @override
  Future<DictionaryEntry?> lookup(String term) {
    lookupCalls++;
    return lookupHandler(term);
  }

  @override
  Future<List<DictionaryMatch>> searchChinese(String query) {
    searchCalls++;
    return searchHandler(query);
  }

  @override
  Future<void> close() async {}
}

class TestPronunciation implements PronunciationService {
  String? spoken;
  @override
  Future<void> play(
    String term, {
    PronunciationAccent accent = PronunciationAccent.automatic,
  }) async {
    spoken = term;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  late AppDatabase database;
  late LearningRepository repository;
  late TestDictionary dictionary;
  late TestPronunciation pronunciation;
  const input = Key('home-dictionary-search');

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LearningRepository(database);
    dictionary = TestDictionary();
    pronunciation = TestPronunciation();
  });
  tearDown(() async => database.close());

  Future<void> showHome(WidgetTester tester) async {
    await database.customSelect('SELECT 1').get();
    await tester.pumpWidget(
      MaterialApp(
        theme: VocabTheme.light,
        home: Scaffold(
          body: TodayView(
            repository: repository,
            dictionaryService: dictionary,
            pronunciationService: pronunciation,
            kissWorkerSettingsRepository: KissWorkerSettingsRepository(
              MemoryAiSecretStore(),
            ),
            onOpenCoach: () {},
            onOpenInbox: () {},
            onOpenWords: () {},
            onOpenPatterns: () {},
            onOpenWordSync: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(input), text);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Chinese candidates open bilingual results, speak and save Chinese',
    (tester) async {
      await showHome(tester);
      await search(tester, '苹果');
      expect(
        find.byKey(const Key('home-dictionary-candidates')),
        findsOneWidget,
      );
      expect(find.text('apple tree'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('dictionary-candidate-apple')),
      );
      await tester.pumpAndSettle();
      expect(find.text('中文翻译 · Microsoft Translator'), findsOneWidget);
      expect(find.text('n. 苹果'), findsOneWidget);
      expect(
        find.textContaining('an edible fruit', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('补充释义 · Microsoft Translator'), findsOneWidget);
      await tester.tap(find.byTooltip('播放单词发音'));
      await tester.pumpAndSettle();
      expect(pronunciation.spoken, 'apple');
      final savedWord = repository
          .watchWords(query: 'apple')
          .firstWhere((words) => words.isNotEmpty)
          .then((words) => words.single);
      await tester.tap(find.byTooltip('收藏'));
      await tester.pump();
      final word = await tester.runAsync(
        () => savedWord.timeout(const Duration(seconds: 5)),
      );
      expect(word!.definition, 'n. 苹果');
      expect(word.source, 'Microsoft Translator');
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('typing does not call the paid API until search is submitted', (
    tester,
  ) async {
    await showHome(tester);
    await tester.enterText(find.byKey(input), 'apple');
    await tester.pump(const Duration(seconds: 1));
    expect(dictionary.lookupCalls, 0);

    await tester.tap(find.byTooltip('搜索'));
    await tester.pumpAndSettle();
    expect(dictionary.lookupCalls, 1);
    expect(find.byKey(const Key('home-dictionary-result')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('empty, failed and unconfigured lookups are explicit', (
    tester,
  ) async {
    dictionary.searchHandler = (_) async => [];
    await showHome(tester);
    await search(tester, '没收录');
    expect(find.textContaining('暂未返回“没收录”'), findsOneWidget);
    dictionary.searchHandler = (_) async =>
        throw const DictionaryServiceException(
          DictionaryFailureKind.notConfigured,
        );
    await search(tester, '苹果');
    expect(find.text('请先在「我的 → 在线词典」配置 Microsoft Translator'), findsOneWidget);
    dictionary.lookupHandler = (_) async => const DictionaryEntry(
      term: 'rareword',
      source: 'Microsoft Translator',
      senses: [DictionarySense(partOfSpeech: 'n.', definition: 'English only')],
    );
    await search(tester, 'rareword');
    expect(find.text('在线查询失败，请稍后重试'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'old requests cannot restore results after invalid input or clear',
    (tester) async {
      final pending = Completer<DictionaryEntry?>();
      dictionary.lookupHandler = (_) => pending.future;
      await showHome(tester);
      await tester.enterText(find.byKey(input), 'apple');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.enterText(find.byKey(input), '123');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      pending.complete(apple);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-dictionary-result')), findsNothing);
      expect(find.text('请输入中文词语或英文单词、短语'), findsOneWidget);

      final pendingChinese = Completer<List<DictionaryMatch>>();
      dictionary.searchHandler = (_) => pendingChinese.future;
      await tester.enterText(find.byKey(input), '苹果');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.tap(find.byTooltip('清空搜索'));
      pendingChinese.complete(const [
        DictionaryMatch(term: 'apple', chineseDefinition: '苹果'),
      ]);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-dictionary-candidates')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
