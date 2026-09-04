import 'dart:math';

import '../../domain/coach_models.dart';
import '../local/app_database.dart';

class ConversationRepository {
  ConversationRepository(this._database);

  static const defaultRetentionLimit = 20;
  static const minRetentionLimit = 1;
  static const maxRetentionLimit = 100;
  static const _retentionSettingKey = 'chat.retention_limit';

  final AppDatabase _database;
  final Random _random = Random.secure();

  Future<int> loadRetentionLimit() async {
    final stored = int.tryParse(
      await _database.getSetting(_retentionSettingKey) ?? '',
    );
    return (stored ?? defaultRetentionLimit).clamp(
      minRetentionLimit,
      maxRetentionLimit,
    );
  }

  Future<void> saveRetentionLimit(int value) async {
    final normalized = value.clamp(minRetentionLimit, maxRetentionLimit);
    await _database.setSetting(_retentionSettingKey, '$normalized');
    await _database.pruneConversations(normalized);
  }

  Future<List<CoachConversationSummary>> listConversations() async {
    final rows = await _database.listConversationSessions();
    return rows
        .map(
          (row) => CoachConversationSummary(
            id: row.id,
            title: row.title,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<String> createConversation({required String initialMessage}) async {
    final conversationId = _newId('conversation');
    await _database.createConversation(
      id: conversationId,
      initialMessageId: _newId('message'),
      initialMessage: initialMessage,
    );
    await _database.pruneConversations(await loadRetentionLimit());
    return conversationId;
  }

  Future<List<CoachMessage>> loadMessages(String conversationId) async {
    final rows = await _database.getConversationMessages(conversationId);
    return rows
        .map(
          (row) => CoachMessage(
            id: row.id,
            role: row.role == 'user' ? CoachRole.user : CoachRole.assistant,
            text: row.content,
            createdAt: row.createdAt,
          ),
        )
        .toList(growable: false);
  }

  Future<CoachMessage> addMessage({
    required String conversationId,
    required CoachRole role,
    required String text,
  }) async {
    final id = _newId('message');
    final createdAt = DateTime.now();
    await _database.addConversationMessage(
      id: id,
      conversationId: conversationId,
      role: role == CoachRole.user ? 'user' : 'assistant',
      content: text,
    );
    return CoachMessage(
      id: id,
      role: role,
      text: text.trim(),
      createdAt: createdAt,
    );
  }

  Future<void> useFirstUserMessageAsTitle(
    String conversationId,
    String message,
  ) async {
    final sessions = await _database.listConversationSessions();
    final session = sessions
        .where((row) => row.id == conversationId)
        .firstOrNull;
    if (session == null || session.title != '新对话') return;
    final singleLine = message.trim().replaceAll(RegExp(r'\s+'), ' ');
    final title = singleLine.length <= 32
        ? singleLine
        : '${singleLine.substring(0, 32)}…';
    await _database.renameConversation(conversationId, title);
  }

  Future<void> deleteConversation(String id) =>
      _database.deleteConversation(id);

  Future<void> clearConversations() => _database.clearConversations();

  String _newId(String prefix) {
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final entropy = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    return '$prefix-$micros-$entropy';
  }
}
