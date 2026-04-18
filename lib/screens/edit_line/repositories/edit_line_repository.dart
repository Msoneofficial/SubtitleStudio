import 'dart:io';

import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';
import 'package:subtitle_studio/main.dart'; // For isar instance
import 'package:subtitle_studio/widgets/video_player_widget.dart'; // For Subtitle
import 'package:subtitle_studio/utils/subtitle_parser.dart'; // For SimpleSubtitleLine
import 'package:subtitle_studio/utils/platform_file_handler.dart';

/// Repository layer for EditLineScreen operations
/// 
/// This class abstracts all database operations, file I/O, and business logic
/// for single subtitle line editing, following clean architecture principles.
/// 
/// Responsibilities:
/// - Fetch and update single subtitle lines
/// - Load and save preferences specific to edit line screen
/// - Video path management
/// - File save operations (SRT export)
/// - Character counting and validation logic
/// - Subtitle generation for video player
/// 
/// Following Single Responsibility Principle:
/// - Database operations are isolated from UI
/// - Business logic separated from presentation
/// - Preferences managed in one place
/// - File I/O abstracted from UI concerns
class EditLineRepository {
  static final EditLineRepository _instance = EditLineRepository._internal();
  factory EditLineRepository() => _instance;
  EditLineRepository._internal();

  /// Fetch a single subtitle line by collection ID and index
  /// 
  /// Returns null if not found or index is out of bounds
  Future<SubtitleLine?> fetchSubtitleLine(
    Id collectionId,
    int index,
  ) async {
    await logInfo(
      'Fetching subtitle line at index $index from collection $collectionId',
      context: 'EditLineRepository.fetchSubtitleLine',
    );

    try {
      final collection = await isar.subtitleCollections.get(collectionId);

      if (collection == null) {
        await logWarning(
          'Subtitle collection $collectionId not found',
          context: 'EditLineRepository.fetchSubtitleLine',
        );
        return null;
      }

      // Check bounds: index is 1-based for display, but array is 0-based
      if (index < 1 || index > collection.lines.length) {
        await logWarning(
          'Index $index out of bounds for collection $collectionId (length: ${collection.lines.length})',
          context: 'EditLineRepository.fetchSubtitleLine',
        );
        return null;
      }

      final line = collection.lines[index - 1]; // Convert to 0-based array index

      final editedPreview = line.edited != null && line.edited!.isNotEmpty
          ? line.edited!.substring(0, line.edited!.length > 50 ? 50 : line.edited!.length)
          : '';

      await logInfo(
        'Successfully fetched line $index: "$editedPreview..."',
        context: 'EditLineRepository.fetchSubtitleLine',
      );

      return line;
    } catch (e, stackTrace) {
      await logError(
        'Failed to fetch subtitle line',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.fetchSubtitleLine',
      );
      rethrow;
    }
  }

  /// Fetch subtitle collection metadata
  Future<SubtitleCollection?> fetchSubtitleCollection(Id collectionId) async {
    await logInfo(
      'Fetching subtitle collection $collectionId',
      context: 'EditLineRepository.fetchSubtitleCollection',
    );

    try {
      final collection = await isar.subtitleCollections.get(collectionId);

      if (collection != null) {
        await logInfo(
          'Successfully fetched collection "${collection.fileName}" with ${collection.lines.length} lines',
          context: 'EditLineRepository.fetchSubtitleCollection',
        );
      } else {
        await logWarning(
          'Collection $collectionId not found',
          context: 'EditLineRepository.fetchSubtitleCollection',
        );
      }

      return collection;
    } catch (e, stackTrace) {
      await logError(
        'Failed to fetch subtitle collection',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.fetchSubtitleCollection',
      );
      rethrow;
    }
  }

  /// Update a subtitle line in the database
  /// 
  /// Updates original text, edited text, start time, and end time
  /// Returns true if successful, false otherwise
  Future<bool> updateSubtitleLine({
    required Id collectionId,
    required int lineIndex,
    required String originalText,
    required String editedText,
    required String startTime,
    required String endTime,
  }) async {
    await logInfo(
      'Updating subtitle line $lineIndex in collection $collectionId',
      context: 'EditLineRepository.updateSubtitleLine',
    );

    try {
      return await logPerformance(
        'Update subtitle line',
        () async {
          final collection = await isar.subtitleCollections.get(collectionId);

          if (collection == null) {
            await logWarning(
              'Collection $collectionId not found',
              context: 'EditLineRepository.updateSubtitleLine',
            );
            return false;
          }

          // Validate index bounds (1-based)
          if (lineIndex < 1 || lineIndex > collection.lines.length) {
            await logWarning(
              'Index $lineIndex out of bounds',
              context: 'EditLineRepository.updateSubtitleLine',
            );
            return false;
          }

          // Update the line (0-based array access)
          final arrayIndex = lineIndex - 1;
          collection.lines[arrayIndex].original = originalText;
          collection.lines[arrayIndex].edited = editedText;
          collection.lines[arrayIndex].startTime = startTime;
          collection.lines[arrayIndex].endTime = endTime;

          // Write to database
          await isar.writeTxn(() async {
            await isar.subtitleCollections.put(collection);
          });

          await logInfo(
            'Successfully updated line $lineIndex',
            context: 'EditLineRepository.updateSubtitleLine',
          );

          return true;
        },
        context: 'EditLineRepository',
      );
    } catch (e, stackTrace) {
      await logError(
        'Failed to update subtitle line',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.updateSubtitleLine',
      );
      return false;
    }
  }

  /// Delete a subtitle line from the collection
  Future<bool> deleteSubtitleLine(Id collectionId, int lineIndex) async {
    await logInfo(
      'Deleting subtitle line $lineIndex from collection $collectionId',
      context: 'EditLineRepository.deleteSubtitleLine',
    );

    try {
      final success = await deleteSubtitleLineDB(collectionId, lineIndex);

      if (success) {
        await logInfo(
          'Successfully deleted line $lineIndex',
          context: 'EditLineRepository.deleteSubtitleLine',
        );
      } else {
        await logWarning(
          'Failed to delete line $lineIndex',
          context: 'EditLineRepository.deleteSubtitleLine',
        );
      }

      return success;
    } catch (e, stackTrace) {
      await logError(
        'Error deleting subtitle line',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.deleteSubtitleLine',
      );
      return false;
    }
  }

  /// Mark or unmark a subtitle line
  Future<bool> markSubtitleLine(
    Id collectionId,
    int lineIndex,
    bool marked,
  ) async {
    await logInfo(
      'Marking line $lineIndex in collection $collectionId as $marked',
      context: 'EditLineRepository.markSubtitleLine',
    );

    try {
      final success = await markSubtitleLine(collectionId, lineIndex, marked);

      if (success) {
        await logInfo(
          'Successfully marked line $lineIndex',
          context: 'EditLineRepository.markSubtitleLine',
        );
      } else {
        await logWarning(
          'Failed to mark line $lineIndex',
          context: 'EditLineRepository.markSubtitleLine',
        );
      }

      return success;
    } catch (e, stackTrace) {
      await logError(
        'Error marking subtitle line',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.markSubtitleLine',
      );
      return false;
    }
  }

  /// Update comment for a subtitle line
  Future<bool> updateSubtitleLineComment(
    Id collectionId,
    int lineIndex,
    String? comment,
  ) async {
    await logInfo(
      'Updating comment for line $lineIndex in collection $collectionId',
      context: 'EditLineRepository.updateSubtitleLineComment',
    );

    try {
      await updateSubtitleLineComment(collectionId, lineIndex, comment);

      await logInfo(
        'Successfully updated comment for line $lineIndex',
        context: 'EditLineRepository.updateSubtitleLineComment',
      );

      return true;
    } catch (e, stackTrace) {
      await logError(
        'Error updating comment',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.updateSubtitleLineComment',
      );
      return false;
    }
  }

  /// Generate subtitles for video player from collection
  Future<List<Subtitle>> generateSubtitles(Id collectionId) async {
    await logInfo(
      'Generating subtitles for video player from collection $collectionId',
      context: 'EditLineRepository.generateSubtitles',
    );

    try {
      return await logPerformance(
        'Generate subtitles for video',
        () async {
          final collection = await isar.subtitleCollections.get(collectionId);

          if (collection == null || collection.lines.isEmpty) {
            await logWarning(
              'Collection $collectionId not found or empty',
              context: 'EditLineRepository.generateSubtitles',
            );
            return <Subtitle>[];
          }

          final subtitles = collection.lines.map((line) {
            final startDuration = _parseTimeString(line.startTime);
            final endDuration = _parseTimeString(line.endTime);

            return Subtitle(
              index: line.index,
              start: startDuration,
              end: endDuration,
              text: line.edited ?? '', // Handle null with empty string
            );
          }).toList();

          await logInfo(
            'Generated ${subtitles.length} subtitles for video player',
            context: 'EditLineRepository.generateSubtitles',
          );

          return subtitles;
        },
        context: 'EditLineRepository',
      );
    } catch (e, stackTrace) {
      await logError(
        'Failed to generate subtitles',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.generateSubtitles',
      );
      return [];
    }
  }

  /// Generate secondary subtitles from simple subtitle lines
  List<Subtitle> generateSecondarySubtitles(
    List<SimpleSubtitleLine> lines,
  ) {
    return lines.map((line) {
      final startDuration = _parseTimeString(line.startTime);
      final endDuration = _parseTimeString(line.endTime);

      return Subtitle(
        index: line.index,
        start: startDuration,
        end: endDuration,
        text: line.text, // text is non-nullable in SimpleSubtitleLine
      );
    }).toList();
  }

  /// Parse time string (HH:mm:ss,SSS or HH:mm:ss.SSS) to Duration
  Duration _parseTimeString(String time) {
    try {
      // Normalize separator - replace period with comma for consistency
      final normalized = time.replaceAll('.', ',');
      final parts = normalized.split(',');
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
    } catch (e) {
      logWarning(
        'Failed to parse time string "$time": $e',
        context: 'EditLineRepository._parseTimeString',
      );
      return Duration.zero;
    }
  }

  // ============================================
  // PREFERENCES OPERATIONS
  // ============================================

  /// Load all preferences relevant to edit line screen
  /// 
  /// Batches all preference loading into a single efficient operation
  Future<EditLinePreferences> loadAllPreferences(Id collectionId) async {
    await logInfo(
      'Loading all preferences for edit line screen',
      context: 'EditLineRepository.loadAllPreferences',
    );

    try {
      return await logPerformance(
        'Load all edit line preferences',
        () async {
          // Load all preferences in parallel for maximum performance
          final results = await Future.wait([
            PreferencesModel.getMsoneEnabled(),
            PreferencesModel.getShowOriginalLine(),
            PreferencesModel.getAutoSaveWithNavigation(),
            PreferencesModel.getSaveToFileEnabled(),
            PreferencesModel.getAutoResizeOnKeyboard(),
            PreferencesModel.getMaxLineLength(),
            PreferencesModel.getShowOriginalTextField(),
            PreferencesModel.getVideoPath(collectionId),
            PreferencesModel.getEditLineResizeRatio(),
            PreferencesModel.getMobileVideoResizeRatio(),
            PreferencesModel.getSwitchLayout(),
            PreferencesModel.getColorHistory(),
          ]);

          final preferences = EditLinePreferences(
            isMsoneEnabled: results[0] as bool,
            showOriginalLine: results[1] as bool,
            autoSaveWithNavigation: results[2] as bool,
            saveToFileEnabled: results[3] as bool,
            autoResizeOnKeyboard: results[4] as bool,
            maxLineLength: results[5] as int,
            showOriginalTextField: results[6] as bool,
            videoPath: results[7] as String?,
            resizeRatio: results[8] as double,
            mobileVideoResizeRatio: results[9] as double,
            layoutPreference: results[10] as String,
            colorHistory: (results[11] as List<String>)
                .map((hex) => _parseColorFromHex(hex))
                .where((color) => color != null)
                .cast<Color>()
                .toList(),
          );

          await logInfo(
            'Successfully loaded all preferences',
            context: 'EditLineRepository.loadAllPreferences',
          );

          return preferences;
        },
        context: 'EditLineRepository',
      );
    } catch (e, stackTrace) {
      await logError(
        'Failed to load preferences',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.loadAllPreferences',
      );

      // Return default preferences on error
      return EditLinePreferences.defaults();
    }
  }

  /// Parse color from hex string
  Color? _parseColorFromHex(String hex) {
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return null;
    }
  }

  /// Save individual preference
  Future<void> savePreference(String key, dynamic value) async {
    try {
      switch (key) {
        case 'msoneEnabled':
          await PreferencesModel.setMsoneEnabled(value as bool);
          break;
        case 'showOriginalLine':
          await PreferencesModel.setShowOriginalLine(value as bool);
          break;
        case 'autoSaveWithNavigation':
          await PreferencesModel.setAutoSaveWithNavigation(value as bool);
          break;
        case 'saveToFileEnabled':
          await PreferencesModel.setSaveToFileEnabled(value as bool);
          break;
        case 'autoResizeOnKeyboard':
          await PreferencesModel.setAutoResizeOnKeyboard(value as bool);
          break;
        case 'maxLineLength':
          await PreferencesModel.setMaxLineLength(value as int);
          break;
        case 'showOriginalTextField':
          await PreferencesModel.setShowOriginalTextField(value as bool);
          break;
        case 'resizeRatio':
          await PreferencesModel.setEditLineResizeRatio(value as double);
          break;
        case 'mobileVideoResizeRatio':
          await PreferencesModel.setMobileVideoResizeRatio(value as double);
          break;
        case 'layoutPreference':
          await PreferencesModel.setSwitchLayout(value as String);
          break;
        default:
          await logWarning(
            'Unknown preference key: $key',
            context: 'EditLineRepository.savePreference',
          );
      }
    } catch (e, stackTrace) {
      await logError(
        'Failed to save preference $key',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.savePreference',
      );
    }
  }

  /// Save video path for collection
  Future<void> saveVideoPath(Id collectionId, String path) async {
    await logInfo(
      'Saving video path for collection $collectionId',
      context: 'EditLineRepository.saveVideoPath',
    );

    try {
      await PreferencesModel.saveVideoPath(collectionId, path);
      await logInfo(
        'Successfully saved video path',
        context: 'EditLineRepository.saveVideoPath',
      );
    } catch (e, stackTrace) {
      await logError(
        'Failed to save video path',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.saveVideoPath',
      );
    }
  }

  /// Remove video path for collection
  Future<void> removeVideoPath(Id collectionId) async {
    await logInfo(
      'Removing video path for collection $collectionId',
      context: 'EditLineRepository.removeVideoPath',
    );

    try {
      await PreferencesModel.removeVideoPath(collectionId);
      await logInfo(
        'Successfully removed video path',
        context: 'EditLineRepository.removeVideoPath',
      );
    } catch (e, stackTrace) {
      await logError(
        'Failed to remove video path',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.removeVideoPath',
      );
    }
  }

  /// Save color history
  Future<void> saveColorHistory(List<Color> colors) async {
    try {
      final colorStrings = colors
          .map((color) => '#${color.value.toRadixString(16).padLeft(8, '0')}')
          .toList();
      await PreferencesModel.saveColorHistory(colorStrings);
    } catch (e, stackTrace) {
      await logError(
        'Failed to save color history',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.saveColorHistory',
      );
    }
  }

  // ============================================
  // FILE OPERATIONS
  // ============================================

  /// Save subtitle content to file using 3-strategy approach
  /// 
  /// Strategy 1: Try originalFileUri (SAF URI)
  /// Strategy 2: Try filePath
  /// Strategy 3: Ask user to pick new location
  /// 
  /// Returns true if save was successful
  Future<bool> saveSrtFile({
    required String content,
    required String? originalFileUri,
    required String? filePath,
    required Function() onPickNewLocation,
  }) async {
    await logInfo(
      'Attempting to save SRT file with 3-strategy approach',
      context: 'EditLineRepository.saveSrtFile',
    );

    try {
      return await logPerformance(
        'Save SRT file',
        () async {
          // Strategy 1: Try SAF URI
          if (originalFileUri != null && originalFileUri.isNotEmpty) {
            await logInfo(
              'Strategy 1: Attempting to save using SAF URI',
              context: 'EditLineRepository.saveSrtFile',
            );

            try {
              final success = await PlatformFileHandler.writeFile(
                content: content,
                filePath: originalFileUri,
                mimeType: 'application/x-subrip',
              );

              if (success) {
                await logInfo(
                  'Strategy 1 successful: Saved via SAF URI',
                  context: 'EditLineRepository.saveSrtFile',
                );
                return true;
              }
            } catch (e) {
              await logWarning(
                'Strategy 1 failed: SAF URI write error',
                context: 'EditLineRepository.saveSrtFile',
              );
            }
          }

          // Strategy 2: Try direct file path
          if (filePath != null && filePath.isNotEmpty) {
            await logInfo(
              'Strategy 2: Attempting to save using file path',
              context: 'EditLineRepository.saveSrtFile',
            );

            try {
              final file = File(filePath);
              if (await file.exists()) {
                await file.writeAsString(content);
                await logInfo(
                  'Strategy 2 successful: Saved via direct file path',
                  context: 'EditLineRepository.saveSrtFile',
                );
                return true;
              } else {
                await logWarning(
                  'Strategy 2 failed: File does not exist',
                  context: 'EditLineRepository.saveSrtFile',
                );
              }
            } catch (e) {
              await logWarning(
                'Strategy 2 failed: File write error: $e',
                context: 'EditLineRepository.saveSrtFile',
              );
            }
          }

          // Strategy 3: Ask user to pick new location
          await logInfo(
            'Strategy 3: Requesting user to pick new save location',
            context: 'EditLineRepository.saveSrtFile',
          );

          onPickNewLocation();
          return false;
        },
        context: 'EditLineRepository',
      );
    } catch (e, stackTrace) {
      await logError(
        'Fatal error during file save',
        error: e,
        stackTrace: stackTrace,
        context: 'EditLineRepository.saveSrtFile',
      );
      return false;
    }
  }
}

/// Preferences model for EditLineScreen
/// 
/// Encapsulates all preference data in a single immutable object
/// for better state management and testability
class EditLinePreferences {
  final bool isMsoneEnabled;
  final bool showOriginalLine;
  final bool autoSaveWithNavigation;
  final bool saveToFileEnabled;
  final bool autoResizeOnKeyboard;
  final int maxLineLength;
  final bool showOriginalTextField;
  final String? videoPath;
  final double resizeRatio;
  final double mobileVideoResizeRatio;
  final String layoutPreference;
  final List<Color> colorHistory;

  const EditLinePreferences({
    required this.isMsoneEnabled,
    required this.showOriginalLine,
    required this.autoSaveWithNavigation,
    required this.saveToFileEnabled,
    required this.autoResizeOnKeyboard,
    required this.maxLineLength,
    required this.showOriginalTextField,
    this.videoPath,
    required this.resizeRatio,
    required this.mobileVideoResizeRatio,
    required this.layoutPreference,
    required this.colorHistory,
  });

  /// Default preferences factory
  factory EditLinePreferences.defaults() {
    return const EditLinePreferences(
      isMsoneEnabled: false,
      showOriginalLine: false,
      autoSaveWithNavigation: true,
      saveToFileEnabled: false,
      autoResizeOnKeyboard: true,
      maxLineLength: 32,
      showOriginalTextField: true,
      videoPath: null,
      resizeRatio: 0.35,
      mobileVideoResizeRatio: 0.4,
      layoutPreference: 'layout1',
      colorHistory: [],
    );
  }

  EditLinePreferences copyWith({
    bool? isMsoneEnabled,
    bool? showOriginalLine,
    bool? autoSaveWithNavigation,
    bool? saveToFileEnabled,
    bool? autoResizeOnKeyboard,
    int? maxLineLength,
    bool? showOriginalTextField,
    String? videoPath,
    double? resizeRatio,
    double? mobileVideoResizeRatio,
    String? layoutPreference,
    List<Color>? colorHistory,
  }) {
    return EditLinePreferences(
      isMsoneEnabled: isMsoneEnabled ?? this.isMsoneEnabled,
      showOriginalLine: showOriginalLine ?? this.showOriginalLine,
      autoSaveWithNavigation:
          autoSaveWithNavigation ?? this.autoSaveWithNavigation,
      saveToFileEnabled: saveToFileEnabled ?? this.saveToFileEnabled,
      autoResizeOnKeyboard: autoResizeOnKeyboard ?? this.autoResizeOnKeyboard,
      maxLineLength: maxLineLength ?? this.maxLineLength,
      showOriginalTextField:
          showOriginalTextField ?? this.showOriginalTextField,
      videoPath: videoPath ?? this.videoPath,
      resizeRatio: resizeRatio ?? this.resizeRatio,
      mobileVideoResizeRatio:
          mobileVideoResizeRatio ?? this.mobileVideoResizeRatio,
      layoutPreference: layoutPreference ?? this.layoutPreference,
      colorHistory: colorHistory ?? this.colorHistory,
    );
  }
}
