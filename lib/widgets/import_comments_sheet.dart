import 'package:flutter/material.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/main.dart';
import 'dart:convert';
import 'dart:io';

class ImportCommentsSheet extends StatefulWidget {
  final int subtitleCollectionId;
  final Function? onCommentsImported;

  const ImportCommentsSheet({
    super.key,
    required this.subtitleCollectionId,
    this.onCommentsImported,
  });

  @override
  ImportCommentsSheetState createState() => ImportCommentsSheetState();
}

class ImportCommentsSheetState extends State<ImportCommentsSheet> {
  bool _isLoading = false;
  String? _selectedFileName;
  Map<String, dynamic>? _projectData;
  int _totalCommentsCount = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: onSurfaceColor.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.file_download_outlined,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Comments',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Import comments from another project file',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: onSurfaceColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Selection Card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _selectProjectFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? onSurfaceColor.withValues(alpha: 0.05) 
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: onSurfaceColor.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.folder_open,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFileName ?? 'Select Project File',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedFileName != null
                                        ? 'Tap to select a different file'
                                        : Platform.isAndroid
                                            ? 'Choose an .msone project file to import comments from'
                                            : 'Browse and select an .msone project file to import comments from',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: onSurfaceColor.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Comments Info (shown when file is selected)
                  if (_projectData != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Project File Loaded',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Found $_totalCommentsCount comments in the project file.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (_totalCommentsCount > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Comments will be imported based on subtitle line matching. Mark status will be preserved from the source file.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: mutedColor,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            Text(
                              'This project file does not contain any comments to import.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: onSurfaceColor.withValues(alpha: 0.12),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: onSurfaceColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Import Button
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ElevatedButton(
                            onPressed: (_projectData != null && _totalCommentsCount > 0 && !_isLoading) 
                                ? _importComments 
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Import',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
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
        ],
      ),
    );
  }

  Future<void> _selectProjectFile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      String? fileContent;
      String? fileName;

      if (Platform.isAndroid) {
        // Use SAF for Android with proper .msone file filtering (same as existing file picker)
        final mimeTypes = _getMsoneFileMimeTypes();
        final fileInfo = await PlatformFileHandler.readFile(mimeTypes: mimeTypes);
        
        if (fileInfo != null) {
          // Properly decode UTF-8 content to preserve Unicode characters
          try {
            fileContent = utf8.decode(fileInfo.content);
          } catch (e) {
            // Fallback to Latin-1 if UTF-8 fails
            fileContent = String.fromCharCodes(fileInfo.content);
          }
          fileName = fileInfo.path.split('/').last.split('\\').last;
          
          // If the filename doesn't end with .msone, warn the user
          if (!fileName.toLowerCase().endsWith('.msone')) {
            if (mounted) {
              SnackbarHelper.showWarning(context, 'Selected file may not be a valid .msone project file');
            }
          }
        }
      } else {
        // Use regular file picker for other platforms (Desktop, iOS)
        final filePath = await FilePickerConvenience.pickMsoneFile(context: context);
        
        if (filePath != null) {
          try {
            final file = File(filePath);
            // Explicitly specify UTF-8 encoding to preserve Unicode characters
            fileContent = await file.readAsString(encoding: utf8);
            fileName = filePath.split(Platform.pathSeparator).last;
          } catch (e) {
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              SnackbarHelper.showError(context, 'Failed to read project file: $e');
            }
            return;
          }
        }
      }

      if (fileContent != null && fileName != null) {
        // Parse the project file content
        try {
          final projectData = jsonDecode(fileContent);
          print('DEBUG: File selection - Project data keys: ${projectData.keys.toList()}');
          
          if (projectData['subtitleCollection'] != null) {
            final subtitleCollection = projectData['subtitleCollection'] as Map<String, dynamic>;
            print('DEBUG: File selection - Subtitle collection keys: ${subtitleCollection.keys.toList()}');
            
            if (subtitleCollection['lines'] != null) {
              final lines = subtitleCollection['lines'] as List<dynamic>;
              print('DEBUG: File selection - Total lines in project: ${lines.length}');
              
              // Debug: Check first comment with Unicode characters
              for (final line in lines.take(5)) {
                final comment = line['comment'] as String?;
                if (comment != null && comment.trim().isNotEmpty) {
                  print('DEBUG: Sample comment: $comment (length: ${comment.length})');
                  // Check if comment contains Unicode characters
                  final hasUnicode = comment.runes.any((rune) => rune > 127);
                  print('DEBUG: Comment has Unicode: $hasUnicode');
                  break;
                }
              }
            }
          }
          
          final commentsCount = _countCommentsInProject(projectData);
          print('DEBUG: File selection - Comments count: $commentsCount');

          setState(() {
            _selectedFileName = fileName;
            _projectData = projectData;
            _totalCommentsCount = commentsCount;
            _isLoading = false;
          });
        } catch (parseError) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            SnackbarHelper.showError(context, 'Invalid project file format');
          }
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarHelper.showError(context, 'Error selecting file: $e');
      }
    }
  }

  int _countCommentsInProject(Map<String, dynamic> projectData) {
    try {
      final subtitleCollection = projectData['subtitleCollection'] as Map<String, dynamic>?;
      if (subtitleCollection == null) return 0;

      final lines = subtitleCollection['lines'] as List<dynamic>?;
      if (lines == null) return 0;

      int count = 0;
      for (final line in lines) {
        final comment = line['comment'] as String?;
        final index = line['index'] as int?;
        
        // Count lines that have both an index and a non-empty comment
        if (index != null && comment != null && comment.trim().isNotEmpty) {
          count++;
        }
      }
      return count;
    } catch (e) {
      print('Error counting comments: $e');
      return 0;
    }
  }

  Future<void> _importComments() async {
    if (_projectData == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Get current subtitle collection
      final currentCollection = await isar.subtitleCollections.get(widget.subtitleCollectionId);
      if (currentCollection == null) {
        throw Exception('Current subtitle collection not found');
      }

      // Extract comments from project data
      final subtitleCollection = _projectData!['subtitleCollection'] as Map<String, dynamic>;
      final importLines = subtitleCollection['lines'] as List<dynamic>;

      // Create a simple map by index for direct line-to-line matching
      final commentByIndex = <int, String>{};
      final markByIndex = <int, bool>{};
      final resolvedByIndex = <int, bool>{};

      for (final line in importLines) {
        final comment = line['comment'] as String?;
        final index = line['index'] as int?;
        final marked = line['marked'] as bool? ?? false;
        final resolved = line['resolved'] as bool? ?? false;

        if (index != null && comment != null && comment.trim().isNotEmpty) {
          // Ensure Unicode characters are preserved by not performing any text transformations
          commentByIndex[index] = comment; // Keep original comment as-is
          markByIndex[index] = marked;
          resolvedByIndex[index] = resolved;
        }
      }

      // Update current collection lines by matching index
      int importedCount = 0;
      await isar.writeTxn(() async {
        for (final currentLine in currentCollection.lines) {
          final comment = commentByIndex[currentLine.index];
          final marked = markByIndex[currentLine.index];
          final resolved = resolvedByIndex[currentLine.index];
          
          if (comment != null) {
            // Debug: Check Unicode preservation before database save
            final hasUnicode = comment.runes.any((rune) => rune > 127);
            if (hasUnicode) {
              print('DEBUG: Importing Unicode comment for line ${currentLine.index}: $comment');
            }
            
            // Assign comment directly without any modifications to preserve Unicode
            currentLine.comment = comment;
            // Use the original mark status from the source file
            currentLine.marked = marked ?? false;
            // Import resolved status
            currentLine.resolved = resolved ?? false;
            importedCount++;
          }
        }
        await isar.subtitleCollections.put(currentCollection);
      });

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.of(context).pop();
        SnackbarHelper.showSuccess(context, 'Imported $importedCount comments and updated mark status successfully');
        widget.onCommentsImported?.call();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to import comments: $e');
      }
    }
  }

  /// Get MIME types for .msone files (same as used in FilePickerSAF)
  List<String> _getMsoneFileMimeTypes() {
    return ['application/octet-stream', 'text/plain'];
  }
}