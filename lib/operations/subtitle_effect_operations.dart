import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/utils/time_parser.dart';
import 'package:subtitle_studio/main.dart'; // For isar instance
import 'package:subtitle_studio/operations/subtitle_sync_operations.dart'; // For formatDuration
import 'package:subtitle_studio/utils/subtitle_sorting.dart'; // Enhanced subtitle sorting

class SubtitleEffectOperations {
  /// Generate typewriter effect by creating multiple subtitle lines
  /// Each line shows progressively more characters with precise timing
  static Future<List<SubtitleLine>> generateTypewriterEffect({
    required SubtitleLine originalLine,
    required String color,
    double endDelay = 0.0, // End delay in seconds
  }) async {
    final text = originalLine.edited ?? originalLine.original;
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), ''); // Remove existing HTML tags
    
    if (cleanText.trim().isEmpty) return [];
    
    final startTime = parseTimeString(originalLine.startTime);
    final endTime = parseTimeString(originalLine.endTime);
    final totalDuration = endTime.inMilliseconds - startTime.inMilliseconds;
    
    // Calculate end delay in milliseconds
    final endDelayMs = (endDelay * 1000).round();
    final availableDuration = totalDuration - endDelayMs;
    
    if (availableDuration <= 0) return []; // Not enough time for effect
    
    final List<SubtitleLine> effectLines = [];
    final characters = cleanText.split('');
    
    // Calculate timing for each character based on available duration and total characters
    final millisecondsPerCharacter = availableDuration / characters.length;
    
    for (int i = 1; i <= characters.length; i++) {
      final partialText = characters.take(i).join('');
      final coloredText = '<font color="#$color">$partialText</font>';
      
      final lineStartTime = startTime.inMilliseconds + ((i - 1) * millisecondsPerCharacter).round();
      final lineEndTime = startTime.inMilliseconds + (i * millisecondsPerCharacter).round();
      
      // For the last character, extend to show full text until actual end time
      final adjustedEndTime = (i == characters.length) ? endTime.inMilliseconds : lineEndTime;
      
      final newLine = SubtitleLine()
        ..index = originalLine.index + i - 1
        ..original = originalLine.original
        ..edited = coloredText
        ..startTime = SubtitleSyncOperations.formatDuration(Duration(milliseconds: lineStartTime))
        ..endTime = SubtitleSyncOperations.formatDuration(Duration(milliseconds: adjustedEndTime))
        ..marked = originalLine.marked;
      
      effectLines.add(newLine);
    }
    
    return effectLines;
  }
  
  /// Generate karaoke effect by creating multiple subtitle lines
  /// Each line highlights progressively more text
  static Future<List<SubtitleLine>> generateKaraokeEffect({
    required SubtitleLine originalLine,
    required String color,
    String effectType = 'word', // 'word' or 'character'
    double endDelay = 0.0, // End delay in seconds
    bool hasTextSelection = false, // Whether user selected specific text
    int selectionStart = 0, // Start position of selection
    int selectionEnd = 0, // End position of selection
    String? selectedText, // The selected text
    String? fullText, // The full text with selection
  }) async {
    // Use the provided full text if available, otherwise use original line text
    final sourceText = fullText ?? (originalLine.edited ?? originalLine.original);
    final cleanText = sourceText.replaceAll(RegExp(r'<[^>]*>'), ''); // Remove existing HTML tags
    
    if (cleanText.trim().isEmpty) return [];
    
    // If there's a text selection, only apply effect to that part
    String textToEffect;
    String beforeSelection = '';
    String afterSelection = '';
    
    if (hasTextSelection && selectedText != null && selectedText.isNotEmpty) {
      // Apply effect only to selected text
      textToEffect = selectedText;
      // Use the full text from the text controller for proper selection bounds
      final workingText = fullText ?? cleanText;
      if (selectionStart > 0 && selectionStart <= workingText.length) {
        beforeSelection = workingText.substring(0, selectionStart);
      }
      if (selectionEnd < workingText.length && selectionEnd >= 0) {
        afterSelection = workingText.substring(selectionEnd);
      }
    } else {
      // Apply effect to entire text
      textToEffect = cleanText;
    }
    
    if (textToEffect.trim().isEmpty) return [];
    
    final startTime = parseTimeString(originalLine.startTime);
    final endTime = parseTimeString(originalLine.endTime);
    final totalDuration = endTime.inMilliseconds - startTime.inMilliseconds;
    
    // Calculate end delay in milliseconds
    final endDelayMs = (endDelay * 1000).round();
    final availableDuration = totalDuration - endDelayMs;
    
    if (availableDuration <= 0) return []; // Not enough time for effect
    
    final List<SubtitleLine> effectLines = [];
    
    // Split based on effect type - apply only to the text portion that should have effect
    List<String> segments;
    if (effectType == 'character') {
      segments = textToEffect.split('');
    } else {
      segments = textToEffect.split(' ');
    }
    
    if (segments.isEmpty) return [];
    
    // Calculate timing for each segment
    final timePerSegment = availableDuration / segments.length;
    
    for (int i = 1; i <= segments.length; i++) {
      List<String> highlightedSegments;
      List<String> remainingSegments;
      
      if (effectType == 'character') {
        highlightedSegments = segments.take(i).toList();
        remainingSegments = segments.skip(i).toList();
      } else {
        highlightedSegments = segments.take(i).toList();
        remainingSegments = segments.skip(i).toList();
      }
      
      String karaokeText;
      
      // Build the karaoke text based on whether we have text selection
      if (hasTextSelection && selectedText != null && selectedText.isNotEmpty) {
        // We have text selection - build: beforeSelection + progressiveEffect + remainingEffect + afterSelection
        String progressiveEffectText = '';
        String remainingEffectText = '';
        
        if (effectType == 'character') {
          progressiveEffectText = highlightedSegments.join('');
          remainingEffectText = remainingSegments.join('');
        } else {
          progressiveEffectText = highlightedSegments.join(' ');
          remainingEffectText = remainingSegments.isNotEmpty ? remainingSegments.join(' ') : '';
        }
        
        // Build final text with selection context
        String finalText = '';
        
        // Add text before selection without effect
        if (beforeSelection.isNotEmpty) {
          finalText += beforeSelection;
        }
        
        // Add progressive effect text
        if (progressiveEffectText.isNotEmpty) {
          finalText += '<font color="#$color">$progressiveEffectText</font>';
        }
        
        // Add remaining effect text in normal color
        if (remainingEffectText.isNotEmpty) {
          if (effectType == 'word' && progressiveEffectText.isNotEmpty) {
            finalText += ' ';
          }
          finalText += remainingEffectText;
        }
        
        // Add text after selection without effect
        if (afterSelection.isNotEmpty) {
          finalText += afterSelection;
        }
        
        karaokeText = finalText;
      } else {
        // No text selection - apply effect to entire text (original behavior)
        if (remainingSegments.isNotEmpty) {
          if (effectType == 'character') {
            final highlightedText = highlightedSegments.join('');
            final remainingText = remainingSegments.join('');
            karaokeText = '<font color="#$color">$highlightedText</font>$remainingText';
          } else {
            final highlightedText = highlightedSegments.join(' ');
            final remainingText = remainingSegments.join(' ');
            karaokeText = '<font color="#$color">$highlightedText</font> $remainingText';
          }
        } else {
          final highlightedText = effectType == 'character' 
              ? highlightedSegments.join('')
              : highlightedSegments.join(' ');
          karaokeText = '<font color="#$color">$highlightedText</font>';
        }
      }
      
      final lineStartTime = startTime.inMilliseconds + ((i - 1) * timePerSegment).round();
      final lineEndTime = startTime.inMilliseconds + (i * timePerSegment).round();
      
      // For the last segment, extend to show full text until actual end time
      final adjustedEndTime = (i == segments.length) ? endTime.inMilliseconds : lineEndTime;
      
      final newLine = SubtitleLine()
        ..index = originalLine.index + i - 1
        ..original = originalLine.original
        ..edited = karaokeText
        ..startTime = SubtitleSyncOperations.formatDuration(Duration(milliseconds: lineStartTime))
        ..endTime = SubtitleSyncOperations.formatDuration(Duration(milliseconds: adjustedEndTime))
        ..marked = originalLine.marked;
      
      effectLines.add(newLine);
    }
    
    return effectLines;
  }
  
  /// Apply effects to subtitle collection in database
  static Future<bool> applyEffectToSubtitleCollection({
    required int subtitleCollectionId,
    required int originalLineIndex,
    required List<SubtitleLine> effectLines,
  }) async {
    try {
      // Get the subtitle collection
      final collection = await isar.subtitleCollections.get(subtitleCollectionId);
      if (collection == null) return false;
      
      await isar.writeTxn(() async {
        // Create a new list without the original line
        final newLines = <SubtitleLine>[];
        
        // Add all lines except the original line
        for (final line in collection.lines) {
          if (line.index != originalLineIndex + 1) {
            newLines.add(line);
          }
        }
        
        // Add the effect lines
        newLines.addAll(effectLines);
        
        // Sort and re-index all lines intelligently (preserves overlaps, handles positioning tags)
        final sortedLines = sortAndReindexSubtitleLines(newLines);
        
        // Replace the entire lines list with the sorted list
        collection.lines = sortedLines;
        
        // Save the updated collection
        await isar.subtitleCollections.put(collection);
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
