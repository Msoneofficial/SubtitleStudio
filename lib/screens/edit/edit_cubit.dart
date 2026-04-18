import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/screens/edit/edit_state.dart';
import 'package:subtitle_studio/screens/edit/repositories/subtitle_repository.dart';
import 'package:subtitle_studio/screens/edit/repositories/screen_repository.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';
import 'package:subtitle_studio/widgets/video_player_widget.dart';
import 'package:subtitle_studio/utils/subtitle_parser.dart';
import 'package:subtitle_studio/screens/screen_edit.dart'; // For SubtitleEntry

/// Cubit for managing the Edit Screen state
/// 
/// This Cubit encapsulates all business logic for the edit screen,
/// following the BLoC pattern for state management. It communicates
/// with SubtitleRepository and VideoRepository to fetch and manipulate data.
/// 
/// Key Responsibilities:
/// - Load and manage subtitle lines
/// - Handle video player integration
/// - Manage selection mode (single, range, all)
/// - Handle marking and commenting
/// - Manage source view mode
/// - Handle secondary subtitles
/// - Coordinate checkpoint operations
/// - Manage UI preferences (floating controls, MSone features, layout)
/// - Error handling and comprehensive logging
/// 
/// State Flow:
/// 1. Initial loading state
/// 2. Emit loaded state with subtitle lines
/// 3. Update state based on user actions (edit, delete, mark, select)
/// 4. Emit error state on failures
class EditCubit extends Cubit<EditState> {
  final SubtitleRepository _subtitleRepo;
  final VideoRepository _videoRepo;
  final int subtitleCollectionId;
  final int sessionId;

  EditCubit({
    required this.subtitleCollectionId,
    required this.sessionId,
    SubtitleRepository? subtitleRepository,
    VideoRepository? videoRepository,
  })  : _subtitleRepo = subtitleRepository ?? SubtitleRepository(),
        _videoRepo = videoRepository ?? VideoRepository(),
        super(EditState.initial()) {
    logInfo('EditCubit: Initialized for collection $subtitleCollectionId, session $sessionId');
  }

  /// Initialize the edit screen
  /// 
  /// Loads:
  /// 1. Subtitle collection metadata
  /// 2. Subtitle lines
  /// 3. Video path (if saved)
  /// 4. Secondary subtitles (if configured)
  /// 5. Preferences (floating controls, MSone, layout, resize ratio)
  Future<void> initialize({int? lastEditedIndex}) async {
    try {
      logInfo('EditCubit: Starting initialization');
      
      emit(state.copyWith(isLoading: true, errorMessage: null));

      // Load subtitle collection
      final collection = await _subtitleRepo.fetchSubtitleCollection(subtitleCollectionId);
      if (collection == null) {
        throw Exception('Subtitle collection not found: $subtitleCollectionId');
      }

      // Load subtitle lines
      final lines = await _subtitleRepo.fetchLines(subtitleCollectionId);
      
      // Generate subtitles for video player
      final generatedSubtitles = _subtitleRepo.generateSubtitles(lines);

      // Load video path
      final videoPath = await _videoRepo.getSavedVideoPath(subtitleCollectionId);
      final isVideoLoaded = videoPath != null;

      // Load secondary subtitles if configured
      List<Subtitle> secondarySubtitles = [];
      List<SimpleSubtitleLine> originalSecondarySubtitles = [];
      final secondaryData = await _videoRepo.loadSavedSecondarySubtitle(subtitleCollectionId);
      
      if (secondaryData != null) {
        if (secondaryData.useOriginal) {
          // Use original text as secondary
          originalSecondarySubtitles = lines.map((line) {
            return SimpleSubtitleLine(
              index: line.index,
              startTime: line.startTime,
              endTime: line.endTime,
              text: line.original,
            );
          }).toList();
          secondarySubtitles = _subtitleRepo.generateSimpleSubtitles(originalSecondarySubtitles);
        } else if (secondaryData.subtitles != null) {
          // Use external subtitle file
          originalSecondarySubtitles = secondaryData.subtitles!;
          secondarySubtitles = _subtitleRepo.generateSimpleSubtitles(originalSecondarySubtitles);
        }
      }

      // Load preferences
      final floatingControlsEnabled = await _videoRepo.getFloatingControlsEnabled();
      final isMsoneEnabled = await _videoRepo.getMsoneEnabled();
      final layout = await _videoRepo.getLayoutPreference();
      final resizeRatio = await _videoRepo.getEditScreenResizeRatio();
      final mobileResizeRatio = await _videoRepo.getMobileVideoResizeRatio();

      // Create initial checkpoint (non-critical, continue if it fails)
      try {
        await _subtitleRepo.createInitialSnapshot(sessionId, subtitleCollectionId);
      } catch (e) {
        logWarning('Could not create initial checkpoint: $e');
        // Continue without checkpoint - this is not critical for basic functionality
      }

      logInfo('EditCubit: Loaded ${lines.length} subtitle lines');

      emit(EditState(
        subtitleCollection: collection,
        subtitleLines: lines,
        generatedSubtitles: generatedSubtitles,
        selectedVideoPath: videoPath,
        isVideoLoaded: isVideoLoaded,
        secondarySubtitles: secondarySubtitles,
        originalSecondarySubtitles: originalSecondarySubtitles,
        highlightedIndex: lastEditedIndex,
        floatingControlsEnabled: floatingControlsEnabled,
        isMsoneEnabled: isMsoneEnabled,
        isLayout1: layout == 'layout1',
        resizeRatio: resizeRatio,
        mobileVideoResizeRatio: mobileResizeRatio,
        isLoading: false,
      ));

      logInfo('EditCubit: Initialization complete');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error during initialization',
        context: 'initialize',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize: $e',
      ));
    }
  }

  /// Refresh subtitle lines from database
  /// 
  /// Used after operations that modify the database directly
  /// (e.g., checkpoint restore, batch operations)
  Future<void> refreshSubtitleLines() async {
    try {
      logInfo('EditCubit: Refreshing subtitle lines');

      final lines = await _subtitleRepo.fetchLines(subtitleCollectionId);
      final generatedSubtitles = _subtitleRepo.generateSubtitles(lines);

      // Update secondary subtitles if using original text
      List<Subtitle> secondarySubtitles = state.secondarySubtitles;
      List<SimpleSubtitleLine> originalSecondarySubtitles = state.originalSecondarySubtitles;
      
      if (state.showSecondarySubtitles && originalSecondarySubtitles.isNotEmpty) {
        // Check if using original text (by comparing first line)
        final isUsingOriginal = lines.isNotEmpty && 
            originalSecondarySubtitles.isNotEmpty &&
            originalSecondarySubtitles.first.text == lines.first.original;
        
        if (isUsingOriginal) {
          // Regenerate secondary from updated original text
          originalSecondarySubtitles = lines.map((line) {
            return SimpleSubtitleLine(
              index: line.index,
              startTime: line.startTime,
              endTime: line.endTime,
              text: line.original,
            );
          }).toList();
          secondarySubtitles = _subtitleRepo.generateSimpleSubtitles(originalSecondarySubtitles);
        }
      }

      emit(state.copyWith(
        subtitleLines: lines,
        generatedSubtitles: generatedSubtitles,
        secondarySubtitles: secondarySubtitles,
        originalSecondarySubtitles: originalSecondarySubtitles,
      ));

      logInfo('EditCubit: Refreshed ${lines.length} subtitle lines');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error refreshing subtitle lines',
        context: 'refreshSubtitleLines',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Mark a subtitle line (toggle marked status)
  Future<void> markLine(int index) async {
    try {
      logInfo('EditCubit: Marking line at index $index');

      final line = state.subtitleLines[index];
      final newMarkedStatus = !line.marked;

      await _subtitleRepo.markLine(subtitleCollectionId, index, newMarkedStatus);

      // Update local state
      final updatedLines = List<SubtitleLine>.from(state.subtitleLines);
      updatedLines[index] = SubtitleLine()
        ..index = line.index
        ..startTime = line.startTime
        ..endTime = line.endTime
        ..original = line.original
        ..edited = line.edited
        ..marked = newMarkedStatus
        ..comment = line.comment
        ..resolved = line.resolved;

      emit(state.copyWith(subtitleLines: updatedLines));

      logInfo('EditCubit: Line marked status: $newMarkedStatus');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error marking line',
        context: 'markLine',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update comment for a subtitle line
  Future<void> updateComment(int index, String? comment) async {
    try {
      logInfo('EditCubit: Updating comment for line at index $index');

      final line = state.subtitleLines[index];

      await _subtitleRepo.updateComment(subtitleCollectionId, index, comment);

      // Update local state
      final updatedLines = List<SubtitleLine>.from(state.subtitleLines);
      updatedLines[index] = SubtitleLine()
        ..index = line.index
        ..startTime = line.startTime
        ..endTime = line.endTime
        ..original = line.original
        ..edited = line.edited
        ..marked = line.marked
        ..comment = comment
        ..resolved = line.resolved;

      emit(state.copyWith(subtitleLines: updatedLines));

      logInfo('EditCubit: Comment updated');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error updating comment',
        context: 'updateComment',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete a single subtitle line with checkpoint
  Future<void> deleteLine(int index) async {
    try {
      logInfo('EditCubit: Deleting line at index $index');

      await _subtitleRepo.deleteLine(subtitleCollectionId, index);

      // Refresh to get updated lines
      await refreshSubtitleLines();

      logInfo('EditCubit: Line deleted');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error deleting line',
        context: 'deleteLine',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        errorMessage: 'Failed to delete line: $e',
      ));
    }
  }

  /// Delete multiple selected lines with checkpoint
  Future<void> deleteSelectedLines() async {
    try {
      logInfo('EditCubit: Deleting ${state.selectedIndices.length} selected lines');

      if (state.selectedIndices.isEmpty) {
        logWarning('EditCubit: No lines selected for deletion');
        return;
      }

      // Convert selected indices to list
      final indices = state.selectedIndices.toList();

      await _subtitleRepo.batchDeleteLines(subtitleCollectionId, indices);

      // Clear selection and refresh
      emit(state.copyWith(
        selectedIndices: {},
        isSelectionMode: false,
        isRangeSelectionActive: false,
      ));

      await refreshSubtitleLines();

      logInfo('EditCubit: Selected lines deleted');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error deleting selected lines',
        context: 'deleteSelectedLines',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        errorMessage: 'Failed to delete selected lines: $e',
      ));
    }
  }

  /// Toggle selection for a subtitle line
  void toggleSelection(int index) {
    logInfo('EditCubit: Toggling selection for index $index');

    final newState = state.toggleSelection(index);
    emit(newState);

    logInfo('EditCubit: Selection mode: ${newState.isSelectionMode}, selected: ${newState.selectedIndices.length}');
  }

  /// Clear all selections
  void clearSelection() {
    logInfo('EditCubit: Clearing all selections');

    emit(state.clearSelection());
  }

  /// Select all subtitle lines
  void selectAll() {
    logInfo('EditCubit: Selecting all ${state.subtitleLines.length} lines');

    final allIndices = List.generate(state.subtitleLines.length, (i) => i).toSet();
    
    emit(state.copyWith(
      selectedIndices: allIndices,
      isSelectionMode: true,
    ));
  }

  /// Navigate to a specific index (for video sync and goto)
  void navigateToIndex(int index) {
    logInfo('EditCubit: Navigating to index $index');

    if (index < 0 || index >= state.subtitleLines.length) {
      logWarning('EditCubit: Invalid navigation index: $index');
      return;
    }

    emit(state.copyWith(highlightedIndex: index));
  }

  /// Toggle card expansion state
  void toggleCardExpansion(int index) {
    logInfo('EditCubit: Toggling card expansion for index $index');

    final newState = state.toggleCardExpansion(index);
    emit(newState);
  }

  /// Load video from path
  Future<void> loadVideo(String videoPath, {Duration? lastPosition}) async {
    try {
      logInfo('EditCubit: Loading video from: $videoPath');

      // Save video path
      await _videoRepo.saveVideoPath(subtitleCollectionId, videoPath);

      emit(state.copyWith(
        selectedVideoPath: videoPath,
        isVideoLoaded: true,
        lastVideoPosition: lastPosition,
      ));

      logInfo('EditCubit: Video loaded successfully');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error loading video',
        context: 'loadVideo',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        errorMessage: 'Failed to load video: $e',
      ));
    }
  }

  /// Unload video and clear saved path
  Future<void> unloadVideo() async {
    try {
      logInfo('EditCubit: Unloading video');

      await _videoRepo.removeVideoPath(subtitleCollectionId);

      emit(state.copyWith(
        selectedVideoPath: null,
        isVideoLoaded: false,
        lastVideoPosition: Duration.zero,
      ));

      logInfo('EditCubit: Video unloaded successfully');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error unloading video',
        context: 'unloadVideo',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update video position (for restoration)
  void updateVideoPosition(Duration position) {
    emit(state.copyWith(lastVideoPosition: position));
  }

  /// Toggle secondary subtitles visibility
  void toggleSecondarySubtitles() {
    logInfo('EditCubit: Toggling secondary subtitles');

    final newShowState = !state.showSecondarySubtitles;
    emit(state.copyWith(showSecondarySubtitles: newShowState));

    logInfo('EditCubit: Secondary subtitles visible: $newShowState');
  }

  /// Load secondary subtitle from external file
  Future<void> loadSecondarySubtitleFromFile(String path) async {
    try {
      logInfo('EditCubit: Loading secondary subtitle from file: $path');

      final secondaryData = await _videoRepo.saveAndLoadSecondarySubtitle(
        subtitleCollectionId,
        path,
      );

      final secondarySubtitles = _subtitleRepo.generateSimpleSubtitles(
        secondaryData.subtitles!,
      );

      emit(state.copyWith(
        originalSecondarySubtitles: secondaryData.subtitles,
        secondarySubtitles: secondarySubtitles,
        showSecondarySubtitles: true,
      ));

      logInfo('EditCubit: Secondary subtitle loaded from file');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error loading secondary subtitle',
        context: 'loadSecondarySubtitleFromFile',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        errorMessage: 'Failed to load secondary subtitle: $e',
      ));
    }
  }

  /// Use original text as secondary subtitle
  Future<void> useOriginalAsSecondary() async {
    try {
      logInfo('EditCubit: Using original text as secondary subtitle');

      await _videoRepo.setUseOriginalAsSecondary(subtitleCollectionId, true);

      final originalSecondarySubtitles = state.subtitleLines.map((line) {
        return SimpleSubtitleLine(
          index: line.index,
          startTime: line.startTime,
          endTime: line.endTime,
          text: line.original,
        );
      }).toList();

      final secondarySubtitles = _subtitleRepo.generateSimpleSubtitles(
        originalSecondarySubtitles,
      );

      emit(state.copyWith(
        originalSecondarySubtitles: originalSecondarySubtitles,
        secondarySubtitles: secondarySubtitles,
        showSecondarySubtitles: true,
      ));

      logInfo('EditCubit: Original text set as secondary subtitle');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error setting original as secondary',
        context: 'useOriginalAsSecondary',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        errorMessage: 'Failed to use original as secondary: $e',
      ));
    }
  }

  /// Clear secondary subtitles
  Future<void> clearSecondarySubtitles() async {
    try {
      logInfo('EditCubit: Clearing secondary subtitles');

      await _videoRepo.clearSecondarySubtitle(subtitleCollectionId);

      emit(state.copyWith(
        originalSecondarySubtitles: [],
        secondarySubtitles: [],
        showSecondarySubtitles: false,
      ));

      logInfo('EditCubit: Secondary subtitles cleared');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error clearing secondary subtitles',
        context: 'clearSecondarySubtitles',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Switch to source view mode
  void switchToSourceView() {
    logInfo('EditCubit: Switching to source view mode');

    if (state.isSourceView) {
      logWarning('EditCubit: Already in source view mode');
      return;
    }

    // Convert subtitle lines to source view entries
    final sourceViewEntries = _subtitleRepo.convertToSourceViewEntries(
      state.subtitleLines,
    );

    emit(state.copyWith(
      isSourceView: true,
      sourceViewEntries: sourceViewEntries,
    ));

    logInfo('EditCubit: Switched to source view mode');
  }

  /// Switch back to cards view mode
  void switchToCardsView() {
    logInfo('EditCubit: Switching to cards view mode');

    if (!state.isSourceView) {
      logWarning('EditCubit: Already in cards view mode');
      return;
    }

    emit(state.copyWith(
      isSourceView: false,
      sourceViewEntries: [],
    ));

    logInfo('EditCubit: Switched to cards view mode');
  }

  /// Sync source view changes back to database
  Future<void> syncSourceViewToDatabase(List<SubtitleEntry> entries) async {
    try {
      logInfo('EditCubit: Syncing source view changes to database');

      await _subtitleRepo.syncSourceViewToDatabase(
        subtitleCollectionId,
        entries,
      );

      // Refresh subtitle lines and return to cards view
      await refreshSubtitleLines();
      
      emit(state.copyWith(
        isSourceView: false,
        sourceViewEntries: [],
      ));

      logInfo('EditCubit: Source view synced to database');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error syncing source view',
        context: 'syncSourceViewToDatabase',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        errorMessage: 'Failed to sync source view: $e',
      ));
    }
  }

  /// Update floating controls preference
  Future<void> updateFloatingControls(bool enabled) async {
    logInfo('EditCubit: Updating floating controls: $enabled');

    await _videoRepo.saveFloatingControlsEnabled(enabled);
    emit(state.copyWith(floatingControlsEnabled: enabled));
  }

  /// Update MSone features preference
  Future<void> updateMsoneFeatures(bool enabled) async {
    logInfo('EditCubit: Updating MSone features: $enabled');

    await _videoRepo.saveMsoneEnabled(enabled);
    emit(state.copyWith(isMsoneEnabled: enabled));
  }

  /// Update layout preference
  Future<void> updateLayout(bool isLayout1) async {
    logInfo('EditCubit: Updating layout: ${isLayout1 ? 'layout1' : 'layout2'}');

    await _videoRepo.saveLayoutPreference(isLayout1 ? 'layout1' : 'layout2');
    emit(state.copyWith(isLayout1: isLayout1));
  }

  /// Update resize ratio
  Future<void> updateResizeRatio(double ratio) async {
    logInfo('EditCubit: Updating resize ratio: $ratio');

    await _videoRepo.saveEditScreenResizeRatio(ratio);
    emit(state.copyWith(resizeRatio: ratio));
  }

  /// Update mobile video resize ratio
  Future<void> updateMobileResizeRatio(double ratio) async {
    logInfo('EditCubit: Updating mobile resize ratio: $ratio');

    await _videoRepo.saveMobileVideoResizeRatio(ratio);
    emit(state.copyWith(mobileVideoResizeRatio: ratio));
  }

  /// Update last edited session timestamp
  Future<void> updateLastEditedSession() async {
    try {
      await _subtitleRepo.updateLastEditedSession(sessionId);
      logInfo('EditCubit: Updated last edited session timestamp');
    } catch (e) {
      logWarning('EditCubit: Failed to update last edited session: $e');
    }
  }

  /// Reload preferences from database
  /// 
  /// Call this method when preferences are changed externally (e.g., from settings sheet)
  /// to sync the cubit state with the latest database values
  Future<void> reloadPreferences() async {
    try {
      logInfo('EditCubit: Reloading preferences from database');
      
      final floatingControlsEnabled = await _videoRepo.getFloatingControlsEnabled();
      final isMsoneEnabled = await _videoRepo.getMsoneEnabled();
      final layout = await _videoRepo.getLayoutPreference();
      final resizeRatio = await _videoRepo.getEditScreenResizeRatio();
      
      emit(state.copyWith(
        floatingControlsEnabled: floatingControlsEnabled,
        isMsoneEnabled: isMsoneEnabled,
        isLayout1: layout == 'layout1',
        resizeRatio: resizeRatio,
      ));
      
      logInfo('EditCubit: Preferences reloaded successfully');
    } catch (e, stackTrace) {
      logError(
        'EditCubit: Error reloading preferences',
        context: 'reloadPreferences',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}

