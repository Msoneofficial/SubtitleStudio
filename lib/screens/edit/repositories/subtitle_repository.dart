import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/widgets/video_player_widget.dart';
import 'package:subtitle_studio/utils/subtitle_parser.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';
import 'package:subtitle_studio/services/checkpoint_manager.dart';
import 'package:subtitle_studio/utils/time_parser.dart';
import 'package:subtitle_studio/main.dart'; // For isar instance
import '../../screen_edit.dart'; // For SubtitleEntry

/// Repository layer for subtitle operations
/// 
/// This class abstracts all database operations and business logic
/// for subtitle management, following clean architecture principles.
/// 
/// Responsibilities:
/// - Fetch subtitle lines and collections
/// - Update subtitle lines (edit, mark, comment)
/// - Delete subtitle lines (single and batch)
/// - Checkpoint management integration
/// - Source view synchronization
/// - Generate subtitles for video player
class SubtitleRepository {
  static final SubtitleRepository _instance = SubtitleRepository._internal();
  factory SubtitleRepository() => _instance;
  SubtitleRepository._internal();

  /// Fetch all subtitle lines for a collection
  Future<List<SubtitleLine>> fetchLines(int collectionId) async {
    logInfo('SubtitleRepository: Fetching subtitle lines for collection $collectionId');
    try {
      final subtitles = await fetchSubtitleLines(collectionId); // Use database_helper function
      logInfo('SubtitleRepository: Successfully fetched ${subtitles.length} subtitle lines');
      return subtitles;
    } catch (e) {
      logError('SubtitleRepository: Failed to fetch subtitle lines: $e');
      rethrow;
    }
  }

  /// Fetch subtitle collection by ID
  Future<SubtitleCollection?> fetchSubtitleCollection(int id) async {
    logInfo('SubtitleRepository: Fetching subtitle collection $id');
    try {
      final collection = await fetchSubtitle(id);
      if (collection != null) {
        logInfo('SubtitleRepository: Successfully fetched collection "${collection.fileName}"');
      } else {
        logWarning('SubtitleRepository: Collection $id not found');
      }
      return collection;
    } catch (e) {
      logError('SubtitleRepository: Failed to fetch collection: $e');
      rethrow;
    }
  }

  /// Mark a subtitle line
  Future<bool> markLine(int collectionId, int index, bool marked) async {
    logInfo('SubtitleRepository: Marking line $index in collection $collectionId as $marked');
    try {
      final success = await markSubtitleLine(collectionId, index, marked); // Use database_helper function
      if (success) {
        logInfo('SubtitleRepository: Successfully marked line $index');
      } else {
        logWarning('SubtitleRepository: Failed to mark line $index');
      }
      return success;
    } catch (e) {
      logError('SubtitleRepository: Error marking line $index: $e');
      rethrow;
    }
  }

  /// Update comment for a subtitle line
  Future<bool> updateComment(int collectionId, int index, String? comment) async {
    logInfo('SubtitleRepository: Updating comment for line $index in collection $collectionId');
    try {
      await updateSubtitleLineComment(collectionId, index, comment);
      logInfo('SubtitleRepository: Successfully updated comment for line $index');
      return true;
    } catch (e) {
      logError('SubtitleRepository: Error updating comment for line $index: $e');
      rethrow;
    }
  }

  /// Delete a single subtitle line
  Future<bool> deleteLine(int collectionId, int index) async {
    logInfo('SubtitleRepository: Deleting line $index from collection $collectionId');
    try {
      final success = await deleteSubtitleLineDB(collectionId, index); // Use database_helper function
      if (success) {
        logInfo('SubtitleRepository: Successfully deleted line $index');
      } else {
        logWarning('SubtitleRepository: Failed to delete line $index');
      }
      return success;
    } catch (e) {
      logError('SubtitleRepository: Error deleting line $index: $e');
      rethrow;
    }
  }

  /// Batch delete multiple subtitle lines
  /// Returns a map with 'success' and 'failed' counts
  Future<Map<String, int>> batchDeleteLines(
    int collectionId,
    List<int> indices,
    {bool createCheckpoint = true}
  ) async {
    logInfo('SubtitleRepository: Batch deleting ${indices.length} lines from collection $collectionId');
    
    int successCount = 0;
    int failCount = 0;
    
    // Sort indices in descending order to maintain validity during deletion
    final sortedIndices = indices.toList()..sort((a, b) => b.compareTo(a));
    
    try {
      for (final index in sortedIndices) {
        try {
          final success = await deleteSubtitleLineDB(collectionId, index);
          if (success) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          logError('SubtitleRepository: Error deleting index $index: $e');
          failCount++;
        }
      }
      
      logInfo('SubtitleRepository: Batch delete completed - Success: $successCount, Failed: $failCount');
      return {'success': successCount, 'failed': failCount};
    } catch (e) {
      logError('SubtitleRepository: Batch delete error: $e');
      rethrow;
    }
  }

  /// Get marked subtitle lines
  Future<List<SubtitleLine>> getMarkedLines(int collectionId) async {
    logInfo('SubtitleRepository: Fetching marked lines for collection $collectionId');
    try {
      final markedLines = await getMarkedSubtitleLines(collectionId);
      logInfo('SubtitleRepository: Found ${markedLines.length} marked lines');
      return markedLines;
    } catch (e) {
      logError('SubtitleRepository: Error fetching marked lines: $e');
      rethrow;
    }
  }

  /// Get all subtitle lines with comments
  Future<List<SubtitleLine>> getLinesWithComments(int collectionId) async {
    logInfo('SubtitleRepository: Fetching lines with comments for collection $collectionId');
    try {
      final linesWithComments = await getAllSubtitleLinesWithComments(collectionId);
      logInfo('SubtitleRepository: Found ${linesWithComments.length} lines with comments');
      return linesWithComments;
    } catch (e) {
      logError('SubtitleRepository: Error fetching lines with comments: $e');
      rethrow;
    }
  }

  /// Generate subtitles for video player from SubtitleLine list
  List<Subtitle> generateSubtitles(List<SubtitleLine> subtitleLines) {
    logInfo('SubtitleRepository: Generating ${subtitleLines.length} subtitles for video player');
    try {
      return subtitleLines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value;
        return Subtitle(
          index: index,
          start: parseTimeString(line.startTime),
          end: parseTimeString(line.endTime),
          text: line.edited ?? line.original,
          marked: line.marked,
          comment: line.comment,
        );
      }).toList();
    } catch (e) {
      logError('SubtitleRepository: Error generating subtitles: $e');
      rethrow;
    }
  }

  /// Generate subtitles from SimpleSubtitleLine list
  List<Subtitle> generateSimpleSubtitles(List<SimpleSubtitleLine> subtitleLines) {
    logInfo('SubtitleRepository: Generating ${subtitleLines.length} simple subtitles for video player');
    try {
      return subtitleLines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value;
        return Subtitle(
          index: index,
          start: parseTimeString(line.startTime),
          end: parseTimeString(line.endTime),
          text: line.text,
          marked: false,
          comment: null,
        );
      }).toList();
    } catch (e) {
      logError('SubtitleRepository: Error generating simple subtitles: $e');
      rethrow;
    }
  }

  /// Convert subtitle lines to source view entries
  List<SubtitleEntry> convertToSourceViewEntries(List<SubtitleLine> lines) {
    logInfo('SubtitleRepository: Converting ${lines.length} lines to source view entries');
    try {
      return lines.asMap().entries.map((entry) {
        return SubtitleEntry.fromSubtitleLine(entry.value, entry.key);
      }).toList();
    } catch (e) {
      logError('SubtitleRepository: Error converting to source view entries: $e');
      rethrow;
    }
  }

  /// Sync source view entries back to database
  Future<void> syncSourceViewToDatabase(
    int collectionId,
    List<SubtitleEntry> entries,
  ) async {
    logInfo('SubtitleRepository: Syncing ${entries.length} source view entries to database');
    try {
      // Get the subtitle collection
      final collection = await isar.subtitleCollections.get(collectionId);
      if (collection == null) {
        throw Exception('Subtitle collection $collectionId not found');
      }

      // Update the lines from source view entries
      await isar.writeTxn(() async {
        for (int i = 0; i < entries.length; i++) {
          final entry = entries[i];
          if (i < collection.lines.length) {
            final line = collection.lines[i];
            // Update times and text from source view
            line.startTime = entry.startTime;
            line.endTime = entry.endTime;
            // Update edited text (preserve original)
            if (entry.text != line.original) {
              line.edited = entry.text;
            } else {
              line.edited = null; // Clear edit if it matches original
            }
          }
        }
        await isar.subtitleCollections.put(collection);
      });
      
      logInfo('SubtitleRepository: Successfully synced source view to database');
    } catch (e) {
      logError('SubtitleRepository: Error syncing source view: $e');
      rethrow;
    }
  }

  /// Create a checkpoint for the current state
  Future<void> createCheckpoint(
    int collectionId,
    int sessionId,
    String operationType,
    String description,
  ) async {
    logInfo('SubtitleRepository: Creating checkpoint "$description" for collection $collectionId');
    try {
      await CheckpointManager.createCheckpoint(
        subtitleCollectionId: collectionId,
        sessionId: sessionId,
        operationType: operationType,
        description: description,
        deltas: [], // Empty for manual checkpoints
      );
      logInfo('SubtitleRepository: Successfully created checkpoint');
    } catch (e) {
      logError('SubtitleRepository: Error creating checkpoint: $e');
      rethrow;
    }
  }

  /// Create initial checkpoint snapshot
  Future<void> createInitialSnapshot(
    int collectionId,
    int sessionId,
  ) async {
    logInfo('SubtitleRepository: Creating initial checkpoint snapshot for collection $collectionId');
    try {
      await CheckpointManager.createInitialSnapshot(
        subtitleCollectionId: collectionId,
        sessionId: sessionId,
      );
      logInfo('SubtitleRepository: Successfully created initial snapshot');
    } catch (e) {
      logWarning('SubtitleRepository: Could not create initial snapshot: $e');
      // Don't rethrow - this is not critical for basic functionality
    }
  }

  /// Update last edited session
  Future<void> updateLastEditedSession(int sessionId) async {
    logInfo('SubtitleRepository: Updating last edited session to $sessionId');
    try {
      await updateLastEditedSession(sessionId);
      logInfo('SubtitleRepository: Successfully updated last edited session');
    } catch (e) {
      logError('SubtitleRepository: Error updating last edited session: $e');
      rethrow;
    }
  }

  /// Get session edit mode
  Future<bool> getSessionEditMode(int sessionId) async {
    logInfo('SubtitleRepository: Fetching edit mode for session $sessionId');
    try {
      final editMode = await getSessionEditMode(sessionId);
      logInfo('SubtitleRepository: Session $sessionId edit mode: $editMode');
      return editMode;
    } catch (e) {
      logError('SubtitleRepository: Error fetching session edit mode: $e');
      rethrow;
    }
  }
}
