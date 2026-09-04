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
