import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar_community/isar.dart';
import 'package:provider/provider.dart';
import 'package:subtitle_studio/main.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/themes/theme_switcher_button.dart';
import 'package:subtitle_studio/utils/srt_compiler.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'package:subtitle_studio/operations/subtitle_sync_operations.dart';

import 'package:subtitle_studio/operations/subtitle_operations.dart';
import 'package:subtitle_studio/widgets/custom_text_render.dart';
import 'package:subtitle_studio/widgets/formatting_menu.dart';
import 'package:subtitle_studio/widgets/colour_picker_widget.dart';

import 'package:subtitle_studio/widgets/subtitle_actions_menu.dart';
import 'package:subtitle_studio/widgets/dictionary_search_widget.dart';
import 'package:subtitle_studio/widgets/olam_dictionary_widget.dart';
import 'package:subtitle_studio/widgets/urban_dictionary_widget.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/screens/screen_help.dart';
import 'package:subtitle_studio/widgets/settings_sheet.dart';
import 'package:subtitle_studio/widgets/first_time_instructions.dart';
import 'package:subtitle_studio/widgets/secondary_subtitle_sheet.dart';
import 'package:subtitle_studio/widgets/video_player_widget.dart';
import 'package:subtitle_studio/utils/responsive_layout.dart';
import 'package:subtitle_studio/utils/msone_hotkey_manager.dart' as hotkey;
import 'package:subtitle_studio/widgets/scrolling_title_widget.dart';
import 'package:subtitle_studio/widgets/marked_lines_sheet.dart';
import 'package:subtitle_studio/widgets/checkpoint_sheet.dart';
import 'package:subtitle_studio/widgets/comment_dialog.dart';
import 'package:subtitle_studio/widgets/goto_line_sheet.dart';
import 'package:subtitle_studio/utils/time_parser.dart';
import 'package:subtitle_studio/utils/subtitle_parser.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/unicode_text_input_formatter.dart';
import 'package:subtitle_studio/utils/time_input_formatter.dart';
import 'package:subtitle_studio/themes/theme_provider.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subtitle_studio/screens/edit_line/edit_line_cubit.dart' hide TimeValidator;
import 'package:subtitle_studio/screens/edit_line/edit_line_state.dart';
import 'package:subtitle_studio/features/ai_explanation/ai_explanation_cubit.dart';
import 'package:subtitle_studio/widgets/ai_explanation_sheet.dart';

// Edit subtitle line screen with video player integration
// Uses Bloc/Cubit for state management, character counting, and time validation
// Supports keyboard shortcuts, formatting, and responsive layouts

class EditSubtitleScreen extends StatefulWidget {
  final Id subtitleId; // ID of the subtitle collection
  final int index; // Index of the subtitle line
  final int sessionId;
  final bool isNewSubtitle; // Indicates if this is a new subtitle
  final bool editMode; // New parameter to indicate if session is in edit mode
  // Video-related parameters
  final String? videoPath;
  final bool isVideoLoaded;
  final Duration? startVideoPosition;
  // Secondary subtitle parameters
  final List<SimpleSubtitleLine>? secondarySubtitles;

  const EditSubtitleScreen({
    super.key,
    required this.subtitleId,
    required this.index,
    required this.sessionId,
    this.isNewSubtitle = false,
    this.editMode =
        false, // Default to false (translation mode) for backward compatibility
    this.videoPath,
    this.isVideoLoaded = false,
    this.startVideoPosition,
    this.secondarySubtitles,
  });

  @override
  EditSubtitleScreenState createState() => EditSubtitleScreenState();
}

class EditSubtitleScreenState extends State<EditSubtitleScreen> {
  late TextEditingController _originalController;
  late TextEditingController _editedController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _currentIndexController;
  late ScrollController _scrollController;
  final FocusNode _focusNode = FocusNode();
  final UndoHistoryController _undoHistoryController = UndoHistoryController();
  final List<Color> _colorHistory = []; // Maintain color history
  SubtitleLine? _subtitleLine; // To hold the fetched subtitle line
  SubtitleCollection? _subtitle; // To hold the fetched subtitle collection
  bool isEditingEnabled = false;
  bool _isTimeVisible = false;
  bool isRawEnabled = false;
  bool _isMsoneEnabled = false; // Will be set from SharedPreferences
  bool _isEditMode = false; // Add a mode toggle
  bool _showOriginalLine =
      false; // Track if original line should be shown when edited is empty
  bool _showOriginalTextField =
      true; // Control visibility of original text field
  bool _autoSaveWithNavigation = true; // Default to true now
  bool _isSaveToFileEnabled =
      false; // New variable to track if we should save to file directly
  // Video player related variables
  final GlobalKey<VideoPlayerWidgetState> _videoPlayerKey = GlobalKey();
  bool _isVideoVisible = false;
  bool _isVideoLoaded = false;
  String? _selectedVideoPath;
  List<Subtitle> _subtitles = [];
  bool _autoResizeOnKeyboard = true; // Auto resize video when keyboard appears
  // Removed _isKeyboardVisible to prevent rebuild storms during keyboard animations
  bool _isVideoPlaying = false; // Track video play state

  // Repeat playback feature for current subtitle
  bool _isRepeatModeEnabled = false; // Track if repeat mode is enabled
  Timer? _repeatPlaybackTimer; // Timer for repeat playback monitoring

  // Custom range repeat feature
  bool _isCustomRangeMode = false; // Track if custom range mode is enabled
  int? _customRangeStartIndex; // Start subtitle index for custom range
  int? _customRangeEndIndex; // End subtitle index for custom range

  // Secondary subtitle support
  List<SimpleSubtitleLine> _secondarySubtitles = [];
  List<Subtitle> _secondarySubtitlesForPlayer = [];
  bool _showSecondarySubtitles = false;

  // Resize ratio for desktop layout
  double _resizeRatio = 0.35;
  Timer? _resizeRatioSaveTimer; // Timer for debouncing resize ratio saves
  double? _lastLoggedRatio; // Track last logged ratio to reduce debug noise
  bool _isResizeRatioLoaded =
      false; // Track if resize ratio has been loaded from preferences

  // Mobile video resize state variables
  double _mobileVideoResizeRatio = 0.4;
  Timer? _mobileResizeRatioSaveTimer; // Timer for debouncing mobile resize ratio saves
  bool _isMobileResizeRatioLoaded = false; // Track if mobile resize ratio has been loaded from preferences

  // AI Explanation Cubit
  late AiExplanationCubit _aiExplanationCubit;

  // Layout preference for desktop
  String _layoutPreference = 'layout1'; // Default to layout1

  // Variables to track initial values for unsaved changes detection
  String _initialOriginalText = '';
  String _initialEditedText = '';
  String _initialStartTime = '';
  String _initialEndTime = '';

  // Variables to track time validation errors
  String? _startTimeError;
  String? _endTimeError;
  String? _timeOrderError;
  Timer? _characterCountTimer; // Debounce timer for character counting
  Timer? _timeUpdateTimer; // Debounce timer for time field updates
  Timer? _subtitleUpdateTimer; // Debounce timer for subtitle updates

  // Character count and validation variables
  final int _originalCharCount = 0;
  final int _editedCharCount = 0;
  final bool _originalHasLongLine = false;
  final bool _editedHasLongLine = false;

  // Character count update with 50ms debounce
  void _instantCharacterCountUpdate() {
    _characterCountTimer?.cancel();
    _characterCountTimer = Timer(const Duration(milliseconds: 50), () {
      // Character counting handled by EditLineBloc
    });
  }

  @override
  void initState() {
    super.initState();
    _originalController = TextEditingController();
    _editedController = TextEditingController();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
    _currentIndexController = TextEditingController();
    _scrollController = ScrollController();

    // Initialize AI Explanation Cubit
    _aiExplanationCubit = AiExplanationCubit();
    // Note: Stream listener is handled in the explanation sheet itself

    // Character counting listeners - use Cubit for reactive character counting
    _originalController.addListener(() {
      context.read<EditLineCubit>().updateOriginalText(_originalController.text);
    });
    
    _editedController.addListener(() {
      context.read<EditLineCubit>().updateEditedText(_editedController.text);
    });

    // Initialize error tracking variables
    _startTimeError = null;
    _endTimeError = null;
    _timeOrderError = null;

    // Initialize edit mode from widget property
    _isEditMode = widget.editMode || widget.isNewSubtitle;

    // Make time visible for new subtitles or in edit mode
    if (widget.isNewSubtitle || _isEditMode) {
      _isTimeVisible = true;
    }

    // Initialize video player state
    _initializeVideoPlayer();

    // Register hotkey shortcuts
    _registerHotkeyShortcuts();

    // Batch all async initialization operations for better performance
    _initializeAsyncData();
  }

  // Optimized async initialization with batched operations
  Future<void> _initializeAsyncData() async {
    try {
      // Run all independent async operations in parallel
      final futures = <Future>[
        _loadColorHistory(),
        _loadMsoneStatus(),
        _loadShowOriginalLine(),
        _loadAutoSaveWithNavigation(),
        _loadSaveToFileEnabled(),
        _loadAutoResizeOnKeyboard(),
        // _loadMaxLineLength() removed - maxLineLength now handled by EditLineRepository
        _loadShowOriginalTextField(),
        _loadResizeRatio(), // Load resize ratio
        _loadMobileResizeRatio(), // Load mobile resize ratio
        _loadLayoutPreference(), // Load layout preference
        if (_isEditMode) _loadSavedVideoPath(),
        _fetchSubtitleLine(widget.subtitleId, widget.index - 1),
      ];

      await Future.wait(futures);

      // Initialize character counts
      _instantCharacterCountUpdate();
    } catch (e) {
      await logError(
        'Error during initialization',
        error: e,
        context: 'EditSubtitleScreen._initializeAsync',
      );
    }
  }

  void _initializeVideoPlayer() {
    _isVideoLoaded = widget.isVideoLoaded;
    _selectedVideoPath = widget.videoPath;
    _isVideoVisible = _isVideoLoaded; // Show video by default if loaded

    // Initialize video playing state
    _isVideoPlaying = false;

    // Initialize secondary subtitles if provided
    if (widget.secondarySubtitles != null &&
        widget.secondarySubtitles!.isNotEmpty) {
      _secondarySubtitles = widget.secondarySubtitles!;
      _showSecondarySubtitles = true;
      _generateSecondarySubtitles();
    } else {
      _showSecondarySubtitles = false;
    }

    // Generate initial subtitles if subtitle data is available
    if (_subtitle != null) {
      _markSubtitlesForRegeneration();
      _generateSubtitles();
    }

    // Sync video player state after a short delay to ensure video player is loaded
    if (_isVideoLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _syncVideoPlayerState();
        });
      });
    }
  }

  /// Register hotkey shortcuts using MSoneHotkeyManager
  Future<void> _registerHotkeyShortcuts() async {
    // Unregister HomeScreen shortcuts to prevent conflicts (e.g., Ctrl+E)
    await hotkey.MSoneHotkeyManager.instance.unregisterHomeScreenShortcuts();
    
    await hotkey.MSoneHotkeyManager.instance
        .registerEditSubtitleScreenShortcuts(
          onSave: _handleSaveShortcut,
          onNextLine: _handleNextLineShortcut,
          onPreviousLine: _handlePreviousLineShortcut,
          onTextFormatting: _handleTextFormattingShortcut,
          onDelete: _handleDeleteCurrentShortcut,
          onPlayPause: _handlePlayPauseShortcut,
          // New shortcuts
          onMsoneDictionary: _showMsoneDictionary,
          onOlamDictionary: _showOlamDictionary,
          onUrbanDictionary: _showUrbanDictionary,
          onColorPicker: _handleColorPickerShortcut,
          onMarkLine: _handleMarkLineShortcut,
          onMarkLineAndComment: _handleMarkLineAndCommentShortcut,
          onJumpToLine: _handleJumpToLineShortcut,
          onHelp: _handleHelpShortcut,
          onSettings: _handleSettingsShortcut,
          onPopScreen: _handlePopScreenShortcut,
          // Add video control shortcuts
          onToggleRepeat: _handleToggleRepeatShortcut,
          onToggleRepeatRange: _handleToggleRepeatRangeShortcut,
          onToggleFullscreen: _handleToggleFullscreenShortcut,
          // New split and merge shortcuts
          onSplitLine: _handleSplitLineShortcut,
          onMergeLine: _handleMergeLineShortcut,
          // Video sync shortcut
          onSyncWithVideo: () => _syncWithVideoPosition(),
          // Marked lines sheet shortcut
          onShowMarkedLines: _showMarkedLinesModal,
          // Paste original shortcut
          onPasteOriginal: _handlePasteOriginalShortcut,
        );
  }

  /// Sync the play/pause button state with the actual video player state
  void _syncVideoPlayerState() {
    if (_videoPlayerKey.currentState != null && mounted) {
      final actualPlayingState = _videoPlayerKey.currentState!.isPlaying();
      if (_isVideoPlaying != actualPlayingState) {
        setState(() {
          _isVideoPlaying = actualPlayingState;
        });
      }
    }
  } // Performance optimization: Track if subtitles need regeneration

  bool _needSubtitleRegeneration = true;

  void _generateSubtitles() {
    if (_subtitle?.lines != null && _needSubtitleRegeneration) {
      final newSubtitles =
          _subtitle!.lines.asMap().entries.map((entry) {
            final index =
                entry.key; // Use array index instead of database index
            final line = entry.value;
            return Subtitle(
              index:
                  index, // This ensures video player uses same indexing as list
              start: parseTimeString(line.startTime),
              end: parseTimeString(line.endTime),
              text:
                  line.edited?.replaceAll('<br>', '\n') ??
                  line.original.replaceAll('<br>', '\n'),
              marked: line.marked,
            );
          }).toList();

      setState(() {
        _subtitles = newSubtitles;
        _needSubtitleRegeneration = false;
      });

      // Update video player with new subtitles (this will check for changes internally)
      if (_videoPlayerKey.currentState != null) {
        _videoPlayerKey.currentState!.updateSubtitles(_subtitles);
      }
    }
  }

  // Method to mark subtitles as needing regeneration
  void _markSubtitlesForRegeneration() {
    _needSubtitleRegeneration = true;
  }

  void _seekVideoToSubtitle() {
    if (_isVideoLoaded &&
        _videoPlayerKey.currentState != null &&
        _subtitleLine != null) {
      final startTime = parseTimeString(_subtitleLine!.startTime);
      // Add 50ms offset to ensure subtitle is visible after seeking
      // This prevents the subtitle from disappearing when seeking to exact start time
      final seekPosition = startTime + const Duration(milliseconds: 50);

      // Check if video player is initialized
      if (_videoPlayerKey.currentState!.isInitialized()) {
        _videoPlayerKey.currentState!.seekTo(seekPosition);
        // Pause video if repeat mode is enabled to prevent autoplay on navigation
        if (_isRepeatModeEnabled) {
          _videoPlayerKey.currentState!.pause();
        }
      } else {
        // Wait for video player to initialize, then seek
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_videoPlayerKey.currentState != null &&
                _videoPlayerKey.currentState!.isInitialized()) {
              _videoPlayerKey.currentState!.seekTo(seekPosition);
              // Pause video if repeat mode is enabled to prevent autoplay on navigation
              if (_isRepeatModeEnabled) {
                _videoPlayerKey.currentState!.pause();
              }
            }
          });
        });
      }
    }
  }

  /// Toggle repeat playback mode for current subtitle
  void _toggleRepeatMode() {
    if (!_isVideoLoaded || _subtitleLine == null) {
      SnackbarHelper.showWarning(
        context,
        'Video or subtitle not available for repeat mode',
      );
      return;
    }

    setState(() {
      _isRepeatModeEnabled = !_isRepeatModeEnabled;
    });

    if (_isRepeatModeEnabled) {
      _startRepeatPlayback();
      SnackbarHelper.showSuccess(
        context,
        'Repeat mode enabled for current subtitle',
      );
    } else {
      _stopRepeatPlayback();
      SnackbarHelper.showInfo(context, 'Repeat mode disabled');
    }
  }

  /// Start repeat playback for current subtitle or custom range
  void _startRepeatPlayback() {
    if (!_isVideoLoaded || _videoPlayerKey.currentState == null) {
      return;
    }

    // Check if video is currently playing to preserve the play state
    final wasPlaying = _videoPlayerKey.currentState!.isPlaying();

    Duration startTime, endTime;

    if (_isCustomRangeMode &&
        _customRangeStartIndex != null &&
        _customRangeEndIndex != null) {
      // Custom range mode: use start time of start index and end time of end index
      final startSubtitle = _subtitles.firstWhere(
        (s) => s.index == _customRangeStartIndex! + 1,
      );
      final endSubtitle = _subtitles.firstWhere(
        (s) => s.index == _customRangeEndIndex! + 1,
      );

      startTime = startSubtitle.start - const Duration(milliseconds: 100);
      endTime = endSubtitle.end + const Duration(milliseconds: 100);
    } else {
      // Normal mode: use current subtitle
      if (_subtitleLine == null) return;
      startTime =
          parseTimeString(_subtitleLine!.startTime) -
          const Duration(milliseconds: 100);
      endTime =
          parseTimeString(_subtitleLine!.endTime) +
          const Duration(milliseconds: 100);
    }

    // Ensure start time is not negative
    final clampedStartTime = startTime.isNegative ? Duration.zero : startTime;

    // Seek to start position, but only play if video was already playing
    _videoPlayerKey.currentState!.seekTo(clampedStartTime);
    if (wasPlaying) {
      _videoPlayerKey.currentState!.play();
    }

    // Set up timer to monitor playback and repeat
    _repeatPlaybackTimer?.cancel();
    _repeatPlaybackTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted ||
          !_isRepeatModeEnabled ||
          _videoPlayerKey.currentState == null) {
        timer.cancel();
        return;
      }

      final currentPosition =
          _videoPlayerKey.currentState!.getCurrentPosition();

      // Loop back to start time if needed
      if (currentPosition >= endTime) {
        _videoPlayerKey.currentState!.seekTo(clampedStartTime);
        // Continue playing if video was playing
        if (_videoPlayerKey.currentState!.isPlaying()) {
          _videoPlayerKey.currentState!.play();
        }
      }
    });
  }

  /// Stop repeat playback and reset custom range
  void _stopRepeatPlayback() {
    _repeatPlaybackTimer?.cancel();
    _repeatPlaybackTimer = null;
    // Reset custom range when stopping repeat mode
    _isCustomRangeMode = false;
    _customRangeStartIndex = null;
    _customRangeEndIndex = null;
  }

  /// Update repeat timing for current subtitle without changing play/pause state
  void _updateRepeatTiming() {
    if (!_isVideoLoaded ||
        _videoPlayerKey.currentState == null ||
        _subtitleLine == null) {
      return;
    }

    Duration startTime, endTime;

    if (_isCustomRangeMode &&
        _customRangeStartIndex != null &&
        _customRangeEndIndex != null) {
      // Custom range mode: use start time of start index and end time of end index
      final startSubtitle = _subtitles.firstWhere(
        (s) => s.index == _customRangeStartIndex! + 1,
      );
      final endSubtitle = _subtitles.firstWhere(
        (s) => s.index == _customRangeEndIndex! + 1,
      );

      startTime = startSubtitle.start - const Duration(milliseconds: 100);
      endTime = endSubtitle.end + const Duration(milliseconds: 100);
    } else {
      // Normal mode: use current subtitle
      startTime =
          parseTimeString(_subtitleLine!.startTime) -
          const Duration(milliseconds: 100);
      endTime =
          parseTimeString(_subtitleLine!.endTime) +
          const Duration(milliseconds: 100);
    }

    // Ensure start time is not negative
    final clampedStartTime = startTime.isNegative ? Duration.zero : startTime;

    // Seek to start position and pause (don't auto-play after navigation)
    _videoPlayerKey.currentState!.seekTo(clampedStartTime);
    _videoPlayerKey.currentState!.pause();

    // Set up timer to monitor playback and repeat
    _repeatPlaybackTimer?.cancel();
    _repeatPlaybackTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted ||
          !_isRepeatModeEnabled ||
          _videoPlayerKey.currentState == null) {
        timer.cancel();
        return;
      }

      final currentPosition =
          _videoPlayerKey.currentState!.getCurrentPosition();

      // If we've reached the end time, seek back to start and continue playing only if video is playing
      if (currentPosition >= endTime) {
        _videoPlayerKey.currentState!.seekTo(clampedStartTime);
        // Only continue playing if the video is currently playing
        if (_videoPlayerKey.currentState!.isPlaying()) {
          _videoPlayerKey.currentState!.play();
        }
      }
    });
  }

  /// Set custom repeat range
  void setCustomRepeatRange(int startIndex, int endIndex) {
    if (startIndex <= endIndex &&
        startIndex >= 0 &&
        endIndex < _subtitles.length) {
      _isCustomRangeMode = true;
      _customRangeStartIndex = startIndex;
      _customRangeEndIndex = endIndex;

      // If repeat mode is already enabled, restart with new range
      if (_isRepeatModeEnabled) {
        _startRepeatPlayback();
      }
    }
  }

  /// Clear custom repeat range and switch to normal repeat mode
  void clearCustomRepeatRange() {
    _isCustomRangeMode = false;
    _customRangeStartIndex = null;
    _customRangeEndIndex = null;

    // If repeat mode is enabled, restart with normal mode
    if (_isRepeatModeEnabled) {
      _startRepeatPlayback();
    }
  }

  // Public interface methods for video player widget

  /// Get subtitles list for external access
  List<Subtitle> get subtitles => _subtitles;

  /// Get repeat mode enabled state
  bool get isRepeatModeEnabled => _isRepeatModeEnabled;

  /// Toggle repeat mode (public method)
  void toggleRepeatMode() => _toggleRepeatMode();

  /// Start repeat playback (public method)
  void startRepeatPlayback() => _startRepeatPlayback();

  // Load video file for edit mode
  Future<void> _pickVideoFile() async {
    final filePath = await FilePickerConvenience.pickVideoFile(
      context: context,
    );

    if (filePath != null) {
      setState(() {
        _selectedVideoPath = filePath;
        _isVideoVisible = true;
        _isVideoLoaded = true;
      });

      // Save video path to preferences for this subtitle collection
      await PreferencesModel.saveVideoPath(widget.subtitleId, filePath);

      // Generate subtitles for video player
      _markSubtitlesForRegeneration();
      _generateSubtitles();

      // Seek to current subtitle if available
      if (_subtitleLine != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _seekVideoToSubtitle();
        });
      }

      // Show success message
      SnackbarHelper.showSuccess(
        context,
        'Video loaded successfully',
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Unload video (optimized single setState)
  Future<void> _unloadVideo() async {
    setState(() {
      _selectedVideoPath = null;
      _isVideoVisible = false;
      _isVideoLoaded = false;
    });

    await PreferencesModel.removeVideoPath(widget.subtitleId);
    SnackbarHelper.showInfo(
      context,
      'Video unloaded',
      duration: const Duration(seconds: 2),
    );
  }

  // Sync with current video position and find nearest subtitle
  Future<void> _syncWithVideoPosition() async {
    if (!_isVideoLoaded || 
        _videoPlayerKey.currentState == null || 
        !_videoPlayerKey.currentState!.isInitialized() ||
        _subtitle?.lines == null) {
      SnackbarHelper.showError(
        context,
        'Video player not ready or no subtitles available',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      // Get current video position
      final currentPosition = _videoPlayerKey.currentState!.getCurrentPosition();
      
      await logInfo(
        'Sync: Current video position: ${currentPosition.toString()}, subtitle line: ${_subtitleLine!.toString()}',
        context: 'EditSubtitleScreen._handleVideoSync',
      );
      
      // Find the nearest subtitle line
      int nearestIndex = _findNearestSubtitleIndex(currentPosition);
      
      if (nearestIndex == -1) {
        SnackbarHelper.showInfo(
          context,
          'No subtitle found near current video position',
          duration: const Duration(seconds: 2),
        );
        return;
      }
      
      await logInfo(
        'Sync: Found nearest subtitle at index: $nearestIndex (0-based)',
        context: 'EditSubtitleScreen._handleVideoSync',
      );
      
      // Check if the current subtitle line position is the same as the nearest index
      // If so, skip the operation to avoid unnecessary navigation
      if (_subtitleLine != null && _subtitleLine!.index - 1 == nearestIndex) {
        await logInfo(
          'Sync: Current subtitle position is same as nearest index, skipping operation',
          context: 'EditSubtitleScreen._handleVideoSync',
        );
        SnackbarHelper.showInfo(
          context,
          'Already on the nearest subtitle line',
          duration: const Duration(seconds: 1),
        );
        return;
      }
      
      // Check if we need to save current changes before navigating
      if (_hasUnsavedChanges()) {
        final shouldSave = await _showUnsavedChangesDialog();
        if (!shouldSave) return; // User chose to leave without saving or cancelled
      }
      
      // Navigate to the found subtitle line
      // nearestIndex is 0-based, but _skipToLine expects 0-based index
      _skipToLine(widget.subtitleId, nearestIndex);
      
      SnackbarHelper.showSuccess(
        context,
        'Synced to subtitle line ${nearestIndex + 1}',
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      await logError(
        'Error during video sync',
        error: e,
        context: 'EditSubtitleScreen._handleVideoSync',
      );
      SnackbarHelper.showError(
        context,
        'Failed to sync with video position',
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Find the nearest subtitle index based on video position
  int _findNearestSubtitleIndex(Duration currentPosition) {
    if (_subtitle?.lines == null || _subtitle!.lines.isEmpty) {
      return -1;
    }

    int nearestIndex = -1;
    Duration smallestDistance = const Duration(hours: 24); // Large initial value
    
    for (int i = 0; i < _subtitle!.lines.length; i++) {
      final line = _subtitle!.lines[i];
      
      try {
        // Parse subtitle times
        final startTime = _parseSubtitleTime(line.startTime);
        final endTime = _parseSubtitleTime(line.endTime);
        
        final startDuration = Duration(
          hours: startTime.hour,
          minutes: startTime.minute,
          seconds: startTime.second,
          milliseconds: startTime.millisecond,
        );
        
        final endDuration = Duration(
          hours: endTime.hour,
          minutes: endTime.minute,
          seconds: endTime.second,
          milliseconds: endTime.millisecond,
        );
        
        // Check if current position is within subtitle time range
        if (currentPosition >= startDuration && currentPosition <= endDuration) {
          // Direct match - current position is within this subtitle's timing
          return i;
        }
        
        // Calculate distance to subtitle start time
        final distanceToStart = (currentPosition - startDuration).abs();
        
        // Update nearest if this is closer
        if (distanceToStart < smallestDistance) {
          smallestDistance = distanceToStart;
          nearestIndex = i;
        }
        
        // Also check distance to end time for better accuracy
        final distanceToEnd = (currentPosition - endDuration).abs();
        if (distanceToEnd < smallestDistance) {
          smallestDistance = distanceToEnd;
          nearestIndex = i;
        }
        
      } catch (e) {
        logWarning(
          'Error parsing time for subtitle $i: $e',
          context: 'EditSubtitleScreen._findNearestSubtitleIndex',
        );
        continue;
      }
    }
    
    return nearestIndex;
  }

  // Optimized settings loading with single setState
  Future<void> _loadMsoneStatus() async {
    final msoneEnabled = await PreferencesModel.getMsoneEnabled();
    if (mounted) {
      setState(() {
        _isMsoneEnabled = msoneEnabled;
      });
    }
  }

  // Optimized settings reload with single setState
  Future<void> _reloadAllSettings() async {
    final results = await Future.wait([
      PreferencesModel.getMsoneEnabled(),
      PreferencesModel.getSaveToFileEnabled(),
      PreferencesModel.getAutoResizeOnKeyboard(),
      PreferencesModel.getMaxLineLength(),
    ]);

    if (mounted) {
      setState(() {
        _isMsoneEnabled = results[0] as bool;
        _isSaveToFileEnabled = results[1] as bool;
        _autoResizeOnKeyboard = results[2] as bool;
        // results[3] was _maxLineLength - no longer needed (handled by Bloc)
      });

      // Character counts will be recalculated by Cubit when text changes
    }
  }

  // Optimized color history loading
  Future<void> _loadColorHistory() async {
    final colorStrings = await PreferencesModel.getColorHistory();
    if (mounted) {
      setState(() {
        _colorHistory.clear();
        _colorHistory.addAll(
          colorStrings.map((color) => Color(int.parse(color))),
        );
      });
    }
  }

  Future<void> _saveColorHistory() async {
    final colorStrings =
        _colorHistory
            .map(
              (color) =>
                  '${(color.a * 255).round() << 24 | (color.r * 255).round() << 16 | (color.g * 255).round() << 8 | (color.b * 255).round()}',
            )
            .toList();
    await PreferencesModel.saveColorHistory(colorStrings);
  }

  Future<void> _loadShowOriginalLine() async {
    final showOriginalLine = await PreferencesModel.getShowOriginalLine();
    setState(() {
      _showOriginalLine = showOriginalLine;
    });
  }

  Future<void> _saveShowOriginalLine(bool value) async {
    setState(() {
      _showOriginalLine = value;
      // When enabling Show Original Line, default auto-save to false
      if (value) {
        _autoSaveWithNavigation = false;
      } else {
        _autoSaveWithNavigation =
            true; // Always true when Show Original Line is disabled
      }
    });

    await PreferencesModel.setShowOriginalLine(value);
    // Update the auto-save setting in preferences
    if (value) {
      await PreferencesModel.setAutoSaveWithNavigation(false);
    } else {
      await PreferencesModel.setAutoSaveWithNavigation(true);
    }

    _applyShowOriginalLine();
  }

  Future<void> _loadAutoSaveWithNavigation() async {
    final autoSave = await PreferencesModel.getAutoSaveWithNavigation();
    final showOriginal = await PreferencesModel.getShowOriginalLine();

    setState(() {
      // Auto-save is true by default unless Show Original Line is enabled
      if (showOriginal) {
        _autoSaveWithNavigation = autoSave;
      } else {
        _autoSaveWithNavigation = true; // Always true in normal mode
      }
    });
  }

  Future<void> _saveAutoSaveWithNavigation(bool value) async {
    setState(() {
      _autoSaveWithNavigation = value;
    });
    await PreferencesModel.setAutoSaveWithNavigation(value);
  }

  Future<void> _loadSaveToFileEnabled() async {
    final saveToFileEnabled =
        await PreferencesModel.getSaveToFileEnabled();
    setState(() {
      _isSaveToFileEnabled = saveToFileEnabled;
    });
  }

  Future<void> _loadAutoResizeOnKeyboard() async {
    final autoResizeOnKeyboard = await PreferencesModel.getAutoResizeOnKeyboard();
    setState(() {
      _autoResizeOnKeyboard = autoResizeOnKeyboard;
    });
  }

  // Load show original text field setting
  Future<void> _loadShowOriginalTextField() async {
    try {
      final showOriginalTextField =
          await PreferencesModel.getShowOriginalTextField();
      setState(() {
        _showOriginalTextField = showOriginalTextField;
      });
    } catch (e) {
      // Default to true if loading fails
      setState(() {
        _showOriginalTextField = true;
      });
    }
  }

  // Save show original text field setting
  Future<void> _saveShowOriginalTextField(bool value) async {
    try {
      await PreferencesModel.setShowOriginalTextField(value);
      setState(() {
        _showOriginalTextField = value;
      });
    } catch (e) {
      logError(
        'Failed to save show original text field setting',
        error: e,
        context: 'EditSubtitleScreen._saveShowOriginalTextField',
      );
    }
  }

  // Load saved video path for edit mode
  Future<void> _loadSavedVideoPath() async {
    if (_isEditMode || widget.isNewSubtitle) {
      final savedPath = await PreferencesModel.getVideoPath(
        widget.subtitleId,
      );
      if (savedPath != null && mounted) {
        setState(() {
          _selectedVideoPath = savedPath;
          _isVideoVisible = true;
          _isVideoLoaded = true;
        });
      }
    }
  }

  // Load resize ratio preference
  Future<void> _loadResizeRatio() async {
    final ratio = await PreferencesModel.getEditLineResizeRatio();
    await logInfo(
      'Loading resize ratio: $ratio',
      context: 'EditSubtitleScreen._loadResizeRatio',
    );
    if (mounted) {
      setState(() {
        _resizeRatio = ratio;
        _isResizeRatioLoaded = true;
      });
      await logInfo(
        'Updated _resizeRatio to: $_resizeRatio, loaded: $_isResizeRatioLoaded',
        context: 'EditSubtitleScreen._loadResizeRatio',
      );
    }
  }

  // Save resize ratio preference with debouncing
  Future<void> _saveResizeRatio(double ratio) async {
    // Only log when ratio changes significantly
    if (_lastLoggedRatio == null || (ratio - _lastLoggedRatio!).abs() > 0.05) {
      await logInfo(
        '_saveResizeRatio called with: $ratio',
        context: 'EditSubtitleScreen._saveResizeRatio',
      );
      _lastLoggedRatio = ratio;
    }

    setState(() {
      _resizeRatio = ratio;
    });

    // Cancel any existing timer
    _resizeRatioSaveTimer?.cancel();

    // Start a new timer to save after a short delay
    _resizeRatioSaveTimer = Timer(const Duration(milliseconds: 300), () async {
      await logInfo(
        'Timer saving ratio to SharedPreferences: $ratio',
        context: 'EditSubtitleScreen._saveResizeRatio',
      );
      await PreferencesModel.setEditLineResizeRatio(ratio);
      await logInfo(
        'Save completed - verification: ${await PreferencesModel.getEditLineResizeRatio()}',
        context: 'EditSubtitleScreen._saveResizeRatio',
      );
    });
  }

  /// Load mobile video resize ratio from preferences
  Future<void> _loadMobileResizeRatio() async {
    if (!mounted) return;
    
    try {
      final ratio = await PreferencesModel.getMobileVideoResizeRatio();
      if (mounted) {
        setState(() {
          _mobileVideoResizeRatio = ratio;
          _isMobileResizeRatioLoaded = true;
        });
      }
    } catch (e) {
      logError(
        'Error loading mobile resize ratio',
        error: e,
        context: 'EditSubtitleScreen._loadMobileResizeRatio',
      );
      if (mounted) {
        setState(() {
          _mobileVideoResizeRatio = 0.4; // Default fallback
          _isMobileResizeRatioLoaded = true;
        });
      }
    }
  }

  /// Save mobile video resize ratio with debouncing
  void _saveMobileResizeRatio(double ratio) {
    // Cancel any existing timer
    _mobileResizeRatioSaveTimer?.cancel();
    
    // Set up a new timer with 500ms delay
    _mobileResizeRatioSaveTimer = Timer(Duration(milliseconds: 500), () async {
      try {
        await PreferencesModel.setMobileVideoResizeRatio(ratio);
      } catch (e) {
        logError(
          'Error saving mobile resize ratio',
          error: e,
          context: 'EditSubtitleScreen._saveMobileResizeRatio',
        );
      }
    });
  }

  /// Load layout preference for desktop layout switching
  Future<void> _loadLayoutPreference() async {
    final layout = await PreferencesModel.getSwitchLayout();
    if (mounted) {
      setState(() {
        _layoutPreference = layout;
      });
    }
  }

  Future<void> _saveAutoResizeOnKeyboard(bool value) async {
    setState(() {
      _autoResizeOnKeyboard = value;
    });
    await PreferencesModel.setAutoResizeOnKeyboard(value);
  }

  void _applyShowOriginalLine() {
    if (_showOriginalLine &&
        (_editedController.text.isEmpty || _editedController.text == '') &&
        _originalController.text.isNotEmpty) {
      setState(() {
        _editedController.text = _originalController.text;
      });
    }
  }

  // Store the initial values when a subtitle line is loaded
  void _storeInitialValues() {
    _initialOriginalText = _originalController.text;
    _initialEditedText = _editedController.text;
    _initialStartTime = _startTimeController.text;
    _initialEndTime = _endTimeController.text;
  }

  // Parse time string (HH:mm:ss,SSS) and set the corresponding controller
  void _parseTimeString(String timeString, bool isStartTime) {
    try {
      // If time string is valid, set it directly to the controller
      if (timeString.isNotEmpty) {
        if (isStartTime) {
          _startTimeController.text = timeString;
        } else {
          _endTimeController.text = timeString;
        }
      } else {
        // Set default values
        if (isStartTime) {
          _startTimeController.text = '00:00:00,000';
        } else {
          _endTimeController.text = '00:00:05,000';
        }
      }
    } catch (e) {
      // If parsing fails, set default values
      if (isStartTime) {
        _startTimeController.text = '00:00:00,000';
      } else {
        _endTimeController.text = '00:00:05,000';
      }
    }
  }

  // Get time string from the corresponding controller
  String _combineTimeComponents(bool isStartTime) {
    try {
      String timeString = isStartTime ? _startTimeController.text : _endTimeController.text;
      
      // If the controller is empty, return default time
      if (timeString.isEmpty) {
        return isStartTime ? '00:00:00,000' : '00:00:05,000';
      }
      
      return timeString;
    } catch (e) {
      // Return default time if there's an error
      return isStartTime ? '00:00:00,000' : '00:00:05,000';
    }
  }

  // Validate time components and show errors if any
  String? _validateTimeComponents(bool isStartTime) {
    try {
      String timeString = isStartTime ? _startTimeController.text : _endTimeController.text;
      return TimeValidator.validateTimeString(timeString);
    } catch (e) {
      return 'Invalid time format';
    }
  }

  // Validate that start time is less than end time
  String? _validateTimeOrder() {
    String startTime = _combineTimeComponents(true);
    String endTime = _combineTimeComponents(false);

    return TimeValidator.validateTimeOrder(startTime, endTime);
  }

  // Sync time from video for start time
  void _syncStartTimeFromVideo() {
    if (_isVideoLoaded && _videoPlayerKey.currentState != null) {
      final currentPosition =
          _videoPlayerKey.currentState!.getCurrentPosition();
      final timeString = SubtitleSyncOperations.formatDuration(currentPosition);

      // Parse the time string into components
      _parseTimeString(timeString, true);

      // Update the combined controller
      _updateCombinedTimeControllers();

      // Show feedback to user
      SnackbarHelper.showSuccess(
        context,
        'Start time synced to current video position: $timeString',
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Sync time from video for end time
  void _syncEndTimeFromVideo() {
    if (_isVideoLoaded && _videoPlayerKey.currentState != null) {
      final currentPosition =
          _videoPlayerKey.currentState!.getCurrentPosition();
      final timeString = SubtitleSyncOperations.formatDuration(currentPosition);

      // Parse the time string into components
      _parseTimeString(timeString, false);

      // Update the combined controller
      _updateCombinedTimeControllers();

      // Show feedback to user
      SnackbarHelper.showSuccess(
        context,
        'End time synced to current video position: $timeString',
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Instant time controller updates (removed debouncing for maximum responsiveness)
  void _updateCombinedTimeControllers({bool validateTime = false}) {
    // Cancel any pending timer and update immediately
    _timeUpdateTimer?.cancel();

    if (!mounted) return;

    // Preserve cursor positions before updating text
    final startCursor = _startTimeController.selection;
    final endCursor = _endTimeController.selection;

    final newStartText = _combineTimeComponents(true);
    final newEndText = _combineTimeComponents(false);

    // Only update text if it actually changed to avoid cursor reset
    if (_startTimeController.text != newStartText) {
      _startTimeController.text = newStartText;
    } else {
      // Text didn't change, restore cursor position that might have been affected
      _startTimeController.selection = startCursor;
    }

    if (_endTimeController.text != newEndText) {
      _endTimeController.text = newEndText;  
    } else {
      // Text didn't change, restore cursor position that might have been affected
      _endTimeController.selection = endCursor;
    }

    // If validation is explicitly requested, validate and set errors
    if (validateTime) {
      setState(() {
        _startTimeError = _validateTimeComponents(true);
        _endTimeError = _validateTimeComponents(false);
        _timeOrderError = _validateTimeOrder();
      });
    } else {
      // If there were previous validation errors, re-validate to potentially clear them
      // This allows real-time validation clearing when user fixes time values
      if (_startTimeError != null ||
          _endTimeError != null ||
          _timeOrderError != null) {
        setState(() {
          _startTimeError = _validateTimeComponents(true);
          _endTimeError = _validateTimeComponents(false);
          _timeOrderError = _validateTimeOrder();
        });
      }
    }
  }

  // Build simplified time input field
  Widget _buildTimeComponentFields(String label, bool isStartTime) {
    final timeController = isStartTime ? _startTimeController : _endTimeController;

    // Determine error states
    final hasComponentError =
        isStartTime ? _startTimeError != null : _endTimeError != null;
    final hasOrderError = _timeOrderError != null;
    final hasError = hasComponentError || hasOrderError;

    final borderColor = hasError ? Colors.red : const Color(0xFF0A9396);
    final focusedBorderColor = hasError ? Colors.red : const Color(0xFF0A9396);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start, // Grow downward only
      mainAxisSize: MainAxisSize.min, // Take minimum space needed
      children: [
        // Title row with video sync button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: hasError ? Colors.red : null,
              ),
            ),
            if (_isVideoLoaded) ...[
              const SizedBox(width: 12),
              IconButton(
                onPressed:
                    isStartTime
                        ? _syncStartTimeFromVideo
                        : _syncEndTimeFromVideo,
                icon: const Icon(Icons.sync),
                color: const Color(0xFF0A9396),
                iconSize: 20,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip:
                    'Sync ${isStartTime ? 'start' : 'end'} time with current video position',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF0A9396,
                  ).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Single time input field with fixed separators
        TextField(
          controller: timeController,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            TimeInputFormatter(),
          ],
            style: TextStyle(
              color: hasError ? Colors.red : const Color(0xFFEE9B00),
              fontSize: 16, // Reduced from 18
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0, // Reduced from 1.2
            ),
            decoration: InputDecoration(
              hintText: 'HH:mm:ss,SSS',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14, // Reduced from 16
                fontWeight: FontWeight.normal,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, // Reduced from 12
                vertical: 12, // Reduced from 16
              ),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: borderColor,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: focusedBorderColor,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Disable autocorrect for faster input
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            textInputAction: TextInputAction.next,
            enableIMEPersonalizedLearning: false,
            enableInteractiveSelection: true,
            showCursor: true,
            onChanged: (value) {
              // Update Cubit if available
              try {
                final cubit = context.read<EditLineCubit>();
                if (isStartTime) {
                  cubit.updateStartTime(value);
                } else {
                  cubit.updateEndTime(value);
                }
              } catch (e) {
                // Cubit not available, continue with legacy
              }
              
              // Update time controllers after cursor position is set
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateCombinedTimeControllers();
              });
            },
            onEditingComplete: () {
              // Validate when user finishes editing this field
              _updateCombinedTimeControllers(validateTime: true);
            },
          ),

        const SizedBox(height: 8),

        // Format hint
        Text(
          'HH:mm:ss,SSS',
          style: TextStyle(
            fontSize: 11,
            color: hasError ? Colors.red : Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Show error message using BlocBuilder for reactive updates
        BlocBuilder<EditLineCubit, EditLineState>(
          buildWhen: (previous, current) =>
              previous.startTimeError != current.startTimeError ||
              previous.endTimeError != current.endTimeError ||
              previous.timeOrderError != current.timeOrderError,
          builder: (context, state) {
            // Use Bloc state if initialized, otherwise use legacy state
            final startError = state.isInitialized ? state.startTimeError : _startTimeError;
            final endError = state.isInitialized ? state.endTimeError : _endTimeError;
            final orderError = state.isInitialized ? state.timeOrderError : _timeOrderError;
            
            final componentError = isStartTime ? startError : endError;
            final hasComponentErr = componentError != null;
            final hasOrderErr = orderError != null;
            
            if (hasComponentErr) {
              return Text(
                componentError,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              );
            } else if (hasOrderErr) {
              return Text(
                orderError,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              );
            }
            
            // No error
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  // Check if there are unsaved changes
  bool _hasUnsavedChanges() {
    // Check text field changes
    bool hasTextChanges =
        _originalController.text != _initialOriginalText ||
        _editedController.text != _initialEditedText;

    // Check time changes using combined controllers
    bool hasTimeChanges =
        _startTimeController.text != _initialStartTime ||
        _endTimeController.text != _initialEndTime;

    // Also check if current time component state differs from initial combined time
    // This ensures we catch cases where time components have changed but may not
    // have been reflected in combined controllers yet
    if (!hasTimeChanges) {
      String currentStartTime = _combineTimeComponents(true);
      String currentEndTime = _combineTimeComponents(false);
      hasTimeChanges =
          currentStartTime != _initialStartTime ||
          currentEndTime != _initialEndTime;
    }

    return hasTextChanges || hasTimeChanges;
  }

  // Show confirmation dialog for unsaved changes
  Future<bool> _showUnsavedChangesDialog() async {
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          enableDrag: true,
          isDismissible: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            final primaryColor = Theme.of(context).primaryColor;
            final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
            final mutedColor = onSurfaceColor.withValues(alpha: 0.6);

            return Container(
              margin: const EdgeInsets.all(16),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Unsaved Changes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop(false); // Close dialog and stay on current screen
                      },
                      tooltip: 'Close (ESC)',
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You have unsaved changes in this subtitle line.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'What would you like to do?',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: mutedColor),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false); // Close dialog first
                      // Return the current active index (convert from 1-based to 0-based)
                      final currentIndex = _subtitleLine != null ? _subtitleLine!.index - 1 : widget.index;
                      Navigator.of(context).pop(currentIndex);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Leave Without Saving'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save changes and then leave
                      final saved = await _updateSubtitle(context);
                      if (saved && mounted) {
                        Navigator.of(context).pop(false); // Close dialog first
                        // Return the current active index (convert from 1-based to 0-based)
                        final currentIndex = _subtitleLine != null ? _subtitleLine!.index - 1 : widget.index;
                        Navigator.of(context).pop(currentIndex);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save & Leave'),
                  ),
                ],
              ),
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed
  }

  Future<void> _showOriginalLineWarningDialog(bool enableShowOriginal) async {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false, // User must tap a button
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // Dynamic color variables for adaptive theming
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).primaryColor;
        final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
        final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
        final borderColor = onSurfaceColor.withValues(alpha: 0.12);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important Notice',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please review these important changes',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: mutedColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Warning Content Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? onSurfaceColor.withValues(alpha: 0.05)
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (enableShowOriginal) ...[
                          Text(
                            'When "Show Original Line" is enabled:',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint(
                            'Original text will be copied to the edited field when it\'s empty',
                            context,
                          ),
                          const SizedBox(height: 8),
                          _buildBulletPoint(
                            'Auto-save with navigation will be DISABLED to prevent accidental saving of original text as edited',
                            context,
                          ),
                          const SizedBox(height: 8),
                          _buildBulletPoint(
                            'You can manually enable auto-save later at your own risk',
                            context,
                          ),
                        ] else ...[
                          Text(
                            'When "Show Original Line" is disabled:',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint(
                            'Original text will no longer be automatically copied to edited field',
                            context,
                          ),
                          const SizedBox(height: 8),
                          _buildBulletPoint(
                            'Auto-save with navigation will be ENABLED automatically',
                            context,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'Do you want to continue?',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSurface,
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.close,
                                  size: 20,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
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
                            onPressed: () {
                              Navigator.of(context).pop();
                              _saveShowOriginalLine(enableShowOriginal);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
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
                                  Icons.check,
                                  size: 20,
                                  color: onSurfaceColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Continue',
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulletPoint(String text, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Cancel any pending timers
    _characterCountTimer?.cancel();
    _timeUpdateTimer?.cancel();
    _subtitleUpdateTimer?.cancel();
    _repeatPlaybackTimer?.cancel(); // Cancel repeat playback timer
    _resizeRatioSaveTimer?.cancel(); // Cancel resize ratio save timer
    _mobileResizeRatioSaveTimer?.cancel(); // Cancel mobile resize ratio save timer

    // Dispose AI Explanation Cubit
    _aiExplanationCubit.close();

    // Remove character count listeners before disposing
    _originalController.removeListener(_instantCharacterCountUpdate);
    _editedController.removeListener(_instantCharacterCountUpdate);

    _originalController.dispose();
    _editedController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _currentIndexController.dispose();
    _scrollController.dispose();

    _saveColorHistory(); // Save color history when the screen is disposed

    // Unregister only this screen's hotkey shortcuts (not all shortcuts globally)
    // This prevents breaking shortcuts in the parent EditScreen
    hotkey.MSoneHotkeyManager.instance.unregisterEditSubtitleScreenShortcuts();

    super.dispose();
  }

  Future<void> _fetchSubtitleLine(subtitleId, lineIndex) async {
    // Clear any existing validation errors when loading a new line
    setState(() {
      _startTimeError = null;
      _endTimeError = null;
      _timeOrderError = null;
    });

    // Fetch the subtitle document using the provided ID
    _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;

    // Handle case when we're creating a new subtitle or at the end of the list
    if (widget.index > _subtitle!.lines.length) {
      if (widget.isNewSubtitle || _isEditMode) {
        // Create an empty subtitle line when in edit mode or creating a new subtitle
        setState(() {
          _subtitleLine =
              SubtitleLine()
                ..index =
                    _subtitle!.lines.isEmpty ? 1 : _subtitle!.lines.length + 1
                ..startTime = "00:00:00,000"
                ..endTime = "00:00:05,000"
                ..original = ""
                ..edited = "";

          _originalController.text = _subtitleLine!.original;
          _editedController.text = _subtitleLine!.edited ?? '';
          _startTimeController.text = _subtitleLine!.startTime;
          _endTimeController.text = _subtitleLine!.endTime;
          _currentIndexController.text = _subtitleLine!.index.toString();

          // Parse time strings into individual components
          _parseTimeString(_subtitleLine!.startTime, true);
          _parseTimeString(_subtitleLine!.endTime, false);

          // Store initial values for change tracking
          _storeInitialValues();

          // Character counts updated by Cubit
        });

        // Mark subtitles for regeneration and generate for video player
        _markSubtitlesForRegeneration();
        _generateSubtitles();
        
        return;
      }
    }

    // Check if lineIndex is within valid range before accessing the array
    if (widget.index <= _subtitle!.lines.length &&
        lineIndex >= 0 &&
        lineIndex < _subtitle!.lines.length) {
      _subtitleLine = _subtitle?.lines[lineIndex];
      setState(() {
        _originalController.text = _subtitleLine!.original;
        // Only set edited text if it exists, otherwise leave it empty
        _editedController.text =
            _subtitleLine!.edited != null
                ? _subtitleLine!.edited!.replaceAll('<br>', '\n')
                : '';
        _startTimeController.text = _subtitleLine!.startTime;
        _endTimeController.text = _subtitleLine!.endTime;
        _currentIndexController.text = _subtitleLine!.index.toString();
        // Apply show original line logic after setting controller values
        _applyShowOriginalLine();

        // Parse time strings into individual components
        _parseTimeString(_subtitleLine!.startTime, true);
        _parseTimeString(_subtitleLine!.endTime, false);

        // Store initial values for change tracking
        _storeInitialValues();

        // Character counts updated by Cubit
      });

      // Mark subtitles for regeneration and generate for video player
      _markSubtitlesForRegeneration();
      _generateSubtitles();

      // Seek video to current subtitle position if video is loaded
      if (_isVideoLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _seekVideoToSubtitle();
        });
      }
    } else {
      // Handle the case when the line index is out of range
      logError(
        'Invalid line index: $lineIndex, max index: ${_subtitle!.lines.length - 1}',
        context: 'EditSubtitleScreen._skipToLine',
      );
    }
  }

  /// Check if there are any validation errors that would prevent navigation
  bool _hasValidationErrors() {
    return _startTimeError != null ||
        _endTimeError != null ||
        _timeOrderError != null;
  }

  void _nextSubtitle(subtitleId, lineIndex) async {
    // Don't stop repeat mode when navigating - let it continue
    // Only stop if we're outside the custom range
    if (_isRepeatModeEnabled && _isCustomRangeMode) {
      final nextIndex = _subtitleLine?.index ?? 0;
      if (_customRangeEndIndex != null && nextIndex > _customRangeEndIndex!) {
        // We're going beyond the custom range, keep repeat but pause it temporarily
        _stopRepeatPlayback();
      }
    }

    // Check for validation errors first
    if (_hasValidationErrors()) {
      SnackbarHelper.showError(
        context,
        'Please fix validation errors before navigating',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Verify the next index is within bounds before navigating
    if (lineIndex > 0 && lineIndex <= _subtitle!.lines.length) {
      // Save changes if auto-save is enabled or we're in normal mode
      if (_autoSaveWithNavigation || !_showOriginalLine) {
        final saveSuccess = await _updateSubtitleSilently();
        if (!saveSuccess) {
          // Don't navigate if save failed
          return;
        }
      }
      // Navigate to next subtitle
      await _fetchSubtitleLine(subtitleId, lineIndex - 1);

      // Resume repeat if enabled
      if (_isRepeatModeEnabled) {
        final currentIndex =
            (_subtitleLine?.index ?? 1) - 1; // Convert to 0-based
        if (!_isCustomRangeMode) {
          // For normal repeat mode, update to the new subtitle line
          // This will update repeat timing with the new subtitle without changing play/pause state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateRepeatTiming();
          });
        } else if (_customRangeStartIndex != null &&
            _customRangeEndIndex != null &&
            currentIndex >= _customRangeStartIndex! &&
            currentIndex <= _customRangeEndIndex!) {
          // For custom range mode, only restart if we're still in range
          // Video is already paused by _seekVideoToSubtitle when repeat mode is enabled
          // User needs to manually start playback
        }
      }
    } else {
      // Show a message when there's no next subtitle
      SnackbarHelper.showWarning(
        context,
        'This is the last subtitle',
        duration: const Duration(seconds: 1),
      );
    }
  }

  void _prevSubtitle(subtitleId, lineIndex) async {
    // Don't stop repeat mode when navigating - let it continue
    // Only stop if we're outside the custom range
    if (_isRepeatModeEnabled && _isCustomRangeMode) {
      final prevIndex =
          (_subtitleLine?.index ?? 2) - 2; // Previous index in 0-based
      if (_customRangeStartIndex != null &&
          prevIndex < _customRangeStartIndex!) {
        // We're going before the custom range, keep repeat but pause it temporarily
        _stopRepeatPlayback();
      }
    }

    // Check for validation errors first
    if (_hasValidationErrors()) {
      SnackbarHelper.showError(
        context,
        'Please fix validation errors before navigating',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (lineIndex > 0 && lineIndex <= _subtitle!.lines.length) {
      // Save changes if auto-save is enabled or we're in normal mode
      if (_autoSaveWithNavigation || !_showOriginalLine) {
        final saveSuccess = await _updateSubtitleSilently();
        if (!saveSuccess) {
          // Don't navigate if save failed
          return;
        }
      }
      // Navigate to the previous subtitle line (lineIndex is 1-based, convert to 0-based for array access)
      await _fetchSubtitleLine(subtitleId, lineIndex - 1);

      // Resume repeat if we're in range and it was enabled
      if (_isRepeatModeEnabled) {
        final currentIndex =
            (_subtitleLine?.index ?? 1) - 1; // Convert to 0-based
        if (!_isCustomRangeMode) {
          // For normal repeat mode, update to the new subtitle line
          // This will update repeat timing with the new subtitle without changing play/pause state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateRepeatTiming();
          });
        } else if (_customRangeStartIndex != null &&
            _customRangeEndIndex != null &&
            currentIndex >= _customRangeStartIndex! &&
            currentIndex <= _customRangeEndIndex!) {
          // For custom range mode, only restart if we're still in range
          // Video is already paused by _seekVideoToSubtitle when repeat mode is enabled
          // User needs to manually start playback
        }
      }
    } else {
      // Show a message when there's no previous subtitle
      SnackbarHelper.showWarning(
        context,
        'This is the first subtitle',
        duration: const Duration(seconds: 1),
      );
    }
  }

  void _skipToLine(subtitleId, lineIndex) {
    // Check if we're navigating outside custom range
    if (_isRepeatModeEnabled && _isCustomRangeMode) {
      if (_customRangeStartIndex != null &&
          _customRangeEndIndex != null &&
          (lineIndex < _customRangeStartIndex! ||
              lineIndex > _customRangeEndIndex!)) {
        // We're going outside the custom range, pause repeat temporarily
        _stopRepeatPlayback();
      }
    }

    // Navigate to the specified subtitle line
    setState(() {
      _fetchSubtitleLine(subtitleId, lineIndex);
    });

    // Resume repeat if we're in range and it was enabled
    if (_isRepeatModeEnabled) {
      if (!_isCustomRangeMode) {
        // For normal repeat mode, update to the new subtitle line
        // This will update repeat timing with the new subtitle without changing play/pause state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateRepeatTiming();
        });
      } else if (_customRangeStartIndex != null &&
          _customRangeEndIndex != null &&
          lineIndex >= _customRangeStartIndex! &&
          lineIndex <= _customRangeEndIndex!) {
        // For custom range mode, only restart if we're still in range
        // Video is already paused by _seekVideoToSubtitle when repeat mode is enabled
        // User needs to manually start playback
      }
    }
  }

  Future<bool> _updateSubtitle(contxt) async {
    if (_subtitleLine != null) {
      // Ensure combined time controllers are up to date before checking for changes
      _updateCombinedTimeControllers();

      // Check if there are any changes to save
      if (!_hasUnsavedChanges()) {
        ScaffoldMessenger.of(contxt).showSnackBar(
          SnackBar(
            content: const Text('No changes to save'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(10),
          ),
        );
        return false;
      }

      // Check if the edited text is empty but there are other changes
      if (_editedController.text.trim().isEmpty) {
        // Allow saving if there are changes to original text or time fields
        if (_originalController.text != _initialOriginalText ||
            _startTimeController.text != _initialStartTime ||
            _endTimeController.text != _initialEndTime) {
          // There are changes to save, continue with save operation
        } else {
          // No changes at all and empty edited text
          ScaffoldMessenger.of(contxt).showSnackBar(
            SnackBar(
              content: const Text(
                'Cannot save empty edited text with no other changes',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(10),
            ),
          );
          return false;
        }
      }

      // Validate time before saving - enable validation and show errors
      _updateCombinedTimeControllers(validateTime: true);

      // Check if there are validation errors after validation
      if (_startTimeError != null ||
          _endTimeError != null ||
          _timeOrderError != null) {
        // Expand time section and highlight errors
        if (!_isTimeVisible) {
          setState(() {
            _isTimeVisible = true;
          });

          // Auto-scroll to time section
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        }

        // Show error message
        String errorMessage =
            _startTimeError ??
            _endTimeError ??
            _timeOrderError ??
            'Time validation failed';
        ScaffoldMessenger.of(contxt).showSnackBar(
          SnackBar(
            content: Text('Time validation error: $errorMessage'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(10),
          ),
        );
        return false;
      }

      try {
        if (_isEditMode) {
          // In edit mode, always update edited text (even if empty, to save the change)
          _subtitleLine!.edited = _editedController.text.replaceAll(
            '\n',
            '<br>',
          );
        } else {
          // In translation mode, update both original and edited text
          // Always update edited text to preserve the change (even if empty)
          _subtitleLine!.edited = _editedController.text.replaceAll(
            '\n',
            '<br>',
          );
          _subtitleLine!.original = _originalController.text;
        }

        // Update combined time controllers and use them for saving (validate during save)
        _updateCombinedTimeControllers(validateTime: true);
        _subtitleLine!.startTime = _startTimeController.text;
        _subtitleLine!.endTime = _endTimeController.text;

        // Handle new lines in edit mode
        if (_isEditMode && !_subtitle!.lines.contains(_subtitleLine)) {
          await Future.microtask(() async {
            await addSubtitleLine(
              widget.subtitleId,
              _subtitleLine!,
              _subtitle!.lines.length,
            );
          });
        } else {
          // Store the line state before changes for checkpoint
          final lineBeforeChanges = SubtitleLine()
            ..index = _subtitleLine!.index
            ..startTime = _initialStartTime
            ..endTime = _initialEndTime
            ..original = _initialOriginalText
            ..edited = _subtitleLine!.edited
            ..marked = _subtitleLine!.marked;
          
          // Call the database function for existing lines asynchronously
          await Future.microtask(() async {
            await saveSubtitleChangesToDatabase(
              _subtitle!.id,
              _subtitleLine!,
              _parseSubtitleTime,
              sessionId: widget.sessionId,
              beforeLine: lineBeforeChanges,
            );
          });
        }

        await Future.microtask(() async {
          await updateLastEditedIndex(widget.sessionId, _subtitleLine!.index);
        });

        // Mark subtitles for regeneration and regenerate subtitles for video player after saving changes (async)
        await Future.microtask(() {
          _markSubtitlesForRegeneration();
          _generateSubtitles();
        });

        // Check if we should save directly to file
        if (_isSaveToFileEnabled && _subtitle != null) {
          // Get the current edited content from the UI, not from database
          // Create an updated SubtitleLine with current form data
          final updatedLine =
              SubtitleLine()
                ..index = _subtitleLine!.index
                ..startTime = _startTimeController.text
                ..endTime = _endTimeController.text
                ..original = _originalController.text
                ..edited = _editedController.text.isEmpty ? null : _editedController.text
                ..marked = _subtitleLine!.marked;

          // Create a copy of all lines and update the current one
          final updatedLines = List<SubtitleLine>.from(_subtitle!.lines);
          final currentIndex = updatedLines.indexWhere((line) => line.index == _subtitleLine!.index);
          if (currentIndex != -1) {
            updatedLines[currentIndex] = updatedLine;
          }

          await _performEnhancedFileSave(contxt, updatedLines);
        } else {
          // Only show database-only success message if not saving to file
          if (!mounted) return true;

          ScaffoldMessenger.of(contxt).showSnackBar(
            SnackBar(
              content: const Text('Changes saved successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating, // Floating style
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), // Rounded corners
              ),
              duration: const Duration(seconds: 2), // Duration of the snackbar
              dismissDirection: DismissDirection.up,
              margin: EdgeInsets.all(10),
            ),
          );
        }

        // Update initial values after successful save
        _storeInitialValues();

        // Clear validation errors after successful save
        setState(() {
          _startTimeError = null;
          _endTimeError = null;
          _timeOrderError = null;
        });

        return true;
      } catch (e) {
        if (!mounted) return false;

        ScaffoldMessenger.of(contxt).showSnackBar(
          SnackBar(
            content: SafeArea(child: Text('Failed to save changes: $e')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating, // Floating style
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Rounded corners
            ),
            duration: const Duration(seconds: 2), // Duration of the snackbar
            margin: const EdgeInsets.all(10.0), // Margin for floating behavior
          ),
        );
        return false;
      }
    }
    return false;
  }

  Future<bool> _updateSubtitleSilently() async {
    if (_subtitleLine != null) {
      // Ensure combined time controllers are up to date before checking for changes
      _updateCombinedTimeControllers();

      // Check if there are any changes to save
      if (!_hasUnsavedChanges()) {
        // No changes to save, navigation should still be allowed
        return true;
      }

      // Allow saving if there are changes to original text or time fields,
      // even if edited text is empty
      if (_editedController.text.trim().isEmpty &&
          _originalController.text == _initialOriginalText &&
          _startTimeController.text == _initialStartTime &&
          _endTimeController.text == _initialEndTime) {
        // No changes at all, skip saving but allow navigation
        return true;
      }

      // Validate time components - show errors if validation fails during autosave
      _updateCombinedTimeControllers(validateTime: true);
      if (_startTimeError != null ||
          _endTimeError != null ||
          _timeOrderError != null) {
        // Expand time section and highlight errors
        if (!_isTimeVisible) {
          setState(() {
            _isTimeVisible = true;
          });

          // Auto-scroll to time section
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        }

        // Show error message for autosave validation failure
        String errorMessage =
            _startTimeError ??
            _endTimeError ??
            _timeOrderError ??
            'Time validation failed';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot autosave - Time validation error: $errorMessage',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
        return false;
      }

      try {
        if (_isEditMode) {
          // In edit mode, always update edited text (even if empty, to save the change)
          _subtitleLine!.edited = _editedController.text.replaceAll(
            '\n',
            '<br>',
          );
        } else {
          // In translation mode, update both original and edited text
          // Always update edited text to preserve the change (even if empty)
          _subtitleLine!.edited = _editedController.text.replaceAll(
            '\n',
            '<br>',
          );
          _subtitleLine!.original = _originalController.text;
        }

        // Update combined time controllers and use them for saving (validate during save)
        _updateCombinedTimeControllers(validateTime: true);
        _subtitleLine!.startTime = _startTimeController.text;
        _subtitleLine!.endTime = _endTimeController.text;
        // Handle new lines in edit mode
        if (_isEditMode && !_subtitle!.lines.contains(_subtitleLine)) {
          await Future.microtask(() async {
            await addSubtitleLine(
              widget.subtitleId,
              _subtitleLine!,
              _subtitle!.lines.length,
            );
          });
        } else {
          // Store the line state before changes for checkpoint (for silent save)
          final lineBeforeChanges = SubtitleLine()
            ..index = _subtitleLine!.index
            ..startTime = _initialStartTime
            ..endTime = _initialEndTime
            ..original = _initialOriginalText
            ..edited = _subtitleLine!.edited
            ..marked = _subtitleLine!.marked;
          
          // Call the database function for existing lines asynchronously
          await Future.microtask(() async {
            await saveSubtitleChangesToDatabase(
              _subtitle!.id,
              _subtitleLine!,
              _parseSubtitleTime,
              sessionId: widget.sessionId,
              beforeLine: lineBeforeChanges,
            );
          });
        }

        await Future.microtask(() async {
          await updateLastEditedIndex(widget.sessionId, _subtitleLine!.index);
        });

        // Mark subtitles for regeneration and regenerate for video player after saving changes (async)
        await Future.microtask(() {
          _markSubtitlesForRegeneration();
          _generateSubtitles();
        });

        // Clear validation errors after successful save
        if (mounted) {
          setState(() {
            _startTimeError = null;
            _endTimeError = null;
            _timeOrderError = null;
          });
        }

        return true;
      } catch (e) {
        logError(
          'Failed to save changes',
          error: e,
          context: 'EditSubtitleScreen._saveChanges',
        );
        return false;
      }
    }
    return false;
  }

  // Helper function to parse subtitle time
  DateTime _parseSubtitleTime(String time) {
    // Assuming the time format is "HH:mm:ss,SSS" (e.g., "00:01:23,456")
    List<String> parts = time.split(',');
    List<String> hms = parts[0].split(':');
    int hours = int.parse(hms[0]);
    int minutes = int.parse(hms[1]);
    int seconds = int.parse(hms[2]);
    int milliseconds = int.parse(parts[1]);

    return DateTime(0, 1, 1, hours, minutes, seconds, milliseconds);
  }

  void _generateSecondarySubtitles() {
    setState(() {
      _secondarySubtitlesForPlayer =
          _secondarySubtitles.asMap().entries.map((entry) {
            final index =
                entry.key; // Use array index instead of database index
            final line = entry.value;
            return Subtitle(
              index:
                  index, // This ensures video player uses same indexing as list
              start: parseTimeString(line.startTime),
              end: parseTimeString(line.endTime),
              text: line.text.replaceAll('<br>', '\n'),
              marked: false, // Secondary subtitles don't have marked field
            );
          }).toList();
    });

    // Update video player with new secondary subtitles
    if (_videoPlayerKey.currentState != null) {
      _videoPlayerKey.currentState!.updateSecondarySubtitles(
        _secondarySubtitlesForPlayer,
      );
    }
  }

  void _toggleSecondarySubtitles() {
    // Toggle visibility
    setState(() {
      _showSecondarySubtitles = !_showSecondarySubtitles;
    });

    // Ensure secondary subtitles are loaded from constructor if available but not yet initialized
    if (_showSecondarySubtitles &&
        _secondarySubtitles.isEmpty &&
        widget.secondarySubtitles != null &&
        widget.secondarySubtitles!.isNotEmpty) {
      _secondarySubtitles = widget.secondarySubtitles!;
      _generateSecondarySubtitles();
    }

    // Update video player with secondary subtitles based on visibility
    if (_videoPlayerKey.currentState != null) {
      if (_showSecondarySubtitles && _secondarySubtitlesForPlayer.isNotEmpty) {
        _videoPlayerKey.currentState!.updateSecondarySubtitles(
          _secondarySubtitlesForPlayer,
        );
      } else {
        _videoPlayerKey.currentState!.updateSecondarySubtitles([]);
      }
    }
  }

  // Helper method to build menu item rows with beautiful styling
  Widget _buildMenuItemRow({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // Show edit line menu modal with beautiful styling
  void _showEditLineMenuModal() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 10,
        kToolbarHeight + 10,
        10,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        // Settings
        PopupMenuItem<String>(
          value: 'settings',
          child: _buildMenuItemRow(
            icon: Icons.settings,
            title: 'Settings',
            color: Colors.blue,
          ),
        ),

        // Video options for edit mode
        if (_isEditMode || widget.isNewSubtitle) ...[
          const PopupMenuDivider(),
          if (!_isVideoLoaded)
            PopupMenuItem<String>(
              value: 'loadVideo',
              child: _buildMenuItemRow(
                icon: Icons.video_file,
                title: 'Load Video',
                color: Colors.purple,
              ),
            ),
          if (_isVideoLoaded) ...[
            PopupMenuItem<String>(
              value: 'unloadVideo',
              child: _buildMenuItemRow(
                icon: Icons.video_camera_back,
                title: 'Unload Video',
                color: Colors.deepOrange,
              ),
            ),
          ],
        ],

        // Secondary subtitle options (show if video is loaded)
        if (_isVideoLoaded) ...[
          const PopupMenuDivider(),
          // Load secondary subtitle option
          PopupMenuItem<String>(
            value: 'loadSecondarySubtitle',
            child: _buildMenuItemRow(
              icon: Icons.subtitles,
              title: 'Load Secondary Subtitle',
              color: Colors.teal,
            ),
          ),
          // Toggle secondary subtitle visibility (only if subtitles are loaded)
          if (_secondarySubtitles.isNotEmpty)
            PopupMenuItem<String>(
              value: 'toggleSecondarySubtitle',
              child: _buildMenuItemRow(
                icon:
                    _showSecondarySubtitles
                        ? Icons.visibility
                        : Icons.visibility_off,
                title: _showSecondarySubtitles ? 'Hide Secondary' : 'Show Secondary',
                color: Colors.cyan,
              ),
            ),
        ],

        // Auto resize on keyboard option (show if video is loaded and on mobile platform)
        if (_isVideoLoaded && ResponsiveLayout.isMobilePlatform()) ...[
          if (_secondarySubtitles.isEmpty)
            const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'autoResizeOnKeyboard',
            child: _buildMenuItemRow(
              icon:
                  _autoResizeOnKeyboard
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
              title: 'Resize Player on Keyboard',
              color: Colors.green,
            ),
          ),
        ],

        // Translation mode specific options
        if (!_isEditMode) ...[
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'showOriginal',
            child: _buildMenuItemRow(
              icon:
                  _showOriginalLine
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
              title: 'Show Original Line',
              color: Colors.orange,
            ),
          ),

          // Auto-save option (only when Show Original Line is enabled)
          if (_showOriginalLine)
            PopupMenuItem<String>(
              value: 'autoSave',
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: _buildMenuItemRow(
                  icon:
                      _autoSaveWithNavigation
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                  title: 'Auto-save with navigation',
                  color: Colors.green,
                ),
              ),
            ),
        ],

        // Divider before delete and mark options
        // const PopupMenuDivider(),

        // Show/Hide original text field
        PopupMenuItem<String>(
          value: 'toggleOriginalField',
          child: _buildMenuItemRow(
            icon:
                _showOriginalTextField
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
            title: 'Show Original Text Field',
            color: Colors.blue,
          ),
        ),

        // Formatted view toggle
        PopupMenuItem<String>(
          value: 'toggleFormatted',
          child: _buildMenuItemRow(
            icon:
                isRawEnabled ? Icons.check_box : Icons.check_box_outline_blank,
            title: 'Formatted View',
            color: Colors.green,
          ),
        ),
        const PopupMenuDivider(),

        // Mark/Unmark line
        PopupMenuItem<String>(
          value: 'markLine',
          child: _buildMenuItemRow(
            icon:
                (_subtitleLine?.marked ?? false)
                    ? Icons.bookmark_remove
                    : Icons.bookmark_add,
            title:
                (_subtitleLine?.marked ?? false) ? 'Unmark Line' : 'Mark Line',
            color: (_subtitleLine?.marked ?? false) ? Colors.grey : Colors.red,
          ),
        ),

        // Show marked lines
        PopupMenuItem<String>(
          value: 'showMarkedLines',
          child: _buildMenuItemRow(
            icon: Icons.bookmark,
            title: 'Show in Marked Lines',
            color: Colors.red,
          ),
        ),

        // Edit History
        PopupMenuItem<String>(
          value: 'checkpointHistory',
          child: _buildMenuItemRow(
            icon: Icons.history,
            title: 'Edit History',
            color: Colors.deepPurple,
          ),
        ),

        // Jump to line
        PopupMenuItem<String>(
          value: 'jumpToLine',
          child: _buildMenuItemRow(
            icon: Icons.arrow_upward_rounded,
            title: 'Jump to Line',
            color: Colors.orange,
          ),
        ),

        // Delete subtitle line
        PopupMenuItem<String>(
          value: 'delete',
          child: _buildMenuItemRow(
            icon: Icons.delete,
            title: 'Delete Subtitle Line',
            color: Colors.red,
          ),
        ),

        // Divider before help
        const PopupMenuDivider(),

        // Help & Documentation
        PopupMenuItem<String>(
          value: 'help',
          child: _buildMenuItemRow(
            icon: Icons.help_outline,
            title: 'Help & Documentation',
            color: Colors.purple,
          ),
        ),
      ],
    ).then((value) => _handleEditLineMenuSelection(value));
  }

  // Handle edit line menu selection
  void _handleEditLineMenuSelection(String? value) {
    if (value == null) return;

    switch (value) {
      case 'settings':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          builder:
              (context) => SettingsSheet(
                onSettingsChanged: () {
                  _reloadAllSettings();
                },
              ),
        );
        break;
      case 'loadVideo':
        _pickVideoFile();
        break;
      case 'unloadVideo':
        _unloadVideo();
        break;
      case 'showOriginal':
        _showOriginalLineWarningDialog(!_showOriginalLine);
        break;
      case 'toggleOriginalField':
        _saveShowOriginalTextField(!_showOriginalTextField);
        break;
      case 'toggleFormatted':
        setState(() {
          isRawEnabled = !isRawEnabled;
        });
        break;
      case 'autoSave':
        _saveAutoSaveWithNavigation(!_autoSaveWithNavigation);
        break;
      case 'loadSecondarySubtitle':
        _showSecondarySubtitleModal();
        break;
      case 'toggleSecondarySubtitle':
        _toggleSecondarySubtitles();
        break;
      case 'autoResizeOnKeyboard':
        _saveAutoResizeOnKeyboard(!_autoResizeOnKeyboard);
        break;
      case 'markLine':
        _toggleMarkLine();
        break;
      case 'showMarkedLines':
        _showMarkedLinesModal();
        break;
      case 'checkpointHistory':
        _showCheckpointHistoryModal();
        break;
      case 'jumpToLine':
        _showJumpToLineModal();
        break;
      case 'delete':
        if (_subtitleLine == null) return;

        SubtitleOperations.showDeleteConfirmation(
          context: context,
          subtitleId: widget.subtitleId,
          currentLine: _subtitleLine!,
          collection: _subtitle!,
          onSuccess:
              () => _fetchSubtitleLine(
                widget.subtitleId,
                _subtitleLine!.index - 1,
              ),
          sessionId: widget.sessionId,
        );
        break;
      case 'help':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HelpScreen()),
        );
        break;
    }
  }

  // Toggle mark status of the current subtitle line
  Future<void> _toggleMarkLine() async {
    if (_subtitleLine == null) return;

    final currentMarked = _subtitleLine!.marked;
    final newMarked = !currentMarked;
    final lineIndex = _subtitleLine!.index - 1;

    logInfo(
      'ToggleMarkLine: subtitleId=${widget.subtitleId}, subtitleIndex=${_subtitleLine!.index}, arrayIndex=$lineIndex, newMarked=$newMarked',
      context: 'EditSubtitleScreen._toggleMarkLine',
    );

    try {
      final success = await markSubtitleLine(
        widget.subtitleId,
        lineIndex,
        newMarked,
      );
      if (success) {
        setState(() {
          _subtitleLine!.marked = newMarked;
        });

        // Refresh subtitle collection data and update video player
        _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;
        _markSubtitlesForRegeneration();
        _generateSubtitles();

        // Show success message
        SnackbarHelper.showSuccess(
          context,
          newMarked ? 'Line marked' : 'Line unmarked',
          duration: const Duration(seconds: 1),
        );
      } else {
        SnackbarHelper.showError(context, 'Failed to update mark status - check debug log for details');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Error updating mark status: $e');
    }
  }

  // Show comment dialog for current line
  void _showCommentDialogForCurrentLine() {
    if (_subtitleLine == null) return;
    
    // Check if video player is in fullscreen mode
    final videoPlayerState = _videoPlayerKey.currentState;
    final isInFullscreenMode = videoPlayerState?.isInFullscreenMode() ?? false;
    
    if (isInFullscreenMode) {
      logInfo(
        'Showing comment dialog for fullscreen mode - current line',
        context: 'EditSubtitleScreen._showCommentDialogForCurrentLine',
      );
      
      // In fullscreen mode, find corresponding subtitle and use video player's fullscreen comment dialog
      final currentIndex = _subtitleLine!.index - 1; // Convert to 0-based index
      if (currentIndex >= 0 && currentIndex < _subtitles.length && videoPlayerState != null) {
        final subtitle = _subtitles[currentIndex];
        
        // Create a subtitle with current comment for the fullscreen dialog
        final subtitleWithComment = Subtitle(
          index: subtitle.index,
          start: subtitle.start,
          end: subtitle.end,
          text: subtitle.text,
          comment: _subtitleLine!.comment,
        );
        
        // Use the video player's fullscreen-specific comment dialog
        videoPlayerState.showFullscreenCommentDialog(subtitleWithComment);
        return;
      }
    } else {
      logInfo(
        'Showing comment dialog for normal mode - current line',
        context: 'EditSubtitleScreen._showCommentDialogForCurrentLine',
      );
    }
    
    // Store the current playing state before showing dialog (for normal mode)
    bool wasPlaying = false;
    if (videoPlayerState != null && !isInFullscreenMode) {
      wasPlaying = videoPlayerState.isPlaying();
      logInfo(
        'Comment dialog opening in normal mode - video was ${wasPlaying ? 'playing' : 'paused'}',
        context: 'EditSubtitleScreen._showCommentDialogForCurrentLine',
      );
      
      // Pause video if it was playing when comment dialog opens
      if (wasPlaying) {
        videoPlayerState.pause();
        logInfo(
          'Paused video for comment input in line edit screen',
          context: 'EditSubtitleScreen._showCommentDialogForCurrentLine',
        );
      }
    }
    
    // Flag to track if video has been resumed to prevent double resuming
    bool hasResumed = false;
    
    // Normal mode or fallback - use the standard comment dialog
    CommentDialog.show(
      context,
      existingComment: _subtitleLine!.comment,
      originalText: _subtitleLine!.original,
      editedText: _subtitleLine!.edited,
      subtitleIndex: _subtitleLine!.index,
      onCommentSaved: (comment) async {
        try {
          // Update comment in database  
          final success = await updateSubtitleLineComment(
            widget.subtitleId,
            _subtitleLine!.index - 1,
            comment,
          );
          
          if (success) {
            setState(() {
              _subtitleLine!.comment = comment;
            });
            
            // Refresh subtitle collection data and update video player
            _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;
            _markSubtitlesForRegeneration();
            _generateSubtitles();
            
            final modeText = isInFullscreenMode ? 'fullscreen' : 'normal';
            SnackbarHelper.showSuccess(context, 
              (comment.isNotEmpty) ? 'Comment updated ($modeText mode)' : 'Comment deleted ($modeText mode)');
          } else {
            SnackbarHelper.showError(context, 'Failed to update comment');
          }
          
          // Resume video if it was playing before dialog opened and not already resumed
          if (wasPlaying && videoPlayerState != null && !hasResumed) {
            hasResumed = true;
            videoPlayerState.play();
            logInfo(
              'Resumed video after comment save in line edit screen',
              context: 'EditSubtitleScreen._showCommentDialogForCurrentLine',
            );
          }
        } catch (e) {
          SnackbarHelper.showError(context, 'Failed to update comment: $e');
        }
      },
      onCommentDeleted: () async {
        try {
          // Delete comment from database
          final success = await updateSubtitleLineComment(
            widget.subtitleId,
            _subtitleLine!.index - 1,
            null,
          );
          
          if (success) {
            setState(() {
              _subtitleLine!.comment = null;
            });
            
            // Refresh subtitle collection data and update video player
            _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;
            _markSubtitlesForRegeneration();
            _generateSubtitles();
            
            final modeText = isInFullscreenMode ? 'fullscreen' : 'normal';
            SnackbarHelper.showSuccess(context, 'Comment deleted ($modeText mode)');
          } else {
            SnackbarHelper.showError(context, 'Failed to delete comment');
          }
          
          // Resume video if it was playing before dialog opened and not already resumed
          if (wasPlaying && videoPlayerState != null && !hasResumed) {
            hasResumed = true;
            videoPlayerState.play();
            logInfo(
              'Resumed video after comment delete in line edit screen',
              context: 'EditSubtitleScreen._showCommentDialogForCurrentLine',
            );
          }
        } catch (e) {
          SnackbarHelper.showError(context, 'Failed to delete comment: $e');
        }
      },
    ).then((_) {
      // This executes when the dialog is dismissed (by canceling without save/delete)
      // Resume video if it was playing before dialog opened and we haven't already resumed it
      if (wasPlaying && videoPlayerState != null && !hasResumed) {
        videoPlayerState.play();
        logInfo(
          'Resumed video after comment dialog dismissed in line edit screen',
          context: 'EditSubtitleScreen._showCommentDialogForCurrentLine',
        );
      }
    });
  }

  // Show marked lines modal
  Future<void> _showMarkedLinesModal() async {
    try {
      final markedLines = await getMarkedSubtitleLines(widget.subtitleId);
      
      // Get the current line's database index if it's marked
      int? initialHighlightIndex;
      if (_subtitleLine != null && _subtitleLine!.marked) {
        initialHighlightIndex = _subtitleLine!.index; // Database index (1-based)
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height,
          child: MarkedLinesSheet(
            markedLines: markedLines,
            initialHighlightLineIndex: initialHighlightIndex, // Pass the current line index to highlight
            onLineSelected: (index) {
              // Navigate to the selected line
              _skipToLine(widget.subtitleId, index);
            },
            onCommentUpdated: (index, comment) async {
              // Update comment in database and refresh UI
              try {
                await updateSubtitleLineComment(widget.subtitleId, index, comment);
                // Refresh the subtitle data from database
                _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;
                
                // Update current line if it matches
                if (_subtitleLine != null && _subtitleLine!.index == index + 1) {
                      setState(() {
                        _subtitleLine!.comment = comment;
                      });
                    }
                    
                    // Regenerate subtitles for video player
                    _markSubtitlesForRegeneration();
                    _generateSubtitles();
                    
                    SnackbarHelper.showSuccess(context, 
                      comment != null ? 'Comment updated' : 'Comment deleted');
                  } catch (e) {
                    SnackbarHelper.showError(context, 'Failed to update comment: $e');
                  }
                },
            onResolvedUpdated: (index, resolved) async {
              // Update resolved status in database
              try {
                await updateSubtitleLineResolved(widget.subtitleId, index, resolved);
                // Refresh the subtitle data from database
                _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;
                
                // Update current line if it matches
                if (_subtitleLine != null && _subtitleLine!.index == index + 1) {
                  setState(() {
                    _subtitleLine!.resolved = resolved;
                  });
                }
                
                // Regenerate subtitles for video player
                _markSubtitlesForRegeneration();
                _generateSubtitles();
                
                SnackbarHelper.showSuccess(context, 
                  resolved ? 'Comment marked as resolved' : 'Comment marked as unresolved');
              } catch (e) {
                SnackbarHelper.showError(context, 'Failed to update resolved status: $e');
              }
            },
            onTextEdited: (index, newText) async {
              // Update edited text in database and refresh UI
              try {
                // Get the subtitle line from database
                final subtitle = await isar.subtitleCollections.get(widget.subtitleId);
                if (subtitle != null && index < subtitle.lines.length) {
                  final updatedLine = subtitle.lines[index];
                  updatedLine.edited = newText;
                  
                  // Save to database
                  await saveSubtitleChangesToDatabase(
                    widget.subtitleId,
                    updatedLine,
                    _parseSubtitleTime,
                    sessionId: widget.sessionId,
                  );
                  
                  // Refresh the subtitle data from database
                  _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;
                  
                  // Update current line if it matches
                  if (_subtitleLine != null && _subtitleLine!.index == index + 1) {
                    setState(() {
                      _subtitleLine!.edited = newText;
                    });
                  }
                  
                  // Regenerate subtitles for video player
                  _markSubtitlesForRegeneration();
                  _generateSubtitles();
                  
                  SnackbarHelper.showSuccess(context, 'Subtitle text updated');
                }
              } catch (e) {
                SnackbarHelper.showError(context, 'Failed to update subtitle text: $e');
              }
            },
              ),
        ),
      );
    } catch (e) {
      SnackbarHelper.showError(context, 'Error loading marked lines: $e');
    }
  }

  // Show Edit History modal (responsive dialog)
  void _showCheckpointHistoryModal() {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    
    if (isLargeScreen) {
      // Show as dialog on large screens
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 800,
              maxHeight: 700,
            ),
            child: CheckpointSheet(
              sessionId: widget.sessionId,
              subtitleCollectionId: widget.subtitleId,
              onCheckpointRestored: () async {
                // Reload subtitle data after checkpoint restoration
                _subtitle = await isar.subtitleCollections.get(widget.subtitleId);
                
                if (_subtitle != null && _subtitleLine != null) {
                  // Re-fetch the current subtitle line to get updated data
                  final currentIndex = _subtitleLine!.index - 1;
                  if (currentIndex >= 0 && currentIndex < _subtitle!.lines.length) {
                    setState(() {
                      _subtitleLine = _subtitle!.lines[currentIndex];
                      _originalController.text = _subtitleLine!.original;
                      _editedController.text = _subtitleLine!.edited ?? '';
                      _startTimeController.text = _subtitleLine!.startTime;
                      _endTimeController.text = _subtitleLine!.endTime;
                    });
                    
                    // Regenerate subtitles for video player
                    _markSubtitlesForRegeneration();
                    _generateSubtitles();
                  }
                }
              },
            ),
          ),
        ),
      );
    } else {
      // Show fullscreen on mobile
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => CheckpointSheet(
            sessionId: widget.sessionId,
            subtitleCollectionId: widget.subtitleId,
            onCheckpointRestored: () async {
              // Reload subtitle data after checkpoint restoration
              _subtitle = await isar.subtitleCollections.get(widget.subtitleId);
              
              if (_subtitle != null && _subtitleLine != null) {
                // Re-fetch the current subtitle line to get updated data
                final currentIndex = _subtitleLine!.index - 1;
                if (currentIndex >= 0 && currentIndex < _subtitle!.lines.length) {
                  setState(() {
                    _subtitleLine = _subtitle!.lines[currentIndex];
                    _originalController.text = _subtitleLine!.original;
                    _editedController.text = _subtitleLine!.edited ?? '';
                    _startTimeController.text = _subtitleLine!.startTime;
                    _endTimeController.text = _subtitleLine!.endTime;
                  });
                  
                  // Regenerate subtitles for video player
                  _markSubtitlesForRegeneration();
                  _generateSubtitles();
                }
              }
            },
          ),
        ),
      );
    }
  }

  // Show jump to line modal
  Future<void> _showJumpToLineModal() async {
    if (_subtitle?.lines == null || _subtitle!.lines.isEmpty) {
      SnackbarHelper.showError(context, 'No subtitle lines available');
      return;
    }

    final totalLines = _subtitle!.lines.length;
    final currentLine = _subtitleLine?.index.toString() ?? '1';

    showGotToLineModal(
      context: context,
      initialValue: currentLine,
      hintText: totalLines,
      title: 'Jump to Line',
      onSubmitted: (value) {
        final lineNumber = int.tryParse(value);
        if (lineNumber != null && lineNumber >= 1 && lineNumber <= totalLines) {
          // Convert 1-based line number to 0-based index for _skipToLine
          _skipToLine(widget.subtitleId, lineNumber - 1);
        }
      },
    );
  }

  // Show Olam Dictionary modal
  void _showOlamDictionary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        // Get selected text or use full text as fallback
        String searchText = _originalController.text;
        if (_originalController.selection.isValid &&
            _originalController.selection.start !=
                _originalController.selection.end) {
          searchText = _originalController.text.substring(
            _originalController.selection.start,
            _originalController.selection.end,
          );
        }

        return OlamDictionaryWidget(
          onSelectTranslation: (text) {
            // Insert selected text into edited field
            _editedController.text = text;
            Navigator.pop(context);
          },
          initialSearchTerm: searchText,
        );
      },
    );
  }

  // Show Urban Dictionary modal
  void _showUrbanDictionary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        // Get selected text or use full text as fallback
        String searchText = _originalController.text;
        if (_originalController.selection.isValid &&
            _originalController.selection.start !=
                _originalController.selection.end) {
          searchText = _originalController.text.substring(
            _originalController.selection.start,
            _originalController.selection.end,
          );
        }

        return UrbanDictionaryWidget(
          onSelectTranslation: (text) {
            // Insert selected text into edited field
            _editedController.text = text;
            Navigator.pop(context);
          },
          initialSearchTerm: searchText,
        );
      },
    );
  }

  // Show MSone Dictionary modal
  void _showMsoneDictionary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        // Get selected text or use full text as fallback
        String searchText = _originalController.text;
        if (_originalController.selection.isValid &&
            _originalController.selection.start !=
                _originalController.selection.end) {
          searchText = _originalController.text.substring(
            _originalController.selection.start,
            _originalController.selection.end,
          );
        }

        return FractionallySizedBox(
          heightFactor: 0.95, // 95% of screen height
          child: DictionarySearchWidget(
            onSelectTranslation: (text) {
              // Insert selected text into edited field
              _editedController.text = text;
              Navigator.pop(context);
            },
            initialSearchTerm: searchText,
          ),
        );
      },
    );
  }

  // Show Secondary Subtitle modal
  Future<void> _showSecondarySubtitleModal() async {
    if (!mounted) return;

    // Get the current subtitle lines
    List<SubtitleLine> originalSubtitles = [];
    if (_subtitle?.lines != null) {
      originalSubtitles = _subtitle!.lines;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      builder: (context) {
        return SecondarySubtitleSheet(
          originalSubtitles: originalSubtitles,
          subtitleCollectionId: widget.subtitleId,
          videoPlayerState: _videoPlayerKey.currentState,
          onSecondarySubtitlesLoaded: (secondarySubtitles) {
            setState(() {
              _secondarySubtitles = secondarySubtitles;
              _showSecondarySubtitles = true;
              _generateSecondarySubtitles();
            });
            if (mounted) {
              SnackbarHelper.showSuccess(context, 'Secondary subtitles loaded');
            }
          },
        );
      },
    );
  }

  // Show AI Explanation - triggers the AI explanation feature
  Future<void> _showAiExplanation() async {
    // Get current text to explain
    final currentText = _editedController.text.isEmpty 
        ? _originalController.text 
        : _editedController.text;

    // Get context lines (current mode - original or edited based on _isEditMode)
    final previousLines = <String>[];
    if (_subtitleLine != null && _subtitle != null) {
      final currentIndex = _subtitleLine!.index - 1;
      for (int i = currentIndex - 1; i >= 0 && i >= currentIndex - 3; i--) {
        final line = _subtitle!.lines[i];
        final text = _isEditMode 
            ? (line.edited?.isNotEmpty == true ? line.edited! : line.original)
            : line.original;
        previousLines.insert(0, text);
      }
    }
    
    final nextLines = <String>[];
    if (_subtitleLine != null && _subtitle != null) {
      final currentIndex = _subtitleLine!.index - 1;
      for (int i = currentIndex + 1; i < _subtitle!.lines.length && i <= currentIndex + 3; i++) {
        final line = _subtitle!.lines[i];
        final text = _isEditMode 
            ? (line.edited?.isNotEmpty == true ? line.edited! : line.original)
            : line.original;
        nextLines.add(text);
      }
    }

    // Get all lines for context adjustment (current mode)
    final allLines = <String>[];
    if (_subtitle != null) {
      for (final line in _subtitle!.lines) {
        final text = _isEditMode 
            ? (line.edited?.isNotEmpty == true ? line.edited! : line.original)
            : line.original;
        allLines.add(text);
      }
    }

    // Get original lines for context selector
    final originalAllLines = <String>[];
    if (_subtitle != null) {
      for (final line in _subtitle!.lines) {
        originalAllLines.add(line.original);
      }
    }

    // Get edited lines for context selector
    final editedAllLines = <String>[];
    if (_subtitle != null) {
      for (final line in _subtitle!.lines) {
        final text = line.edited?.isNotEmpty == true ? line.edited! : line.original;
        editedAllLines.add(text);
      }
    }

    // Use the AI Explanation Sheet widget
    if (!mounted) return;
    AiExplanationSheet.show(
      context: context,
      aiExplanationCubit: _aiExplanationCubit,
      currentText: currentText,
      previousLines: previousLines,
      nextLines: nextLines,
      allLines: allLines,
      currentIndex: _subtitleLine?.index != null ? _subtitleLine!.index - 1 : 0,
      originalAllLines: originalAllLines,
      editedAllLines: editedAllLines,
    );
  }

  // Handle mark/unmark from video player fullscreen controls
  Future<void> _handleVideoPlayerMarkToggle(
    int subtitleIndex,
    bool isMarked,
  ) async {
    logInfo(
      'HandleVideoPlayerMarkToggle: subtitleIndex=$subtitleIndex (0-based array index), isMarked=$isMarked',
      context: 'EditSubtitleScreen._handleVideoPlayerMarkToggle',
    );
    
    try {
      final success = await markSubtitleLine(
        widget.subtitleId,
        subtitleIndex, // subtitleIndex is already 0-based array index
        isMarked,
      );
      if (success) {
        // Update the current subtitle line if it matches
        // Note: _subtitleLine.index is 1-based, so we need to check subtitleIndex + 1
        if (_subtitleLine != null && _subtitleLine!.index == subtitleIndex + 1) {
          setState(() {
            _subtitleLine!.marked = isMarked;
          });
        }

        // Refresh subtitle collection data from database to ensure all data is current
        _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;

        // Update the subtitles list for video player
        _markSubtitlesForRegeneration();
        _generateSubtitles();

        // Show success message
        SnackbarHelper.showSuccess(
          context,
          isMarked ? 'Line marked' : 'Line unmarked',
          duration: const Duration(seconds: 1),
        );
      } else {
        SnackbarHelper.showError(context, 'Failed to update mark status - check debug log for details');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Error updating mark status: $e');
    }
  }

  List<String> _getEditInstructions() {
    return [
      'Use the text field to edit the subtitle line.',
      'Tap the "Edit Time" button to edit timing (start/end times) for the subtitle.',
      'Navigate between subtitle lines using the arrow buttons or the line number input.',
      'The changes will be saved automatically while navigating, or you can save manually using the save button.',
      'Enable "Auto-Save to File" in the settings to save changes directly to the file.',
      'Use the formatting menu to apply text styles like bold, italic and color.',
      'The palette icon opens the color picker for text formatting.',
    ];
  }

  Widget _buildResponsiveContent(bool shouldShowVideo, Column originalContent) {
    if (ResponsiveLayout.shouldUseDesktopLayout(context)) {
      // Don't build the ResizableSplitView until the resize ratio is loaded
      if (!_isResizeRatioLoaded) {
        logInfo(
          'Waiting for resize ratio to load...',
          context: 'EditSubtitleScreen._buildResponsiveContent',
        );
        // Return a temporary layout while loading
        return Row(
          children: [
            Expanded(
              flex: 35, // Default 35% while loading
              child: _buildEditingInterfaceWithoutVideo(originalContent),
            ),
            Expanded(
              flex: 65, // Default 65% while loading
              child:
                  shouldShowVideo && _selectedVideoPath != null
                      ? Container(
                        margin: const EdgeInsets.all(16),
                        child: VideoPlayerWidget(
                          key: _videoPlayerKey,
                          videoPath: _selectedVideoPath!,
                          subtitleCollectionId: widget.subtitleId,
                          subtitles: _subtitles,
                          secondarySubtitles:
                              _showSecondarySubtitles
                                  ? _secondarySubtitlesForPlayer
                                  : [],
                          onSubtitleCommentUpdated: (subtitleIndex, comment) async {
                            // Update comment in database and refresh UI
                            try {
                              await updateSubtitleLineComment(widget.subtitleId, subtitleIndex, comment);
                              // Refresh the subtitle data from database
                              _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;
                              
                              // Update current line if it matches
                              if (_subtitleLine != null && _subtitleLine!.index == subtitleIndex + 1) {
                                setState(() {
                                  _subtitleLine!.comment = comment;
                                });
                              }
                              
                              // Regenerate subtitles for video player
                              _markSubtitlesForRegeneration();
                              _generateSubtitles();
                              
                              SnackbarHelper.showSuccess(context, 
                                comment != null ? 'Comment updated' : 'Comment deleted');
                            } catch (e) {
                              SnackbarHelper.showError(context, 'Failed to update comment: $e');
                            }
                          },
                        ),
                      )
                      : Container(),
            ),
          ],
        );
      }

      // Only log ratio changes when they're significant to reduce debug noise
      if (_lastLoggedRatio == null ||
          (_resizeRatio - _lastLoggedRatio!).abs() > 0.01) {
        logInfo(
          'Creating ResizableSplitView with initialRatio: $_resizeRatio, loaded: $_isResizeRatioLoaded',
          context: 'EditSubtitleScreen._buildResponsiveContent',
        );
        _lastLoggedRatio = _resizeRatio;
      }

      // Desktop layout: resizable editing interface and video player side by side
      // Apply layout switching based on preference (layout1/layout2)
      final videoContent = shouldShowVideo && _selectedVideoPath != null
          ? _buildVideoPlayerWidget()
          : _buildNoVideoPlaceholder();

      final editingContent = _buildEditingInterfaceWithoutVideo(originalContent);

      // Determine left and right children based on layout preference
      final leftChild = _layoutPreference == 'layout2' ? videoContent : editingContent;
      final rightChild = _layoutPreference == 'layout2' ? editingContent : videoContent;

      return ResizableSplitView(
        initialRatio: _resizeRatio,
        minRatio: 0.2,
        maxRatio: 0.8,
        dividerThickness: 6.0, // Increased from default 4.0 for better touch interaction
        onRatioChanged: (ratio) {
          // Only log every 10th ratio change to reduce noise
          if ((ratio * 1000).round() % 10 == 0) {
            logInfo(
              'ResizableSplitView onRatioChanged: $ratio',
              context: 'EditSubtitleScreen._buildResponsiveContent',
            );
          }
          _saveResizeRatio(ratio);
        },
        leftChild: leftChild,
        rightChild: rightChild,
      );
    } else {
      // Mobile layout: vertical layout with resizable video
      // Don't build until mobile resize ratio is loaded
      if (!_isMobileResizeRatioLoaded) {
        logInfo(
          'Waiting for mobile resize ratio to load...',
          context: 'EditSubtitleScreen.build',
        );
        // Return a temporary layout while loading
        return originalContent;
      }

      // Removed excessive logging that was causing performance issues during keyboard animations
      // logInfo(
      //   'Creating mobile ResizableSplitView with mobileRatio: $_mobileVideoResizeRatio, loaded: $_isMobileResizeRatioLoaded',
      //   context: 'EditSubtitleScreen.build',
      // );

      // Mobile layout with vertical ResizableSplitView - only if auto-resize is enabled and video is visible
      return ResponsiveLayout.shouldUseMobileLayout(context) && _autoResizeOnKeyboard && shouldShowVideo
        ? ResizableSplitView(
            initialRatio: _mobileVideoResizeRatio,
            minRatio: 0.2,
            maxRatio: 0.8,
            vertical: true, // Vertical split for mobile
            dividerThickness: 6.0, // Increased for mobile touch interaction
            onRatioChanged: (ratio) {
              logInfo(
                'Mobile ResizableSplitView onRatioChanged: $ratio',
                context: 'EditSubtitleScreen.build',
              );
              // Only save the ratio, don't trigger setState to avoid build loops
              _mobileVideoResizeRatio = ratio;
              _saveMobileResizeRatio(ratio);
            },
            leftChild: shouldShowVideo && _selectedVideoPath != null
              ? LayoutBuilder(
                  key: const Key('video_player_layout_builder'),
                  builder: (context, constraints) {
                    return VideoPlayerWidget(
                      key: _videoPlayerKey,
                      videoPath: _selectedVideoPath!,
                      subtitleCollectionId: widget.subtitleId,
                      subtitles: _subtitles,
                      secondarySubtitles: _showSecondarySubtitles ? _secondarySubtitlesForPlayer : [],
                      onSubtitlesUpdated: () {
                        // Debounce subtitle updates to prevent excessive rebuilds
                        _subtitleUpdateTimer?.cancel();
                        _subtitleUpdateTimer = Timer(const Duration(milliseconds: 100), () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _markSubtitlesForRegeneration();
                                _generateSubtitles();
                              });
                            }
                          });
                        });
                      },
                      onSubtitleMarked: (subtitleIndex, isMarked) async {
                        await _handleVideoPlayerMarkToggle(subtitleIndex, isMarked);
                      },
                      onSubtitleCommentUpdated: (subtitleIndex, comment) async {
                        // Update comment in database and refresh UI
                        try {
                          await updateSubtitleLineComment(widget.subtitleId, subtitleIndex, comment);
                          // Refresh the subtitle data from database
                          _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;
                          
                          // Update current line if it matches
                          if (_subtitleLine != null && _subtitleLine!.index == subtitleIndex + 1) {
                            setState(() {
                              _subtitleLine!.comment = comment;
                            });
                          }
                          
                          // Regenerate subtitles for video player
                          _markSubtitlesForRegeneration();
                          _generateSubtitles();
                          
                          SnackbarHelper.showSuccess(context, 
                            comment != null ? 'Comment updated' : 'Comment deleted');
                        } catch (e) {
                          SnackbarHelper.showError(context, 'Failed to update comment: $e');
                        }
                      },
                      onPlayStateChanged: (isPlaying) {
                        // Only update if the state actually changed to avoid unnecessary rebuilds
                        if (mounted && _isVideoPlaying != isPlaying) {
                          setState(() {
                            _isVideoPlaying = isPlaying;
                          });
                        }
                      },
                      onRepeatModeToggled: (isEnabled) {
                        if (isEnabled != _isRepeatModeEnabled) {
                          _toggleRepeatMode();
                        }
                      },
                      isRepeatModeEnabled: _isRepeatModeEnabled,
                    );
                  },
                )
              : Container(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_outlined,
                          size: 60,
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No video loaded',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _pickVideoFile,
                          icon: const Icon(Icons.video_file),
                          label: const Text('Load Video'),
                        ),
                      ],
                    ),
                  ),
                ),
            rightChild: _buildEditingInterfaceWithoutVideo(originalContent),
          )
        : // Fallback to original content for mobile when auto-resize is disabled or no video is visible
          ResponsiveLayout.shouldUseMobileLayout(context) && !shouldShowVideo
            ? _buildMobileContentWithoutVideo(originalContent) // Show mobile layout without video section
            : originalContent; // Original content with video section (for desktop or when video is visible)
    }
  }

  Widget _buildEditingInterfaceWithoutVideo(Column originalContent) {
    // Create a modified version of the original content without the video player
    final children = originalContent.children;
    final modifiedChildren = <Widget>[];

    for (final child in children) {
      // Skip the video player widget (SizedBox with height 240 containing VideoPlayerWidget)
      if (child is SizedBox && child.height == 240) {
        continue; // Skip video player
      }
      // Skip the spacing after video player
      else if (modifiedChildren.isNotEmpty &&
          modifiedChildren.last is SizedBox &&
          child is SizedBox &&
          child.height == 1) {
        continue; // Skip spacing after video
      } else {
        modifiedChildren.add(child);
      }
    }

    return Column(children: modifiedChildren);
  }

  /// Build video player widget with consistent configuration
  Widget _buildVideoPlayerWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: VideoPlayerWidget(
        key: _videoPlayerKey,
        videoPath: _selectedVideoPath!,
        subtitleCollectionId: widget.subtitleId,
        subtitles: _subtitles,
        secondarySubtitles:
            _showSecondarySubtitles
                ? _secondarySubtitlesForPlayer
                : [],
        onSubtitlesUpdated: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _markSubtitlesForRegeneration();
                _generateSubtitles();
              });
            }
          });
        },
        onSubtitleMarked: (subtitleIndex, isMarked) async {
          // Handle marking/unmarking from video player
          await _handleVideoPlayerMarkToggle(
            subtitleIndex,
            isMarked,
          );
        },
        onSubtitleCommentUpdated: (subtitleIndex, comment) async {
          // Update comment in database and refresh UI
          try {
            await updateSubtitleLineComment(widget.subtitleId, subtitleIndex, comment);
            // Refresh the subtitle data from database
            _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;
            
            // Update current line if it matches
            if (_subtitleLine != null && _subtitleLine!.index == subtitleIndex + 1) {
              setState(() {
                _subtitleLine!.comment = comment;
              });
            }
            
            // Regenerate subtitles for video player
            _markSubtitlesForRegeneration();
            _generateSubtitles();
            
            SnackbarHelper.showSuccess(context, 
              comment != null ? 'Comment updated' : 'Comment deleted');
          } catch (e) {
            SnackbarHelper.showError(context, 'Failed to update comment: $e');
          }
        },
        onPlayStateChanged: (isPlaying) {
          // Update play/pause button state when video player state changes
          if (mounted) {
            setState(() {
              _isVideoPlaying = isPlaying;
            });
          }
        },
        onRepeatModeToggled: (isEnabled) {
          // Handle repeat mode toggle from video player
          if (isEnabled != _isRepeatModeEnabled) {
            _toggleRepeatMode();
          }
        },
        isRepeatModeEnabled: _isRepeatModeEnabled,
      ),
    );
  }

  /// Build placeholder for when no video is loaded
  Widget _buildNoVideoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No video loaded',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickVideoFile,
            icon: const Icon(Icons.video_file),
            label: const Text('Load Video'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContentWithoutVideo(Column originalContent) {
    // For mobile devices when no video is loaded, show just the editing interface 
    // without the video player section to provide full screen space for editing
    final children = originalContent.children;
    final modifiedChildren = <Widget>[];

    for (final child in children) {
      // Skip the video player widget (SizedBox with height 240 containing VideoPlayerWidget)
      if (child is SizedBox && child.height == 240) {
        continue; // Skip video player section
      }
      // Skip the spacing after video player
      else if (modifiedChildren.isNotEmpty &&
          modifiedChildren.last is SizedBox &&
          child is SizedBox &&
          child.height == 1) {
        continue; // Skip spacing after video
      } else {
        modifiedChildren.add(child);
      }
    }

    return Column(children: modifiedChildren);
  }

  // Keyboard shortcut handlers
  void _handlePlayPauseShortcut() {
    if (_isVideoLoaded && _videoPlayerKey.currentState != null) {
      // Get current play state and toggle it
      final isPlaying = _videoPlayerKey.currentState!.isPlaying();
      if (isPlaying) {
        _videoPlayerKey.currentState!.pause();
      } else {
        _videoPlayerKey.currentState!.play();
      }
    }
  }

  void _handleNextLineShortcut() {
    // If video is loaded and in fullscreen mode, use video skip function
    if (_isVideoLoaded && _videoPlayerKey.currentState != null) {
      final videoPlayer = _videoPlayerKey.currentState!;
      if (videoPlayer.isInFullscreenMode()) {
        logInfo(
          'Ctrl+. pressed in fullscreen mode - using video skip to next subtitle',
          context: 'EditSubtitleScreen._handleNextLineShortcut',
        );
        videoPlayer.seekToNextSubtitle();
        return;
      }
    }
    
    // Otherwise, use normal subtitle line navigation
    logInfo(
      'Ctrl+. pressed - using normal line navigation',
      context: 'EditSubtitleScreen._handleNextLineShortcut',
    );
    if (_subtitleLine != null) {
      _nextSubtitle(widget.subtitleId, _subtitleLine!.index + 1);
    }
  }

  void _handlePreviousLineShortcut() {
    // If video is loaded and in fullscreen mode, use video skip function
    if (_isVideoLoaded && _videoPlayerKey.currentState != null) {
      final videoPlayer = _videoPlayerKey.currentState!;
      if (videoPlayer.isInFullscreenMode()) {
        logInfo(
          'Ctrl+, pressed in fullscreen mode - using video skip to previous subtitle',
          context: 'EditSubtitleScreen._handlePreviousLineShortcut',
        );
        videoPlayer.seekToPreviousSubtitle();
        return;
      }
    }
    
    // Otherwise, use normal subtitle line navigation
    logInfo(
      'Ctrl+, pressed - using normal line navigation',
      context: 'EditSubtitleScreen._handlePreviousLineShortcut',
    );
    if (_subtitleLine != null && _subtitleLine!.index > 1) {
      _prevSubtitle(widget.subtitleId, _subtitleLine!.index - 1);
    }
  }

  void _handleTextFormattingShortcut(hotkey.TextFormattingType type) {
    // Use the existing FormattingMenu's _toggleFormatting method logic
    String tag;
    switch (type) {
      case hotkey.TextFormattingType.bold:
        tag = 'b';
        break;
      case hotkey.TextFormattingType.italic:
        tag = 'i';
        break;
      case hotkey.TextFormattingType.underline:
        tag = 'u';
        break;
    }

    // Use the same logic as FormattingMenu's _toggleFormatting
    _toggleFormattingForShortcut(tag, _editedController);

    // Update character counts
    _instantCharacterCountUpdate();
  }

  void _toggleFormattingForShortcut(
    String tag,
    TextEditingController controller,
  ) {
    // This is the same logic from FormattingMenu._toggleFormatting
    if (controller.text.isEmpty || !controller.selection.isValid) {
      return;
    }

    final originalText = controller.text;
    final selection = controller.selection;
    final selectedText = selection.textInside(originalText);

    if (selectedText.isNotEmpty) {
      final start = selection.start;
      final end = selection.end;

      // Preserve leading and trailing white spaces
      final leadingSpaces =
          selectedText.length > selectedText.trimLeft().length
              ? selectedText.substring(
                0,
                selectedText.indexOf(selectedText.trimLeft()),
              )
              : '';
      final trailingSpaces =
          selectedText.length > selectedText.trimRight().length
              ? selectedText.substring(
                selectedText.lastIndexOf(selectedText.trimRight()) +
                    selectedText.trimRight().length,
              )
              : '';

      final trimmedText = selectedText.trim();

      if (trimmedText.startsWith("<$tag>") && trimmedText.endsWith("</$tag>")) {
        // Remove tags and restore white spaces
        final unwrappedText = trimmedText.substring(
          tag.length + 2,
          trimmedText.length - (tag.length + 3),
        );
        controller.text = originalText.replaceRange(
          start,
          end,
          "$leadingSpaces$unwrappedText$trailingSpaces",
        );
        controller.selection = TextSelection.collapsed(
          offset: start + unwrappedText.length + leadingSpaces.length,
        );
      } else {
        // Add tags and preserve white spaces
        final wrappedText = "<$tag>$trimmedText</$tag>";
        controller.text = originalText.replaceRange(
          start,
          end,
          "$leadingSpaces$wrappedText$trailingSpaces",
        );
        controller.selection = TextSelection.collapsed(
          offset: start + wrappedText.length + leadingSpaces.length,
        );
      }
    }
  }

  void _handleSaveShortcut() async {
    // Use the same save function as the save button
    await _updateSubtitle(context);
    // The _updateSubtitle function already shows appropriate feedback
  }

  void _handleDeleteCurrentShortcut() {
    // Use the existing delete functionality directly (same as menu option)
    if (_subtitleLine == null) return;

    SubtitleOperations.showDeleteConfirmation(
      context: context,
      subtitleId: widget.subtitleId,
      currentLine: _subtitleLine!,
      collection: _subtitle!,
      onSuccess:
          () => _fetchSubtitleLine(widget.subtitleId, _subtitleLine!.index - 1),
      sessionId: widget.sessionId,
    );
  }

  void _handleColorPickerShortcut() {
    // Open the ColorPickerWithTextEditing as a bottom sheet using the same pattern as FormattingMenu
    final colorPickerKey = GlobalKey<ColorPickerWithTextEditingState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'Text Color Editor',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
            elevation: 1,
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 80, // Space for floating button
            ),
            child: ColorPickerWithTextEditing(
              key: colorPickerKey,
              controller: _editedController,
              initialSelection: _editedController.selection,
              initialColor: Colors.white,
              colorHistory: _colorHistory,
              showApplyButton: false, // Hide the apply button from the widget
            ),
          ),
          floatingActionButton: Container(
            width: MediaQuery.of(context).size.width - 32,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: FloatingActionButton.extended(
              onPressed: () {
                // Apply the color changes
                colorPickerKey.currentState?.applyChanges();
                _saveColorHistory();
                Navigator.of(context).pop(true);
              },
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              label: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Apply Color",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  void _handleMarkLineShortcut() {
    // Use the existing mark/unmark functionality
    _toggleMarkLine();
  }

  void _handleMarkLineAndCommentShortcut() {
    // If line is not marked, mark it first, then show comment dialog
    // If line is already marked, just show comment dialog
    if (_subtitleLine != null) {
      if (!_subtitleLine!.marked) {
        // Mark the line first, then show comment dialog
        _toggleMarkLine().then((_) {
          // Wait a bit for the mark operation to complete, then show comment dialog
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _showCommentDialogForCurrentLine();
            }
          });
        });
      } else {
        // Line is already marked, just show comment dialog
        _showCommentDialogForCurrentLine();
      }
    }
  }

  void _handleJumpToLineShortcut() {
    // Use the same logic as the menu item - call _showJumpToLineModal()
    _showJumpToLineModal();
  }

  void _handleHelpShortcut() {
    // Navigate to help screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpScreen()),
    );
  }

  void _handleSettingsShortcut() {
    // Show settings sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder:
          (context) => SettingsSheet(
            onSettingsChanged: () {
              _reloadAllSettings();
            },
          ),
    );
  }

  void _handlePopScreenShortcut() async {
    // Use the same logic as the back button - check for unsaved changes
    if (_hasUnsavedChanges()) {
      final shouldPop = await _showUnsavedChangesDialog();
      if (shouldPop) {
        // Return the current active index (convert from 1-based to 0-based)
        final currentIndex = _subtitleLine != null ? _subtitleLine!.index - 1 : widget.index;
        Navigator.of(context).pop(currentIndex);
      }
    } else {
      // Return the current active index (convert from 1-based to 0-based)
      final currentIndex = _subtitleLine != null ? _subtitleLine!.index - 1 : widget.index;
      Navigator.of(context).pop(currentIndex);
    }
  }

  void _handleToggleRepeatShortcut() {
    // Toggle repeat mode
    _toggleRepeatMode();
  }

  void _handleToggleRepeatRangeShortcut() {
    // For now, set a simple range around current subtitle (current ± 2)
    if (_subtitleLine != null && _subtitle != null) {
      final currentIndex = (_subtitleLine!.index - 1); // Convert to 0-based
      final maxIndex = _subtitle!.lines.length - 1;

      final startIndex = (currentIndex - 2).clamp(0, maxIndex);
      final endIndex = (currentIndex + 2).clamp(0, maxIndex);

      // Enable repeat mode if not already enabled
      if (!_isRepeatModeEnabled) {
        _toggleRepeatMode();
      }

      // Set custom range
      setCustomRepeatRange(startIndex, endIndex);
    }
  }

  void _handleToggleFullscreenShortcut() {
    // Toggle fullscreen if video is loaded
    if (_isVideoLoaded && _videoPlayerKey.currentState != null) {
      _videoPlayerKey.currentState!.toggleCustomFullscreen();
    }
  }

  // Split line shortcut handler
  void _handleSplitLineShortcut() {
    // Use the existing split functionality from SubtitleOperations
    if (_subtitleLine != null && _subtitle != null) {
      SubtitleOperations.handleSplitButton(
        context: context,
        editedController: _editedController,
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        subtitleId: widget.subtitleId,
        currentLine: _subtitleLine!,
        refreshCallback:
            () => _fetchSubtitleLine(widget.subtitleId, _subtitleLine!.index),
        sessionId: widget.sessionId,
      );
    }
  }

  // Merge line shortcut handler
  void _handleMergeLineShortcut() {
    logInfo(
      '_handleMergeLineShortcut called',
      context: 'EditSubtitleScreen._handleMergeLineShortcut',
    );
    // Use the existing merge functionality from SubtitleOperations
    if (_subtitleLine != null && _subtitle != null) {
      logInfo(
        'Showing merge confirmation dialog',
        context: 'EditSubtitleScreen._handleMergeLineShortcut',
      );
      SubtitleOperations.showMergeConfirmation(
        context: context,
        currentLine: _subtitleLine!,
        collection: _subtitle!,
        subtitleId: widget.subtitleId,
        refreshCallback: (newLineIndex) =>
            _fetchSubtitleLine(widget.subtitleId, newLineIndex - 1),
        sessionId: widget.sessionId,
      );
    } else {
      logWarning(
        'Cannot merge - _subtitleLine: ${_subtitleLine != null}, _subtitle: ${_subtitle != null}',
        context: 'EditSubtitleScreen._handleMergeLineShortcut',
      );
    }
  }

  // Paste original shortcut handler
  void _handlePasteOriginalShortcut() {
    // Only allow in translation mode (not edit mode)
    if (!_isEditMode && mounted) {
      setState(() {
        _editedController.text = _originalController.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL PERFORMANCE FIX: Do NOT read MediaQuery.viewInsets in build method!
    // Reading viewInsets causes rebuilds on every keyboard animation frame (60fps)
    // Instead, we listen to keyboard state in FocusNode listeners
    // The _isKeyboardVisible state is updated via FocusNode, not MediaQuery
    
    // Force video to always show to eliminate keyboard-related UI changes
    final shouldShowVideo = _isVideoVisible && _selectedVideoPath != null;

    return FirstTimeInstructions(
      screenName: 'edit_line',
      instructions: _getEditInstructions(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          // Check for unsaved changes
          if (_hasUnsavedChanges()) {
            await _showUnsavedChangesDialog();
          } else {
            // Return the current active index (convert from 1-based to 0-based)
            final currentIndex = _subtitleLine != null ? _subtitleLine!.index - 1 : widget.index;
            Navigator.of(context).pop(currentIndex);
          }
        },
        child: Builder(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () async {
                    // Check for unsaved changes
                    if (_hasUnsavedChanges()) {
                      await _showUnsavedChangesDialog();
                      // Note: _showUnsavedChangesDialog handles navigation internally
                    } else {
                      // Return the current active index (convert from 1-based to 0-based)
                      final currentIndex = _subtitleLine != null ? _subtitleLine!.index - 1 : widget.index;
                      Navigator.of(context).pop(currentIndex);
                    }
                  },
                ),
                title: Row(
                  children: [
                    Expanded(
                      child:
                          _subtitle != null
                              ? ScrollingTitleWidget(
                                title: _subtitle!.fileName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.4,
                              )
                              : const Text(
                                "Subtitle Studio",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                    // Mark indicator for current subtitle line
                    if (_subtitleLine?.marked == true)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: Listener(
                          onPointerDown: (PointerDownEvent event) {
                            // Handle right-click on desktop platforms
                            if (event.kind == PointerDeviceKind.mouse && 
                                event.buttons == kSecondaryMouseButton) {
                              _showCommentDialogForCurrentLine();
                            }
                          },
                          child: GestureDetector(
                            onLongPress: () {
                              // Handle long press on touch devices
                              _showCommentDialogForCurrentLine();
                            },
                            onTap: () {
                              // Optional: quick toggle mark status on tap
                              _toggleMarkLine();
                            },
                            child: const Icon(
                              Icons.bookmark_added,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                iconTheme: const IconThemeData(
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                actions: [
                  const ThemeSwitcherButton(),
                  if (_isVideoLoaded)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isVideoVisible = !_isVideoVisible;
                        });

                        // If making the video visible again, seek to current subtitle start time
                        if (_isVideoVisible && _subtitleLine != null) {
                          // Give time for video player to initialize
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Future.delayed(Duration(milliseconds: 1000), () {
                              if (_videoPlayerKey.currentState != null &&
                                  _videoPlayerKey.currentState!
                                      .isInitialized()) {
                                final startTime = parseTimeString(
                                  _subtitleLine!.startTime,
                                );
                                _videoPlayerKey.currentState!.seekTo(startTime);
                              }
                            });
                          });
                        }
                      },
                      icon:
                          _isVideoVisible
                              ? SvgPicture.asset(
                                'assets/movie_off.svg',
                                semanticsLabel: 'Movie off',
                                height: 25,
                                width: 35,
                              )
                              : const Icon(Icons.movie_outlined),
                    ),
                  if (_isVideoLoaded && _isVideoVisible)
                    IconButton(
                      tooltip: 'Sync with video position',
                      icon: const Icon(Icons.sync),
                      onPressed: _syncWithVideoPosition,
                    ),
                  IconButton(
                    tooltip: 'Menu',
                    icon: const Icon(Icons.menu),
                    onPressed: () => _showEditLineMenuModal(),
                  ),
                ],
              ),
              body:
                  _subtitle?.lines.isEmpty ?? false
                      ? _buildEmptySubtitleView(context)
                      : GestureDetector(
                        onSecondaryTap:
                            () =>
                                _showEditLineMenuModal(), // Right-click opens menu
                        child: _buildResponsiveContent(
                          shouldShowVideo,
                          Column(
                            children: [
                              // Video player at the top
                              if (shouldShowVideo)
                                SizedBox(
                                  height: 240,
                                  child: VideoPlayerWidget(
                                    key: _videoPlayerKey,
                                    videoPath: _selectedVideoPath!,
                                    subtitleCollectionId: widget.subtitleId,
                                    subtitles: _subtitles,
                                    secondarySubtitles:
                                        _showSecondarySubtitles
                                            ? _secondarySubtitlesForPlayer
                                            : [],
                                    onSubtitlesUpdated: () {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (mounted) {
                                              setState(() {
                                                _markSubtitlesForRegeneration();
                                                _generateSubtitles();
                                              });
                                            }
                                          });
                                    },
                                    onSubtitleMarked: (
                                      subtitleIndex,
                                      isMarked,
                                    ) async {
                                      // Handle marking/unmarking from video player
                                      await _handleVideoPlayerMarkToggle(
                                        subtitleIndex,
                                        isMarked,
                                      );
                                    },
                                    onSubtitleCommentUpdated: (subtitleIndex, comment) async {
                                      // Update comment in database and refresh UI
                                      try {
                                        await updateSubtitleLineComment(widget.subtitleId, subtitleIndex, comment);
                                        // Refresh the subtitle data from database
                                        _subtitle = (await isar.subtitleCollections.get(widget.subtitleId))!;
                                        
                                        // Update current line if it matches
                                        if (_subtitleLine != null && _subtitleLine!.index == subtitleIndex + 1) {
                                          setState(() {
                                            _subtitleLine!.comment = comment;
                                          });
                                        }
                                        
                                        // Regenerate subtitles for video player
                                        _markSubtitlesForRegeneration();
                                        _generateSubtitles();
                                        
                                        SnackbarHelper.showSuccess(context, 
                                          comment != null ? 'Comment updated' : 'Comment deleted');
                                      } catch (e) {
                                        SnackbarHelper.showError(context, 'Failed to update comment: $e');
                                      }
                                    },
                                    onPlayStateChanged: (isPlaying) {
                                      // Update play/pause button state when video player state changes
                                      if (mounted) {
                                        setState(() {
                                          _isVideoPlaying = isPlaying;
                                        });
                                      }
                                    },
                                    onRepeatModeToggled: (isEnabled) {
                                      // Handle repeat mode toggle from video player
                                      if (isEnabled != _isRepeatModeEnabled) {
                                        _toggleRepeatMode();
                                      }
                                    },
                                    isRepeatModeEnabled: _isRepeatModeEnabled,
                                  ),
                                ),
                              // Add spacing after video when it's shown
                              if (shouldShowVideo) const SizedBox(height: 1),
                              // Main content in scrollable area
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // In edit mode, skip the original text field and related controls
                                        if (!_isEditMode) ...[
                                          // Show title row and checkboxes only when original text field is visible
                                          if (_showOriginalTextField) ...[
                                            // Empty space where the labels and controls used to be
                                            const SizedBox(height: 0),
                                          ],
                                          // Original text field - conditionally displayed
                                          if (_showOriginalTextField) ...[
                                            Stack(
                                              children: [
                                                Container(
                                                  height: 100,
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(
                                                    8.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF0A9396,
                                                      ),
                                                      width: 1.5,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4.0,
                                                        ),
                                                  ),
                                                  child:
                                                      isRawEnabled
                                                          ? CustomHtmlText(
                                                            htmlContent:
                                                                _originalController
                                                                    .text
                                                                    .replaceAll(
                                                                      '\n',
                                                                      '<br>',
                                                                    ),
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                            defaultStyle:
                                                                TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 16,
                                                                ),
                                                          )
                                                          : TextField(
                                                            controller:
                                                                _originalController,
                                                            undoController:
                                                                _undoHistoryController,
                                                            keyboardType:
                                                                TextInputType
                                                                    .multiline,
                                                            readOnly:
                                                                !isEditingEnabled,
                                                            maxLines: null,
                                                            expands: true,
                                                            inputFormatters: [
                                                              UnicodeTextInputFormatter(),
                                                            ],
                                                            decoration: const InputDecoration(
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              contentPadding:
                                                                  EdgeInsets.fromLTRB(
                                                                    8.0,
                                                                    8.0,
                                                                    60.0,
                                                                    8.0,
                                                                  ), // Add right padding for icon buttons
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 16,
                                                                  color: Color(
                                                                    0xFFFFFFFF,
                                                                  ),
                                                                ),
                                                            scrollPhysics:
                                                                const ClampingScrollPhysics(), // Enable scrolling
                                                            // Ultra-optimized settings for maximum keyboard responsiveness
                                                            autocorrect:
                                                                false, // Critical: Disable autocorrect for instant typing
                                                            enableSuggestions:
                                                                false, // Critical: Disable suggestions to reduce processing
                                                            smartDashesType:
                                                                SmartDashesType
                                                                    .disabled, // Disable smart dashes
                                                            smartQuotesType:
                                                                SmartQuotesType
                                                                    .disabled, // Disable smart quotes
                                                            textInputAction:
                                                                TextInputAction
                                                                    .newline, // Optimize for multiline
                                                            enableIMEPersonalizedLearning:
                                                                false, // Critical: Disable IME learning for faster response
                                                            enableInteractiveSelection:
                                                                true, // Enable text selection
                                                            showCursor:
                                                                true, // Keep cursor visible
                                                          ),
                                                ),
                                                // Character count positioned at bottom-right (with margin from buttons)
                                                Positioned(
                                                  bottom: 1,
                                                  right: 4,
                                                  child: BlocBuilder<EditLineCubit, EditLineState>(
                                                    buildWhen: (previous, current) =>
                                                        previous.originalCharCount != current.originalCharCount ||
                                                        previous.originalHasLongLine != current.originalHasLongLine,
                                                    builder: (context, state) {
                                                      // Use Bloc state if available, fallback to legacy state
                                                      final charCount = state.isInitialized 
                                                          ? state.originalCharCount 
                                                          : _originalCharCount;
                                                      final hasLongLine = state.isInitialized
                                                          ? state.originalHasLongLine
                                                          : _originalHasLongLine;
                                                      
                                                      return _CharacterCountWidget(
                                                        count: charCount,
                                                        hasLongLine: hasLongLine,
                                                      );
                                                    },
                                                  ),
                                                ),
                                                // "Original" title positioned at top-left
                                                Positioned(
                                                  top: 1,
                                                  left: 4,
                                                  child: Text(
                                                    'Original',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromARGB(
                                                        100,
                                                        255,
                                                        255,
                                                        255,
                                                      ),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                // Index/total count positioned at bottom-left
                                                Positioned(
                                                  bottom: 1,
                                                  left: 4,
                                                  child: Text(
                                                    "${_subtitleLine?.index ?? 1}/${_subtitle?.lines.length ?? 0}",
                                                    style: const TextStyle(
                                                      color: Color.fromARGB(
                                                        125,
                                                        255,
                                                        255,
                                                        255,
                                                      ),
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                // Copy button and edit button positioned at top-right as a column
                                                Positioned(
                                                  top: 1,
                                                  right: 1,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        constraints:
                                                            const BoxConstraints(
                                                              minWidth: 24,
                                                              minHeight: 24,
                                                            ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () {
                                                          Clipboard.setData(
                                                            ClipboardData(
                                                              text:
                                                                  _originalController
                                                                      .text,
                                                            ),
                                                          );
                                                          SnackbarHelper.showSuccess(
                                                            context,
                                                            'Copied to clipboard',
                                                            duration:
                                                                const Duration(
                                                                  seconds: 2,
                                                                ),
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.copy,
                                                          size: 16,
                                                        ),
                                                        color: const Color(
                                                          0xFFCA6702,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        constraints:
                                                            const BoxConstraints(
                                                              minWidth: 24,
                                                              minHeight: 24,
                                                            ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () {
                                                          setState(() {
                                                            isEditingEnabled =
                                                                !isEditingEnabled;
                                                          });
                                                        },
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          size: 16,
                                                        ),
                                                        color:
                                                            isEditingEnabled
                                                                ? const Color(
                                                                  0xFFBB3E03,
                                                                )
                                                                : const Color(
                                                                  0xFFCA6702,
                                                                ),
                                                        tooltip:
                                                            "Toggle Edit Mode",
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ],

                                        // Empty space where the labels and line count used to be
                                        const SizedBox(height: 0),
                                        const SizedBox(height: 5),
                                        Stack(
                                          children: [
                                            Container(
                                              height:
                                                  100, // Set a fixed height for the TextField
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF0A9396,
                                                  ),
                                                  width: 1.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                              child:
                                                  isRawEnabled &&
                                                          _editedController
                                                              .text
                                                              .isNotEmpty
                                                      ? CustomHtmlText(
                                                        htmlContent:
                                                            _editedController
                                                                .text
                                                                .replaceAll(
                                                                  '\n',
                                                                  '<br>',
                                                                ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        defaultStyle: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                                      )
                                                      : TextField(
                                                        controller:
                                                            _editedController,
                                                        focusNode: _focusNode,
                                                        undoController:
                                                            _undoHistoryController,
                                                        keyboardType:
                                                            TextInputType
                                                                .multiline,
                                                        readOnly:
                                                            false, // Original subtitle should not be editable
                                                        maxLines:
                                                            null, // Allow the text to wrap and grow if needed
                                                        expands:
                                                            true, // Make the TextField expand vertically to fit the height
                                                        inputFormatters: [
                                                          UnicodeTextInputFormatter(),
                                                        ],
                                                        decoration: const InputDecoration(
                                                          border:
                                                              InputBorder.none,
                                                          contentPadding:
                                                              EdgeInsets.fromLTRB(
                                                                8.0,
                                                                8.0,
                                                                30.0,
                                                                8.0,
                                                              ), // Add right padding for icon buttons
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          color: Color(
                                                            0xFFFFFFFF,
                                                          ),
                                                        ),
                                                        scrollPhysics:
                                                            const ClampingScrollPhysics(), // Enable scrolling
                                                        // Balanced settings for normal keyboard with good performance
                                                        autocorrect:
                                                            false, // Keep disabled for performance
                                                        enableSuggestions:
                                                            true, // Enable to show normal keyboard with suggestions
                                                        smartDashesType:
                                                            SmartDashesType
                                                                .disabled, // Keep disabled for performance
                                                        smartQuotesType:
                                                            SmartQuotesType
                                                                .disabled, // Keep disabled for performance
                                                        textInputAction:
                                                            TextInputAction
                                                                .newline, // Optimize for multiline
                                                        enableIMEPersonalizedLearning:
                                                            true, // Enable for normal keyboard behavior
                                                        enableInteractiveSelection:
                                                            true, // Keep text selection
                                                        showCursor:
                                                            true, // Keep cursor visible
                                                        // Remove any onChanged callback to prevent lag
                                                      ),
                                            ),
                                            // Character count positioned at bottom-right (with margin from buttons)
                                            Positioned(
                                              bottom: 1,
                                              right: 4,
                                              child: BlocBuilder<EditLineCubit, EditLineState>(
                                                buildWhen: (previous, current) =>
                                                    previous.editedCharCount != current.editedCharCount ||
                                                    previous.editedHasLongLine != current.editedHasLongLine,
                                                builder: (context, state) {
                                                  // Use Bloc state if available, fallback to legacy state
                                                  final charCount = state.isInitialized 
                                                      ? state.editedCharCount 
                                                      : _editedCharCount;
                                                  final hasLongLine = state.isInitialized
                                                      ? state.editedHasLongLine
                                                      : _editedHasLongLine;
                                                  
                                                  return _CharacterCountWidget(
                                                    count: charCount,
                                                    hasLongLine: hasLongLine,
                                                  );
                                                },
                                              ),
                                            ),
                                            // "Edited" title positioned at top-left
                                            Positioned(
                                              top: 1,
                                              left: 4,
                                              child: Text(
                                                _isEditMode
                                                    ? 'Subtitle Text'
                                                    : 'Edited',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color.fromARGB(
                                                    100,
                                                    255,
                                                    255,
                                                    255,
                                                  ),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            // Index/total count positioned at bottom-left
                                            Positioned(
                                              bottom: 1,
                                              left: 4,
                                              child: Text(
                                                "${_subtitleLine?.index ?? 1}/${_subtitle?.lines.length ?? 0}",
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                    120,
                                                    255,
                                                    255,
                                                    255,
                                                  ),
                                                  fontStyle: FontStyle.italic,
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            // Copy/paste buttons positioned at top-right as a column
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 24,
                                                          minHeight: 24,
                                                        ),
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () {
                                                      Clipboard.setData(
                                                        ClipboardData(
                                                          text:
                                                              _editedController
                                                                  .text,
                                                        ),
                                                      );
                                                      SnackbarHelper.showSuccess(
                                                        context,
                                                        'Copied to clipboard',
                                                        duration:
                                                            const Duration(
                                                              seconds: 2,
                                                            ),
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.copy,
                                                      size: 16,
                                                    ),
                                                    color: const Color(
                                                      0xFFCA6702,
                                                    ),
                                                  ),
                                                  // Only show paste original button in translation mode
                                                  if (!_isEditMode)
                                                    IconButton(
                                                      constraints:
                                                          const BoxConstraints(
                                                            minWidth: 24,
                                                            minHeight: 24,
                                                          ),
                                                      padding: EdgeInsets.zero,
                                                      onPressed: () {
                                                        setState(() {
                                                          _editedController
                                                                  .text =
                                                              _originalController
                                                                  .text;
                                                        });
                                                      },
                                                      icon: const Icon(
                                                        Icons.paste,
                                                        size: 16,
                                                      ),
                                                      color: const Color(
                                                        0xFFCA6702,
                                                      ),
                                                      tooltip: "Paste Original",
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                // Calculate available width and adjust button sizes accordingly
                                                double availableWidth =
                                                    constraints.maxWidth;
                                                double buttonSize =
                                                    availableWidth < 400
                                                        ? 28
                                                        : 32; // Smaller icons for narrow screens
                                                double buttonPadding =
                                                    availableWidth < 400
                                                        ? 0.4
                                                        : 1.0; // Less padding for narrow screens

                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Flexible(
                                                      child: IconButton(
                                                        constraints:
                                                            BoxConstraints(
                                                              minWidth: 24,
                                                              maxWidth: 36,
                                                            ),
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  buttonPadding,
                                                            ),
                                                        onPressed:
                                                            _subtitleLine !=
                                                                    null
                                                                ? () => _prevSubtitle(
                                                                  widget
                                                                      .subtitleId,
                                                                  _subtitleLine!
                                                                          .index -
                                                                      1,
                                                                )
                                                                : null,
                                                        icon: Icon(
                                                          Icons.skip_previous,
                                                          size: buttonSize,
                                                          color:
                                                              Provider.of<
                                                                        ThemeProvider
                                                                      >(
                                                                        context,
                                                                      ).themeMode ==
                                                                      ThemeMode
                                                                          .light
                                                                  ? const Color.fromARGB(
                                                                    255,
                                                                    0,
                                                                    45,
                                                                    54,
                                                                  )
                                                                  : const Color.fromARGB(
                                                                    255,
                                                                    233,
                                                                    216,
                                                                    166,
                                                                  ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Dictionary popup menu button (moved here - always visible)
                                                    Flexible(
                                                      child: PopupMenuButton<
                                                        String
                                                      >(
                                                        icon: Icon(
                                                          Icons.book,
                                                          size: buttonSize,
                                                          color:
                                                              Provider.of<
                                                                        ThemeProvider
                                                                      >(
                                                                        context,
                                                                      ).themeMode ==
                                                                      ThemeMode
                                                                          .light
                                                                  ? const Color.fromARGB(
                                                                    255,
                                                                    0,
                                                                    45,
                                                                    54,
                                                                  )
                                                                  : const Color.fromARGB(
                                                                    255,
                                                                    233,
                                                                    216,
                                                                    166,
                                                                  ),
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16,
                                                              ),
                                                        ),
                                                        elevation: 8,
                                                        offset: const Offset(
                                                          0,
                                                          8,
                                                        ),
                                                        tooltip: 'Dictionary',
                                                        onSelected: (
                                                          String value,
                                                        ) {
                                                          if (value == "olam") {
                                                            _showOlamDictionary();
                                                          } else if (value ==
                                                              "urban") {
                                                            _showUrbanDictionary();
                                                          } else if (value ==
                                                              "msone") {
                                                            _showMsoneDictionary();
                                                          } else if (value ==
                                                              "ai_explain") {
                                                            _showAiExplanation();
                                                          }
                                                        },
                                                        itemBuilder:
                                                            (
                                                              BuildContext
                                                              context,
                                                            ) => [
                                                              // MSone Dictionary option (moved from icon row)
                                                              if (_isMsoneEnabled)
                                                                PopupMenuItem(
                                                                  value:
                                                                      "msone",
                                                                  child: Container(
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              4,
                                                                        ),
                                                                    child: Row(
                                                                      children: [
                                                                        SvgPicture.asset(
                                                                          'assets/msone.svg',
                                                                          semanticsLabel:
                                                                              'Msone Logo',
                                                                          height:
                                                                              20,
                                                                          width:
                                                                              20,
                                                                          colorFilter: const ColorFilter.mode(
                                                                            Color(
                                                                              0xFF3A86FF,
                                                                            ),
                                                                            BlendMode.srcIn,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              16,
                                                                        ),
                                                                        Text(
                                                                          "MSone Dictionary",
                                                                          style: Theme.of(
                                                                            context,
                                                                          ).textTheme.bodyLarge?.copyWith(
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              // Show Olam Dictionary only if MSone is enabled
                                                              if (_isMsoneEnabled)
                                                                PopupMenuItem(
                                                                  value: "olam",
                                                                  child: Container(
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              4,
                                                                        ),
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .book,
                                                                          color: Color(
                                                                            0xFF9C27B0,
                                                                          ), // Purple color for Olam
                                                                          size:
                                                                              24,
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              16,
                                                                        ),
                                                                        Text(
                                                                          "Olam Dictionary",
                                                                          style: Theme.of(
                                                                            context,
                                                                          ).textTheme.bodyLarge?.copyWith(
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              // Urban Dictionary is always available
                                                              PopupMenuItem(
                                                                value: "urban",
                                                                child: Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .forum,
                                                                        color: Color(
                                                                          0xFF4CAF50,
                                                                        ), // Green color for Urban Dictionary
                                                                        size:
                                                                            24,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            16,
                                                                      ),
                                                                      Text(
                                                                        "Urban Dictionary",
                                                                        style: Theme.of(
                                                                          context,
                                                                        ).textTheme.bodyLarge?.copyWith(
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              // AI Explanation
                                                              PopupMenuItem(
                                                                value: "ai_explain",
                                                                child: Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .auto_awesome,
                                                                        color: Color(
                                                                          0xFF9C27B0,
                                                                        ), // Purple color for AI
                                                                        size:
                                                                            24,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            16,
                                                                      ),
                                                                      Text(
                                                                        "Explain with AI",
                                                                        style: Theme.of(
                                                                          context,
                                                                        ).textTheme.bodyLarge?.copyWith(
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: FormattingMenu(
                                                        controller:
                                                            _editedController,
                                                        colorHistory:
                                                            _colorHistory,
                                                        onColorHistoryUpdate:
                                                            _saveColorHistory,
                                                      ),
                                                    ),
                                                    if (_subtitleLine != null &&
                                                        _subtitle != null)
                                                      Flexible(
                                                        child: SubtitleActionsMenu(
                                                          editedController:
                                                              _editedController,
                                                          startTime:
                                                              _startTimeController
                                                                  .text,
                                                          endTime:
                                                              _endTimeController
                                                                  .text,
                                                          subtitleId:
                                                              widget.subtitleId,
                                                          currentLine:
                                                              _subtitleLine!,
                                                          collection:
                                                              _subtitle!,
                                                          refreshCallback:
                                                              () => _fetchSubtitleLine(
                                                                widget
                                                                    .subtitleId,
                                                                _subtitleLine!
                                                                    .index,
                                                              ),
                                                          refreshToLineCallback:
                                                              (newLineIndex) => _fetchSubtitleLine(
                                                                widget
                                                                    .subtitleId,
                                                                newLineIndex - 1, // Convert from 1-based to 0-based array index
                                                              ),
                                                          sessionId: widget.sessionId,
                                                          onBeforeAdd: _updateSubtitleSilently, // Save before adding new line
                                                          isVideoLoaded: _isVideoLoaded,
                                                          getCurrentVideoPosition: _isVideoLoaded && _videoPlayerKey.currentState != null
                                                              ? () => _videoPlayerKey.currentState!.getCurrentPosition()
                                                              : null,
                                                        ),
                                                      ),
                                                    Flexible(
                                                      child: IconButton(
                                                        constraints:
                                                            BoxConstraints(
                                                              minWidth: 24,
                                                              maxWidth: 36,
                                                            ),
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  buttonPadding,
                                                            ),
                                                        icon: Icon(
                                                          Icons.save,
                                                          size: buttonSize,
                                                          color:
                                                              Provider.of<
                                                                        ThemeProvider
                                                                      >(
                                                                        context,
                                                                      ).themeMode ==
                                                                      ThemeMode
                                                                          .light
                                                                  ? const Color.fromARGB(
                                                                    255,
                                                                    0,
                                                                    45,
                                                                    54,
                                                                  )
                                                                  : const Color.fromARGB(
                                                                    255,
                                                                    233,
                                                                    216,
                                                                    166,
                                                                  ),
                                                        ),
                                                        onPressed: () async {
                                                          // Show loading state briefly for better UX
                                                          setState(() {
                                                            // Could add a loading indicator here if needed
                                                          });

                                                          // Perform save operation asynchronously
                                                          await Future.microtask(
                                                            () async {
                                                              await _updateSubtitle(
                                                                context,
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    // Play/Pause button for video
                                                    if (_isVideoLoaded)
                                                      Flexible(
                                                        child: IconButton(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal:
                                                                    buttonPadding,
                                                              ),
                                                          constraints:
                                                              BoxConstraints(
                                                                minWidth: 24,
                                                                maxWidth: 36,
                                                              ),
                                                          icon: Icon(
                                                            _isVideoPlaying
                                                                ? Icons.pause
                                                                : Icons
                                                                    .play_arrow,
                                                            size: buttonSize,
                                                            color:
                                                                Provider.of<
                                                                          ThemeProvider
                                                                        >(
                                                                          context,
                                                                        ).themeMode ==
                                                                        ThemeMode
                                                                            .light
                                                                    ? const Color.fromARGB(
                                                                      255,
                                                                      0,
                                                                      45,
                                                                      54,
                                                                    )
                                                                    : const Color.fromARGB(
                                                                      255,
                                                                      233,
                                                                      216,
                                                                      166,
                                                                    ),
                                                          ),
                                                          onPressed: () {
                                                            if (_videoPlayerKey
                                                                    .currentState !=
                                                                null) {
                                                              if (_isVideoPlaying) {
                                                                _videoPlayerKey
                                                                    .currentState!
                                                                    .pause();
                                                              } else {
                                                                _videoPlayerKey
                                                                    .currentState!
                                                                    .play();
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      ),

                                                    Flexible(
                                                      child: IconButton(
                                                        constraints:
                                                            BoxConstraints(
                                                              minWidth: 24,
                                                              maxWidth: 36,
                                                            ),
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  buttonPadding,
                                                            ),
                                                        onPressed:
                                                            _subtitleLine !=
                                                                    null
                                                                ? () => _nextSubtitle(
                                                                  widget
                                                                      .subtitleId,
                                                                  _subtitleLine!
                                                                          .index +
                                                                      1,
                                                                )
                                                                : null,
                                                        icon: Icon(
                                                          Icons.skip_next,
                                                          size: buttonSize,
                                                          color:
                                                              Provider.of<
                                                                        ThemeProvider
                                                                      >(
                                                                        context,
                                                                      ).themeMode ==
                                                                      ThemeMode
                                                                          .light
                                                                  ? const Color.fromARGB(
                                                                    255,
                                                                    0,
                                                                    45,
                                                                    54,
                                                                  )
                                                                  : const Color.fromARGB(
                                                                    255,
                                                                    233,
                                                                    216,
                                                                    166,
                                                                  ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 0),

                                        // Time fields section - update keyboard type for both fields
                                        Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _isTimeVisible =
                                                          !_isTimeVisible;
                                                    });

                                                    // Auto-scroll to bottom when time fields are shown
                                                    if (_isTimeVisible) {
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback((
                                                            _,
                                                          ) {
                                                            _scrollController.animateTo(
                                                              _scrollController
                                                                  .position
                                                                  .maxScrollExtent,
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        300,
                                                                  ),
                                                              curve:
                                                                  Curves
                                                                      .easeInOut,
                                                            );
                                                          });
                                                    }
                                                  },
                                                  label: Text(
                                                    "Edit Time",
                                                    style: TextStyle(
                                                      color: Color(0xFFCA6702),
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  icon: Icon(
                                                    _isTimeVisible
                                                        ? Icons
                                                            .keyboard_arrow_down
                                                        : Icons.chevron_right,
                                                    size: 32,
                                                    color: Color(0xFFCA6702),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (_isTimeVisible)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16.0,
                                                    ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                                                  children: [
                                                    Expanded(
                                                      child: _buildTimeComponentFields(
                                                        'Start Time',
                                                        true,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: _buildTimeComponentFields(
                                                        'End Time',
                                                        false,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
            ); // Scaffold
          }, // builder (inner Builder)
        ), // Builder (inner - wraps Scaffold)
      ), // PopScope
    ); // FirstTimeInstructions
  }

  // New method to build the empty state view
  Widget _buildEmptySubtitleView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.subtitles_outlined,
            size: 80,
            color: Color(0xFF0A9396),
          ),
          const SizedBox(height: 24),
          const Text(
            "No subtitles yet",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Get started by adding your first subtitle line",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addInitialSubtitleLine,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 1, 54, 64),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Add Subtitle Line",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Method to add the initial subtitle line
  Future<void> _addInitialSubtitleLine() async {
    setState(() {
      _isEditMode = true; // Switch to edit mode
      _isTimeVisible = true; // Show time fields
    });

    // Create an empty subtitle line
    final newLine =
        SubtitleLine()
          ..index = 1
          ..original = ""
          ..startTime = "00:00:00,000"
          ..endTime = "00:00:02,000";

    try {
      // Add to database
      final success = await addSubtitleLine(widget.subtitleId, newLine, 0);
      if (success) {
        // Wait a moment to ensure database transaction completes
        await Future.delayed(const Duration(milliseconds: 100));

        // Force refresh subtitle collection from database before fetching line
        _subtitle = await isar.subtitleCollections.get(widget.subtitleId);

        // Refresh the screen with the new line
        _fetchSubtitleLine(widget.subtitleId, 0);
        if (!mounted) return;
        SubtitleOperations.showSuccessSnackbar(
          context,
          'New subtitle line added',
        );

        // Return true when navigating back to indicate success
        // This will trigger the refresh in the parent screen
        // Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        SnackbarHelper.showError(context, 'Failed to add subtitle line');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Error: $e');
    }
  }

  /// Enhanced file save with three-strategy approach
  Future<void> _performEnhancedFileSave(BuildContext contxt, List<SubtitleLine> updatedLines) async {
    if (_subtitle == null) return;

    // Generate SRT content
    final srtContent = SrtCompiler.generateSrtContent(updatedLines);

    // Strategy 1: Try to save using originalFileUri (SAF URI)
    bool saveSuccessful = false;
    String? originalFileUri = _subtitle!.originalFileUri;
    
    if (originalFileUri!.isNotEmpty) {
      try {
        if (Platform.isAndroid && originalFileUri.startsWith('content://')) {
          // Use SAF to write to the content URI
          final success = await PlatformFileHandler.writeFile(
            content: srtContent,
            filePath: originalFileUri,
            fileName: _subtitle!.fileName,
            mimeType: 'application/x-subrip',
          );

          if (success) {
            saveSuccessful = true;
            if (mounted) {
              ScaffoldMessenger.of(contxt).showSnackBar(
                SnackBar(
                  content: const Text('Changes saved to database and file'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(10),
                ),
              );
            }
          }
        } else {
          // Desktop platform with regular file path
          String? filePath = originalFileUri;
          
          // Check if the path is a directory or doesn't end with .srt
          if (Directory(filePath).existsSync() || !filePath.toLowerCase().endsWith('.srt')) {
            // Create a proper file path by combining the directory with the filename
            String fileName = _subtitle!.fileName;
            if (!fileName.toLowerCase().endsWith('.srt')) {
              fileName = '$fileName.srt';
            }
            filePath = '$filePath/$fileName';
          }

          await File(filePath).writeAsString(srtContent);
          saveSuccessful = true;
          
          if (mounted) {
            ScaffoldMessenger.of(contxt).showSnackBar(
              SnackBar(
                content: const Text('Changes saved to database and file'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                duration: const Duration(seconds: 2),
                margin: const EdgeInsets.all(10),
              ),
            );
          }
        }
      } catch (e) {
        // Strategy 1 failed, we'll try Strategy 2
        if (kDebugMode) {
          logWarning(
            'Failed to save using originalFileUri: $e',
            context: 'EditSubtitleScreen._saveChanges',
          );
        }
      }
    }

    // Strategy 2: If Strategy 1 failed, try using filePath
    if (!saveSuccessful) {
      String? filePath = _subtitle!.filePath;
      
      if (filePath!.isNotEmpty) {
        try {
          if (Platform.isAndroid && filePath.startsWith('content://')) {
            // Use SAF to write to the content URI
            final success = await PlatformFileHandler.writeFile(
              content: srtContent,
              filePath: filePath,
              fileName: _subtitle!.fileName,
              mimeType: 'application/x-subrip',
            );

            if (success) {
              saveSuccessful = true;
              if (mounted) {
                ScaffoldMessenger.of(contxt).showSnackBar(
                  SnackBar(
                    content: const Text('Changes saved to database and file'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(10),
                  ),
                );
              }
            }
          } else {
            // Desktop platform with regular file path
            String? filePathToUse = filePath;
            
            // Check if the path is a directory or doesn't end with .srt
            if (Directory(filePathToUse).existsSync() || !filePathToUse.toLowerCase().endsWith('.srt')) {
              // Create a proper file path by combining the directory with the filename
              String fileName = _subtitle!.fileName;
              if (!fileName.toLowerCase().endsWith('.srt')) {
                fileName = '$fileName.srt';
              }
              filePathToUse = '$filePathToUse/$fileName';
            }

            await File(filePathToUse).writeAsString(srtContent);
            saveSuccessful = true;
            
            if (mounted) {
              ScaffoldMessenger.of(contxt).showSnackBar(
                SnackBar(
                  content: const Text('Changes saved to database and file'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(10),
                ),
              );
            }
          }
        } catch (e) {
          // Strategy 2 also failed
          if (kDebugMode) {
            logWarning(
              'Failed to save using filePath: $e',
              context: 'EditSubtitleScreen._saveChanges',
            );
          }
        }
      }
    }

    // Strategy 3: If both strategies failed, ask user to pick new location
    if (!saveSuccessful) {
      if (!mounted) return;
      
      // Show dialog asking user to pick new save location
      final shouldPickLocation = await _showSaveLocationDialog();
      
      if (shouldPickLocation == true && mounted) {
        try {
          String? newFilePath;
          String? newOriginalUri;
          
          if (Platform.isAndroid) {
            // Use SAF on Android
            final fileInfo = await PlatformFileHandler.saveNewFile(
              content: srtContent,
              fileName: _subtitle!.fileName.endsWith('.srt') 
                  ? _subtitle!.fileName 
                  : '${_subtitle!.fileName}.srt',
              mimeType: 'application/x-subrip',
            );
            
            if (fileInfo != null) {
              newFilePath = fileInfo.path;
              newOriginalUri = fileInfo.safUri;
              saveSuccessful = true;
            }
          } else if (Platform.isIOS) {
            // iOS platform - show save file dialog with bytes parameter
            final srtBytes = Uint8List.fromList(utf8.encode(srtContent));
            final result = await fp.FilePicker.platform.saveFile(
              dialogTitle: 'Save Subtitle File',
              fileName: _subtitle!.fileName.endsWith('.srt') 
                  ? _subtitle!.fileName 
                  : '${_subtitle!.fileName}.srt',
              type: fp.FileType.custom,
              allowedExtensions: ['srt'],
              bytes: srtBytes,
            );
            
            if (result != null) {
              newFilePath = result;
              newOriginalUri = result;
              saveSuccessful = true;
            }
          } else {
            // Desktop platform - show save file dialog
            final result = await fp.FilePicker.platform.saveFile(
              dialogTitle: 'Save Subtitle File',
              fileName: _subtitle!.fileName.endsWith('.srt') 
                  ? _subtitle!.fileName 
                  : '${_subtitle!.fileName}.srt',
              type: fp.FileType.custom,
              allowedExtensions: ['srt'],
            );
            
            if (result != null) {
              try {
                final file = File(result);
                await file.writeAsString(srtContent);
                newFilePath = result;
                newOriginalUri = result;
                saveSuccessful = true;
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(contxt).showSnackBar(
                    SnackBar(
                      content: Text('Failed to write file: $e'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      margin: const EdgeInsets.all(10),
                    ),
                  );
                }
              }
            }
          }
          
          // Update the subtitle collection with new paths
          if (saveSuccessful && newFilePath != null) {
            _subtitle!.filePath = newFilePath;
            _subtitle!.originalFileUri = newOriginalUri;
            
            final updateSuccess = await updateSubtitleCollection(_subtitle!);
            
            if (updateSuccess && mounted) {
              ScaffoldMessenger.of(contxt).showSnackBar(
                SnackBar(
                  content: const Text('Changes saved to database and file (new location)'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(10),
                ),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(contxt).showSnackBar(
                SnackBar(
                  content: const Text('File saved but failed to update file location in database'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  margin: const EdgeInsets.all(10),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(contxt).showSnackBar(
              SnackBar(
                content: Text('Failed to save file to new location: $e'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                margin: const EdgeInsets.all(10),
              ),
            );
          }
        }
      }
    }
    
    // If all strategies failed and user didn't pick a new location
    if (!saveSuccessful && mounted) {
      ScaffoldMessenger.of(contxt).showSnackBar(
        SnackBar(
          content: const Text('File save failed - changes saved to database only'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  /// Show dialog asking user if they want to pick a new save location
  Future<bool?> _showSaveLocationDialog() async {
    // Dynamic color variables for adaptive theming
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.folder_open_rounded,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Save Location',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Original file location is no longer accessible',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: onSurfaceColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'File Access Issue',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: onSurfaceColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The original file location is no longer accessible. This can happen when files are moved, deleted, or when storage permissions have changed.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Would you like to choose a new location to save the file?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onSurfaceColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: onSurfaceColor,
                          side: BorderSide(
                            color: onSurfaceColor.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close,
                              size: 20,
                              color: onSurfaceColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: onSurfaceColor,
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
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Choose',
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

// Character count display widget
class _CharacterCountWidget extends StatelessWidget {
  final int count;
  final bool hasLongLine;

  const _CharacterCountWidget({required this.count, required this.hasLongLine});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count chars',
      style: TextStyle(
        fontSize: 11,
        color: hasLongLine ? Colors.red : Colors.white.withValues(alpha: 0.5),
        fontWeight: hasLongLine ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

// Text field widget with undo/redo support
class _OptimizedTextField extends StatefulWidget {
  final TextEditingController controller;
  final UndoHistoryController undoController;
  final bool readOnly;
  final String title;
  final Widget characterCountWidget;
  final String indexText;
  final bool isRawEnabled;
  final bool showEditButton;
  final bool showPasteButton;
  final bool isEditingEnabled;

  const _OptimizedTextField({
    required this.controller,
    required this.undoController,
    required this.readOnly,
    required this.title,
    required this.characterCountWidget,
    required this.indexText,
    required this.isRawEnabled,
    required this.showEditButton,
    required this.showPasteButton,
    required this.isEditingEnabled,
  });

  @override
  State<_OptimizedTextField> createState() => _OptimizedTextFieldState();
}

class _OptimizedTextFieldState extends State<_OptimizedTextField> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            border: Border.all(color: const Color(0xFF0A9396), width: 1.5),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child:
              widget.isRawEnabled
                  ? CustomHtmlText(
                    htmlContent: widget.controller.text.replaceAll(
                      '\n',
                      '<br>',
                    ),
                    textAlign: TextAlign.center,
                    defaultStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  )
                  : TextField(
                    controller: widget.controller,
                    undoController: widget.undoController,
                    keyboardType: TextInputType.multiline,
                    readOnly: widget.readOnly,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(
                        8.0,
                        8.0,
                        30.0,
                        8.0,
                      ), // Add right padding for icon buttons
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFFFFFF),
                    ),
                    scrollPhysics: const BouncingScrollPhysics(),
                    // Balanced settings for normal keyboard with good performance
                    autocorrect: false, // Keep disabled for performance
                    enableSuggestions:
                        true, // Enable to show normal keyboard with suggestions
                    smartDashesType:
                        SmartDashesType.disabled, // Keep disabled for performance
                    smartQuotesType:
                        SmartQuotesType.disabled, // Keep disabled for performance
                    textInputAction:
                        TextInputAction.newline, // Optimize for multiline
                    enableIMEPersonalizedLearning:
                        true, // Enable for normal keyboard behavior
                    enableInteractiveSelection: true, // Enable text selection
                    showCursor: true, // Keep cursor visible
                  ),
        ),
        // Character count positioned at bottom-right
        Positioned(bottom: 1, right: 4, child: widget.characterCountWidget),
        // Title positioned at top-left
        Positioned(
          top: 1,
          left: 4,
          child: Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(100, 255, 255, 255),
              fontSize: 12,
            ),
          ),
        ),
        // Index/total count positioned at bottom-left
        Positioned(
          bottom: 1,
          left: 4,
          child: Text(
            widget.indexText,
            style: const TextStyle(
              color: Color.fromARGB(125, 255, 255, 255),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
        // Action buttons positioned at top-right
        Positioned(
          top: 1,
          right: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Copy functionality - will be implemented when needed
                },
                icon: const Icon(Icons.copy, size: 16),
                color: const Color(0xFFCA6702),
              ),
              if (widget.showEditButton)
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Edit functionality - will be implemented when needed
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  color:
                      widget.isEditingEnabled
                          ? const Color(0xFFBB3E03)
                          : const Color(0xFFCA6702),
                  tooltip: "Toggle Edit Mode",
                ),
              if (widget.showPasteButton)
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Paste functionality - will be implemented when needed
                  },
                  icon: const Icon(Icons.paste, size: 16),
                  color: const Color(0xFFCA6702),
                  tooltip: "Paste Original",
                ),
            ],
          ),
        ),
      ],
    );
  }
}
