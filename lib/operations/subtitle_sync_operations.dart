import 'package:flutter/foundation.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/utils/time_parser.dart';

class SyncResult {
  final bool success;
  final String message;

  SyncResult({
    required this.success,
    required this.message,
  });
}

class SubtitleSyncOperations {
  /// Shifts all subtitle timecodes while preserving their durations.
  /// New start and end times are provided for the first and last subtitles.
  static Future<SyncResult> shiftTimecodes({
    required int subtitleId,
    required List<SubtitleLine> subtitleLines,
    required String newStartTime,
    required String newEndTime,
  }) async {
    try {
      if (subtitleLines.isEmpty) {
        return SyncResult(
          success: false,
          message: 'No subtitles to shift',
        );
      }
      
      // Parse the new time values
      final Duration newStartDuration;
      final Duration newEndDuration;
      
      try {
        newStartDuration = parseTimeString(newStartTime);
        newEndDuration = parseTimeString(newEndTime);
      } catch (e) {
        return SyncResult(
          success: false,
          message: 'Invalid time format. Use HH:MM:SS,mmm',
        );
      }

      // Get original start and end times
      final originalStartDuration = parseTimeString(subtitleLines.first.startTime);
      final originalEndDuration = parseTimeString(subtitleLines.last.endTime);
      final originalTotalDuration = originalEndDuration - originalStartDuration;
      final newTotalDuration = newEndDuration - newStartDuration;

      if (newTotalDuration.inMilliseconds <= 0) {
        return SyncResult(
          success: false,
          message: 'New end time must be after new start time',
        );
      }

      // Calculate the scaling factor
      final double scaleFactor = newTotalDuration.inMilliseconds / originalTotalDuration.inMilliseconds;
      
      List<SubtitleLine> updatedLines = [];
      
      // Update all subtitle timecodes
      for (final line in subtitleLines) {
        final originalStartMs = parseTimeString(line.startTime);
        final originalEndMs = parseTimeString(line.endTime);
        
        // Calculate new times
        // If we're applying a scale factor, we need to scale from the original start time
        final relativeStartMs = originalStartMs - originalStartDuration;
        final newRelativeStartMs = Duration(
          milliseconds: (relativeStartMs.inMilliseconds * scaleFactor).round()
        );
        
        // Calculate the new absolute start time
        final newStartMs = newStartDuration + newRelativeStartMs;
        
        // Preserve duration for each subtitle
        final duration = originalEndMs - originalStartMs;
        final newEndMs = newStartMs + duration;
        
        // Create updated subtitle
        final updatedLine = SubtitleLine()
          ..index = line.index
          ..original = line.original
          ..edited = line.edited
          ..startTime = formatDuration(newStartMs)
          ..endTime = formatDuration(newEndMs);
        
        updatedLines.add(updatedLine);
      }
      
      // Update in database
      final success = await updateMultipleSubtitleLines(subtitleId, updatedLines);
      
      if (!success) {
        return SyncResult(
          success: false,
          message: 'Failed to update subtitle lines in database',
        );
      }

      return SyncResult(
        success: true,
        message: 'Subtitle timecodes shifted successfully',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error shifting timecodes: $e');
      }
      return SyncResult(
        success: false,
        message: 'Failed to shift timecodes: $e',
      );
    }
  }

  /// Shifts timecodes for selected subtitle lines only.
  /// New start and end times are provided for the first and last selected subtitles.
  static Future<SyncResult> shiftSelectedTimecodes({
    required int subtitleId,
    required List<SubtitleLine> allSubtitleLines,
    required List<int> selectedIndices,
    required String newStartTime,
    required String newEndTime,
  }) async {
    try {
      if (selectedIndices.isEmpty) {
        return SyncResult(
          success: false,
          message: 'No subtitles selected',
        );
      }

      // Sort indices to ensure proper order
      selectedIndices.sort();
      
      // Get the selected subtitle lines
      List<SubtitleLine> selectedLines = selectedIndices
          .map((index) => allSubtitleLines[index])
          .toList();
      
      // Parse the new time values
      final Duration newStartDuration;
      final Duration newEndDuration;
      
      try {
        newStartDuration = parseTimeString(newStartTime);
        newEndDuration = parseTimeString(newEndTime);
      } catch (e) {
        return SyncResult(
          success: false,
          message: 'Invalid time format. Use HH:MM:SS,mmm',
        );
      }

      // Get original start and end times for selected subtitles
      final originalStartDuration = parseTimeString(selectedLines.first.startTime);
      final originalEndDuration = parseTimeString(selectedLines.last.endTime);
      final originalTotalDuration = originalEndDuration - originalStartDuration;
      final newTotalDuration = newEndDuration - newStartDuration;

      if (newTotalDuration.inMilliseconds <= 0) {
        return SyncResult(
          success: false,
          message: 'New end time must be after new start time',
        );
      }

      // Calculate the scaling factor
      final double scaleFactor = newTotalDuration.inMilliseconds / originalTotalDuration.inMilliseconds;
      
      List<SubtitleLine> updatedLines = [];
      
      // Update selected subtitle timecodes
      for (int i = 0; i < selectedIndices.length; i++) {
        final index = selectedIndices[i];
        final line = allSubtitleLines[index];
        
        final originalStartMs = parseTimeString(line.startTime);
        final originalEndMs = parseTimeString(line.endTime);
        
        // Calculate new times
        final relativeStartMs = originalStartMs - originalStartDuration;
        final newRelativeStartMs = Duration(
          milliseconds: (relativeStartMs.inMilliseconds * scaleFactor).round()
        );
        
        // Calculate the new absolute start time
        final newStartMs = newStartDuration + newRelativeStartMs;
        
        // Preserve duration for each subtitle
        final duration = originalEndMs - originalStartMs;
        final newEndMs = newStartMs + duration;
        
        // Create updated subtitle
        final updatedLine = SubtitleLine()
          ..index = line.index
          ..original = line.original
          ..edited = line.edited
          ..startTime = formatDuration(newStartMs)
          ..endTime = formatDuration(newEndMs);
        
        updatedLines.add(updatedLine);
      }
      
      // Update in database (only the selected lines)
      final success = await updateMultipleSubtitleLines(subtitleId, updatedLines);
      
      if (!success) {
        return SyncResult(
          success: false,
          message: 'Failed to update selected subtitle lines in database',
        );
      }

      return SyncResult(
        success: true,
        message: 'Selected subtitle timecodes shifted successfully',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error shifting selected timecodes: $e');
      }
      return SyncResult(
        success: false,
        message: 'Failed to shift timecodes: $e',
      );
    }
  }

  /// Adjusts subtitle timecodes based on framerate conversion.
  static Future<SyncResult> adjustFramerate({
    required int subtitleId,
    required List<SubtitleLine> subtitleLines,
    required double sourceFramerate,
    required double targetFramerate,
  }) async {
    try {
      if (subtitleLines.isEmpty) {
        return SyncResult(
          success: false,
          message: 'No subtitles to adjust',
        );
      }
      
      // Validate framerates
      if (sourceFramerate <= 0 || targetFramerate <= 0) {
        return SyncResult(
          success: false,
          message: 'Framerates must be positive values',
        );
      }
      
      // Calculate the conversion factor
      final double conversionFactor = sourceFramerate / targetFramerate;
      
      List<SubtitleLine> updatedLines = [];
      
      // Update all subtitle timecodes
      for (final line in subtitleLines) {
        final originalStartDuration = parseTimeString(line.startTime);
        final originalEndDuration = parseTimeString(line.endTime);
        
        // Apply conversion factor to both times
        final newStartDuration = Duration(
          milliseconds: (originalStartDuration.inMilliseconds * conversionFactor).round()
        );
        
        final newEndDuration = Duration(
          milliseconds: (originalEndDuration.inMilliseconds * conversionFactor).round()
        );
        
        // Create updated subtitle
        final updatedLine = SubtitleLine()
          ..index = line.index
          ..original = line.original
          ..edited = line.edited
          ..startTime = formatDuration(newStartDuration)
          ..endTime = formatDuration(newEndDuration);
        
        updatedLines.add(updatedLine);
      }
      
      // Update in database
      final success = await updateMultipleSubtitleLines(subtitleId, updatedLines);
      
      if (!success) {
        return SyncResult(
          success: false,
          message: 'Failed to update subtitle lines in database',
        );
      }

      return SyncResult(
        success: true,
        message: 'Subtitle timecodes adjusted for framerate change',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error adjusting framerate: $e');
      }
      return SyncResult(
        success: false,
        message: 'Failed to adjust framerate: $e',
      );
    }
  }
  
  // Helper function to format Duration to the SRT time format
  static String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    
    return '$hours:$minutes:$seconds,$milliseconds';
  }
}
