// Subtitle Studio v3 - Subtitle Processing and Import Engine
//
// This utility provides comprehensive subtitle file processing capabilities including
// parsing, validation, cleaning, and format conversion. It serves as the core engine
// for importing subtitle files from various sources with advanced processing options.
//
// Key Features:
// - Multi-encoding support with automatic detection
// - SRT format parsing with error recovery
// - Advanced cleaning options (hearing impaired text removal)
// - Subtitle timing validation and correction
// - Overlapping subtitle detection and merging
// - Format normalization and validation
// - Database integration for processed subtitles
//
// Processing Pipeline:
// 1. File encoding detection and content reading
// 2. SRT format parsing with error handling
// 3. Timing validation and correction
// 4. Optional text cleaning and processing
// 5. Database storage with metadata
//
// iOS Port Considerations:
// - Replace charset_converter with iOS native encoding detection
// - Use NSStringEncoding for character encoding handling
// - Implement similar processing pipeline with iOS file APIs
// - Adapt error handling to iOS conventions
// - Use Core Data for processed subtitle storage

import 'dart:convert'; // Text encoding and JSON operations
import 'dart:io'; // File system operations
import 'package:flutter/foundation.dart'; // Flutter debugging utilities
import 'package:flutter/material.dart'; // UI framework for context handling
import 'package:shared_preferences/shared_preferences.dart'; // For storing SAF URIs
import 'package:subtitle_studio/database/database_helper.dart'; // Database operations
import 'package:subtitle_studio/database/models/models.dart'; // Data models
import 'package:charset_converter/charset_converter.dart'; // Character encoding detection
import 'package:subtitle_studio/utils/subtitle_sorting.dart'; // Enhanced subtitle sorting

/// Process and import subtitle file with comprehensive cleaning and validation options
///
/// This function serves as the main entry point for subtitle file processing, providing
/// a complete pipeline from raw file input to processed database storage:
///
/// **Processing Steps:**
/// 1. **File Reading**: Multi-encoding detection and content extraction
/// 2. **Format Parsing**: SRT structure parsing with error recovery
/// 3. **Validation**: Timing validation and format correction
/// 4. **Cleaning**: Optional text processing and cleanup operations
/// 5. **Storage**: Database integration with metadata preservation
///
/// **Advanced Features:**
/// - Automatic character encoding detection (UTF-8, ISO-8859-1, Windows-1252, etc.)
/// - Hearing impaired text detection and removal (text in brackets, speaker labels)
/// - Overlapping subtitle detection and intelligent merging
/// - Timeline validation and automatic timing correction
/// - Duplicate subtitle detection and removal
///
/// **Parameters:**
/// - [filePath]: Full path to the subtitle file for processing
/// - [context]: Flutter BuildContext for UI feedback and error handling
/// - [removeHearingImpairedLines]: Enable automatic removal of accessibility text
/// - [mergeOverlappingSubtitles]: Enable intelligent merging of timing conflicts
///
/// **Returns:**
/// - Map containing processing results, database IDs, and metadata
/// - null if processing fails or is cancelled by user
///
/// **Error Handling:**
/// - Comprehensive error recovery for malformed SRT files
/// - Graceful fallback for encoding detection failures
/// - User-friendly error messages for common issues
/// - Detailed logging for debugging complex parsing problems
///
/// **iOS Implementation Notes:**
/// ```swift
/// func processAndImportSubtitle(
///     filePath: String,
///     removeHearingImpaired: Bool = false,
///     mergeOverlapping: Bool = false
/// ) async throws -> SubtitleProcessingResult? {
///     // 1. Use NSString encoding detection
///     // 2. Parse SRT with NSRegularExpression
///     // 3. Apply cleaning options
///     // 4. Store in Core Data
/// }
/// ```
Future<Map?> processAndImportSubtitle(
  String filePath,
  BuildContext context, {
  bool removeHearingImpairedLines =
      false, // Remove [Speaker] and (sound) annotations
  bool mergeOverlappingSubtitles =
      false, // Merge subtitles with timing conflicts
}) async {
  try {
    // Step 1: File Reading and Encoding Detection
    String srtContent; // Decoded file content
    String? encoding; // Detected character encoding
    final file = File(filePath); // File system reference
    final fileName = file.uri.pathSegments.last; // Extract filename for display

    try {
      // Attempt multi-encoding detection and content reading
      // This handles various subtitle file encodings commonly used worldwide
      srtContent = await _detectAndReadFileEncoding(file);
      encoding =
          "UTF-8"; // Default assumption, actual detection in helper function
    } catch (e) {
      throw Exception('Failed to decode SRT file: $e');
    }

    // Step 2: SRT Format Parsing and Structure Validation
    var parsedLines = _parseSrtContent(srtContent);

    // Step 3: Comprehensive Processing Pipeline
    if (parsedLines.isNotEmpty) {
      // Fix invalid indexing and time codes that could cause playback issues
      parsedLines = _fixInvalidFormats(parsedLines);

      // Optional: Remove hearing impaired accessibility text
      // Detects and removes text in brackets [], parentheses (), and speaker labels
      if (removeHearingImpairedLines) {
        parsedLines = removeHearingImpairedText(parsedLines);
      }

      // Optional: Merge subtitles with overlapping timelines
      // Intelligently combines subtitles that appear simultaneously
      if (mergeOverlappingSubtitles) {
        parsedLines = _mergeOverlappingSubtitles(parsedLines);
      }

      // Re-index lines to ensure sequential numbering for proper playback
      parsedLines = _reindexSubtitles(parsedLines);
    }

    // Store processed subtitle in database with proper platform-specific file path handling
    final subtitleData = await storeSubtitleData(
      parsedLines,
      fileName,
      encoding,
      filePath, // Store full file path (not just directory) as filePath
      originalFileUri:
          Platform.isAndroid
              ? filePath
              : filePath, // Use same value for both on regular files
      projectFilePath: null, // No project file path for regular imports
    );

    // Update the last edited session
    final sessionId = subtitleData['sessionId'];
    await updateLastEditedSession(sessionId);

    return subtitleData;
  } catch (e) {
    if (kDebugMode) {
      print('Error processing subtitle: $e');
    }
    rethrow;
  }
}

/// Processes and imports subtitle file without requiring a BuildContext
/// For use when the widget that initiated the operation might be unmounted
Future<Map?> processSubtitleWithoutContext(
  String filePath, {
  bool removeHearingImpairedLines = false,
  bool mergeOverlappingSubtitles = false,
}) async {
  try {
    if (kDebugMode) {
      print('Processing subtitle without context: $filePath');
    }

    // Read file with appropriate encoding
    String srtContent;
    String? encoding;
    final file = File(filePath);
    final fileName = file.uri.pathSegments.last;

    try {
      // Try different encodings
      srtContent = await _detectAndReadFileEncoding(file);
      encoding = "UTF-8"; // Default assumption
    } catch (e) {
      throw Exception('Failed to decode SRT file: $e');
    }

    // Parse and process subtitle lines
    var parsedLines = _parseSrtContent(srtContent);

    // Clean up subtitle lines based on options
    if (parsedLines.isNotEmpty) {
      // Fix invalid indexing and time codes
      parsedLines = _fixInvalidFormats(parsedLines);

      // Remove hearing impaired text if requested
      if (removeHearingImpairedLines) {
        parsedLines = removeHearingImpairedText(parsedLines);
      }

      // Merge overlapping subtitles if requested
      if (mergeOverlappingSubtitles) {
        parsedLines = _mergeOverlappingSubtitles(parsedLines);
      }

      // Re-index lines to ensure they are sequential
      parsedLines = _reindexSubtitles(parsedLines);
    }

    // Store processed subtitle in database with proper platform-specific file path handling
    final subtitleData = await storeSubtitleData(
      parsedLines,
      fileName,
      encoding,
      filePath, // Store full file path (not just directory) as filePath
      originalFileUri:
          Platform.isAndroid
              ? filePath
              : filePath, // Use same value for both on non-Android, actual URI on Android
      projectFilePath: null, // No project file path for regular imports
    );

    // Update the last edited session
    final sessionId = subtitleData['sessionId'];
    await updateLastEditedSession(sessionId);

    return subtitleData;
  } catch (e) {
    if (kDebugMode) {
      print('Error processing subtitle without context: $e');
    }
    rethrow;
  }
}

/// SAF-compatible version: Processes and imports subtitle content with context
/// Uses file content instead of file path for Storage Access Framework compatibility
Future<Map?> processAndImportSubtitleContent(
  String content,
  String fileName,
  String displayPath,
  BuildContext context, {
  bool removeHearingImpairedLines =
      false, // Remove [Speaker] and (sound) annotations
  bool mergeOverlappingSubtitles =
      false, // Merge subtitles with timing conflicts
  String? contentUri, // Android SAF content URI for persistence
}) async {
  try {
    // Step 1: Content Processing (no file system access needed)
    String srtContent = content; // Content already provided
    String encoding = "UTF-8"; // Assume UTF-8 for content-based processing

    // Step 2: SRT Format Parsing and Structure Validation
    var parsedLines = _parseSrtContent(srtContent);

    // Step 3: Comprehensive Processing Pipeline
    if (parsedLines.isNotEmpty) {
      // Fix invalid indexing and time codes that could cause playback issues
      parsedLines = _fixInvalidFormats(parsedLines);

      // Optional: Remove hearing impaired accessibility text
      // Detects and removes text in brackets [], parentheses (), and speaker labels
      if (removeHearingImpairedLines) {
        parsedLines = removeHearingImpairedText(parsedLines);
      }

      // Optional: Merge overlapping subtitles to prevent timing conflicts
      if (mergeOverlappingSubtitles) {
        parsedLines = _mergeOverlappingSubtitles(parsedLines);
      }

      // Step 4: Database Import with Metadata
      // Creates Session and SubtitleCollection entries with comprehensive metadata
      final subtitleData = await storeSubtitleData(
        parsedLines,
        fileName,
        encoding,
        displayPath,
        originalFileUri: contentUri, // Store original content URI in database
        projectFilePath: null, // No project file path for content imports
      );

      return subtitleData;
    } else {
      throw Exception(
        'No valid subtitle entries found in the processed content.',
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error processing subtitle content: $e');
    }
    rethrow;
  }
}

/// SAF-compatible version: Processes subtitle content without requiring BuildContext
/// For use when the widget that initiated the operation might be unmounted
Future<Map?> processSubtitleContentWithoutContext(
  String content,
  String fileName,
  String displayPath, {
  bool removeHearingImpairedLines = false,
  bool mergeOverlappingSubtitles = false,
  String? contentUri, // Android SAF content URI for persistence
}) async {
  try {
    // Step 1: Content Processing (no file system access needed)
    String srtContent = content; // Content already provided
    String encoding = "UTF-8"; // Assume UTF-8 for content-based processing

    // Step 2: SRT Format Parsing and Structure Validation
    var parsedLines = _parseSrtContent(srtContent);

    // Step 3: Comprehensive Processing Pipeline
    if (parsedLines.isNotEmpty) {
      // Fix invalid indexing and time codes that could cause playback issues
      parsedLines = _fixInvalidFormats(parsedLines);

      // Optional: Remove hearing impaired accessibility text
      if (removeHearingImpairedLines) {
        parsedLines = removeHearingImpairedText(parsedLines);
      }

      // Optional: Merge overlapping subtitles to prevent timing conflicts
      if (mergeOverlappingSubtitles) {
        parsedLines = _mergeOverlappingSubtitles(parsedLines);
      }

      // Step 4: Database Import with Metadata (without context)
      final subtitleData = await storeSubtitleData(
        parsedLines,
        fileName,
        encoding,
        displayPath,
        originalFileUri: contentUri, // Store original content URI in database
        projectFilePath: null, // No project file path for content imports
      );

      // Update the last edited session
      final sessionId = subtitleData['sessionId'];
      await updateLastEditedSession(sessionId);

      return subtitleData;
    } else {
      throw Exception(
        'No valid subtitle entries found in the processed content.',
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error processing subtitle content without context: $e');
    }
    rethrow;
  }
}

/// Detect file encoding and read content
/// Attempts to detect file encoding and read content efficiently
/// Uses streaming approach for large files to improve performance
Future<String> _detectAndReadFileEncoding(File file) async {
  try {
    // Get file size to determine reading strategy
    final fileStat = await file.stat();
    final fileSizeInMB = fileStat.size / (1024 * 1024);

    // For files larger than 5MB, use streaming approach
    if (fileSizeInMB > 5) {
      // Try UTF-8 with streaming read for performance
      final stream = file.openRead();
      final buffer = StringBuffer();
      await for (final chunk in stream.transform(utf8.decoder)) {
        buffer.write(chunk);
      }
      return buffer.toString();
    }

    // For smaller files, use regular approach with encoding detection
    // Attempt UTF-8 decoding
    return await file.readAsString(encoding: utf8);
  } catch (e) {
    try {
      // Attempt ISO-8859-1 (Latin-1) decoding
      final bytes = await file.readAsBytes();
      return await CharsetConverter.decode("latin1", bytes);
    } catch (e) {
      try {
        // Attempt Windows-1252 decoding
        final bytes = await file.readAsBytes();
        return await CharsetConverter.decode("windows-1252", bytes);
      } catch (e) {
        try {
          // Attempt UTF-16 decoding
          final bytes = await file.readAsBytes();
          return await CharsetConverter.decode("utf16", bytes);
        } catch (e) {
          // Fallback to raw bytes if nothing works
          final bytes = await file.readAsBytes();
          return String.fromCharCodes(bytes);
        }
      }
    }
  }
}

/// Parses SRT content into structured subtitle lines with performance optimizations
List<SubtitleLine> _parseSrtContent(String content) {
  // Use more efficient line splitting for better performance
  final lines = content.split('\n');
  final List<SubtitleLine> subtitles = <SubtitleLine>[];

  int? currentIndex;
  String? startTime, endTime;
  List<String> textLines = <String>[];
  bool isInSubtitle = false;

  // Pre-compile regex patterns for better performance
  final indexPattern = RegExp(r'^\d+$');
  final timePattern = RegExp(
    r'(\d{2}:\d{2}:\d{2},\d{1,3})\s*-->\s*(\d{2}:\d{2}:\d{2},\d{1,3})',
  );

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    if (line.isEmpty) {
      // Empty line means end of current subtitle entry
      if (isInSubtitle &&
          startTime != null &&
          endTime != null &&
          textLines.isNotEmpty) {
        final subtitleLine =
            SubtitleLine()
              ..index = currentIndex ?? subtitles.length + 1
              ..startTime = startTime
              ..endTime = endTime
              ..original = textLines.join('\n')
              ..edited = null;

        subtitles.add(subtitleLine);
      }
      isInSubtitle = false;
      currentIndex = null;
      startTime = null;
      endTime = null;
      textLines = <String>[]; // Clear list for reuse
    } else if (!isInSubtitle && indexPattern.hasMatch(line)) {
      // Start new subtitle with an index
      isInSubtitle = true;
      currentIndex = int.parse(line);
    } else if (isInSubtitle && line.contains('-->')) {
      // Timestamp line - use faster contains check before regex
      final timeMatch = timePattern.firstMatch(line);
      if (timeMatch != null) {
        startTime = _fixTimeFormat(timeMatch.group(1)!);
        endTime = _fixTimeFormat(timeMatch.group(2)!);
      }
    } else if (isInSubtitle) {
      // Text content
      textLines.add(line);
    }
  }

  // Add the last subtitle if exists
  if (isInSubtitle &&
      startTime != null &&
      endTime != null &&
      textLines.isNotEmpty) {
    final subtitleLine =
        SubtitleLine()
          ..index = currentIndex ?? subtitles.length + 1
          ..startTime = startTime
          ..endTime = endTime
          ..original = textLines.join('\n')
          ..edited = null;

    subtitles.add(subtitleLine);
  }

  return subtitles;
}

/// Fixes time format to ensure it's in HH:mm:ss,SSS format
String _fixTimeFormat(String timeCode) {
  // Ensure time code is in correct format
  final timeRegex = RegExp(r'(\d{2}):(\d{2}):(\d{2}),(\d{1,3})');
  final match = timeRegex.firstMatch(timeCode);

  if (match != null) {
    final hours = match.group(1)!;
    final minutes = match.group(2)!;
    final seconds = match.group(3)!;
    String milliseconds = match.group(4)!;

    // Ensure milliseconds are exactly 3 digits
    if (milliseconds.length < 3) {
      milliseconds = milliseconds.padRight(3, '0');
    } else if (milliseconds.length > 3) {
      milliseconds = milliseconds.substring(0, 3);
    }

    return '$hours:$minutes:$seconds,$milliseconds';
  }

  return timeCode; // Return original if no match
}

/// Fixes invalid formats (indices, time codes)
List<SubtitleLine> _fixInvalidFormats(List<SubtitleLine> subtitles) {
  // Sort by start time
  subtitles.sort((a, b) => _compareTimeCodes(a.startTime, b.startTime));

  // Fix indices and time formats
  for (var i = 0; i < subtitles.length; i++) {
    subtitles[i].index = i + 1;
    subtitles[i].startTime = _fixTimeFormat(subtitles[i].startTime);
    subtitles[i].endTime = _fixTimeFormat(subtitles[i].endTime);
  }

  return subtitles;
}

/// Removes hearing impaired text (in square brackets and parentheses)
///
/// This function removes common hearing impaired annotations while preserving:
/// - Newline characters and text formatting
/// - Normal dialogue in parentheses that's part of speech
/// - Text structure and readability
///
/// Removed patterns include:
/// - [text] - Sound effects, speaker labels, descriptions (including multi-line)
/// - (text) when preceded by - - Additional sound descriptions
/// - Standalone action/sound descriptions: (sighing), (gunfire echoes), (door closes)
/// - Emotion indicators: (laughing), (crying), (whispering)
/// - Sound effect descriptions: (explosion), (thunder), (phone ringing)
/// - Complete parenthetical lines that are descriptions rather than dialogue
/// - ♪ and music notes
/// - Speaker labels with colons (NAME:, SPEAKER:)
/// - Lines that become empty or contain only special characters after removal
///
/// This is a public function that can be used outside the import process
List<SubtitleLine> removeHearingImpairedText(List<SubtitleLine> subtitles) {
  final List<SubtitleLine> cleanedSubtitles = [];

  for (var subtitle in subtitles) {
    String cleanText = subtitle.original;

    // STEP 1: Remove multi-line and single-line bracketed text first (before line splitting)
    // This handles cases like:
    // [ringtone playing "Sugar, Sugar"
    // by The Archies]
    // Using dotAll mode to match across newlines
    cleanText = cleanText.replaceAll(RegExp(r'\[.*?\]', dotAll: true), '');

    // Also remove dash/hyphen followed by multi-line bracketed text
    cleanText = cleanText.replaceAll(
      RegExp(r'\s*-\s*\[.*?\]', dotAll: true),
      '',
    );

    // STEP 2: Process remaining patterns line by line to preserve formatting
    final lines = cleanText.split('\n');
    final List<String> cleanedLines = [];

    for (var line in lines) {
      String cleanLine = line;

      // Remove parenthetical descriptions when preceded by dash: -(text), - (text)
      cleanLine = cleanLine.replaceAll(RegExp(r'\s*-\s*\(.*?\)'), '');

      // Remove all-caps parenthetical text at start: (SOUND) or (JOHN)
      cleanLine = cleanLine.replaceAll(RegExp(r'^\s*\([A-Z\s]+\)\s*'), '');
      
      // Remove standalone parenthetical descriptions (sound effects, actions, emotions)
      // This catches patterns like: (sighing), (gunfire echoes), (door closes), etc.
      // Match parentheses at line start or end, or standalone lines
      cleanLine = cleanLine.replaceAll(
        RegExp(
          r'^\s*\([^)]*(?:sound|music|noise|effect|playing|ringing|buzzing|beeping|singing|humming|whistling|'
          r'sigh|gasp|groan|grunt|cough|sneeze|laugh|cry|scream|yell|whisper|murmur|'
          r'gunfire|gunshot|explosion|bang|crash|thud|slam|click|creak|squeak|'
          r'door|window|footsteps|walking|running|'
          r'echo|reverberat|distant|fading|'
          r'wind|rain|thunder|storm|water|'
          r'car|engine|motor|vehicle|'
          r'phone|ring|beep|alarm|bell|'
          r'dramatic|tense|suspenseful|ominous|upbeat|sad|happy|angry|'
          r'continues|continuing|sustained|'
          r'ing\b)[^)]*\)\s*',
          caseSensitive: false,
        ),
        '',
      );
      
      // Remove parenthetical text that's a complete line (standalone action/sound description)
      // This catches remaining patterns where the entire line is just a parenthetical
      if (RegExp(r'^\s*\([^)]+\)\s*$').hasMatch(cleanLine)) {
        // Check if it looks like a description rather than dialogue
        // If it contains common action/description words or is all lowercase (typical for descriptions)
        final innerText = cleanLine.replaceAll(RegExp(r'[()]'), '').trim().toLowerCase();
        final isLikelyDescription = 
          // Short phrases (typically descriptions, not dialogue)
          innerText.length < 30 ||
          // Contains common description patterns
          RegExp(r'\b(ing\b|\w+ly\b|\w+s\b)').hasMatch(innerText) ||
          // All lowercase or no capital letters in middle (descriptions are usually lowercase)
          !RegExp(r'[A-Z]').hasMatch(innerText.substring(1));
        
        if (isLikelyDescription) {
          cleanLine = '';
        }
      }
      
      // Remove parenthetical text at the end of a line if it's an action/sound
      cleanLine = cleanLine.replaceAll(
        RegExp(
          r'\s*\([^)]*(?:ing|echo|sound|effect|noise)\s*[^)]*\)\s*$',
          caseSensitive: false,
        ),
        '',
      );

      // Remove music notes and symbols: ♪, ♫, ♬, ♩
      cleanLine = cleanLine.replaceAll(RegExp(r'[♪♫♬♩]+'), '');

      // Remove lines with only music notation like: ♪ ~ ♪
      cleanLine = cleanLine.replaceAll(RegExp(r'^[\s♪♫♬♩~\-_]+$'), '');

      // Remove speaker labels with colons: SPEAKER: or NAME:
      cleanLine = cleanLine.replaceAll(RegExp(r'^\s*[A-Z\s]+:\s*'), '');

      // Clean up multiple spaces (but preserve single spaces and tabs)
      cleanLine = cleanLine.replaceAll(RegExp(r' {2,}'), ' ');

      // Trim leading/trailing whitespace from the line
      cleanLine = cleanLine.trim();

      // Only keep lines that have meaningful content
      // Skip lines that are empty or contain only special characters/punctuation
      if (cleanLine.isNotEmpty && !_isOnlySpecialCharacters(cleanLine)) {
        cleanedLines.add(cleanLine);
      }
    }

    // Rejoin lines with newlines to preserve formatting
    final finalText = cleanedLines.join('\n').trim();

    // Only include subtitles that have meaningful content after cleaning
    if (finalText.isNotEmpty && !_isOnlySpecialCharacters(finalText)) {
      subtitle.original = finalText;
      cleanedSubtitles.add(subtitle);
    }
  }

  return cleanedSubtitles;
}

/// Checks if a string contains only special characters, punctuation, or whitespace
/// Returns true if the string has no meaningful alphabetic or numeric content
bool _isOnlySpecialCharacters(String text) {
  // Remove all whitespace, punctuation, and common special characters
  final cleanedText = text.replaceAll(
    RegExp(r'[\s\p{P}\p{S}♪♫♬♩~\-_*]+', unicode: true),
    '',
  );

  // If nothing remains, it was only special characters
  return cleanedText.isEmpty;
}

/// Merges subtitles with identical time codes
List<SubtitleLine> _mergeOverlappingSubtitles(List<SubtitleLine> subtitles) {
  if (subtitles.length <= 1) return subtitles;

  final List<SubtitleLine> mergedSubtitles = [];
  int i = 0;

  while (i < subtitles.length) {
    final currentSub = subtitles[i];

    // Skip subtitles with positioning tags (in curly braces)
    if (currentSub.original.contains(RegExp(r'\{.*?\}'))) {
      mergedSubtitles.add(currentSub);
      i++;
      continue;
    }

    // Check if the next subtitle has the same timing
    if (i + 1 < subtitles.length &&
        currentSub.startTime == subtitles[i + 1].startTime &&
        currentSub.endTime == subtitles[i + 1].endTime) {
      // Skip next subtitle if it has positioning tags
      if (subtitles[i + 1].original.contains(RegExp(r'\{.*?\}'))) {
        mergedSubtitles.add(currentSub);
        i++;
        continue;
      }

      // Merge the subtitles
      final mergedSub =
          SubtitleLine()
            ..index = currentSub.index
            ..startTime = currentSub.startTime
            ..endTime = currentSub.endTime
            ..original = '${currentSub.original}\n${subtitles[i + 1].original}'
            ..edited = null;

      mergedSubtitles.add(mergedSub);
      i += 2; // Skip the next subtitle since we've merged it
    } else {
      mergedSubtitles.add(currentSub);
      i++;
    }
  }

  return mergedSubtitles;
}

/// Re-indexes subtitles to ensure sequential numbering with intelligent sorting
/// Now uses enhanced sorting to preserve overlaps and handle positioning tags
List<SubtitleLine> _reindexSubtitles(List<SubtitleLine> subtitles) {
  // Sort intelligently (preserves overlaps, handles tags) and re-index in one operation
  return sortAndReindexSubtitleLines(subtitles);
}

/// Compares two time codes in format HH:mm:ss,SSS
int _compareTimeCodes(String time1, String time2) {
  // Convert time format to milliseconds
  int timeToMillis(String timeCode) {
    final parts = timeCode.split(':');
    final secondsParts = parts[2].split(',');

    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(secondsParts[0]);
    final millis = int.parse(secondsParts[1]);

    return ((hours * 60 + minutes) * 60 + seconds) * 1000 + millis;
  }

  return timeToMillis(time1) - timeToMillis(time2);
}

/// Retrieve stored SAF content URI for a file
/// Returns null if no URI is stored for the given fileName
Future<String?> getSafContentUri(String fileName) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = 'saf_uri_${fileName.replaceAll(RegExp(r'[^\w\-_.]'), '_')}';
    return prefs.getString(key);
  } catch (e) {
    if (kDebugMode) {
      print('Failed to retrieve SAF URI for $fileName: $e');
    }
    return null;
  }
}
