enum CoachRole { user, assistant }

class CoachMessage {
  const CoachMessage({
    required this.role,
    required this.text,
    this.id,
    this.createdAt,
  });

  final CoachRole role;
  final String text;
  final String? id;
  final DateTime? createdAt;
}

class CoachConversationSummary {
  const CoachConversationSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum CoachLearningKind { word, pattern }

class CoachLearningSuggestion {
  const CoachLearningSuggestion({
    required this.kind,
    required this.text,
    required this.meaning,
    this.example,
  });

  final CoachLearningKind kind;
  final String text;
  final String meaning;
  final String? example;
}

enum AiProviderKind { gemini, openAiCompatible }

extension AiProviderKindDetails on AiProviderKind {
  String get storageValue => switch (this) {
    AiProviderKind.gemini => 'gemini',
    AiProviderKind.openAiCompatible => 'openai-compatible',
  };

  String get label => switch (this) {
    AiProviderKind.gemini => 'Gemini',
    AiProviderKind.openAiCompatible => 'OpenAI Compatible',
  };

  static AiProviderKind fromStorage(String? value) {
    return switch (value) {
      'openai-compatible' => AiProviderKind.openAiCompatible,
      _ => AiProviderKind.gemini,
    };
  }
}

class AiProviderConfig {
  const AiProviderConfig({
    required this.kind,
    required this.baseUrl,
    required this.model,
  });

  const AiProviderConfig.gemini()
    : kind = AiProviderKind.gemini,
      baseUrl = 'https://generativelanguage.googleapis.com/v1beta/openai',
      model = 'gemini-3.1-flash-lite';

  final AiProviderKind kind;
  final String baseUrl;
  final String model;

  String get displayName => kind.label;
}

class AiChatSettings {
  const AiChatSettings({required this.config, required this.apiKey});

  final AiProviderConfig config;
  final String? apiKey;

  bool get isConfigured =>
      apiKey?.trim().isNotEmpty == true &&
      config.baseUrl.trim().isNotEmpty &&
      config.model.trim().isNotEmpty;
}
