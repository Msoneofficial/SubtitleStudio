// Subtitle Studio v3 - Startup Permission Manager
//
// This utility handles permission requests on app startup to ensure the app has
// all necessary permissions before the user starts using core functionality.
// 
// Key Features:
// - Checks current permission status on startup
// - Requests missing permissions with user-friendly explanations
// - Handles different Android API levels appropriately  
// - Provides fallback strategies when permissions are denied
// - Shows informative dialogs explaining why permissions are needed
//
// Permissions Handled:
// - Storage permissions (for subtitle file access)
// - Media permissions (for video file access on Android 13+)
// - Internet permission (already granted at install, no runtime request needed)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// Handles permission requests and checks on app startup
class StartupPermissionManager {
  /// Check and request all necessary permissions on app startup
  /// 
  /// Returns true if all essential permissions are granted or not needed,
  /// false if critical permissions are denied
  static Future<bool> checkAndRequestStartupPermissions(BuildContext context) async {
    if (!Platform.isAndroid) {
      // Non-Android platforms don't need runtime permissions
      return true;
    }

    try {
      // Check current permission status
      final permissionStatus = await _getCurrentPermissionStatus();
      
      if (permissionStatus.allGranted) {
        if (kDebugMode) {
          print('All permissions already granted');
        }
        return true;
      }

      if (permissionStatus.needsRequest) {
        // Show explanation dialog before requesting permissions
        final shouldRequest = await _showPermissionExplanationDialog(context, permissionStatus);
        
        if (!shouldRequest) {
          // User chose not to grant permissions
          return _handlePermissionsDenied(context, permissionStatus);
        }

        // Request the permissions
        final granted = await _requestMissingPermissions(permissionStatus);
        
        if (!granted) {
          return _handlePermissionsDenied(context, permissionStatus);
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking startup permissions: $e');
      }
      // Don't block app startup on permission errors
      return true;
    }
  }

  /// Get current status of all app permissions
  static Future<PermissionStatusInfo> _getCurrentPermissionStatus() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    final info = PermissionStatusInfo();

    if (sdkInt >= 33) {
      // Android 13+ (API 33+) - Check granular media permissions
      info.photosStatus = await Permission.photos.status;
      info.videosStatus = await Permission.videos.status;
      info.audioStatus = await Permission.audio.status;
      info.storageStatus = await Permission.storage.status;
      info.androidVersion = AndroidVersion.android13Plus;
    } else if (sdkInt >= 30) {
      // Android 11-12 (API 30-32) - Check storage permission
      info.storageStatus = await Permission.storage.status;
      info.androidVersion = AndroidVersion.android11To12;
    } else {
      // Android 10 and below (API 29-) - Check storage permission
      info.storageStatus = await Permission.storage.status;
      info.androidVersion = AndroidVersion.android10AndBelow;
    }

    return info;
  }

  /// Show dialog explaining why permissions are needed
  static Future<bool> _showPermissionExplanationDialog(
    BuildContext context, 
    PermissionStatusInfo permissionStatus
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9, // Increase width
          constraints: BoxConstraints(maxWidth: 420), // Maximum width constraint
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
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.security,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Permissions Required",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Required for core app functionality",
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
              const SizedBox(height: 16),
              
              // Permission explanation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subtitle Studio needs the following permissions:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionExplanation(permissionStatus, onSurfaceColor, mutedColor),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Privacy notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These permissions are only used for file operations and video playback. Your privacy is protected.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: mutedColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      "Not Now",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Grant",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;
  }

  /// Build permission explanation based on Android version
  static Widget _buildPermissionExplanation(
    PermissionStatusInfo permissionStatus,
    Color onSurfaceColor,
    Color mutedColor,
  ) {
    final explanations = <Widget>[];

    switch (permissionStatus.androidVersion) {
      case AndroidVersion.android13Plus:
        if (permissionStatus.photosStatus?.isDenied == true) {
          explanations.add(_buildPermissionItem(
            Icons.image,
            'Photos Access',
            'To access subtitle files stored in media folders',
            onSurfaceColor,
            mutedColor,
          ));
        }
        if (permissionStatus.videosStatus?.isDenied == true) {
          explanations.add(_buildPermissionItem(
            Icons.videocam,
            'Videos Access',
            'To extract subtitles from video files',
            onSurfaceColor,
            mutedColor,
          ));
        }
        if (permissionStatus.audioStatus?.isDenied == true) {
          explanations.add(_buildPermissionItem(
            Icons.audiotrack,
            'Audio Access',
            'To access subtitle files in audio/media folders',
            onSurfaceColor,
            mutedColor,
          ));
        }
        break;
        
      case AndroidVersion.android11To12:
      case AndroidVersion.android10AndBelow:
        if (permissionStatus.storageStatus?.isDenied == true) {
          explanations.add(_buildPermissionItem(
            Icons.folder,
            'Storage Access',
            'To read and save subtitle files on your device',
            onSurfaceColor,
            mutedColor,
          ));
        }
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: explanations,
    );
  }

  /// Build individual permission explanation item
  static Widget _buildPermissionItem(
    IconData icon, 
    String title, 
    String description,
    Color onSurfaceColor,
    Color mutedColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: mutedColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Request missing permissions based on Android version
  static Future<bool> _requestMissingPermissions(PermissionStatusInfo permissionStatus) async {
    try {
      switch (permissionStatus.androidVersion) {
        case AndroidVersion.android13Plus:
          // Request granular media permissions
          final permissions = <Permission>[];
          
          if (permissionStatus.photosStatus?.isDenied == true) {
            permissions.add(Permission.photos);
          }
          if (permissionStatus.videosStatus?.isDenied == true) {
            permissions.add(Permission.videos);
          }
          if (permissionStatus.audioStatus?.isDenied == true) {
            permissions.add(Permission.audio);
          }
          
          if (permissions.isNotEmpty) {
            final results = await permissions.request();
            final hasAnyPermission = results.values.any((status) => 
              status == PermissionStatus.granted || status == PermissionStatus.limited);
            
            // Also try to request storage permission for broader access
            final storageStatus = await Permission.storage.request();
            
            return hasAnyPermission || storageStatus == PermissionStatus.granted;
          }
          return true;

        case AndroidVersion.android11To12:
        case AndroidVersion.android10AndBelow:
          // Request storage permission
          if (permissionStatus.storageStatus?.isDenied == true) {
            final result = await Permission.storage.request();
            return result == PermissionStatus.granted;
          }
          return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting permissions: $e');
      }
      return false;
    }
  }

  /// Handle case where permissions are denied
  static Future<bool> _handlePermissionsDenied(
    BuildContext context, 
    PermissionStatusInfo permissionStatus
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9, // Increase width
          constraints: BoxConstraints(maxWidth: 420), // Maximum width constraint
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
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Limited Functionality",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Some features may not work properly",
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
              const SizedBox(height: 16),
              
              // Content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Without these permissions, some features may not work properly:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLimitationItem('• File import/export may be limited', mutedColor),
                    _buildLimitationItem('• Video subtitle extraction may not work', mutedColor),
                    _buildLimitationItem('• You can still use Storage Access Framework for file operations', mutedColor),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Settings notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can grant permissions later in Settings > Apps > Subtitle Studio > Permissions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: mutedColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openAppSettings();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Settings",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Don't block app startup even if permissions are denied
    return true;
  }

  /// Build limitation item for permissions denied dialog
  static Widget _buildLimitationItem(String text, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: mutedColor,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Information about current permission status
class PermissionStatusInfo {
  PermissionStatus? storageStatus;
  PermissionStatus? photosStatus;
  PermissionStatus? videosStatus;
  PermissionStatus? audioStatus;
  AndroidVersion androidVersion = AndroidVersion.android10AndBelow;

  /// Check if all required permissions are granted
  bool get allGranted {
    switch (androidVersion) {
      case AndroidVersion.android13Plus:
        // For Android 13+, we need at least one media permission or storage permission
        final hasMediaPermission = 
          photosStatus == PermissionStatus.granted ||
          photosStatus == PermissionStatus.limited ||
          videosStatus == PermissionStatus.granted ||
          videosStatus == PermissionStatus.limited ||
          audioStatus == PermissionStatus.granted ||
          audioStatus == PermissionStatus.limited;
        
        final hasStoragePermission = storageStatus == PermissionStatus.granted;
        
        return hasMediaPermission || hasStoragePermission;

      case AndroidVersion.android11To12:
      case AndroidVersion.android10AndBelow:
        return storageStatus == PermissionStatus.granted;
    }
  }

  /// Check if any permissions need to be requested
  bool get needsRequest {
    switch (androidVersion) {
      case AndroidVersion.android13Plus:
        return photosStatus?.isDenied == true ||
               videosStatus?.isDenied == true ||
               audioStatus?.isDenied == true ||
               storageStatus?.isDenied == true;

      case AndroidVersion.android11To12:
      case AndroidVersion.android10AndBelow:
        return storageStatus?.isDenied == true;
    }
  }
}

/// Android version categories for permission handling
enum AndroidVersion {
  android10AndBelow,
  android11To12,
  android13Plus,
}
