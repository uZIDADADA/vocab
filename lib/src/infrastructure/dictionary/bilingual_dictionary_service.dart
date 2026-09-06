import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'dictionary_service.dart';

/// WordNet English definitions plus a separately attributed ECDICT core subset.
/// These dictionaries do not share sense IDs: Chinese glosses are word-level.
class BilingualDictionaryService implements DictionaryService {
  BilingualDictionaryService({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
      _english = WordNetDictionaryService(supportDirectory: supportDirectory);

  static const chineseSource = 'ECDICT 常用词库 · MIT';
  static const _name = 'ecdict-core-v1.sqlite';
  static final _chineseQuery = RegExp(r'^[\u3400-\u9fff]+$');
  final Future<Directory> Function() _supportDirectory;
  final WordNetDictionaryService _english;
  Future<Database>? _databaseFuture;

  Future<Database> _database() async {
    final pending = _databaseFuture ??= _initialize();
    try {
      return await pending;
    } on Object {
      if (identical(pending, _databaseFuture)) _databaseFuture = null;
      rethrow;
    }
  }

  @override
  Future<DictionaryEntry?> lookup(String term) async {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final db = await _database();
    final rows = db.select(
      '''
      WITH candidates(term_id, priority) AS (
        SELECT id, 0 FROM entry WHERE term = ?
        UNION ALL
        SELECT term_id, 1 FROM form WHERE text = ?
      )
      SELECT e.term, e.translation FROM candidates c
      JOIN entry e ON e.id = c.term_id
      ORDER BY c.priority, e.rank, e.term LIMIT 1
    ''',
      [normalized, normalized],
    );
    final chinese = rows.isEmpty ? null : rows.first;
    final chineseHeadword = chinese?['term'] as String?;
    var english = await _english.lookup(normalized);
    if (english == null &&
        chineseHeadword != null &&
        chineseHeadword != normalized) {
      english = await _english.lookup(chineseHeadword);
    }
    if (english == null && chinese == null) return null;
    return DictionaryEntry(
      term: normalized,
      senses: english?.senses ?? const [],
      source: [
        if (chinese != null) chineseSource,
        if (english != null) english.source,
      ].join(' / '),
      chineseDefinition: chinese?['translation'] as String?,
      chineseSource: chinese == null ? null : chineseSource,
      chineseHeadword: chineseHeadword,
    );
  }

  @override
  Future<List<DictionaryMatch>> searchChinese(String query) async {
    final normalized = query.trim();
    if (!_chineseQuery.hasMatch(normalized) || normalized.length > 40) {
      return const [];
    }
    final db = await _database();
    // The primary key supports this prefix range. No scan of definitions or
    // sentence translation: complete gloss matches precede longer phrases.
    final rows = db.select(
      '''
      SELECT e.term, e.translation,
        MIN(CASE WHEN c.text = ? THEN 0 ELSE 1 END) AS priority,
        MIN(length(c.text)) AS gloss_length
      FROM chinese_term c JOIN entry e ON e.id = c.term_id
      WHERE c.text >= ? AND c.text < ?
      GROUP BY e.term
      ORDER BY priority, e.rank, gloss_length, e.term LIMIT 20
    ''',
      [normalized, normalized, '$normalized\uffff'],
    );
    return List.unmodifiable(
      rows.map(
        (row) => DictionaryMatch(
          term: row['term'] as String,
          chineseDefinition: row['translation'] as String,
        ),
      ),
    );
  }

  Future<Database> _initialize() async {
    final root = await _supportDirectory();
    final directory = Directory(p.join(root.path, 'dictionary'));
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, _name));
    if (!await file.exists() || await file.length() == 0) {
      final data = await rootBundle.load('assets/dictionary/$_name.gz');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final path = file.path;
      await Isolate.run(() {
        final temporary = File('$path.tmp');
        temporary.writeAsBytesSync(gzip.decode(bytes), flush: true);
        temporary.renameSync(path);
      });
    }
    return sqlite3.open(file.path, mode: OpenMode.readOnly);
  }

  @override
  Future<void> close() async {
    await _english.close();
    final pending = _databaseFuture;
    _databaseFuture = null;
    if (pending == null) return;
    try {
      (await pending).close();
    } on Object {
      // A failed initialization has no open database to close.
    }
  }
}
