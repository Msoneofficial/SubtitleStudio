import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:subtitle_studio/utils/load_srt_file.dart';
import 'package:subtitle_studio/utils/subtitle_processor.dart';
import 'package:subtitle_studio/utils/intent_handler.dart';
import 'package:subtitle_studio/utils/saf_path_converter.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/project_manager.dart';
import 'package:subtitle_studio/database/models/models.dart';

class SubtitleImportOptionsSheet extends StatefulWidget {
  final Function(Session) onSubtitleImported;
  final String? initialFilePath;
  final String? initialFileName;
  final String? originalSafUri;  // Original SAF URI for database storage

  const SubtitleImportOptionsSheet({
    super.key,
    required this.onSubtitleImported,
    this.initialFilePath,
    this.initialFileName,
    this.originalSafUri,
  });

  @override
  State<SubtitleImportOptionsSheet> createState() => _SubtitleImportOptionsSheetState();
}

class _SubtitleImportOptionsSheetState extends State<SubtitleImportOptionsSheet> {
  bool _removeHearingImpairedLines = false;
  bool _mergeOverlappingSubtitles = false;
  String? _selectedProjectPath;  // Store selected project directory path
  bool _isLoading = false;
  String? _selectedFilePath;
  String _fileName = '';
  String? _safUri; // Store SAF URI for Android file operations
  String? _fileContent; // Store the content that was already read to avoid double reading

  @override
  void initState() {
    super.initState();
    // Initialize with pre-filled data if provided
    if (widget.initialFilePath != null) {
      _selectedFilePath = widget.initialFilePath;
      // Extract proper filename for display
      _fileName = widget.initialFileName ?? IntentHandler.getFileName(widget.initialFilePath!);
      // If we have an original SAF URI from intent, use it
      if (widget.originalSafUri != null) {
        _safUri = widget.originalSafUri;
      }
    }
  }

  Future<void> _selectFile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final subtitleData = await pickSRT(context);
      if (subtitleData != null && mounted) {
        setState(() {
          _selectedFilePath = subtitleData['filePath'];
          _fileName = subtitleData['fileName'] ?? '';
          _safUri = subtitleData['safUri']; // Store SAF URI separately
          _fileContent = subtitleData['content']; // Store the content that was already read
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error selecting file: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectProjectDirectory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Toggle the project file saving option
      if (_selectedProjectPath != null) {
        // If already selected, deselect it
        setState(() {
          _selectedProjectPath = null;
          _isLoading = false;
        });
        
        if (mounted) {
          SnackbarHelper.showInfo(context, 'Project file saving disabled');
        }
      } else {
        // If not selected, enable project file saving
        setState(() {
          _selectedProjectPath = 'user_selected'; // Mark that user has chosen to save project
          _isLoading = false;
        });
        
        if (mounted) {
          SnackbarHelper.showInfo(context, 'Project file will be saved during import');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processAndImport() async {
    if (_selectedFilePath == null) {
      SnackbarHelper.showError(context, 'Please select a subtitle file first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String subtitleContent;
      String displayPath = _selectedFilePath!;
      String? contentUri = _safUri; // Use stored SAF URI
      
      // For SAF URIs, create a better display path for the database
      if (_safUri != null && IntentHandler.isContentUri(_safUri!)) {
        // Use SafPathConverter for correct SAF URI to path conversion
        final safDisplayPath = SafPathConverter.normalizePath(_safUri!);
        
        if (kDebugMode) {
          print('SubtitleImportOptionsSheet: originalPath=$displayPath, correctedPath=$safDisplayPath, safUri=$_safUri');
        }
        
        // Only use the SAF display path if it looks valid and includes filename
        if (safDisplayPath != _safUri && safDisplayPath.contains('/') && 
            (safDisplayPath.toLowerCase().endsWith('.srt') || 
             safDisplayPath.toLowerCase().endsWith('.vtt') ||
             safDisplayPath.toLowerCase().endsWith('.ass') ||
             safDisplayPath.toLowerCase().endsWith('.ssa') ||
             _fileName.isNotEmpty)) {
          displayPath = safDisplayPath;
          
          // Ensure the display path includes the filename if it doesn't already
          if (_fileName.isNotEmpty && !displayPath.toLowerCase().endsWith(_fileName.toLowerCase())) {
            // Construct complete path with filename
            if (displayPath.endsWith('/')) {
              displayPath += _fileName;
            } else {
              // Replace the last part with our filename
              final pathParts = displayPath.split('/');
              if (pathParts.isNotEmpty) {
                pathParts[pathParts.length - 1] = _fileName;
                displayPath = pathParts.join('/');
              }
            }
          }
        } else {
          // Fallback: Use the temp file path but ensure it has proper filename
          displayPath = _selectedFilePath!;
          if (_fileName.isNotEmpty && !displayPath.toLowerCase().endsWith(_fileName.toLowerCase())) {
            // If the selected path doesn't end with filename, construct it
            final dir = File(displayPath).parent.path;
            displayPath = '$dir${Platform.pathSeparator}$_fileName';
          }
        }
      }
      
      // Ensure the path always ends with a subtitle file extension
      if (!displayPath.toLowerCase().endsWith('.srt') && 
          !displayPath.toLowerCase().endsWith('.vtt') &&
          !displayPath.toLowerCase().endsWith('.ass') &&
          !displayPath.toLowerCase().endsWith('.ssa')) {
        if (_fileName.isNotEmpty) {
          // Use the filename if available
          if (!displayPath.endsWith('/') && !displayPath.endsWith(Platform.pathSeparator)) {
            displayPath += Platform.pathSeparator;
          }
          displayPath += _fileName;
        } else {
          // Fallback: add .srt extension
          displayPath += '.srt';
        }
      }
      
      if (_fileContent != null) {
        // Use the content that was already read during file selection
        subtitleContent = _fileContent!;
        if (mounted) {
          SnackbarHelper.showInfo(context, 'Processing selected file...', duration: const Duration(seconds: 2));
        }
      } else if (_safUri != null) {
        // Fallback: File was selected using SAF but content wasn't stored, read from SAF URI
        if (mounted) {
          SnackbarHelper.showInfo(context, 'Processing file from external storage...', duration: const Duration(seconds: 2));
        }
        
        // Read content directly from SAF URI
        subtitleContent = await IntentHandler.readContentFromUri(_safUri!);
        
        if (subtitleContent.isEmpty) {
          throw Exception('Failed to read file content from external storage. The file may be empty or inaccessible.');
        }
      } else {
        // Read content from regular file path
        final file = File(_selectedFilePath!);
        subtitleContent = await file.readAsString();
      }

      // Process and import subtitle content with selected options
      final subtitleData = await processAndImportSubtitleContent(
        subtitleContent,
        _fileName.isNotEmpty ? _fileName : 'subtitle.srt',
        displayPath,
        context,
        removeHearingImpairedLines: _removeHearingImpairedLines,
        mergeOverlappingSubtitles: _mergeOverlappingSubtitles,
        contentUri: contentUri, // Store SAF URI for future access
      );

      if (subtitleData != null && mounted) {
        // Handle project saving based on user preference
        if (_selectedProjectPath != null) {
          // Manual project saving - prompt user to select directory
          final session = subtitleData['session'] as Session?;
          final subtitleCollection = subtitleData['subtitleCollection'] as SubtitleCollection?;
          
          if (session != null && subtitleCollection != null) {
            final projectPath = await ProjectManager.saveProject(
              context: context,
              session: session,
              subtitleCollection: subtitleCollection,
              forceNewLocation: true,
            );
            
            if (projectPath != null) {
              await ProjectManager.updateSessionProjectPath(
                sessionId: session.id,
                projectFilePath: projectPath,
              );
            }
          }
        }
        // If _selectedProjectPath is null, skip project saving entirely
        // The subtitle data is already imported and ready to use

        // Create session for navigation (fallback if not in subtitleData)
        Session session;
        if (subtitleData['session'] != null) {
          session = subtitleData['session'] as Session;
        } else {
          session = Session(
            subtitleCollectionId: subtitleData['subtitleCollectionId'],
            fileName: subtitleData['fileName'] ?? '',
            lastEditedIndex: subtitleData['lastEditedIndex'],
          );
        }

        Navigator.pop(context);
        widget.onSubtitleImported(session);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error processing subtitle: $e', duration: const Duration(seconds: 4));
        setState(() {
          _isLoading = false;
        });
      }
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

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.file_download_outlined,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Import Subtitle",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Configure import settings and select file",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // File Selection Action Card
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _selectFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedFilePath != null ? Colors.green : primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _selectedFilePath != null ? Icons.check : Icons.file_open,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFilePath != null 
                                    ? (_fileName.isNotEmpty ? _fileName : "SRT File Selected")
                                    : "Select Subtitle File",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedFilePath != null 
                                    ? "File ready for import with selected options"
                                    : "Choose an SRT subtitle file to import",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: mutedColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isLoading)
                          Icon(
                            _selectedFilePath != null ? Icons.refresh : Icons.chevron_right_rounded,
                            color: mutedColor,
                            size: 24,
                          ),
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Set Project Directory Action Card
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _selectProjectDirectory,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedProjectPath != null ? Colors.orange : primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _selectedProjectPath != null ? Icons.check : Icons.folder_open,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedProjectPath != null 
                                    ? "Project File Selected"
                                    : "Save Project File (Optional)",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedProjectPath != null 
                                    ? "Will prompt to save .msone file during import"
                                    : "Tap to save a .msone project file",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: mutedColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isLoading)
                          Icon(
                            _selectedProjectPath != null ? Icons.refresh : Icons.chevron_right_rounded,
                            color: mutedColor,
                            size: 24,
                          ),
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Import Options Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Import Options",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Remove hearing impaired lines option
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _removeHearingImpairedLines = !_removeHearingImpairedLines;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _removeHearingImpairedLines ? primaryColor : Colors.transparent,
                                  border: Border.all(
                                    color: _removeHearingImpairedLines ? primaryColor : borderColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _removeHearingImpairedLines
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Remove Hearing Impaired Lines',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Removes text inside "[ ]" brackets',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Merge overlapping subtitles option
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _mergeOverlappingSubtitles = !_mergeOverlappingSubtitles;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _mergeOverlappingSubtitles ? primaryColor : Colors.transparent,
                                  border: Border.all(
                                    color: _mergeOverlappingSubtitles ? primaryColor : borderColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _mergeOverlappingSubtitles
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Merge Overlapping Subtitles',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Combines subtitles with same timing',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
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
              
              const SizedBox(height: 24),
              
              // Import Button
              Container(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processAndImport,
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
                            Icon(Icons.download, size: 20, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _selectedProjectPath != null ? "Import & Save Project" : "Import Subtitle",
                              style: TextStyle(
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
      ),
    );
  }
}
