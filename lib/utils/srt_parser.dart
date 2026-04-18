import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:charset_converter/charset_converter.dart';

/// A utility class for parsing SRT (SubRip) subtitle files.
/// Handles different character encodings and converts subtitle data into structured format.
class SubtitleParser {
  /// Creates a new instance of SubtitleParser
  SubtitleParser();

  /// Parses an SRT file and returns subtitle data
  ///
  /// Parameters:
  /// - [file]: The SRT file to parse
  ///
  /// Returns a Map containing:
  /// - subtitleCollectionId: ID of the stored subtitle collection
  /// - fileName: Name of the parsed file
  /// - lastEditedIndex: Index of last edited subtitle (null for new files)
  ///
  /// Throws an Exception if file encoding is not supported
  Future<Map> parseSrtFile(File file, BuildContext context) async {
    String srtContent;
    String? encoding;
    final fullFilePath = file.path; // Store the full file path including filename

    try {
      // Attempt UTF-8 decoding
      srtContent = await file.readAsString(encoding: utf8);
      encoding = "UTF-8";
    } catch (e) {
      try {
        // Attempt ISO-8859-1 (Latin-1) decoding
        final bytes = await file.readAsBytes();
        srtContent = await CharsetConverter.decode("latin1", bytes);
        encoding = "ISO-8859-1";
      } catch (e) {
        try {
          // Attempt ASCII decoding
          final bytes = await file.readAsBytes();
          srtContent = await CharsetConverter.decode("ascii", bytes);
          encoding = "ASCII";
        } catch (e) {
          try {
            // Attempt Windows-1252 decoding
            final bytes = await file.readAsBytes();
            srtContent = await CharsetConverter.decode("windows-1252", bytes);
            encoding = "Windows-1252";
          } catch (e) {
            try {
              // Attempt UTF-16 decoding
              final bytes = await file.readAsBytes();
              srtContent = await CharsetConverter.decode("utf16", bytes);
              encoding = "UTF-16";
            } catch (e) {
              try {
                // Attempt UTF-32 decoding
                final bytes = await file.readAsBytes();
                srtContent = await CharsetConverter.decode("utf32", bytes);
                encoding = "UTF-32";
              } catch (e) {
                if (context.mounted) {
                  // Show error message if all decoding attempts fail
                  SnackbarHelper.showError(
                    context,
                    "Encoding not supported! Please use UTF-8, ISO-8859-1, ASCII, Windows-1252, UTF-16, or UTF-32.",
                  );
                }
                throw Exception('Failed to decode SRT file.');
              }
            }
          }
        }
      }
    }

    final parsedLines = _parseSrtContent(srtContent);
    final String fileName = file.uri.pathSegments.last;

    // Log parsed lines for debugging
    if (kDebugMode) {
      print('Parsed subtitle lines: $parsedLines');
    }

    // Ensure parsedLines is not empty
    if (parsedLines.isEmpty) {
      throw Exception('Parsed subtitle lines are empty');
    }

    // Store subtitle data with the full file path instead of directory path only
    final subtitleData =
        await storeSubtitleData(parsedLines, fileName, encoding, fullFilePath, projectFilePath: null);

    // Update the last edited session
    final sessionId = subtitleData['sessionId'];
    await updateLastEditedSession(sessionId);

    // Verify the update
    if (kDebugMode) {
      print('Updated last edited session to: $sessionId');
    }

    return subtitleData;
  }

  /// Parses the content of an SRT file into a list of SubtitleLine objects
  ///
  /// Parameters:
  /// - [content]: The string content of the SRT file
  ///
  /// Returns a List of SubtitleLine objects containing parsed subtitle data
  List<SubtitleLine> _parseSrtContent(String content) {
    final lines = content.split('\n');
    final List<SubtitleLine> subtitles = [];

    int? currentIndex;
    String? startTime, endTime;
    List<String> textLines = [];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue; // Skip empty lines

      if (RegExp(r'^\d+$').hasMatch(line)) {
        // Store previous subtitle if exists
        if (currentIndex != null &&
            startTime != null &&
            endTime != null &&
            textLines.isNotEmpty) {
          final subtitleLine = SubtitleLine()
            ..index = currentIndex
            ..startTime = startTime
            ..endTime = endTime
            ..original = textLines.join('\n')
            ..edited = null;

          subtitles.add(subtitleLine);
        }

        // Reset for new entry
        currentIndex = int.parse(line);
        startTime = null;
        endTime = null;
        textLines = [];
      } else if (line.contains(RegExp(r'--\>'))) {
        final times = line.split(RegExp(r'\s*-->\s*'));
        if (times.length == 2) {
          startTime = times[0].trim();
          endTime = times[1].trim();
        }
      } else {
        textLines.add(line);
      }
    }

    // Add the last subtitle if exists
    if (currentIndex != null &&
        startTime != null &&
        endTime != null &&
        textLines.isNotEmpty) {
      final subtitleLine = SubtitleLine()
        ..index = currentIndex
        ..startTime = startTime
        ..endTime = endTime
        ..original = textLines.join('\n')
        ..edited = null;

      subtitles.add(subtitleLine);
    }

    return subtitles;
  }
}
