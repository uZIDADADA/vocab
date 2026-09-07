import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/application/import/vocabulary_import_coordinator.dart';
import 'package:vocab/src/data/local/app_database.dart';
import 'package:vocab/src/data/repositories/ai_settings_repository.dart';
import 'package:vocab/src/data/repositories/learning_repository.dart';
import 'package:vocab/src/domain/coach_models.dart';
import 'package:vocab/src/domain/learning_models.dart';
import 'package:vocab/src/infrastructure/dictionary/dictionary_service.dart';

void main() {
  late AppDatabase database;
  late LearningRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LearningRepository(database);
    await database.customSelect('SELECT 1').get();
  });

  tearDown(() => database.close());

  test('streak uses distinct calendar days and permits unfinished today', () {
    final now = DateTime(2026, 3, 1, 12);
    expect(LearningRepository.streak([], now), 0);
    final dates = [
      DateTime(2026, 2, 28, 10),
      DateTime(2026, 2, 28, 20),
      DateTime(2026, 2, 27),
    ];
    expect(LearningRepository.streak(dates, now), 2);
    expect(LearningRepository.streak([...dates, now], now), 3);
    expect(LearningRepository.streak(dates, DateTime(2026, 3, 2)), 0);
  });

  test('review calendar reads persisted events', () async {
    expect(await repository.watchReviewDates().first, isEmpty);
    final word = (await repository.watchWords().first).first;
    await repository.review(itemType: 'word', itemId: word.id, rating: 3);
    expect(await repository.watchReviewDates().first, hasLength(1));
  });

  test('upload candidates exclude imported, deleted and demo words', () async {
    expect(await repository.wordsForUpload(), isEmpty);
    await repository.addWord(term: 'phone', definition: '手机');
    await repository.importVocabulary(const [
      ImportedVocabularyCandidate(term: 'remote', definition: '远端'),
    ]);
    expect((await repository.wordsForUpload()).map((word) => word.term), [
      'phone',
    ]);
    final word = (await repository.watchWords(query: 'phone').first).single;
    await repository.deleteWord(word.id);
    expect(await repository.wordsForUpload(), isEmpty);
  });

  test('seeds and searches local vocabulary', () async {
    expect(await repository.watchWords().first, hasLength(3));

    await repository.addWord(
      term: 'deliberate',
      definition: '深思熟虑的',
      partOfSpeech: 'adj.',
    );

    final results = await repository.watchWords(query: 'delib').first;
    expect(results, hasLength(1));
    expect(results.single.term, 'deliberate');
  });

  test('persists favorite changes and soft deletes', () async {
    final word = (await repository.watchWords(query: 'nuance').first).single;
    await repository.toggleWordFavorite(word);

    final favorite =
        (await repository.watchWords(query: 'nuance').first).single;
    expect(favorite.isFavorite, isTrue);

    await repository.deleteWord(word.id);
    expect(await repository.watchWords(query: 'nuance').first, isEmpty);
  });

  test('dictionary favorites are inserted once and stay favorite', () async {
    await repository.favoriteDictionaryWord(
      term: 'fortuitous',
      definition: 'adj. happening by chance',
      partOfSpeech: 'adj.',
      source: 'Open English WordNet 2025 · CC BY 4.0',
      example: 'a fortuitous encounter',
    );
    await repository.favoriteDictionaryWord(
      term: ' FORTUITOUS ',
      definition: 'duplicate',
      partOfSpeech: 'adj.',
      source: 'Open English WordNet 2025 · CC BY 4.0',
    );

    final words = await repository.watchWords(query: 'fortuitous').first;
    expect(words, hasLength(1));
    expect(words.single.isFavorite, isTrue);
    expect(words.single.source, contains('Open English WordNet'));
  });

  test('records review events and updates statistics', () async {
    final initialStats = await repository.watchStats().first;
    expect(initialStats.wordCount, 3);
    expect(initialStats.patternCount, 3);
    expect(initialStats.dueWordCount, 2);
    expect(initialStats.duePatternCount, 1);
    expect(initialStats.inboxCount, 3);

    final pattern = (await repository.watchPatterns().first).first;
    await repository.review(
      itemType: 'pattern',
      itemId: pattern.id,
      rating: 4,
      durationMs: 1800,
    );

    final stats = await repository.watchStats().first;
    expect(stats.reviewCount, 1);
  });

  test('lists pending inbox entries and marks them processed', () async {
    final initialItems = await repository.watchPendingInbox().first;
    expect(initialItems, hasLength(3));

    await repository.markInboxProcessed(initialItems.first.id);

    final remainingItems = await repository.watchPendingInbox().first;
    final stats = await repository.watchStats().first;
    expect(remainingItems, hasLength(2));
    expect(
      remainingItems.any((item) => item.id == initialItems.first.id),
      isFalse,
    );
    expect(stats.inboxCount, 2);
  });

  test(
    'stores AI metadata in SQLite and API key in the secret store',
    () async {
      final secretStore = MemoryAiSecretStore();
      final settingsRepository = AiSettingsRepository(database, secretStore);

      await settingsRepository.save(
        const AiProviderConfig.gemini(),
        replacementApiKey: 'gemini-test-key',
      );

      final settings = await settingsRepository.load();
      expect(settings.config.kind, AiProviderKind.gemini);
      expect(settings.config.model, 'gemini-3.1-flash-lite');
      expect(settings.apiKey, 'gemini-test-key');
      expect(settings.isConfigured, isTrue);
      expect(await database.getSetting('ai.api_key'), isNull);
    },
  );

  test('imports KISS words once and places them in the review queue', () async {
    const candidate = ImportedVocabularyCandidate(
      term: 'artifact',
      definition: '人工制品；产物',
      phonetic: '/ˈɑːrtɪfækt/',
      examples: ['This file is a build artifact.'],
    );

    final first = await repository.importVocabulary([candidate]);
    final second = await repository.importVocabulary([candidate]);
    final due = await repository.getDueReviews();

    expect(first.importedCount, 1);
    expect(second.skippedCount, 1);
    expect(due.any((item) => item.prompt == 'artifact'), isTrue);
    final imported =
        (await repository.watchWords(query: 'artifact').first).single;
    expect(imported.source, 'KISS-Worker');
    expect(imported.tag, '浏览器收藏');
  });

  test('fills missing KISS definitions from the offline dictionary', () async {
    await repository.importVocabulary(const [
      ImportedVocabularyCandidate(term: 'artifact', definition: ''),
    ]);
    expect(
      (await repository.watchWords(query: 'artifact').first).single.definition,
      '待补充释义',
    );

    final coordinator = VocabularyImportCoordinator(
      repository,
      const _DictionaryStub(),
    );
    final result = await coordinator.repairImportedDefinitions();
    final repaired =
        (await repository.watchWords(query: 'artifact').first).single;

    expect(result.updatedCount, 1);
    expect(result.importedCount, 0);
    expect(repaired.definition, '人工制品；产物');
    expect(repaired.partOfSpeech, 'n.');
    expect(
      (await repository.getDueReviews())
          .singleWhere((item) => item.prompt == 'artifact')
          .example,
      'This file is a build artifact.',
    );
  });

  test(
    'dictionary enrichment never overwrites an existing definition',
    () async {
      const candidate = ImportedVocabularyCandidate(
        term: 'artifact',
        definition: '我自己的释义',
      );
      await repository.importVocabulary(const [candidate]);
      final coordinator = VocabularyImportCoordinator(
        repository,
        const _DictionaryStub(),
      );

      final result = await coordinator.importVocabulary(const [candidate]);

      expect(result.updatedCount, 0);
      expect(result.skippedCount, 1);
      expect(
        (await repository.watchWords(query: 'artifact').first)
            .single
            .definition,
        '我自己的释义',
      );
    },
  );

  test(
    'saves confirmed AI suggestions independently of chat history',
    () async {
      const suggestions = [
        CoachLearningSuggestion(
          kind: CoachLearningKind.word,
          text: 'deliberately',
          meaning: '故意地；审慎地',
          example: 'She spoke deliberately.',
        ),
        CoachLearningSuggestion(
          kind: CoachLearningKind.pattern,
          text: 'What matters most is …',
          meaning: '最重要的是……',
        ),
      ];

      expect(await repository.saveCoachSuggestions(suggestions), 2);
      expect(await repository.saveCoachSuggestions(suggestions), 0);
      expect(
        (await repository.watchWords(query: 'deliberately').first)
            .single
            .source,
        'AI 对练',
      );
      expect(
        (await repository.watchPatterns(query: 'matters most').first)
            .single
            .category,
        'AI 对练',
      );
    },
  );
}

class _DictionaryStub implements DictionaryService {
  const _DictionaryStub();

  @override
  Future<DictionaryEntry?> lookup(String term) async => DictionaryEntry(
    term: term,
    source: 'ECDICT 常用词库 · MIT / Open English WordNet 2025 · CC BY 4.0',
    chineseDefinition: '人工制品；产物',
    senses: const [
      DictionarySense(
        partOfSpeech: 'n.',
        definition: 'an object made by a person',
        example: 'This file is a build artifact.',
      ),
    ],
  );

  @override
  Future<List<DictionaryMatch>> searchChinese(String query) async => const [];

  @override
  Future<void> close() async {}
}
