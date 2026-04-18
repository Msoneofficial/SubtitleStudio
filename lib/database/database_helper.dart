// Subtitle Studio v3 - Database Operations Layer
//
// This file provides the data access layer for the entire application using Isar database.
// It handles all CRUD operations for subtitle collections, editing sessions, and user preferences.
//
// Key Responsibilities:
// - Subtitle data storage and retrieval
// - Session management for editing workflows
// - Database transactions and error handling
// - Data migration and cleanup operations
// - Performance optimization for large subtitle files
//
// Architecture Notes:
// - Uses global Isar instance from main.dart
// - All operations wrapped in transactions for consistency
// - Comprehensive logging for debugging database issues
// - Error handling with graceful fallbacks
//
// iOS Port Implementation:
// - Replace Isar with Core Data or SQLite
// - Implement similar transaction patterns
// - Use iOS-native data persistence frameworks
// - Adapt queries to iOS database conventions
// - Consider iOS background processing limitations

import 'package:flutter/foundation.dart';     // Flutter debugging utilities
import 'package:isar_community/isar.dart';              // Isar database framework
import 'package:subtitle_studio/database/models/models.dart'; // Data models
import 'package:subtitle_studio/main.dart';      // Global Isar instance access
import 'package:subtitle_studio/utils/logging_helpers.dart'; // Logging utilities
import 'package:subtitle_studio/services/checkpoint_manager.dart'; // Checkpoint management
import 'package:subtitle_studio/utils/subtitle_sorting.dart'; // Enhanced subtitle sorting
import 'dart:math';                           // Math utilities for ID generation
import 'dart:io';                             // File and Directory operations
import 'package:path_provider/path_provider.dart'; // App directories access

/// Updates the macOsSrtBookmark for a SubtitleCollection
Future<bool> updateSubtitleCollectionMacOsSrtBookmark(int subtitleCollectionId, String? bookmarkString) async {
  try {
    await isar.writeTxn(() async {
      final subtitle = await isar.subtitleCollections.get(subtitleCollectionId);
      if (subtitle != null) {
        subtitle.macOsSrtBookmark = bookmarkString;
        await isar.subtitleCollections.put(subtitle);
      }
    });
    return true;
  } catch (e) {
    debugPrint('Error updating macOsSrtBookmark for subtitle collection: $e');
    return false;
  }
}

/// Store parsed subtitle data in the database with comprehensive metadata
///
/// This function handles the complete workflow of storing subtitle data:
/// 1. Creates a SubtitleCollection with all subtitle lines and metadata
/// 2. Stores the collection in a database transaction
/// 3. Creates an associated Session for editing workflow tracking
/// 4. Returns comprehensive data for immediate use by calling code
///
/// **Parameters:**
/// - [parsedLines]: List of SubtitleLine objects from parser
/// - [fileName]: Original file name for display and identification
/// - [encoding]: Character encoding detected/specified during import
/// - [filePath]: Full file path for potential re-import or reference
/// - [editMode]: Whether this is a new file (false) or existing edit (true)
/// - [originalFileUri]: Original file URI for SAF or future reference
/// - [macOsSrtBookmark]: Optional macOS security-scoped bookmark for the SRT file's directory
///
/// **Returns Map containing:**
/// - `subtitleCollectionId`: Database ID for the subtitle collection
/// - `fileName`: Original file name for UI display
/// - `lastEditedIndex`: null for new imports, index for continuing edits
/// - `sessionId`: Database ID for the editing session
///
/// **Error Handling:**
/// - All database operations wrapped in transactions
/// - Comprehensive logging for debugging
/// - Throws exceptions on critical failures for upstream handling
///
/// **iOS Implementation Notes:**
/// - Replace Isar transactions with Core Data save contexts
/// - Use NSManagedObjectContext for thread-safe operations
/// - Implement similar return pattern for consistency
/// - Consider iOS background app refresh limitations
Future<Map<String, dynamic>> storeSubtitleData(List<SubtitleLine> parsedLines,
    String fileName, String encoding, String filePath, {bool editMode = false, String? originalFileUri, String? projectFilePath, String? macOsSrtBookmark}) async {
  logInfo('Storing subtitle data: $fileName with ${parsedLines.length} lines');
  
  // Create subtitle collection with comprehensive metadata
  // This object contains all subtitle lines plus file information
  final subtitle = SubtitleCollection(
    fileName: fileName,        // Original file name for display
    encoding: encoding,        // Character encoding for proper text handling
    filePath: filePath,        // Full path for potential re-import
    originalFileUri: originalFileUri, // Store original URI for SAF
    lines: parsedLines,        // All parsed subtitle entries
    macOsSrtBookmark: macOsSrtBookmark, // Store bookmark if provided
  );

  // Store subtitle collection in database transaction
  // Transaction ensures data consistency if operation fails
  int subtitleId = 0;
  await isar.writeTxn(() async {
    subtitleId = await isar.subtitleCollections.put(subtitle);
  });

  logInfo('Subtitle collection stored with ID: $subtitleId');

  // Create editing session for workflow tracking
  // Sessions track user's editing progress and preferences
  final session = Session(
    subtitleCollectionId: subtitleId,  // Link to subtitle data
    fileName: fileName,                // Display name in recent files
    lastEditedIndex: null,             // Start from beginning for new imports
    editMode: editMode,                // Track if this is new or continued edit
    projectFilePath: projectFilePath,  // Store project file URI/path
  );

  // Store session in separate transaction for isolation
  int sessionId = 0;
  await isar.writeTxn(() async {
    sessionId = await isar.sessions.put(session);
  });

  // Return data needed by the UI
  return {
    "subtitleCollectionId": subtitleId,
    "fileName": fileName,
    "lastEditedIndex": null,
    "sessionId": sessionId,
    "editMode": editMode, // Include edit mode in returned data
    "session": session, // Include session object for project creation
    "subtitleCollection": subtitle, // Include subtitle collection for project creation
  };
}

/// Retrieves all sessions from the database
///
/// Returns a List of Session objects sorted by creation date
Future<List<Session>> getAllSessions() async {
  final sessions = await isar.sessions.where().findAll();
  debugPrint("Database sessions count: ${sessions.length}");
  return sessions;
}

/// Deletes a session and its associated subtitle collection
///
/// Parameters:
/// - [subtitleCollectionId]: ID of the subtitle collection to delete
/// - [sessionId]: ID of the session to delete
Future<void> deleteSession(int subtitleCollectionId, int sessionId) async {
  await isar.writeTxn(() async {
    await isar.subtitleCollections.delete(subtitleCollectionId);
    await isar.sessions.delete(sessionId);
  });
}

Future<void> saveThemeMode(String themeMode) async {
  final preferences = await isar.preferences.where().findFirst() ??
      Preferences(autoSave: false); // default value for required field

  preferences.themeMode = themeMode;

  await isar.writeTxn(() async {
    await isar.preferences.put(preferences);
  });
}

Future<String?> getThemeMode() async {
  final preferences = await isar.preferences.where().findFirst();
  return preferences?.themeMode;
}

Future<List<SubtitleLine>> fetchSubtitleLines(int subtitleCollectionId) async {
  final subtitle = await isar.subtitleCollections.get(subtitleCollectionId);
  return subtitle?.lines ?? [];
}

Future<int?> getLastEditedIndex(int sessionId) async {
  final session = await isar.sessions.get(sessionId);
  return session?.lastEditedIndex;
}

Future<void> updateLastEditedIndex(int sessionId, int newIndex) async {
  // Start a write transaction
  await isar.writeTxn(() async {
    // Get the session
    final session = await isar.sessions.get(sessionId);

    // Update the lastEditedIndex if session exists
    if (session != null) {
      session.lastEditedIndex = newIndex;
      // Save the updated session
      await isar.sessions.put(session);
    }
  });
}

Future<void> saveSubtitleChangesToDatabase(
    int subtitleId,
    SubtitleLine updatedLine,
    DateTime Function(String) parseTimeFunction,
    {int? sessionId, SubtitleLine? beforeLine}) async {
  // Store checkpoint info before transaction
  SubtitleLine? lineBeforeChanges;
  bool shouldCreateCheckpoint = false;
  
  await isar.writeTxn(() async {
    final existingSubtitle = await isar.subtitleCollections.get(subtitleId);
    if (existingSubtitle != null) {
      // Get the line before changes for checkpoint
      lineBeforeChanges = beforeLine ?? existingSubtitle.lines[updatedLine.index - 1];
      
      // Check if anything has changed (before we modify anything)
      if (sessionId != null && lineBeforeChanges != null) {
        shouldCreateCheckpoint = 
            lineBeforeChanges!.startTime != updatedLine.startTime ||
            lineBeforeChanges!.endTime != updatedLine.endTime ||
            lineBeforeChanges!.original != updatedLine.original ||
            lineBeforeChanges!.edited != updatedLine.edited;
      }
      
      // Update the specific line based on the index
      int index = updatedLine.index;
      existingSubtitle.lines[index - 1] = updatedLine;

      // Sort the lines intelligently (preserves overlaps, handles positioning tags)
      // This uses enhanced sorting: time -> index -> tag priority
      existingSubtitle.lines = sortAndReindexSubtitleLines(existingSubtitle.lines);

      // Save the updated subtitle collection
      await isar.subtitleCollections.put(existingSubtitle);
    }
  });
  
  // Create checkpoint OUTSIDE the transaction to avoid nested transaction error
  if (shouldCreateCheckpoint && sessionId != null && lineBeforeChanges != null) {
    await CheckpointManager.createEditCheckpoint(
      sessionId: sessionId,
      subtitleCollectionId: subtitleId,
      beforeLine: lineBeforeChanges!,
      afterLine: updatedLine,
    );
  }
}

// Function to read lastEditedSession from Preferences
Future<int?> getLastEditedSession() async {
  // Get the first Preferences record
  final preferences = await isar.preferences.where().findFirst();

  // Log the result

  // Return the lastEditedSession value if preferences exists
  return preferences?.lastEditedSession;
}

// Function to write lastEditedSession to Preferences
Future<void> updateLastEditedSession(int sessionId) async {
  // Check if the sessionId is valid
  if (sessionId <= 0) {
    if (kDebugMode) {
      print('Invalid session ID: $sessionId');
    }
    return;
  }

  await isar.writeTxn(() async {
    // Try to find existing preferences or create new one
    var preferences = await isar.preferences.where().findFirst() ??
        Preferences(autoSave: true); // Create new preferences if none exist

    // Update the lastEditedSession
    preferences.lastEditedSession = sessionId;

    // Save the preferences
    await isar.preferences.put(preferences);

    if (kDebugMode) {
      print('Updated last edited session to: $sessionId');
    }
  });
}

// Fetch subtitle data for compiling
Future<SubtitleCollection?> fetchSubtitle(int subtitleCollectionId) async {
  return await isar.subtitleCollections.get(subtitleCollectionId);
}

/// Deletes a subtitle line and reindexes the remaining lines
Future<bool> deleteSubtitleLineDB(int subtitleId, int lineIndex) async {
  return await isar.writeTxn(() async {
    final subtitle = await isar.subtitleCollections.get(subtitleId);
    if (subtitle == null) return false;

    final newLines = List<SubtitleLine>.from(subtitle.lines);
    if (lineIndex >= newLines.length) return false;

    newLines.removeAt(lineIndex);
    
    // Sort and reindex intelligently (preserves overlaps, handles positioning tags)
    subtitle.lines = sortAndReindexSubtitleLines(newLines);
    await isar.subtitleCollections.put(subtitle);
    return true;
  });
}

Future<bool> splitSubtitleLine(int subtitleId, SubtitleLine firstPart,
    SubtitleLine secondPart, int originalIndex) async {
  try {
    await isar.writeTxn(() async {
      final subtitle = await isar.subtitleCollections.get(subtitleId);
      if (subtitle != null) {
        // Create new list with both parts
        final newLines = List<SubtitleLine>.from(subtitle.lines);

        // Update the first part at the original index
        newLines[originalIndex] = firstPart;

        // Insert the second part after the original index
        newLines.insert(originalIndex + 1, secondPart);

        // Sort and reindex intelligently (preserves overlaps, handles positioning tags)
        subtitle.lines = sortAndReindexSubtitleLines(newLines);
        await isar.subtitleCollections.put(subtitle);
      }
    });
    return true;
  } catch (e) {
    debugPrint('Error splitting subtitle line: $e');
    return false;
  }
}

Future<bool> mergeSubtitleLines(int subtitleId, SubtitleLine mergedLine,
    int firstLineIndex, int secondLineIndex) async {
  try {
    await isar.writeTxn(() async {
      final subtitle = await isar.subtitleCollections.get(subtitleId);
      if (subtitle != null) {
        // Create new list without the merged lines
        final newLines = List<SubtitleLine>.from(subtitle.lines);

        // Remove the two lines being merged (remove higher index first)
        final maxIndex = max(firstLineIndex, secondLineIndex);
        final minIndex = min(firstLineIndex, secondLineIndex);
        newLines.removeAt(maxIndex);
        newLines.removeAt(minIndex);

        // Insert merged line at the position of the first line
        newLines.insert(minIndex, mergedLine);

        // Sort and reindex intelligently (preserves overlaps, handles positioning tags)
        subtitle.lines = sortAndReindexSubtitleLines(newLines);
        await isar.subtitleCollections.put(subtitle);
      }
    });
    return true;
  } catch (e) {
    debugPrint('Error merging subtitle lines: $e');
    return false;
  }
}

Future<bool> addSubtitleLine(
    int subtitleId, SubtitleLine newLine, int insertIndex) async {
  try {
    await isar.writeTxn(() async {
      final subtitle = await isar.subtitleCollections.get(subtitleId);
      if (subtitle != null) {
        // Create new list with the new line
        final newLines = List<SubtitleLine>.from(subtitle.lines);
        newLines.insert(insertIndex, newLine);

        // Sort and reindex intelligently (preserves overlaps, handles positioning tags)
        subtitle.lines = sortAndReindexSubtitleLines(newLines);
        await isar.subtitleCollections.put(subtitle);
      }
    });
    return true;
  } catch (e) {
    debugPrint('Error adding subtitle line: $e');
    return false;
  }
}

/// Updates multiple subtitle lines in the database
Future<bool> updateMultipleSubtitleLines(int subtitleId, List<SubtitleLine> updatedLines) async {
  try {
    await isar.writeTxn(() async {
      final subtitle = await isar.subtitleCollections.get(subtitleId);
      if (subtitle != null) {
        // Create a map of index to updated lines for quick lookup
        final updateMap = {for (var line in updatedLines) line.index: line};
        
        // Update each line in the collection that has a matching update
        for (int i = 0; i < subtitle.lines.length; i++) {
          final currentLineIndex = subtitle.lines[i].index;
          if (updateMap.containsKey(currentLineIndex)) {
            subtitle.lines[i] = updateMap[currentLineIndex]!;
          }
        }
        
        // Save the updated subtitle collection
        await isar.subtitleCollections.put(subtitle);
      }
    });
    return true;
  } catch (e) {
    debugPrint('Error updating multiple subtitle lines: $e');
    return false;
  }
}

/// Retrieves a session's edit mode status
Future<bool> getSessionEditMode(int sessionId) async {
  final session = await isar.sessions.get(sessionId);
  return session?.editMode ?? false; // Default to false if session not found
}

/// Updates a subtitle collection in the database
Future<bool> updateSubtitleCollection(SubtitleCollection subtitleCollection) async {
  try {
    await isar.writeTxn(() async {
      await isar.subtitleCollections.put(subtitleCollection);
    });
    return true;
  } catch (e) {
    debugPrint('Error updating subtitle collection: $e');
    return false;
  }
}

/// Marks or unmarks a subtitle line
Future<bool> markSubtitleLine(int subtitleId, int lineIndex, bool marked) async {
  try {
    bool updateSuccessful = false;
    String debugInfo = '';
    
    await isar.writeTxn(() async {
      final subtitle = await isar.subtitleCollections.get(subtitleId);
      
      if (subtitle == null) {
        debugInfo = 'Subtitle collection not found for id $subtitleId';
      } else if (lineIndex < 0) {
        debugInfo = 'Invalid lineIndex $lineIndex (negative)';
      } else if (lineIndex >= subtitle.lines.length) {
        debugInfo = 'Invalid lineIndex $lineIndex (>= ${subtitle.lines.length})';
      } else {
        // Valid operation
        subtitle.lines[lineIndex].marked = marked;
        await isar.subtitleCollections.put(subtitle);
        updateSuccessful = true;
        debugInfo = 'Successfully updated line $lineIndex to marked=$marked';
      }
    });
    
    debugPrint('MarkSubtitleLine: subtitleId=$subtitleId, lineIndex=$lineIndex, marked=$marked, result=$updateSuccessful - $debugInfo');
    return updateSuccessful;
  } catch (e) {
    debugPrint('Error marking subtitle line: $e');
    return false;
  }
}

/// Gets all marked subtitle lines for a subtitle collection
Future<List<SubtitleLine>> getMarkedSubtitleLines(int subtitleId) async {
  try {
    final subtitle = await isar.subtitleCollections.get(subtitleId);
    if (subtitle != null) {
      return subtitle.lines.where((line) => line.marked).toList();
    }
    return [];
  } catch (e) {
    debugPrint('Error getting marked subtitle lines: $e');
    return [];
  }
}

/// Gets all subtitle lines that have comments (marked or unmarked)
Future<List<SubtitleLine>> getAllSubtitleLinesWithComments(int subtitleId) async {
  try {
    final subtitle = await isar.subtitleCollections.get(subtitleId);
    if (subtitle != null) {
      return subtitle.lines.where((line) => line.comment?.trim().isNotEmpty == true).toList();
    }
    return [];
  } catch (e) {
    debugPrint('Error getting subtitle lines with comments: $e');
    return [];
  }
}

/// Updates the comment for a subtitle line
Future<bool> updateSubtitleLineComment(int subtitleId, int lineIndex, String? comment) async {
  try {
    await isar.writeTxn(() async {
      final subtitle = await isar.subtitleCollections.get(subtitleId);
      if (subtitle != null && lineIndex >= 0 && lineIndex < subtitle.lines.length) {
        subtitle.lines[lineIndex].comment = comment;
        await isar.subtitleCollections.put(subtitle);
      }
    });
    return true;
  } catch (e) {
    debugPrint('Error updating subtitle line comment: $e');
    return false;
  }
}

/// Gets the comment for a subtitle line
Future<String?> getSubtitleLineComment(int subtitleId, int lineIndex) async {
  try {
    final subtitle = await isar.subtitleCollections.get(subtitleId);
    if (subtitle != null && lineIndex >= 0 && lineIndex < subtitle.lines.length) {
      return subtitle.lines[lineIndex].comment;
    }
    return null;
  } catch (e) {
    debugPrint('Error getting subtitle line comment: $e');
    return null;
  }
}

/// Updates the resolved status for a subtitle line comment
Future<bool> updateSubtitleLineResolved(int subtitleId, int lineIndex, bool resolved) async {
  try {
    await isar.writeTxn(() async {
      final subtitle = await isar.subtitleCollections.get(subtitleId);
      if (subtitle != null && lineIndex >= 0 && lineIndex < subtitle.lines.length) {
        subtitle.lines[lineIndex].resolved = resolved;
        await isar.subtitleCollections.put(subtitle);
      }
    });
    return true;
  } catch (e) {
    debugPrint('Error updating subtitle line resolved status: $e');
    return false;
  }
}

/// Unmarks a subtitle line and clears its comment and resolved status
Future<bool> unmarkSubtitleLine(int subtitleId, int lineIndex) async {
  try {
    await isar.writeTxn(() async {
      final subtitle = await isar.subtitleCollections.get(subtitleId);
      if (subtitle != null && lineIndex >= 0 && lineIndex < subtitle.lines.length) {
        subtitle.lines[lineIndex].marked = false;
        subtitle.lines[lineIndex].comment = null;
        subtitle.lines[lineIndex].resolved = false;
        await isar.subtitleCollections.put(subtitle);
      }
    });
    return true;
  } catch (e) {
    debugPrint('Error unmarking subtitle line: $e');
    return false;
  }
}

/// Clear all dictionary entries from the database
Future<void> clearDictionaryEntries() async {
  await isar.writeTxn(() async {
    await isar.dictionaryEntrys.clear();
  });
}

/// Add dictionary entries in batches for better performance
Future<void> addDictionaryEntries(List<DictionaryEntry> entries) async {
  const batchSize = 1000;
  for (int i = 0; i < entries.length; i += batchSize) {
    final end = (i + batchSize < entries.length) ? i + batchSize : entries.length;
    final batch = entries.sublist(i, end);
    
    await isar.writeTxn(() async {
      await isar.dictionaryEntrys.putAll(batch);
    });
  }
}

/// Search dictionary entries by word and type
Future<List<DictionaryEntry>> searchDictionaryByWord(String query, String dictionaryType, {bool wholeWord = false, bool caseSensitive = false}) async {
  final allEntries = await isar.dictionaryEntrys.where().findAll();
  final matchingEntries = allEntries.where((entry) {
    if (entry.dictionaryType != dictionaryType) return false;
    
    if (wholeWord) {
      // For whole word matching, use Unicode-aware word boundaries
      // Create pattern that matches word at start, end, or surrounded by whitespace/punctuation
      final pattern = caseSensitive ? query : query.toLowerCase();
      final text = caseSensitive ? entry.word : entry.word.toLowerCase();
      
      // Check if query matches as a complete word (surrounded by word boundaries or string boundaries)
      final regexPattern = r'(?:^|[\\s\\p{P}\\p{Z}])' + RegExp.escape(pattern) + r'(?=[\\s\\p{P}\\p{Z}]|$)';
      final regex = RegExp(regexPattern, unicode: true, caseSensitive: caseSensitive);
      return regex.hasMatch(text);
    } else {
      // For partial matching, handle case sensitivity properly for Unicode
      if (caseSensitive) {
        return entry.word.contains(query);
      } else {
        // Use proper Unicode-aware case conversion
        return entry.word.toLowerCase().contains(query.toLowerCase());
      }
    }
  }).toList();
  
  // Sort results by relevance: exact matches first, then starts with, then contains
  return _sortDictionaryResults(matchingEntries, query, caseSensitive, true);
}

/// Search dictionary entries by meaning (for reverse lookup)
Future<List<DictionaryEntry>> searchDictionaryByMeaning(String query, String dictionaryType, {bool wholeWord = false, bool caseSensitive = false}) async {
  final allEntries = await isar.dictionaryEntrys.where().findAll();
  final matchingEntries = allEntries.where((entry) {
    if (entry.dictionaryType != dictionaryType) return false;
    
    if (wholeWord) {
      // For whole word matching, use Unicode-aware word boundaries
      final pattern = caseSensitive ? query : query.toLowerCase();
      final text = caseSensitive ? entry.meaning : entry.meaning.toLowerCase();
      
      // Check if query matches as a complete word (surrounded by word boundaries or string boundaries)
      final regexPattern = r'(?:^|[\\s\\p{P}\\p{Z}])' + RegExp.escape(pattern) + r'(?=[\\s\\p{P}\\p{Z}]|$)';
      final regex = RegExp(regexPattern, unicode: true, caseSensitive: caseSensitive);
      return regex.hasMatch(text);
    } else {
      // For partial matching, handle case sensitivity properly for Unicode
      if (caseSensitive) {
        return entry.meaning.contains(query);
      } else {
        // Use proper Unicode-aware case conversion
        return entry.meaning.toLowerCase().contains(query.toLowerCase());
      }
    }
  }).toList();
  
  // Sort results by relevance: exact matches first, then starts with, then contains
  return _sortDictionaryResults(matchingEntries, query, caseSensitive, false);
}

/// Sort dictionary search results by relevance
/// Prioritizes exact matches, then starts with, then contains
List<DictionaryEntry> _sortDictionaryResults(List<DictionaryEntry> entries, String query, bool caseSensitive, bool searchByWord) {
  if (entries.isEmpty || query.isEmpty) return entries;
  
  final normalizedQuery = caseSensitive ? query : query.toLowerCase();
  
  return entries..sort((a, b) {
    // Determine which field to search based on search type
    final textA = searchByWord 
        ? (caseSensitive ? a.word : a.word.toLowerCase())
        : (caseSensitive ? a.meaning : a.meaning.toLowerCase());
    final textB = searchByWord 
        ? (caseSensitive ? b.word : b.word.toLowerCase())
        : (caseSensitive ? b.meaning : b.meaning.toLowerCase());
    
    // Calculate relevance scores
    final scoreA = _calculateRelevanceScore(textA, normalizedQuery);
    final scoreB = _calculateRelevanceScore(textB, normalizedQuery);
    
    // Sort by score (higher score = more relevant = comes first)
    final scoreComparison = scoreB.compareTo(scoreA);
    if (scoreComparison != 0) return scoreComparison;
    
    // If scores are equal, sort alphabetically by the search field
    return textA.compareTo(textB);
  });
}

/// Calculate relevance score for dictionary search results
/// Higher score = more relevant
int _calculateRelevanceScore(String text, String query) {
  if (text == query) {
    // Exact match gets highest score
    return 1000;
  } else if (text.startsWith(query)) {
    // Starts with query gets high score
    return 500;
  } else if (text.contains(query)) {
    // Contains query gets medium score
    // Bonus points for shorter text (more relevant if query is larger portion)
    final lengthBonus = max(0, 100 - text.length);
    return 100 + lengthBonus;
  } else {
    // Should not happen in search results, but just in case
    return 0;
  }
}

/// Clear all application data including database and cached files
/// 
/// This function performs a complete data wipe:
/// 1. Clears all Isar database collections (Preferences, Sessions, SubtitleCollections, etc.)
/// 2. Deletes cached waveform files
/// 3. Removes any temporary files created by the app
/// 
/// Use this for:
/// - Resetting the app to factory defaults
/// - Troubleshooting database corruption issues
/// - Preparing app for fresh start
/// 
/// Warning: This operation is irreversible!
Future<void> clearAllApplicationData() async {
  logInfo('Starting complete data wipe...');
  
  try {
    // Clear all Isar database collections
    await isar.writeTxn(() async {
      // Clear all collections
      await isar.preferences.clear();
      await isar.sessions.clear();
      await isar.subtitleCollections.clear();
      await isar.checkpoints.clear();
      await isar.videoPreferences.clear();
      await isar.tutorialStatus.clear();
      // Note: We intentionally keep dictionaryEntrys (Olam dictionary data)
      // as it's downloaded content, not user data
      
      logInfo('Database collections cleared');
    });
    
    // Delete cached waveform files
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final waveformDir = Directory('${appDocDir.path}/waveforms');
      
      if (await waveformDir.exists()) {
        await waveformDir.delete(recursive: true);
        logInfo('Waveform cache cleared');
      }
    } catch (e) {
      logError('Error clearing waveform cache: $e');
      // Continue even if waveform cleanup fails
    }
    
    // Clean up temporary files
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final tempFiles = await tempDir.list().toList();
        for (final file in tempFiles) {
          try {
            if (file is File) {
              await file.delete();
            } else if (file is Directory) {
              await file.delete(recursive: true);
            }
          } catch (e) {
            // Skip files that can't be deleted (might be in use)
            logWarning('Could not delete temp file: ${file.path}');
          }
        }
        logInfo('Temporary files cleaned');
      }
    } catch (e) {
      logError('Error clearing temporary files: $e');
      // Continue even if temp cleanup fails
    }
    
    logInfo('Data wipe completed successfully');
  } catch (e, stackTrace) {
    logError('Error during data wipe: $e\n$stackTrace');
    rethrow;
  }
}

/// Clear all subtitle sessions and related data
/// 
/// This function clears:
/// 1. All subtitle sessions
/// 2. All subtitle collections
/// 3. All checkpoints (edit history)
/// 4. All video preferences
/// 5. Cached waveform files
/// 
/// Preserves:
/// - App settings and preferences
/// - Dictionary data
/// - Tutorial status
/// 
/// Use this for:
/// - Starting fresh with subtitle projects
/// - Clearing workspace without losing app configuration
/// - Freeing up storage space used by subtitles
Future<void> clearAllSessions() async {
  logInfo('Clearing all subtitle sessions...');
  
  try {
    // Clear session-related database collections
    await isar.writeTxn(() async {
      await isar.sessions.clear();
      await isar.subtitleCollections.clear();
      await isar.checkpoints.clear();
      await isar.videoPreferences.clear();
      
      logInfo('Session database collections cleared');
    });
    
    // Delete cached waveform files
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final waveformDir = Directory('${appDocDir.path}/waveforms');
      
      if (await waveformDir.exists()) {
        await waveformDir.delete(recursive: true);
        logInfo('Waveform cache cleared');
      }
    } catch (e) {
      logError('Error clearing waveform cache: $e');
      // Continue even if waveform cleanup fails
    }
    
    logInfo('All sessions cleared successfully');
  } catch (e, stackTrace) {
    logError('Error clearing sessions: $e\n$stackTrace');
    rethrow;
  }
}