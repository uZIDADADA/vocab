import 'package:flutter/material.dart';

import 'data/local/app_database.dart';
import 'data/repositories/ai_settings_repository.dart';
import 'data/repositories/conversation_repository.dart';
import 'data/repositories/kiss_worker_settings_repository.dart';
import 'data/repositories/learning_repository.dart';
import 'data/repositories/pronunciation_settings_repository.dart';
import 'features/home/home_screen.dart';
import 'infrastructure/ai/ai_chat_provider.dart';
import 'infrastructure/pronunciation/pronunciation_service.dart';
import 'infrastructure/sync/kiss_worker_vocabulary_service.dart';
import 'theme/vocab_theme.dart';

class VocabApp extends StatefulWidget {
  const VocabApp({
    this.database,
    this.aiSecretStore,
    this.aiChatProvider,
    this.pronunciationService,
    this.kissVocabularyService,
    super.key,
  });

  final AppDatabase? database;
  final AiSecretStore? aiSecretStore;
  final AiChatProvider? aiChatProvider;
  final PronunciationService? pronunciationService;
  final KissVocabularyService? kissVocabularyService;

  @override
  State<VocabApp> createState() => _VocabAppState();
}

class _VocabAppState extends State<VocabApp> {
  late final bool _ownsDatabase = widget.database == null;
  late final AppDatabase _database = widget.database ?? AppDatabase();
  late final LearningRepository _repository = LearningRepository(_database);
  late final AiSecretStore _secretStore =
      widget.aiSecretStore ?? FlutterSecureAiSecretStore();
  late final AiSettingsRepository _aiSettingsRepository = AiSettingsRepository(
    _database,
    _secretStore,
  );
  late final ConversationRepository _conversationRepository =
      ConversationRepository(_database);
  late final KissWorkerSettingsRepository _kissWorkerSettingsRepository =
      KissWorkerSettingsRepository(_secretStore);
  late final PronunciationSettingsRepository _pronunciationSettingsRepository =
      PronunciationSettingsRepository(_secretStore);
  late final bool _ownsAiChatProvider = widget.aiChatProvider == null;
  late final AiChatProvider _aiChatProvider =
      widget.aiChatProvider ?? OpenAiCompatibleChatProvider();
  late final bool _ownsPronunciationService =
      widget.pronunciationService == null;
  late final PronunciationService _pronunciationService =
      widget.pronunciationService ??
      DictionaryPronunciationService(
        settingsRepository: _pronunciationSettingsRepository,
      );
  late final bool _ownsKissVocabularyService =
      widget.kissVocabularyService == null;
  late final KissVocabularyService _kissVocabularyService =
      widget.kissVocabularyService ?? KissWorkerVocabularyService();

  @override
  void dispose() {
    if (_ownsAiChatProvider) {
      (_aiChatProvider as OpenAiCompatibleChatProvider).close();
    }
    if (_ownsPronunciationService) {
      _pronunciationService.dispose();
    }
    if (_ownsKissVocabularyService) {
      _kissVocabularyService.close();
    }
    if (_ownsDatabase) {
      _database.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocab',
      debugShowCheckedModeBanner: false,
      theme: VocabTheme.light,
      home: HomeScreen(
        repository: _repository,
        aiSettingsRepository: _aiSettingsRepository,
        conversationRepository: _conversationRepository,
        aiChatProvider: _aiChatProvider,
        pronunciationSettingsRepository: _pronunciationSettingsRepository,
        pronunciationService: _pronunciationService,
        kissWorkerSettingsRepository: _kissWorkerSettingsRepository,
        kissVocabularyService: _kissVocabularyService,
      ),
    );
  }
}
