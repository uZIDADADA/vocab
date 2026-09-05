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

enum AiProviderKind { gemini, deepSeek, bigModel, kimi, openAiCompatible }

extension AiProviderKindDetails on AiProviderKind {
  String get storageValue => switch (this) {
    AiProviderKind.gemini => 'gemini',
    AiProviderKind.deepSeek => 'deepseek',
    AiProviderKind.bigModel => 'bigmodel',
    AiProviderKind.kimi => 'kimi',
    AiProviderKind.openAiCompatible => 'openai-compatible',
  };

  String get label => switch (this) {
    AiProviderKind.gemini => 'Gemini',
    AiProviderKind.deepSeek => 'DeepSeek',
    AiProviderKind.bigModel => '智谱 BigModel',
    AiProviderKind.kimi => 'Kimi',
    AiProviderKind.openAiCompatible => 'OpenAI Compatible',
  };

  static AiProviderKind fromStorage(String? value) {
    return switch (value) {
      'deepseek' => AiProviderKind.deepSeek,
      'bigmodel' => AiProviderKind.bigModel,
      'kimi' => AiProviderKind.kimi,
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

  const AiProviderConfig.deepSeek()
    : kind = AiProviderKind.deepSeek,
      baseUrl = 'https://api.deepseek.com',
      model = 'deepseek-v4-flash';

  const AiProviderConfig.bigModel()
    : kind = AiProviderKind.bigModel,
      baseUrl = 'https://open.bigmodel.cn/api/paas/v4',
      model = 'glm-5.2';

  const AiProviderConfig.kimi()
    : kind = AiProviderKind.kimi,
      baseUrl = 'https://api.moonshot.cn/v1',
      model = 'kimi-k2.6';

  const AiProviderConfig.openAiCompatible()
    : kind = AiProviderKind.openAiCompatible,
      baseUrl = 'https://api.openai.com/v1',
      model = '';

  static AiProviderConfig preset(AiProviderKind kind) => switch (kind) {
    AiProviderKind.gemini => const AiProviderConfig.gemini(),
    AiProviderKind.deepSeek => const AiProviderConfig.deepSeek(),
    AiProviderKind.bigModel => const AiProviderConfig.bigModel(),
    AiProviderKind.kimi => const AiProviderConfig.kimi(),
    AiProviderKind.openAiCompatible =>
      const AiProviderConfig.openAiCompatible(),
  };

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
