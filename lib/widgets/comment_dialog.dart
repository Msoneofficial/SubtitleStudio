import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subtitle_studio/utils/responsive_layout.dart';
import 'package:subtitle_studio/utils/unicode_text_input_formatter.dart';

/// Bottom modal sheet for adding or editing comments for marked subtitle lines
/// Following the Sheet Design Reference guidelines for consistent UI
class CommentDialog extends StatefulWidget {
  final String? existingComment;
  final Function(String) onCommentSaved;
  final VoidCallback? onCommentDeleted;
  final VoidCallback? onCancelled; // New callback for cancel action in overlay mode
  final bool isOverlayMode; // Flag to indicate if used in overlay mode (no Navigator)
  final String? originalText; // Original subtitle text to display
  final String? editedText; // Edited subtitle text to display
  final int? subtitleIndex; // Subtitle line index for display
  final Function(String)? onTextEdited; // Callback for when subtitle text is edited

  const CommentDialog({
    super.key,
    this.existingComment,
    required this.onCommentSaved,
    this.onCommentDeleted,
    this.onCancelled,
    this.isOverlayMode = false,
    this.originalText,
    this.editedText,
    this.subtitleIndex,
    this.onTextEdited,
  });

  @override
  CommentDialogState createState() => CommentDialogState();

  /// Static method to show the comment dialog as a bottom modal sheet
  static Future<void> show(
    BuildContext context, {
    String? existingComment,
    required Function(String) onCommentSaved,
    VoidCallback? onCommentDeleted,
    String? originalText,
    String? editedText,
    int? subtitleIndex,
    Function(String)? onTextEdited,
  }) async {
    // Store current orientation preferences before changing to portrait
    List<DeviceOrientation>? originalOrientations;
    
    // Check if we're in fullscreen video mode by checking screen orientation
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    
    // If in landscape (likely fullscreen), store current orientations and switch to portrait
    if (isLandscape) {
      // Store the current preferred orientations (we'll assume they were all orientations)
      originalOrientations = [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
      
      // Force portrait orientation for better comment input experience
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // Give a small delay for orientation change to complete
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        enableDrag: true,
        isDismissible: true,
        builder: (context) => CommentDialog(
          existingComment: existingComment,
          onCommentSaved: onCommentSaved,
          onCommentDeleted: onCommentDeleted,
          originalText: originalText,
          editedText: editedText,
          subtitleIndex: subtitleIndex,
          onTextEdited: onTextEdited,
        ),
      );
    } finally {
      // Restore original orientation when dialog is dismissed
      if (originalOrientations != null) {
        await SystemChrome.setPreferredOrientations(originalOrientations);
      }
    }
  }
}

class CommentDialogState extends State<CommentDialog> {
  late TextEditingController _commentController;
  late TextEditingController _subtitleTextController;
  late FocusNode _focusNode;
  late FocusNode _subtitleFocusNode;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isEditingSubtitleText = false;
  String? _currentSubtitleText;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.existingComment ?? '');
    
    // Initialize subtitle text controller with edited text (priority) or original text
    final hasEdited = widget.editedText != null && widget.editedText!.isNotEmpty;
    final hasOriginal = widget.originalText != null && widget.originalText!.isNotEmpty;
    _currentSubtitleText = hasEdited ? widget.editedText! : (hasOriginal ? widget.originalText! : '');
    _subtitleTextController = TextEditingController(text: _currentSubtitleText);
    
    _focusNode = FocusNode();
    _subtitleFocusNode = FocusNode();
    _isEditing = widget.existingComment != null;
    
    // Automatically focus and show keyboard when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _subtitleTextController.dispose();
    _focusNode.dispose();
    _subtitleFocusNode.dispose();
    super.dispose();
  }

  void _closeDialog() {
    // Handle cancel action based on mode
    if (widget.isOverlayMode) {
      // In overlay mode, call the cancel callback if provided
      if (widget.onCancelled != null) {
        widget.onCancelled!();
      }
    } else {
      // In normal mode, use Navigator to pop the dialog
      Navigator.of(context).pop();
    }
  }

  void _saveComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      // Call the callback to save the comment
      // The parent (screen_edit.dart) will handle marking the line if needed
      widget.onCommentSaved(comment);
      
      // Only call Navigator.pop() if not in overlay mode
      if (!widget.isOverlayMode) {
        Navigator.of(context).pop();
      }
      // In overlay mode, the parent handles closing via the callback
    } catch (e) {
      // Handle any errors
      debugPrint('Error saving comment: $e');
      setState(() => _isLoading = false);
    }
  }

  void _deleteComment() async {
    setState(() => _isLoading = true);
    
    try {
      // Call the callback to delete the comment
      if (widget.onCommentDeleted != null) {
        widget.onCommentDeleted!();
      }
      
      // Only call Navigator.pop() if not in overlay mode
      if (!widget.isOverlayMode) {
        Navigator.of(context).pop();
      }
      // In overlay mode, the parent handles closing via the callback
    } catch (e) {
      // Handle any errors
      debugPrint('Error deleting comment: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic color variables for adaptive theming
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    Widget content = Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Standard Header Structure
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.comment_outlined,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Comment' : 'Add Comment',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEditing 
                            ? 'Modify your comment for this subtitle line'
                            : 'Add a comment to this subtitle line',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete button in header if editing
                  if (_isEditing && widget.onCommentDeleted != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _deleteComment,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Subtitle Content Display (if available)
            if (widget.originalText != null || widget.editedText != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with subtitle index and copy button
                    Row(
                      children: [
                        Icon(
                          Icons.subtitles_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.subtitleIndex != null 
                            ? 'Subtitle Line #${widget.subtitleIndex}'
                            : 'Subtitle Line',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        const Spacer(),
                        // Copy button aligned with title
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(text: _currentSubtitleText ?? ''));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text('Subtitle text copied to clipboard'),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Editable subtitle text field
                    if (_currentSubtitleText != null && _currentSubtitleText!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isEditingSubtitleText ? Colors.blue : borderColor,
                            width: _isEditingSubtitleText ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Edit/Save button row
                            if (widget.onTextEdited != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Edit/Save button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          if (_isEditingSubtitleText) {
                                            // Save the edited text
                                            final newText = _subtitleTextController.text.trim();
                                            if (newText.isNotEmpty && newText != _currentSubtitleText) {
                                              widget.onTextEdited!(newText);
                                              setState(() {
                                                _currentSubtitleText = newText;
                                                _isEditingSubtitleText = false;
                                              });
                                            } else {
                                              setState(() {
                                                _isEditingSubtitleText = false;
                                                _subtitleTextController.text = _currentSubtitleText ?? '';
                                              });
                                            }
                                          } else {
                                            // Enter edit mode
                                            setState(() {
                                              _isEditingSubtitleText = true;
                                            });
                                            _subtitleFocusNode.requestFocus();
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _isEditingSubtitleText ? Icons.check : Icons.edit,
                                                color: Colors.blue,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _isEditingSubtitleText ? 'Save' : 'Edit',
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Cancel button - only in edit mode
                                    if (_isEditingSubtitleText)
                                      Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _isEditingSubtitleText = false;
                                            _subtitleTextController.text = _currentSubtitleText ?? '';
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
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
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
                            // Text field
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: _isEditingSubtitleText
                                  ? CallbackShortcuts(
                                      bindings: <ShortcutActivator, VoidCallback>{
                                        const SingleActivator(LogicalKeyboardKey.enter): () {
                                          // Enter only: Save edited text
                                          final newText = _subtitleTextController.text.trim();
                                          if (newText.isNotEmpty && newText != _currentSubtitleText) {
                                            widget.onTextEdited!(newText);
                                            setState(() {
                                              _currentSubtitleText = newText;
                                              _isEditingSubtitleText = false;
                                            });
                                          } else {
                                            setState(() {
                                              _isEditingSubtitleText = false;
                                              _subtitleTextController.text = _currentSubtitleText ?? '';
                                            });
                                          }
                                        },
                                      },
                                      child: TextField(
                                        controller: _subtitleTextController,
                                        focusNode: _subtitleFocusNode,
                                        maxLines: null,
                                        minLines: 2,
                                        keyboardType: TextInputType.multiline,
                                        textInputAction: TextInputAction.newline,
                                        inputFormatters: [
                                          UnicodeTextInputFormatter(),
                                        ],
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
                                          final newText = value.trim();
                                          if (newText.isNotEmpty && newText != _currentSubtitleText) {
                                            widget.onTextEdited!(newText);
                                            setState(() {
                                              _currentSubtitleText = newText;
                                              _isEditingSubtitleText = false;
                                            });
                                          }
                                        },
                                      ),
                                    )
                                  : Text(
                                      _currentSubtitleText!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        height: 1.4,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Comment Input Field
            Container(
              decoration: BoxDecoration(
                color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
              ),
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent) {
                    // Check for Enter key
                    if (event.logicalKey == LogicalKeyboardKey.enter) {
                      // Check if Shift is pressed
                      if (event.isShiftPressed) {
                        // Shift+Enter: Allow new line (do nothing, let TextField handle it)
                        return;
                      } else {
                        // Enter only: Save comment
                        if (!_isLoading && _commentController.text.trim().isNotEmpty) {
                          _saveComment();
                        }
                      }
                    }
                  }
                },
                child: TextField(
                  controller: _commentController,
                  inputFormatters: [
                    UnicodeTextInputFormatter(),
                  ],
                  focusNode: _focusNode,
                  maxLines: null,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: 'Comment',
                    hintText: ResponsiveLayout.isDesktopPlatform() 
                        ? 'Enter your comment here... (Enter to save, Shift+Enter for new line)'
                        : 'Enter your comment here...',
                    prefixIcon: Icon(
                      Icons.edit_note,
                      color: Colors.blue,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                  enabled: !_isLoading,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _closeDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onSurfaceColor,
                        side: BorderSide(
                          color: onSurfaceColor.withValues(alpha: 0.3),
                        ),
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
                  child: Container(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveComment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isEditing ? Icons.update : Icons.add_comment,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isEditing ? 'Update' : 'Add',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
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
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        // Only add keyboard padding if NOT in overlay mode (overlay handles it separately)
        bottom: widget.isOverlayMode ? 0 : MediaQuery.of(context).viewInsets.bottom,
      ),
      child: content,
    );
  }
}
