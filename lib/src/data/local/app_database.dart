import 'package:drift/drift.dart';

import 'database_connection.dart';

part 'app_database.g.dart';

class VocabularyEntries extends Table {
  TextColumn get id => text()();

  TextColumn get term => text().withLength(min: 1, max: 240)();

  TextColumn get definition => text()();

  TextColumn get partOfSpeech => text().nullable()();

  TextColumn get source => text().withDefault(const Constant('手动添加'))();

  TextColumn get sourceContext => text().nullable()();

  TextColumn get tag => text().withDefault(const Constant('未分类'))();

  IntColumn get mastery => integer().withDefault(const Constant(0))();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  DateTimeColumn get reviewDueAt => dateTime().nullable()();

  IntColumn get syncRevision => integer().withDefault(const Constant(0))();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SentencePatterns extends Table {
  TextColumn get id => text()();

  TextColumn get pattern => text().withLength(min: 1, max: 800)();

  TextColumn get meaning => text()();

  TextColumn get category => text().withDefault(const Constant('日常表达'))();

  TextColumn get example => text().nullable()();

  IntColumn get mastery => integer().withDefault(const Constant(0))();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  DateTimeColumn get reviewDueAt => dateTime().nullable()();

  IntColumn get syncRevision => integer().withDefault(const Constant(0))();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReviewEvents extends Table {
  TextColumn get id => text()();

  TextColumn get itemType => text()();

  TextColumn get itemId => text()();

  IntColumn get rating => integer()();

  IntColumn get durationMs => integer().withDefault(const Constant(0))();

  DateTimeColumn get reviewedAt => dateTime()();

  IntColumn get syncRevision => integer().withDefault(const Constant(0))();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class InboxEntries extends Table {
  TextColumn get id => text()();

  TextColumn get kind => text()();

  TextColumn get content => text()();

  TextColumn get source => text().withDefault(const Constant('手动添加'))();

  BoolColumn get isProcessed => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  IntColumn get syncRevision => integer().withDefault(const Constant(0))();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class ConversationSessions extends Table {
  TextColumn get id => text()();

  TextColumn get title => text().withDefault(const Constant('新对话'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ConversationMessages extends Table {
  TextColumn get id => text()();

  TextColumn get conversationId => text().references(
    ConversationSessions,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get role => text()();

  TextColumn get content => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DatabaseStats {
  const DatabaseStats({
    required this.wordCount,
    required this.patternCount,
    required this.dueWordCount,
    required this.duePatternCount,
    required this.inboxCount,
    required this.reviewCount,
  });

  final int wordCount;
  final int patternCount;
  final int dueWordCount;
  final int duePatternCount;
  final int inboxCount;
  final int reviewCount;

  int get dueCount => dueWordCount + duePatternCount;
}

@DriftDatabase(
  tables: [
    VocabularyEntries,
    SentencePatterns,
    ReviewEvents,
    InboxEntries,
    AppSettings,
    ConversationSessions,
    ConversationMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createIndexes();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(conversationSessions);
        await migrator.createTable(conversationMessages);
        await _createConversationIndexes();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      if (details.wasCreated) {
        await seedDemoData();
      }
      await _backfillDemoPatternExamples();
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS vocabulary_term_idx '
      'ON vocabulary_entries(term COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS vocabulary_due_idx '
      'ON vocabulary_entries(review_due_at) WHERE deleted_at IS NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS pattern_due_idx '
      'ON sentence_patterns(review_due_at) WHERE deleted_at IS NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS review_item_idx '
      'ON review_events(item_type, item_id, reviewed_at)',
    );
    await _createConversationIndexes();
  }

  Future<void> _createConversationIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS conversation_updated_idx '
      'ON conversation_sessions(updated_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS conversation_message_idx '
      'ON conversation_messages(conversation_id, created_at)',
    );
  }

  Stream<List<VocabularyEntry>> watchVocabulary({String query = ''}) {
    return _vocabularyQuery(query).watch();
  }

  Future<List<VocabularyEntry>> getVocabulary({String query = ''}) {
    return _vocabularyQuery(query).get();
  }

  SimpleSelectStatement<$VocabularyEntriesTable, VocabularyEntry>
  _vocabularyQuery(String query) {
    final normalized = query.trim();
    final statement = select(vocabularyEntries)
      ..where((row) {
        final active = row.deletedAt.isNull();
        if (normalized.isEmpty) return active;
        final match = '%${_escapeLike(normalized)}%';
        return active &
            (row.term.like(match, escapeChar: r'\') |
                row.definition.like(match, escapeChar: r'\') |
                row.tag.like(match, escapeChar: r'\'));
      })
      ..orderBy([
        (row) => OrderingTerm.desc(row.isFavorite),
        (row) => OrderingTerm.desc(row.updatedAt),
      ]);
    return statement;
  }

  Stream<List<SentencePattern>> watchSentencePatterns({String query = ''}) {
    final normalized = query.trim();
    final statement = select(sentencePatterns)
      ..where((row) {
        final active = row.deletedAt.isNull();
        if (normalized.isEmpty) return active;
        final match = '%${_escapeLike(normalized)}%';
        return active &
            (row.pattern.like(match, escapeChar: r'\') |
                row.meaning.like(match, escapeChar: r'\') |
                row.category.like(match, escapeChar: r'\'));
      })
      ..orderBy([
        (row) => OrderingTerm.desc(row.isFavorite),
        (row) => OrderingTerm.desc(row.updatedAt),
      ]);
    return statement.watch();
  }

  Stream<List<InboxEntry>> watchPendingInboxEntries() {
    return (select(inboxEntries)
          ..where((row) => row.isProcessed.equals(false))
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .watch();
  }

  Future<void> markInboxEntryProcessed(String id) {
    return (update(inboxEntries)..where((row) => row.id.equals(id))).write(
      InboxEntriesCompanion(
        isProcessed: const Value(true),
        isDirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<DatabaseStats> watchStats() {
    return customSelect(
      '''
      SELECT
        (SELECT COUNT(*) FROM vocabulary_entries WHERE deleted_at IS NULL) AS word_count,
        (SELECT COUNT(*) FROM sentence_patterns WHERE deleted_at IS NULL) AS pattern_count,
        (SELECT COUNT(*) FROM vocabulary_entries
          WHERE deleted_at IS NULL
          AND (review_due_at IS NULL OR review_due_at <= CAST(strftime('%s', 'now') AS INTEGER))) AS due_word_count,
        (SELECT COUNT(*) FROM sentence_patterns
          WHERE deleted_at IS NULL
          AND (review_due_at IS NULL OR review_due_at <= CAST(strftime('%s', 'now') AS INTEGER))) AS due_pattern_count,
        (SELECT COUNT(*) FROM inbox_entries WHERE is_processed = 0) AS inbox_count,
        (SELECT COUNT(*) FROM review_events) AS review_count
      ''',
      readsFrom: {
        vocabularyEntries,
        sentencePatterns,
        inboxEntries,
        reviewEvents,
      },
    ).watchSingle().map(
      (row) => DatabaseStats(
        wordCount: row.read<int>('word_count'),
        patternCount: row.read<int>('pattern_count'),
        dueWordCount: row.read<int>('due_word_count'),
        duePatternCount: row.read<int>('due_pattern_count'),
        inboxCount: row.read<int>('inbox_count'),
        reviewCount: row.read<int>('review_count'),
      ),
    );
  }

  Future<String?> getSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((row) => row.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        key: key,
        value: value,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> addVocabulary({
    required String id,
    required String term,
    required String definition,
    String? partOfSpeech,
    String tag = '手动添加',
    String source = '手动添加',
    String? sourceContext,
    bool isFavorite = false,
  }) async {
    final now = DateTime.now();
    await into(vocabularyEntries).insert(
      VocabularyEntriesCompanion.insert(
        id: id,
        term: term.trim(),
        definition: definition.trim(),
        partOfSpeech: Value(_emptyToNull(partOfSpeech)),
        tag: Value(tag),
        source: Value(source),
        sourceContext: Value(_emptyToNull(sourceContext)),
        isFavorite: Value(isFavorite),
        reviewDueAt: Value(now),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<VocabularyEntry?> getActiveVocabularyByTerm(String term) {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) return Future.value(null);
    return (select(vocabularyEntries)
          ..where(
            (row) =>
                row.deletedAt.isNull() & row.term.lower().equals(normalized),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> updateVocabularyDetails({
    required String id,
    required String definition,
    String? partOfSpeech,
    String? sourceContext,
  }) async {
    await (update(vocabularyEntries)..where((row) => row.id.equals(id))).write(
      VocabularyEntriesCompanion(
        definition: Value(definition.trim()),
        partOfSpeech: Value(_emptyToNull(partOfSpeech)),
        sourceContext: Value(_emptyToNull(sourceContext)),
        isDirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> addSentencePattern({
    required String id,
    required String pattern,
    required String meaning,
    String category = '日常表达',
    String? example,
  }) async {
    final now = DateTime.now();
    await into(sentencePatterns).insert(
      SentencePatternsCompanion.insert(
        id: id,
        pattern: pattern.trim(),
        meaning: meaning.trim(),
        category: Value(category),
        example: Value(_emptyToNull(example)),
        reviewDueAt: Value(now),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> setVocabularyFavorite(String id, bool favorite) async {
    await (update(vocabularyEntries)..where((row) => row.id.equals(id))).write(
      VocabularyEntriesCompanion(
        isFavorite: Value(favorite),
        isDirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setPatternFavorite(String id, bool favorite) async {
    await (update(sentencePatterns)..where((row) => row.id.equals(id))).write(
      SentencePatternsCompanion(
        isFavorite: Value(favorite),
        isDirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> softDeleteVocabulary(String id) async {
    final now = DateTime.now();
    await (update(vocabularyEntries)..where((row) => row.id.equals(id))).write(
      VocabularyEntriesCompanion(
        deletedAt: Value(now),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> softDeletePattern(String id) async {
    final now = DateTime.now();
    await (update(sentencePatterns)..where((row) => row.id.equals(id))).write(
      SentencePatternsCompanion(
        deletedAt: Value(now),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> recordReview({
    required String id,
    required String itemType,
    required String itemId,
    required int rating,
    int durationMs = 0,
  }) async {
    assert(rating >= 1 && rating <= 4, 'rating must be between 1 and 4');
    final now = DateTime.now();
    final nextDue = now.add(switch (rating) {
      1 => const Duration(minutes: 10),
      2 => const Duration(days: 1),
      3 => const Duration(days: 3),
      _ => const Duration(days: 7),
    });

    await transaction(() async {
      await into(reviewEvents).insert(
        ReviewEventsCompanion.insert(
          id: id,
          itemType: itemType,
          itemId: itemId,
          rating: rating,
          durationMs: Value(durationMs),
          reviewedAt: now,
        ),
      );

      if (itemType == 'word') {
        await (update(
          vocabularyEntries,
        )..where((row) => row.id.equals(itemId))).write(
          VocabularyEntriesCompanion(
            mastery: Value((rating + 1).clamp(1, 5)),
            reviewDueAt: Value(nextDue),
            isDirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
      } else if (itemType == 'pattern') {
        await (update(
          sentencePatterns,
        )..where((row) => row.id.equals(itemId))).write(
          SentencePatternsCompanion(
            mastery: Value((rating + 1).clamp(1, 5)),
            reviewDueAt: Value(nextDue),
            isDirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<List<VocabularyEntry>> getDueVocabulary() {
    final now = DateTime.now();
    return (select(vocabularyEntries)
          ..where(
            (row) =>
                row.deletedAt.isNull() &
                (row.reviewDueAt.isNull() |
                    row.reviewDueAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.reviewDueAt)]))
        .get();
  }

  Future<List<SentencePattern>> getDueSentencePatterns() {
    final now = DateTime.now();
    return (select(sentencePatterns)
          ..where(
            (row) =>
                row.deletedAt.isNull() &
                (row.reviewDueAt.isNull() |
                    row.reviewDueAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.reviewDueAt)]))
        .get();
  }

  Future<bool> hasActiveVocabularyTerm(String term) async {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final row = await customSelect(
      'SELECT 1 FROM vocabulary_entries '
      'WHERE deleted_at IS NULL AND lower(trim(term)) = ? LIMIT 1',
      variables: [Variable<String>(normalized)],
      readsFrom: {vocabularyEntries},
    ).getSingleOrNull();
    return row != null;
  }

  Future<bool> hasActiveSentencePattern(String pattern) async {
    final normalized = pattern.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final row = await customSelect(
      'SELECT 1 FROM sentence_patterns '
      'WHERE deleted_at IS NULL AND lower(trim(pattern)) = ? LIMIT 1',
      variables: [Variable<String>(normalized)],
      readsFrom: {sentencePatterns},
    ).getSingleOrNull();
    return row != null;
  }

  Future<List<ConversationSession>> listConversationSessions() {
    return (select(
      conversationSessions,
    )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).get();
  }

  Future<List<ConversationMessage>> getConversationMessages(
    String conversationId,
  ) {
    return (select(conversationMessages)
          ..where((row) => row.conversationId.equals(conversationId))
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
        .get();
  }

  Future<void> createConversation({
    required String id,
    required String initialMessageId,
    required String initialMessage,
  }) async {
    final now = DateTime.now();
    await transaction(() async {
      await into(conversationSessions).insert(
        ConversationSessionsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await into(conversationMessages).insert(
        ConversationMessagesCompanion.insert(
          id: initialMessageId,
          conversationId: id,
          role: 'assistant',
          content: initialMessage,
          createdAt: now,
        ),
      );
    });
  }

  Future<void> addConversationMessage({
    required String id,
    required String conversationId,
    required String role,
    required String content,
  }) async {
    final now = DateTime.now();
    await transaction(() async {
      await into(conversationMessages).insert(
        ConversationMessagesCompanion.insert(
          id: id,
          conversationId: conversationId,
          role: role,
          content: content.trim(),
          createdAt: now,
        ),
      );
      await (update(conversationSessions)
            ..where((row) => row.id.equals(conversationId)))
          .write(ConversationSessionsCompanion(updatedAt: Value(now)));
    });
  }

  Future<void> renameConversation(String id, String title) {
    return (update(
      conversationSessions,
    )..where((row) => row.id.equals(id))).write(
      ConversationSessionsCompanion(
        title: Value(title.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteConversation(String id) async {
    await (delete(
      conversationSessions,
    )..where((row) => row.id.equals(id))).go();
  }

  Future<void> clearConversations() async {
    await delete(conversationSessions).go();
  }

  Future<void> pruneConversations(int limit) async {
    final keep = limit.clamp(1, 100);
    final stale = await customSelect(
      'SELECT id FROM conversation_sessions '
      'ORDER BY updated_at DESC LIMIT -1 OFFSET ?',
      variables: [Variable<int>(keep)],
      readsFrom: {conversationSessions},
    ).get();
    if (stale.isEmpty) return;
    await transaction(() async {
      for (final row in stale) {
        await (delete(
          conversationSessions,
        )..where((session) => session.id.equals(row.read<String>('id')))).go();
      }
    });
  }

  Future<void> seedDemoData() async {
    final now = DateTime.now();
    await batch((batch) {
      batch.insertAll(vocabularyEntries, [
        VocabularyEntriesCompanion.insert(
          id: 'demo-word-serendipity',
          term: 'serendipity',
          definition: '意外发现美好事物的能力',
          partOfSpeech: const Value('n.'),
          source: const Value('KISS WebDAV'),
          tag: const Value('网页收藏'),
          mastery: const Value(3),
          reviewDueAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
        VocabularyEntriesCompanion.insert(
          id: 'demo-word-nuance',
          term: 'nuance',
          definition: '细微差别；微妙之处',
          partOfSpeech: const Value('n.'),
          tag: const Value('写作表达'),
          mastery: const Value(4),
          reviewDueAt: Value(now.add(const Duration(days: 2))),
          createdAt: now,
          updatedAt: now.subtract(const Duration(minutes: 1)),
        ),
        VocabularyEntriesCompanion.insert(
          id: 'demo-word-spontaneous',
          term: 'spontaneous',
          definition: '自发的；自然流露的',
          partOfSpeech: const Value('adj.'),
          source: const Value('AI 对练'),
          tag: const Value('AI 对练'),
          mastery: const Value(2),
          reviewDueAt: Value(now),
          createdAt: now,
          updatedAt: now.subtract(const Duration(minutes: 2)),
        ),
      ]);

      batch.insertAll(sentencePatterns, [
        SentencePatternsCompanion.insert(
          id: 'demo-pattern-useful',
          pattern: 'What I find most useful is …',
          meaning: '我觉得最有用的是……',
          category: const Value('表达观点'),
          example: const Value(
            'What I find most useful is the chance to practice every day.',
          ),
          mastery: const Value(2),
          reviewDueAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
        SentencePatternsCompanion.insert(
          id: 'demo-pattern-realize',
          pattern: 'I used to think … but now I realize …',
          meaning: '我过去认为……但现在我意识到……',
          category: const Value('个人成长'),
          example: const Value(
            'I used to think fluency meant speaking fast, but now I realize clarity matters more.',
          ),
          mastery: const Value(3),
          reviewDueAt: Value(now.add(const Duration(days: 1))),
          createdAt: now,
          updatedAt: now.subtract(const Duration(minutes: 1)),
        ),
        SentencePatternsCompanion.insert(
          id: 'demo-pattern-choose',
          pattern: 'If I had to choose, I would …',
          meaning: '如果一定要选，我会……',
          category: const Value('做出选择'),
          example: const Value(
            'If I had to choose, I would spend more time listening.',
          ),
          mastery: const Value(4),
          reviewDueAt: Value(now.add(const Duration(days: 3))),
          createdAt: now,
          updatedAt: now.subtract(const Duration(minutes: 2)),
        ),
      ]);

      batch.insertAll(inboxEntries, [
        for (var index = 0; index < 3; index++)
          InboxEntriesCompanion.insert(
            id: 'demo-inbox-$index',
            kind: index == 0 ? 'word' : 'pattern',
            content: '待整理示例 ${index + 1}',
            source: Value(index == 0 ? 'KISS WebDAV' : 'AI 收藏'),
            createdAt: now.subtract(Duration(minutes: index)),
            updatedAt: now.subtract(Duration(minutes: index)),
          ),
      ]);
    });
  }

  Future<void> _backfillDemoPatternExamples() async {
    final patternTable = await customSelect(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'sentence_patterns'",
    ).get();
    if (patternTable.isEmpty) return;

    const examples = {
      'demo-pattern-useful':
          'What I find most useful is the chance to practice every day.',
      'demo-pattern-realize': 'I used to think fluency meant speaking fast, but now I realize clarity matters more.',
      'demo-pattern-choose':
          'If I had to choose, I would spend more time listening.',
    };
    for (final entry in examples.entries) {
      await (update(sentencePatterns)
            ..where((row) => row.id.equals(entry.key) & row.example.isNull()))
          .write(SentencePatternsCompanion(example: Value(entry.value)));
    }
  }
}

String _escapeLike(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

String? _emptyToNull(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
