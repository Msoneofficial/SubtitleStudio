import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

/// Represents a single subtitle entry with all its components
/// Made mutable for performance reasons (matching EditScreen approach)
class SubtitleEntry {
  String index;
  String startTime;
  String endTime;
  String text;

  SubtitleEntry({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  /// Convert to SRT format string
  String toSrtString() {
    return '$index\n$startTime --> $endTime\n$text\n';
  }

  /// Parse a single SRT entry from text
  static SubtitleEntry? fromSrtText(String srtText) {
    final lines = srtText.trim().split('\n');
    if (lines.length < 3) return null;

    final index = lines[0].trim();
    final timecode = lines[1].trim();
    final text = lines.skip(2).join('\n').trim();

    // Parse timecode
    final timeParts = timecode.split(' --> ');
    if (timeParts.length != 2) return null;

    return SubtitleEntry(
      index: index,
      startTime: timeParts[0].trim(),
      endTime: timeParts[1].trim(),
      text: text,
    );
  }

  /// Create a copy with modified fields
  SubtitleEntry copyWith({
    String? index,
    String? startTime,
    String? endTime,
    String? text,
  }) {
    return SubtitleEntry(
      index: index ?? this.index,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      text: text ?? this.text,
    );
  }

  // Removed props getter since we don't extend Equatable anymore for performance
}

/// Immutable state model for the SourceViewScreen
/// 
/// This class represents all the UI state for the source view editor,
/// following clean architecture and BLoC pattern principles.
@immutable
class SourceViewState extends Equatable {
  // Core subtitle data
  final List<SubtitleEntry> subtitleEntries;
  final String filePath;
  final String? displayName;
  final String? safUri;
  
  // Loading and error states
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;
  
  // Edit state
  final bool hasUnsavedChanges;
  final Encoding fileEncoding;
  
  // Save state
  final bool isSaving;
  final String? saveMessage;
  final bool saveSuccessful;

  const SourceViewState({
    this.subtitleEntries = const [],
    required this.filePath,
    this.displayName,
    this.safUri,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
    this.hasUnsavedChanges = false,
    this.fileEncoding = utf8,
    this.isSaving = false,
    this.saveMessage,
    this.saveSuccessful = false,
  });

  /// Initial state constructor
  factory SourceViewState.initial({
    required String filePath,
    String? displayName,
    String? safUri,
  }) {
    return SourceViewState(
      filePath: filePath,
      displayName: displayName,
      safUri: safUri,
      isLoading: true,
    );
  }

  /// Loading state
  SourceViewState toLoading() {
    return copyWith(
      isLoading: true,
      errorMessage: null,
      saveMessage: null,
    );
  }

  /// Loaded state
  SourceViewState toLoaded({
    required List<SubtitleEntry> entries,
    required Encoding encoding,
  }) {
    return copyWith(
      subtitleEntries: entries,
      fileEncoding: encoding,
      isLoading: false,
      isInitialized: true,
      errorMessage: null,
      hasUnsavedChanges: false,
    );
  }

  /// Error state
  SourceViewState toError(String error) {
    return copyWith(
      isLoading: false,
      errorMessage: error,
      saveMessage: null,
    );
  }

  /// Content changed state
  SourceViewState toContentChanged({
    required List<SubtitleEntry> entries,
  }) {
    return copyWith(
      subtitleEntries: entries,
      hasUnsavedChanges: true,
      saveMessage: null,
    );
  }

  /// Saving state
  SourceViewState toSaving() {
    return copyWith(
      isSaving: true,
      saveMessage: null,
    );
  }

  /// Save success state
  SourceViewState toSaveSuccess(String message) {
    return copyWith(
      isSaving: false,
      hasUnsavedChanges: false,
      saveMessage: message,
      saveSuccessful: true,
    );
  }

  /// Save error state
  SourceViewState toSaveError(String error) {
    return copyWith(
      isSaving: false,
      saveMessage: error,
      saveSuccessful: false,
    );
  }

  /// Create a copy with modified fields
  SourceViewState copyWith({
    List<SubtitleEntry>? subtitleEntries,
    String? filePath,
    String? displayName,
    String? safUri,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool? hasUnsavedChanges,
    Encoding? fileEncoding,
    bool? isSaving,
    String? saveMessage,
    bool? saveSuccessful,
  }) {
    return SourceViewState(
      subtitleEntries: subtitleEntries ?? this.subtitleEntries,
      filePath: filePath ?? this.filePath,
      displayName: displayName ?? this.displayName,
      safUri: safUri ?? this.safUri,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      fileEncoding: fileEncoding ?? this.fileEncoding,
      isSaving: isSaving ?? this.isSaving,
      saveMessage: saveMessage,
      saveSuccessful: saveSuccessful ?? this.saveSuccessful,
    );
  }

  /// Get display filename
  String get displayFileName {
    return displayName ?? filePath.split('/').last.split('\\').last;
  }

  /// Convert subtitle entries to SRT content
  String toSrtContent() {
    final buffer = StringBuffer();
    for (int i = 0; i < subtitleEntries.length; i++) {
      if (i > 0) buffer.write('\n');
      buffer.write(subtitleEntries[i].toSrtString());
    }
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
        subtitleEntries,
        filePath,
        displayName,
        safUri,
        isLoading,
        isInitialized,
        errorMessage,
        hasUnsavedChanges,
        fileEncoding,
        isSaving,
        saveMessage,
        saveSuccessful,
      ];
}