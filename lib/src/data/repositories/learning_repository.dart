import 'dart:math';

import '../../domain/learning_models.dart';
import '../local/app_database.dart';

class LearningRepository {
  LearningRepository(this._database);

  final AppDatabase _database;
  final Random _random = Random.secure();

  Stream<List<WordItem>> watchWords({String query = ''}) {
    return _database
        .watchVocabulary(query: query)
        .map(
          (rows) => rows
              .map(
                (row) => WordItem(
                  id: row.id,
                  term: row.term,
                  definition: row.definition,
                  partOfSpeech: row.partOfSpeech,
                  source: row.source,
                  tag: row.tag,
                  mastery: row.mastery,
                  isFavorite: row.isFavorite,
                  reviewDueAt: row.reviewDueAt,
                  updatedAt: row.updatedAt,
                ),
              )
              .toList(growable: false),
        );
  }

  Stream<List<PatternItem>> watchPatterns({String query = ''}) {
    return _database
        .watchSentencePatterns(query: query)
        .map(
          (rows) => rows
              .map(
                (row) => PatternItem(
                  id: row.id,
                  pattern: row.pattern,
                  meaning: row.meaning,
                  category: row.category,
                  example: row.example,
                  mastery: row.mastery,
                  isFavorite: row.isFavorite,
                  reviewDueAt: row.reviewDueAt,
                  updatedAt: row.updatedAt,
                ),
              )
              .toList(growable: false),
        );
  }

  Stream<LearningStats> watchStats() {
    return _database.watchStats().map(
      (stats) => LearningStats(
        wordCount: stats.wordCount,
        patternCount: stats.patternCount,
        dueWordCount: stats.dueWordCount,
        duePatternCount: stats.duePatternCount,
        inboxCount: stats.inboxCount,
        reviewCount: stats.reviewCount,
      ),
    );
  }

  Future<void> addWord({
    required String term,
    required String definition,
    String? partOfSpeech,
    String tag = '手动添加',
  }) {
    return _database.addVocabulary(
      id: _newId('word'),
      term: term,
      definition: definition,
      partOfSpeech: partOfSpeech,
      tag: tag,
    );
  }

  Future<void> addPattern({
    required String pattern,
    required String meaning,
    String category = '日常表达',
    String? example,
  }) {
    return _database.addSentencePattern(
      id: _newId('pattern'),
      pattern: pattern,
      meaning: meaning,
      category: category,
      example: example,
    );
  }

  Future<void> toggleWordFavorite(WordItem item) {
    return _database.setVocabularyFavorite(item.id, !item.isFavorite);
  }

  Future<void> togglePatternFavorite(PatternItem item) {
    return _database.setPatternFavorite(item.id, !item.isFavorite);
  }

  Future<void> deleteWord(String id) => _database.softDeleteVocabulary(id);

  Future<void> deletePattern(String id) => _database.softDeletePattern(id);

  Future<void> review({
    required String itemType,
    required String itemId,
    required int rating,
    int durationMs = 0,
  }) {
    return _database.recordReview(
      id: _newId('review'),
      itemType: itemType,
      itemId: itemId,
      rating: rating,
      durationMs: durationMs,
    );
  }

  String _newId(String prefix) {
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final entropy = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    return '$prefix-$micros-$entropy';
  }
}
