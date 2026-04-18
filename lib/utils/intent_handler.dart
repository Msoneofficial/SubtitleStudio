import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

/// Information about a file opened via intent
class IntentFileInfo {
  final String path;          // Display path or temp file path
  final String? safUri;       // Original SAF URI if available
  final bool isContentUri;    // Whether the original was a content URI
  final String originalPath;  // Original path from intent
  
  const IntentFileInfo({
    required this.path,
    this.safUri,
    required this.isContentUri,
    required this.originalPath,
  });
}

/// Information about an intent with action and file details
class IntentActionInfo {
  final String path;          // File path
  final String action;        // Action: 'import' or 'source_view'
  final String? safUri;       // Original SAF URI if available
  final bool isContentUri;    // Whether the original was a content URI
  
  const IntentActionInfo({
    required this.path,
    required this.action,
    this.safUri,
    required this.isContentUri,
  });
}

/// Intent handling utility for opening files from external sources
/// 
/// This class now provides enhanced support for SAF URIs to work better with
/// the new storage system. Key improvements:
/// 
/// - IntentFileInfo preserves both display paths and SAF URIs
/// - Better integration with database originalFileUri storage
/// - Support for reading content directly from SAF URIs
/// - Maintains backward compatibility with existing code
class IntentHandler {
  static const MethodChannel _channel = MethodChannel('org.malayalamsubtitles.studio/intent');

  /// Get the initial intent data (file path) when app was opened from external source
  static Future<String?> getInitialIntentData() async {
    // On Windows and other desktop platforms, command line arguments are handled in main()
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return null; // Command line args are handled in main.dart
    }
    
    // Android intent handling
    try {
      final String? result = await _channel.invokeMethod('getInitialIntentData');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to get initial intent data: '${e.message}'.");
      }
      return null;
    }
  }

  /// Read file content from content URI and save to temporary file
  /// This is Android-specific functionality
  static Future<String?> handleContentUri(String contentUri) async {
    // Only available on Android
    if (!Platform.isAndroid) {
      if (kDebugMode) {
        print("handleContentUri is only available on Android platform");
      }
      return null;
    }
    
    try {
      final Uint8List? fileBytes = await _channel.invokeMethod('readFileFromContentUri', {'uri': contentUri});
      
      if (fileBytes != null) {
        // Create a temporary file
        final tempDir = await getTemporaryDirectory();
        final fileName = _extractFileNameFromUri(contentUri);
        final tempFile = File('${tempDir.path}/$fileName');
        
        // Write the content to temporary file
        await tempFile.writeAsBytes(fileBytes);
        return tempFile.path;
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to read content from URI: '${e.message}'.");
      }
    }
    return null;
  }

  /// Extract filename from content URI
  static String _extractFileNameFromUri(String uri) {
    // Try to extract filename from URI
    final decoded = Uri.decodeFull(uri);
    final parts = decoded.split('/');
    for (int i = parts.length - 1; i >= 0; i--) {
      if (parts[i].contains('.srt') || parts[i].contains('.msone')) {
        // Clean up the filename
        String filename = parts[i];
        
        // Handle URL encoding like %3A (colon)
        if (filename.contains('%3A')) {
          filename = filename.split('%3A').last;
        }
        if (filename.contains(':')) {
          filename = filename.split(':').last;
        }
        
        // Handle other common URL encodings
        filename = Uri.decodeFull(filename);
        
        // Remove any remaining path separators or special characters
        filename = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        
        return filename.isNotEmpty ? filename : (parts[i].contains('.msone') ? 'imported_project.msone' : 'imported_subtitle.srt');
      }
    }
    
    // If no extension found, try to extract from the last part anyway
    if (parts.isNotEmpty) {
      String lastPart = Uri.decodeFull(parts.last);
      if (lastPart.contains('%3A')) {
        lastPart = lastPart.split('%3A').last;
      }
      if (lastPart.contains(':')) {
        lastPart = lastPart.split(':').last;
      }
      lastPart = lastPart.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      
      // Add appropriate extension if missing
      if (uri.toLowerCase().contains('msone')) {
        return lastPart.endsWith('.msone') ? lastPart : '$lastPart.msone';
      } else {
        return lastPart.endsWith('.srt') ? lastPart : '$lastPart.srt';
      }
    }
    
    return uri.toLowerCase().contains('msone') ? 'imported_project.msone' : 'imported_subtitle_${DateTime.now().millisecondsSinceEpoch}.srt';
  }

  /// Check if the given path is a valid SRT file
  static bool isSrtFile(String? path) {
    if (path == null) return false;
    final lowercasePath = path.toLowerCase();
    return lowercasePath.endsWith('.srt') || 
           lowercasePath.endsWith('.ass') || 
           lowercasePath.endsWith('.vtt') || 
           lowercasePath.contains('.srt') ||
           lowercasePath.contains('.ass') ||
           lowercasePath.contains('.vtt');
  }

  /// Check if the given path is a valid MSone project file
  static bool isMsoneFile(String? path) {
    if (path == null) return false;
    return path.toLowerCase().endsWith('.msone') || path.toLowerCase().contains('.msone');
  }

  /// Check if we should use SAF for the given file info
  /// This helps determine the appropriate file handling approach
  static bool shouldUseSaf(IntentFileInfo fileInfo) {
    return Platform.isAndroid && fileInfo.isContentUri && fileInfo.safUri != null;
  }

  /// Create IntentFileInfo from a regular file path
  /// Useful for converting existing file paths to the new system
  static IntentFileInfo fromFilePath(String filePath) {
    return IntentFileInfo(
      path: filePath,
      safUri: isContentUri(filePath) ? filePath : null,
      isContentUri: isContentUri(filePath),
      originalPath: filePath,
    );
  }

  /// Check if the path is a content URI
  static bool isContentUri(String? path) {
    if (path == null) return false;
    return path.startsWith('content://');
  }

  /// Extract filename from a file path or content URI
  static String getFileName(String path) {
    if (Platform.isAndroid && isContentUri(path)) {
      return _extractFileNameFromUri(path);
    }
    
    // Handle both forward slashes and backslashes for cross-platform compatibility
    // Try backslash first (Windows), then forward slash (Unix/Android)
    final backslashIndex = path.lastIndexOf('\\');
    final forwardSlashIndex = path.lastIndexOf('/');
    
    // Use the last occurring separator
    final lastSeparatorIndex = backslashIndex > forwardSlashIndex ? backslashIndex : forwardSlashIndex;
    
    if (lastSeparatorIndex >= 0) {
      return path.substring(lastSeparatorIndex + 1);
    }
    
    // If no separators found, return the whole path
    return path;
  }

  /// Process file path and return comprehensive file information
  /// This method preserves SAF URIs when possible for better integration
  /// with the database and file management system
  static Future<IntentFileInfo?> processFileWithInfo(String path) async {
    if (Platform.isAndroid && isContentUri(path)) {
      // For content URIs, preserve the original URI and create temp file if needed
      try {
        // Try to create temp file for content access
        final tempPath = await handleContentUri(path);
        
        return IntentFileInfo(
          path: tempPath ?? path,
          safUri: path,  // Preserve original content URI
          isContentUri: true,
          originalPath: path,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error processing content URI: $e');
        }
        // Return with original path if temp file creation fails
        return IntentFileInfo(
          path: path,
          safUri: path,
          isContentUri: true,
          originalPath: path,
        );
      }
    } else {
      // For regular file paths
      return IntentFileInfo(
        path: path,
        safUri: null,
        isContentUri: false,
        originalPath: path,
      );
    }
  }

  /// Get enhanced intent data with action information
  /// Returns IntentActionInfo with path, action, and SAF URI when available
  static Future<IntentActionInfo?> getInitialIntentDataWithAction() async {
    final intentData = await getInitialIntentData();
    if (intentData == null) return null;

    try {
      // Try to parse as JSON first (new format)
      final jsonData = jsonDecode(intentData);
      final path = jsonData['path'] as String;
      final action = jsonData['action'] as String;
      
      // Process the file to get proper file info
      final fileInfo = await processFileWithInfo(path);
      if (fileInfo != null) {
        return IntentActionInfo(
          path: fileInfo.path,
          action: action,
          safUri: fileInfo.safUri,
          isContentUri: fileInfo.isContentUri,
        );
      }
    } catch (e) {
      // Not JSON, treat as legacy format (plain file path)
      final fileInfo = await processFileWithInfo(intentData);
      if (fileInfo != null) {
        return IntentActionInfo(
          path: fileInfo.path,
          action: 'import', // Default action for legacy format
          safUri: fileInfo.safUri,
          isContentUri: fileInfo.isContentUri,
        );
      }
    }
    
    return null;
  }

  /// Get comprehensive intent data with SAF URI preservation
  /// Returns IntentFileInfo with both display path and SAF URI when available
  static Future<IntentFileInfo?> getInitialIntentDataWithInfo() async {
    final intentData = await getInitialIntentData();
    if (intentData != null) {
      return await processFileWithInfo(intentData);
    }
    return null;
  }

  /// Process file path - convert content URI to temp file if needed
  /// This is primarily for Android content URIs
  static Future<String?> processFilePath(String path) async {
    if (Platform.isAndroid && isContentUri(path)) {
      return await handleContentUri(path);
    }
    return path;
  }

  /// Read content from IntentFileInfo 
  /// This method knows whether to use SAF URI or file path for content reading
  static Future<String> readContentFromIntentFile(IntentFileInfo fileInfo) async {
    if (fileInfo.isContentUri && fileInfo.safUri != null && Platform.isAndroid) {
      // Use SAF URI for content reading to maintain permissions
      return await readContentFromUri(fileInfo.safUri!);
    } else {
      // Use regular file reading for local files or when temp file exists
      final file = File(fileInfo.path);
      return await file.readAsString();
    }
  }

  /// Get the appropriate originalFileUri for database storage
  /// Returns the SAF URI if available, otherwise the file path
  static String getOriginalFileUri(IntentFileInfo fileInfo) {
    if (fileInfo.isContentUri && fileInfo.safUri != null) {
      return fileInfo.safUri!;  // Use SAF URI for database storage
    } else {
      return fileInfo.path;     // Use file path for local files
    }
  }

  /// Get display path from SAF URI for better user experience
  /// Converts content URIs to readable storage paths like "/storage/emulated/0/..."
  /// 
  /// Example:
  /// Input:  content://com.android.externalstorage.documents/document/primary%3ADownload%2FSub%2FMystic%20River%202003.Msone.srt
  /// Output: /storage/emulated/0/Download/Sub/Mystic River 2003.Msone.srt
  static String getDisplayPathFromSafUri(String safUri) {
    if (!Platform.isAndroid || !isContentUri(safUri)) {
      return safUri; // Return as-is for non-content URIs
    }
    
    try {
      if (kDebugMode) {
        print('Converting SAF URI to display path: $safUri');
      }
      
      // Decode the URI to get readable components
      final decoded = Uri.decodeFull(safUri);
      
      if (kDebugMode) {
        print('Decoded URI: $decoded');
      }
      
      // Extract the path component for external storage documents
      if (decoded.contains('com.android.externalstorage.documents')) {
        // Pattern: content://com.android.externalstorage.documents/document/primary%3ADownload%2FSub%2Ffile.srt
        final parts = decoded.split('/');
        
        // Find the document part
        for (int i = 0; i < parts.length; i++) {
          if (parts[i] == 'document' && i + 1 < parts.length) {
            String documentPart = parts[i + 1];
            
            if (kDebugMode) {
              print('Document part: $documentPart');
            }
            
            // Handle primary storage
            if (documentPart.startsWith('primary:')) {
              String relativePath = documentPart.substring(8); // Remove 'primary:'
              
              if (kDebugMode) {
                print('Relative path before decoding: $relativePath');
              }
              
              // Comprehensive URL decoding (this should handle all encodings)
              relativePath = Uri.decodeFull(relativePath);
              
              if (kDebugMode) {
                print('Relative path after decoding: $relativePath');
              }
              
              String finalPath = '/storage/emulated/0/$relativePath';
              
              if (kDebugMode) {
                print('Final display path: $finalPath');
              }
              
              return finalPath;
            }
            
            // Handle other storage locations
            if (documentPart.contains(':')) {
              int colonIndex = documentPart.indexOf(':');
              if (colonIndex != -1 && colonIndex < documentPart.length - 1) {
                String storage = documentPart.substring(0, colonIndex);
                String relativePath = documentPart.substring(colonIndex + 1);
                
                if (kDebugMode) {
                  print('Storage: $storage, Relative path before decoding: $relativePath');
                }
                
                // Comprehensive URL decoding
                relativePath = Uri.decodeFull(relativePath); // Decode all URL encodings at once
                
                String finalPath = '/storage/$storage/$relativePath';
                
                if (kDebugMode) {
                  print('Final display path (other storage): $finalPath');
                }
                
                return finalPath;
              }
            }
            break;
          }
        }
      }
      
      // For other document providers, fall back to filename extraction
      final fileName = _extractFileNameFromUri(safUri);
      String fallbackPath = '/storage/emulated/0/Download/$fileName'; // Default assumption for downloads
      
      if (kDebugMode) {
        print('Using fallback path (other document provider): $fallbackPath');
      }
      
      return fallbackPath;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing SAF URI for display path: $e');
      }
      // Fallback: extract filename and assume Downloads folder
      final fileName = _extractFileNameFromUri(safUri);
      String errorFallbackPath = '/storage/emulated/0/Download/$fileName';
      
      if (kDebugMode) {
        print('Using error fallback path: $errorFallbackPath');
      }
      
      return errorFallbackPath;
    }
  }

  /// Read file content directly from content URI as string
  /// This is Android-specific functionality for SAF compatibility
  static Future<String> readContentFromUri(String contentUri) async {
    // Only available on Android
    if (!Platform.isAndroid) {
      throw UnsupportedError("readContentFromUri is only available on Android platform");
    }
    
    try {
      final Uint8List? fileBytes = await _channel.invokeMethod('readFileFromContentUri', {'uri': contentUri});
      
      if (fileBytes != null) {
        // Convert bytes to string using proper UTF-8 decoding
        // This correctly handles multi-byte Unicode characters
        try {
          return utf8.decode(fileBytes);
        } catch (e) {
          // If UTF-8 decoding fails, try Latin-1 as fallback
          // Latin-1 preserves all byte values as characters
          if (kDebugMode) {
            print('UTF-8 decoding failed, using Latin-1 fallback: $e');
          }
          return latin1.decode(fileBytes);
        }
      } else {
        throw Exception('Failed to read file content from URI: No data received');
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to read content from URI: '${e.message}'.");
      }
      throw Exception('Failed to read content from URI: ${e.message}');
    }
  }

  /// Get file descriptor path for large files (Android only)
  /// This allows FFmpeg to work with large video files without loading them into memory
  static Future<String?> getFileDescriptorPath(String contentUri) async {
    // Only available on Android
    if (!Platform.isAndroid) {
      throw UnsupportedError("getFileDescriptorPath is only available on Android platform");
    }
    
    try {
      final String? fdPath = await _channel.invokeMethod('getFileDescriptorPath', {'uri': contentUri});
      return fdPath;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to get file descriptor path: '${e.message}'.");
      }
      return null;
    }
  }

  /// Test method to verify display path conversion (debug only)
  /// This method can be called to test URI conversion without actual file access
  static void testDisplayPathConversion() {
    if (!kDebugMode) return; // Only run in debug mode
    
    // Test cases
    final testUris = [
      'content://com.android.externalstorage.documents/document/primary%3ADownload%2FSub%2FMystic%20River%202003.Msone.srt',
      'content://com.android.externalstorage.documents/document/primary%3ADownload%2Ftest%20file.srt',
      'content://com.android.externalstorage.documents/document/primary%3ADocuments%2Fsubtitle.srt',
    ];
    
    print('=== Testing Display Path Conversion ===');
    for (String uri in testUris) {
      print('Input URI: $uri');
      String result = getDisplayPathFromSafUri(uri);
      print('Output Path: $result');
      print('---');
    }
    print('=== End Test ===');
  }
}
