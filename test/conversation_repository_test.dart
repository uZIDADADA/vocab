import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/src/data/local/app_database.dart';
import 'package:vocab/src/data/repositories/conversation_repository.dart';
import 'package:vocab/src/domain/coach_models.dart';

void main() {
  late AppDatabase database;
  late ConversationRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ConversationRepository(database);
    await database.customSelect('SELECT 1').get();
  });

  tearDown(() => database.close());

  test(
    'persists messages and derives a title from the first user message',
    () async {
      final id = await repository.createConversation(initialMessage: 'Hello');
      await repository.addMessage(
        conversationId: id,
        role: CoachRole.user,
        text: 'I want to practice planning my week',
      );
      await repository.useFirstUserMessageAsTitle(
        id,
        'I want to practice planning my week',
      );

      final conversations = await repository.listConversations();
      final messages = await repository.loadMessages(id);
      expect(conversations.single.title, 'I want to practice planning my w…');
      expect(messages.map((message) => message.text), [
        'Hello',
        'I want to practice planning my week',
      ]);
    },
  );

  test('keeps only the configured number of recent conversations', () async {
    await repository.saveRetentionLimit(2);
    await repository.createConversation(initialMessage: 'One');
    await repository.createConversation(initialMessage: 'Two');
    await repository.createConversation(initialMessage: 'Three');

    expect(await repository.loadRetentionLimit(), 2);
    expect(await repository.listConversations(), hasLength(2));
    final messageCount = await database
        .customSelect('SELECT COUNT(*) AS count FROM conversation_messages')
        .getSingle();
    expect(messageCount.read<int>('count'), 2);
  });
}
