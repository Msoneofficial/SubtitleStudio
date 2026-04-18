import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'package:subtitle_studio/utils/saf_file_handler.dart';
import 'package:subtitle_studio/utils/saf_path_converter.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';

/// Platform-specific file picker utilities using SAF on Android
/// 
/// This utility provides a unified interface for file and folder picking across different platforms:
/// - Android: Uses Storage Access Framework (SAF) for secure file access
/// - Windows, Linux, macOS: Uses file_picker for traditional desktop experience
/// - iOS: Uses file_picker for native iOS file access
class FilePickerSAF {
  static String? _lastUsedDirectory;

  // Add this initialization method
  static Future<void> _initLastUsedDirectory() async {
    if (_lastUsedDirectory == null) {
      _lastUsedDirectory = await PreferencesModel.getLastUsedDirectory();
    }
  }
  
  /// Pick a single file with platform-specific implementation
  /// 
  /// [context] - BuildContext for navigation and theming
  /// [title] - Title shown in the picker dialog (desktop only)
  /// [allowedExtensions] - List of allowed file extensions (e.g., ['.srt', '.txt'])
  /// [pickText] - Text shown on the pick/select button (not used on Android SAF)
  /// 
  /// Returns the selected file path or null if cancelled
  static Future<String?> pickFile({
    required BuildContext context,
    required String title,
    List<String>? allowedExtensions,
    String? pickText,
  }) async {
    if (Platform.isAndroid) {
      // Use SAF on Android
      return _pickFileAndroid(
        context: context,
        allowedExtensions: allowedExtensions,
      );
    } else {
      // Desktop and iOS - use file_picker
      return _pickFileDesktop(
        title: title,
        allowedExtensions: allowedExtensions,
      );
    }
  }

  /// Pick a folder with platform-specific implementation
  /// 
  /// [context] - BuildContext for navigation and theming
  /// [title] - Title shown in the picker dialog
  /// [pickText] - Text shown on the pick/select button
  /// 
  /// Returns the selected folder path or null if cancelled
  static Future<String?> pickFolder({
    required BuildContext context,
    required String title,
    String? pickText,
  }) async {
    if (Platform.isAndroid) {
      // On Android with SAF, we can't pick folders directly
      // Users save individual files instead
      if (context.mounted) {
        SnackbarHelper.showSnackBar(
          context,
          'On Android, files are saved individually using the system save dialog.',
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        );
      }
      return null;
    } else {
      // Desktop and iOS - use file_picker
      return _pickFolderDesktop(title: title);
    }
  }

  /// Pick a single file with URI-only mode (no content reading)
  /// This is useful for large files like videos to avoid OutOfMemoryError
  /// 
  /// [context] - BuildContext for navigation and theming
  /// [title] - Title shown in the picker dialog (desktop only)
  /// [allowedExtensions] - List of allowed file extensions (e.g., ['.mp4', '.mkv'])
  /// [pickText] - Text shown on the pick/select button (not used on Android SAF)
  /// 
  /// Returns a SafFileInfo object with URI and display path (content will be null)
  static Future<SafFileInfo?> pickFileUriOnly({
    required BuildContext context,
    required String title,
    List<String>? allowedExtensions,
    String? pickText,
  }) async {
    if (Platform.isAndroid) {
      // Use SAF URI-only mode on Android
      return _pickFileUriOnlyAndroid(
        context: context,
        allowedExtensions: allowedExtensions,
      );
    } else {
      // Desktop and iOS - fall back to regular file picker and return SafFileInfo
      final path = await _pickFileDesktop(
        title: title,
        allowedExtensions: allowedExtensions,
      );
      if (path != null) {
        // For desktop, we can return the path as both URI and displayPath
        return SafFileInfo(
          uri: path,
          displayPath: path,
          content: null,
        );
      }
      return null;
    }
  }

  /// Pick a file with both display path and SAF URI information
  /// This is useful for subtitle files where we need both pieces of info
  /// 
  /// [context] - BuildContext for navigation and theming
  /// [title] - Title shown in the picker dialog (desktop only)
  /// [allowedExtensions] - List of allowed file extensions (e.g., ['.srt', '.vtt'])
  /// 
  /// Returns a Map with 'displayPath' and 'safUri' keys, or null if cancelled
  static Future<Map<String, String?>?> pickFileWithInfo({
    required BuildContext context,
    required String title,
    List<String>? allowedExtensions,
  }) async {
    if (Platform.isAndroid) {
      // Use SAF on Android
      try {
        final mimeTypes = _extensionsToMimeTypes(allowedExtensions);
        final fileInfo = await PlatformFileHandler.readFile(mimeTypes: mimeTypes);
        
        if (fileInfo != null) {
          // Fix the display path using proper SAF URI conversion
          final correctedPath = SafPathConverter.normalizePath(fileInfo.safUri ?? fileInfo.path);
          
          if (kDebugMode) {
            print('FilePickerSAF pickFileWithInfo: originalPath=${fileInfo.path}, correctedPath=$correctedPath, safUri=${fileInfo.safUri}');
          }
          return {
            'displayPath': correctedPath, // Use corrected path
            'safUri': fileInfo.safUri,
            'content': fileInfo.contentAsString, // Include the content to avoid double reading
          };
        }
        return null;
      } catch (e) {
        if (context.mounted) {
          SnackbarHelper.showError(context, 'Error selecting file: $e');
        }
        return null;
      }
    } else {
      // Desktop and iOS - use file_picker
      final path = await _pickFileDesktop(
        title: title,
        allowedExtensions: allowedExtensions,
      );
      if (path != null) {
        // Read content for desktop
        try {
          final file = File(path);
          final content = await file.readAsString();
          return {
            'displayPath': path,
            'safUri': null, // No SAF URI on desktop
            'content': content,
          };
        } catch (e) {
          if (context.mounted) {
            SnackbarHelper.showError(context, 'Error reading file: $e');
          }
          return null;
        }
      }
      return null;
    }
  }

  /// Android SAF file picker implementation
  static Future<String?> _pickFileAndroid({
    required BuildContext context,
    List<String>? allowedExtensions,
  }) async {
    try {
      // Convert file extensions to MIME types for SAF
      final mimeTypes = _extensionsToMimeTypes(allowedExtensions);
      
      final fileInfo = await PlatformFileHandler.readFile(mimeTypes: mimeTypes);
      
      if (fileInfo != null) {
        // For Android SAF, we return the corrected display path for UI purposes
        // The SAF URI will be handled separately in the import process
        final correctedPath = SafPathConverter.normalizePath(fileInfo.safUri ?? fileInfo.path);
        
        if (kDebugMode) {
          print('FilePickerSAF Android: originalPath=${fileInfo.path}, correctedPath=$correctedPath, safUri=${fileInfo.safUri}');
        }
        return correctedPath;
      }
      
      return null;
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(
          context,
          'Error selecting file: $e',
        );
      }
      return null;
    }
  }

  /// Android SAF file picker implementation for URI-only mode (no content reading)
  static Future<SafFileInfo?> _pickFileUriOnlyAndroid({
    required BuildContext context,
    List<String>? allowedExtensions,
  }) async {
    try {
      // Convert file extensions to MIME types for SAF
      final mimeTypes = _extensionsToMimeTypes(allowedExtensions);
      
      // Use the new URI-only method to avoid reading large file content
      final fileInfo = await SafFileHandler.openFileUriOnly(
        mimeTypes: mimeTypes,
      );
      
      return fileInfo;
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(
          context,
          'Error selecting file: $e',
        );
      }
      return null;
    }
  }

  /// Desktop file picker implementation using file_picker package
  static Future<String?> _pickFileDesktop({
    required String title,
    List<String>? allowedExtensions,
  }) async {
    try {
      await _initLastUsedDirectory();

      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        dialogTitle: title,
        type: allowedExtensions != null ? fp.FileType.custom : fp.FileType.any,
        allowedExtensions: allowedExtensions?.map((e) => e.replaceFirst('.', '')).toList(),
        allowMultiple: false,
        initialDirectory: _lastUsedDirectory,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        _lastUsedDirectory = File(filePath).parent.path;
        // Save to shared preferences
        await PreferencesModel.setLastUsedDirectory(_lastUsedDirectory);
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file on desktop: $e');
      return null;
    }
  }

  /// Desktop folder picker implementation using file_picker package
  static Future<String?> _pickFolderDesktop({
    required String title,
  }) async {
    try {
      await _initLastUsedDirectory();

      String? selectedDirectory = await fp.FilePicker.platform.getDirectoryPath(
        dialogTitle: title,
        initialDirectory: _lastUsedDirectory,
      );

      _lastUsedDirectory = selectedDirectory;
      // Save to shared preferences
      await PreferencesModel.setLastUsedDirectory(_lastUsedDirectory);
          return selectedDirectory;
    } catch (e) {
      debugPrint('Error picking folder on desktop: $e');
      return null;
    }
  }

  /// Convert file extensions to MIME types for Android SAF
  static List<String> _extensionsToMimeTypes(List<String>? extensions) {
    if (extensions == null || extensions.isEmpty) {
      return ['*/*'];
    }

    final mimeTypes = <String>[];
    
    for (final ext in extensions) {
      final cleanExt = ext.toLowerCase().replaceFirst('.', '');
      
      switch (cleanExt) {
        case 'srt':
          mimeTypes.addAll(['application/x-subrip', 'text/plain']);
          break;
        case 'vtt':
          mimeTypes.addAll(['text/vtt', 'text/plain']);
          break;
        case 'ass':
        case 'ssa':
          mimeTypes.add('text/plain');
          break;
        case 'msone':
          mimeTypes.addAll(['application/octet-stream', 'text/plain']);
          break;
        case 'json':
          mimeTypes.addAll(['application/json', 'text/plain']);
          break;
        case 'txt':
          mimeTypes.add('text/plain');
          break;
        case 'mp4':
        case 'mkv':
        case 'avi':
        case 'mov':
        case 'm4v':
        case 'webm':
        case 'wmv':
        case 'flv':
          mimeTypes.add('video/*');
          break;
        default:
          mimeTypes.add('*/*');
          break;
      }
    }
    
    // Remove duplicates - don't add '*/*' fallback as it shows all files
    final uniqueMimeTypes = mimeTypes.toSet().toList();
    
    return uniqueMimeTypes;
  }
}

/// Convenience class for specific file operations using SAF
class FilePickerConvenience {
  
  /// Pick a subtitle file (SRT, VTT, ASS, SSA)
  static Future<String?> pickSubtitleFile({
    required BuildContext context,
  }) async {
    return FilePickerSAF.pickFile(
      context: context,
      title: 'Select Subtitle File',
      allowedExtensions: ['.srt', '.vtt', '.ass', '.ssa'], // Show all subtitle formats
      pickText: 'Select Subtitle',
    );
  }

  /// Pick a subtitle file with both display path and SAF URI information
  /// Returns a Map with 'displayPath' and 'safUri' keys, or null if cancelled
  static Future<Map<String, String?>?> pickSubtitleFileWithInfo({
    required BuildContext context,
  }) async {
    return FilePickerSAF.pickFileWithInfo(
      context: context,
      title: 'Select Subtitle File',
      allowedExtensions: ['.srt', '.vtt', '.ass', '.ssa'],
    );
  }
  
  /// Pick an MSone project file
  static Future<String?> pickMsoneFile({
    required BuildContext context,
  }) async {
    return FilePickerSAF.pickFile(
      context: context,
      title: 'Select MSone Project',
      allowedExtensions: ['.msone'], // Only show .msone files for project import
      pickText: 'Select Project',
    );
  }
  
  /// Pick a video file
  static Future<String?> pickVideoFile({
    required BuildContext context,
  }) async {
    // Use URI-only mode for video files to avoid OutOfMemoryError
    final fileInfo = await FilePickerSAF.pickFileUriOnly(
      context: context,
      title: 'Select Video File',
      allowedExtensions: ['.mp4', '.mkv', '.avi', '.mov', '.m4v', '.webm'],
      pickText: 'Select Video',
    );
    
    return fileInfo?.uri; // Return URI instead of display path for video files
  }
  
  /// Pick a video file with both URI and display name information
  static Future<Map<String, String?>?> pickVideoFileWithInfo({
    required BuildContext context,
  }) async {
    // Use URI-only mode for video files to avoid OutOfMemoryError
    final fileInfo = await FilePickerSAF.pickFileUriOnly(
      context: context,
      title: 'Select Video File',
      allowedExtensions: ['.mp4', '.mkv', '.avi', '.mov', '.m4v', '.webm'],
      pickText: 'Select Video',
    );
    
    if (fileInfo != null) {
      // Fix the display path using proper SAF URI conversion
      final correctedPath = SafPathConverter.normalizePath(fileInfo.uri);
      
      if (kDebugMode) {
        print('FilePickerConvenience pickVideoFileWithInfo: originalPath=${fileInfo.displayPath}, correctedPath=$correctedPath, uri=${fileInfo.uri}');
      }
      
      return {
        'uri': fileInfo.uri,
        'displayPath': correctedPath, // Use corrected path
        'displayName': fileInfo.fileName, // This extracts just the filename
      };
    }
    
    return null;
  }
  
  /// Pick export folder (desktop only, on Android shows explanation)
  static Future<String?> pickExportFolder({
    required BuildContext context,
  }) async {
    return FilePickerSAF.pickFolder(
      context: context,
      title: 'Select Project Directory',
      pickText: 'Select Folder',
    );
  }
  
  /// Save a file using platform-appropriate method
  static Future<String?> saveFile({
    required BuildContext context,
    required String content,
    required String fileName,
    String mimeType = 'text/plain',
    String? existingFilePath,
  }) async {
    if (Platform.isAndroid) {
      // Use SAF on Android for new file save dialog
      try {
        final fileInfo = await PlatformFileHandler.saveNewFile(
          content: content,
          fileName: fileName,
          mimeType: mimeType,
        );
        
        return fileInfo?.path;
      } catch (e) {
        if (context.mounted) {
          SnackbarHelper.showError(context, 'Error saving file: $e');
        }
        return null;
      }
    } else {
      // On desktop, calling code should handle save dialog
      // This is a placeholder for the actual implementation
      throw UnsupportedError('Desktop save dialog should be handled by calling code');
    }
  }
}
