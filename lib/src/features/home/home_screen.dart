import 'package:flutter/material.dart';

import '../../data/repositories/ai_settings_repository.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/kiss_worker_settings_repository.dart';
import '../../data/repositories/learning_repository.dart';
import '../../data/repositories/pronunciation_settings_repository.dart';
import '../../infrastructure/ai/ai_chat_provider.dart';
import '../../infrastructure/pronunciation/pronunciation_service.dart';
import '../../infrastructure/sync/kiss_worker_vocabulary_service.dart';
import '../coach/coach_view.dart';
import '../inbox/inbox_page.dart';
import '../library/library_view.dart';
import '../profile/profile_view.dart';
import '../today/today_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.repository,
    required this.aiSettingsRepository,
    required this.aiChatProvider,
    required this.conversationRepository,
    required this.pronunciationSettingsRepository,
    required this.pronunciationService,
    required this.kissWorkerSettingsRepository,
    required this.kissVocabularyService,
    super.key,
  });

  final LearningRepository repository;
  final AiSettingsRepository aiSettingsRepository;
  final AiChatProvider aiChatProvider;
  final ConversationRepository conversationRepository;
  final PronunciationSettingsRepository pronunciationSettingsRepository;
  final PronunciationService pronunciationService;
  final KissWorkerSettingsRepository kissWorkerSettingsRepository;
  final KissVocabularyService kissVocabularyService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _coachKey = GlobalKey<CoachViewState>();
  int _tabIndex = 0;
  int _librarySegment = 0;
  int _libraryNavigationVersion = 0;

  void _selectTab(int index) {
    if (_tabIndex == index) return;
    setState(() => _tabIndex = index);
  }

  void _openInbox() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InboxPage(repository: widget.repository),
      ),
    );
  }

  void _openLibrary(int segment) {
    setState(() {
      _librarySegment = segment;
      _libraryNavigationVersion++;
      _tabIndex = 1;
    });
  }

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: '今日',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: '词句',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: '对练',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: '我的',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tabIndex,
          children: [
            TodayView(
              repository: widget.repository,
              pronunciationService: widget.pronunciationService,
              onOpenCoach: () => _selectTab(2),
              onOpenInbox: _openInbox,
              onOpenWords: () => _openLibrary(0),
              onOpenPatterns: () => _openLibrary(1),
              kissWorkerSettingsRepository: widget.kissWorkerSettingsRepository,
              onOpenWordSync: () => _selectTab(3),
            ),
            LibraryView(
              key: ValueKey('library-$_libraryNavigationVersion'),
              repository: widget.repository,
              pronunciationService: widget.pronunciationService,
              selectedSegment: _librarySegment,
              onSegmentChanged: (value) {
                if (_librarySegment != value) {
                  setState(() => _librarySegment = value);
                }
              },
            ),
            CoachView(
              key: _coachKey,
              settingsRepository: widget.aiSettingsRepository,
              conversationRepository: widget.conversationRepository,
              learningRepository: widget.repository,
              provider: widget.aiChatProvider,
            ),
            ProfileView(
              onOpenAiSettings: () => _coachKey.currentState?.openSettings(),
              repository: widget.repository,
              pronunciationSettingsRepository:
                  widget.pronunciationSettingsRepository,
              kissWorkerSettingsRepository: widget.kissWorkerSettingsRepository,
              kissVocabularyService: widget.kissVocabularyService,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        destinations: _destinations,
        onDestinationSelected: _selectTab,
      ),
    );
  }
}
