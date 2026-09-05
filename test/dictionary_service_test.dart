import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/infrastructure/dictionary/dictionary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled WordNet returns offline definitions', () async {
    final directory = await Directory.systemTemp.createTemp(
      'vocab-wordnet-test-',
    );
    final service = WordNetDictionaryService(
      supportDirectory: () async => directory,
    );
    try {
      final entry = await service.lookup('serendipity');
      expect(entry, isNotNull);
      expect(entry!.term, 'serendipity');
      expect(entry.senses, isNotEmpty);
      expect(entry.senses.first.definition, isNotEmpty);
      expect(entry.source, contains('Open English WordNet 2025'));
      expect(await service.lookup('not-a-real-word-xyz'), isNull);
    } finally {
      await service.close();
      await directory.delete(recursive: true);
    }
  });
}
