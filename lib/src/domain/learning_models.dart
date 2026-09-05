class WordItem {
  const WordItem({
    required this.id,
    required this.term,
    required this.definition,
    required this.partOfSpeech,
    required this.source,
    required this.tag,
    required this.mastery,
    required this.isFavorite,
    required this.reviewDueAt,
    required this.updatedAt,
  });

  final String id;
  final String term;
  final String definition;
  final String? partOfSpeech;
  final String source;
  final String tag;
  final int mastery;
  final bool isFavorite;
  final DateTime? reviewDueAt;
  final DateTime updatedAt;
}

class PatternItem {
  const PatternItem({
    required this.id,
    required this.pattern,
    required this.meaning,
    required this.category,
    required this.example,
    required this.mastery,
    required this.isFavorite,
    required this.reviewDueAt,
    required this.updatedAt,
  });

  final String id;
  final String pattern;
  final String meaning;
  final String category;
  final String? example;
  final int mastery;
  final bool isFavorite;
  final DateTime? reviewDueAt;
  final DateTime updatedAt;
}

class LearningStats {
  const LearningStats({
    required this.wordCount,
    required this.patternCount,
    required this.dueWordCount,
    required this.duePatternCount,
    required this.inboxCount,
    required this.reviewCount,
  });

  const LearningStats.empty()
    : wordCount = 0,
      patternCount = 0,
      dueWordCount = 0,
      duePatternCount = 0,
      inboxCount = 0,
      reviewCount = 0;

  final int wordCount;
  final int patternCount;
  final int dueWordCount;
  final int duePatternCount;
  final int inboxCount;
  final int reviewCount;

  int get dueCount => dueWordCount + duePatternCount;
}

class InboxItem {
  const InboxItem({
    required this.id,
    required this.kind,
    required this.content,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String content;
  final String source;
  final DateTime createdAt;
}

class ImportedVocabularyCandidate {
  const ImportedVocabularyCandidate({
    required this.term,
    required this.definition,
    this.phonetic,
    this.examples = const [],
    this.sourceTimestamp,
  });

  final String term;
  final String definition;
  final String? phonetic;
  final List<String> examples;
  final DateTime? sourceTimestamp;
}

class VocabularyImportResult {
  const VocabularyImportResult({
    required this.importedCount,
    required this.skippedCount,
  });

  final int importedCount;
  final int skippedCount;
}

class ReviewQueueItem {
  const ReviewQueueItem({
    required this.itemType,
    required this.itemId,
    required this.prompt,
    required this.answer,
    required this.label,
    this.phonetic,
    this.partOfSpeech,
    this.example,
  });

  final String itemType;
  final String itemId;
  final String prompt;
  final String answer;
  final String label;
  final String? phonetic;
  final String? partOfSpeech;
  final String? example;
}
