import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/data/local/app_database.dart';
import 'package:vocab/src/data/repositories/ai_settings_repository.dart';
import 'package:vocab/src/data/repositories/learning_repository.dart';
import 'package:vocab/src/domain/coach_models.dart';
import 'package:vocab/src/domain/learning_models.dart';

void main() {
  late AppDatabase database;
  late LearningRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LearningRepository(database);
    await database.customSelect('SELECT 1').get();
  });

  tearDown(() => database.close());

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
