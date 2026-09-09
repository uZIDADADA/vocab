import 'dart:async';

import 'package:flutter/material.dart';

import 'application/import/vocabulary_import_coordinator.dart';
import 'data/local/app_database.dart';
import 'data/repositories/ai_settings_repository.dart';
import 'data/repositories/conversation_repository.dart';
import 'data/repositories/kiss_worker_settings_repository.dart';
import 'data/repositories/learning_repository.dart';
import 'data/repositories/pronunciation_settings_repository.dart';
import 'data/repositories/translator_settings_repository.dart';
import 'features/home/home_screen.dart';
import 'infrastructure/ai/ai_chat_provider.dart';
import 'infrastructure/dictionary/dictionary_service.dart';
import 'infrastructure/dictionary/microsoft_translator_dictionary_service.dart';
import 'infrastructure/pronunciation/pronunciation_service.dart';
import 'infrastructure/sync/kiss_worker_vocabulary_service.dart';
import 'theme/vocab_theme.dart';

class VocabApp extends StatefulWidget {
  const VocabApp({
    this.database,
    this.aiSecretStore,
    this.aiChatProvider,
    this.dictionaryService,
    this.pronunciationService,
    this.kissVocabularyService,
    super.key,
  });

  final AppDatabase? database;
  final AiSecretStore? aiSecretStore;
  final AiChatProvider? aiChatProvider;
  final DictionaryService? dictionaryService;
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
  late final TranslatorSettingsRepository _translatorSettingsRepository =
      TranslatorSettingsRepository(_secretStore);
  late final bool _ownsAiChatProvider = widget.aiChatProvider == null;
  late final AiChatProvider _aiChatProvider =
      widget.aiChatProvider ?? OpenAiCompatibleChatProvider();
  late final bool _ownsDictionaryService = widget.dictionaryService == null;
  late final DictionaryService _dictionaryService =
      widget.dictionaryService ??
      MicrosoftTranslatorDictionaryService(
        settingsRepository: _translatorSettingsRepository,
      );
  late final VocabularyImportCoordinator _vocabularyImportCoordinator =
      VocabularyImportCoordinator(_repository);
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
  void initState() {
    super.initState();
    if (_ownsDictionaryService) {
      unawaited(_removeLegacyDictionaryCache());
    }
  }

  Future<void> _removeLegacyDictionaryCache() async {
    try {
      await removeLegacyOfflineDictionaryCache();
    } on Object {
      // The cache contains only generated copies of former bundled assets.
      // Cleanup failure must not prevent the application from starting.
    }
  }

  @override
  void dispose() {
    if (_ownsAiChatProvider) {
      (_aiChatProvider as OpenAiCompatibleChatProvider).close();
    }
    if (_ownsPronunciationService) {
      _pronunciationService.dispose();
    }
    if (_ownsDictionaryService) {
      _dictionaryService.close();
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
        dictionaryService: _dictionaryService,
        vocabularyImportCoordinator: _vocabularyImportCoordinator,
        pronunciationSettingsRepository: _pronunciationSettingsRepository,
        translatorSettingsRepository: _translatorSettingsRepository,
        pronunciationService: _pronunciationService,
        kissWorkerSettingsRepository: _kissWorkerSettingsRepository,
        kissVocabularyService: _kissVocabularyService,
      ),
    );
  }
}
