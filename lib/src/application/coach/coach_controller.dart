import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/repositories/ai_settings_repository.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../domain/coach_models.dart';
import '../../infrastructure/ai/ai_chat_provider.dart';

class CoachController extends ChangeNotifier {
  CoachController(
    this._settingsRepository,
    this._conversationRepository,
    this._provider,
  );

  static const _firstGreeting =
      'Hi! I’m your English conversation coach. What would you like to talk about today?';
  static const _newGreeting =
      'New conversation started. What shall we practice?';

  final AiSettingsRepository _settingsRepository;
  final ConversationRepository _conversationRepository;
  final AiChatProvider _provider;
  final List<CoachMessage> _messages = [];
  List<CoachConversationSummary> _conversations = const [];
  String? _currentConversationId;
  int _retentionLimit = ConversationRepository.defaultRetentionLimit;

  AiChatSettings _settings = const AiChatSettings(
    config: AiProviderConfig.gemini(),
    apiKey: null,
  );
  bool _isInitializing = true;
  bool _isSending = false;
  bool _isExtracting = false;
  String? _errorMessage;

  UnmodifiableListView<CoachMessage> get messages =>
      UnmodifiableListView(_messages);
  UnmodifiableListView<CoachConversationSummary> get conversations =>
      UnmodifiableListView(_conversations);
  String? get currentConversationId => _currentConversationId;
  int get retentionLimit => _retentionLimit;
  AiChatSettings get settings => _settings;
  bool get isInitializing => _isInitializing;
  bool get isSending => _isSending;
  bool get isExtracting => _isExtracting;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    try {
      final results = await Future.wait([
        _settingsRepository.load(),
        _conversationRepository.loadRetentionLimit(),
        _conversationRepository.listConversations(),
      ]);
      _settings = results[0] as AiChatSettings;
      _retentionLimit = results[1] as int;
      _conversations = results[2] as List<CoachConversationSummary>;
      if (_conversations.isEmpty) {
        await _createConversation(_firstGreeting);
      } else {
        await _loadConversation(_conversations.first.id);
      }
    } catch (_) {
      _errorMessage = '读取 AI 设置或历史对话失败，请稍后重试。';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> saveSettings(
    AiProviderConfig config, {
    String? replacementApiKey,
  }) async {
    final baseUri = Uri.tryParse(config.baseUrl.trim());
    if (baseUri == null ||
        !baseUri.hasScheme ||
        (baseUri.scheme != 'https' && baseUri.scheme != 'http')) {
      _errorMessage = '请输入以 http:// 或 https:// 开头的 Base URL。';
      notifyListeners();
      return false;
    }
    if (config.model.trim().isEmpty) {
      _errorMessage = '请输入模型名称。';
      notifyListeners();
      return false;
    }
    if (config.kind != _settings.config.kind &&
        replacementApiKey?.trim().isEmpty != false) {
      _errorMessage = '切换 AI 服务提供商时，请填写对应的 API Key。';
      notifyListeners();
      return false;
    }
    if (!_settings.isConfigured && replacementApiKey?.trim().isEmpty != false) {
      _errorMessage = '首次配置需要填写 API Key。';
      notifyListeners();
      return false;
    }

    try {
      await _settingsRepository.save(
        config,
        replacementApiKey: replacementApiKey,
      );
      _settings = await _settingsRepository.load();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = '保存 AI 设置失败。';
      notifyListeners();
      return false;
    }
  }

  Future<bool> send(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty || _isSending) return false;
    if (!_settings.isConfigured) {
      _errorMessage = '请先配置 AI 服务和 API Key。';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _errorMessage = null;

    try {
      final conversationId =
          _currentConversationId ?? await _createConversation(_newGreeting);
      final userMessage = await _conversationRepository.addMessage(
        conversationId: conversationId,
        role: CoachRole.user,
        text: normalized,
      );
      _messages.add(userMessage);
      await _conversationRepository.useFirstUserMessageAsTitle(
        conversationId,
        normalized,
      );
      await _refreshConversations();
      notifyListeners();
      final reply = await _provider.complete(
        config: _settings.config,
        apiKey: _settings.apiKey!,
        messages: List.unmodifiable(_messages),
      );
      final assistantMessage = await _conversationRepository.addMessage(
        conversationId: conversationId,
        role: CoachRole.assistant,
        text: reply,
      );
      _messages.add(assistantMessage);
      await _refreshConversations();
      return true;
    } on AiChatException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '发生了未知错误，请稍后重试。';
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<List<CoachLearningSuggestion>?> extractLearningItems(
    CoachMessage message,
  ) async {
    if (_isSending || _isExtracting) return null;
    if (!_settings.isConfigured) {
      _errorMessage = '请先配置 AI 服务。';
      notifyListeners();
      return null;
    }
    _isExtracting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _provider.complete(
        config: _settings.config,
        apiKey: _settings.apiKey!,
        systemInstruction: '''
You extract useful English learning items from one chat message for a Chinese learner.
Return only a JSON array with at most 8 objects. Each object must use:
{"type":"word"|"pattern","text":"English item","meaning":"concise Chinese meaning","example":"optional English example"}
Prefer reusable words, collocations, and sentence patterns. Do not include names or trivial words. Return [] when nothing is useful.
''',
        messages: [
          CoachMessage(
            role: CoachRole.user,
            text: 'Extract learning items from this message:\n${message.text}',
          ),
        ],
      );
      return _parseSuggestions(response);
    } on AiChatException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'AI 返回的整理结果无法解析，请重试。';
      return null;
    } finally {
      _isExtracting = false;
      notifyListeners();
    }
  }

  Future<void> newConversation() async {
    if (_isSending) return;
    try {
      await _createConversation(_newGreeting);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = '创建新对话失败。';
    }
    notifyListeners();
  }

  Future<void> openConversation(String id) async {
    if (_isSending || id == _currentConversationId) return;
    try {
      await _loadConversation(id);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = '读取历史对话失败。';
    }
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    if (_isSending) return;
    try {
      await _conversationRepository.deleteConversation(id);
      await _refreshConversations();
      if (_currentConversationId == id) {
        if (_conversations.isEmpty) {
          await _createConversation(_newGreeting);
        } else {
          await _loadConversation(_conversations.first.id);
        }
      }
      _errorMessage = null;
    } catch (_) {
      _errorMessage = '删除对话失败。';
    }
    notifyListeners();
  }

  Future<void> clearAllConversations() async {
    if (_isSending) return;
    try {
      await _conversationRepository.clearConversations();
      await _createConversation(_newGreeting);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = '清空对话失败。';
    }
    notifyListeners();
  }

  Future<bool> updateRetentionLimit(int value) async {
    try {
      await _conversationRepository.saveRetentionLimit(value);
      _retentionLimit = await _conversationRepository.loadRetentionLimit();
      await _refreshConversations();
      if (_currentConversationId != null &&
          !_conversations.any((item) => item.id == _currentConversationId)) {
        await _loadConversation(_conversations.first.id);
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = '保存对话保留数量失败。';
      notifyListeners();
      return false;
    }
  }

  Future<String> _createConversation(String greeting) async {
    final id = await _conversationRepository.createConversation(
      initialMessage: greeting,
    );
    await _refreshConversations();
    await _loadConversation(id);
    return id;
  }

  Future<void> _loadConversation(String id) async {
    final loaded = await _conversationRepository.loadMessages(id);
    _currentConversationId = id;
    _messages
      ..clear()
      ..addAll(loaded);
  }

  Future<void> _refreshConversations() async {
    _conversations = await _conversationRepository.listConversations();
  }

  List<CoachLearningSuggestion> _parseSuggestions(String response) {
    final start = response.indexOf('[');
    final end = response.lastIndexOf(']');
    if (start < 0 || end < start) throw const FormatException();
    final decoded = jsonDecode(response.substring(start, end + 1));
    if (decoded is! List<dynamic>) throw const FormatException();
    final suggestions = <CoachLearningSuggestion>[];
    for (final value in decoded.take(8)) {
      if (value is! Map<String, dynamic>) continue;
      final text = value['text'];
      final meaning = value['meaning'];
      if (text is! String || meaning is! String) continue;
      final kind = value['type'] == 'word'
          ? CoachLearningKind.word
          : value['type'] == 'pattern'
          ? CoachLearningKind.pattern
          : null;
      if (kind == null || text.trim().isEmpty || meaning.trim().isEmpty) {
        continue;
      }
      suggestions.add(
        CoachLearningSuggestion(
          kind: kind,
          text: text.trim(),
          meaning: meaning.trim(),
          example: value['example'] is String
              ? (value['example'] as String).trim()
              : null,
        ),
      );
    }
    return suggestions;
  }
}
