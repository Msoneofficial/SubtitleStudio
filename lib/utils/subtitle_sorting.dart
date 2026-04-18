// Subtitle Studio - Enhanced Subtitle Sorting Utility
//
// Provides intelligent sorting for subtitle lines that preserves overlapping subtitles
// and handles positioning tags correctly.
//
// Sorting Strategy:
// 1. Sort by start time (primary)
// 2. Sort by end time if start times are equal (secondary)
// 3. Sort by original index if times are identical (tertiary)
// 4. Prioritize lines without positioning tags over tagged lines (quaternary)
//
// This ensures:
// - Overlapping subtitles are preserved (not merged or deleted)
// - Lines with same timecode maintain their original order
// - Lines without positioning tags (e.g., {an8}) appear before tagged lines
// - Consistent, predictable ordering across all save operations

import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/utils/time_parser.dart';

/// Enhanced sorting for subtitle lines that preserves overlaps and handles positioning tags
///
/// **Sorting Priority:**
/// 1. **Start time** (earlier times first)
/// 2. **End time** if start times match (earlier end times first)
/// 3. **Original index** if both times match (maintains original order)
/// 4. **Positioning tags** if all else equal (non-tagged lines before tagged lines)
///
/// **Positioning Tag Detection:**
/// - Detects tags like `{an8}`, `{\pos(x,y)}`, `{\a6}`, etc.
/// - Lines without these tags get priority
/// - This ensures main subtitles appear before secondary/positioned subtitles
///
/// **Parameters:**
/// - [lines]: List of SubtitleLine objects to sort
///
/// **Returns:**
/// - Sorted list of SubtitleLine objects (does not modify original list)
List<SubtitleLine> sortSubtitleLinesIntelligently(List<SubtitleLine> lines) {
  // Create a copy to avoid modifying the original list
  final sortedLines = List<SubtitleLine>.from(lines);
  
  sortedLines.sort((a, b) {
    // 1. Primary: Sort by start time
    final aStartTime = parseTimeString(a.startTime);
    final bStartTime = parseTimeString(b.startTime);
    final startTimeComparison = aStartTime.compareTo(bStartTime);
    
    if (startTimeComparison != 0) {
      return startTimeComparison;
    }
    
    // 2. Secondary: If start times are equal, sort by end time
    final aEndTime = parseTimeString(a.endTime);
    final bEndTime = parseTimeString(b.endTime);
    final endTimeComparison = aEndTime.compareTo(bEndTime);
    
    if (endTimeComparison != 0) {
      return endTimeComparison;
    }
    
    // 3. Tertiary: If both times are equal, use original index to maintain order
    final indexComparison = a.index.compareTo(b.index);
    
    if (indexComparison != 0) {
      return indexComparison;
    }
    
    // 4. Quaternary: If even indices match, prioritize lines without positioning tags
    // Check both original and edited text for positioning tags
    final aHasTag = _hasPositioningTag(a.original) || 
                    (a.edited?.isNotEmpty == true && _hasPositioningTag(a.edited!));
    final bHasTag = _hasPositioningTag(b.original) || 
                    (b.edited?.isNotEmpty == true && _hasPositioningTag(b.edited!));
    
    if (aHasTag && !bHasTag) {
      return 1; // b comes first (no tag)
    } else if (!aHasTag && bHasTag) {
      return -1; // a comes first (no tag)
    }
    
    // 5. If everything is identical, maintain original order (stable sort)
    return 0;
  });
  
  return sortedLines;
}

/// Checks if a subtitle text contains positioning tags
///
/// **Detects common SRT/ASS positioning tags:**
/// - `{an8}` - Alignment tags (an1-an9)
/// - `{\pos(x,y)}` - Position tags
/// - `{\a6}` - Legacy alignment tags
/// - `{\move(x1,y1,x2,y2)}` - Movement tags
/// - Any text starting with `{\ ` generally
///
/// **Parameters:**
/// - [text]: Subtitle text to check
///
/// **Returns:**
/// - `true` if positioning tags are detected
/// - `false` otherwise
bool _hasPositioningTag(String text) {
  if (text.isEmpty) return false;
  
  // Check for common positioning tag patterns
  // Pattern matches: {an8}, {\pos(x,y)}, {\a6}, {\move(...)}, etc.
  final positioningTagPattern = RegExp(
    r'\{\\?(?:an\d|pos|a\d|move|alignment|position)',
    caseSensitive: false,
  );
  
  return positioningTagPattern.hasMatch(text);
}

/// Sort and re-index subtitle lines
///
/// Combines sorting with re-indexing in one operation.
/// This is the recommended method to use when updating subtitle collections.
///
/// **Parameters:**
/// - [lines]: List of SubtitleLine objects to sort and re-index
///
/// **Returns:**
/// - Sorted and re-indexed list of SubtitleLine objects
List<SubtitleLine> sortAndReindexSubtitleLines(List<SubtitleLine> lines) {
  // First, sort the lines intelligently
  final sortedLines = sortSubtitleLinesIntelligently(lines);
  
  // Then, re-index based on the new order
  for (int i = 0; i < sortedLines.length; i++) {
    sortedLines[i].index = i + 1;
  }
  
  return sortedLines;
}
