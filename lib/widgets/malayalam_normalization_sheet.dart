import 'package:flutter/material.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/utils/malayalam_normalizer.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';

class MalayalamNormalizationSheet extends StatefulWidget {
  final int subtitleCollectionId;
  final List<SubtitleLine> subtitleLines;
  final VoidCallback onNormalizationComplete;

  const MalayalamNormalizationSheet({
    super.key,
    required this.subtitleCollectionId,
    required this.subtitleLines,
    required this.onNormalizationComplete,
  });

  @override
  State<MalayalamNormalizationSheet> createState() => _MalayalamNormalizationSheetState();
}

class _MalayalamNormalizationSheetState extends State<MalayalamNormalizationSheet> {
  bool _isAnalyzing = false;
  bool _isApplying = false;
  bool _isAnalyzed = false;
  bool _isCompleted = false;
  List<SubtitleNormalizationPreview> _previewResults = [];
  Map<int, bool> _selectedChanges = {};
  int _totalPotentialChanges = 0;
  bool _hasMalayalamContent = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkMalayalamContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkMalayalamContent() {
    // Check if any subtitle contains Malayalam text
    for (SubtitleLine line in widget.subtitleLines) {
      final textToCheck = line.edited ?? line.original;
      if (MalayalamNormalizer.containsMalayalam(textToCheck)) {
        _hasMalayalamContent = true;
        break;
      }
    }
  }

  // Helper function to parse subtitle time to DateTime
  DateTime _parseSubtitleTime(String time) {
    // Assuming the time format is "HH:mm:ss,SSS" (e.g., "00:01:23,456")
    List<String> parts = time.split(',');
    List<String> hms = parts[0].split(':');
    int hours = int.parse(hms[0]);
    int minutes = int.parse(hms[1]);
    int seconds = int.parse(hms[2]);
    int milliseconds = int.parse(parts[1]);

    return DateTime(0, 1, 1, hours, minutes, seconds, milliseconds);
  }

  Future<void> _analyzeChanges() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Use microtask to ensure UI updates immediately
      await Future.microtask(() {});
      
      // Initialize the normalizer
      await MalayalamNormalizer.initialize();

      List<SubtitleNormalizationPreview> previews = [];
      int totalPotentialChanges = 0;
      Map<int, bool> selectedChanges = {};

      // Process subtitles in batches to prevent UI blocking
      const batchSize = 50;
      for (int batchStart = 0; batchStart < widget.subtitleLines.length; batchStart += batchSize) {
        final batchEnd = (batchStart + batchSize < widget.subtitleLines.length) 
            ? batchStart + batchSize 
            : widget.subtitleLines.length;
        
        // Process this batch
        for (int i = batchStart; i < batchEnd; i++) {
          final line = widget.subtitleLines[i];
          final originalText = line.edited ?? line.original;
          
          final normalizationResult = MalayalamNormalizer.normalizeWithChanges(originalText);
          
          if (normalizationResult.hasChanges) {
            final preview = SubtitleNormalizationPreview(
              lineIndex: i,
              subtitleLine: line,
              originalText: originalText,
              result: normalizationResult,
            );
            
            previews.add(preview);
            totalPotentialChanges += normalizationResult.changes.length;
            // Use preview index (previews.length - 1) instead of subtitle line index i
            selectedChanges[previews.length - 1] = true; // Select all by default
          }
        }
        
        // Allow UI to breathe between batches
        if (batchEnd < widget.subtitleLines.length) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      // Ensure the widget is still mounted before updating state
      if (mounted) {
        // Update the data and immediately set both flags
        setState(() {
          _previewResults = previews;
          _totalPotentialChanges = totalPotentialChanges;
          _selectedChanges = selectedChanges;
          _isAnalyzing = false;
          _isAnalyzed = true;
        });
      }

    } catch (e) {
      debugPrint('Error during analysis: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _applySelectedChanges() async {
    setState(() {
      _isApplying = true;
    });

    try {
      int successfulUpdates = 0;

      // Apply changes only for selected previews
      for (int i = 0; i < _previewResults.length; i++) {
        if (_selectedChanges[i] == true) {
          final preview = _previewResults[i];

          // Create updated line
          final updatedLine = SubtitleLine()
            ..index = preview.subtitleLine.index
            ..original = preview.subtitleLine.original
            ..edited = preview.result.normalizedText
            ..startTime = preview.subtitleLine.startTime
            ..endTime = preview.subtitleLine.endTime
            ..marked = preview.subtitleLine.marked;

          try {
            await saveSubtitleChangesToDatabase(
              widget.subtitleCollectionId,
              updatedLine,
              _parseSubtitleTime,
            );

            successfulUpdates++;
          } catch (e) {
            debugPrint('Failed to update line ${preview.lineIndex + 1}: $e');
          }
        }
      }

      setState(() {
        _isApplying = false;
        _isCompleted = true;
      });

      if (successfulUpdates > 0) {
        widget.onNormalizationComplete();
        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            'Applied normalization to $successfulUpdates subtitle line${successfulUpdates != 1 ? 's' : ''}',
          );
        }
      }

    } catch (e) {
      setState(() {
        _isApplying = false;
      });
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Failed to apply changes: $e',
        );
      }
    }
  }

  void _toggleAllChanges(bool selectAll) {
    setState(() {
      for (int i = 0; i < _previewResults.length; i++) {
        _selectedChanges[i] = selectAll;
      }
    });
  }

  int get _selectedChangesCount {
    return _selectedChanges.values.where((selected) => selected == true).length;
  }

  // Helper method to provide user-friendly descriptions for changes
  String _getChangeDescription(NormalizationChange change) {
    final rule = change.rule;
    final replacement = change.replacement;
    final count = change.occurrences;
    
    // Common spelling corrections
    if (rule == 'പക്ഷെ' && replacement == 'പക്ഷേ') {
      return 'Fixed spelling: "പക്ഷെ" → "പക്ഷേ" ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == 'അപ്പൊൾ' && replacement == 'അപ്പോൾ') {
      return 'Fixed spelling: "അപ്പൊൾ" → "അപ്പോൾ" ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == 'ഇപ്പൊൾ' && replacement == 'ഇപ്പോൾ') {
      return 'Fixed spelling: "ഇപ്പൊൾ" → "ഇപ്പോൾ" ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == 'ഒകെ' && replacement == 'ഓക്കെ') {
      return 'Fixed spelling: "ഒകെ" → "ഓക്കെ" ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == 'ശെരി' && replacement == 'ശരി') {
      return 'Fixed spelling: "ശെരി" → "ശരി" ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == 'പെട്ടന്ന്' && replacement == 'പെട്ടെന്ന്') {
      return 'Fixed spelling: "പെട്ടന്ന്" → "പെട്ടെന്ന്" ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == 'നമ്മുക്ക്' && replacement == 'നമുക്ക്') {
      return 'Fixed spelling: "നമ്മുക്ക്" → "നമുക്ക്" ($count time${count > 1 ? 's' : ''})';
    }
    
    // Conditional spelling corrections (regex-based)
    if (rule.contains('സാധാ\\( \\)') || rule.contains('സാധാ( )')) {
      return 'Fixed spelling: "സാധാ" → "സാദാ" (only when followed by space) ($count time${count > 1 ? 's' : ''})';
    }
    
    // Chillu character normalization with detailed explanations
    if (rule == 'ന്‍' && replacement == 'ൻ') {
      return 'Normalized chillu-N: "ന്‍" (na + virama + zwnj) → "ൻ" (chillu-n) - Modern Unicode form ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == 'ള്‍' && replacement == 'ൾ') {
      return 'Normalized chillu-L: "ള്‍" (la + virama + zwnj) → "ൾ" (chillu-ll) - Modern Unicode form ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == 'ല്‍' && replacement == 'ൽ') {
      return 'Normalized chillu-L: "ല്‍" (la + virama + zwnj) → "ൽ" (chillu-l) - Modern Unicode form ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == 'ര്‍' && replacement == 'ർ') {
      return 'Normalized chillu-R: "ര്‍" (ra + virama + zwnj) → "ർ" (chillu-rr) - Modern Unicode form ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == 'ണ്‍' && replacement == 'ൺ') {
      return 'Normalized chillu-N: "ണ്‍" (nna + virama + zwnj) → "ൺ" (chillu-nn) - Modern Unicode form ($count time${count > 1 ? 's' : ''})';
    }
    
    // ZWNJ and spacing fixes
    if (rule.contains('‌')) {
      return 'Removed unnecessary ZWNJ (Zero Width Non-Joiner U+200C) - Improves text rendering ($count time${count > 1 ? 's' : ''})';
    }
    
    // Punctuation fixes
    if (rule == ' ?' && replacement == '?') {
      return 'Fixed question mark spacing: Removed space before "?" ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == ' !' && replacement == '!') {
      return 'Fixed exclamation mark spacing: Removed space before "!" ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == ' ,' && replacement == ',') {
      return 'Fixed comma spacing: Removed space before "," ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == '  ' && replacement == ' ') {
      return 'Fixed double spacing: Multiple spaces → Single space ($count time${count > 1 ? 's' : ''})';
    }
    
    // Au sign normalization
    if (rule == 'ൌ' && replacement == 'ൗ') {
      return 'Updated Au vowel sign: "ൌ" (old form U+0D4C) → "ൗ" (modern form U+0D57) ($count time${count > 1 ? 's' : ''})';
    }
    
    // Vowel combinations
    if (rule == 'ാെ' && replacement == 'ൊ') {
      return 'Normalized vowel combination: "ാെ" (aa + e) → "ൊ" (proper o vowel) ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == 'ാേ' && replacement == 'ോ') {
      return 'Normalized vowel combination: "ാേ" (aa + ee) → "ോ" (proper oo vowel) ($count time${count > 1 ? 's' : ''})';
    }
    
    // Conjunct fixes
    if (rule.contains('ൻറ') || rule.contains('ന്റ')) {
      return 'Fixed conjunct consonant: Chillu-n + റ combination for better rendering ($count time${count > 1 ? 's' : ''})';
    }
    
    // Soft hyphen removal
    if (rule.contains('\xC2\xAD')) {
      return 'Removed soft hyphen: Invisible U+00AD character that affects text processing ($count time${count > 1 ? 's' : ''})';
    }
    
    // New regex-based formatting rules (matching actual sed patterns)
    if (rule == ' *\$') {
      return 'Removed trailing spaces: Cleaned up spacing at end of lines ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == '^ *') {
      return 'Removed leading spaces: Cleaned up spacing at beginning of lines ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == ',\\([^[:digit:] ]\\)') {
      return 'Added space after comma: Improved readability by adding space after comma when not followed by digit or space ($count time${count > 1 ? 's' : ''})';
    }
    if (rule == '^-\\([^ >]\\)') {
      return 'Fixed dash spacing: Added space after dash at beginning of line ($count time${count > 1 ? 's' : ''})';
    }
    
    // Generic fallback for other changes
    if (rule.length == 1 && replacement.length == 1) {
      return 'Character normalization: "$rule" → "$replacement" - Unicode standardization ($count time${count > 1 ? 's' : ''})';
    }
    
    // For complex rules, show a generic description
    return 'Text improvement: "$rule" → "$replacement" ($count time${count > 1 ? 's' : ''})';
  }

  // Helper method to build highlighted text showing where changes occur
  Widget _buildHighlightedText(BuildContext context, String text, List<NormalizationChange> changes, {required bool isOriginal}) {
    if (changes.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
        ),
      );
    }

    if (isOriginal) {
      // For BEFORE: use a simpler approach - apply each rule and see what would change
      List<TextSpan> spans = [];
      String workingText = text;
      
      // Create a map of positions to highlight
      Set<int> highlightPositions = <int>{};
      
      for (var change in changes) {
        String rule = change.rule;
        
        try {
          if (rule == ' *\$') {
            // Trailing spaces - only highlight if there are actual spaces
            RegExp regex = RegExp(r' +$');  // Use + to require at least one space
            for (var match in regex.allMatches(workingText)) {
              for (int i = match.start; i < match.end; i++) {
                highlightPositions.add(i);
              }
            }
          } else if (rule == '^ *') {
            // Leading spaces - only highlight if there are actual spaces
            RegExp regex = RegExp(r'^ +');  // Use + to require at least one space
            for (var match in regex.allMatches(workingText)) {
              for (int i = match.start; i < match.end; i++) {
                highlightPositions.add(i);
              }
            }
          } else if (rule == ',\\([^[:digit:] ]\\)') {
            // Comma without space
            RegExp regex = RegExp(r',([^0-9 ])');
            for (var match in regex.allMatches(workingText)) {
              for (int i = match.start; i < match.end; i++) {
                highlightPositions.add(i);
              }
            }
          } else if (rule == '^-\\([^ >]\\)') {
            // Dash without space
            RegExp regex = RegExp(r'^-([^ >])');
            for (var match in regex.allMatches(workingText)) {
              for (int i = match.start; i < match.end; i++) {
                highlightPositions.add(i);
              }
            }
          } else if (rule.contains('സാധാ\\( \\)') || rule.contains('സാധാ( )')) {
            // സാധാ followed by space
            RegExp regex = RegExp(r'സാധാ( )');
            for (var match in regex.allMatches(workingText)) {
              // Only highlight 'സാധാ' part, not the space
              for (int i = match.start; i < match.start + 'സാധാ'.length; i++) {
                highlightPositions.add(i);
              }
            }
          } else {
            // Simple string replacement - find all occurrences
            int index = 0;
            while ((index = workingText.indexOf(rule, index)) != -1) {
              for (int i = index; i < index + rule.length; i++) {
                highlightPositions.add(i);
              }
              index += rule.length;
            }
          }
        } catch (e) {
          // If regex fails, skip highlighting for this rule
          continue;
        }
      }
      
      // Build spans based on highlight positions
      for (int i = 0; i < workingText.length; i++) {
        bool isHighlighted = highlightPositions.contains(i);
        
        // Group consecutive characters with same highlight status
        int start = i;
        while (i + 1 < workingText.length && 
               highlightPositions.contains(i + 1) == isHighlighted) {
          i++;
        }
        
        String segment = workingText.substring(start, i + 1);
        
        // Special handling for trailing spaces - make them visible
        String displaySegment = segment;
        if (isHighlighted && segment.trim().isEmpty) {
          // Replace trailing spaces with visible dots for highlighting
          displaySegment = segment.replaceAll(' ', '•');
        }
        
        spans.add(TextSpan(
          text: displaySegment,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            backgroundColor: isHighlighted 
                ? Colors.red.withValues(alpha: 0.3) 
                : null,
            fontWeight: isHighlighted ? FontWeight.bold : null,
          ),
        ));
      }
      
      return spans.isEmpty 
          ? Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'))
          : RichText(text: TextSpan(children: spans));
          
    } else {
      // For AFTER: apply the normalization and show result
      String resultText = text;
      
      // Apply each change rule to get the final result
      for (var change in changes) {
        String rule = change.rule;
        String replacement = change.replacement;
        
        try {
          if (rule == ' *\$') {
            resultText = resultText.replaceAll(RegExp(r' *$'), replacement);
          } else if (rule == '^ *') {
            resultText = resultText.replaceAll(RegExp(r'^ *'), replacement);
          } else if (rule == ',\\([^[:digit:] ]\\)') {
            resultText = resultText.replaceAllMapped(RegExp(r',([^0-9 ])'), (match) {
              return ', ${match.group(1)}';
            });
          } else if (rule == '^-\\([^ >]\\)') {
            resultText = resultText.replaceAllMapped(RegExp(r'^-([^ >])'), (match) {
              return '- ${match.group(1)}';
            });
          } else if (rule.contains('സാധാ\\( \\)') || rule.contains('സാധാ( )')) {
            resultText = resultText.replaceAllMapped(RegExp(r'സാധാ( )'), (match) {
              return 'സാദാ${match.group(1)}'; // Replace സാധാ with സാദാ, keep the space
            });
          } else {
            resultText = resultText.replaceAll(rule, replacement);
          }
        } catch (e) {
          // If regex fails, skip this replacement
          continue;
        }
      }
      
      return Text(
        resultText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic theming variables
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.95,
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header Section (fixed at top)
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: onSurfaceColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.translate,
                        color: onSurfaceColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Malayalam Text Normalization',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isCompleted 
                                ? 'Changes applied successfully'
                                : _isAnalyzed
                                    ? 'Review and select changes to apply'
                                    : 'Analyze your subtitles for improvements',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: mutedColor,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Main content area (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Initial State - Show info and start analysis
                      if (!_isAnalyzed && !_isCompleted) ...[
                        // Warning for non-Malayalam content
                        if (!_hasMalayalamContent) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No Malayalam text detected in current subtitles. This feature is specifically designed for Malayalam text normalization.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        Text(
                          'About Malayalam Text Normalization',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This feature automatically identifies and corrects common Malayalam text issues:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),

                        // Feature list
                        ...const [
                          '• Chillu character normalization',
                          '• Common spelling corrections',
                          '• ZWNJ (Zero Width Non-Joiner) cleanup',
                          '• Punctuation and spacing fixes',
                          '• Malayalam-specific text improvements',
                        ].map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )),

                        const SizedBox(height: 20),

                        // Examples section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, color: onSurfaceColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Examples',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: onSurfaceColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              _buildExampleRow(context, 'പക്ഷെ ഞാൻ വരും', 'പക്ഷേ ഞാൻ വരും'),
                              const SizedBox(height: 12),
                              _buildExampleRow(context, 'അപ്പൊൾ ഒകെ', 'അപ്പോൾ ഓക്കെ'),
                              const SizedBox(height: 12),
                              _buildExampleRow(context, 'എന്താണ് ?ശരിയാണോ', 'എന്താണ്? ശരിയാണോ'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Analyze button with loading indicator
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isAnalyzing ? null : _analyzeChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isAnalyzing ? 'Analyzing...' : 'Analyze Changes',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24), // Extra spacing for floating buttons
                      ],

                      // Analysis Results - Show preview of changes
                      if (_isAnalyzed && !_isAnalyzing && !_isCompleted) ...[
                        // Header with statistics
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.analytics_outlined, color: onSurfaceColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Analysis Complete',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: onSurfaceColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Found ${_previewResults.length} subtitle${_previewResults.length != 1 ? 's' : ''} with $_totalPotentialChanges potential improvement${_totalPotentialChanges != 1 ? 's' : ''}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: onSurfaceColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Toggle all checkbox
                              if (_previewResults.isNotEmpty)
                                Row(
                                  children: [
                                    Text(
                                      'Select All',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: onSurfaceColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Checkbox(
                                      value: _selectedChangesCount == _previewResults.length,
                                      onChanged: (value) => _toggleAllChanges(value ?? false),
                                      activeColor: primaryColor,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Preview list with scrollbar
                        Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _scrollController,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _previewResults.length,
                            cacheExtent: 1000, // Cache more items for smoother scrolling
                            addAutomaticKeepAlives: false, // Don't keep all items alive
                            addRepaintBoundaries: true, // Optimize repainting
                            itemBuilder: (context, index) {
                              final preview = _previewResults[index];
                              final isSelected = _selectedChanges[index] ?? false;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? primaryColor.withValues(alpha: 0.05)
                                      : surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected 
                                        ? primaryColor.withValues(alpha: 0.3)
                                        : borderColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with checkbox and line info
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedChanges[index] = value ?? false;
                                            });
                                          },
                                          activeColor: primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Line ${preview.lineIndex + 1}',
                                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                '${preview.result.changes.length} improvement${preview.result.changes.length != 1 ? 's' : ''} available',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: mutedColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Before/After preview - now in column layout
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Before section
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'BEFORE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.red.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: _buildHighlightedText(
                                            context,
                                            preview.originalText,
                                            preview.result.changes,
                                            isOriginal: true,
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // After section
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'AFTER',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.green.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: _buildHighlightedText(
                                            context,
                                            preview.originalText,
                                            preview.result.changes,
                                            isOriginal: false,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Changes details - show ALL changes
                                    if (preview.result.changes.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        'Improvements (${preview.result.changes.length}):',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: mutedColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...preview.result.changes.map((change) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '• ${_getChangeDescription(change)}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: mutedColor,
                                            height: 1.3,
                                          ),
                                        ),
                                      )),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 100), // Extra space for floating buttons
                      ],

                      // Completion state
                      if (_isCompleted) ...[
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 48,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Normalization Complete!',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Selected normalization changes have been applied to your subtitles.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Close',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Floating action buttons (fixed at bottom)
              if (_isAnalyzed && !_isCompleted)
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(
                      top: BorderSide(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: onSurfaceColor,
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.close,
                                  size: 20,
                                  color: onSurfaceColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: onSurfaceColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _selectedChangesCount > 0 ? _applySelectedChanges : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isApplying
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_fix_high, size: 20),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Apply ($_selectedChangesCount)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build example rows showing before/after text
  Widget _buildExampleRow(BuildContext context, String before, String after) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        // Before text
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.red.withValues(alpha: 0.2) 
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDarkMode 
                    ? Colors.red.withValues(alpha: 0.5) 
                    : Colors.red.withValues(alpha: 0.3)
              ),
            ),
            child: Text(
              before,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: isDarkMode ? Colors.red[100] : Colors.red[900],
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
        
        // Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward,
            size: 16,
            color: isDarkMode ? Colors.green[300] : Colors.green[700],
          ),
        ),
        
        // After text
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.green.withValues(alpha: 0.2) 
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDarkMode 
                    ? Colors.green.withValues(alpha: 0.5) 
                    : Colors.green.withValues(alpha: 0.3)
              ),
            ),
            child: Text(
              after,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: isDarkMode ? Colors.green[100] : Colors.green[900],
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ],
    );
  }
}

// Helper class to store normalization preview for each subtitle
class SubtitleNormalizationPreview {
  final int lineIndex;
  final SubtitleLine subtitleLine;
  final String originalText;
  final NormalizationResult result;

  SubtitleNormalizationPreview({
    required this.lineIndex,
    required this.subtitleLine,
    required this.originalText,
    required this.result,
  });
}
