import 'package:flutter/material.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:isar_community/isar.dart';
import '../utils/logging_helpers.dart';
import '../utils/snackbar_helper.dart';
import '../services/checkpoint_manager.dart';

import '../widgets/add_line_confirmation_sheet.dart';
import '../widgets/delete_confirmation_sheet.dart';
import '../widgets/merge_confirmation_sheet.dart';
import '../widgets/split_confirmation_sheet.dart';

class SubtitleOperations {
  static final RegExp positionRegex = RegExp(r'^\{\\an[1-9]\}');

  static void showDeleteConfirmation({
    required BuildContext context,
    required Id subtitleId,
    required SubtitleLine currentLine,
    required SubtitleCollection collection,
    required Function() onSuccess,
    required int sessionId,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DeleteConfirmationSheet(
        lineIndex: currentLine.index,
        onConfirm: () {
          Navigator.pop(context); // Close the modal first
          deleteSubtitleLine(
            context: context,
            subtitleId: subtitleId,
            currentLine: currentLine,
            collection: collection,
            onSuccess: onSuccess,
            sessionId: sessionId,
          );
        },
      ),
    );
  }

  static Future<void> deleteSubtitleLine({
    required BuildContext context,
    required Id subtitleId,
    required SubtitleLine currentLine,
    required SubtitleCollection collection,
    bool batch = false,
    required Function() onSuccess,
    required int sessionId,
  }) async {
    logInfo('Deleting subtitle line: ${currentLine.index} from collection ${collection.id}');
    
    // Create checkpoint BEFORE deleting
    await CheckpointManager.createDeleteCheckpoint(
      sessionId: sessionId,
      subtitleCollectionId: subtitleId,
      deletedLine: currentLine,
      deletedIndex: currentLine.index - 1,
    );
    
    final success = await deleteSubtitleLineDB(subtitleId, currentLine.index - 1);

    if (!context.mounted) return;

    if (success) {
      logInfo('Subtitle line ${currentLine.index} deleted successfully');
      if (!batch) {

      onSuccess();
      showSuccessSnackbar(context, 'Subtitle line deleted successfully');
      }
    } else {
      logError('Failed to delete subtitle line ${currentLine.index}');
      if (!batch) {
      _showErrorSnackbar(context, 'Failed to delete subtitle line');
      }
    }
  }

  static void showSuccessSnackbar(BuildContext context, String message) {
    SnackbarHelper.showSuccess(context, message);
  }

  static void _showErrorSnackbar(BuildContext context, String message) {
    SnackbarHelper.showError(context, message);
  }

  static void handleSplitButton({
    required BuildContext context,
    required TextEditingController editedController,
    required String startTime,
    required String endTime,
    required Id subtitleId,
    required SubtitleLine currentLine,
    required Function() refreshCallback,
    required int sessionId,
  }) {
    if (editedController.selection.isValid) {
      final cursorPosition = editedController.selection.start;
      final text = editedController.text;

      // Adjust cursor position to handle newlines properly
      int adjustedPosition = cursorPosition;
      
      // If cursor is at a newline, move it to after the newline to avoid including it in both parts
      if (cursorPosition < text.length && text[cursorPosition] == '\n') {
        adjustedPosition = cursorPosition + 1;
      }
      // If cursor is right after a newline, move it to before the newline to avoid empty line in second part
      else if (cursorPosition > 0 && text[cursorPosition - 1] == '\n') {
        adjustedPosition = cursorPosition - 1;
      }

      final firstPart = text.substring(0, adjustedPosition).trimRight();
      final secondPart = text.substring(adjustedPosition).trimLeft();

      final start = _parseTime(startTime);
      final end = _parseTime(endTime);
      final totalDuration = end.inMilliseconds - start.inMilliseconds;

      final totalChars = text.length.toDouble();
      final firstPartChars = adjustedPosition.toDouble();

      final firstPartDuration = Duration(
          milliseconds:
              (totalDuration * (firstPartChars / totalChars)).round());

      final splitTime = Duration(
          milliseconds:
              start.inMilliseconds + firstPartDuration.inMilliseconds);

      final firstPartTime = _formatTime(start);
      final middleTime = _formatTime(splitTime);
      final secondPartTime = _formatTime(end);

      if (firstPart.isEmpty || secondPart.isEmpty) {
        SnackbarHelper.showError(
          context,
          'Cannot split: One of the parts would be empty',
        );
        return;
      }

      _showSplitConfirmation(
        context: context,
        firstPart: firstPart,
        secondPart: secondPart,
        firstPartTime: '$firstPartTime → $middleTime',
        secondPartTime: '$middleTime → $secondPartTime',
        subtitleId: subtitleId,
        currentLine: currentLine,
        refreshCallback: refreshCallback,
        sessionId: sessionId,
      );
    } else {
      SnackbarHelper.showError(
        context,
        'Please position the cursor where you want to split the subtitle',
      );
    }
  }

  static void _showSplitConfirmation({
    required BuildContext context,
    required String firstPart,
    required String secondPart,
    required String firstPartTime,
    required String secondPartTime,
    required Id subtitleId,
    required SubtitleLine currentLine,
    required Function() refreshCallback,
    required int sessionId,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SplitConfirmationSheet(
        lineIndex: currentLine.index,
        firstPart: firstPart,
        secondPart: secondPart,
        firstPartTime: firstPartTime,
        secondPartTime: secondPartTime,
        onConfirm: () => _splitSubtitleLine(
          context: context,
          firstPart: firstPart,
          secondPart: secondPart,
          firstPartTime: firstPartTime,
          secondPartTime: secondPartTime,
          subtitleId: subtitleId,
          currentLine: currentLine,
          refreshCallback: refreshCallback,
          sessionId: sessionId,
        ),
      ),
    );
  }

  static Future<void> _splitSubtitleLine({
    required BuildContext context,
    required String firstPart,
    required String secondPart,
    required String firstPartTime,
    required String secondPartTime,
    required Id subtitleId,
    required SubtitleLine currentLine,
    required Function() refreshCallback,
    required int sessionId,
  }) async {
    try {
      // Keep copy of original line for checkpoint
      final originalLine = SubtitleLine()
        ..index = currentLine.index
        ..original = currentLine.original
        ..edited = currentLine.edited
        ..startTime = currentLine.startTime
        ..endTime = currentLine.endTime;

      final newLine = SubtitleLine()
        ..index = currentLine.index + 1
        ..original = currentLine.original
        ..edited = secondPart.replaceAll('\n', '<br>')
        ..startTime = secondPartTime.split(' → ')[0]
        ..endTime = secondPartTime.split(' → ')[1];

      // Create a copy of the first part for checkpoint (before modifying currentLine)
      final firstPartForCheckpoint = SubtitleLine()
        ..index = currentLine.index
        ..original = currentLine.original
        ..edited = firstPart.replaceAll('\n', '<br>')
        ..startTime = currentLine.startTime
        ..endTime = firstPartTime.split(' → ')[1];

      // Create checkpoint BEFORE splitting
      await CheckpointManager.createSplitCheckpoint(
        sessionId: sessionId,
        subtitleCollectionId: subtitleId,
        originalLine: originalLine,
        firstPart: firstPartForCheckpoint,
        secondPart: newLine,
      );

      // Now modify the current line
      currentLine.edited = firstPart.replaceAll('\n', '<br>');
      currentLine.endTime = firstPartTime.split(' → ')[1];

      final success = await splitSubtitleLine(
          subtitleId, currentLine, newLine, currentLine.index - 1);

      if (success) {
        
        // Update the lastEditedIndex to the first part of the split
        await updateLastEditedIndex(sessionId, currentLine.index);
        
        refreshCallback();
        if (!context.mounted) return;

        SnackbarHelper.showSuccess(
          context,
          'Subtitle split successfully',
        );
      } else {
        throw Exception('Failed to split subtitle in database');
      }
    } catch (e) {
      if (!context.mounted) return;

      SnackbarHelper.showError(
        context,
        'Failed to split subtitle: $e',
      );
    }
  }

  static void showMergeConfirmation({
    required BuildContext context,
    required SubtitleLine currentLine,
    required SubtitleCollection collection,
    required Id subtitleId,
    required Function(int newLineIndex) refreshCallback,
    required int sessionId,
  }) {
    final hasPreviousLine = currentLine.index > 1;
    final hasNextLine = currentLine.index < collection.lines.length;

    showModalBottomSheet(
      context: context,
      builder: (context) => MergeConfirmationSheet(
        lineIndex: currentLine.index,
        hasPreviousLine: hasPreviousLine,
        hasNextLine: hasNextLine,
        onConfirm: (mergePrevious) => _mergeSubtitleLine(
          context: context,
          mergePrevious: mergePrevious,
          currentLine: currentLine,
          collection: collection,
          subtitleId: subtitleId,
          refreshCallback: refreshCallback,
          sessionId: sessionId,
        ),
      ),
    );
  }

  static Future<void> _mergeSubtitleLine({
    required BuildContext context,
    required bool mergePrevious,
    required SubtitleLine currentLine,
    required SubtitleCollection collection,
    required Id subtitleId,
    required Function(int newLineIndex) refreshCallback,
    required int sessionId,
  }) async {
    logInfo('Merging subtitle line: ${currentLine.index} ${mergePrevious ? 'with previous' : 'with next'} line');
    
    try {
      final currentIndex = currentLine.index - 1;
      final mergeIndex = mergePrevious ? currentIndex - 1 : currentIndex + 1;

      if (mergeIndex < 0 || mergeIndex >= collection.lines.length) {
        logError('Invalid merge index: $mergeIndex for collection with ${collection.lines.length} lines');
        throw Exception('Invalid merge index');
      }

      final mergeTargetLine = collection.lines[mergeIndex];
      
      // Keep copies of original lines for checkpoint
      final originalFirst = SubtitleLine()
        ..index = mergePrevious ? mergeTargetLine.index : currentLine.index
        ..original = mergePrevious ? mergeTargetLine.original : currentLine.original
        ..edited = mergePrevious ? mergeTargetLine.edited : currentLine.edited
        ..startTime = mergePrevious ? mergeTargetLine.startTime : currentLine.startTime
        ..endTime = mergePrevious ? mergeTargetLine.endTime : currentLine.endTime;
      
      final originalSecond = SubtitleLine()
        ..index = mergePrevious ? currentLine.index : mergeTargetLine.index
        ..original = mergePrevious ? currentLine.original : mergeTargetLine.original
        ..edited = mergePrevious ? currentLine.edited : mergeTargetLine.edited
        ..startTime = mergePrevious ? currentLine.startTime : mergeTargetLine.startTime
        ..endTime = mergePrevious ? currentLine.endTime : mergeTargetLine.endTime;

      // Helper function to merge text fields, handling null values properly
      String? mergeEditedFields(String? first, String? second) {
        if (first == null && second == null) return null;
        if (first == null) return second;
        if (second == null) return first;
        return '$first\n$second';
      }

      final mergedLine = SubtitleLine()
        ..index = mergePrevious ? mergeTargetLine.index : currentLine.index
        ..original = mergePrevious
            ? '${mergeTargetLine.original}\n${currentLine.original}'
            : '${currentLine.original}\n${mergeTargetLine.original}'
        ..edited = mergePrevious
            ? mergeEditedFields(mergeTargetLine.edited, currentLine.edited)
            : mergeEditedFields(currentLine.edited, mergeTargetLine.edited)
        ..startTime =
            mergePrevious ? mergeTargetLine.startTime : currentLine.startTime
        ..endTime =
            mergePrevious ? currentLine.endTime : mergeTargetLine.endTime;

      // Create checkpoint BEFORE merging
      await CheckpointManager.createMergeCheckpoint(
        sessionId: sessionId,
        subtitleCollectionId: subtitleId,
        firstLine: originalFirst,
        secondLine: originalSecond,
        mergedLine: mergedLine,
      );

      final success = await mergeSubtitleLines(
          subtitleId,
          mergedLine,
          mergePrevious ? mergeIndex : currentIndex,
          mergePrevious ? currentIndex : mergeIndex);

      if (success) {
        
        logInfo('Subtitle lines merged successfully: lines ${currentLine.index} and ${mergeTargetLine.index}');
        
        // Navigate to the correct line after merge
        // When merging with previous: navigate to the previous line (which now contains merged content)
        // When merging with next: stay at current line (which now contains merged content)
        final navigateToIndex = mergePrevious ? currentLine.index - 1 : currentLine.index;
        refreshCallback(navigateToIndex);
        
        if (!context.mounted) return;

        SnackbarHelper.showSuccess(
          context,
          'Subtitle lines merged successfully',
        );
      } else {
        logError('Failed to merge subtitle lines in database');
        throw Exception('Failed to merge subtitle lines');
      }
    } catch (e) {
      logError('Error during merge operation: $e');
      if (!context.mounted) return;

      SnackbarHelper.showError(
        context,
        'Failed to merge subtitle lines: $e',
      );
    }
  }

  static void showAddLineConfirmation({
    required BuildContext context,
    required SubtitleLine currentLine,
    required SubtitleCollection collection,
    required String currentStartTime,
    required String currentEndTime,
    required Id subtitleId,
    required Function(int newLineIndex) refreshCallback, // Changed to accept new line index
    required int sessionId,
    required Future<bool> Function() onBeforeAdd, // New callback to save current line
    bool isVideoLoaded = false,
    Duration? Function()? getCurrentVideoPosition,
  }) {
    // Use fetchSubtitle from database_helper instead of direct DB access
    fetchSubtitle(subtitleId).then((freshCollection) {
      if (freshCollection == null) {
        _showErrorSnackbar(context, 'Collection not found');
        return;
      }
      
      // Use the fresh collection for accurate indexes
      final currentIndex = currentLine.index - 1;
      final isFirstLine = currentIndex == 0;
      final isLastLine = currentIndex >= freshCollection.lines.length - 1;
      final isSingleLine = freshCollection.lines.length == 1;
      
      // Safely access previous and next times with bounds checking
      String? previousEndTime;
      String? nextStartTime;
      
      // Check array bounds before access
      if (!isFirstLine && currentIndex > 0 && currentIndex - 1 < freshCollection.lines.length) {
        previousEndTime = freshCollection.lines[currentIndex - 1].endTime;
      }
      
      // Check array bounds before access
      if (!isLastLine && currentIndex + 1 < freshCollection.lines.length) {
        nextStartTime = freshCollection.lines[currentIndex + 1].startTime;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => AddLineConfirmationSheet(
          lineIndex: currentLine.index,
          currentStartTime: currentStartTime,
          currentEndTime: currentEndTime,
          previousEndTime: previousEndTime,
          nextStartTime: nextStartTime,
          isSingleLine: isSingleLine,
          isVideoLoaded: isVideoLoaded,
          getCurrentVideoPosition: getCurrentVideoPosition,
          collection: freshCollection,
          onConfirm: (addBefore, useVideoPosition, durationMs) async {
            // Save current line before adding new line
            final saveSuccess = await onBeforeAdd();
            if (!saveSuccess) {
              if (context.mounted) {
                _showErrorSnackbar(context, 'Failed to save current line before adding new line');
              }
              return;
            }
            
            // Calculate the new line index before calling _addNewLine
            // When adding before: new line takes current index, so navigate to current index
            // When adding after: old line stays at current index, new line is at index+1
            // Note: currentLine.index is 1-based (display index), so we pass it directly
            final newLineIndexToNavigate = addBefore ? currentLine.index : currentLine.index + 1;
            
            // Proceed with adding new line
            await _addNewLine(
              context: context,
              addBefore: addBefore,
              currentLine: currentLine,
              collection: freshCollection,
              subtitleId: subtitleId,
              refreshCallback: refreshCallback,
              sessionId: sessionId,
              newLineIndex: newLineIndexToNavigate,
              useVideoPosition: useVideoPosition,
              videoPosition: useVideoPosition && getCurrentVideoPosition != null ? getCurrentVideoPosition() : null,
              durationMs: durationMs,
            );
          },
        ),
      );
    });
  }

  static Future<void> _addNewLine({
    required BuildContext context,
    required bool addBefore,
    required SubtitleLine currentLine,
    required SubtitleCollection collection,
    required Id subtitleId,
    required Function(int newLineIndex) refreshCallback,
    required int sessionId,
    required int newLineIndex,
    bool useVideoPosition = false,
    Duration? videoPosition,
    int durationMs = 2000,
  }) async {
    try {
      final currentIndex = currentLine.index - 1;
      String startTime, endTime;

      // If using video position and it's available
      if (useVideoPosition && videoPosition != null) {
        if (addBefore) {
          // New line ends at video position
          endTime = _formatTime(videoPosition);
          // New line starts duration before video position
          final newLineStart = Duration(
            milliseconds: videoPosition.inMilliseconds - durationMs > 0
                ? videoPosition.inMilliseconds - durationMs
                : 0,
          );
          startTime = _formatTime(newLineStart);
        } else {
          // New line starts at video position
          startTime = _formatTime(videoPosition);
          // New line ends duration after video position
          endTime = _formatTime(Duration(
            milliseconds: videoPosition.inMilliseconds + durationMs,
          ));
        }
      } else {
        // Use default timing based on current line times
        final currentStart = _parseTime(currentLine.startTime);
        final currentEnd = _parseTime(currentLine.endTime);

        if (addBefore) {
          // For any line, create a new line with custom duration before (but not before 0)
          final newLineStart = Duration(
              milliseconds: currentStart.inMilliseconds - durationMs > 0 
                  ? currentStart.inMilliseconds - durationMs 
                  : 0);
          startTime = _formatTime(newLineStart);
          endTime = currentLine.startTime;
        } else {
          // For any line, create a new line with custom duration after current end
          startTime = currentLine.endTime;
          endTime = _formatTime(Duration(
              milliseconds: currentEnd.inMilliseconds + durationMs));
        }
      }

      // Fixed insertion index calculation to avoid range errors
      int newLineIndexForDb;
      if (addBefore) {
        newLineIndexForDb = currentLine.index;
      } else {
        newLineIndexForDb = currentLine.index + 1;
      }

      // Create the new line with proper index
      final newLine = SubtitleLine()
        ..index = newLineIndexForDb
        ..original = ''
        ..startTime = startTime
        ..endTime = endTime;

      // Use properly calculated index for database insertion
      final insertAtIndex = addBefore ? currentIndex : currentIndex + 1;
      
      // Create checkpoint BEFORE adding
      await CheckpointManager.createAddCheckpoint(
        sessionId: sessionId,
        subtitleCollectionId: subtitleId,
        addedLine: newLine,
        insertIndex: insertAtIndex,
      );
      
      final success = await addSubtitleLine(subtitleId, newLine, insertAtIndex);

      if (success) {
        // Navigate to the newly added line using the callback with the correct index
        refreshCallback(newLineIndex);
        if (!context.mounted) return;
        showSuccessSnackbar(context, 'New line added successfully at line $newLineIndex');
      } else {
        throw Exception('Failed to add new line');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackbar(context, 'Failed to add new line: $e');
    }
  }

  // Helper methods
  static Duration _parseTime(String time) {
    List<String> parts = time.split(',');
    List<String> hms = parts[0].split(':');
    return Duration(
        hours: int.parse(hms[0]),
        minutes: int.parse(hms[1]),
        seconds: int.parse(hms[2]),
        milliseconds: int.parse(parts[1]));
  }

  static String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');

    return '${twoDigits(duration.inHours)}:'
        '${twoDigits(duration.inMinutes.remainder(60))}:'
        '${twoDigits(duration.inSeconds.remainder(60))},'
        '${threeDigits(duration.inMilliseconds.remainder(1000))}';
  }
}
