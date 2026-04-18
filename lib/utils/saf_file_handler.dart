import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// SAF (Storage Access Framework) File Handler for Android
/// 
/// This class provides secure file operations without requiring MANAGE_EXTERNAL_STORAGE
/// permission by using Android's Storage Access Framework (SAF).
/// 
/// **Memory Safety**: All file picker operations use URI-only mode by default, preventing
/// OutOfMemoryError for files of any size. Content is loaded on-demand using [readFileFromUri].
/// 
/// Key features:
/// - Open files using ACTION_OPEN_DOCUMENT (URI-only, memory safe)
/// - Save new files using ACTION_CREATE_DOCUMENT  
/// - Save over existing files using persistent URIs
/// - Display user-friendly file paths
/// - No MANAGE_EXTERNAL_STORAGE permission required
/// - Safe for files of any size (videos, large subtitles, etc.)
class SafFileHandler {
  static const MethodChannel _channel = MethodChannel('org.malayalamsubtitles.studio/saf');
  
  /// Cache to store currently opened file URIs and their display paths
  static final Map<String, String> _openFileUris = {};
  
  /// Get the cached URI for a file path (used for saving over existing files)
  static String? getCachedUri(String filePath) {
    return _openFileUris[filePath];
  }
  
  /// Check if SAF is available (Android only)
  static bool get isAvailable => Platform.isAndroid;
  
  /// Open a file using SAF ACTION_OPEN_DOCUMENT
  /// 
  /// This launches the system file picker and allows the user to select a file.
  /// Returns a [SafFileInfo] object containing only the URI and display path.
  /// 
  /// **Memory Safe**: This method does NOT load file content into memory, preventing
  /// OutOfMemoryError for files of any size. Use [readFileFromUri] to load content
  /// only when needed.
  /// 
  /// [mimeTypes] - List of MIME types to filter (e.g., ['text/plain', 'application/json'])
  /// [initialFileName] - Optional suggested filename for the picker
  static Future<SafFileInfo?> openFile({
    List<String>? mimeTypes,
    String? initialFileName,
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    try {
      // Always use URI-only mode to prevent OutOfMemoryError
      final result = await _channel.invokeMethod('openFileUriOnly', {
        'mimeTypes': mimeTypes ?? ['*/*'],
        'initialFileName': initialFileName,
      });
      
      if (result != null) {
        final map = Map<String, dynamic>.from(result);
        final uri = map['uri'] as String;
        final displayPath = map['displayPath'] as String;
        
        // Cache the URI for future save operations
        _openFileUris[displayPath] = uri;
        
        return SafFileInfo(
          uri: uri,
          displayPath: displayPath,
          content: null, // Content not loaded - use readFileFromUri if needed
        );
      }
      
      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('SAF openFile error: ${e.message}');
      }
      rethrow;
    }
  }

  /// Open a file using SAF ACTION_OPEN_DOCUMENT (URI only, no content reading)
  /// 
  /// This launches the system file picker and allows the user to select a file.
  /// Returns a [SafFileInfo] object containing only the URI and display path.
  /// 
  /// **Note**: This method is now identical to [openFile]. Both methods use URI-only
  /// mode to prevent OutOfMemoryError. Kept for backwards compatibility.
  /// 
  /// [mimeTypes] - List of MIME types to filter (e.g., ['video/*'])
  /// [initialFileName] - Optional suggested filename for the picker
  @Deprecated('Use openFile() instead - both methods now use URI-only mode')
  static Future<SafFileInfo?> openFileUriOnly({
    List<String>? mimeTypes,
    String? initialFileName,
  }) async {
    // Delegate to openFile which now uses URI-only mode by default
    return openFile(mimeTypes: mimeTypes, initialFileName: initialFileName);
  }

  /// Create a new document using SAF ACTION_CREATE_DOCUMENT
  /// 
  /// This launches the system save dialog and allows the user to choose a location
  /// and filename for a new file. This is the "Save As..." functionality.
  /// 
  /// [fileName] - Suggested filename for the new document
  /// [mimeType] - MIME type of the file to create
  static Future<SafFileInfo?> createDocument({
    required String fileName,
    String mimeType = 'text/plain',
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    try {
      final result = await _channel.invokeMethod('createDocument', {
        'fileName': fileName,
        'mimeType': mimeType,
      });
      
      if (result != null) {
        final map = Map<String, dynamic>.from(result);
        final uri = map['uri'] as String;
        final displayPath = map['displayPath'] as String;
        
        // Cache the URI for future save operations
        _openFileUris[displayPath] = uri;
        
        return SafFileInfo(
          uri: uri,
          displayPath: displayPath,
          content: null, // New document starts empty
        );
      }
      
      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('SAF createDocument error: ${e.message}');
      }
      rethrow;
    }
  }
  
  /// Save a new file using SAF ACTION_CREATE_DOCUMENT
  /// 
  /// This launches the system save dialog and allows the user to choose a location
  /// and filename for a new file.
  /// 
  /// [content] - The file content as bytes
  /// [fileName] - Suggested filename for the save dialog
  /// [mimeType] - MIME type of the file (e.g., 'text/plain')
  static Future<SafFileInfo?> saveNewFile({
    required Uint8List content,
    required String fileName,
    String mimeType = 'text/plain',
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    try {
      final result = await _channel.invokeMethod('saveNewFile', {
        'content': content,
        'fileName': fileName,
        'mimeType': mimeType,
      });
      
      if (result != null) {
        final map = Map<String, dynamic>.from(result);
        final uri = map['uri'] as String;
        final displayPath = map['displayPath'] as String;
        
        // Cache the URI for future save operations
        _openFileUris[displayPath] = uri;
        
        return SafFileInfo(
          uri: uri,
          displayPath: displayPath,
          content: content,
        );
      }
      
      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('SAF saveNewFile error: ${e.message}');
      }
      rethrow;
    }
  }
  
  /// Save over an existing file using its cached URI
  /// 
  /// This overwrites the content of a file that was previously opened with openFile().
  /// 
  /// [filePath] - The display path returned from openFile()
  /// [content] - The new file content as bytes
  static Future<bool> saveExistingFile({
    required String filePath,
    required Uint8List content,
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    final uri = _openFileUris[filePath];
    if (uri == null) {
      throw ArgumentError('No cached URI found for file path: $filePath. '
          'File must be opened with openFile() first.');
    }
    
    try {
      final result = await _channel.invokeMethod('saveExistingFile', {
        'uri': uri,
        'content': content,
      });
      
      return result == true;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('SAF saveExistingFile error: ${e.message}');
      }
      rethrow;
    }
  }
  
  /// Write content directly to a SAF URI
  /// 
  /// This bypasses the caching mechanism and writes directly to the provided URI.
  /// Useful when you have a SAF URI from database and want to overwrite the file.
  /// 
  /// [safUri] - The SAF content URI (e.g., content://com.android.externalstorage.documents/...)
  /// [content] - The file content as bytes
  static Future<bool> writeSafUri(String safUri, Uint8List content) async {
    if (!isAvailable) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    try {
      final result = await _channel.invokeMethod('saveExistingFile', {
        'uri': safUri,
        'content': content,
      });
      
      return result == true;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('SAF writeSafUri error: ${e.message}');
      }
      rethrow;
    }
  }

  /// Save content using either existing URI or create new file
  /// 
  /// This is a convenience method that automatically chooses between saving
  /// over an existing file or creating a new one based on whether a URI is cached.
  /// 
  /// [filePath] - The display path (if saving over existing) or suggested filename
  /// [content] - The file content as bytes
  /// [mimeType] - MIME type for new files
  static Future<SafFileInfo?> saveFile({
    required String filePath,
    required Uint8List content,
    String mimeType = 'text/plain',
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    // Check if we have a cached URI for this file path
    if (_openFileUris.containsKey(filePath)) {
      final success = await saveExistingFile(
        filePath: filePath,
        content: content,
      );
      
      if (success) {
        return SafFileInfo(
          uri: _openFileUris[filePath]!,
          displayPath: filePath,
          content: content,
        );
      }
      return null;
    } else {
      // Create a new file
      return await saveNewFile(
        content: content,
        fileName: filePath.split('/').last,
        mimeType: mimeType,
      );
    }
  }
  
  /// Clear cached URIs (useful for memory management)
  static void clearCache() {
    _openFileUris.clear();
  }
  
  /// Get all cached file paths
  static List<String> getCachedFilePaths() {
    return _openFileUris.keys.toList();
  }
  
  /// Check if a file path has a cached URI
  static bool hasFileOpen(String filePath) {
    return _openFileUris.containsKey(filePath);
  }

  /// Write content to an existing SAF URI
  /// 
  /// [uri] - The SAF content URI to write to
  /// [content] - The content to write as bytes
  static Future<bool> writeFileContent({
    required String uri,
    required Uint8List content,
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    try {
      final result = await _channel.invokeMethod('saveExistingFile', {
        'uri': uri,
        'content': content,
      });
      
      return result == true;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('SAF writeFileContent error: ${e.message}');
      }
      rethrow;
    }
  }

  /// Read file content from a SAF URI
  /// 
  /// This method reads the content of a file using its SAF content URI.
  /// Useful when you have a previously saved SAF URI and need to reload the file.
  /// 
  /// **Important**: This method loads the entire file into memory. For files >10MB,
  /// consider using streaming or native file descriptor approaches.
  /// 
  /// [uri] - The SAF content URI (e.g., content://com.android.externalstorage.documents/...)
  /// 
  /// Returns the file content as bytes
  static Future<Uint8List> readFileFromUri(String uri) async {
    if (!isAvailable) {
      throw UnsupportedError('SAF is only available on Android');
    }
    
    try {
      // Use the intent channel's readFileFromContentUri method
      const intentChannel = MethodChannel('org.malayalamsubtitles.studio/intent');
      final result = await intentChannel.invokeMethod('readFileFromContentUri', {
        'uri': uri,
      });
      
      if (result != null) {
        return Uint8List.fromList(List<int>.from(result));
      } else {
        throw Exception('Failed to read file from URI: $uri');
      }
    } on PlatformException catch (e) {
      if (e.code == 'FILE_TOO_LARGE' || e.code == 'OUT_OF_MEMORY') {
        if (kDebugMode) {
          print('SAF readFileFromUri: File too large for memory');
        }
        // Re-throw with helpful message
        throw PlatformException(
          code: e.code,
          message: 'File is too large to load into memory (>10MB). Consider using a file descriptor approach for large files.',
          details: e.details,
        );
      }
      if (kDebugMode) {
        print('SAF readFileFromUri error: ${e.message}');
      }
      rethrow;
    }
  }

  /// Check if we have persistent permission for a URI
  /// This helps determine if a previously selected file is still accessible
  static Future<bool> hasUriPermission({
    required String uri,
  }) async {
    if (!isAvailable) {
      return false;
    }
    
    try {
      final result = await _channel.invokeMethod('hasUriPermission', {
        'uri': uri,
      });
      
      return result == true;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('SAF hasUriPermission error: ${e.message}');
      }
      return false;
    }
  }

  /// Release persistent permission for a URI
  /// Call this when you no longer need access to a file
  static Future<bool> releaseUriPermission({
    required String uri,
  }) async {
    if (!isAvailable) {
      return false;
    }
    
    try {
      final result = await _channel.invokeMethod('releaseUriPermission', {
        'uri': uri,
      });
      
      return result == true;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('SAF releaseUriPermission error: ${e.message}');
      }
      return false;
    }
  }
}

/// Information about a file accessed through SAF
class SafFileInfo {
  /// The persistent content URI for the file
  final String uri;
  
  /// User-friendly display path for the file
  final String displayPath;
  
  /// The file content as bytes (null for URI-only operations)
  final Uint8List? content;
  
  const SafFileInfo({
    required this.uri,
    required this.displayPath,
    this.content,
  });
  
  /// Get the file content as a UTF-8 string
  String get contentAsString {
    if (content == null) {
      throw StateError('Content is not available for URI-only file operations');
    }
    return String.fromCharCodes(content!);
  }
  
  /// Get the filename from the display path
  String get fileName {
    // Handle both forward slashes and backslashes for cross-platform compatibility
    final String path = displayPath;
    
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
  
  @override
  String toString() => 'SafFileInfo(uri: $uri, displayPath: $displayPath, size: ${content?.length ?? 0} bytes)';
}
