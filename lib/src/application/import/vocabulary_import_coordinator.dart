import '../../data/repositories/learning_repository.dart';
import '../../domain/learning_models.dart';
import '../../infrastructure/dictionary/dictionary_service.dart';

/// Coordinates KISS imports. Optional enrichment is retained for tests and
/// embedders, but the app no longer sends imported terms to an online service.
class VocabularyImportCoordinator {
  const VocabularyImportCoordinator(
    this._repository, [
    this._dictionaryService,
  ]);

  final LearningRepository _repository;
  final DictionaryService? _dictionaryService;

  Future<VocabularyImportResult> importVocabulary(
    Iterable<ImportedVocabularyCandidate> candidates,
  ) async {
    final enriched = <ImportedVocabularyCandidate>[];
    for (final candidate in candidates) {
      enriched.add(await _enrich(candidate));
    }
    return _repository.importVocabulary(enriched);
  }

  Future<VocabularyImportResult> repairImportedDefinitions() async {
    final candidates = await _repository.importedWordsMissingDefinition();
    if (candidates.isEmpty) {
      return const VocabularyImportResult(importedCount: 0, skippedCount: 0);
    }
    return importVocabulary(candidates);
  }

  Future<ImportedVocabularyCandidate> _enrich(
    ImportedVocabularyCandidate candidate,
  ) async {
    if (candidate.definition.trim().isNotEmpty &&
        candidate.definition.trim() != '待补充释义') {
      return candidate;
    }

    final dictionaryService = _dictionaryService;
    if (dictionaryService == null) return candidate;

    DictionaryEntry? entry;
    try {
      entry = await dictionaryService.lookup(candidate.term);
    } on Object {
      // Dictionary enrichment is best effort; a failed lookup must not block
      // importing the user's browser favorites.
      return candidate;
    }
    if (entry == null) return candidate;

    final chinese = entry.chineseDefinition?.trim();
    final definition = chinese?.isNotEmpty == true
        ? chinese!
        : entry.senses
              .map(
                (sense) => '${sense.partOfSpeech} ${sense.definition}'.trim(),
              )
              .where((value) => value.isNotEmpty)
              .join('\n');
    if (definition.isEmpty) return candidate;

    final parts = entry.partOfSpeech?.trim().isNotEmpty == true
        ? entry.partOfSpeech!.trim()
        : entry.senses
              .map((sense) => sense.partOfSpeech.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .join(' / ');
    final dictionaryExamples = entry.senses
        .map((sense) => sense.example?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    return ImportedVocabularyCandidate(
      term: candidate.term,
      definition: definition,
      partOfSpeech: candidate.partOfSpeech ?? (parts.isEmpty ? null : parts),
      phonetic: candidate.phonetic,
      examples: candidate.examples.isEmpty
          ? dictionaryExamples
          : candidate.examples,
      sourceTimestamp: candidate.sourceTimestamp,
      dictionarySource: entry.source,
    );
  }
}
