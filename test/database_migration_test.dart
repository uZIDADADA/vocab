import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:vocab/src/data/local/app_database.dart';

void main() {
  test('upgrades a version 1 database with conversation tables', () async {
    final sqliteDatabase = sqlite3.openInMemory();
    sqliteDatabase.execute('CREATE TABLE legacy_marker (id INTEGER)');
    sqliteDatabase.execute('PRAGMA user_version = 1');
    final database = AppDatabase.forTesting(
      NativeDatabase.opened(sqliteDatabase),
    );

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('conversation_sessions', 'conversation_messages') "
          'ORDER BY name',
        )
        .get();

    expect(tables.map((row) => row.read<String>('name')), [
      'conversation_messages',
      'conversation_sessions',
    ]);
    await database.close();
  });
}
