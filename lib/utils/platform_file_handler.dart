import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'saf_file_handler.dart';
import 'saf_path_converter.dart';

/// Platform-aware file handler that uses SAF on Android and direct file access on other platforms
/// 
/// This class provides a unified interface for file operations across platforms:
/// - Android: Uses Storage Access Framework (SAF) without MANAGE_EXTERNAL_STORAGE permission
/// - Other platforms: Uses traditional file system access
class PlatformFileHandler {
  
  /// Read a file from the file system
  /// 
  /// On Android: Uses SAF to open a file picker and read the selected file
  /// On other platforms: Reads directly from the file path
  /// 
  /// [filePath] - On non-Android platforms, the file path to read
  /// [mimeTypes] - On Android, MIME types to filter in the file picker
  /// 
  /// Returns a [PlatformFileInfo] object with file content and metadata
  static Future<PlatformFileInfo?> readFile({
    String? filePath,
    List<String>? mimeTypes,
  }) async {
    if (Platform.isAndroid) {
      // Use SAF on Android
      final safInfo = await SafFileHandler.openFile(
        mimeTypes: mimeTypes ?? _getDefaultMimeTypes(),
      );
      
      if (safInfo != null) {
        // Load content from URI (openFile now returns URI-only for memory safety)
        final content = await SafFileHandler.readFileFromUri(safInfo.uri);
        
        // Fix the display path using proper SAF URI conversion
        final correctedPath = SafPathConverter.normalizePath(safInfo.uri);
        
        return PlatformFileInfo(
          path: correctedPath, // Use corrected path instead of safInfo.displayPath
          content: content,
          isFromSaf: true,
          safUri: safInfo.uri,
        );
      }
      return null;
    } else {
      // Use direct file access on other platforms
      if (filePath == null) {
        throw ArgumentError('filePath is required on non-Android platforms');
      }
      
      try {
        final file = File(filePath);
        if (!await file.exists()) {
          return null;
        }
        
        final content = await file.readAsBytes();
        return PlatformFileInfo(
          path: filePath,
          content: content,
          isFromSaf: false,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error reading file: $e');
        }
        return null;
      }
    }
  }
  
  /// Write content to a file
  /// 
  /// On Android: Uses SAF to save the file (either to existing or new location)
  /// On other platforms: Writes directly to the file path
  /// 
  /// [content] - The content to write (as string)
  /// [filePath] - The target file path or SAF URI
  /// [fileName] - Suggested filename for new files (Android SAF)
  /// [mimeType] - MIME type for the file
  /// 
  /// Returns true if the write was successful
  static Future<bool> writeFile({
    required String content,
    required String filePath,
    String? fileName,
    String mimeType = 'text/plain',
  }) async {
    final contentBytes = Uint8List.fromList(utf8.encode(content));
    
    if (Platform.isAndroid) {
      // Use SAF on Android
      try {
        // Check if filePath is a SAF URI (content://)
        if (filePath.startsWith('content://')) {
          // Write directly to the SAF URI
          return await _writeSafUri(filePath, contentBytes);
        } else {
          // Use the regular SAF save mechanism
          final safInfo = await SafFileHandler.saveFile(
            filePath: filePath,
            content: contentBytes,
            mimeType: mimeType,
          );
          
          return safInfo != null;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error writing file with SAF: $e');
        }
        return false;
      }
    } else if (Platform.isIOS) {
      // On iOS, we cannot write to arbitrary file paths due to sandbox restrictions
      // The file picker returns a path, but we don't have write access to it
      if (kDebugMode) {
        print('iOS: Cannot write to arbitrary file path due to sandbox restrictions: $filePath');
      }
      return false;
    } else {
      // Use direct file access on desktop platforms (Windows, Linux, macOS)
      try {
        final file = File(filePath);
        
        // Ensure parent directory exists
        final parentDir = file.parent;
        if (!await parentDir.exists()) {
          if (kDebugMode) {
            print('Creating parent directory: ${parentDir.path}');
          }
          await parentDir.create(recursive: true);
        }
        
        // Write the file
        await file.writeAsBytes(contentBytes);
        
        if (kDebugMode) {
          print('Successfully wrote file: $filePath (${contentBytes.length} bytes)');
        }
        
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('Error writing file to $filePath: $e');
          print('Stack trace: ${StackTrace.current}');
        }
        return false;
      }
    }
  }

  /// Write content directly to a SAF URI (Android only)
  static Future<bool> _writeSafUri(String safUri, Uint8List content) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('SAF URI writing is only supported on Android');
    }
    
    try {
      // Use the SAF method channel directly to write to the URI
      final success = await SafFileHandler.writeSafUri(safUri, content);
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error writing to SAF URI: $e');
      }
      return false;
    }
  }
  
  /// Save a new file with a save dialog
  /// 
  /// On Android: Uses SAF ACTION_CREATE_DOCUMENT
  /// On other platforms: This method is not implemented (use writeFile instead)
  /// 
  /// [content] - The content to save
  /// [fileName] - Suggested filename
  /// [mimeType] - MIME type for the file
  /// 
  /// Returns a [PlatformFileInfo] object if successful
  static Future<PlatformFileInfo?> saveNewFile({
    required String content,
    required String fileName,
    String mimeType = 'text/plain',
  }) async {
    if (Platform.isAndroid) {
      final contentBytes = Uint8List.fromList(utf8.encode(content));
      
      try {
        final safInfo = await SafFileHandler.saveNewFile(
          content: contentBytes,
          fileName: fileName,
          mimeType: mimeType,
        );
        
        if (safInfo != null) {
          // Fix the display path using proper SAF URI conversion
          final correctedPath = SafPathConverter.normalizePath(safInfo.uri);
          
          if (kDebugMode) {
            print('PlatformFileHandler saveNewFile: originalPath=${safInfo.displayPath}, correctedPath=$correctedPath, uri=${safInfo.uri}');
          }
          
          return PlatformFileInfo(
            path: correctedPath, // Use corrected path
            content: contentBytes, // Return the content we just saved
            isFromSaf: true,
            safUri: safInfo.uri,
          );
        }
        return null;
      } catch (e) {
        if (kDebugMode) {
          print('Error saving new file with SAF: $e');
        }
        return null;
      }
    } else {
      throw UnsupportedError('saveNewFile is only supported on Android. Use writeFile on other platforms.');
    }
  }
  
  /// Check if a file exists
  /// 
  /// On Android: Checks if the file path has a cached SAF URI
  /// On other platforms: Checks if the file exists on the file system
  static Future<bool> fileExists(String filePath) async {
    if (Platform.isAndroid) {
      return SafFileHandler.hasFileOpen(filePath);
    } else {
      try {
        final file = File(filePath);
        return await file.exists();
      } catch (e) {
        return false;
      }
    }
  }
  
  /// Get the default MIME types for subtitle files
  static List<String> _getDefaultMimeTypes() {
    return [
      'text/plain',
      'application/x-subrip',
      'text/vtt',
      'application/json',
      'application/octet-stream', // For .msone files
      '*/*', // Allow all files as fallback
    ];
  }
  
  /// Clear any cached file URIs (Android only)
  static void clearCache() {
    if (Platform.isAndroid) {
      SafFileHandler.clearCache();
    }
  }
  
  /// Get all cached file paths (Android only)
  static List<String> getCachedFilePaths() {
    if (Platform.isAndroid) {
      return SafFileHandler.getCachedFilePaths();
    }
    return [];
  }
}

/// Information about a file accessed through the platform file handler
class PlatformFileInfo {
  /// The file path (or display path for SAF)
  final String path;
  
  /// The file content as bytes
  final Uint8List content;
  
  /// Whether this file was accessed through SAF
  final bool isFromSaf;
  
  /// The SAF URI (only available if isFromSaf is true)
  final String? safUri;
  
  const PlatformFileInfo({
    required this.path,
    required this.content,
    required this.isFromSaf,
    this.safUri,
  });
  
  /// Get the file content as a UTF-8 string
  String get contentAsString => utf8.decode(content);
  
  /// Get the filename from the path
  String get fileName {
    // Handle both forward slashes and backslashes for cross-platform compatibility
    final String filePath = path;
    
    // Try backslash first (Windows), then forward slash (Unix/Android)
    final backslashIndex = filePath.lastIndexOf('\\');
    final forwardSlashIndex = filePath.lastIndexOf('/');
    
    // Use the last occurring separator
    final lastSeparatorIndex = backslashIndex > forwardSlashIndex ? backslashIndex : forwardSlashIndex;
    
    if (lastSeparatorIndex >= 0) {
      return filePath.substring(lastSeparatorIndex + 1);
    }
    
    // If no separators found, return the whole path
    return filePath;
  }
  
  /// Check if this is a subtitle file based on extension
  bool get isSubtitleFile {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.srt') || 
           lowerPath.endsWith('.vtt') || 
           lowerPath.endsWith('.ass') || 
           lowerPath.endsWith('.ssa');
  }
  
  /// Check if this is an MSone project file
  bool get isMsoneFile {
    return path.toLowerCase().endsWith('.msone');
  }
  
  @override
  String toString() => 'PlatformFileInfo(path: $path, size: ${content.length} bytes, fromSaf: $isFromSaf)';
}
