import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/infrastructure/dictionary/bilingual_dictionary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late BilingualDictionaryService service;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('vocab-bilingual-test-');
    service = BilingualDictionaryService(
      supportDirectory: () async => directory,
    );
  });
  tearDownAll(() async {
    await service.close();
    await directory.delete(recursive: true);
  });

  test(
    'real assets provide separately attributed Chinese and English',
    () async {
      final entry = (await service.lookup(' APPLE '))!;
      expect(entry.term, 'apple');
      expect(entry.chineseDefinition, contains('苹果'));
      expect(entry.chineseSource, contains('ECDICT'));
      expect(entry.senses.first.definition, contains('fruit'));
      expect(entry.source, contains('Open English WordNet'));
      expect(
        (await service.lookup('serendipity'))!.chineseDefinition,
        contains('偶然发现'),
      );
    },
  );

  test(
    'Chinese reverse lookup ranks exact meanings and opens English words',
    () async {
      final apples = await service.searchChinese(' 苹果 ');
      expect(apples.first.term, 'apple');
      expect(apples.first.chineseDefinition, contains('苹果'));
      final bank = await service.searchChinese('银行');
      expect(bank.map((match) => match.term), contains('bank'));
      final learning = await service.searchChinese('学习');
      expect(learning.map((match) => match.term), contains('learn'));
      expect(
        (await service.lookup(learning.first.term))!.chineseDefinition,
        isNotEmpty,
      );
      expect((await service.searchChinese('学')).length, lessThanOrEqualTo(20));
      expect(await service.searchChinese('不存在的中文词条测试'), isEmpty);
      expect(await service.searchChinese("%' OR 1=1 --"), isEmpty);
      expect(await service.searchChinese(''), isEmpty);
    },
  );

  test(
    'inflections retain English lookup and resolve Chinese headwords',
    () async {
      final entry = (await service.lookup('apples'))!;
      expect(entry.chineseDefinition, contains('苹果'));
      expect(entry.senses, isNotEmpty);
      expect(entry.chineseHeadword, 'apple');
      expect(
        (await service.lookup('running'))!.chineseDefinition,
        contains('赛跑'),
      );
      expect(await service.lookup('not-a-real-word-xyz'), isNull);
      expect(await service.lookup(' '), isNull);
    },
  );

  test('browser favorite examples have offline Chinese definitions', () async {
    for (final term in const ['completed', 'flow', 'explorer', 'diagram']) {
      final entry = await service.lookup(term);
      expect(entry, isNotNull, reason: term);
      expect(entry!.chineseDefinition, isNotEmpty, reason: term);
    }
  });

  test('missing Chinese coverage keeps the original English entry', () async {
    final entry = (await service.lookup('aardvark'))!;
    expect(entry.senses, isNotEmpty);
    expect(entry.chineseDefinition, isNull);
    expect(entry.chineseSource, isNull);
  });

  test(
    'initialization failure can be retried and installed assets reopened',
    () async {
      var calls = 0;
      final retryService = BilingualDictionaryService(
        supportDirectory: () async {
          if (++calls == 1) throw const FileSystemException('test failure');
          return directory;
        },
      );
      try {
        await expectLater(
          retryService.searchChinese('苹果'),
          throwsA(isA<FileSystemException>()),
        );
        expect((await retryService.searchChinese('苹果')).first.term, 'apple');
        await retryService.close();
        expect(
          (await retryService.lookup('apple'))!.chineseDefinition,
          contains('苹果'),
        );
      } finally {
        await retryService.close();
      }
    },
  );
}
