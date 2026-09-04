import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openDatabaseConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final databaseDirectory = Directory(p.join(directory.path, 'database'));
    if (!databaseDirectory.existsSync()) {
      await databaseDirectory.create(recursive: true);
    }

    final file = File(p.join(databaseDirectory.path, 'vocab.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
