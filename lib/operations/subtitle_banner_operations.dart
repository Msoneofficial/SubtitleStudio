import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/utils/time_parser.dart';
import 'package:subtitle_studio/services/checkpoint_manager.dart';
import 'package:subtitle_studio/utils/subtitle_sorting.dart'; // Enhanced subtitle sorting

class SubtitleBannerOperations {
  // Default banner texts for testing
  static const String defaultBeginningBanner = '<b><font color="#ff0000">എംസോൺ റിലീസ് - \n www.malayalamsubtitles.org \n www.facebook.com/msonepage</font></b>';
  static const String defaultMiddleBanner = '<b><font color="#ff0000">എംസോൺ പരിഭാഷകൾ \n Android & iOS ആപ്പുകളിലും ലഭ്യമാണ്. \n www.malayalamsubtitles.org</font></b>';
  static const String defaultEndBanner = '<b><font color="#ff0000">എംസോൺ പരിഭാഷകൾക്ക് സന്ദർശിക്കുക \n www.malayalamsubtitles.org \n www.facebook.com/groups/MSONEsubs</font></b>';
  
  // Banner duration in milliseconds (10 seconds)
  static const int bannerDurationMs = 10000;

  /// Calculate positions for banners in the subtitle file
  static BannerPositions calculateBannerPositions(List<SubtitleLine> subtitleLines) {
    if (subtitleLines.isEmpty) {
      return BannerPositions(
        beginningPosition: Duration.zero,
        middlePosition: Duration(milliseconds: 30000), // 30 seconds default
        endPosition: Duration(milliseconds: 60000), // 60 seconds default
      );
    }    // Get first and last subtitle times
    final firstSubtitle = parseTimeString(subtitleLines.first.startTime);
    final lastSubtitle = parseTimeString(subtitleLines.last.endTime);
    
    // Find middle subtitle
    final middleIndex = subtitleLines.length ~/ 2;    // Calculate available gaps and positions
    Duration beginningPosition;
    Duration middlePosition;
    Duration endPosition;
    
    // Beginning: Calculate safe position before first subtitle
    final firstSubtitleMs = firstSubtitle.inMilliseconds;
    final minStartTime = 5000; // Minimum 5 seconds from beginning
    final maxStartTime = firstSubtitleMs - 1000; // At least 1 second before first subtitle
    
    if (maxStartTime <= minStartTime) {
      // If first subtitle is too early, place banner at minimum position
      beginningPosition = Duration(milliseconds: minStartTime);
    } else {
      // Try to place 15 seconds before first subtitle, but within safe bounds
      final preferredStartTime = firstSubtitleMs - 15000;
      beginningPosition = Duration(
        milliseconds: preferredStartTime.clamp(minStartTime, maxStartTime)
      );
    }
    
    // Middle: Find a gap around the middle subtitle
    middlePosition = _findBestMiddlePosition(subtitleLines, middleIndex);
    
    // End: 5 seconds after last subtitle
    endPosition = Duration(milliseconds: lastSubtitle.inMilliseconds + 5000);
    
    return BannerPositions(
      beginningPosition: beginningPosition,
      middlePosition: middlePosition,
      endPosition: endPosition,
    );
  }
    /// Find the best position for middle banner by looking for gaps between subtitles
  static Duration _findBestMiddlePosition(List<SubtitleLine> subtitleLines, int targetIndex) {
    // Ensure target index is valid
    if (targetIndex < 0 || targetIndex >= subtitleLines.length) {
      targetIndex = subtitleLines.length ~/ 2;
    }
    
    // Look for gaps around the middle area
    for (int i = targetIndex - 2; i <= targetIndex + 2; i++) {
      if (i >= 0 && i < subtitleLines.length - 1) {
        final currentEnd = parseTimeString(subtitleLines[i].endTime);
        final nextStart = parseTimeString(subtitleLines[i + 1].startTime);
        final gap = nextStart.inMilliseconds - currentEnd.inMilliseconds;
        
        // If gap is large enough for banner (at least 12 seconds)
        if (gap >= 12000) {
          return Duration(milliseconds: currentEnd.inMilliseconds + 1000);
        }
      }
    }
    
    // If no suitable gap found, place it after the middle subtitle
    // Ensure we don't go out of bounds
    final safeIndex = targetIndex.clamp(0, subtitleLines.length - 1);
    final middleSubtitleEnd = parseTimeString(subtitleLines[safeIndex].endTime);
    return Duration(milliseconds: middleSubtitleEnd.inMilliseconds + 1000);
  }
    /// Insert banners into the subtitle collection
  static Future<bool> insertBanners({
    required int subtitleCollectionId,
    required int sessionId,
    required List<SubtitleLine> currentSubtitleLines,
    required String beginningText,
    required String middleText,
    required String endText,
    bool includeBeginning = true,
    bool includeMiddle = true,
    bool includeEnd = true,
    BannerPositions? customPositions,
  }) async {
    try {
      // Capture pre-operation state for checkpoint
      final preOperationState = currentSubtitleLines.map((line) => 
        SubtitleLine()
          ..index = line.index
          ..startTime = line.startTime
          ..endTime = line.endTime
          ..original = line.original
          ..edited = line.edited
          ..marked = line.marked
          ..comment = line.comment
          ..resolved = line.resolved
      ).toList();
      
      // Calculate banner positions
      final positions = customPositions ?? calculateBannerPositions(currentSubtitleLines);
      
      // Create banner subtitle lines based on toggles
      final banners = <SubtitleLine>[];
      
      if (includeBeginning) {
        banners.add(_createBannerLine(
          text: beginningText,
          startTime: _formatDuration(positions.beginningPosition),
          index: 0, // Will be adjusted during insertion
        ));
      }
      
      if (includeMiddle) {
        banners.add(_createBannerLine(
          text: middleText,
          startTime: _formatDuration(positions.middlePosition),
          index: 0, // Will be adjusted during insertion
        ));
      }
      
      if (includeEnd) {
        banners.add(_createBannerLine(
          text: endText,
          startTime: _formatDuration(positions.endPosition),
          index: 0, // Will be adjusted during insertion
        ));
      }
      
      // If no banners selected, return success
      if (banners.isEmpty) {
        return true;
      }
      
      // Create checkpoint FIRST - before any modifications
      // Count how many banners will be inserted for the description
      int bannerCount = 0;
      if (includeBeginning) bannerCount++;
      if (includeMiddle) bannerCount++;
      if (includeEnd) bannerCount++;
      
      final deltas = <SubtitleLineDelta>[];
      for (final banner in banners) {
        final insertIndex = _findInsertionIndex(preOperationState, banner.startTime);
        deltas.add(SubtitleLineDelta()
          ..changeType = 'add'
          ..lineIndex = insertIndex
          ..beforeState = null
          ..afterState = banner);
      }
      
      await CheckpointManager.createCheckpoint(
        sessionId: sessionId,
        subtitleCollectionId: subtitleCollectionId,
        operationType: 'add',
        description: 'Inserted $bannerCount banner${bannerCount == 1 ? '' : 's'}',
        deltas: deltas,
        preOperationState: preOperationState,
        metadata: {
          'bannerCount': bannerCount,
          'includeBeginning': includeBeginning,
          'includeMiddle': includeMiddle,
          'includeEnd': includeEnd,
        },
      );
      
      // NOW perform the actual modifications
      // Sort all lines by start time to determine proper insertion order
      final allLines = List<SubtitleLine>.from(currentSubtitleLines);
      
      // Insert banners in reverse chronological order to maintain indices
      for (final banner in banners.reversed) {
        final insertIndex = _findInsertionIndex(allLines, banner.startTime);
        allLines.insert(insertIndex, banner);
      }
      
      // Sort and reindex intelligently (preserves overlaps, handles positioning tags)
      final sortedLines = sortAndReindexSubtitleLines(allLines);
      
      // Update the database
      final subtitle = await fetchSubtitle(subtitleCollectionId);
      if (subtitle != null) {
        subtitle.lines = sortedLines;
        return await updateSubtitleCollection(subtitle);
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
    /// Create a banner subtitle line
  static SubtitleLine _createBannerLine({
    required String text,
    required String startTime,
    required int index,
  }) {
    final startDuration = parseTimeString(startTime);
    final endDuration = Duration(milliseconds: startDuration.inMilliseconds + bannerDurationMs);
    
    return SubtitleLine()
      ..index = index
      ..startTime = startTime
      ..endTime = _formatDuration(endDuration)
      ..original = text
      ..edited = null;
  }
  
  /// Format Duration to subtitle time string format (HH:mm:ss,SSS)
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')},'
           '${milliseconds.toString().padLeft(3, '0')}';
  }
  
  /// Find the correct insertion index for a banner based on its start time
  static int _findInsertionIndex(List<SubtitleLine> lines, String startTime) {
    final targetTime = parseTimeString(startTime);
    
    for (int i = 0; i < lines.length; i++) {
      final lineTime = parseTimeString(lines[i].startTime);
      if (targetTime.inMilliseconds < lineTime.inMilliseconds) {
        return i;
      }
    }
    
    return lines.length; // Insert at end
  }
  /// Check if banners can be inserted (ensure sufficient gaps exist)
  static BannerValidationResult validateBannerInsertion(
    List<SubtitleLine> subtitleLines, {
    BannerPositions? customPositions,
  }) {
    if (subtitleLines.isEmpty) {
      return BannerValidationResult(
        canInsert: true,
        warnings: ['No existing subtitles found. Banners will be inserted at default positions.'],
      );
    }
    
    final positions = customPositions ?? calculateBannerPositions(subtitleLines);
    final warnings = <String>[];
    bool hasOverlaps = false;
    
    // Check for potential conflicts
    for (final line in subtitleLines) {
      final startTime = parseTimeString(line.startTime);
      final endTime = parseTimeString(line.endTime);
      
      // Check beginning banner conflict
      if (_timesOverlap(positions.beginningPosition, 
          Duration(milliseconds: positions.beginningPosition.inMilliseconds + bannerDurationMs),
          startTime, endTime)) {
        warnings.add('Beginning banner may overlap with subtitle at ${line.startTime}');
        hasOverlaps = true;
      }
      
      // Check middle banner conflict
      if (_timesOverlap(positions.middlePosition,
          Duration(milliseconds: positions.middlePosition.inMilliseconds + bannerDurationMs),
          startTime, endTime)) {
        warnings.add('Middle banner may overlap with subtitle at ${line.startTime}');
        hasOverlaps = true;
      }
      
      // Check end banner conflict
      if (_timesOverlap(positions.endPosition,
          Duration(milliseconds: positions.endPosition.inMilliseconds + bannerDurationMs),
          startTime, endTime)) {
        warnings.add('End banner may overlap with subtitle at ${line.startTime}');
        hasOverlaps = true;
      }
    }
    
    // Calculate recommended positions if there are overlaps
    BannerPositions? recommendedPositions;
    if (hasOverlaps) {
      recommendedPositions = _calculateRecommendedPositions(subtitleLines);
    }
    
    return BannerValidationResult(
      canInsert: true, // Allow insertion even with warnings
      warnings: warnings,
      recommendedPositions: recommendedPositions,
    );
  }
  
  /// Calculate recommended positions to avoid overlaps
  static BannerPositions _calculateRecommendedPositions(List<SubtitleLine> subtitleLines) {
    // Find safe beginning position
    Duration recommendedBeginning = _findSafeBeginningPosition(subtitleLines);
    
    // Find safe middle position
    Duration recommendedMiddle = _findSafeMiddlePosition(subtitleLines);
    
    // Find safe end position
    Duration recommendedEnd = _findSafeEndPosition(subtitleLines);
    
    return BannerPositions(
      beginningPosition: recommendedBeginning,
      middlePosition: recommendedMiddle,
      endPosition: recommendedEnd,
    );
  }
  
  /// Find a safe beginning position that doesn't overlap
  static Duration _findSafeBeginningPosition(List<SubtitleLine> subtitleLines) {
    final firstSubtitle = parseTimeString(subtitleLines.first.startTime);
    
    // Start checking from 5 seconds
    for (int startMs = 5000; startMs < firstSubtitle.inMilliseconds - 1000; startMs += 1000) {
      final endMs = startMs + bannerDurationMs;
      bool hasOverlap = false;
      
      for (final line in subtitleLines) {
        final lineStart = parseTimeString(line.startTime);
        final lineEnd = parseTimeString(line.endTime);
        
        if (_timesOverlap(Duration(milliseconds: startMs), Duration(milliseconds: endMs),
            lineStart, lineEnd)) {
          hasOverlap = true;
          break;
        }
      }
      
      if (!hasOverlap) {
        return Duration(milliseconds: startMs);
      }
    }
    
    // If no safe position found, return minimum
    return Duration(milliseconds: 5000);
  }
  
  /// Find a safe middle position that doesn't overlap
  static Duration _findSafeMiddlePosition(List<SubtitleLine> subtitleLines) {
    // Start from the middle area and expand outward
    final middleIndex = subtitleLines.length ~/ 2;
    final middleTime = parseTimeString(subtitleLines[middleIndex].startTime);
    
    // Try positions around the middle
    for (int offset = 0; offset < subtitleLines.length * 30000; offset += 5000) {
      for (int direction in [-1, 1]) {
        final startMs = middleTime.inMilliseconds + (offset * direction);
        if (startMs < 0) continue;
        
        final endMs = startMs + bannerDurationMs;
        bool hasOverlap = false;
        
        for (final line in subtitleLines) {
          final lineStart = parseTimeString(line.startTime);
          final lineEnd = parseTimeString(line.endTime);
          
          if (_timesOverlap(Duration(milliseconds: startMs), Duration(milliseconds: endMs),
              lineStart, lineEnd)) {
            hasOverlap = true;
            break;
          }
        }
        
        if (!hasOverlap) {
          return Duration(milliseconds: startMs);
        }
      }
    }
    
    // Fallback to after middle subtitle
    final middleEnd = parseTimeString(subtitleLines[middleIndex].endTime);
    return Duration(milliseconds: middleEnd.inMilliseconds + 1000);
  }
  
  /// Find a safe end position that doesn't overlap
  static Duration _findSafeEndPosition(List<SubtitleLine> subtitleLines) {
    final lastSubtitle = parseTimeString(subtitleLines.last.endTime);
    
    // Start from 5 seconds after last subtitle
    for (int startMs = lastSubtitle.inMilliseconds + 5000; startMs < lastSubtitle.inMilliseconds + 60000; startMs += 1000) {
      final endMs = startMs + bannerDurationMs;
      bool hasOverlap = false;
      
      for (final line in subtitleLines) {
        final lineStart = parseTimeString(line.startTime);
        final lineEnd = parseTimeString(line.endTime);
        
        if (_timesOverlap(Duration(milliseconds: startMs), Duration(milliseconds: endMs),
            lineStart, lineEnd)) {
          hasOverlap = true;
          break;
        }
      }
      
      if (!hasOverlap) {
        return Duration(milliseconds: startMs);
      }
    }
    
    // Fallback to 5 seconds after last subtitle
    return Duration(milliseconds: lastSubtitle.inMilliseconds + 5000);
  }
  
  /// Check if two time ranges overlap
  static bool _timesOverlap(Duration start1, Duration end1, Duration start2, Duration end2) {
    return start1.inMilliseconds < end2.inMilliseconds && 
           end1.inMilliseconds > start2.inMilliseconds;
  }
}

/// Helper class to store banner positions
class BannerPositions {
  final Duration beginningPosition;
  final Duration middlePosition;
  final Duration endPosition;
  
  BannerPositions({
    required this.beginningPosition,
    required this.middlePosition,
    required this.endPosition,
  });
}

/// Helper class for validation results
class BannerValidationResult {
  final bool canInsert;
  final List<String> warnings;
  final BannerPositions? recommendedPositions;
  
  BannerValidationResult({
    required this.canInsert,
    required this.warnings,
    this.recommendedPositions,
  });
}
