class DictionaryEntry {
  const DictionaryEntry({
    required this.term,
    required this.senses,
    required this.source,
    this.chineseDefinition,
    this.chineseSource,
    this.chineseHeadword,
    this.partOfSpeech,
  });

  final String term;
  final List<DictionarySense> senses;
  final String source;
  final String? chineseDefinition;
  final String? chineseSource;
  final String? chineseHeadword;
  final String? partOfSpeech;
}

class DictionaryMatch {
  const DictionaryMatch({required this.term, required this.chineseDefinition});

  final String term;
  final String chineseDefinition;
}

class DictionarySense {
  const DictionarySense({
    required this.partOfSpeech,
    required this.definition,
    this.example,
  });

  final String partOfSpeech;
  final String definition;
  final String? example;
}

abstract interface class DictionaryService {
  Future<DictionaryEntry?> lookup(String term);

  Future<List<DictionaryMatch>> searchChinese(String query);

  Future<void> close();
}

enum DictionaryFailureKind {
  notConfigured,
  authentication,
  rateLimited,
  network,
  service,
}

class DictionaryServiceException implements Exception {
  const DictionaryServiceException(this.kind);

  final DictionaryFailureKind kind;
}
