import 'package:flutter/material.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchReplaceSheet extends StatefulWidget {
  final List<SubtitleLine> subtitleLines;
  final int subtitleId;
  final bool isReplaceMode;
  final Function() onRefresh;
  final Function(int) onLineSelected;

  const SearchReplaceSheet({
    super.key,
    required this.subtitleLines,
    required this.subtitleId,
    required this.isReplaceMode,
    required this.onRefresh,
    required this.onLineSelected,
  });

  @override
  State<SearchReplaceSheet> createState() => _SearchReplaceSheetState();
}

class _SearchReplaceSheetState extends State<SearchReplaceSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _searching = false;
  bool _selectionMode = false;
  Set<int> _selectedIndices = {};
  bool _caseSensitive = false;
  bool _wholeWord = false;

  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _searching = true;
      _searchResults = [];
    });

    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) {
      setState(() {
        _searching = false;
      });
      return;
    }

    for (int i = 0; i < widget.subtitleLines.length; i++) {
      final line = widget.subtitleLines[i];
      final originalText = line.edited ?? line.original;
      final text = _caseSensitive ? originalText : originalText.toLowerCase();
      final term = _caseSensitive ? searchTerm : searchTerm.toLowerCase();

      if (_wholeWord) {
        final pattern = '\\b${RegExp.escape(searchTerm)}\\b';
        final regExp = RegExp(pattern, caseSensitive: _caseSensitive);

        final matches = regExp.allMatches(text);

        for (final match in matches) {
          _searchResults.add(
            SearchResult(
              lineIndex: i,
              line: line,
              matchStart: match.start,
              matchEnd: match.end,
              originalText: originalText,
            ),
          );
        }
      } else {
        int startIndex = 0;
        int index;

        while ((index = text.indexOf(term, startIndex)) != -1) {
          _searchResults.add(
            SearchResult(
              lineIndex: i,
              line: line,
              matchStart: index,
              matchEnd: index + term.length,
              originalText: originalText,
            ),
          );

          startIndex = index + term.length;
        }
      }
    }

    setState(() {
      _searching = false;
    });
  }

  Future<void> _replaceAll() async {
    final searchTerm = _searchController.text.trim();
    final replaceTerm = _replaceController.text;

    if (searchTerm.isEmpty) return;

    final theme = Theme.of(context);
    final highlightColor = theme.brightness == Brightness.dark
        ? Color(0xFFE9C46A)  // Yellow for dark mode
        : Color(0xFF2A9D8F); // Teal for light mode

    final shouldReplace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Replace All'),
        content: Text('Replace all occurrences of "$searchTerm" with "$replaceTerm"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.black87,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Replace All',
              style: TextStyle(
                color: highlightColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldReplace) return;

    final Map<int, SubtitleLine> updatedLinesMap = {};

    for (final result in _searchResults) {
      final oldText = result.line.edited ?? result.line.original;

      RegExp pattern;
      if (_wholeWord) {
        pattern = RegExp('\\b${RegExp.escape(searchTerm)}\\b', caseSensitive: _caseSensitive);
      } else {
        pattern = RegExp(RegExp.escape(searchTerm), caseSensitive: _caseSensitive);
      }

      final newText = oldText.replaceAll(pattern, replaceTerm);

      if (!updatedLinesMap.containsKey(result.line.index)) {
        final updatedLine = SubtitleLine()
          ..index = result.line.index
          ..startTime = result.line.startTime
          ..endTime = result.line.endTime
          ..original = result.line.original
          ..edited = newText;

        updatedLinesMap[result.line.index] = updatedLine;
      }
    }

    final updatedLines = updatedLinesMap.values.toList();

    final success = await updateMultipleSubtitleLines(
      widget.subtitleId,
      updatedLines,
    );

    if (success) {
      widget.onRefresh();
      Navigator.pop(context);
      SnackbarHelper.showSuccess(
        context,
        'Replaced ${_searchResults.length} occurrences in ${updatedLines.length} lines',
      );
    } else {
      SnackbarHelper.showError(
        context,
        'Failed to replace text',
      );
    }
  }

  void _startSelectionMode() {
    setState(() {
      _selectionMode = true;
      _selectedIndices = {};
    });
  }

  void _toggleSelection(int resultIndex) {
    setState(() {
      if (_selectedIndices.contains(resultIndex)) {
        _selectedIndices.remove(resultIndex);
      } else {
        _selectedIndices.add(resultIndex);
      }
    });
  }

  Future<void> _replaceSelected() async {
    if (_selectedIndices.isEmpty) return;
    
    final searchTerm = _searchController.text.trim();
    final replaceTerm = _replaceController.text;

    final theme = Theme.of(context);
    final highlightColor = theme.brightness == Brightness.dark
        ? Color(0xFFE9C46A)  // Yellow for dark mode
        : Color(0xFF2A9D8F); // Teal for light mode

    final shouldReplace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Replace Selected'),
        content: Text('Replace ${_selectedIndices.length} selected occurrences of "$searchTerm" with "$replaceTerm"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.black87,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Replace',
              style: TextStyle(
                color: highlightColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldReplace) return;

    final Map<int, SubtitleLine> updatedLinesMap = {};

    for (final resultIndex in _selectedIndices) {
      final result = _searchResults[resultIndex];
      final oldText = result.line.edited ?? result.line.original;

      final beforeText = oldText.substring(0, result.matchStart);
      final afterText = oldText.substring(result.matchEnd);

      final newText = beforeText + replaceTerm + afterText;

      if (updatedLinesMap.containsKey(result.line.index)) {
        updatedLinesMap[result.line.index] = SubtitleLine()
          ..index = result.line.index
          ..startTime = result.line.startTime
          ..endTime = result.line.endTime
          ..original = result.line.original
          ..edited = newText;
      } else {
        updatedLinesMap[result.line.index] = SubtitleLine()
          ..index = result.line.index
          ..startTime = result.line.startTime
          ..endTime = result.line.endTime
          ..original = result.line.original
          ..edited = newText;
      }
    }

    final updatedLines = updatedLinesMap.values.toList();

    final success = await updateMultipleSubtitleLines(
      widget.subtitleId,
      updatedLines,
    );

    if (success) {
      widget.onRefresh();
      setState(() {
        _selectionMode = false;
        _selectedIndices = {};
      });
      SnackbarHelper.showSuccess(
        context,
        'Replaced ${_selectedIndices.length} occurrences in ${updatedLines.length} lines',
      );

      _performSearch();
    } else {
      SnackbarHelper.showError(
        context,
        'Failed to replace text',
      );
    }
  }

  // Helper method to safely run search when options change
  void _runSearchWithOptions() {
    if (_searchController.text.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic color variables for adaptive theming
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    // Legacy highlight colors for search functionality
    final highlightColor = isDark
        ? Color(0xFFE9C46A)
        : Color(0xFF2A9D8F);

    final selectedCardColor = isDark
        ? Color(0xFF2A9D8F).withValues(alpha:0.3)
        : Color(0xFF2A9D8F).withValues(alpha:0.2);

    final matchBackgroundColor = isDark
        ? Color(0xFF4CAF50)  // Green for dark mode - changed color
        : Color(0xFF2196F3); // Blue for light mode - changed color

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // Top Section - Fixed height content with status bar safe area
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.find_replace,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Text(
                                'Find & Replace',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Search and replace text across subtitle lines',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            foregroundColor: onSurfaceColor,
                            padding: const EdgeInsets.all(8),
                          ),
                          icon: Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Search Input Section
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Find text',
                        prefixIcon: Icon(
                          Icons.search,
                          color: primaryColor,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        labelStyle: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                        ),
                      ),
                      onSubmitted: (_) => _performSearch(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Replace Input Section
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _replaceController,
                      decoration: InputDecoration(
                        labelText: 'Replace with',
                        prefixIcon: Icon(
                          Icons.find_replace,
                          color: primaryColor,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        labelStyle: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Options Section
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Transform.scale(
                                scale: 0.8,
                                child: Checkbox(
                                  value: _caseSensitive,
                                  onChanged: (value) {
                                    setState(() {
                                      _caseSensitive = value ?? false;
                                    });
                                    _runSearchWithOptions();
                                  },
                                  activeColor: primaryColor,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Case sensitive',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Transform.scale(
                                scale: 0.8,
                                child: Checkbox(
                                  value: _wholeWord,
                                  onChanged: (value) {
                                    setState(() {
                                      _wholeWord = value ?? false;
                                    });
                                    _runSearchWithOptions();
                                  },
                                  activeColor: primaryColor,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Whole word',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Search Button
                  Container(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: _performSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Search',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Action Buttons Section
                  if (!_selectionMode)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: _searchResults.isNotEmpty ? _startSelectionMode : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _searchResults.isNotEmpty ? Colors.orange : onSurfaceColor.withValues(alpha: 0.3),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.checklist, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Select',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: _searchResults.isNotEmpty ? _replaceAll : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _searchResults.isNotEmpty ? Colors.green : onSurfaceColor.withValues(alpha: 0.3),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_fix_high, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Replace All',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
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
                  if (_selectionMode)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 36,
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectionMode = false;
                                  _selectedIndices = {};
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: onSurfaceColor,
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: _selectedIndices.isNotEmpty ? _replaceSelected : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedIndices.isNotEmpty ? Colors.green : onSurfaceColor.withValues(alpha: 0.3),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.done_all, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Replace (${_selectedIndices.length})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
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
                ],
              ),
            ),
            
            // Results List - Expandable section
            Expanded(
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      
                      // Results Display Section
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: primaryColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Found ${_searchResults.length} match${_searchResults.length != 1 ? 'es' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: onSurfaceColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Results Content
                      Expanded(
                        child: _searching
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                  ),
                                ),
                              )
                            : _searchResults.isEmpty && _searchController.text.isNotEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.search_off,
                                            size: 48,
                                            color: mutedColor,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No results found',
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: mutedColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : _searchResults.isNotEmpty
                                    ? ListView.builder(
                                        itemCount: _searchResults.length,
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.only(bottom: 24),
                                        itemBuilder: (context, index) {
                                          final result = _searchResults[index];
                                          final text = result.originalText;
                                          final beforeMatch = text.substring(0, result.matchStart);
                                          final matchText = text.substring(
                                            result.matchStart,
                                            result.matchEnd,
                                          );
                                          final afterMatch = text.substring(result.matchEnd);
                
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: _selectionMode
                                                    ? () => _toggleSelection(index)
                                                    : () => widget.onLineSelected(result.lineIndex),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: _selectionMode && _selectedIndices.contains(index)
                                                        ? selectedCardColor
                                                        : (isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: _selectionMode && _selectedIndices.contains(index)
                                                          ? highlightColor
                                                          : borderColor,
                                                      width: _selectionMode && _selectedIndices.contains(index) ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          if (_selectionMode)
                                                            Padding(
                                                              padding: const EdgeInsets.only(right: 8),
                                                              child: Icon(
                                                                _selectedIndices.contains(index)
                                                                    ? Icons.check_circle
                                                                    : Icons.circle_outlined,
                                                                color: _selectedIndices.contains(index)
                                                                    ? highlightColor
                                                                    : onSurfaceColor.withValues(alpha: 0.6),
                                                                size: 20,
                                                              ),
                                                            ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: primaryColor,
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: Text(
                                                              'Line ${result.line.index}',
                                                              style: GoogleFonts.spaceMono(
                                                                textStyle: const TextStyle(
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.white,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            result.line.startTime,
                                                            style: GoogleFonts.spaceMono(
                                                              textStyle: TextStyle(
                                                                color: mutedColor,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      RichText(
                                                        text: TextSpan(
                                                          style: Theme.of(context).textTheme.bodyMedium,
                                                          children: [
                                                            TextSpan(text: beforeMatch),
                                                            TextSpan(
                                                              text: matchText,
                                                              style: TextStyle(
                                                                backgroundColor: matchBackgroundColor,
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            TextSpan(text: afterMatch),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResult {
  final int lineIndex;
  final SubtitleLine line;
  final int matchStart;
  final int matchEnd;
  final String originalText;

  SearchResult({
    required this.lineIndex,
    required this.line,
    required this.matchStart,
    required this.matchEnd,
    required this.originalText,
  });
}
