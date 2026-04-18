// Subtitle Studio v3 - Home Screen
//
// This is the main landing screen of the application that serves as the central hub
// for all subtitle editing workflows. It provides access to recent projects,
// creation of new subtitle files, importing existing files, and extracting
// subtitles from video files.
//
// Key Features:
// - Recent sessions display with search functionality
// - Multiple creation workflows (new, import, extract)
// - File association handling (opening .srt files from external apps)
// - First-time user tutorial system
// - Settings and help access
// - Theme switching capabilities
//
// Architecture:
// - Uses StatefulWidget with TickerProviderStateMixin for animations
// - Provider pattern for theme management
// - Database integration for session management
// - Custom floating action buttons for primary actions
// - Material Design with custom animations
//
// iOS Port Considerations:
// - Replace Material Design with iOS native components
// - Convert FloatingActionButton to iOS action sheets or toolbars
// - Use iOS navigation patterns (tab bar, navigation controller)
// - Replace Provider with ObservableObject/Combine
// - Implement iOS-specific file handling and document picker
// - Adapt animations to iOS conventions (UIView animations)

import 'package:flutter/foundation.dart';     // Flutter debugging and platform detection
import 'package:flutter/material.dart';      // Material Design components
import 'package:flutter/services.dart';      // Hardware services and keyboard support
import 'dart:convert';                        // For encoding/decoding file content
import 'package:flutter_svg/flutter_svg.dart'; // SVG asset support
import 'package:flutter_bloc/flutter_bloc.dart'; // BLoC state management
import 'package:subtitle_studio/screens/edit_line/edit_line_bloc.dart'; // EditSubtitleScreenBloc wrapper
import 'package:subtitle_studio/screens/screen_help.dart';      // Help documentation
import 'package:subtitle_studio/screens/screen_source_view.dart'; // Source view screen
import 'package:subtitle_studio/screens/home/home_cubit.dart';  // Home screen Cubit
import 'package:subtitle_studio/screens/home/home_state.dart';  // Home screen State
// Removed startup_permission_manager - not needed with pure SAF implementation
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart'; // File picker utilities
import 'package:subtitle_studio/utils/saf_file_handler.dart';    // SAF file operations
import 'package:subtitle_studio/utils/saf_path_converter.dart';  // SAF path conversion
import '../utils/responsive_layout.dart';     // Responsive layout utilities
import '../database/models/models.dart';     // Data models
import '../themes/theme_switcher_button.dart'; // Theme toggle component
import 'package:subtitle_studio/widgets/settings_sheet.dart';   // Settings modal
import 'package:subtitle_studio/widgets/create_subtitle_sheet.dart'; // New project creation
import 'package:subtitle_studio/widgets/import_project_sheet.dart'; // Project import
import 'package:subtitle_studio/widgets/subtitle_import_options_sheet.dart'; // Import workflow
import 'package:subtitle_studio/widgets/subtitle_extract_options_sheet.dart'; // Video extraction
import 'package:subtitle_studio/database/database_helper.dart'; // Database operations
import 'package:subtitle_studio/utils/logging_helpers.dart';    // Logging utilities
import 'package:subtitle_studio/utils/snackbar_helper.dart';    // User notifications
import 'package:subtitle_studio/utils/update_manager.dart';     // In-app update functionality
import 'package:subtitle_studio/widgets/first_time_instructions.dart'; // Tutorial system
import 'package:subtitle_studio/utils/msone_hotkey_manager.dart' as hotkey; // Keyboard shortcuts
import 'edit/edit_screen_bloc.dart';          // Main editing interface with BLoC wrapper

/// Main home screen widget serving as the application's primary interface
/// 
/// This screen provides the central hub for all subtitle editing workflows:
/// 
/// **Primary Functions:**
/// - Display recent editing sessions with search capabilities
/// - Provide quick access to create new subtitle projects
/// - Handle file imports from various sources
/// - Extract subtitles from video files using FFmpeg
/// - Manage user settings and preferences
/// - Provide help and documentation access
/// 
/// **User Experience Features:**
/// - Animated floating action buttons for primary actions
/// - Search functionality for finding specific sessions
/// - Visual feedback for loading states
/// - Smooth transitions between screens
/// - First-time user guidance system
/// 
/// **Technical Implementation:**
/// - State management using Cubit (BLoC pattern)
/// - Clean architecture with repository pattern
/// - Comprehensive logging throughout
/// - File association handling for external app integration
/// - Custom FAB implementation for enhanced UX
/// 
/// **iOS Port Implementation Notes:**
/// - Replace FloatingActionButton with iOS action sheets or bottom toolbar
/// - Use UITableView or UICollectionView for recent sessions list
/// - Implement iOS document picker for file import workflows
/// - Replace Material search with iOS UISearchController
/// - Use iOS navigation patterns (UINavigationController, UITabBarController)
/// - Convert animations to UIView animation blocks or Core Animation
class HomeScreen extends StatelessWidget {
  /// Optional file path from intent/file association
  /// When app is opened with a .srt file, this contains the file path
  final String? initialFilePath;
  
  /// Optional file name extracted from intent
  /// Used for display purposes when file association opens the app
  final String? initialFileName;
  
  /// Whether the initial file is a .msone project file
  /// Used to determine if import project sheet should be shown
  final bool isProjectFile;
  
  /// Original SAF URI for files opened via intent
  /// Used to preserve the content URI for database storage
  final String? originalSafUri;

  const HomeScreen({
    super.key,
    this.initialFilePath,    // File path from external app intent
    this.initialFileName,    // Display name from external app intent
    this.isProjectFile = false, // Whether file is .msone project
    this.originalSafUri,     // Original SAF URI for database storage
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit()..loadSessions(),
      child: _HomeScreenContent(
        initialFilePath: initialFilePath,
        initialFileName: initialFileName,
        isProjectFile: isProjectFile,
        originalSafUri: originalSafUri,
      ),
    );
  }
}

/// Internal content widget for the home screen
/// 
/// This widget handles the actual UI rendering and user interactions,
/// while HomeScreen above provides the BLoC provider.
class _HomeScreenContent extends StatefulWidget {
  final String? initialFilePath;
  final String? initialFileName;
  final bool isProjectFile;
  final String? originalSafUri;

  const _HomeScreenContent({
    this.initialFilePath,
    this.initialFileName,
    this.isProjectFile = false,
    this.originalSafUri,
  });

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late AnimationController _customFabController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _customFabAnimation;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  // GlobalKeys for tutorials
  final GlobalKey _themeSwitcherKey = GlobalKey();
  final GlobalKey _settingsButtonKey = GlobalKey();
  final GlobalKey _createButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    logInfo('HomeScreen initialized');

    // Add app lifecycle observer for update checks
    WidgetsBinding.instance.addObserver(this);

    // Initialize fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Initialize custom FAB animation
    _customFabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _customFabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _customFabController, curve: Curves.easeInOut),
    );

    // Handle initial file path from intent
    _handleInitialFilePath();
    
    // SAF implementation does not require startup permissions
    // Permission dialogs removed for pure SAF implementation
    
    // Check for flexible update completion
    _checkFlexibleUpdateCompletion();
    
    // Check for updates automatically after a delay
    _checkForUpdatesAutomatically();
    
    // Register hotkey shortcuts
    _registerHotkeyShortcuts();
  }

  /// Check for updates automatically after the home screen loads
  Future<void> _checkForUpdatesAutomatically() async {
    try {
      // Wait for the home screen to fully load and animations to complete
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        final updateInfo = await UpdateManager.instance.checkForUpdate();
        if (updateInfo != null && mounted) {
          UpdateManager.instance.showUpdateDialog(context, updateInfo);
        }
      }
    } catch (e) {
      logError('Error checking for updates automatically: $e');
    }
  }

  Future<void> _handleInitialFilePath() async {
    if (widget.initialFilePath != null) {
      // Wait a bit to ensure the UI is ready
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        if (widget.isProjectFile) {
          // Handle .msone project file
          _handleImportProject(
            preselectedFilePath: widget.initialFilePath!,
            originalSafUri: widget.originalSafUri,
          );
        } else {
          // Handle .srt subtitle file
          _showImportWithFilePath(
            widget.initialFilePath!, 
            widget.initialFileName,
            originalSafUri: widget.originalSafUri,
          );
        }
      }
    }
  }

  /// Register hotkey shortcuts using MSoneHotkeyManager
  Future<void> _registerHotkeyShortcuts() async {
    await hotkey.MSoneHotkeyManager.instance.registerHomeScreenShortcuts(
      onOpenSrtFile: _handleOpenSrtFileShortcut,
      onImportMsoneFile: _handleImportMsoneFileShortcut,
      onExtractSubtitleFromVideo: _handleExtractSubtitleFromVideoShortcut,
      onCreateNew: _handleCreateNewShortcut,
      onHelp: _handleHelpShortcut,
      onSettings: _handleSettingsShortcut,
    );
  }

  /// Re-register HomeScreen shortcuts after returning from other screens
  /// This ensures that shared shortcuts (help, settings) work correctly in HomeScreen
  Future<void> _reRegisterHomeScreenShortcuts() async {
    // First unregister any remaining shared shortcuts that might still point to disposed widgets
    await hotkey.MSoneHotkeyManager.instance.unregisterCallback(hotkey.HotkeyAction.help);
    await hotkey.MSoneHotkeyManager.instance.unregisterCallback(hotkey.HotkeyAction.settings);
    
    // Then re-register them with HomeScreen's handlers
    await hotkey.MSoneHotkeyManager.instance.registerCallback(hotkey.HotkeyAction.help, _handleHelpShortcut);
    await hotkey.MSoneHotkeyManager.instance.registerCallback(hotkey.HotkeyAction.settings, _handleSettingsShortcut);
  }

  // Hotkey shortcut handlers
  void _handleOpenSrtFileShortcut() {
    _handleImport();
  }

  void _handleImportMsoneFileShortcut() {
    _handleImportProject();
  }

  void _handleExtractSubtitleFromVideoShortcut() {
    _handleExtract(); // This opens the extract options directly
  }

  void _handleCreateNewShortcut() {
    _handleCreate();
  }

  void _handleHelpShortcut() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpScreen()),
    );
  }

  void _handleSettingsShortcut() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => SettingsSheet(
        onSettingsChanged: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  void dispose() {
    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Unregister hotkey shortcuts
    hotkey.MSoneHotkeyManager.instance.unregisterAll();
    
    _fadeController.dispose();
    _customFabController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Check for flexible update completion when app resumes
    if (state == AppLifecycleState.resumed) {
      _checkFlexibleUpdateCompletion();
      // Also refresh sessions in case they were updated while app was paused
      context.read<HomeCubit>().loadSessions();
    }
  }

  /// Check if a flexible update has completed downloading and is ready to install
  Future<void> _checkFlexibleUpdateCompletion() async {
    try {
      await UpdateManager.instance.checkFlexibleUpdateCompletion(context);
    } catch (e) {
      logError('Error checking flexible update completion: $e');
    }
  }

  Future<void> _deleteSession(Session session) async {
    try {
      await context.read<HomeCubit>().deleteSession(session);
      
      // Unfocus search field to prevent keyboard from showing
      _searchFocusNode.unfocus();
      
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Deleted "${session.fileName}"', duration: const Duration(seconds: 2));
      }
    } catch (e) {
      // Error already shown by BlocConsumer listener
    }
  }

  List<String> _getHomeInstructions() {
    return [
      'Use the help button (❔) to access comprehensive documentation and guides.',
      'Use the theme switcher button (✨/🌙/☀️) in the top-right to switch between dark, light, and classic themes.',
      'Tap the settings button (⚙️) to access app preferences and configure MSone features.',
      'Use the sort button to organize sessions by last opened, last created, or name.',
      'Use the floating action buttons to create new subtitles, import files, extract from video, or continue editing.',
      'Each session card shows editing progress, languages detected, and file information.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        // Handle errors
        if (state.errorMessage != null) {
          SnackbarHelper.showError(context, state.errorMessage!);
          context.read<HomeCubit>().clearError();
        }
        
        // Start fade animation when data loads
        if (!state.isLoading && _fadeController.status == AnimationStatus.dismissed) {
          _fadeController.forward();
        }
      },
      builder: (context, state) => FirstTimeInstructions(
      screenName: 'home',
      instructions: _getHomeInstructions(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Subtitle Studio',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            ),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          actions: [
            // Sort button - only show if there are sessions
            if (state.hasSessions)
              PopupMenuButton<SessionSortOption>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort Sessions',
                onSelected: (SessionSortOption option) {
                  context.read<HomeCubit>().changeSortOption(option);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<SessionSortOption>>[
                  PopupMenuItem<SessionSortOption>(
                    value: SessionSortOption.lastOpened,
                    child: Row(
                      children: [
                        Icon(
                          state.sortOption == SessionSortOption.lastOpened
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 20,
                          color: state.sortOption == SessionSortOption.lastOpened
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text('Last Opened'),
                      ],
                    ),
                  ),
                  PopupMenuItem<SessionSortOption>(
                    value: SessionSortOption.lastCreated,
                    child: Row(
                      children: [
                        Icon(
                          state.sortOption == SessionSortOption.lastCreated
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 20,
                          color: state.sortOption == SessionSortOption.lastCreated
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text('Last Created'),
                      ],
                    ),
                  ),
                  PopupMenuItem<SessionSortOption>(
                    value: SessionSortOption.name,
                    child: Row(
                      children: [
                        Icon(
                          state.sortOption == SessionSortOption.name
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 20,
                          color: state.sortOption == SessionSortOption.name
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text('Name (A-Z)'),
                      ],
                    ),
                  ),
                  PopupMenuItem<SessionSortOption>(
                    value: SessionSortOption.nameDesc,
                    child: Row(
                      children: [
                        Icon(
                          state.sortOption == SessionSortOption.nameDesc
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 20,
                          color: state.sortOption == SessionSortOption.nameDesc
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text('Name (Z-A)'),
                      ],
                    ),
                  ),
                ],
              ),
            // Clear All Sessions button - only show if there are sessions
            if (state.hasSessions)
              IconButton(
                onPressed: () => _showClearAllSessionsDialog(),
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear All Sessions',
              ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
              },
              icon: const Icon(Icons.help_outline),
              tooltip: 'Help & Documentation',
            ),
            ThemeSwitcherButton(key: _themeSwitcherKey),
            IconButton(
              key: _settingsButtonKey,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                  ),
                  builder: (context) => SettingsSheet(
                    onSettingsChanged: () {
                      setState(() {});
                    },
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
            ),
          ],
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () {
              // Collapse FAB when tapping anywhere on the screen
              if (state.isFabExpanded) {
                _toggleCustomFab();
              }
              // Unfocus search field
              _searchFocusNode.unfocus();
            },
            child: Stack(
              children: [
                state.isLoading
                    ? _buildLoadingState()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            _buildWelcomeHeader(state),
                            _buildSearchBar(state),
                            Expanded(child: _buildSessionsList(state)),
                          ],
                        ),
                      ),
                _buildCustomFAB(state),
              ],
            ),
          ),
        ),
        floatingActionButton: null, // Remove default FAB
      ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your subtitle sessions...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(HomeState state) {
    final hasLastEdited = state.lastEditedSession != null;
    final isFirstTime = !state.hasSessions;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.subtitles_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFirstTime ? 'Welcome to Subtitle Studio!' : 'Ready to continue editing?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (hasLastEdited) ...[
            Text(
              'Continue with: ${state.lastEditedSession!.fileName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _navigateToEditScreen(state.lastEditedSession!),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Continue Editing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ] else ...[
            Text(
              isFirstTime 
                  ? 'Start creating your first subtitle project'
                  : 'Ready to start your next subtitle project',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(HomeState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) => context.read<HomeCubit>().updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Search subtitle files...',
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          suffixIcon: state.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<HomeCubit>().clearSearch();
                    _searchFocusNode.unfocus();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSessionsList(HomeState state) {
    final filteredSessions = state.filteredSessions;
    
    if (filteredSessions.isEmpty) {
      return _buildEmptyState(state);
    }

    // Use responsive layout to determine if we should show grid or list
    if (ResponsiveLayout.shouldUseDesktopLayout(context)) {
      // Desktop layout: use grid view
      final columns = ResponsiveLayout.getGridColumns(context);
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 180, // Fixed height that fits the content properly
        ),
        itemCount: filteredSessions.length,
        itemBuilder: (context, index) {
          final session = filteredSessions[index];
          return _buildSessionCard(session, index, state);
        },
      );
    } else {
      // Mobile layout: use list view
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: filteredSessions.length,
        itemBuilder: (context, index) {
          final session = filteredSessions[index];
          return _buildSessionCard(session, index, state);
        },
      );
    }
  }

  Widget _buildEmptyState(HomeState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            state.searchQuery.isNotEmpty ? Icons.search_off : Icons.subtitles_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            state.searchQuery.isNotEmpty 
                ? 'No subtitle files match your search'
                : 'No subtitle sessions found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            state.searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Create your first subtitle project to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (state.searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleImport,
              icon: Icon(Icons.file_open, color: Theme.of(context).colorScheme.onPrimary,),
              label: const Text('Open SRT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                fixedSize: Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _handleCreate,
              icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary,),
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                fixedSize: Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session, int index, HomeState state) {
    final isLastEdited = state.lastEditedSession?.id == session.id;
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _getSessionInfo(session),
      builder: (context, snapshot) {
        final sessionInfo = snapshot.data ?? {};
        
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: Card(
            elevation: isLastEdited ? 6 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isLastEdited 
                  ? BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    )
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () => _navigateToEditScreen(session),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
                  children: [
                    _buildSessionCardHeader(session, isLastEdited),
                    const SizedBox(height: 8),
                    Flexible( // Allow info section to shrink if needed
                      child: _buildSessionCardInfo(sessionInfo, session),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionCardHeader(Session session, bool isLastEdited) {
    return FutureBuilder<bool>(
      future: _isMSoneSubtitle(session),
      builder: (context, snapshot) {
        final isMSoneFile = snapshot.data ?? false;
        
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isMSoneFile
                  ? SvgPicture.asset(
                      'assets/msone.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        Colors.blue,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(
                      Icons.subtitles,
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
                      size: 18,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.fileName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLastEdited) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                                  Icons.history,
                                  color: Colors.white,
                                  size: 10,
                                ),
                          // Text(
                          //   'LAST EDITED',
                          //   style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          //     color: Theme.of(context).colorScheme.onPrimary,
                          //     fontWeight: FontWeight.bold,
                          //     fontSize: 8,
                          //   ),
                          // ),
                        ),
                      ],
                      // Project file indicator
                      if (session.projectFilePath != null && session.projectFilePath!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Has project file',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder_special,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                // const SizedBox(width: 2),
                                // Text(
                                //   'PROJECT',
                                //   style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                //     color: Colors.white,
                                //     fontWeight: FontWeight.bold,
                                //     fontSize: 8,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      // Delete button in header
                      IconButton(
                        onPressed: () => _showDeleteConfirmation(session),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 18,
                        ),
                        iconSize: 18,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Delete Session',
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        session.editMode ? Icons.edit : Icons.translate,
                        size: 14,
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        session.editMode ? 'Edit Mode' : 'Translation Mode',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionCardInfo(Map<String, dynamic> sessionInfo, Session session) {
    final totalLines = sessionInfo['totalLines'] ?? 0;
    final editedLines = sessionInfo['editedLines'] ?? 0;
    final progress = totalLines > 0 ? editedLines / totalLines : 0.0;
    final iconColor = Theme.of(context).colorScheme.secondary.withValues(alpha: 0.95);
    
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take minimum space
        children: [
          // Progress bar - only show in translation mode
          if (!session.editMode) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: iconColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Info items row
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.format_list_numbered,
                  label: 'Lines',
                  value: '${sessionInfo['totalLines'] ?? 0}',
                ),
              ),
              _buildInfoDivider(),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.edit_note,
                  label: 'Edited',
                  value: '${sessionInfo['editedLines'] ?? 0}',
                ),
              ),
              _buildInfoDivider(),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.my_location,
                  label: 'Last Line',
                  value: '${sessionInfo['lastEditedIndex'] ?? 1}',
                ),
              ),
              _buildInfoDivider(),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.language,
                  label: 'Languages',
                  value: sessionInfo['languageCodes'] ?? 'EN',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on available width
        final availableWidth = constraints.maxWidth;
        final iconSize = (availableWidth * 0.15).clamp(12.0, 18.0); // 15% of width, between 12-18
        final valueFontSize = (availableWidth * 0.12).clamp(10.0, 14.0); // 12% of width, between 10-14
        final labelFontSize = (availableWidth * 0.09).clamp(8.0, 11.0); // 9% of width, between 8-11
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.95),
            ),
            SizedBox(height: (availableWidth * 0.02).clamp(2.0, 4.0)), // Responsive spacing
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: valueFontSize,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: labelFontSize,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Make divider height responsive to available space
        final dividerHeight = (constraints.maxHeight * 0.6).clamp(20.0, 35.0);
        
        return Container(
          height: dividerHeight,
          width: 1,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          margin: const EdgeInsets.symmetric(horizontal: 4),
        );
      },
    );
  }

  Widget _buildCustomFAB(HomeState state) {
    return Positioned(
      bottom: 32,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expanded action buttons
          AnimatedBuilder(
            animation: _customFabAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_customFabAnimation),
                child: FadeTransition(
                  opacity: _customFabAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (state.isFabExpanded) ...[
                        _buildCustomFabButton(
                          key: _createButtonKey,
                          onPressed: () {
                            _toggleCustomFab();
                            _handleCreate();
                          },
                          icon: Icons.add,
                          label: 'Create',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        _buildCustomFabButton(
                          onPressed: () {
                            _toggleCustomFab();
                            _handleExtract();
                          },
                          icon: Icons.video_collection,
                          label: 'Extract',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        _buildCustomFabButton(
                          onPressed: () {
                            _toggleCustomFab();
                            _handleImportProject();
                          },
                          icon: Icons.unarchive,
                          label: 'Import',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        _buildCustomFabButton(
                          onPressed: () {
                            _toggleCustomFab();
                            _handleImport();
                          },
                          icon: Icons.file_open,
                          label: 'Open',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        _buildCustomFabButton(
                          onPressed: () {
                            _toggleCustomFab();
                            _handleSourceView();
                          },
                          icon: Icons.document_scanner,
                          label: 'View',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          // Main FAB button
          SizedBox(
            width: 120, // Same width as child buttons
            child: FloatingActionButton.extended(
              heroTag: "customMainFab",
              onPressed: _toggleCustomFab,
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: AnimatedRotation(
                turns: state.isFabExpanded ? 0.250 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  state.isFabExpanded ? Icons.close : Icons.menu,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              label: Text(
                'Menu',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleCustomFab() {
    context.read<HomeCubit>().toggleFabExpansion();
    
    final isExpanded = context.read<HomeCubit>().state.isFabExpanded;
    if (isExpanded) {
      _customFabController.forward();
    } else {
      _customFabController.reverse();
    }
  }

  Widget _buildCustomFabButton({
    Key? key,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: 120, // Fixed width to ensure alignment
      child: FloatingActionButton.extended(
        key: key,
        heroTag: "custom_$label",
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: color,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getSessionInfo(Session session) async {
    return await context.read<HomeCubit>().getSessionInfo(session);
  }

  Future<bool> _isMSoneSubtitle(Session session) async {
    return await context.read<HomeCubit>().isMSoneSubtitle(session);
  }

  Future<void> _navigateToEditScreen(Session session) async {
    try {
      await context.read<HomeCubit>().updateLastEditedSession(session.id);

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditScreenBloc(
            subtitleCollectionId: session.subtitleCollectionId,
            lastEditedIndex: session.lastEditedIndex,
            sessionId: session.id,
          ),
        ),
      );

      if (mounted) {
        // Re-register HomeScreen shortcuts after returning from EditScreen
        await _reRegisterHomeScreenShortcuts();
        context.read<HomeCubit>().loadSessions();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Navigation error: $e');
      }
      if (mounted) {
        context.read<HomeCubit>().loadSessions();
      }
    }
  }

  Future<void> _handleCreate() async {
    try {
      if (!mounted) return;
      
      // Capture cubit reference before opening bottom sheet
      final cubit = context.read<HomeCubit>();
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        builder: (context) => CreateSubtitleSheet(
          onSubtitleCreated: (subtitleData) async {
            if (subtitleData != null) {
              cubit.loadSessions();
              
              final session = Session(
                subtitleCollectionId: subtitleData['subtitleCollectionId'],
                fileName: subtitleData['fileName'] ?? '',
                lastEditedIndex: subtitleData['lastEditedIndex'],
                editMode: subtitleData['editMode'] ?? true,
              );
              
              await cubit.updateLastEditedSession(session.id);
              
              if (mounted) {
                final navigator = Navigator.of(context);
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => EditSubtitleScreenBloc(
                      subtitleId: subtitleData['subtitleCollectionId'],
                      index: 1,
                      sessionId: subtitleData['sessionId'],
                      isNewSubtitle: true,
                      editMode: subtitleData['editMode'] ?? true,
                    ),
                  ),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Error: $e');
    }
  }

  void _handleImport() {
    // Capture cubit reference before opening bottom sheet
    final cubit = context.read<HomeCubit>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => SubtitleImportOptionsSheet(
        onSubtitleImported: (session) {
          cubit.loadSessions();
          _navigateToEditScreen(session);
        },
      ),
    );
  }

  void _showImportWithFilePath(String filePath, String? fileName, {String? originalSafUri}) {
    // Capture cubit reference before opening bottom sheet
    final cubit = context.read<HomeCubit>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => SubtitleImportOptionsSheet(
        initialFilePath: filePath,
        initialFileName: fileName,
        originalSafUri: originalSafUri,  // Pass original SAF URI
        onSubtitleImported: (session) {
          cubit.loadSessions();
          _navigateToEditScreen(session);
        },
      ),
    );
  }

  void _handleExtract() {
    // Capture cubit reference before opening bottom sheet
    final cubit = context.read<HomeCubit>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => SubtitleExtractOptionsSheet(
        onSubtitleExtracted: (session) async {
          try {
            await cubit.updateLastEditedSession(session.id);
            await Future.delayed(const Duration(milliseconds: 300));
            
            if (mounted) {
              await cubit.loadSessions();
              _navigateToEditScreen(session);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error during extraction navigation: $e');
            }
            if (mounted) {
              SnackbarHelper.showError(context, 'Error: $e');
            }
          }
        },
      ),
    );
  }

  void _handleImportProject({String? preselectedFilePath, String? originalSafUri}) {
    // Capture cubit reference before opening bottom sheet
    final cubit = context.read<HomeCubit>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ImportProjectSheet(
        initialFilePath: preselectedFilePath,
        originalSafUri: originalSafUri,  // Pass original SAF URI
        onProjectImported: (session) async {
          try {
            await cubit.updateLastEditedSession(session.id);
            await Future.delayed(const Duration(milliseconds: 300));
            
            if (mounted) {
              await cubit.loadSessions();
              // Navigation is now handled by SessionSelectionSheet
              // No need to navigate here as it would cause duplicate navigation
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error during import navigation: $e');
            }
            if (mounted) {
              SnackbarHelper.showError(context, 'Error: $e');
            }
          }
        },
      ),
    );
  }

  void _handleSourceView() async {
    try {
      // Check if SAF is available (Android)
      if (SafFileHandler.isAvailable) {
        // Use SAF file picker for Android
        final fileInfo = await SafFileHandler.openFile(
          mimeTypes: ['text/plain', 'application/x-subrip', '*/*'],
        );
        
        if (fileInfo != null && mounted) {
          // Fix the display path using proper SAF URI conversion
          final correctedPath = SafPathConverter.normalizePath(fileInfo.uri);
          
          if (kDebugMode) {
            print('Home _handleSourceView: originalPath=${fileInfo.displayPath}, correctedPath=$correctedPath, uri=${fileInfo.uri}');
          }
          
          // Load file content from URI (openFile now returns URI-only for memory safety)
          String? fileContent;
          try {
            final contentBytes = await SafFileHandler.readFileFromUri(fileInfo.uri);
            try {
              fileContent = utf8.decode(contentBytes);
            } catch (e) {
              // If UTF-8 fails, try Latin-1 as fallback
              try {
                fileContent = latin1.decode(contentBytes);
              } catch (e2) {
                if (kDebugMode) {
                  print('Failed to decode file content: $e2');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to read file content: $e');
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to read file: ${e.toString()}')),
              );
            }
            return;
          }
          
          // Navigate to source view screen with SAF URI and pre-loaded content
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SourceViewScreen(
                filePath: correctedPath, // Use corrected path
                displayName: fileInfo.fileName,
                safUri: fileInfo.uri,
                fileContent: fileContent, // Pass pre-loaded content
              ),
            ),
          ).then((_) {
            // Re-register shortcuts when returning from source view
            _reRegisterHomeScreenShortcuts();
          });
        }
      } else {
        // Use regular file picker for non-Android platforms
        final filePath = await FilePickerConvenience.pickSubtitleFile(context: context);
        
        if (filePath != null && mounted) {
          // Navigate to source view screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SourceViewScreen(
                filePath: filePath,
              ),
            ),
          ).then((_) {
            // Re-register shortcuts when returning from source view
            _reRegisterHomeScreenShortcuts();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error opening file: $e');
      }
      await logError('Error in source view handler: $e');
    }
  }

  void _showDeleteConfirmation(Session session) {
    void handleKeyEvent(KeyEvent event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          Navigator.pop(context);
          _deleteSession(session);
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: handleKeyEvent,
        child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header section with icon and title
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Delete Session",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "This action cannot be undone",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Warning content card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Warning",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are about to permanently delete the session:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '"${session.fileName}"',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All subtitle lines, edits, and progress will be permanently lost.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Cancel",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteSession(session);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_forever,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Delete",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ), // Close KeyboardListener
      )
    );
  }

  /// Show confirmation dialog for clearing all sessions
  void _showClearAllSessionsDialog() {
    // Capture cubit and navigator references before opening dialog
    final cubit = context.read<HomeCubit>();
    final state = cubit.state;
    final sessionCount = state.recentSessions.length;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final dialogContext = context;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header section with icon and title
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_sweep,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clear All Sessions',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This action cannot be undone',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Warning content card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'WARNING',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You are about to permanently delete:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• $sessionCount subtitle session${sessionCount != 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• All subtitle lines and content',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• All editing history and checkpoints',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• All video preferences and associations',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• All cached waveform data',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your app settings and dictionary data will be preserved.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => navigator.pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel_outlined, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              "Cancel",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Close dialog
                          navigator.pop();
                          
                          // Show loading dialog
                          showDialog(
                            context: dialogContext,
                            barrierDismissible: false,
                            builder: (context) => const AlertDialog(
                              content: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 16),
                                  Text('Clearing all sessions...'),
                                ],
                              ),
                            ),
                          );
                          
                          try {
                            // Clear all sessions
                            await clearAllSessions();
                            
                            if (mounted) {
                              // Close loading dialog
                              Navigator.of(dialogContext).pop();
                              
                              // Reload sessions
                              await cubit.loadSessions();
                              
                              // Show success message
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('All sessions cleared successfully!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              // Close loading dialog
                              Navigator.of(dialogContext).pop();
                              
                              // Show error message
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to clear sessions: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_sweep, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Clear All",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
