import 'package:flutter/services.dart';

/// A custom input formatter for time input in the format HH:mm:ss,SSS
/// Users can only edit digits, separators (:, ,) are automatically maintained
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Handle empty input - show full format with zeros
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '00:00:00,000',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // Check if this is a deletion by comparing lengths and content
    final isLengthReduction = newValue.text.length < oldValue.text.length;
    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    final newDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final isDigitReduction = newDigits.length < oldDigits.length;
    
    // If this is a deletion, try to handle it more naturally
    if (isLengthReduction && isDigitReduction && oldDigits.length == newDigits.length + 1) {
      return _handleSimpleDeletion(oldValue, newValue);
    }
    
    // For additions or other changes, use the normal formatting
    return _handleNormalFormatting(newValue);
  }
  
  /// Handle deletions by trying to maintain the structure
  TextEditingValue _handleSimpleDeletion(TextEditingValue oldValue, TextEditingValue newValue) {
    // Try to maintain the existing structure for simple deletions
    final newText = newValue.text;
    
    // Check if the new text is a valid partial time format
    if (_isValidPartialTimeFormat(newText)) {
      // Calculate the correct cursor position for deletion
      final cursorPos = _calculateCursorPositionForDeletion(oldValue, newValue);
      
      // If it's already in a good format, keep it as is with corrected cursor
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPos),
      );
    }
    
    // Otherwise, fall back to normal formatting
    return _handleNormalFormatting(newValue);
  }
  
  /// Calculate cursor position for deletion scenarios
  int _calculateCursorPositionForDeletion(TextEditingValue oldValue, TextEditingValue newValue) {
    final oldText = oldValue.text;
    final newText = newValue.text;
    
    // Find where the deletion occurred
    int deletionPos = -1;
    for (int i = 0; i < oldText.length && i < newText.length; i++) {
      if (oldText[i] != newText[i]) {
        deletionPos = i;
        break;
      }
    }
    
    // If we couldn't find the deletion position, or deletion was at the end
    if (deletionPos == -1) {
      deletionPos = newText.length;
    }
    
    // The cursor should be at the deletion position
    return deletionPos;
  }
  
  /// Check if text is a valid partial time format that we should preserve
  bool _isValidPartialTimeFormat(String text) {
    // Allow patterns like:
    // 1, 12, 12:, 12:3, 12:34, 12:34:, 12:34:5, 12:34:56, 12:34:56,, 12:34:56,7, etc.
    // Also accept full format: 12:34:56,789
    return RegExp(r'^\d{0,2}(:\d{0,2}(:\d{0,2}(,\d{0,3})?)?)?$').hasMatch(text);
  }
  
  /// Handle normal formatting for additions and complex changes
  TextEditingValue _handleNormalFormatting(TextEditingValue newValue) {
    // Remove all non-digit characters from the new input
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Limit to 9 digits maximum (HH mm ss SSS)
    final limitedDigits = digitsOnly.length > 9 ? digitsOnly.substring(0, 9) : digitsOnly;
    
    // If no digits, return empty
    if (limitedDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // Format the digits into HH:mm:ss,SSS based on how many digits we have
    String formattedTime = _formatDigits(limitedDigits);
    
    // Calculate cursor position
    int cursorPosition = _calculateCursorPositionForNormalFormatting(newValue, formattedTime);
    
    return TextEditingValue(
      text: formattedTime,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
  
  /// Calculate cursor position for normal formatting (non-deletion cases)
  int _calculateCursorPositionForNormalFormatting(TextEditingValue newValue, String formattedText) {
    final newText = newValue.text;
    final newCursor = newValue.selection.baseOffset;
    
    // Count digits before cursor in the input text
    int digitsBeforeCursor = 0;
    for (int i = 0; i < newCursor && i < newText.length; i++) {
      if (RegExp(r'\d').hasMatch(newText[i])) {
        digitsBeforeCursor++;
      }
    }
    
    return _findPositionAfterNthDigit(formattedText, digitsBeforeCursor);
  }
  
  /// Format digits into HH:mm:ss,SSS format with separators always visible
  String _formatDigits(String digits) {
    // Pad digits to ensure we always have the full structure
    final paddedDigits = digits.padRight(9, '0');
    
    // Always return full format: HH:mm:ss,SSS
    return '${paddedDigits.substring(0, 2)}:${paddedDigits.substring(2, 4)}:${paddedDigits.substring(4, 6)},${paddedDigits.substring(6, 9)}';
  }
  
  /// Find position after the nth digit in formatted text
  int _findPositionAfterNthDigit(String formattedText, int n) {
    if (n <= 0) return 0;
    
    int digitCount = 0;
    for (int i = 0; i < formattedText.length; i++) {
      if (RegExp(r'\d').hasMatch(formattedText[i])) {
        digitCount++;
        if (digitCount == n) {
          return i + 1;
        }
      }
    }
    
    return formattedText.length;
  }
}

/// Validates time string and returns error message if invalid
class TimeValidator {
  static String? validateTimeString(String timeString) {
    if (timeString.isEmpty) return 'Time cannot be empty';
    
    // Parse the time string - be more flexible with format
    final timeRegex = RegExp(r'^(\d{1,2}):(\d{1,2}):(\d{1,2}),(\d{1,3})$');
    final match = timeRegex.firstMatch(timeString);
    
    if (match == null) {
      return 'Invalid time format. Use HH:mm:ss,SSS';
    }
    
    try {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final milliseconds = int.parse(match.group(4)!);
      
      if (hours > 23) return 'Hours must be 0-23';
      if (minutes > 59) return 'Minutes must be 0-59';
      if (seconds > 59) return 'Seconds must be 0-59';
      if (milliseconds > 999) return 'Milliseconds must be 0-999';
      
      return null; // No errors
    } catch (e) {
      return 'Invalid time values';
    }
  }
  
  /// Converts time string to milliseconds for comparison
  static int timeStringToMilliseconds(String timeString) {
    final timeRegex = RegExp(r'^(\d{1,2}):(\d{1,2}):(\d{1,2}),(\d{1,3})$');
    final match = timeRegex.firstMatch(timeString);
    
    if (match == null) return 0;
    
    try {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final milliseconds = int.parse(match.group(4)!);
      
      return hours * 3600000 + minutes * 60000 + seconds * 1000 + milliseconds;
    } catch (e) {
      return 0;
    }
  }
  
  /// Validates that start time is less than end time
  static String? validateTimeOrder(String startTime, String endTime) {
    final startMs = timeStringToMilliseconds(startTime);
    final endMs = timeStringToMilliseconds(endTime);
    
    if (startMs >= endMs) {
      return 'Start time must be less than end time';
    }
    
    return null;
  }
}
