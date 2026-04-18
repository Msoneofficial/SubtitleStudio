import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/utils/time_parser.dart';
import 'package:subtitle_studio/utils/responsive_layout.dart';
import 'package:subtitle_studio/widgets/comment_dialog.dart';

class _HoverableButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  const _HoverableButton({
    required this.onTap,
    required this.icon,
    required this.color,
  });

  @override
  _HoverableButtonState createState() => _HoverableButtonState();
}

class _HoverableButtonState extends State<_HoverableButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered ? widget.color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class MarkedLinesSheet extends StatefulWidget {
  final List<SubtitleLine> markedLines;
  final List<SubtitleLine>? allLinesWithComments; // All lines that have comments (marked or unmarked)
  final Function(int) onLineSelected;
  final Function(int, String?)? onCommentUpdated;
  final Function(int)? onLineUnmarked; // Callback for unmarking and deleting comments
  final Function(int, bool)? onResolvedUpdated; // Callback for updating resolved status
  final Function(int, String)? onTextEdited; // Callback for editing subtitle text
  final int? initialHighlightLineIndex; // Database index (1-based) to highlight on open

  const MarkedLinesSheet({
    super.key,
    required this.markedLines,
    this.allLinesWithComments,
    required this.onLineSelected,
    this.onCommentUpdated,
    this.onLineUnmarked,
    this.onResolvedUpdated,
    this.onTextEdited,
    this.initialHighlightLineIndex,
  });

  @override
  MarkedLinesSheetState createState() => MarkedLinesSheetState();
}

class MarkedLinesSheetState extends State<MarkedLinesSheet> {
  late List<SubtitleLine> _currentMarkedLines;
  bool _showAllComments = false; // Toggle to show all lines with comments
  String _resolvedFilter = 'all'; // Filter: 'all', 'resolved', 'unresolved'
  int? _editingLineIndex; // Track which line is being edited
  final Map<int, TextEditingController> _textControllers = {}; // Controllers for each line
  final Map<int, FocusNode> _focusNodes = {}; // Focus nodes for each line
  int _highlightedIndex = 0; // Track which line is highlighted for keyboard navigation
  final FocusNode _listFocusNode = FocusNode(); // Focus node for the list itself
  final ScrollController _scrollController = ScrollController(); // For scrolling to highlighted item
  final List<GlobalKey> _cardKeys = []; // Keys for each card to enable scrolling

  @override
  void initState() {
    super.initState();
    _currentMarkedLines = List.from(widget.markedLines);
    
    // Load preference and then trigger scroll if needed
    _loadShowAllCommentsPreference().then((_) {
      // If initial highlight index is provided, scroll to it after preference is loaded
      if (widget.initialHighlightLineIndex != null && mounted) {
        print('DEBUG: initState - will scroll to index ${widget.initialHighlightLineIndex}');
        // Wait for the widget to build at least once before trying to scroll
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('DEBUG: initState postFrameCallback - now triggering scroll after 500ms delay');
          // Increase delay to 500ms to ensure DraggableScrollableSheet finishes building
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              print('DEBUG: About to call _scrollToLineByDatabaseIndex');
              _scrollToLineByDatabaseIndex(widget.initialHighlightLineIndex!);
            }
          });
        });
      }
    });
    
    // Request focus for keyboard navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _listFocusNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // Dispose all controllers and focus nodes
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _listFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadShowAllCommentsPreference() async {
    final showAllComments = await PreferencesModel.getShowAllComments();
    if (mounted) {
      setState(() {
        _showAllComments = showAllComments;
      });
    }
  }

  /// Get count of resolved comments from all available lines
  int get _resolvedCount {
    List<SubtitleLine> allLines;
    if (_showAllComments && widget.allLinesWithComments != null) {
      final Set<int> seenIndices = {};
      final List<SubtitleLine> mergedLines = [];
      for (final line in _currentMarkedLines) {
        mergedLines.add(line);
        seenIndices.add(line.index);
      }
      for (final line in widget.allLinesWithComments!) {
        if (!seenIndices.contains(line.index)) {
          mergedLines.add(line);
        }
      }
      allLines = mergedLines;
    } else {
      allLines = _currentMarkedLines;
    }
    return allLines.where((line) => line.resolved).length;
  }

  /// Get total count of all available lines
  int get _totalCount {
    if (_showAllComments && widget.allLinesWithComments != null) {
      final Set<int> seenIndices = {};
      int count = 0;
      for (final line in _currentMarkedLines) {
        seenIndices.add(line.index);
        count++;
      }
      for (final line in widget.allLinesWithComments!) {
        if (!seenIndices.contains(line.index)) {
          count++;
        }
      }
      return count;
    }
    return _currentMarkedLines.length;
  }

  List<SubtitleLine> get _displayedLines {
    List<SubtitleLine> lines;
    
    if (_showAllComments && widget.allLinesWithComments != null) {
      // Merge marked lines and lines with comments
      final Set<int> seenIndices = {};
      final List<SubtitleLine> mergedLines = [];
      
      // Add all marked lines first
      for (final line in _currentMarkedLines) {
        mergedLines.add(line);
        seenIndices.add(line.index);
      }
      
      // Add lines with comments that aren't already marked
      for (final line in widget.allLinesWithComments!) {
        if (!seenIndices.contains(line.index)) {
          mergedLines.add(line);
          seenIndices.add(line.index);
        }
      }
      
      // Sort by index to maintain proper order
      mergedLines.sort((a, b) => a.index.compareTo(b.index));
      
      lines = mergedLines;
    } else {
      lines = _currentMarkedLines;
    }
    
    // Apply resolved filter
    if (_resolvedFilter == 'resolved') {
      return lines.where((line) => line.resolved).toList();
    } else if (_resolvedFilter == 'unresolved') {
      return lines.where((line) => !line.resolved).toList();
    }
    
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          _moveHighlight(1);
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          _moveHighlight(-1);
        },
        const SingleActivator(LogicalKeyboardKey.enter): () {
          _openCommentDialogForHighlighted();
        },
      },
      child: Focus(
        focusNode: _listFocusNode,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Title row
                Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showAllComments ? 'Lines with Comments' : 'Marked Lines',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_resolvedCount resolved of $_totalCount total',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showAllComments ? Icons.comment : Icons.bookmark_added,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_displayedLines.length}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                
                // Checkbox rows
                if (widget.allLinesWithComments != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _showAllComments,
                          onChanged: (value) async {
                            final newValue = value ?? false;
                            setState(() {
                              _showAllComments = newValue;
                            });
                            // Save the preference
                            await PreferencesModel.setShowAllComments(newValue);
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Show all lines with comments (including unmarked)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Resolved filter row
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Show:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Radio buttons for filter
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip(
                            context,
                            label: 'All',
                            value: 'all',
                            icon: Icons.list,
                          ),
                          _buildFilterChip(
                            context,
                            label: 'Resolved',
                            value: 'resolved',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          _buildFilterChip(
                            context,
                            label: 'Unresolved',
                            value: 'unresolved',
                            icon: Icons.radio_button_unchecked,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: _displayedLines.isEmpty 
                ? _buildEmptyState(context) 
                : _buildMarkedLinesList(context),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final isSelected = _resolvedFilter == value;
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _resolvedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? chipColor.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? chipColor
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected 
                  ? chipColor
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                    ? chipColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showAllComments ? Icons.comment_outlined : Icons.bookmark_border,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            _showAllComments ? 'No lines with comments' : 'No marked lines',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _showAllComments 
                ? 'Add comments to subtitle lines to see them here'
                : 'Long press on a subtitle line and select "Mark Line" to bookmark it',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMarkedLinesList(BuildContext context) {
    print('DEBUG: _buildMarkedLinesList called, _displayedLines.length: ${_displayedLines.length}');
    
    // Ensure we have enough keys for all items
    // CRITICAL: Only add NEW keys if we don't have enough, don't recreate existing ones
    final keysNeeded = _displayedLines.length;
    if (_cardKeys.length < keysNeeded) {
      final keysToAdd = keysNeeded - _cardKeys.length;
      for (int i = 0; i < keysToAdd; i++) {
        _cardKeys.add(GlobalKey());
        print('DEBUG: Added NEW GlobalKey, _cardKeys.length now: ${_cardKeys.length}');
      }
    }
    // Remove excess keys if list shortened
    else if (_cardKeys.length > keysNeeded) {
      print('DEBUG: Removing ${_cardKeys.length - keysNeeded} excess keys');
      _cardKeys.removeRange(keysNeeded, _cardKeys.length);
    }
    
    print('DEBUG: Final _cardKeys.length: ${_cardKeys.length}');
    print('DEBUG: Keys hash codes: ${_cardKeys.map((k) => k.hashCode).toList()}');
    
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _displayedLines.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final line = _displayedLines[index];
        final formattedStart = _formatDurationToThreeDigits(parseTimeString(line.startTime));
        final formattedEnd = _formatDurationToThreeDigits(parseTimeString(line.endTime));
        final hasEditedText = line.edited?.isNotEmpty == true;
        final isHighlighted = index == _highlightedIndex;
        
        return GestureDetector(
          key: _cardKeys[index], // Assign key to enable scrolling
          onTap: () {
            setState(() {
              _highlightedIndex = index;
            });
          },
          onLongPress: () {
            // Let the callback handle modal closing
            widget.onLineSelected(line.index - 1); // Convert to 0-based index
          },
          onDoubleTap: () {
            // Let the callback handle modal closing
            widget.onLineSelected(line.index - 1); // Convert to 0-based index
          },
          child: Card(
            elevation: isHighlighted ? 4 : 2,
            color: isHighlighted 
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isHighlighted 
                  ? BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with line number, bookmark icon, and timestamp
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: line.marked 
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${line.index}',
                          style: TextStyle(
                            color: line.marked ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        line.marked ? Icons.bookmark_added : Icons.comment,
                        color: line.marked ? Colors.red : Colors.blue,
                        size: 18,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$formattedStart → $formattedEnd',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle text - inline editable
                  _buildEditableSubtitleText(context, line, hasEditedText),
                  
                  // Comment section
                  if (line.comment?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: line.resolved 
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: line.resolved 
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                line.resolved ? Icons.check_circle : Icons.comment,
                                color: line.resolved ? Colors.green : Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                line.resolved ? 'Resolved Comment' : 'Comment',
                                style: TextStyle(
                                  color: line.resolved ? Colors.green : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              if (widget.onCommentUpdated != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildHoverableButton(
                                      onTap: () => _showCommentDialog(context, line),
                                      icon: Icons.edit,
                                      color: line.resolved ? Colors.green : Colors.blue,
                                    ),
                                    const SizedBox(width: 16),
                                    _buildHoverableButton(
                                      onTap: () => _showDeleteConfirmation(context, line),
                                      icon: Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            line.comment!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: line.resolved ? Colors.green.shade700 : Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Resolved checkbox
                          Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: Checkbox(
                                  value: line.resolved,
                                  onChanged: (value) => _toggleResolved(line, value ?? false),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _toggleResolved(line, !line.resolved),
                                child: Text(
                                  'Resolved',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: line.resolved ? Colors.green.shade600 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else if (widget.onCommentUpdated != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showCommentDialog(context, line),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_comment_outlined,
                              color: Colors.grey.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add comment',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditableSubtitleText(BuildContext context, SubtitleLine line, bool hasEditedText) {
    final isEditing = _editingLineIndex == line.index;
    
    // Get or create text controller for this line
    if (!_textControllers.containsKey(line.index)) {
      final textToEdit = hasEditedText ? line.edited! : line.original;
      _textControllers[line.index] = TextEditingController(text: textToEdit);
      _focusNodes[line.index] = FocusNode();
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEditing 
              ? Colors.blue 
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          width: isEditing ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show original text if there's an edited version
          if (hasEditedText) ...[
            Row(
              children: [
                Icon(
                  Icons.text_fields,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Original',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                line.original,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Editable text section
          Row(
            children: [
              Icon(
                hasEditedText ? Icons.edit : Icons.text_fields,
                size: 14,
                color: hasEditedText ? Colors.blue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                hasEditedText ? 'Edited' : 'Text',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: hasEditedText ? Colors.blue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Copy button for current text (edited or original)
              if (!isEditing)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final textToCopy = hasEditedText ? line.edited! : line.original;
                      await Clipboard.setData(ClipboardData(text: textToCopy));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text('Text copied'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy,
                            color: Colors.green,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Copy',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Edit/Save/Cancel buttons
              if (widget.onTextEdited != null) ...[
                if (isEditing) ...[
                  // Cancel button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          // Reset text to original
                          final textToReset = hasEditedText ? line.edited! : line.original;
                          _textControllers[line.index]!.text = textToReset;
                          _editingLineIndex = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Save button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _saveEditedText(line),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Edit button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _editingLineIndex = line.index;
                        });
                        _focusNodes[line.index]?.requestFocus();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              color: Colors.blue,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasEditedText 
                  ? Colors.blue.withValues(alpha: 0.05)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: isEditing
                ? CallbackShortcuts(
                    bindings: <ShortcutActivator, VoidCallback>{
                      const SingleActivator(LogicalKeyboardKey.enter): () {
                        // Enter only: Save edited text
                        _saveEditedText(line);
                      },
                    },
                    child: TextField(
                      controller: _textControllers[line.index],
                      focusNode: _focusNodes[line.index],
                      maxLines: null,
                      minLines: 2,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: ResponsiveLayout.isDesktopPlatform() 
                            ? 'Enter subtitle text... (Enter to save, Shift+Enter for new line)'
                            : 'Enter subtitle text...',
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                      onSubmitted: (value) {
                        // Handle Enter key press on mobile/non-desktop
                        _saveEditedText(line);
                      },
                    ),
                  )
                : Text(
                    hasEditedText ? line.edited! : line.original,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _saveEditedText(SubtitleLine line) async {
    if (widget.onTextEdited == null) return;
    
    final newText = _textControllers[line.index]!.text.trim();
    if (newText.isEmpty) return;
    
    // Call the callback to save
    await widget.onTextEdited!(line.index - 1, newText);
    
    // Update local state
    setState(() {
      _editingLineIndex = null;
      
      // Update in marked lines list
      final markedLineIndex = _currentMarkedLines.indexWhere((l) => l.index == line.index);
      if (markedLineIndex >= 0) {
        _currentMarkedLines[markedLineIndex].edited = newText;
      }
      
      // Update in all comments list if it exists
      if (widget.allLinesWithComments != null) {
        final allLineIndex = widget.allLinesWithComments!.indexWhere((l) => l.index == line.index);
        if (allLineIndex >= 0) {
          widget.allLinesWithComments![allLineIndex].edited = newText;
        }
      }
    });
  }

  void _moveHighlight(int direction) {
    if (_displayedLines.isEmpty) return;
    
    setState(() {
      _highlightedIndex = (_highlightedIndex + direction).clamp(0, _displayedLines.length - 1);
    });
    
    // Scroll to the highlighted item after the widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToHighlightedItem();
    });
  }

  void _scrollToHighlightedItem() {
    print('DEBUG: _scrollToHighlightedItem called');
    print('DEBUG: _displayedLines.isEmpty: ${_displayedLines.isEmpty}');
    print('DEBUG: _scrollController.hasClients: ${_scrollController.hasClients}');
    print('DEBUG: _highlightedIndex: $_highlightedIndex, _cardKeys.length: ${_cardKeys.length}');
    
    if (_displayedLines.isEmpty || !_scrollController.hasClients) return;
    if (_highlightedIndex < 0 || _highlightedIndex >= _cardKeys.length) return;
    
    // Get the key for the highlighted card
    final cardKey = _cardKeys[_highlightedIndex];
    final currentContext = cardKey.currentContext;
    
    print('DEBUG: cardKey.currentContext is ${currentContext != null ? 'NOT NULL' : 'NULL'}');
    
    if (currentContext != null) {
      print('DEBUG: About to call Scrollable.ensureVisible');
      // Use Scrollable.ensureVisible to center the highlighted item
      // This automatically handles variable-height items
      Scrollable.ensureVisible(
        currentContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: 0.5, // 0.5 centers the item in the viewport
      );
    }
  }

  /// Scroll to and highlight a specific line by its database index (1-based)
  void _scrollToLineByDatabaseIndex(int databaseIndex) {
    // Find the line in the displayed lines
    final displayedIndex = _displayedLines.indexWhere((line) => line.index == databaseIndex);
    
    if (displayedIndex != -1) {
      setState(() {
        _highlightedIndex = displayedIndex;
      });
      
      // Use direct offset calculation like EditScreen does
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlightedItemDirect();
      });
    }
  }

  /// Scroll to highlighted item using direct offset calculation (more reliable)
  void _scrollToHighlightedItemDirect() {
    if (_displayedLines.isEmpty || !_scrollController.hasClients) {
      return;
    }
    
    if (_highlightedIndex < 0 || _highlightedIndex >= _displayedLines.length) {
      return;
    }
    
    // Estimate average item height (card with comment can be 250-350px)
    const double estimatedItemHeight = 300.0;
    const double separatorHeight = 12.0;
    const double itemTotalHeight = estimatedItemHeight + separatorHeight;
    
    // Calculate offset to the item
    double offset = _highlightedIndex * itemTotalHeight;
    
    // Account for padding at top
    const double topPadding = 16.0;
    offset += topPadding;
    
    // Calculate the middle of the viewport and center the item
    final viewportHeight = _scrollController.position.viewportDimension;
    offset = offset - (viewportHeight / 2) + (estimatedItemHeight / 2);
    
    // Clamp to valid scroll bounds
    offset = offset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    
    // Animate to the calculated position
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _openCommentDialogForHighlighted() {
    if (_displayedLines.isEmpty || _highlightedIndex >= _displayedLines.length) return;
    
    final line = _displayedLines[_highlightedIndex];
    _showCommentDialog(context, line);
  }

  Widget _buildHoverableButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return _HoverableButton(
      onTap: onTap,
      icon: icon,
      color: color,
    );
  }

  void _showCommentDialog(BuildContext context, SubtitleLine line) {
    CommentDialog.show(
      context,
      existingComment: line.comment,
      originalText: line.original,
      editedText: line.edited,
      subtitleIndex: line.index,
      onTextEdited: widget.onTextEdited != null ? (newText) async {
        // Call the callback to update the edited text
        await widget.onTextEdited!(line.index - 1, newText);
        // Update local state
        setState(() {
          // Update in marked lines list
          final markedLineIndex = _currentMarkedLines.indexWhere((l) => l.index == line.index);
          if (markedLineIndex >= 0) {
            _currentMarkedLines[markedLineIndex].edited = newText;
          }
          
          // Update in all comments list if it exists
          if (widget.allLinesWithComments != null) {
            final allLineIndex = widget.allLinesWithComments!.indexWhere((l) => l.index == line.index);
            if (allLineIndex >= 0) {
              widget.allLinesWithComments![allLineIndex].edited = newText;
            }
          }
        });
      } : null,
      onCommentSaved: (comment) async {
        if (widget.onCommentUpdated != null) {
          await widget.onCommentUpdated!(line.index - 1, comment); // Fix: Convert to 0-based index
          // Update the local state to reflect the change immediately
          setState(() {
            // Update in marked lines list
            final markedLineIndex = _currentMarkedLines.indexWhere((l) => l.index == line.index);
            if (markedLineIndex >= 0) {
              _currentMarkedLines[markedLineIndex].comment = comment;
            }
            
            // Update in all comments list if it exists
            if (widget.allLinesWithComments != null) {
              final allLineIndex = widget.allLinesWithComments!.indexWhere((l) => l.index == line.index);
              if (allLineIndex >= 0) {
                widget.allLinesWithComments![allLineIndex].comment = comment;
              }
            }
          });
        }
      },
      onCommentDeleted: line.comment?.isNotEmpty == true ? () async {
        if (widget.onCommentUpdated != null) {
          await widget.onCommentUpdated!(line.index - 1, null); // Fix: Convert to 0-based index
          // Update the local state to reflect the change immediately
          setState(() {
            // Update in marked lines list
            final markedLineIndex = _currentMarkedLines.indexWhere((l) => l.index == line.index);
            if (markedLineIndex >= 0) {
              _currentMarkedLines[markedLineIndex].comment = null;
            }
            
            // Update in all comments list if it exists
            if (widget.allLinesWithComments != null) {
              final allLineIndex = widget.allLinesWithComments!.indexWhere((l) => l.index == line.index);
              if (allLineIndex >= 0) {
                widget.allLinesWithComments![allLineIndex].comment = null;
              }
            }
          });
        }
      } : null,
    );
  }

  void _toggleResolved(SubtitleLine line, bool resolved) async {
    if (widget.onResolvedUpdated != null) {
      // Update resolved status in database using the callback
      await widget.onResolvedUpdated!(line.index - 1, resolved);
    }
    
    // Update local state
    setState(() {
      line.resolved = resolved;
      
      // Update in marked lines list
      final markedLineIndex = _currentMarkedLines.indexWhere((l) => l.index == line.index);
      if (markedLineIndex >= 0) {
        _currentMarkedLines[markedLineIndex].resolved = resolved;
      }
      
      // Update in all comments list if it exists
      if (widget.allLinesWithComments != null) {
        final allLineIndex = widget.allLinesWithComments!.indexWhere((l) => l.index == line.index);
        if (allLineIndex >= 0) {
          widget.allLinesWithComments![allLineIndex].resolved = resolved;
        }
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, SubtitleLine line) {
    void handleKeyEvent(KeyEvent event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          Navigator.of(context).pop();
          _deleteComment(line);
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: handleKeyEvent,
          child: AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text('Are you sure you want to unmark this line and delete its comment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteComment(line);
                },
                child: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteComment(SubtitleLine line) async {
    if (widget.onLineUnmarked != null) {
      // Call the callback to unmark and delete comment
      await widget.onLineUnmarked!(line.index - 1);
      
      // Update local state by removing the line from lists
      setState(() {
        _currentMarkedLines.removeWhere((l) => l.index == line.index);
        if (widget.allLinesWithComments != null) {
          widget.allLinesWithComments!.removeWhere((l) => l.index == line.index);
        }
      });
    }
  }
  
  // Helper method to format Duration with only 3 millisecond digits
  String _formatDurationToThreeDigits(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);
    
    return '${hours.toString().padLeft(1, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${milliseconds.toString().padLeft(3, '0')}';
  }
}
