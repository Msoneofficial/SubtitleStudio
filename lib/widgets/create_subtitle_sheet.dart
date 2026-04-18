import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:flutter/foundation.dart';
import 'package:subtitle_studio/utils/platform_check.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/app_logger.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'dart:io';

class CreateSubtitleSheet extends StatefulWidget {
  final Function(Map<String, dynamic>?) onSubtitleCreated;

  const CreateSubtitleSheet({
    super.key,
    required this.onSubtitleCreated,
  });

  @override
  State<CreateSubtitleSheet> createState() => _CreateSubtitleSheetState();
}

class _CreateSubtitleSheetState extends State<CreateSubtitleSheet> {
  final TextEditingController _fileNameController = TextEditingController();
  String? _selectedSrtPath;
  String? _selectedProjectPath;
  String _encoding = 'UTF-8';
  final List<String> _encodingOptions = ['UTF-8', 'ISO-8859-1', 'Windows-1252'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AppLogger.instance.info('CreateSubtitleSheet initialized', context: 'CreateSubtitleSheet.initState');
  }

  @override
  void dispose() {
    AppLogger.instance.info('CreateSubtitleSheet disposing', context: 'CreateSubtitleSheet.dispose');
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _selectSrtLocation() async {
    await AppLogger.instance.info('Starting SRT location selection', context: 'CreateSubtitleSheet._selectSrtLocation');
    try {
      if (Platform.isAndroid) {
        // On Android, this will be used later during file creation
        // For now, just mark as selected to enable the create button
        setState(() {
          _selectedSrtPath = 'android_saf_pending'; // Placeholder to indicate SAF will be used
        });
        await AppLogger.instance.info('Android SAF mode selected for SRT location', context: 'CreateSubtitleSheet._selectSrtLocation');
      } else {
        // On other platforms, pick the actual directory
        final hasPermission = await requestStoragePermissions();
        
        if (!hasPermission) {
          if (!mounted) return;
          
          await AppLogger.instance.warning('Storage permission denied for SRT directory selection', context: 'CreateSubtitleSheet._selectSrtLocation');
          SnackbarHelper.showError(
            context,
            'Storage permission is required to select SRT directory. Please grant permission in app settings.',
            duration: const Duration(seconds: 4),
          );
          return;
        }
        
        if (!mounted) return;
        
        final srtDir = await FilePickerConvenience.pickExportFolder(context: context);

        if (srtDir != null && mounted) {
          await AppLogger.instance.info('SRT directory selected: $srtDir', context: 'CreateSubtitleSheet._selectSrtLocation');
          setState(() {
            _selectedSrtPath = srtDir;
          });
        } else if (srtDir == null) {
          await AppLogger.instance.info('SRT directory selection cancelled by user', context: 'CreateSubtitleSheet._selectSrtLocation');
        }
      }
    } catch (e) {
      await AppLogger.instance.error('Error selecting SRT directory: $e', context: 'CreateSubtitleSheet._selectSrtLocation');
      if (kDebugMode) {
        print('Error selecting SRT directory: $e');
      }
      if (mounted) {
        SnackbarHelper.showError(context, 'Error selecting SRT directory: $e');
      }
    }
  }

  Future<void> _selectProjectLocation() async {
    await AppLogger.instance.info('Starting project location selection', context: 'CreateSubtitleSheet._selectProjectLocation');
    try {
      if (Platform.isAndroid) {
        // On Android, this will be used later during file creation
        // For now, just mark as selected to enable the create button
        setState(() {
          _selectedProjectPath = 'android_saf_pending'; // Placeholder to indicate SAF will be used
        });
        await AppLogger.instance.info('Android SAF mode selected for project location', context: 'CreateSubtitleSheet._selectProjectLocation');
      } else {
        // On other platforms, pick the actual directory
        final hasPermission = await requestStoragePermissions();
        
        if (!hasPermission) {
          if (!mounted) return;
          
          await AppLogger.instance.warning('Storage permission denied for project directory selection', context: 'CreateSubtitleSheet._selectProjectLocation');
          SnackbarHelper.showError(
            context,
            'Storage permission is required to select project directory. Please grant permission in app settings.',
            duration: const Duration(seconds: 4),
          );
          return;
        }
        
        if (!mounted) return;
        
        final projectDir = await FilePickerConvenience.pickExportFolder(context: context);

        if (projectDir != null && mounted) {
          await AppLogger.instance.info('Project directory selected: $projectDir', context: 'CreateSubtitleSheet._selectProjectLocation');
          setState(() {
            _selectedProjectPath = projectDir;
          });
        } else if (projectDir == null) {
          await AppLogger.instance.info('Project directory selection cancelled by user', context: 'CreateSubtitleSheet._selectProjectLocation');
        }
      }
    } catch (e) {
      await AppLogger.instance.error('Error selecting project directory: $e', context: 'CreateSubtitleSheet._selectProjectLocation');
      if (kDebugMode) {
        print('Error selecting project directory: $e');
      }
      if (mounted) {
        SnackbarHelper.showError(context, 'Error selecting project directory: $e');
      }
    }
  }

  Future<void> _createSubtitle() async {
    await AppLogger.instance.info('Starting subtitle creation process', context: 'CreateSubtitleSheet._createSubtitle');
    String fileName = _fileNameController.text.trim();
    
    if (fileName.isEmpty) {
      await AppLogger.instance.warning('Empty filename provided for subtitle creation', context: 'CreateSubtitleSheet._createSubtitle');
      SnackbarHelper.showError(context, 'Please enter a file name');
      return;
    }

    // Check if both locations are selected
    if (_selectedSrtPath == null || _selectedProjectPath == null) {
      await AppLogger.instance.warning('SRT or project location not selected for subtitle creation', context: 'CreateSubtitleSheet._createSubtitle');
      SnackbarHelper.showError(context, 'Please select both SRT and project locations');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if filename already has .srt extension, add it if not
      if (!fileName.toLowerCase().endsWith('.srt')) {
        fileName += '.srt';
      }

      String? srtFileUri;      // originalFileUri parameter
      String? srtFilePath;     // filePath parameter 
      String? projectFileUri;  // For storing the project file URI/path
      
      if (Platform.isAndroid) {
        // On Android: Use SAF to create both files at user-selected locations
        await AppLogger.instance.info('Android detected - using SAF for file creation', context: 'CreateSubtitleSheet._createSubtitle');
        
        // Create SRT file using SAF
        final srtFileInfo = await PlatformFileHandler.saveNewFile(
          content: '', // Empty content for new subtitle
          fileName: fileName,
          mimeType: 'application/x-subrip',
        );
        
        if (srtFileInfo == null) {
          await AppLogger.instance.info('SRT file creation cancelled by user', context: 'CreateSubtitleSheet._createSubtitle');
          return;
        }
        
        srtFileUri = srtFileInfo.safUri;        // URI for originalFileUri
        srtFilePath = srtFileInfo.path;         // Display path for filePath
        
        await AppLogger.instance.info('SRT file created via SAF - URI: $srtFileUri, Path: $srtFilePath', context: 'CreateSubtitleSheet._createSubtitle');
        
        // Create project file using SAF
        final projectFileName = fileName.replaceAll('.srt', '.msone');
        final projectFileInfo = await PlatformFileHandler.saveNewFile(
          content: '', // Empty content for new project
          fileName: projectFileName,
          mimeType: 'application/octet-stream', // Generic binary MIME type to preserve .msone extension
        );
        
        if (projectFileInfo == null) {
          await AppLogger.instance.info('Project file creation cancelled by user', context: 'CreateSubtitleSheet._createSubtitle');
          return;
        }
        
        projectFileUri = projectFileInfo.safUri; // URI for project file
        
        await AppLogger.instance.info('Project file created via SAF - URI: $projectFileUri', context: 'CreateSubtitleSheet._createSubtitle');
      } else {
        // On other platforms: Use the selected directories and create full file paths
        final srtFileName = fileName;
        final projectFileName = fileName.replaceAll('.srt', '.msone');
        
        srtFileUri = '${_selectedSrtPath!}${Platform.pathSeparator}$srtFileName';
        srtFilePath = srtFileUri; // Same value for both on other platforms
        projectFileUri = '${_selectedProjectPath!}${Platform.pathSeparator}$projectFileName';
        
        await AppLogger.instance.info('Desktop file paths created - SRT: $srtFilePath, Project: $projectFileUri', context: 'CreateSubtitleSheet._createSubtitle');
        
        // Create the actual SRT file (empty) on disk so it exists for future saves
        try {
          final srtFile = File(srtFilePath);
          await srtFile.writeAsString(''); // Create empty file
          await AppLogger.instance.info('Empty SRT file created at: $srtFilePath', context: 'CreateSubtitleSheet._createSubtitle');
        } catch (e) {
          await AppLogger.instance.error('Failed to create SRT file: $e', context: 'CreateSubtitleSheet._createSubtitle');
          throw Exception('Failed to create SRT file: $e');
        }
      }
      
      // Create an empty list of SubtitleLine objects
      final emptySubtitleLines = <SubtitleLine>[];
      
      // Store the subtitle data with editMode set to true for new subtitles
      final subtitleData = await storeSubtitleData(
        emptySubtitleLines,
        fileName,
        _encoding,
        srtFilePath, // Use SRT file path for filePath parameter
        editMode: true, // Set to true for new subtitles
        originalFileUri: srtFileUri, // Store SRT file URI for originalFileUri parameter
        projectFilePath: projectFileUri, // Store project file URI in session
      );

      await AppLogger.instance.info('Subtitle file created successfully. SRT URI: $srtFileUri, SRT Path: $srtFilePath, Project: $projectFileUri', context: 'CreateSubtitleSheet._createSubtitle');
      
      if (mounted) {
        Navigator.pop(context);
        widget.onSubtitleCreated(subtitleData);
      }
    } catch (e) {
      await AppLogger.instance.error('Error creating subtitle: $e', context: 'CreateSubtitleSheet._createSubtitle');
      if (kDebugMode) {
        print('Error creating subtitle: $e');
      }
      if (mounted) {
        SnackbarHelper.showError(context, 'Error creating subtitle: $e');
      }
    } finally {
      if (mounted) {
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
                        Icons.add_circle_outline,
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
                            'Create New Subtitle',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a new subtitle file with custom settings',
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
              const SizedBox(height: 24),
              
              // File name input
              Container(
                decoration: BoxDecoration(
                  color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _fileNameController,
                  decoration: InputDecoration(
                    labelText: 'Subtitle Name',
                    prefixIcon: Icon(
                      Icons.subtitles,
                      color: primaryColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: TextStyle(
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // SRT Location Selection
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _selectSrtLocation,
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
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.subtitles_outlined,
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
                                Platform.isAndroid ? 'SRT File Location' : 'SRT Directory',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedSrtPath != null 
                                  ? Platform.isAndroid 
                                    ? 'Will prompt to save SRT file when creating'
                                    : 'Selected: ${_selectedSrtPath!.split(Platform.pathSeparator).last}'
                                  : Platform.isAndroid
                                    ? 'Tap to choose where to save SRT file'
                                    : 'Tap to select directory for SRT file',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: mutedColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _selectedSrtPath != null ? Icons.check_circle : Icons.chevron_right_rounded,
                          color: _selectedSrtPath != null ? Colors.green : mutedColor,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Project Location Selection
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _selectProjectLocation,
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
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.folder_special_outlined,
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
                                Platform.isAndroid ? 'Project File Location' : 'Project Directory',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedProjectPath != null 
                                  ? Platform.isAndroid 
                                    ? 'Will prompt to save project file when creating'
                                    : 'Selected: ${_selectedProjectPath!.split(Platform.pathSeparator).last}'
                                  : Platform.isAndroid
                                    ? 'Tap to choose where to save project file'
                                    : 'Tap to select directory for project file',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: mutedColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _selectedProjectPath != null ? Icons.check_circle : Icons.chevron_right_rounded,
                          color: _selectedProjectPath != null ? Colors.orange : mutedColor,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Encoding dropdown
              Container(
                decoration: BoxDecoration(
                  color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _encoding,
                  decoration: InputDecoration(
                    labelText: 'File Encoding',
                    prefixIcon: Icon(
                      Icons.code,
                      color: primaryColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: TextStyle(
                      color: primaryColor,
                    ),
                  ),
                  items: _encodingOptions.map((String encoding) {
                    return DropdownMenuItem<String>(
                      value: encoding,
                      child: Text(encoding),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _encoding = newValue;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Create button
              Container(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createSubtitle,
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Create Subtitle',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
