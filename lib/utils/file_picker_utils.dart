import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:subtitle_studio/utils/platform_check.dart';
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';

/// Platform-specific file picker utilities
/// 
/// This utility provides a unified interface for file and folder picking across different platforms:
/// - Android: Uses Storage Access Framework (SAF) for secure file access
/// - Windows, Linux, macOS: Uses file_picker for traditional desktop experience
/// - iOS: Uses file_picker for native iOS file access
class FilePicker {
  
  /// Pick a single file with platform-specific implementation
  /// 
  /// [context] - BuildContext for navigation and theming
  /// [title] - Title shown in the picker dialog
  /// [allowedExtensions] - List of allowed file extensions (e.g., ['.srt', '.txt'])
  /// [pickText] - Text shown on the pick/select button
  /// 
  /// Returns the selected file path or null if cancelled
  static Future<String?> pickFile({
    required BuildContext context,
    required String title,
    List<String>? allowedExtensions,
    String? pickText,
  }) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _pickFileDesktop(
        title: title,
        allowedExtensions: allowedExtensions,
      );
    } else {
      // Android and iOS - use filesystem_picker
      return _pickFileMobile(
        context: context,
        title: title,
        allowedExtensions: allowedExtensions,
        pickText: pickText ?? 'Select File',
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
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _pickFolderDesktop(title: title);
    } else {
      // Android and iOS - use filesystem_picker
      return _pickFolderMobile(
        context: context,
        title: title,
        pickText: pickText ?? 'Select Folder',
      );
    }
  }

  /// Desktop file picker implementation using file_picker package
  static Future<String?> _pickFileDesktop({
    required String title,
    List<String>? allowedExtensions,
  }) async {
    try {
      // Convert extensions from ['.srt'] format to ['srt'] format
      List<String>? extensions;
      if (allowedExtensions != null) {
        extensions = allowedExtensions
            .map((ext) => ext.startsWith('.') ? ext.substring(1) : ext)
            .toList();
      }

      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: extensions != null ? fp.FileType.custom : fp.FileType.any,
        allowedExtensions: extensions,
        dialogTitle: title,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path!;
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
      String? selectedDirectory = await fp.FilePicker.platform.getDirectoryPath(
        dialogTitle: title,
      );
      return selectedDirectory;
    } catch (e) {
      debugPrint('Error picking folder on desktop: $e');
      return null;
    }
  }

  /// Mobile file picker implementation using filesystem_picker
  static Future<String?> _pickFileMobile({
    required BuildContext context,
    required String title,
    List<String>? allowedExtensions,
    required String pickText,
  }) async {
    try {
      // Request storage permissions before accessing file system
      final hasPermission = await requestStoragePermissions();
      
      if (!hasPermission) {
        if (!context.mounted) return null;
        
        SnackbarHelper.showError(
          context,
          'Storage permission is required to select files. Please grant permission in app settings.',
          duration: const Duration(seconds: 4),
        );
        return null;
      }

      final rootDir = await getDefaultRootDirectory();
      if (!context.mounted) return null;

      return await _showSafeFilesystemPicker(
        context: context,
        rootDirectory: rootDir,
        fsType: FilesystemType.file,
        title: title,
        pickText: pickText,
        allowedExtensions: allowedExtensions,
        fileTileSelectMode: FileTileSelectMode.wholeTile,
      );
    } catch (e) {
      debugPrint('Error picking file on mobile: $e');
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Error selecting file: $e');
      }
      return null;
    }
  }

  /// Mobile folder picker implementation using filesystem_picker
  static Future<String?> _pickFolderMobile({
    required BuildContext context,
    required String title,
    required String pickText,
  }) async {
    try {
      // Request storage permissions before accessing file system
      final hasPermission = await requestStoragePermissions();
      
      if (!hasPermission) {
        if (!context.mounted) return null;
        
        SnackbarHelper.showError(
          context,
          'Storage permission is required to select folders. Please grant permission in app settings.',
          duration: const Duration(seconds: 4),
        );
        return null;
      }

      final rootDir = await getDefaultRootDirectory();
      if (!context.mounted) return null;

      return await _showSafeFilesystemPicker(
        context: context,
        rootDirectory: rootDir,
        fsType: FilesystemType.folder,
        title: title,
        pickText: pickText,
      );
    } catch (e) {
      debugPrint('Error picking folder on mobile: $e');
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Error selecting folder: $e');
      }
      return null;
    }
  }

  /// Show filesystem picker with proper SafeArea handling (for mobile platforms)
  static Future<String?> _showSafeFilesystemPicker({
    required BuildContext context,
    required Directory rootDirectory,
    required FilesystemType fsType,
    required String title,
    required String pickText,
    List<String>? allowedExtensions,
    FileTileSelectMode? fileTileSelectMode,
  }) async {
    // Use Navigator.push to show a full-screen route with SafeArea
    return await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (BuildContext routeContext) {
          return Scaffold(
            body: SafeArea(
              child: FilesystemPicker(
                title: title,
                rootDirectory: rootDirectory,
                fsType: fsType,
                pickText: pickText,
                folderIconColor: Theme.of(context).primaryColor,
                allowedExtensions: allowedExtensions,
                fileTileSelectMode: fileTileSelectMode,
                onSelect: (String path) {
                  Navigator.pop(routeContext, path);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Convenience methods for common file picking scenarios
class FilePickerConvenience {
  
  /// Pick an SRT subtitle file
  static Future<String?> pickSrtFile({
    required BuildContext context,
    String title = 'Select SRT File',
    String pickText = 'Select SRT File',
  }) async {
    return FilePicker.pickFile(
      context: context,
      title: title,
      allowedExtensions: ['.srt'],
      pickText: pickText,
    );
  }

  /// Pick a video file
  static Future<String?> pickVideoFile({
    required BuildContext context,
    String title = 'Pick a Video File',
    String pickText = 'Select Video File',
  }) async {
    return FilePicker.pickFile(
      context: context,
      title: title,
      allowedExtensions: ['.mp4', '.mkv', '.avi'],
      pickText: pickText,
    );
  }

  /// Pick an export folder
  static Future<String?> pickExportFolder({
    required BuildContext context,
    String title = 'Select Export Folder',
    String pickText = 'Select this folder',
  }) async {
    return FilePicker.pickFolder(
      context: context,
      title: title,
      pickText: pickText,
    );
  }

  /// Save file using platform-appropriate method
  static Future<String?> saveFile({
    required BuildContext context,
    required String content,
    required String fileName,
    String mimeType = 'text/plain',
  }) async {
    if (Platform.isAndroid) {
      // Use SAF on Android for direct save
      final result = await PlatformFileHandler.saveNewFile(
        content: content,
        fileName: fileName,
        mimeType: mimeType,
      );
      return result?.path; // Return path if successful
    } else {
      // For desktop platforms, this would require a save dialog
      // For now, return null to indicate unsupported
      return null;
    }
  }
}
