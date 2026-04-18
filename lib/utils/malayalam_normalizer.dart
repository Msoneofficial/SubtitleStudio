import 'package:flutter/services.dart';

class MalayalamNormalizer {
  // Map to store all normalization rules from the sed file
  static final Map<String, String> _normalizationRules = {};
  
  // Map to store regex-based rules that need special processing
  static final Map<String, Map<String, String>> _regexRules = {};
  
  // Initialize the normalizer by loading rules from the sed file
  static Future<void> initialize() async {
    if (_normalizationRules.isNotEmpty) return; // Already initialized
    
    try {
      // Load the sed file content
      final sedContent = await rootBundle.loadString('lib/utils/normalization.sed');
      _parseNormalizationRules(sedContent);
    } catch (e) {
      // Silent fail - rules will be empty if loading fails
      // This allows the app to continue working even if the sed file is missing
      print('Warning: Failed to load normalization.sed file: $e');
    }
  }
  
  // Parse the sed file content and extract normalization rules
  static void _parseNormalizationRules(String sedContent) {
    final lines = sedContent.split('\n');
    
    for (String line in lines) {
      line = line.trim();
      
      // Skip comments and empty lines
      if (line.isEmpty || line.startsWith('#') || !line.startsWith('s/')) {
        continue;
      }
      
      // Parse sed substitution command: s/find/replace/flags
      final regex = RegExp(r'^s/([^/]*)/([^/]*)/([gm]*)$');
      final match = regex.firstMatch(line);
      
      if (match != null) {
        String find = match.group(1)!;
        String replace = match.group(2)!;
        String flags = match.group(3) ?? '';
        
        // Handle special characters and escape sequences
        find = _unescapeSedString(find);
        replace = _unescapeSedString(replace);
        
        // Store rule with flags for regex processing
        _normalizationRules[find] = replace;
        
        // If the find pattern contains regex metacharacters, mark it for regex processing
        // For patterns that start with ^ (start of line), automatically add multiline flag
        if (_isRegexPattern(find) || flags.contains('m') || find.startsWith('^')) {
          String actualFlags = flags;
          if (find.startsWith('^') && !actualFlags.contains('m')) {
            actualFlags += 'm'; // Add multiline flag for start-of-line patterns
          }
          _regexRules[find] = {'replace': replace, 'flags': actualFlags};
        }
      }
    }
  }
  
  // Unescape sed special characters
  static String _unescapeSedString(String input) {
    return input
        .replaceAll(r'\s', ' ')  // \s -> space
        .replaceAll(r'\$', '\$') // \$ -> $
        .replaceAll(r'\\', '\\') // \\ -> \
        .replaceAll(r'\xC2\xAD', '\u00AD'); // Soft hyphen
  }
  
  // Check if a pattern contains regex metacharacters
  static bool _isRegexPattern(String pattern) {
    // Check for common regex metacharacters used in sed
    return pattern.contains('^') || 
           pattern.contains('\$') || 
           pattern.contains('[') || 
           pattern.contains('(') || 
           pattern.contains('*') || 
           pattern.contains('+') || 
           pattern.contains('\\(') ||
           pattern.contains('\\1');
    // Note: removed '?' check as it was causing issues with literal '?' characters
  }
  
  // Convert sed regex pattern to Dart RegExp pattern
  static String _convertSedRegexToDart(String sedPattern) {
    String dartPattern = sedPattern;
    
    // Convert sed character classes to Dart equivalents
    dartPattern = dartPattern
        .replaceAll('[[:space:]]', r'\s')
        .replaceAll('[[:digit:]]', r'\d')
        .replaceAll(r'\(', '(')  // Convert sed groups to Dart groups
        .replaceAll(r'\)', ')')
        .replaceAll(r'[^[:digit:] ]', r'[^0-9 ]') // Convert negative digit and space class
        .replaceAll(r'[^[:digit:]]', r'[^0-9]') // Convert negative digit class
        .replaceAll(r'[^[:space:]]', r'[^\s]'); // Convert negative space class
    
    return dartPattern;
  }
  
  // Check if text contains Malayalam characters
  static bool containsMalayalam(String text) {
    // Malayalam Unicode range: U+0D00-U+0D7F
    final malayalamRegex = RegExp(r'[\u0D00-\u0D7F]');
    return malayalamRegex.hasMatch(text);
  }
  
  // Normalize a single text string
  static String normalizeText(String text) {
    if (text.isEmpty) return text;
    
    String normalizedText = text;
    
    // Apply simple string replacement rules first
    for (String find in _normalizationRules.keys) {
      if (!_regexRules.containsKey(find)) {
        String replace = _normalizationRules[find]!;
        normalizedText = normalizedText.replaceAll(find, replace);
      }
    }
    
    // Apply regex-based rules
    for (String find in _regexRules.keys) {
      try {
        String replace = _regexRules[find]!['replace']!;
        String flags = _regexRules[find]!['flags']!;
        
        // Convert sed pattern to Dart RegExp
        String dartPattern = _convertSedRegexToDart(find);
        
        // Create RegExp with appropriate flags
        bool multiLine = flags.contains('m');
        RegExp regex = RegExp(dartPattern, multiLine: multiLine);
        
        // Convert sed replacement to Dart replacement and apply
        normalizedText = normalizedText.replaceAllMapped(regex, (match) {
          String result = replace;
          // Replace sed backreferences with actual matched groups
          for (int i = 1; i <= 9; i++) {
            if (result.contains('\\$i')) {
              String? groupValue = match.group(i);
              if (groupValue != null) {
                result = result.replaceAll('\\$i', groupValue);
              }
            }
          }
          return result;
        });
      } catch (e) {
        // If regex fails, fall back to simple string replacement
        print('Warning: Regex failed for pattern "$find": $e. Falling back to simple replacement.');
        String replace = _normalizationRules[find]!;
        normalizedText = normalizedText.replaceAll(find, replace);
      }
    }
    
    return normalizedText;
  }
  
  // Normalize text and return changes made
  static NormalizationResult normalizeWithChanges(String originalText) {
    if (originalText.isEmpty) {
      return NormalizationResult(
        originalText: originalText,
        normalizedText: originalText,
        changes: [],
        hasChanges: false,
      );
    }
    
    String currentText = originalText;
    List<NormalizationChange> changes = [];
    
    // Apply simple string replacement rules first and track changes
    for (String find in _normalizationRules.keys) {
      if (!_regexRules.containsKey(find)) {
        String replace = _normalizationRules[find]!;
        
        if (currentText.contains(find)) {
          String beforeChange = currentText;
          int occurrences = find.allMatches(currentText).length;
          currentText = currentText.replaceAll(find, replace);
          
          // Only add change if text actually changed
          if (beforeChange != currentText) {
            changes.add(NormalizationChange(
              rule: find,
              replacement: replace,
              occurrences: occurrences,
              beforeText: beforeChange,
              afterText: currentText,
            ));
          }
        }
      }
    }
    
    // Apply regex-based rules and track changes
    for (String find in _regexRules.keys) {
      try {
        String replace = _regexRules[find]!['replace']!;
        String flags = _regexRules[find]!['flags']!;
        
        // Convert sed pattern to Dart RegExp
        String dartPattern = _convertSedRegexToDart(find);
        
        // Create RegExp with appropriate flags
        bool multiLine = flags.contains('m');
        RegExp regex = RegExp(dartPattern, multiLine: multiLine);
        
        // Count matches before replacing
        int occurrences = regex.allMatches(currentText).length;
        
        if (occurrences > 0) {
          String beforeChange = currentText;
          
          // Convert sed replacement to Dart replacement and apply
          currentText = currentText.replaceAllMapped(regex, (match) {
            String result = replace;
            // Replace sed backreferences with actual matched groups
            for (int i = 1; i <= 9; i++) {
              if (result.contains('\\$i')) {
                String? groupValue = match.group(i);
                if (groupValue != null) {
                  result = result.replaceAll('\\$i', groupValue);
                }
              }
            }
            return result;
          });
          
          // Only add change if text actually changed
          if (beforeChange != currentText) {
            changes.add(NormalizationChange(
              rule: find,
              replacement: replace,
              occurrences: occurrences,
              beforeText: beforeChange,
              afterText: currentText,
            ));
          }
        }
      } catch (e) {
        // If regex fails, fall back to simple string replacement
        String replace = _normalizationRules[find]!;
        
        if (currentText.contains(find)) {
          String beforeChange = currentText;
          int occurrences = find.allMatches(currentText).length;
          currentText = currentText.replaceAll(find, replace);
          
          // Only add change if text actually changed
          if (beforeChange != currentText) {
            changes.add(NormalizationChange(
              rule: find,
              replacement: replace,
              occurrences: occurrences,
              beforeText: beforeChange,
              afterText: currentText,
            ));
          }
        }
      }
    }
    
    return NormalizationResult(
      originalText: originalText,
      normalizedText: currentText,
      changes: changes,
      hasChanges: changes.isNotEmpty,
    );
  }
  
  // Get count of available normalization rules
  static int get ruleCount => _normalizationRules.length;
  
  // Get count of regex rules
  static int get regexRuleCount => _regexRules.length;
  
  // Get all normalization rules
  static Map<String, String> get rules => Map.unmodifiable(_normalizationRules);
  
  // Get all regex rules
  static Map<String, Map<String, String>> get regexRules => Map.unmodifiable(_regexRules);
  
  // Test method to verify regex rules are working
  static String testRegexRules() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('=== MalayalamNormalizer Test Results ===');
    buffer.writeln('Total rules: ${_normalizationRules.length}');
    buffer.writeln('Regex rules: ${_regexRules.length}');
    buffer.writeln('');
    
    // Test cases for the new regex rules
    Map<String, String> testCases = {
      '   Leading spaces test': 'Leading spaces test',
      'Trailing spaces test   ': 'Trailing spaces test',
      'word1,word2': 'word1, word2', // Should add space (no space after comma)
      'word1, word2': 'word1, word2', // Should NOT change (space already exists)
      'number1,123': 'number1,123', // Should not change (digits after comma)
      'word1,abc': 'word1, abc', // Should add space before non-digits
      '-No space after dash': '- No space after dash',
      '- Already has space': '- Already has space',
      'സാധാ മനുഷ്യൻ': 'സാദാ മനുഷ്യൻ', // Should change (space after)
      'സാധാണം': 'സാധാണം', // Should NOT change (no space after)
      'സാധാ': 'സാധാ', // Should NOT change (no space after)
    };
    
    buffer.writeln('Testing new regex rules:');
    for (String input in testCases.keys) {
      String expected = testCases[input]!;
      String result = normalizeText(input);
      bool success = result == expected;
      buffer.writeln('${success ? "✓" : "✗"} "$input" → "$result" (expected: "$expected")');
    }
    
    return buffer.toString();
  }
}

// Class to represent a single normalization change
class NormalizationChange {
  final String rule;
  final String replacement;
  final int occurrences;
  final String? beforeText;
  final String? afterText;
  
  NormalizationChange({
    required this.rule,
    required this.replacement,
    required this.occurrences,
    this.beforeText,
    this.afterText,
  });
  
  @override
  String toString() {
    // For regex rules that remove content (like leading spaces), show a descriptive message
    if (rule == '^ *' && replacement.isEmpty) {
      return 'Removed leading spaces ($occurrences occurrence${occurrences > 1 ? 's' : ''})';
    }
    
    // For trailing spaces removal - check multiple possible patterns
    if ((rule == ' *\$' || rule == ' *\$' || rule.contains(' *\$')) && replacement.isEmpty) {
      return 'Removed trailing spaces ($occurrences occurrence${occurrences > 1 ? 's' : ''})';
    }
    
    // For comma spacing - check multiple possible patterns
    if (rule.contains(',\\([^[:digit:] ]\\)') || rule.contains(',([^0-9 ])') || rule.contains(',\\([^')) {
      return 'Added space after comma ($occurrences occurrence${occurrences > 1 ? 's' : ''})';
    }
    
    // For dash spacing
    if (rule.contains('^-\\([^ >]\\)') || rule.contains('^-([^ >])') || rule.contains('^-')) {
      return 'Fixed dash spacing ($occurrences occurrence${occurrences > 1 ? 's' : ''})';
    }
    
    // For conditional സാധാ → സാദാ correction (only when followed by space)
    if (rule.contains('സാധാ\\( \\)') || rule.contains('സാധാ( )')) {
      return 'Fixed spelling: "സാധാ" → "സാദാ" (only when followed by space) ($occurrences occurrence${occurrences > 1 ? 's' : ''})';
    }
    
    // Default format with more descriptive text
    if (replacement.isEmpty) {
      return 'Removed text pattern ($occurrences occurrence${occurrences > 1 ? 's' : ''})';
    } else {
      return 'Text improvement ($occurrences occurrence${occurrences > 1 ? 's' : ''})';
    }
  }
  
  // Get a sample of the change for display purposes
  String getChangeExample() {
    if (beforeText != null && afterText != null) {
      // Find the first difference between before and after text
      int maxLength = 50; // Limit sample length
      String beforeSample = beforeText!.length > maxLength 
          ? '${beforeText!.substring(0, maxLength)}...' 
          : beforeText!;
      String afterSample = afterText!.length > maxLength 
          ? '${afterText!.substring(0, maxLength)}...' 
          : afterText!;
      
      return 'Before: "$beforeSample"\nAfter:  "$afterSample"';
    }
    return '';
  }
}

// Class to represent the complete normalization result
class NormalizationResult {
  final String originalText;
  final String normalizedText;
  final List<NormalizationChange> changes;
  final bool hasChanges;
  
  NormalizationResult({
    required this.originalText,
    required this.normalizedText,
    required this.changes,
    required this.hasChanges,
  });
  
  // Get summary of changes
  String getChangesSummary() {
    if (!hasChanges) return 'No changes made';
    
    int totalChanges = changes.fold(0, (sum, change) => sum + change.occurrences);
    return '$totalChanges correction${totalChanges > 1 ? 's' : ''} applied';
  }
  
  // Get detailed changes for display
  List<String> getChangesDetails() {
    return changes.map((change) => change.toString()).toList();
  }
}
