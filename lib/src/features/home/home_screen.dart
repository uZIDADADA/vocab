import 'package:flutter/material.dart';

import '../../application/import/vocabulary_import_coordinator.dart';
import '../../data/repositories/ai_settings_repository.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/kiss_worker_settings_repository.dart';
import '../../data/repositories/learning_repository.dart';
import '../../data/repositories/pronunciation_settings_repository.dart';
import '../../data/repositories/translator_settings_repository.dart';
import '../../infrastructure/ai/ai_chat_provider.dart';
import '../../infrastructure/dictionary/dictionary_service.dart';
import '../../infrastructure/pronunciation/pronunciation_service.dart';
import '../../infrastructure/sync/kiss_worker_vocabulary_service.dart';
import '../../theme/vocab_theme.dart';
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
    required this.dictionaryService,
    required this.vocabularyImportCoordinator,
    required this.conversationRepository,
    required this.pronunciationSettingsRepository,
    required this.translatorSettingsRepository,
    required this.pronunciationService,
    required this.kissWorkerSettingsRepository,
    required this.kissVocabularyService,
    super.key,
  });

  final LearningRepository repository;
  final AiSettingsRepository aiSettingsRepository;
  final AiChatProvider aiChatProvider;
  final DictionaryService dictionaryService;
  final VocabularyImportCoordinator vocabularyImportCoordinator;
  final ConversationRepository conversationRepository;
  final PronunciationSettingsRepository pronunciationSettingsRepository;
  final TranslatorSettingsRepository translatorSettingsRepository;
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

  static const _destinations = <_HomeDestination>[
    _HomeDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: '今日',
    ),
    _HomeDestination(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: '词句',
    ),
    _HomeDestination(
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      label: '对练',
    ),
    _HomeDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
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
              dictionaryService: widget.dictionaryService,
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
              translatorSettingsRepository: widget.translatorSettingsRepository,
              kissWorkerSettingsRepository: widget.kissWorkerSettingsRepository,
              kissVocabularyService: widget.kissVocabularyService,
              vocabularyImportCoordinator: widget.vocabularyImportCoordinator,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _VocabNavigationBar(
        selectedIndex: _tabIndex,
        destinations: _destinations,
        onDestinationSelected: _selectTab,
      ),
    );
  }
}

class _HomeDestination {
  const _HomeDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _VocabNavigationBar extends StatelessWidget {
  const _VocabNavigationBar({
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final List<_HomeDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigationTheme = theme.navigationBarTheme;

    return ColoredBox(
      color: navigationTheme.backgroundColor ?? theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: navigationTheme.height ?? 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                for (var index = 0; index < destinations.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _NavigationDestinationButton(
                        index: index,
                        destination: destinations[index],
                        selected: selectedIndex == index,
                        onTap: () => onDestinationSelected(index),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationDestinationButton extends StatelessWidget {
  const _NavigationDestinationButton({
    required this.index,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final _HomeDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: DecoratedBox(
            key: Key('bottom-navigation-item-$index'),
            decoration: BoxDecoration(
              color: selected ? VocabColors.lime : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 24,
                    color: selected ? VocabColors.ink : VocabColors.muted,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: selected ? VocabColors.ink : VocabColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
