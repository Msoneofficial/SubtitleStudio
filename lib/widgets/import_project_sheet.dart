import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/intent_handler.dart';
import 'package:subtitle_studio/utils/project_manager.dart';
import 'package:subtitle_studio/database/models/models.dart';

/// Import Project Sheet Widget
/// 
/// This widget provides the UI for importing .msone project files
/// back into the application. It allows users to:
/// - Select a .msone file to import
/// - Preview the project information from the file
/// - Import the complete project data into the database
/// 
/// The SRT file location is handled during the import process through
/// the session selection sheet, eliminating the need for separate
/// destination folder selection.
/// 
/// The imported data creates new Session and SubtitleCollection entries
/// with fresh IDs while preserving all subtitle content and metadata,
/// including the originalFileUri for proper file referencing.
///
/// Fixed Issues:
/// - Now properly sets originalFileUri during import to maintain
///   file reference integrity for SAF operations and future re-access
/// - Correctly stores content URIs instead of file paths on Android SAF
///   to ensure proper access to files selected via Storage Access Framework
class ImportProjectSheet extends StatefulWidget {
  final Function(Session)? onProjectImported;
  final String? initialFilePath;
  final String? originalSafUri;  // Original SAF URI for database storage

  const ImportProjectSheet({
    super.key,
    this.onProjectImported,
    this.initialFilePath,
    this.originalSafUri,
  });

  @override
  State<ImportProjectSheet> createState() => _ImportProjectSheetState();
}

class _ImportProjectSheetState extends State<ImportProjectSheet> {
  String? _selectedMsoneFilePath;
  bool _isImporting = false;
  bool _isLoadingFile = false;
  Map<String, dynamic>? _projectData;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    // If initial file path is provided, use it
    if (widget.initialFilePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialFile();
      });
    }
  }

  /// Load initial file if provided via intent
  Future<void> _loadInitialFile() async {
    try {
      setState(() {
        _isLoadingFile = true;
        _projectData = null;
      });

      // Process the file path - convert content URI to temp file if needed
      String? processedPath = await IntentHandler.processFilePath(widget.initialFilePath!);
      if (processedPath!.isEmpty) {
        throw Exception('Unable to access the file');
      }

      await _loadProjectData(processedPath);
      setState(() {
        _selectedMsoneFilePath = processedPath;
        _fileName = IntentHandler.getFileName(widget.initialFilePath!).replaceAll('.msone', '');
      });
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error loading project file: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFile = false;
        });
      }
    }
  }

  /// Select .msone file to import
  Future<void> _selectMsoneFile() async {
    setState(() {
      _isLoadingFile = true;
      _projectData = null;
    });

    try {
      if (Platform.isAndroid) {
        // Use SAF on Android
        final fileInfo = await PlatformFileHandler.readFile(
          mimeTypes: ['application/json', 'application/octet-stream', 'text/plain'],
        );
        
        if (fileInfo != null) {
          await _loadProjectDataFromContent(fileInfo.contentAsString, fileInfo.fileName);
          setState(() {
            // Store the actual URI for Android SAF files, not the display path
            _selectedMsoneFilePath = fileInfo.isFromSaf ? fileInfo.safUri : fileInfo.path;
            _fileName = fileInfo.fileName.replaceAll('.msone', '');
          });
        }
      } else {
        // Desktop platforms
        final selectedPath = await FilePickerConvenience.pickMsoneFile(
          context: context,
        );

        if (selectedPath != null) {
          await _loadProjectData(selectedPath);
          setState(() {
            _selectedMsoneFilePath = selectedPath;
            _fileName = selectedPath.split(Platform.pathSeparator).last.replaceAll('.msone', '');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error selecting file: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFile = false;
        });
      }
    }
  }

  /// Load and validate project data from the selected .msone file
  Future<void> _loadProjectData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate required fields
      if (!data.containsKey('session') || 
          !data.containsKey('subtitleCollection') ||
          !data.containsKey('version')) {
        throw Exception('Invalid .msone file format');
      }

      print('[Import] Loaded project data keys: ${data.keys.toList()}');
      if (data.containsKey('checkpoints')) {
        print('[Import] Found ${(data['checkpoints'] as List).length} checkpoints in file');
      } else {
        print('[Import] No checkpoints found in file');
      }

      setState(() {
        _projectData = data;
      });
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error reading project file: $e');
      }
    }
  }

  /// Load project data from file content (for SAF)
  Future<void> _loadProjectDataFromContent(String content, String fileName) async {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Validate required fields
      if (!data.containsKey('session') || 
          !data.containsKey('subtitleCollection') ||
          !data.containsKey('version')) {
        throw Exception('Invalid .msone file format');
      }

      print('[Import] Loaded project data keys: ${data.keys.toList()}');
      if (data.containsKey('checkpoints')) {
        print('[Import] Found ${(data['checkpoints'] as List).length} checkpoints in file');
      } else {
        print('[Import] No checkpoints found in file');
      }

      setState(() {
        _projectData = data;
      });
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error reading project file: $e');
      }
    }
  }

  /// Import the project data into the database
  Future<void> _importProject() async {
    if (_projectData == null) {
      SnackbarHelper.showError(context, 'No project data loaded');
      return;
    }

    // Determine the original file URI for the imported project
    String? originalFileUri;
    if (widget.originalSafUri != null) {
      // Prefer the original SAF URI when available (from intent)
      originalFileUri = widget.originalSafUri;
    } else if (widget.initialFilePath != null) {
      // Use the initial file path provided (for non-SAF files)
      originalFileUri = widget.initialFilePath;
    } else if (_selectedMsoneFilePath != null) {
      // Use the selected .msone file URI (now correctly stores URI for SAF files)
      originalFileUri = _selectedMsoneFilePath;
    } else if (_projectData!['subtitleCollection'] != null &&
               (_projectData!['subtitleCollection'] as Map<String, dynamic>)['originalFileUri'] != null) {
      // Fall back to any originalFileUri from the project data
      originalFileUri = (_projectData!['subtitleCollection'] as Map<String, dynamic>)['originalFileUri'];
    }

    // Show session selection sheet to replace existing session or import as new
    await ProjectManager.showSessionSelectionSheet(
      context: context,
      projectData: _projectData!,
      originalFileUri: originalFileUri,
      onProjectImported: widget.onProjectImported,
    );

    // Navigation is now handled directly by the session selection sheet
    // No need to close this sheet manually since pushAndRemoveUntil will handle it
  }

  /// Get count of edited lines from project data
  int _getEditedLinesCount() {
    if (_projectData == null) return 0;
    
    final subtitleCollectionData = _projectData!['subtitleCollection'] as Map<String, dynamic>;
    final linesData = subtitleCollectionData['lines'] as List<dynamic>;
    
    return linesData.where((lineData) {
      final edited = lineData['edited'];
      return edited != null && edited.toString().isNotEmpty;
    }).length;
  }

  /// Build file selection section
  Widget _buildFileSelectionSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Project File',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isLoadingFile ? null : _selectMsoneFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
              color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.file_open,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isLoadingFile
                      ? Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading project file...',
                              style: TextStyle(
                                color: onSurfaceColor.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _selectedMsoneFilePath != null
                              ? '$_fileName.msone'
                              : 'Tap to select .msone project file',
                          style: TextStyle(
                            color: _selectedMsoneFilePath != null
                                ? onSurfaceColor
                                : onSurfaceColor.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (!_isLoadingFile)
                  Icon(
                    Icons.chevron_right,
                    color: onSurfaceColor.withValues(alpha: 0.3),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build project preview section
  Widget _buildProjectPreview() {
    if (_projectData == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    
    final sessionData = _projectData!['session'] as Map<String, dynamic>;
    final subtitleCollectionData = _projectData!['subtitleCollection'] as Map<String, dynamic>;
    final exportedAt = _projectData!['exportedAt'] as String?;
    final version = _projectData!['version'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('File Name', sessionData['fileName'] ?? 'Unknown', isFileName: true),
          _buildInfoRow('Total Lines', '${(subtitleCollectionData['lines'] as List).length}'),
          _buildInfoRow('Edited Lines', '${_getEditedLinesCount()}'),
          _buildInfoRow('Encoding', subtitleCollectionData['encoding'] ?? 'UTF-8'),
          _buildInfoRow('Mode', (sessionData['editMode'] ?? true) ? 'Edit' : 'Translation'),
          if (_projectData!.containsKey('checkpoints'))
            _buildInfoRow('Checkpoints', '${(_projectData!['checkpoints'] as List).length}'),
          if (exportedAt != null)
            _buildInfoRow('Exported', _formatDateTime(exportedAt)),
          if (version != null)
            _buildInfoRow('Version', version),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isFileName = false}) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: mutedColor,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              overflow: isFileName ? TextOverflow.ellipsis : TextOverflow.visible,
              maxLines: isFileName ? 1 : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.unarchive,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Project',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Import .msone project file',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // File Selection
            _buildFileSelectionSection(),
            
            // Project Preview (only show if file is loaded)
            if (_projectData != null) ...[
              const SizedBox(height: 24),
              _buildProjectPreview(),
            ],
            
            const SizedBox(height: 24),
            
            // Import Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isImporting || _projectData == null) ? null : _importProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isImporting
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
                          const Icon(Icons.unarchive, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Import Project',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
