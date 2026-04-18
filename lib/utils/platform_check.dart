import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'platform_file_handler.dart';

/// Get default root directory for the platform
/// 
/// Note: With SAF implementation, this function is primarily used for:
/// - App-specific directories that don't require permissions
/// - Fallback scenarios for older Android versions
/// - Desktop platforms where direct file access is still available
Future<Directory> getDefaultRootDirectory() async {
  if (Platform.isAndroid) {
    // For Android, we now prefer app-specific directories
    // that don't require permissions, as external storage 
    // access should be done via SAF (Storage Access Framework)
    try {
      // Use external app directory which doesn't require permissions
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir;
      }
      // Fallback to app documents directory
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      // Final fallback for Android
      return await getApplicationDocumentsDirectory();
    }
  } else if (Platform.isIOS) {
    // Use the app's documents directory on iOS.
    return await getApplicationDocumentsDirectory();
  } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    // Try to use the downloads directory on desktop.
    // getDownloadsDirectory() can return null on some platforms.
    final downloads = await getDownloadsDirectory();
    return downloads ?? Directory.current;
  } else {
    // Fallback in case no platform is matched.
    return Directory.current;
  }
}

/// Open app settings page - this function is imported from permission_handler
/// This is just a reference for compatibility, the actual function is imported directly

/// Request storage permissions based on Android API level
/// 
/// This function handles the different permission requirements for different Android versions:
/// - Android 13+ (API 33+): Uses granular media permissions (READ_MEDIA_*)
/// - Android 11-12 (API 30-32): Uses READ_EXTERNAL_STORAGE
/// - Android 10 and below (API 29-): Uses both READ_EXTERNAL_STORAGE and WRITE_EXTERNAL_STORAGE
Future<bool> requestStoragePermissions() async {
  if (!Platform.isAndroid) {
    // Non-Android platforms don't need storage permissions
    return true;
  }
  
  try {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    
    // For Android 13+ (API 33+), we need granular media permissions
    if (sdkInt >= 33) {
      // Request media permissions for Android 13+
      final results = await [
        Permission.photos, // READ_MEDIA_IMAGES
        Permission.videos, // READ_MEDIA_VIDEO
        Permission.audio,  // READ_MEDIA_AUDIO
      ].request();
      
      // Check if at least one permission is granted
      final hasAnyPermission = results.values.any((status) => 
        status == PermissionStatus.granted || status == PermissionStatus.limited);
      
      // Also request storage permission for broader access
      final storageStatus = await Permission.storage.request();
      
      return hasAnyPermission || storageStatus == PermissionStatus.granted;
    } else if (sdkInt >= 30) {
      // For Android 11+ (API 30+), use scoped storage approach
      // We'll primarily use app-specific directories and SAF for user selections
      // Only request READ_EXTERNAL_STORAGE for reading existing files
      final storageStatus = await Permission.storage.request();
      return storageStatus == PermissionStatus.granted;
    } else {
      // For Android 10 and below (API 29-), request both read and write permissions
      final results = await [
        Permission.storage,
      ].request();
      
      // Check if storage permission is granted
      final storageGranted = results[Permission.storage] == PermissionStatus.granted;
      
      return storageGranted;
    }
  } catch (e) {
    // If permission handling fails, fall back to basic storage permission
    try {
      final storageStatus = await Permission.storage.request();
      return storageStatus == PermissionStatus.granted;
    } catch (e2) {
      // If all else fails, return false to indicate permission issues
      return false;
    }
  }
}

/// Get safe directory for file operations that doesn't require special permissions
Future<Directory?> getSafeExportDirectory() async {
  try {
    if (Platform.isAndroid) {
      // For Android, try multiple approaches to find the best accessible directory
      
      // First, try to access external storage directory
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Check if we can write to external storage
          final testFile = File('${externalDir.path}/.test_write');
          await testFile.writeAsString('test');
          await testFile.delete();
          
          print('External storage is writable: ${externalDir.path}');
          return externalDir;
        }
      } catch (e) {
        print('External storage access failed: $e');
      }
      
      // Second, try app documents directory (always accessible)
      try {
        final appDocsDir = await getApplicationDocumentsDirectory();
        print('Using app documents directory: ${appDocsDir.path}');
        return appDocsDir;
      } catch (e) {
        print('App documents directory access failed: $e');
      }
      
      // Last resort: temporary directory with exports subfolder
      try {
        final tempDir = await getTemporaryDirectory();
        final exportDir = Directory('${tempDir.path}/exports');
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        print('Using temporary exports directory: ${exportDir.path}');
        return exportDir;
      } catch (e) {
        print('Temporary directory access failed: $e');
      }
      
    } else {
      // For other platforms, use downloads directory
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        return downloadsDir;
      }
      
      // Fall back to documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      return docsDir;
    }
  } catch (e) {
    print('getSafeExportDirectory failed: $e');
  }
  
  return null;
}

/// Platform-aware file picker that uses SAF on Android and traditional pickers elsewhere
/// 
/// [mimeTypes] - List of MIME types to filter files (Android SAF only)
/// [allowedExtensions] - List of file extensions for traditional file pickers
/// Returns PlatformFileInfo containing file content and metadata
Future<PlatformFileInfo?> pickFile({
  List<String>? mimeTypes,
  List<String>? allowedExtensions,
}) async {
  if (Platform.isAndroid) {
    // Use SAF on Android - no permissions required
    return await PlatformFileHandler.readFile(mimeTypes: mimeTypes);
  } else {
    // For other platforms, we'd need to integrate with existing file picker
    // This would require the calling code to handle the file picker UI
    throw UnsupportedError('Use traditional file picker on non-Android platforms');
  }
}

/// Platform-aware file save that uses SAF on Android
/// 
/// [content] - File content to save
/// [fileName] - Suggested filename
/// [mimeType] - MIME type of the file
/// [existingFilePath] - For saving over existing files (SAF display path)
/// Returns true if save was successful
Future<bool> saveFile({
  required String content,
  required String fileName,
  String mimeType = 'text/plain',
  String? existingFilePath,
}) async {
  if (Platform.isAndroid) {
    // Use SAF on Android - no permissions required
    return await PlatformFileHandler.writeFile(
      content: content,
      filePath: existingFilePath ?? fileName,
      fileName: fileName,
      mimeType: mimeType,
    );
  } else {
    // For other platforms, use direct file access with permissions
    final hasPermission = await requestStoragePermissions();
    if (!hasPermission) return false;
    
    return await PlatformFileHandler.writeFile(
      content: content,
      filePath: existingFilePath ?? fileName,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
}

/// Platform-aware file save dialog that uses SAF on Android
/// 
/// [content] - File content to save
/// [fileName] - Suggested filename
/// [mimeType] - MIME type of the file
/// Returns PlatformFileInfo if successful
Future<PlatformFileInfo?> saveNewFile({
  required String content,
  required String fileName,
  String mimeType = 'text/plain',
}) async {
  if (Platform.isAndroid) {
    // Use SAF on Android - no permissions required
    return await PlatformFileHandler.saveNewFile(
      content: content,
      fileName: fileName,
      mimeType: mimeType,
    );
  } else {
    // For other platforms, this would need to be handled by calling code
    // with a traditional save dialog
    throw UnsupportedError('Use traditional save dialog on non-Android platforms');
  }
}

/// Check if SAF should be used for file operations
bool shouldUseSaf() {
  return Platform.isAndroid;
}

/// Clear cached SAF URIs (Android only)
void clearFileCache() {
  if (Platform.isAndroid) {
    PlatformFileHandler.clearCache();
  }
}
