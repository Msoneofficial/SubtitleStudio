import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/widgets/video_player_widget.dart'; // For Subtitle
import 'package:subtitle_studio/utils/subtitle_parser.dart'; // For SimpleSubtitleLine
import '../screen_edit.dart'; // For SubtitleEntry

/// Immutable state model for the EditScreen
/// 
/// This class represents all the UI state for the subtitle editor,
/// following clean architecture and BLoC pattern principles.
@immutable
class EditState extends Equatable {
  // Core subtitle data
  final SubtitleCollection? subtitleCollection;
  final List<SubtitleLine> subtitleLines;
  final List<Subtitle> generatedSubtitles;
  final String? fileName;
  
  // Loading states
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;
  
  // Video state
  final String? selectedVideoPath;
  final bool isVideoVisible;
  final bool isVideoLoaded;
  final Duration lastVideoPosition;
  
  // Secondary subtitles
  final List<Subtitle> secondarySubtitles;
  final List<SimpleSubtitleLine> originalSecondarySubtitles;
  final bool showSecondarySubtitles;
  
  // UI state - highlighting and navigation
  final int? highlightedIndex;
  final Map<int, bool> expandedCards;
  
  // Selection mode
  final bool isSelectionMode;
  final Set<int> selectedIndices;
  final bool isRangeSelectionActive;
  final int? rangeStartIndex;
  
  // Preferences
  final bool floatingControlsEnabled;
  final bool isMsoneEnabled;
  final double resizeRatio;
  final bool isResizeRatioLoaded;
  final double mobileVideoResizeRatio;
  final bool isMobileResizeRatioLoaded;
  
  // View mode
  final bool isSourceView;
  final List<SubtitleEntry> sourceViewEntries;
  
  // Layout preference
  final bool isLayout1;
  
  // Navigation debouncing
  final bool isNavigating;

  const EditState({
    this.subtitleCollection,
    this.subtitleLines = const [],
    this.generatedSubtitles = const [],
    this.fileName,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
    this.selectedVideoPath,
    this.isVideoVisible = false,
    this.isVideoLoaded = false,
    this.lastVideoPosition = Duration.zero,
    this.secondarySubtitles = const [],
    this.originalSecondarySubtitles = const [],
    this.showSecondarySubtitles = true,
    this.highlightedIndex,
    this.expandedCards = const {},
    this.isSelectionMode = false,
    this.selectedIndices = const {},
    this.isRangeSelectionActive = false,
    this.rangeStartIndex,
    this.floatingControlsEnabled = false,
    this.isMsoneEnabled = false,
    this.resizeRatio = 0.35,
    this.isResizeRatioLoaded = false,
    this.mobileVideoResizeRatio = 0.4,
    this.isMobileResizeRatioLoaded = false,
    this.isSourceView = false,
    this.sourceViewEntries = const [],
    this.isLayout1 = true,
    this.isNavigating = false,
  });

  /// Initial state factory
  factory EditState.initial() {
    return const EditState(
      isLoading: true,
      isInitialized: false,
    );
  }

  /// Create a copy with modified fields
  EditState copyWith({
    SubtitleCollection? subtitleCollection,
    List<SubtitleLine>? subtitleLines,
    List<Subtitle>? generatedSubtitles,
    String? fileName,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    String? selectedVideoPath,
    bool? isVideoVisible,
    bool? isVideoLoaded,
    Duration? lastVideoPosition,
    List<Subtitle>? secondarySubtitles,
    List<SimpleSubtitleLine>? originalSecondarySubtitles,
    bool? showSecondarySubtitles,
    int? highlightedIndex,
    Map<int, bool>? expandedCards,
    bool? isSelectionMode,
    Set<int>? selectedIndices,
    bool? isRangeSelectionActive,
    int? rangeStartIndex,
    bool? floatingControlsEnabled,
    bool? isMsoneEnabled,
    double? resizeRatio,
    bool? isResizeRatioLoaded,
    double? mobileVideoResizeRatio,
    bool? isMobileResizeRatioLoaded,
    bool? isSourceView,
    List<SubtitleEntry>? sourceViewEntries,
    bool? isLayout1,
    bool? isNavigating,
  }) {
    return EditState(
      subtitleCollection: subtitleCollection ?? this.subtitleCollection,
      subtitleLines: subtitleLines ?? this.subtitleLines,
      generatedSubtitles: generatedSubtitles ?? this.generatedSubtitles,
      fileName: fileName ?? this.fileName,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage,
      selectedVideoPath: selectedVideoPath ?? this.selectedVideoPath,
      isVideoVisible: isVideoVisible ?? this.isVideoVisible,
      isVideoLoaded: isVideoLoaded ?? this.isVideoLoaded,
      lastVideoPosition: lastVideoPosition ?? this.lastVideoPosition,
      secondarySubtitles: secondarySubtitles ?? this.secondarySubtitles,
      originalSecondarySubtitles: originalSecondarySubtitles ?? this.originalSecondarySubtitles,
      showSecondarySubtitles: showSecondarySubtitles ?? this.showSecondarySubtitles,
      highlightedIndex: highlightedIndex,
      expandedCards: expandedCards ?? this.expandedCards,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      isRangeSelectionActive: isRangeSelectionActive ?? this.isRangeSelectionActive,
      rangeStartIndex: rangeStartIndex,
      floatingControlsEnabled: floatingControlsEnabled ?? this.floatingControlsEnabled,
      isMsoneEnabled: isMsoneEnabled ?? this.isMsoneEnabled,
      resizeRatio: resizeRatio ?? this.resizeRatio,
      isResizeRatioLoaded: isResizeRatioLoaded ?? this.isResizeRatioLoaded,
      mobileVideoResizeRatio: mobileVideoResizeRatio ?? this.mobileVideoResizeRatio,
      isMobileResizeRatioLoaded: isMobileResizeRatioLoaded ?? this.isMobileResizeRatioLoaded,
      isSourceView: isSourceView ?? this.isSourceView,
      sourceViewEntries: sourceViewEntries ?? this.sourceViewEntries,
      isLayout1: isLayout1 ?? this.isLayout1,
      isNavigating: isNavigating ?? this.isNavigating,
    );
  }

  /// Clear error message
  EditState clearError() {
    return copyWith(errorMessage: null);
  }

  /// Toggle selection for an index
  EditState toggleSelection(int index) {
    final newSelection = Set<int>.from(selectedIndices);
    if (newSelection.contains(index)) {
      newSelection.remove(index);
    } else {
      newSelection.add(index);
    }
    return copyWith(
      selectedIndices: newSelection,
      isSelectionMode: newSelection.isNotEmpty,
    );
  }

  /// Clear all selections
  EditState clearSelection() {
    return copyWith(
      selectedIndices: {},
      isSelectionMode: false,
      isRangeSelectionActive: false,
      rangeStartIndex: null,
    );
  }

  /// Toggle card expansion
  EditState toggleCardExpansion(int index) {
    final newExpanded = Map<int, bool>.from(expandedCards);
    newExpanded[index] = !(newExpanded[index] ?? false);
    return copyWith(expandedCards: newExpanded);
  }

  @override
  List<Object?> get props => [
        subtitleCollection,
        subtitleLines,
        generatedSubtitles,
        fileName,
        isLoading,
        isInitialized,
        errorMessage,
        selectedVideoPath,
        isVideoVisible,
        isVideoLoaded,
        lastVideoPosition,
        secondarySubtitles,
        originalSecondarySubtitles,
        showSecondarySubtitles,
        highlightedIndex,
        expandedCards,
        isSelectionMode,
        selectedIndices,
        isRangeSelectionActive,
        rangeStartIndex,
        floatingControlsEnabled,
        isMsoneEnabled,
        resizeRatio,
        isResizeRatioLoaded,
        mobileVideoResizeRatio,
        isMobileResizeRatioLoaded,
        isSourceView,
        sourceViewEntries,
        isLayout1,
        isNavigating,
      ];
}
