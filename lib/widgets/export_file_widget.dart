import 'package:flutter/material.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:subtitle_studio/utils/platform_check.dart';
import 'package:subtitle_studio/utils/srt_compiler.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/app_logger.dart';
import 'package:subtitle_studio/widgets/file_replace_dialog.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../database/models/models.dart';

class ExportBottomSheet extends StatefulWidget {
  final SubtitleCollection subtitle;
  final Function onExportComplete;

  const ExportBottomSheet({
    super.key,
    required this.subtitle,
    required this.onExportComplete,
  });

  @override
  ExportBottomSheetState createState() => ExportBottomSheetState();
}

class ExportBottomSheetState extends State<ExportBottomSheet> {
  late TextEditingController _fileNameController;
  late TextEditingController _filePathController;
  late TextEditingController _customTagController; // New controller for custom tag
  String _selectedEncoding = "UTF-8"; // Default encoding
  bool _exportOriginalAsWell = false; // Track if original lines should be exported separately

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.subtitle.fileName);
    _filePathController =
        TextEditingController(text: widget.subtitle.filePath ?? '');
    _customTagController = TextEditingController(text: "MSone"); // Default tag value
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _filePathController.dispose();
    _customTagController.dispose(); // Dispose the custom tag controller
    super.dispose();
  }

  Future<void> _pickFolder() async {
    if (!context.mounted) return;
    
    // Use SAF-based file picker
    String? selectedFolder = await FilePickerConvenience.pickExportFolder(context: context);

    setState(() {
      _filePathController.text = selectedFolder!;
    });
    }

  Future<void> _requestStoragePermission() async {
    // On Android with SAF, no permission requests needed
    // On iOS with file picker, no permission requests needed
    // On desktop platforms, request storage permissions
    if (!Platform.isAndroid && !Platform.isIOS) {
      final hasPermission = await requestStoragePermissions();
      
      if (!hasPermission) {
        throw Exception('Storage permission is required to export files. Please grant permission in app settings.');
      }
    }
  }

  Future<void> _exportSrt() async {
    await AppLogger.instance.info('Starting export process', context: 'ExportBottomSheet._exportSrt');
    
    try {
      // Request storage permission
      await _requestStoragePermission();

      final fileName = _fileNameController.text.replaceAll(".srt", "");
      
      // Check if filename contains .msone/.MSone/.Msone before .srt and skip custom tag
      String customTag;
      if (RegExp(r'\.msone(?=\.srt)|\.MSone(?=\.srt)|\.Msone(?=\.srt)', caseSensitive: false).hasMatch(_fileNameController.text)) {
        customTag = ""; // Don't add custom tag for files already containing msone variants
      } else {
        customTag = _customTagController.text.trim().isEmpty ? "MSone" : _customTagController.text.trim();
      }
      
      // Different handling for Android, iOS, and desktop
      if (Platform.isAndroid) {
        // On Android, use SAF to save files individually
        await _exportWithSAF(fileName, customTag);
      } else if (Platform.isIOS) {
        // On iOS, use file picker with bytes
        await _exportWithFilePicker(fileName, customTag);
      } else {
        // On desktop, use traditional file operations
        await _exportTraditional(fileName, customTag);
      }

    } catch (e) {
      await AppLogger.instance.error('Export failed: $e', context: 'ExportBottomSheet._exportSrt');
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Export failed: $e');
      }
    }
  }

  Future<void> _exportWithSAF(String fileName, String customTag) async {
    try {
      // Compile subtitle content
      final content = SrtCompiler.generateSrtContent(widget.subtitle.lines, forceOriginal: _exportOriginalAsWell);
      
      // Determine filename based on export option
      String exportFileName;
      if (_exportOriginalAsWell) {
        exportFileName = "$fileName.original.srt";
      } else {
        // Only add custom tag if it's not empty
        if (customTag.isNotEmpty) {
          exportFileName = "$fileName.$customTag.srt";
        } else {
          exportFileName = "$fileName.srt";
        }
      }
      
      // Use SAF to save the file
      final success = await FilePickerConvenience.saveFile(
        context: context,
        content: content,
        fileName: exportFileName,
        mimeType: 'application/x-subrip', // Proper MIME type for SRT files
      );
      
      if (success != null) {
        await AppLogger.instance.info('Successfully exported via SAF: $success', context: 'ExportBottomSheet._exportWithSAF');
        
        if (context.mounted) {
          widget.onExportComplete();
          Navigator.of(context).pop();
          SnackbarHelper.showSuccess(
            context,
            'Subtitle exported successfully to $exportFileName',
          );
        }
      } else {
        throw Exception('SAF export was cancelled or failed');
      }
    } catch (e) {
      await AppLogger.instance.error('SAF export failed: $e', context: 'ExportBottomSheet._exportWithSAF');
      rethrow;
    }
  }

  Future<void> _exportWithFilePicker(String fileName, String customTag) async {
    try {
      // Compile subtitle content
      final content = SrtCompiler.generateSrtContent(widget.subtitle.lines, forceOriginal: _exportOriginalAsWell);
      
      // Determine filename based on export option
      String exportFileName;
      if (_exportOriginalAsWell) {
        exportFileName = "$fileName.original.srt";
      } else {
        // Only add custom tag if it's not empty
        if (customTag.isNotEmpty) {
          exportFileName = "$fileName.$customTag.srt";
        } else {
          exportFileName = "$fileName.srt";
        }
      }
      
      // Convert content to bytes for iOS file picker
      final contentBytes = Uint8List.fromList(utf8.encode(content));
      
      // Use file picker to save the file on iOS
      final result = await fp.FilePicker.platform.saveFile(
        dialogTitle: 'Save Subtitle File',
        fileName: exportFileName,
        type: fp.FileType.custom,
        allowedExtensions: ['srt'],
        bytes: contentBytes,
      );
      
      if (result != null) {
        await AppLogger.instance.info('Successfully exported via iOS file picker: $result', context: 'ExportBottomSheet._exportWithFilePicker');
        
        if (context.mounted) {
          widget.onExportComplete();
          Navigator.of(context).pop();
          SnackbarHelper.showSuccess(
            context,
            'Subtitle exported successfully to $exportFileName',
          );
        }
      } else {
        await AppLogger.instance.info('iOS export was cancelled by user', context: 'ExportBottomSheet._exportWithFilePicker');
      }
    } catch (e) {
      await AppLogger.instance.error('iOS export failed: $e', context: 'ExportBottomSheet._exportWithFilePicker');
      rethrow;
    }
  }

  Future<void> _exportTraditional(String fileName, String customTag) async {
    if (_filePathController.text.isEmpty) {
      await AppLogger.instance.warning('Export attempted without folder selection', context: 'ExportBottomSheet._exportTraditional');
      SnackbarHelper.showError(
        context,
        Platform.isAndroid 
          ? "Please tap the Save As button to select an output folder."
          : "Please select a folder to save the file.",
      );
      return;
    }

    try {
      // Define file path based on export option
      String filePath;
      
      if (_exportOriginalAsWell) {
        // Export only original content with .original.srt extension
        filePath = "${_filePathController.text}/$fileName.original.srt";
      } else {
        // Export edited lines with custom tag (only if not empty)
        if (customTag.isNotEmpty) {
          filePath = "${_filePathController.text}/$fileName.$customTag.srt";
        } else {
          filePath = "${_filePathController.text}/$fileName.srt";
        }
      }

      // Handle file existence
      final file = File(filePath);
      if (await file.exists()) {
        if (!context.mounted) return;

        // Show the new file replace dialog
        bool shouldContinue = false;
        String finalFilePath = filePath;
        
        await showFileReplaceDialog(
          context: context,
          fileName: fileName,
          existingPath: _filePathController.text,
          onRename: (newFileName) {
            // Update file path with new name
            if (_exportOriginalAsWell) {
              finalFilePath = "${_filePathController.text}/$newFileName.original.srt";
            } else {
              if (customTag.isNotEmpty) {
                finalFilePath = "${_filePathController.text}/$newFileName.$customTag.srt";
              } else {
                finalFilePath = "${_filePathController.text}/$newFileName.srt";
              }
            }
            shouldContinue = true;
          },
          onReplace: () {
            // Keep original file path
            finalFilePath = filePath;
            shouldContinue = true;
          },
        );

        if (!shouldContinue) {
          return; // User cancelled
        }
        
        filePath = finalFilePath;
      }

      // Create and export the subtitle file
      final subtitle = SubtitleCollection(
        fileName: fileName,
        filePath: filePath,
        encoding: _selectedEncoding,
        lines: widget.subtitle.lines,
      );

      // Export with the appropriate option
      await SrtCompiler.compileSrt(subtitle, forceOriginal: _exportOriginalAsWell);
      
      await AppLogger.instance.info('Subtitle exported successfully to: $filePath', context: 'ExportBottomSheet._exportSrt');
      
      if (!context.mounted) return;

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          "Exported to $filePath",
          duration: const Duration(seconds: 2),
        );
        widget.onExportComplete();
        Navigator.pop(context);
      }
    } catch (e) {
      await AppLogger.instance.error('Export failed: $e', context: 'ExportBottomSheet._exportSrt');
      
      if (!context.mounted) return;

      if (mounted) {
        SnackbarHelper.showError(
          context,
          "Error exporting file: $e\nPlease try a different location or check app permissions.",
          duration: const Duration(seconds: 3),
        );
      }
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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                              "Save File As",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle.fileName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: mutedColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Folder Selection Card
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickFolder,
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
                              Icons.folder_outlined,
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
                                  "Export Location",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _filePathController.text.isEmpty 
                                    ? (Platform.isAndroid 
                                        ? "Tap the Export button to select destination folder" 
                                        : "Select folder to save the file")
                                    : _filePathController.text,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: mutedColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: mutedColor,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // File Configuration Section
              // File Name Input
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
                    labelText: 'File Name',
                    prefixIcon: Icon(
                      Icons.drive_file_rename_outline,
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

              // Custom Tag Input
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
                  controller: _customTagController,
                  decoration: InputDecoration(
                    labelText: 'Custom Tag',
                    hintText: 'MSone',
                    helperText: 'Added as .<tag>.srt to the filename',
                    prefixIcon: Icon(
                      Icons.label_outline,
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

              // Encoding Dropdown
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
                  value: _selectedEncoding,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedEncoding = newValue;
                      });
                    }
                  },
                  items: ["UTF-8", "ISO-8859-1", "ASCII"].map((String encoding) {
                    return DropdownMenuItem<String>(
                      value: encoding,
                      child: Text(encoding),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Encoding',
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
                ),
              ),
              const SizedBox(height: 20),

              // Export Options
              Container(
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Export Options",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: Text(
                        "Export original lines only",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        "Uses .original.srt extension instead of custom tag",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                      value: _exportOriginalAsWell,
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            _exportOriginalAsWell = value;
                          });
                        }
                      },
                      activeColor: primaryColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
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
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _exportSrt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.file_download, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Save As",
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
      )
    );
  }
}
