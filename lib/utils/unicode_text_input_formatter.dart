import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// A text input formatter that handles Unicode characters properly for individual character deletion.
/// 
/// This formatter ensures that backspace operations work correctly with
/// Unicode characters by allowing deletion of individual characters within
/// complex scripts like Malayalam (പി, കു, ക്), Arabic, Devanagari, etc.
/// 
/// Instead of deleting entire grapheme clusters (which is the default behavior),
/// this formatter allows deletion of individual combining characters (runes/code points).
/// 
/// IMPORTANT: This formatter respects IME composition states to ensure compatibility
/// with advanced keyboards like Gboard's transliteration feature.
/// 
/// Examples of desired behavior:
/// - Malayalam: പി (പ് + ി) - Backspace should delete ി leaving പ
/// - Arabic: بِسْمِ (with diacritics) - Should delete individual diacritics
/// - Devanagari: कि (क + ि) - Should delete ि leaving क
/// - Complex clusters: ചെയ്തോളാ - Delete ാ from ളാ leaves ചെയ്തോളമെന്ന് (no unwanted conjuncts)
/// - Gboard transliteration: "kai" → "കൈ" (works correctly during composition)
/// 
/// This allows fine-grained editing of complex Unicode text while maintaining
/// compatibility with advanced input methods.
class UnicodeTextInputFormatter extends TextInputFormatter {
  /// Whether to enable debug logging for troubleshooting IME issues
  final bool enableDebugLogging;
  
  /// Creates a new UnicodeTextInputFormatter
  /// 
  /// [enableDebugLogging] - Set to true to enable debug output for troubleshooting
  /// transliteration and IME composition issues. Only works in debug mode.
  const UnicodeTextInputFormatter({this.enableDebugLogging = false});
  
  /// Internal method to log debug information
  void _debugLog(String message) {
    if (enableDebugLogging && kDebugMode) {
      debugPrint('[UnicodeFormatter] $message');
    }
  }
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    _debugLog('=== FORMAT UPDATE ===');
    _debugLog('Old: "${oldValue.text}" (${oldValue.text.length}) composing: ${oldValue.composing}');
    _debugLog('New: "${newValue.text}" (${newValue.text.length}) composing: ${newValue.composing}');
    
    // CRITICAL FIX: If the keyboard is in the middle of composing text (e.g., Gboard
    // transliteration), let it do its job without interference. The composing
    // range will be valid (start > -1) during this time.
    if (newValue.composing.isValid) {
      _debugLog('✓ New value has valid composing - allowing IME operation');
      return newValue;
    }

    // ADDITIONAL SAFETY: If the old value had a valid composing range, it means
    // we might be in the middle of a complex IME operation. Be extra cautious.
    if (oldValue.composing.isValid) {
      _debugLog('✓ Old value had valid composing - allowing IME completion');
      return newValue;
    }

    // If the text length is not reduced, it's not a deletion event.
    if (oldValue.text.length <= newValue.text.length) {
      _debugLog('✓ Text length not reduced - not a deletion');
      return newValue;
    }

    // If the user deleted a selection of text, let the default behavior apply.
    if (oldValue.selection.start != oldValue.selection.end) {
      _debugLog('✓ Selection deletion - using default behavior');
      return newValue;
    }

    // CRITICAL INSIGHT: We need to distinguish between:
    // 1. Manual backspace at cursor position (apply custom logic)
    // 2. IME text replacement operations (allow them)
    
    final deletionLength = oldValue.text.length - newValue.text.length;
    final cursorPos = oldValue.selection.baseOffset;
    
    _debugLog('Deletion length: $deletionLength, cursor: $cursorPos');
    
    // Check if this looks like a manual backspace operation:
    // - Deletion must happen RIGHT BEFORE the cursor
    // - The remaining text should match exactly
    
    if (cursorPos >= deletionLength) {
      // Calculate what the text should look like after a manual backspace
      final expectedPrefix = oldValue.text.substring(0, cursorPos - deletionLength);
      final expectedSuffix = oldValue.text.substring(cursorPos);
      final expectedText = expectedPrefix + expectedSuffix;
      final expectedCursor = cursorPos - deletionLength;
      
      _debugLog('Expected text: "$expectedText", actual: "${newValue.text}"');
      _debugLog('Expected cursor: $expectedCursor, actual: ${newValue.selection.baseOffset}');
      
      // If this matches exactly, it's a manual backspace operation
      if (newValue.text == expectedText && 
          newValue.selection.isCollapsed && 
          newValue.selection.baseOffset == expectedCursor) {
        
        _debugLog('→ Confirmed manual backspace - applying custom Unicode logic');
        
        // Apply our custom Unicode-aware deletion logic
        // Get the text that was before the cursor in the original string.
        final String textBeforeCursor = oldValue.selection.textBefore(oldValue.text);
        
        // If there's no text before the cursor, there's nothing to delete.
        if (textBeforeCursor.isEmpty) {
          _debugLog('✓ No text before cursor');
          return newValue;
        }

        // Get the Unicode code points (runes) of the text before the cursor.
        final runes = textBeforeCursor.runes.toList();

        // If there's only one rune, let the default behavior handle it
        if (runes.length <= 1) {
          _debugLog('✓ Single rune - using default behavior');
          return newValue;
        }

        _debugLog('Runes before cursor: ${runes.length} - ${runes.map((r) => String.fromCharCode(r)).join("")}');

        // ENHANCED FIX: Check if cursor is in the middle of a grapheme cluster
        // This happens when previous deletions created new conjuncts
        final String textAfterCursor = oldValue.selection.textAfter(oldValue.text);
        
        // Check if we're in the middle of a grapheme cluster by comparing
        // the cursor position with grapheme cluster boundaries
        bool isInMiddleOfCluster = false;
        if (textBeforeCursor.isNotEmpty && textAfterCursor.isNotEmpty) {
          // Look for potential conjunct formation around cursor
          final lastRuneBeforeCursor = runes.last;
          
          // Malayalam virama (്) indicates conjunct formation
          const int malayalamVirama = 0x0D4D;
          
          // IMPORTANT: Only treat as "middle of cluster" if:
          // 1. The last character before cursor is virama itself (deleting right after virama)
          // 2. OR there's a virama before the last character AND the last character is NOT a space
          //    (this means we're deleting a consonant that's part of a conjunct)
          //
          // This prevents the bug where deleting a space after "ക്ര " would incorrectly
          // delete the virama as well.
          const int spaceCodeUnit = 0x0020;
          
          if (lastRuneBeforeCursor == malayalamVirama) {
            // Case 1: Deleting right after a virama (e.g., "ക്|" deleting virama)
            isInMiddleOfCluster = true;
            _debugLog('⚠️  Cursor right after virama - using enhanced deletion');
          } else if (runes.length >= 2 && 
                     runes[runes.length - 2] == malayalamVirama && 
                     lastRuneBeforeCursor != spaceCodeUnit) {
            // Case 2: Deleting a consonant that's part of a conjunct (e.g., "ക്ര|" deleting ര)
            // But NOT if deleting a space after a conjunct (e.g., "ക്ര |" deleting space)
            isInMiddleOfCluster = true;
            _debugLog('⚠️  Cursor appears to be in middle of conjunct - using enhanced deletion');
          }
        }
        
        int runesToDelete = 1; // Default: delete one rune
        
        if (isInMiddleOfCluster) {
          // When in middle of conjunct, be smart about deletion to avoid
          // leaving partial conjuncts that confuse cursor positioning
          const int malayalamVirama = 0x0D4D;
          
          // Start with deleting just the current character
          int deleteCount = 1;
          
          // If the last character is not a virama, but there's a virama before it,
          // we're likely after a conjunct (consonant + virama + consonant)
          if (runes.length >= 2 && runes[runes.length - 2] == malayalamVirama) {
            // Delete both the consonant and the virama to clear the conjunct
            deleteCount = 2;
            _debugLog('→ Deleting conjunct: consonant + virama');
          } else if (runes.last == malayalamVirama) {
            // If cursor is right after a virama, just delete the virama
            deleteCount = 1;
            _debugLog('→ Deleting virama only');
          }
          
          runesToDelete = deleteCount;
          _debugLog('→ Enhanced deletion: removing $runesToDelete runes');
        }

        // Remove the calculated number of runes
        final newRunes = runes.sublist(0, runes.length - runesToDelete);

        // Reconstruct the string from the modified list of runes.
        final String newTextBeforeCursor = String.fromCharCodes(newRunes);

        // Combine the parts to form the final text.
        final customNewText = newTextBeforeCursor + textAfterCursor;

        _debugLog('→ Custom result: "$customNewText" (cursor at ${newTextBeforeCursor.length})');

        // Return the new TextEditingValue with the cursor positioned correctly.
        return TextEditingValue(
          text: customNewText,
          selection: TextSelection.collapsed(offset: newTextBeforeCursor.length),
        );
      }
    }
    
    // If we reach here, it's either:
    // - Not a backspace at cursor position
    // - An IME operation that doesn't match the manual backspace pattern
    // - Some other complex operation
    // In all these cases, use the default behavior
    _debugLog('✓ Complex operation or IME - using default behavior');
    return newValue;
  }
}

/// Extension on TextEditingController to add Unicode-aware helper methods
/// 
/// This extension provides additional functionality for working with Unicode text
/// in TextEditingController, allowing fine-grained control over individual runes/code points.
/// 
/// Note: These methods work independently of the UnicodeTextInputFormatter and don't
/// interfere with IME composition states.
extension UnicodeTextEditingController on TextEditingController {
  /// Gets the number of user-perceived characters (grapheme clusters)
  /// This is different from text.length which counts code units
  int get characterCount => text.characters.length;
  
  /// Gets the number of Unicode code points (runes) in the text
  /// This is different from both characterCount and text.length
  int get runeCount => text.runes.length;
  
  /// Deletes a single rune (code point) before the cursor position
  /// This allows deletion of individual characters within grapheme clusters
  void deleteSingleRuneBeforeCursor() {
    if (selection.isCollapsed && selection.baseOffset > 0) {
      final textBeforeCursor = selection.textBefore(text);
      final textAfterCursor = selection.textAfter(text);
      
      if (textBeforeCursor.isNotEmpty) {
        final runes = textBeforeCursor.runes.toList();
        final newRunes = runes.sublist(0, runes.length - 1);
        final newTextBeforeCursor = String.fromCharCodes(newRunes);
        
        value = TextEditingValue(
          text: newTextBeforeCursor + textAfterCursor,
          selection: TextSelection.collapsed(offset: newTextBeforeCursor.length),
        );
      }
    }
  }
  
  /// Inserts text at the current cursor position
  /// This is Unicode-aware and maintains proper cursor positioning
  void insertTextAtCursor(String textToInsert) {
    final currentSelection = selection;
    final currentText = text;
    
    if (currentSelection.isValid) {
      final newText = currentText.replaceRange(
        currentSelection.start,
        currentSelection.end,
        textToInsert,
      );
      
      final newCursorPosition = currentSelection.start + textToInsert.length;
      
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }
  }
  
  /// Gets the character at the specified index (0-based character index, not code unit index)
  String? getCharacterAt(int characterIndex) {
    final charactersList = text.characters.toList();
    if (characterIndex >= 0 && characterIndex < charactersList.length) {
      return charactersList[characterIndex];
    }
    return null;
  }
  
  /// Gets a substring by character indices (not code unit indices)
  String getCharacterSubstring(int startCharacterIndex, int endCharacterIndex) {
    final charactersList = text.characters.toList();
    final actualStart = startCharacterIndex.clamp(0, charactersList.length);
    final actualEnd = endCharacterIndex.clamp(actualStart, charactersList.length);
    
    return charactersList.sublist(actualStart, actualEnd).join();
  }
  
  /// Checks if the text contains complex Unicode characters
  /// This can be useful for debugging or UI decisions
  bool get hasComplexUnicodeCharacters {
    return text.characters.length != text.length;
  }
  
  /// Gets a list of all grapheme clusters in the text
  /// This can be useful for text analysis or debugging
  List<String> get allCharacters => text.characters.toList();
  
  /// Gets a list of all code units in the text
  /// This can be useful for debugging individual character deletion
  List<int> get allCodeUnits => text.codeUnits;
  
  /// Gets a list of all runes (code points) in the text
  /// This shows the individual Unicode code points
  List<int> get allRunes => text.runes.toList();
  
  /// Gets the number of code units (useful for comparing with characterCount)
  int get codeUnitCount => text.length;
}
