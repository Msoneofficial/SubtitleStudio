// Subtitle Studio v3 - In-App Update Manager
// 
// This utility class handles Google Play Store in-app updates using the in_app_update package.
// It provides functionality to:
// - Check for available updates
// - Start immediate updates (blocking)
// - Start flexible updates (non-blocking)
// - Handle update completion for flexible updates
// - Show appropriate UI feedback during update process

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_logger.dart';
import 'app_info.dart';

/// Manager class for handling Google Play Store in-app updates
/// 
/// This class provides a comprehensive solution for implementing in-app updates
/// with proper error handling, logging, and user experience considerations.
class UpdateManager {
  static final UpdateManager _instance = UpdateManager._internal();
  factory UpdateManager() => _instance;
  UpdateManager._internal();

  /// Singleton instance
  static UpdateManager get instance => _instance;

  /// Helper method to format available version display
  /// 
  /// Since Google Play API only provides build number, we create a meaningful
  /// display by showing both the expected pattern and build number
  String _getAvailableVersionDisplay(int? availableVersionCode) {
    if (availableVersionCode == null) return 'Unknown';
    
    // Get current build info for better comparison
    final currentBuild = int.tryParse(AppInfo.buildNumber) ?? 0;
    
    // Show more informative version display
    if (availableVersionCode > currentBuild) {
      return 'Newer version (Build $availableVersionCode)';
    } else {
      return 'Build $availableVersionCode';
    }
  }

  /// Get detailed diagnostic information about update availability
  /// This is useful for debugging update detection issues
  Future<Map<String, dynamic>> getUpdateDiagnostics() async {
    // Only available on Android
    if (!Platform.isAndroid) {
      return {
        'error': 'Update manager only available on Android',
        'platform': Platform.operatingSystem,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      return {
        'updateAvailability': updateInfo.updateAvailability.toString(),
        'updateAvailabilityCode': updateInfo.updateAvailability.index,
        'availableVersionCode': updateInfo.availableVersionCode,
        'clientVersionStalenessDays': updateInfo.clientVersionStalenessDays,
        'installStatus': updateInfo.installStatus.toString(),
        'installStatusCode': updateInfo.installStatus.index,
        'immediateUpdateAllowed': updateInfo.immediateUpdateAllowed,
        'flexibleUpdateAllowed': updateInfo.flexibleUpdateAllowed,
        'packageName': updateInfo.packageName,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check if an update is available from Google Play Store
  /// 
  /// Returns [AppUpdateInfo] if update is available, null otherwise.
  /// This method should be called when the app starts or when user
  /// manually checks for updates.
  /// 
  /// Returns null if:
  /// - No update is available
  /// - Error occurred during check
  /// - App is not installed from Play Store
  /// - Not running on Android platform
  Future<AppUpdateInfo?> checkForUpdate() async {
    // Only available on Android
    if (!Platform.isAndroid) {
      await AppLogger.instance.info(
        'Update check skipped - not on Android platform',
        context: 'UpdateManager.checkForUpdate',
      );
      return null;
    }
    
    try {
      await AppLogger.instance.info('Checking for app updates...');
      
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      // Log detailed update information for debugging
      await AppLogger.instance.info(
        'Update check completed',
        context: 'UpdateManager.checkForUpdate',
        extra: {
          'updateAvailability': updateInfo.updateAvailability.toString(),
          'availableVersionCode': updateInfo.availableVersionCode,
          'clientVersionStalenessDays': updateInfo.clientVersionStalenessDays,
          'installStatus': updateInfo.installStatus.toString(),
          'immediateUpdateAllowed': updateInfo.immediateUpdateAllowed,
          'flexibleUpdateAllowed': updateInfo.flexibleUpdateAllowed,
        },
      );
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await AppLogger.instance.info(
          'Update available - Version: ${updateInfo.availableVersionCode}',
          context: 'UpdateManager.checkForUpdate',
        );
        return updateInfo;
      } else if (updateInfo.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
        await AppLogger.instance.info('Update already in progress');
        return updateInfo; // Return the info so we can handle the in-progress update
      } else {
        await AppLogger.instance.info(
          'No update available - Status: ${updateInfo.updateAvailability}',
          context: 'UpdateManager.checkForUpdate',
        );
        return null;
      }
    } catch (e) {
      await AppLogger.instance.error(
        'Error checking for updates: $e',
        context: 'UpdateManager.checkForUpdate',
      );
      return null;
    }
  }

  /// Start an immediate update (blocks the app until update is complete)
  /// 
  /// This type of update is recommended for critical updates that require
  /// the user to update before continuing to use the app.
  /// 
  /// The update process:
  /// 1. Downloads the update in the background
  /// 2. Shows a full-screen update UI
  /// 3. Installs the update when download completes
  /// 4. Restarts the app automatically
  /// 
  /// [context] - BuildContext for showing dialogs
  /// [updateInfo] - Update information from checkForUpdate()
  /// 
  /// Returns true if update was started successfully
  Future<bool> startImmediateUpdate(BuildContext context, AppUpdateInfo updateInfo) async {
    // Only available on Android
    if (!Platform.isAndroid) {
      await AppLogger.instance.warning(
        'Immediate update not available on ${Platform.operatingSystem}',
        context: 'UpdateManager.startImmediateUpdate',
      );
      return false;
    }
    
    try {
      await AppLogger.instance.info('Starting immediate update...');
      
      // Show loading dialog
      _showUpdateDialog(context, 'Starting update...', isLoading: true);
      
      final result = await InAppUpdate.performImmediateUpdate();
      
      // Remove loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (result == AppUpdateResult.success) {
        await AppLogger.instance.info('Immediate update completed successfully');
        return true;
      } else {
        await AppLogger.instance.warning('Immediate update failed: $result');
        if (context.mounted) {
          _showErrorDialog(context, 'Update failed. Please try again later.');
        }
        return false;
      }
    } catch (e) {
      await AppLogger.instance.error(
        'Error during immediate update: $e',
        context: 'UpdateManager.startImmediateUpdate',
      );
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        _showErrorDialog(context, 'Update failed. Please try again later.');
      }
      return false;
    }
  }

  /// Start a flexible update (allows user to continue using the app)
  /// 
  /// This type of update downloads in the background while the user
  /// continues to use the app. When download completes, the user is
  /// prompted to restart the app to apply the update.
  /// 
  /// The update process:
  /// 1. Downloads the update in the background
  /// 2. User can continue using the app
  /// 3. Shows completion notification when ready
  /// 4. User chooses when to restart and apply update
  /// 
  /// [context] - BuildContext for showing dialogs
  /// [updateInfo] - Update information from checkForUpdate()
  /// 
  /// Returns true if update was started successfully
  Future<bool> startFlexibleUpdate(BuildContext context, AppUpdateInfo updateInfo) async {
    // Only available on Android
    if (!Platform.isAndroid) {
      await AppLogger.instance.warning(
        'Flexible update not available on ${Platform.operatingSystem}',
        context: 'UpdateManager.startFlexibleUpdate',
      );
      return false;
    }
    
    try {
      await AppLogger.instance.info('Starting flexible update...');
      
      final result = await InAppUpdate.startFlexibleUpdate();
      
      if (result == AppUpdateResult.success) {
        await AppLogger.instance.info('Flexible update started successfully');
        
        if (context.mounted) {
          _showSuccessDialog(
            context, 
            'Update is downloading in the background. You\'ll be notified when it\'s ready to install.'
          );
        }
        return true;
      } else {
        await AppLogger.instance.warning('Flexible update failed to start: $result');
        if (context.mounted) {
          _showErrorDialog(context, 'Failed to start update. Please try again later.');
        }
        return false;
      }
    } catch (e) {
      await AppLogger.instance.error(
        'Error during flexible update: $e',
        context: 'UpdateManager.startFlexibleUpdate',
      );
      
      if (context.mounted) {
        _showErrorDialog(context, 'Update failed. Please try again later.');
      }
      return false;
    }
  }

  /// Complete a flexible update (restart the app to apply downloaded update)
  /// 
  /// This method should be called when a flexible update has finished
  /// downloading and the user is ready to apply it. The app will restart
  /// automatically after calling this method.
  /// 
  /// [context] - BuildContext for showing dialogs
  /// 
  /// Returns true if completion was started successfully
  Future<bool> completeFlexibleUpdate(BuildContext context) async {
    // Only available on Android
    if (!Platform.isAndroid) {
      await AppLogger.instance.warning(
        'Complete flexible update not available on ${Platform.operatingSystem}',
        context: 'UpdateManager.completeFlexibleUpdate',
      );
      return false;
    }
    
    try {
      await AppLogger.instance.info('Completing flexible update...');
      
      await InAppUpdate.completeFlexibleUpdate();
      
      await AppLogger.instance.info('Flexible update completed successfully');
      return true;
    } catch (e) {
      await AppLogger.instance.error(
        'Error completing flexible update: $e',
        context: 'UpdateManager.completeFlexibleUpdate',
      );
      
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to complete update. Please try again.');
      }
      return false;
    }
  }

  /// Show update available dialog with options
  /// 
  /// Presents the user with options to:
  /// - Update now (immediate update)
  /// - Update later (flexible update)
  /// - Skip this version
  /// 
  /// [context] - BuildContext for showing dialog
  /// [updateInfo] - Update information from checkForUpdate()
  void showUpdateDialog(BuildContext context, AppUpdateInfo updateInfo) {
    // Only available on Android
    if (!Platform.isAndroid) {
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.system_update,
                  color: Color(0xFF2A9D8F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Update Available',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version of Subtitle Studio is available with improvements and bug fixes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (updateInfo.availableVersionCode != null)
                Column(
                  children: [
                    // Version comparison info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF6D597A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Version: ${AppInfo.versionWithBuild}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6D597A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available Version: ${_getAvailableVersionDisplay(updateInfo.availableVersionCode)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2A9D8F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                'Would you like to update now?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                startFlexibleUpdate(context, updateInfo);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2A9D8F),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Background'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                startImmediateUpdate(context, updateInfo);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF355070),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
  }

  /// Show a generic loading dialog during update operations
  void _showUpdateDialog(BuildContext context, String message, {bool isLoading = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              if (isLoading) 
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF2A9D8F),
                    ),
                  ),
                ),
              if (isLoading) const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show error dialog with retry option
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE56B6F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Color(0xFFE56B6F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Update Error',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF355070),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show success dialog
  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.cloud_download,
                  color: Color(0xFF2A9D8F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Update Started',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF355070),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Check for flexible update completion
  /// 
  /// This method should be called when the app resumes or starts
  /// to check if a flexible update has completed downloading and
  /// is ready to be installed.
  /// 
  /// [context] - BuildContext for showing completion dialog
  Future<void> checkFlexibleUpdateCompletion(BuildContext context) async {
    // Only available on Android
    if (!Platform.isAndroid) {
      return;
    }
    
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.installStatus == InstallStatus.downloaded) {
        await AppLogger.instance.info('Flexible update downloaded and ready to install');
        
        if (context.mounted) {
          _showUpdateReadyDialog(context);
        }
      }
    } catch (e) {
      await AppLogger.instance.error(
        'Error checking flexible update completion: $e',
        context: 'UpdateManager.checkFlexibleUpdateCompletion',
      );
    }
  }

  /// Show dialog when flexible update is ready to install
  void _showUpdateReadyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.download_done,
                  color: Color(0xFF2A9D8F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Update Ready',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'The update has been downloaded and is ready to install. The app will restart to apply the update.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                completeFlexibleUpdate(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF355070),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Install Now'),
            ),
          ],
        );
      },
    );
  }

  /// Fallback method to open Play Store for manual update
  /// 
  /// This method opens the app's Play Store page where users can
  /// manually update the app. Use this as a fallback when in-app
  /// updates are not available or not working.
  /// 
  /// [context] - BuildContext for showing dialogs
  Future<void> openPlayStoreForUpdate(BuildContext context) async {
    try {
      const playStoreUrl = 'https://play.google.com/store/apps/details?id=org.msone.subeditor';
      final uri = Uri.parse(playStoreUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await AppLogger.instance.info('Opened Play Store for manual update');
      } else {
        await AppLogger.instance.error('Could not launch Play Store URL');
        if (context.mounted) {
          _showErrorDialog(context, 'Could not open Play Store. Please search for "Subtitle Studio" in the Play Store manually.');
        }
      }
    } catch (e) {
      await AppLogger.instance.error('Error opening Play Store: $e');
      if (context.mounted) {
        _showErrorDialog(context, 'Could not open Play Store. Please search for "Subtitle Studio" in the Play Store manually.');
      }
    }
  }

  /// Show fallback update dialog when in-app updates are not available
  /// 
  /// This provides users with an alternative way to update via Play Store
  void showFallbackUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D597A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.open_in_new,
                  color: Color(0xFF6D597A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Update Available',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version of Subtitle Studio is available.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please update via Google Play Store to get the latest features and improvements.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  height: 1.3,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openPlayStoreForUpdate(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF355070),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Update via Play Store'),
            ),
          ],
        );
      },
    );
  }
}
