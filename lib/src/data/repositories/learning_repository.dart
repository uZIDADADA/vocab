import 'dart:convert';
import 'dart:math';

import '../../domain/learning_models.dart';
import '../../domain/coach_models.dart';
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

  Stream<List<InboxItem>> watchPendingInbox() {
    return _database.watchPendingInboxEntries().map(
      (rows) => rows
          .map(
            (row) => InboxItem(
              id: row.id,
              kind: row.kind,
              content: row.content,
              source: row.source,
              createdAt: row.createdAt,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> markInboxProcessed(String id) {
    return _database.markInboxEntryProcessed(id);
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

  Stream<List<DateTime>> watchReviewDates() => _database
      .select(_database.reviewEvents)
      .watch()
      .map((rows) => rows.map((row) => row.reviewedAt.toLocal()).toList());

  static int streak(List<DateTime> dates, DateTime now) {
    final days = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    var day = DateTime(now.year, now.month, now.day);
    if (!days.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
    var count = 0;
    while (days.contains(day)) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  Future<List<ImportedVocabularyCandidate>> wordsForUpload() async {
    final rows = await _database.watchVocabulary().first;
    return [
      for (final row in rows)
        if (!row.id.startsWith('demo-') &&
            (row.source == '手动添加' || row.source == 'AI 对练'))
          ImportedVocabularyCandidate(
            term: row.term,
            definition: row.definition,
            sourceTimestamp: row.createdAt,
            phonetic: _readContextText(row.sourceContext, 'phonetic'),
            examples: [?_readContextText(row.sourceContext, 'example')],
          ),
    ];
  }

  Future<void> addWord({
    required String term,
    required String definition,
    String? partOfSpeech,
    String tag = '手动添加',
    String source = '手动添加',
    String? sourceContext,
    bool isFavorite = false,
  }) {
    return _database.addVocabulary(
      id: _newId('word'),
      term: term,
      definition: definition,
      partOfSpeech: partOfSpeech,
      tag: tag,
      source: source,
      sourceContext: sourceContext,
      isFavorite: isFavorite,
    );
  }

  Future<void> favoriteDictionaryWord({
    required String term,
    required String definition,
    required String partOfSpeech,
    required String source,
    String? example,
  }) async {
    final words = await watchWords(query: term).first;
    for (final word in words) {
      if (word.term.trim().toLowerCase() == term.trim().toLowerCase()) {
        if (!word.isFavorite) {
          await _database.setVocabularyFavorite(word.id, true);
        }
        return;
      }
    }
    await addWord(
      term: term,
      definition: definition,
      partOfSpeech: partOfSpeech,
      tag: '词典收藏',
      source: source,
      sourceContext: example == null ? null : jsonEncode({'example': example}),
      isFavorite: true,
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

  static String? _readContextText(String? sourceContext, String key) {
    if (sourceContext == null) return null;
    try {
      final decoded = jsonDecode(sourceContext);
      if (decoded is! Map<String, dynamic>) return null;
      final phonetic = decoded[key];
      return phonetic is String && phonetic.trim().isNotEmpty
          ? phonetic.trim()
          : null;
    } on FormatException {
      return null;
    }
  }

  Future<List<ReviewQueueItem>> getDueReviews() async {
    final results = await Future.wait([
      _database.getDueVocabulary(),
      _database.getDueSentencePatterns(),
    ]);
    final words = results[0].cast<VocabularyEntry>();
    final patterns = results[1].cast<SentencePattern>();
    return [
      for (final word in words)
        ReviewQueueItem(
          itemType: 'word',
          itemId: word.id,
          prompt: word.term,
          answer: word.definition,
          label: word.tag,
          phonetic: _readContextText(word.sourceContext, 'phonetic'),
          partOfSpeech: word.partOfSpeech,
          example: _readContextText(word.sourceContext, 'example'),
        ),
      for (final pattern in patterns)
        ReviewQueueItem(
          itemType: 'pattern',
          itemId: pattern.id,
          prompt: pattern.pattern,
          answer: pattern.meaning,
          label: pattern.category,
          example: pattern.example,
        ),
    ];
  }

  Future<VocabularyImportResult> importVocabulary(
    Iterable<ImportedVocabularyCandidate> candidates,
  ) async {
    var imported = 0;
    var skipped = 0;
    final seen = <String>{};
    for (final candidate in candidates) {
      final term = candidate.term.trim();
      final normalized = term.toLowerCase();
      if (term.isEmpty || !seen.add(normalized)) {
        skipped++;
        continue;
      }
      if (await _database.hasActiveVocabularyTerm(term)) {
        skipped++;
        continue;
      }
      await _database.addVocabulary(
        id: _newId('word'),
        term: term,
        definition: candidate.definition.trim().isEmpty
            ? '待补充释义'
            : candidate.definition.trim(),
        source: 'KISS-Worker',
        tag: '浏览器收藏',
        sourceContext: jsonEncode({
          if (candidate.phonetic?.trim().isNotEmpty == true)
            'phonetic': candidate.phonetic!.trim(),
          if (candidate.examples.isNotEmpty) 'examples': candidate.examples,
          if (candidate.sourceTimestamp != null)
            'timestamp': candidate.sourceTimestamp!.toIso8601String(),
        }),
      );
      imported++;
    }
    return VocabularyImportResult(
      importedCount: imported,
      skippedCount: skipped,
    );
  }

  Future<int> saveCoachSuggestions(
    Iterable<CoachLearningSuggestion> suggestions,
  ) async {
    var saved = 0;
    for (final suggestion in suggestions) {
      final text = suggestion.text.trim();
      final meaning = suggestion.meaning.trim();
      if (text.isEmpty || meaning.isEmpty) continue;
      if (suggestion.kind == CoachLearningKind.word) {
        if (await _database.hasActiveVocabularyTerm(text)) continue;
        await addWord(
          term: text,
          definition: meaning,
          tag: 'AI 提取',
          source: 'AI 对练',
          sourceContext: jsonEncode({
            if (suggestion.example?.trim().isNotEmpty == true)
              'example': suggestion.example!.trim(),
          }),
        );
      } else {
        if (await _database.hasActiveSentencePattern(text)) continue;
        await addPattern(
          pattern: text,
          meaning: meaning,
          category: 'AI 对练',
          example: suggestion.example,
        );
      }
      saved++;
    }
    return saved;
  }

  String _newId(String prefix) {
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final entropy = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    return '$prefix-$micros-$entropy';
  }
}
