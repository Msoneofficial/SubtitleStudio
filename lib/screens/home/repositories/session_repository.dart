import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';

/// Repository for managing subtitle editing sessions
/// 
/// This repository abstracts database operations and business logic
/// from the UI layer, following the Repository Pattern for clean architecture.
/// 
/// Responsibilities:
/// - Fetch all sessions from database
/// - Get last edited session information
/// - Delete sessions and related data
/// - Update session metadata
/// - Analyze session content (line counts, languages, etc.)
/// 
/// Benefits:
/// - Single source of truth for session data
/// - Testable business logic separate from UI
/// - Consistent error handling and logging
/// - Easy to mock for testing
class SessionRepository {
  /// Singleton instance
  static final SessionRepository instance = SessionRepository._internal();
  
  SessionRepository._internal();
  
  /// Fetches all sessions from the database in reverse chronological order
  /// 
  /// Returns a list of sessions sorted with newest first.
  /// Logs errors and returns empty list on failure.
  Future<List<Session>> fetchAllSessions() async {
    try {
      await logInfo('SessionRepository: Fetching all sessions from database');
      
      final sessions = await getAllSessions();
      final reversedSessions = sessions.reversed.toList();
      
      await logInfo('SessionRepository: Successfully fetched ${reversedSessions.length} sessions');
      return reversedSessions;
    } catch (e, stackTrace) {
      await logError(
        'SessionRepository: Error fetching sessions',
        context: 'fetchAllSessions',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
  
  /// Gets the ID of the last edited session
  /// 
  /// Returns null if no session has been edited or if there's an error.
  Future<int?> getLastEditedSessionId() async {
    try {
      await logInfo('SessionRepository: Fetching last edited session ID');
      
      final lastEditedId = await getLastEditedSession();
      
      if (lastEditedId != null) {
        await logInfo('SessionRepository: Last edited session ID: $lastEditedId');
      } else {
        await logInfo('SessionRepository: No last edited session found');
      }
      
      return lastEditedId;
    } catch (e, stackTrace) {
      await logError(
        'SessionRepository: Error fetching last edited session ID',
        context: 'getLastEditedSessionId',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Finds the last edited session from a list of sessions
  /// 
  /// Parameters:
  /// - [sessions]: List of all available sessions
  /// - [lastEditedId]: ID of the last edited session
  /// 
  /// Returns the session if found, null otherwise.
  Session? findLastEditedSession(List<Session> sessions, int? lastEditedId) {
    if (lastEditedId == null) return null;
    
    try {
      final session = sessions.firstWhere(
        (session) => session.id == lastEditedId,
      );
      
      logInfo('SessionRepository: Found last edited session: ${session.fileName}');
      return session;
    } catch (e) {
      logWarning(
        'SessionRepository: Last edited session with ID $lastEditedId not found in list',
        context: 'findLastEditedSession',
      );
      return null;
    }
  }
  
  /// Deletes a session and all its associated data
  /// 
  /// This permanently removes:
  /// - The session record
  /// - All subtitle lines
  /// - Related metadata
  /// 
  /// Parameters:
  /// - [session]: Session to delete
  /// 
  /// Throws an exception if deletion fails.
  Future<void> removeSession(Session session) async {
    try {
      await logInfo(
        'SessionRepository: Deleting session: ${session.fileName}',
        context: 'removeSession',
      );
      
      await deleteSession(session.subtitleCollectionId, session.id);
      
      await logInfo(
        'SessionRepository: Successfully deleted session: ${session.fileName}',
        context: 'removeSession',
      );
    } catch (e, stackTrace) {
      await logError(
        'SessionRepository: Error deleting session: ${session.fileName}',
        context: 'removeSession',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Updates the last edited session ID
  /// 
  /// Parameters:
  /// - [sessionId]: ID of the session to mark as last edited
  Future<void> setLastEditedSession(int sessionId) async {
    try {
      await logInfo(
        'SessionRepository: Updating last edited session to ID: $sessionId',
        context: 'setLastEditedSession',
      );
      
      await updateLastEditedSession(sessionId);
      
      await logInfo(
        'SessionRepository: Successfully updated last edited session',
        context: 'setLastEditedSession',
      );
    } catch (e, stackTrace) {
      await logError(
        'SessionRepository: Error updating last edited session',
        context: 'setLastEditedSession',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Gets comprehensive information about a session
  /// 
  /// Returns a map containing:
  /// - totalLines: Total number of subtitle lines
  /// - editedLines: Number of edited lines
  /// - lastEditedIndex: Index of last edited line
  /// - languageCodes: Detected language codes (e.g., "EN/ML")
  /// - languages: List of detected languages
  /// 
  /// Parameters:
  /// - [session]: Session to analyze
  Future<Map<String, dynamic>> getSessionInfo(Session session) async {
    try {
      final subtitleLines = await fetchSubtitleLines(session.subtitleCollectionId);
      final editedCount = subtitleLines
          .where((line) => line.edited != null && line.edited!.isNotEmpty)
          .length;
      
      // Language detection
      final detectedLanguageCodes = _detectLanguages(subtitleLines);
      
      return {
        'totalLines': subtitleLines.length,
        'editedLines': editedCount,
        'lastEditedIndex': session.lastEditedIndex ?? 1,
        'languageCodes': detectedLanguageCodes.join('/'),
        'languages': detectedLanguageCodes.toList(),
      };
    } catch (e, stackTrace) {
      await logError(
        'SessionRepository: Error getting session info for: ${session.fileName}',
        context: 'getSessionInfo',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Return default values on error
      return {
        'totalLines': 0,
        'editedLines': 0,
        'lastEditedIndex': 1,
        'languageCodes': 'EN',
        'languages': ['EN'],
      };
    }
  }
  
  /// Detects if a session contains MSone subtitles
  /// 
  /// Checks for MSone-specific keywords in the last 5 lines
  /// and in the filename.
  /// 
  /// Parameters:
  /// - [session]: Session to check
  /// 
  /// Returns true if MSone content is detected.
  Future<bool> isMSoneSubtitle(Session session) async {
    try {
      final subtitleLines = await fetchSubtitleLines(session.subtitleCollectionId);
      
      // Check last 5 lines for MSone keywords
      final linesToCheck = subtitleLines.length >= 5
          ? subtitleLines.sublist(subtitleLines.length - 5)
          : subtitleLines;
      
      for (final line in linesToCheck) {
        final text = (line.original + (line.edited ?? '')).toLowerCase();
        if (text.contains('www.malayalamsubtitles.org') ||
            text.contains('msone') ||
            text.contains('msonepage')) {
          return true;
        }
      }
      
      // Fallback to filename check
      final fileName = session.fileName.toLowerCase();
      return fileName.contains('malayalamsubtitles') || fileName.contains('msone');
    } catch (e, stackTrace) {
      await logWarning(
        'SessionRepository: Error detecting MSone subtitle for: ${session.fileName}',
        context: 'isMSoneSubtitle',
        stackTrace: stackTrace,
      );
      
      // Fallback to filename check on error
      final fileName = session.fileName.toLowerCase();
      return fileName.contains('malayalamsubtitles') || fileName.contains('msone');
    }
  }
  
  /// Detects languages present in subtitle lines
  /// 
  /// Analyzes the first 10 lines for common scripts:
  /// - Malayalam, Hindi, Arabic, Chinese, Japanese, Korean, Russian
  /// 
  /// Returns a set of language codes (e.g., {"EN", "ML", "HI"})
  Set<String> _detectLanguages(List<SubtitleLine> subtitleLines) {
    Set<String> detectedLanguageCodes = {'EN'}; // Default English
    
    // Check first 10 lines for performance
    final linesToCheck = subtitleLines.length >= 10
        ? subtitleLines.take(10)
        : subtitleLines;
    
    for (final line in linesToCheck) {
      final text = line.original + (line.edited ?? '');
      
      if (_containsScript(text, 'Malayalam')) detectedLanguageCodes.add('ML');
      if (_containsScript(text, 'Hindi')) detectedLanguageCodes.add('HI');
      if (_containsScript(text, 'Arabic')) detectedLanguageCodes.add('AR');
      if (_containsScript(text, 'Chinese')) detectedLanguageCodes.add('ZH');
      if (_containsScript(text, 'Japanese')) detectedLanguageCodes.add('JA');
      if (_containsScript(text, 'Korean')) detectedLanguageCodes.add('KO');
      if (_containsScript(text, 'Russian')) detectedLanguageCodes.add('RU');
    }
    
    return detectedLanguageCodes;
  }
  
  /// Checks if text contains characters from a specific script
  bool _containsScript(String text, String script) {
    switch (script) {
      case 'Malayalam':
        return RegExp(r'[\u0D00-\u0D7F]').hasMatch(text);
      case 'Hindi':
        return RegExp(r'[\u0900-\u097F]').hasMatch(text);
      case 'Arabic':
        return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
      case 'Chinese':
        return RegExp(r'[\u4E00-\u9FFF]').hasMatch(text);
      case 'Japanese':
        return RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').hasMatch(text);
      case 'Korean':
        return RegExp(r'[\uAC00-\uD7AF]').hasMatch(text);
      case 'Russian':
        return RegExp(r'[\u0400-\u04FF]').hasMatch(text);
      default:
        return false;
    }
  }
}
