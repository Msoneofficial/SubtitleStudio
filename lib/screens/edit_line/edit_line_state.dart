import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/widgets/video_player_widget.dart'; // For Subtitle
import 'package:subtitle_studio/utils/subtitle_parser.dart'; // For SimpleSubtitleLine
import 'package:subtitle_studio/screens/edit_line/repositories/edit_line_repository.dart'; // For EditLinePreferences

/// Immutable state model for EditLineScreen
/// 
/// This class represents all the UI state for single subtitle line editing,
/// following clean architecture and BLoC pattern principles.
/// 
/// State is organized into logical groups to reduce complexity:
/// - Core data (subtitle line, collection)
/// - Text field state
/// - Time field state
/// - Video player state
/// - Character counting state
/// - Validation state
/// - Preferences
/// - UI state flags
@immutable
class EditLineState extends Equatable {
  // ============================================
  // CORE DATA
  // ============================================
  
  /// The current subtitle line being edited
  final SubtitleLine? subtitleLine;
  
  /// The subtitle collection metadata
  final SubtitleCollection? subtitleCollection;
  
  /// Whether this is a new subtitle being created
  final bool isNewSubtitle;
  
  /// Session ID for checkpoint management
  final int sessionId;
  
  // ============================================
  // TEXT FIELD STATE
  // ============================================
  
  /// Original text content
  final String originalText;
  
  /// Edited text content
  final String editedText;
  
  /// Whether editing is enabled
  final bool isEditingEnabled;
  
  /// Whether to show original text field
  final bool showOriginalTextField;
  
  /// Whether to show original line when edited is empty
  final bool showOriginalLine;
  
  /// Whether raw mode is enabled (show formatting tags)
  final bool isRawEnabled;
  
  // ============================================
  // TIME FIELD STATE
  // ============================================
  
  /// Start time string (HH:mm:ss,SSS)
  final String startTime;
  
  /// End time string (HH:mm:ss,SSS)
  final String endTime;
  
  /// Whether time fields are visible
  final bool isTimeVisible;
  
  // ============================================
  // VALIDATION STATE
  // ============================================
  
  /// Validation error for start time field
  final String? startTimeError;
  
  /// Validation error for end time field
  final String? endTimeError;
  
  /// Validation error for time order (start must be < end)
  final String? timeOrderError;
  
  /// Whether there are unsaved changes
  final bool hasUnsavedChanges;
  
  // ============================================
  // CHARACTER COUNTING STATE
  // ============================================
  
  /// Character count for original text (without tags)
  final int originalCharCount;
  
  /// Character count for edited text (without tags)
  final int editedCharCount;
  
  /// Whether original text has lines exceeding max length
  final bool originalHasLongLine;
  
  /// Whether edited text has lines exceeding max length
  final bool editedHasLongLine;
  
  /// Maximum characters per line (from preferences)
  final int maxLineLength;
  
  // ============================================
  // VIDEO PLAYER STATE
  // ============================================
  
  /// Path to the selected video file
  final String? videoPath;
  
  /// Whether video is loaded
  final bool isVideoLoaded;
  
  /// Whether video player is visible
  final bool isVideoVisible;
  
  /// Whether video is currently playing
  final bool isVideoPlaying;
  
  /// Generated subtitles for video player
  final List<Subtitle> subtitles;
  
  /// Whether repeat mode is enabled
  final bool isRepeatModeEnabled;
  
  /// Whether custom range repeat mode is active
  final bool isCustomRangeMode;
  
  /// Start index for custom range repeat
  final int? customRangeStartIndex;
  
  /// End index for custom range repeat
  final int? customRangeEndIndex;
  
  // ============================================
  // SECONDARY SUBTITLES
  // ============================================
  
  /// Secondary subtitle lines (for dual subtitle display)
  final List<SimpleSubtitleLine> secondarySubtitles;
  
  /// Generated secondary subtitles for video player
  final List<Subtitle> secondarySubtitlesForPlayer;
  
  /// Whether to show secondary subtitles
  final bool showSecondarySubtitles;
  
  // ============================================
  // UI STATE
  // ============================================
  
  /// Whether keyboard is visible
  final bool isKeyboardVisible;
  
  /// Resize ratio for desktop layout (0.0 to 1.0)
  final double resizeRatio;
  
  /// Resize ratio for mobile video player (0.0 to 1.0)
  final double mobileVideoResizeRatio;
  
  /// Layout preference for desktop ('layout1' or 'layout2')
  final String layoutPreference;
  
  /// Color history for color picker
  final List<Color> colorHistory;
  
  /// Whether edit mode is active (vs translation mode)
  final bool isEditMode;
  
  // ============================================
  // PREFERENCES
  // ============================================
  
  /// All preferences bundled together
  final EditLinePreferences preferences;
  
  // ============================================
  // LOADING & ERROR STATE
  // ============================================
  
  /// Whether data is being loaded
  final bool isLoading;
  
  /// Whether initialization is complete
  final bool isInitialized;
  
  /// Error message to display to user
  final String? errorMessage;

  const EditLineState({
    // Core data
    this.subtitleLine,
    this.subtitleCollection,
    this.isNewSubtitle = false,
    required this.sessionId,
    
    // Text field state
    this.originalText = '',
    this.editedText = '',
    this.isEditingEnabled = false,
    this.showOriginalTextField = true,
    this.showOriginalLine = false,
    this.isRawEnabled = false,
    
    // Time field state
    this.startTime = '00:00:00,000',
    this.endTime = '00:00:05,000',
    this.isTimeVisible = false,
    
    // Validation state
    this.startTimeError,
    this.endTimeError,
    this.timeOrderError,
    this.hasUnsavedChanges = false,
    
    // Character counting state
    this.originalCharCount = 0,
    this.editedCharCount = 0,
    this.originalHasLongLine = false,
    this.editedHasLongLine = false,
    this.maxLineLength = 32,
    
    // Video player state
    this.videoPath,
    this.isVideoLoaded = false,
    this.isVideoVisible = false,
    this.isVideoPlaying = false,
    this.subtitles = const [],
    this.isRepeatModeEnabled = false,
    this.isCustomRangeMode = false,
    this.customRangeStartIndex,
    this.customRangeEndIndex,
    
    // Secondary subtitles
    this.secondarySubtitles = const [],
    this.secondarySubtitlesForPlayer = const [],
    this.showSecondarySubtitles = false,
    
    // UI state
    this.isKeyboardVisible = false,
    this.resizeRatio = 0.35,
    this.mobileVideoResizeRatio = 0.4,
    this.layoutPreference = 'layout1',
    this.colorHistory = const [],
    this.isEditMode = false,
    
    // Preferences
    EditLinePreferences? preferences,
    
    // Loading & error state
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  }) : preferences = preferences ?? const EditLinePreferences(
         isMsoneEnabled: false,
         showOriginalLine: false,
         autoSaveWithNavigation: true,
         saveToFileEnabled: false,
         autoResizeOnKeyboard: true,
         maxLineLength: 32,
         showOriginalTextField: true,
         resizeRatio: 0.35,
         mobileVideoResizeRatio: 0.4,
         layoutPreference: 'layout1',
         colorHistory: [],
       );

  /// Factory for initial loading state
  factory EditLineState.initial({
    required int sessionId,
    bool isNewSubtitle = false,
    bool isEditMode = false,
  }) {
    return EditLineState(
      sessionId: sessionId,
      isNewSubtitle: isNewSubtitle,
      isEditMode: isEditMode,
      isLoading: true,
      isTimeVisible: isNewSubtitle || isEditMode,
    );
  }

  /// Create a copy with updated fields
  EditLineState copyWith({
    // Core data
    SubtitleLine? subtitleLine,
    SubtitleCollection? subtitleCollection,
    bool? isNewSubtitle,
    int? sessionId,
    
    // Text field state
    String? originalText,
    String? editedText,
    bool? isEditingEnabled,
    bool? showOriginalTextField,
    bool? showOriginalLine,
    bool? isRawEnabled,
    
    // Time field state
    String? startTime,
    String? endTime,
    bool? isTimeVisible,
    
    // Validation state
    String? startTimeError,
    String? endTimeError,
    String? timeOrderError,
    bool? hasUnsavedChanges,
    
    // Character counting state
    int? originalCharCount,
    int? editedCharCount,
    bool? originalHasLongLine,
    bool? editedHasLongLine,
    int? maxLineLength,
    
    // Video player state
    String? videoPath,
    bool? isVideoLoaded,
    bool? isVideoVisible,
    bool? isVideoPlaying,
    List<Subtitle>? subtitles,
    bool? isRepeatModeEnabled,
    bool? isCustomRangeMode,
    int? customRangeStartIndex,
    int? customRangeEndIndex,
    
    // Secondary subtitles
    List<SimpleSubtitleLine>? secondarySubtitles,
    List<Subtitle>? secondarySubtitlesForPlayer,
    bool? showSecondarySubtitles,
    
    // UI state
    bool? isKeyboardVisible,
    double? resizeRatio,
    double? mobileVideoResizeRatio,
    String? layoutPreference,
    List<Color>? colorHistory,
    bool? isEditMode,
    
    // Preferences
    EditLinePreferences? preferences,
    
    // Loading & error state
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    
    // Special flags for nullable fields
    bool clearStartTimeError = false,
    bool clearEndTimeError = false,
    bool clearTimeOrderError = false,
    bool clearErrorMessage = false,
    bool clearVideoPath = false,
    bool clearCustomRangeStart = false,
    bool clearCustomRangeEnd = false,
  }) {
    return EditLineState(
      // Core data
      subtitleLine: subtitleLine ?? this.subtitleLine,
      subtitleCollection: subtitleCollection ?? this.subtitleCollection,
      isNewSubtitle: isNewSubtitle ?? this.isNewSubtitle,
      sessionId: sessionId ?? this.sessionId,
      
      // Text field state
      originalText: originalText ?? this.originalText,
      editedText: editedText ?? this.editedText,
      isEditingEnabled: isEditingEnabled ?? this.isEditingEnabled,
      showOriginalTextField: showOriginalTextField ?? this.showOriginalTextField,
      showOriginalLine: showOriginalLine ?? this.showOriginalLine,
      isRawEnabled: isRawEnabled ?? this.isRawEnabled,
      
      // Time field state
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isTimeVisible: isTimeVisible ?? this.isTimeVisible,
      
      // Validation state
      startTimeError: clearStartTimeError ? null : (startTimeError ?? this.startTimeError),
      endTimeError: clearEndTimeError ? null : (endTimeError ?? this.endTimeError),
      timeOrderError: clearTimeOrderError ? null : (timeOrderError ?? this.timeOrderError),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      
      // Character counting state
      originalCharCount: originalCharCount ?? this.originalCharCount,
      editedCharCount: editedCharCount ?? this.editedCharCount,
      originalHasLongLine: originalHasLongLine ?? this.originalHasLongLine,
      editedHasLongLine: editedHasLongLine ?? this.editedHasLongLine,
      maxLineLength: maxLineLength ?? this.maxLineLength,
      
      // Video player state
      videoPath: clearVideoPath ? null : (videoPath ?? this.videoPath),
      isVideoLoaded: isVideoLoaded ?? this.isVideoLoaded,
      isVideoVisible: isVideoVisible ?? this.isVideoVisible,
      isVideoPlaying: isVideoPlaying ?? this.isVideoPlaying,
      subtitles: subtitles ?? this.subtitles,
      isRepeatModeEnabled: isRepeatModeEnabled ?? this.isRepeatModeEnabled,
      isCustomRangeMode: isCustomRangeMode ?? this.isCustomRangeMode,
      customRangeStartIndex: clearCustomRangeStart ? null : (customRangeStartIndex ?? this.customRangeStartIndex),
      customRangeEndIndex: clearCustomRangeEnd ? null : (customRangeEndIndex ?? this.customRangeEndIndex),
      
      // Secondary subtitles
      secondarySubtitles: secondarySubtitles ?? this.secondarySubtitles,
      secondarySubtitlesForPlayer: secondarySubtitlesForPlayer ?? this.secondarySubtitlesForPlayer,
      showSecondarySubtitles: showSecondarySubtitles ?? this.showSecondarySubtitles,
      
      // UI state
      isKeyboardVisible: isKeyboardVisible ?? this.isKeyboardVisible,
      resizeRatio: resizeRatio ?? this.resizeRatio,
      mobileVideoResizeRatio: mobileVideoResizeRatio ?? this.mobileVideoResizeRatio,
      layoutPreference: layoutPreference ?? this.layoutPreference,
      colorHistory: colorHistory ?? this.colorHistory,
      isEditMode: isEditMode ?? this.isEditMode,
      
      // Preferences
      preferences: preferences ?? this.preferences,
      
      // Loading & error state
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        // Core data
        subtitleLine,
        subtitleCollection,
        isNewSubtitle,
        sessionId,
        
        // Text field state
        originalText,
        editedText,
        isEditingEnabled,
        showOriginalTextField,
        showOriginalLine,
        isRawEnabled,
        
        // Time field state
        startTime,
        endTime,
        isTimeVisible,
        
        // Validation state
        startTimeError,
        endTimeError,
        timeOrderError,
        hasUnsavedChanges,
        
        // Character counting state
        originalCharCount,
        editedCharCount,
        originalHasLongLine,
        editedHasLongLine,
        maxLineLength,
        
        // Video player state
        videoPath,
        isVideoLoaded,
        isVideoVisible,
        isVideoPlaying,
        subtitles,
        isRepeatModeEnabled,
        isCustomRangeMode,
        customRangeStartIndex,
        customRangeEndIndex,
        
        // Secondary subtitles
        secondarySubtitles,
        secondarySubtitlesForPlayer,
        showSecondarySubtitles,
        
        // UI state
        isKeyboardVisible,
        resizeRatio,
        mobileVideoResizeRatio,
        layoutPreference,
        colorHistory,
        isEditMode,
        
        // Preferences
        preferences,
        
        // Loading & error state
        isLoading,
        isInitialized,
        errorMessage,
      ];
}
