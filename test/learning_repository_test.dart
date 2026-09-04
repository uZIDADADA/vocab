import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/data/local/app_database.dart';
import 'package:vocab/src/data/repositories/learning_repository.dart';

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
}
