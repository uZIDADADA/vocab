import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class DictionaryEntry {
  const DictionaryEntry({
    required this.term,
    required this.senses,
    required this.source,
  });

  final String term;
  final List<DictionarySense> senses;
  final String source;
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

  Future<void> close();
}

/// Offline English definitions backed by Open English WordNet 2025.
class WordNetDictionaryService implements DictionaryService {
  WordNetDictionaryService({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  static const _assetPath = 'assets/dictionary/oewn-2025-v2.3.2.sqlite.gz';
  static const _databaseName = 'oewn-2025-v2.3.2.sqlite';

  final Future<Directory> Function() _supportDirectory;
  Future<Database>? _databaseFuture;

  @override
  Future<DictionaryEntry?> lookup(String term) async {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final pendingDatabase = _databaseFuture ??= _initialize();
    late final Database database;
    try {
      database = await pendingDatabase;
    } on Object {
      if (identical(_databaseFuture, pendingDatabase)) {
        _databaseFuture = null;
      }
      rethrow;
    }
    final rows = database.select(
      '''
      WITH candidates(word_id, priority) AS (
        SELECT id, 0 FROM word WHERE text = ? COLLATE NOCASE
        UNION
        SELECT wm.word_id, 1
        FROM morphological_form mf
        JOIN word_morphology wm ON wm.morphological_form_id = mf.id
        WHERE mf.text = ? COLLATE NOCASE
      )
      SELECT
        s.id AS synset_id,
        s.part_of_speech_id AS part_of_speech,
        s.definition AS definition,
        (SELECT text FROM sample WHERE synset_id = s.id ORDER BY id LIMIT 1)
          AS example
      FROM candidates c
      JOIN sense se ON se.word_id = c.word_id
      JOIN synset s ON s.id = se.synset_id
      ORDER BY c.priority, se.sense_sort_order, s.id
      LIMIT 12
      ''',
      [normalized, normalized],
    );
    if (rows.isEmpty) return null;

    final senses = <DictionarySense>[];
    final definitions = <String>{};
    for (final row in rows) {
      final definition = (row['definition'] as String).trim();
      if (definition.isEmpty || !definitions.add(definition)) continue;
      final example = (row['example'] as String?)?.trim();
      senses.add(
        DictionarySense(
          partOfSpeech: _partOfSpeechLabel(row['part_of_speech'] as String),
          definition: definition,
          example: example == null || example.isEmpty ? null : example,
        ),
      );
      if (senses.length == 3) break;
    }
    if (senses.isEmpty) return null;

    return DictionaryEntry(
      term: normalized,
      senses: List.unmodifiable(senses),
      source: 'Open English WordNet 2025 · CC BY 4.0',
    );
  }

  Future<Database> _initialize() async {
    final root = await _supportDirectory();
    final directory = Directory(p.join(root.path, 'dictionary'));
    await directory.create(recursive: true);
    final database = File(p.join(directory.path, _databaseName));
    if (!await database.exists() || await database.length() == 0) {
      final data = await rootBundle.load(_assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await Isolate.run(() => _installDatabase(bytes, database.path));
    }
    return sqlite3.open(database.path, mode: OpenMode.readOnly);
  }

  @override
  Future<void> close() async {
    final future = _databaseFuture;
    _databaseFuture = null;
    if (future == null) return;
    try {
      (await future).close();
    } on Object {
      // Initialization failures do not leave a database to close.
    }
  }
}

void _installDatabase(Uint8List compressed, String databasePath) {
  final database = File(databasePath);
  final temporary = File('$databasePath.tmp');
  temporary.writeAsBytesSync(gzip.decode(compressed), flush: true);
  if (database.existsSync()) database.deleteSync();
  temporary.renameSync(databasePath);
}

String _partOfSpeechLabel(String id) => switch (id) {
  'n' => 'n.',
  'v' => 'v.',
  'r' => 'adv.',
  'a' || 's' => 'adj.',
  _ => id,
};
