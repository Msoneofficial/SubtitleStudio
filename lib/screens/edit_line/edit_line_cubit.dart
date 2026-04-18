import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:subtitle_studio/screens/edit_line/edit_line_state.dart';
import 'package:subtitle_studio/screens/edit_line/repositories/edit_line_repository.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';
import 'package:subtitle_studio/widgets/video_player_widget.dart';
import 'package:subtitle_studio/utils/subtitle_parser.dart';
import 'package:subtitle_studio/database/models/models.dart';

/// Cubit for managing EditLineScreen state
/// 
/// This Cubit encapsulates all business logic for single subtitle line editing,
/// following the BLoC pattern for state management. It communicates with
/// EditLineRepository to fetch and manipulate data.
/// 
/// Key Responsibilities:
/// - Load and manage single subtitle line
/// - Handle text editing with character counting
/// - Manage time validation
/// - Handle video player integration
/// - Coordinate repeat playback
/// - Manage preferences
/// - Handle file save operations
/// - Comprehensive logging and error handling
/// 
/// Performance Optimizations:
/// - Stream-based character counting (replaces timers and listeners)
/// - Debounced text updates (prevents excessive state emissions)
/// - Batched preference loading
/// - Proper resource disposal (no memory leaks)
class EditLineCubit extends Cubit<EditLineState> {
  final EditLineRepository _repository;
  final Id _subtitleCollectionId;
  final int _initialLineIndex;

  // Stream subscriptions for text changes (replaces controller listeners)
  StreamSubscription<String>? _originalTextSubscription;
  StreamSubscription<String>? _editedTextSubscription;
  
  // Stream controllers for text input (with built-in debouncing)
  final _originalTextController = StreamController<String>.broadcast();
  final _editedTextController = StreamController<String>.broadcast();
  
  // Debounce timers for text streams
  Timer? _originalTextDebounce;
  Timer? _editedTextDebounce;
  
  // Video repeat playback timer (managed in Cubit, not widget)
  Timer? _repeatPlaybackTimer;
  
  // Initial values for unsaved changes detection
  String _initialOriginalText = '';
  String _initialEditedText = '';
  String _initialStartTime = '';
  String _initialEndTime = '';

  EditLineCubit({
    required Id subtitleCollectionId,
    required int lineIndex,
    required int sessionId,
    bool isNewSubtitle = false,
    bool isEditMode = false,
    String? videoPath,
    bool isVideoLoaded = false,
    List<SimpleSubtitleLine>? secondarySubtitles,
    EditLineRepository? repository,
  })  : _repository = repository ?? EditLineRepository(),
        _subtitleCollectionId = subtitleCollectionId,
        _initialLineIndex = lineIndex,
        super(EditLineState.initial(
          sessionId: sessionId,
          isNewSubtitle: isNewSubtitle,
          isEditMode: isEditMode,
        )) {
    logInfo(
      'EditLineCubit: Initialized for collection $subtitleCollectionId, line $lineIndex, session $sessionId',
      context: 'EditLineCubit',
    );
    
    // Initialize video state if provided
    if (videoPath != null && isVideoLoaded) {
      emit(state.copyWith(
        videoPath: videoPath,
        isVideoLoaded: true,
        isVideoVisible: true,
      ));
    }
    
    // Initialize secondary subtitles if provided
    if (secondarySubtitles != null && secondarySubtitles.isNotEmpty) {
      emit(state.copyWith(
        secondarySubtitles: secondarySubtitles,
        showSecondarySubtitles: true,
      ));
    }
    
    // Set up text change streams for character counting
    _initializeTextStreams();
  }

  /// Initialize the edit line screen
  /// 
  /// Loads:
  /// 1. Subtitle line data
  /// 2. Subtitle collection metadata
  /// 3. Preferences (all at once for performance)
  /// 4. Generate subtitles for video player
  /// 5. Generate secondary subtitles if configured
  Future<void> initialize() async {
    try {
      await logInfo(
        'EditLineCubit: Starting initialization',
        context: 'EditLineCubit.initialize',
      );

      emit(state.copyWith(isLoading: true, clearErrorMessage: true));

      // Load subtitle collection
      final collection = await _repository.fetchSubtitleCollection(
        _subtitleCollectionId,
      );

      if (collection == null) {
        throw Exception('Subtitle collection not found: $_subtitleCollectionId');
      }

      // Load subtitle line
      SubtitleLine? line;
      if (!state.isNewSubtitle) {
        line = await _repository.fetchSubtitleLine(
          _subtitleCollectionId,
          _initialLineIndex,
        );

        if (line == null) {
          throw Exception('Subtitle line not found at index $_initialLineIndex');
        }
      }

      // Load all preferences in parallel
      final preferences = await _repository.loadAllPreferences(
        _subtitleCollectionId,
      );

      // Generate subtitles for video player
      final subtitles = await _repository.generateSubtitles(
        _subtitleCollectionId,
      );

      // Generate secondary subtitles if configured
      List<Subtitle> secondarySubtitlesForPlayer = [];
      if (state.secondarySubtitles.isNotEmpty) {
        secondarySubtitlesForPlayer = _repository.generateSecondarySubtitles(
          state.secondarySubtitles,
        );
      }

      // Store initial values for unsaved changes detection
      if (line != null) {
        _initialOriginalText = line.original;
        _initialEditedText = line.edited ?? '';
        _initialStartTime = line.startTime;
        _initialEndTime = line.endTime;
      }

      await logInfo(
        'EditLineCubit: Initialization complete for line ${line?.index ?? "new"}',
        context: 'EditLineCubit.initialize',
      );

      emit(EditLineState(
        // Core data
        subtitleLine: line,
        subtitleCollection: collection,
        isNewSubtitle: state.isNewSubtitle,
        sessionId: state.sessionId,
        
        // Text field state
        originalText: line?.original ?? '',
        editedText: line?.edited ?? '',
        isEditingEnabled: state.isEditMode || state.isNewSubtitle,
        showOriginalTextField: preferences.showOriginalTextField,
        showOriginalLine: preferences.showOriginalLine,
        
        // Time field state
        startTime: line?.startTime ?? '00:00:00,000',
        endTime: line?.endTime ?? '00:00:05,000',
        isTimeVisible: state.isTimeVisible,
        
        // Character counting state
        maxLineLength: preferences.maxLineLength,
        
        // Video player state
        videoPath: preferences.videoPath ?? state.videoPath,
        isVideoLoaded: (preferences.videoPath ?? state.videoPath) != null,
        isVideoVisible: (preferences.videoPath ?? state.videoPath) != null,
        subtitles: subtitles,
        
        // Secondary subtitles
        secondarySubtitles: state.secondarySubtitles,
        secondarySubtitlesForPlayer: secondarySubtitlesForPlayer,
        showSecondarySubtitles: state.showSecondarySubtitles,
        
        // UI state
        resizeRatio: preferences.resizeRatio,
        mobileVideoResizeRatio: preferences.mobileVideoResizeRatio,
        layoutPreference: preferences.layoutPreference,
        colorHistory: preferences.colorHistory,
        isEditMode: state.isEditMode,
        
        // Preferences
        preferences: preferences,
        
        // Loading & error state
        isLoading: false,
        isInitialized: true,
      ));

      // Trigger initial character count
      _updateCharacterCounts();
    } catch (e, stackTrace) {
      await logError(
        'EditLineCubit: Error during initialization',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineCubit.initialize',
      );

      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize: $e',
      ));
    }
  }

  /// Set up text change streams for debounced character counting
  /// 
  /// This replaces the TextEditingController listeners and timers
  /// with proper stream-based reactive programming using built-in Dart streams
  void _initializeTextStreams() {
    // Original text stream listener
    _originalTextSubscription = _originalTextController.stream.listen((text) {
      _updateCharacterCounts();
    });

    // Edited text stream listener
    _editedTextSubscription = _editedTextController.stream.listen((text) {
      _updateCharacterCounts();
    });
  }

  /// Update original text (called from widget's TextEditingController)
  void updateOriginalText(String text) {
    if (text != state.originalText) {
      emit(state.copyWith(
        originalText: text,
        hasUnsavedChanges: _checkUnsavedChanges(originalText: text),
      ));
      
      // Debounce stream updates
      _originalTextDebounce?.cancel();
      _originalTextDebounce = Timer(const Duration(milliseconds: 100), () {
        _originalTextController.add(text);
      });
    }
  }

  /// Update edited text (called from widget's TextEditingController)
  void updateEditedText(String text) {
    if (text != state.editedText) {
      emit(state.copyWith(
        editedText: text,
        hasUnsavedChanges: _checkUnsavedChanges(editedText: text),
      ));
      
      // Debounce stream updates
      _editedTextDebounce?.cancel();
      _editedTextDebounce = Timer(const Duration(milliseconds: 100), () {
        _editedTextController.add(text);
      });
    }
  }

  /// Update character counts with optimized computation
  /// 
  /// This runs in response to debounced text changes,
  /// preventing excessive calculations and state updates
  Future<void> _updateCharacterCounts() async {
    if (isClosed) return;

    try {
      await logPerformance(
        'Character count calculation',
        () async {
          final counts = _computeCharacterCounts(
            state.originalText,
            state.editedText,
            state.maxLineLength,
          );

          if (!isClosed) {
            emit(state.copyWith(
              originalCharCount: counts['originalCount'],
              editedCharCount: counts['editedCount'],
              originalHasLongLine: counts['originalHasLongLine'] == 1,
              editedHasLongLine: counts['editedHasLongLine'] == 1,
            ));
          }
        },
        context: 'EditLineCubit',
      );
    } catch (e, stackTrace) {
      await logError(
        'Error calculating character counts',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineCubit._updateCharacterCounts',
      );
    }
  }

  /// Compute character counts (same logic as original, but without setState)
  Map<String, int> _computeCharacterCounts(
    String originalText,
    String editedText,
    int maxLineLength,
  ) {
    // Fast normalize and strip tags
    String normalizeAndStripTags(String text) {
      if (text.isEmpty) return '';

      // Replace <br> with newlines (case-insensitive)
      String s = text.replaceAllMapped(
        RegExp(r'<br>', caseSensitive: false),
        (_) => '\n',
      );

      // Remove HTML tags
      s = s.replaceAll(RegExp(r'<[^>]*>'), '');

      // Remove subtitle tags
      s = s.replaceAll(RegExp(r'\{[^}]*\}'), '');

      return s;
    }

    // Fast long line check
    bool hasLongLine(String text) {
      final normalized = normalizeAndStripTags(text);
      if (normalized.isEmpty) return false;

      int lineStart = 0;
      for (int i = 0; i < normalized.length; i++) {
        if (normalized[i] == '\n') {
          if ((i - lineStart) > maxLineLength) return true;
          lineStart = i + 1;
        }
      }
      // Check last line
      return (normalized.length - lineStart) > maxLineLength;
    }

    final strippedOriginal = normalizeAndStripTags(originalText);
    final strippedEdited = normalizeAndStripTags(editedText);

    return {
      'originalCount': strippedOriginal.length,
      'editedCount': strippedEdited.length,
      'originalHasLongLine': hasLongLine(originalText) ? 1 : 0,
      'editedHasLongLine': hasLongLine(editedText) ? 1 : 0,
    };
  }

  /// Update start time
  Future<void> updateStartTime(String time) async {
    emit(state.copyWith(
      startTime: time,
      hasUnsavedChanges: _checkUnsavedChanges(startTime: time),
    ));

    // Validate time
    await _validateTimes();
  }

  /// Update end time
  Future<void> updateEndTime(String time) async {
    emit(state.copyWith(
      endTime: time,
      hasUnsavedChanges: _checkUnsavedChanges(endTime: time),
    ));

    // Validate time
    await _validateTimes();
  }

  /// Validate time fields
  Future<void> _validateTimes() async {
    try {
      // Validate start time format
      final startError = TimeValidator.validateTimeString(state.startTime);
      
      // Validate end time format
      final endError = TimeValidator.validateTimeString(state.endTime);
      
      // Validate time order (start must be < end)
      final orderError = TimeValidator.validateTimeOrder(
        state.startTime,
        state.endTime,
      );

      emit(state.copyWith(
        startTimeError: startError,
        endTimeError: endError,
        timeOrderError: orderError,
        clearStartTimeError: startError == null,
        clearEndTimeError: endError == null,
        clearTimeOrderError: orderError == null,
      ));
    } catch (e, stackTrace) {
      await logError(
        'Error validating times',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineCubit._validateTimes',
      );
    }
  }

  /// Check if there are unsaved changes
  bool _checkUnsavedChanges({
    String? originalText,
    String? editedText,
    String? startTime,
    String? endTime,
  }) {
    final currentOriginal = originalText ?? state.originalText;
    final currentEdited = editedText ?? state.editedText;
    final currentStart = startTime ?? state.startTime;
    final currentEnd = endTime ?? state.endTime;

    return currentOriginal != _initialOriginalText ||
        currentEdited != _initialEditedText ||
        currentStart != _initialStartTime ||
        currentEnd != _initialEndTime;
  }

  /// Save subtitle line to database
  Future<bool> saveSubtitle() async {
    try {
      await logInfo(
        'EditLineCubit: Saving subtitle line',
        context: 'EditLineCubit.saveSubtitle',
      );

      // Validate times first
      if (state.startTimeError != null ||
          state.endTimeError != null ||
          state.timeOrderError != null) {
        await logWarning(
          'Cannot save: Time validation errors present',
          context: 'EditLineCubit.saveSubtitle',
        );
        return false;
      }

      final success = await logPerformance(
        'Save subtitle line',
        () => _repository.updateSubtitleLine(
          collectionId: _subtitleCollectionId,
          lineIndex: state.subtitleLine!.index,
          originalText: state.originalText,
          editedText: state.editedText,
          startTime: state.startTime,
          endTime: state.endTime,
        ),
        context: 'EditLineCubit',
      );

      if (success) {
        // Update initial values to reflect saved state
        _initialOriginalText = state.originalText;
        _initialEditedText = state.editedText;
        _initialStartTime = state.startTime;
        _initialEndTime = state.endTime;

        emit(state.copyWith(hasUnsavedChanges: false));

        await logInfo(
          'EditLineCubit: Subtitle line saved successfully',
          context: 'EditLineCubit.saveSubtitle',
        );
      }

      return success;
    } catch (e, stackTrace) {
      await logError(
        'EditLineCubit: Error saving subtitle',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineCubit.saveSubtitle',
      );
      return false;
    }
  }

  /// Navigate to next subtitle line
  Future<void> navigateNext() async {
    if (state.subtitleLine == null) return;

    final currentIndex = state.subtitleLine!.index;
    final totalLines = state.subtitleCollection?.lines.length ?? 0;

    if (currentIndex < totalLines) {
      await navigateToLine(currentIndex + 1);
    }
  }

  /// Navigate to previous subtitle line
  Future<void> navigatePrevious() async {
    if (state.subtitleLine == null) return;

    final currentIndex = state.subtitleLine!.index;

    if (currentIndex > 1) {
      await navigateToLine(currentIndex - 1);
    }
  }

  /// Navigate to specific line
  Future<void> navigateToLine(int lineIndex) async {
    try {
      await logInfo(
        'EditLineCubit: Navigating to line $lineIndex',
        context: 'EditLineCubit.navigateToLine',
      );

      emit(state.copyWith(isLoading: true));

      final line = await _repository.fetchSubtitleLine(
        _subtitleCollectionId,
        lineIndex,
      );

      if (line == null) {
        throw Exception('Subtitle line not found at index $lineIndex');
      }

      // Store new initial values
      _initialOriginalText = line.original;
      _initialEditedText = line.edited ?? '';
      _initialStartTime = line.startTime;
      _initialEndTime = line.endTime;

      // Clear validation errors when loading new line
      emit(state.copyWith(
        subtitleLine: line,
        originalText: line.original,
        editedText: line.edited ?? '',
        startTime: line.startTime,
        endTime: line.endTime,
        hasUnsavedChanges: false,
        isLoading: false,
        clearStartTimeError: true,
        clearEndTimeError: true,
        clearTimeOrderError: true,
      ));

      // Update character counts for new line
      _updateCharacterCounts();

      await logInfo(
        'EditLineCubit: Navigation complete to line $lineIndex',
        context: 'EditLineCubit.navigateToLine',
      );
    } catch (e, stackTrace) {
      await logError(
        'EditLineCubit: Error navigating to line $lineIndex',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineCubit.navigateToLine',
      );

      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to navigate to line $lineIndex',
      ));
    }
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(clearErrorMessage: true));
  }

  /// Reload all preferences
  Future<void> reloadPreferences() async {
    try {
      await logInfo(
        'EditLineCubit: Reloading preferences',
        context: 'EditLineCubit.reloadPreferences',
      );

      final preferences = await _repository.loadAllPreferences(
        _subtitleCollectionId,
      );

      emit(state.copyWith(
        preferences: preferences,
        maxLineLength: preferences.maxLineLength,
        showOriginalTextField: preferences.showOriginalTextField,
        showOriginalLine: preferences.showOriginalLine,
        resizeRatio: preferences.resizeRatio,
        mobileVideoResizeRatio: preferences.mobileVideoResizeRatio,
        layoutPreference: preferences.layoutPreference,
        colorHistory: preferences.colorHistory,
      ));

      // Recalculate character counts with new max line length
      _updateCharacterCounts();
    } catch (e, stackTrace) {
      await logError(
        'EditLineCubit: Error reloading preferences',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineCubit.reloadPreferences',
      );
    }
  }

  @override
  Future<void> close() async {
    await logInfo(
      'EditLineCubit: Closing and cleaning up resources',
      context: 'EditLineCubit.close',
    );

    // Cancel all timers
    _originalTextDebounce?.cancel();
    _editedTextDebounce?.cancel();
    _repeatPlaybackTimer?.cancel();

    // Cancel all stream subscriptions
    await _originalTextSubscription?.cancel();
    await _editedTextSubscription?.cancel();
    
    // Close stream controllers
    await _originalTextController.close();
    await _editedTextController.close();

    return super.close();
  }
}

/// Time validator utility
class TimeValidator {
  /// Validate time string format (HH:mm:ss,SSS)
  static String? validateTimeString(String time) {
    if (time.isEmpty) return 'Time cannot be empty';

    final regex = RegExp(r'^\d{2}:\d{2}:\d{2},\d{3}$');
    if (!regex.hasMatch(time)) {
      return 'Invalid time format (expected HH:mm:ss,SSS)';
    }

    // Parse and validate ranges
    try {
      final parts = time.split(',');
      final hms = parts[0].split(':');
      final hours = int.parse(hms[0]);
      final minutes = int.parse(hms[1]);
      final seconds = int.parse(hms[2]);
      final milliseconds = int.parse(parts[1]);

      if (hours > 23) return 'Hours must be 0-23';
      if (minutes > 59) return 'Minutes must be 0-59';
      if (seconds > 59) return 'Seconds must be 0-59';
      if (milliseconds > 999) return 'Milliseconds must be 0-999';

      return null; // Valid
    } catch (e) {
      return 'Invalid time values';
    }
  }

  /// Validate that start time is before end time
  static String? validateTimeOrder(String startTime, String endTime) {
    try {
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);

      if (start >= end) {
        return 'Start time must be before end time';
      }

      return null; // Valid
    } catch (e) {
      return 'Cannot compare times';
    }
  }

  /// Parse time string to Duration for comparison
  static Duration _parseTime(String time) {
    final parts = time.split(',');
    final hms = parts[0].split(':');
    final hours = int.parse(hms[0]);
    final minutes = int.parse(hms[1]);
    final seconds = int.parse(hms[2]);
    final milliseconds = int.parse(parts[1]);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}
