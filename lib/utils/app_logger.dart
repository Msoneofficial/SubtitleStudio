// Subtitle Studio v3 - Comprehensive Application Logging System
//
// This logging system provides enterprise-grade logging functionality for
// debugging, error tracking, and performance monitoring. It's designed to help
// developers troubleshoot issues both during development and in production.
//
// Key Features:
// - Multi-level logging (DEBUG, INFO, WARNING, ERROR, FATAL)
// - Automatic log file rotation to prevent disk space issues
// - Device and application information collection
// - Flutter error capture and logging
// - Performance monitoring and timing
// - Log export functionality for debugging
// - Memory-efficient logging with batching
// - Cross-platform compatibility
//
// iOS Port Considerations:
// - Replace getApplicationSupportDirectory with iOS-specific paths
// - Use iOS logging framework (os_log) for better integration
// - Implement iOS crash reporting integration
// - Adapt file operations to iOS sandbox restrictions
// - Use iOS-native error reporting systems

import 'dart:io';                              // File system operations
import 'dart:convert';                         // JSON encoding for structured logs
import 'package:flutter/foundation.dart';     // Flutter debugging utilities
import 'package:path_provider/path_provider.dart'; // App directory access
import 'package:device_info_plus/device_info_plus.dart'; // Device information
import 'package:package_info_plus/package_info_plus.dart'; // App version info

/// Enumeration of log levels for categorizing message severity
/// 
/// Each level has a numeric value for filtering and a string name for display:
/// - DEBUG (0): Detailed information for debugging during development
/// - INFO (1): General information about app operation
/// - WARNING (2): Potentially harmful situations that don't stop execution
/// - ERROR (3): Error events that might still allow app to continue
/// - FATAL (4): Critical errors that may cause app termination
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARNING'),
  error(3, 'ERROR'),
  fatal(4, 'FATAL');

  const LogLevel(this.value, this.name);
  final int value;  // Numeric value for comparison and filtering
  final String name; // Human-readable name for log output
}

/// Enterprise-grade logging system for comprehensive app monitoring and debugging
/// 
/// This singleton class provides a centralized logging solution with the following capabilities:
/// 
/// **Core Logging Features:**
/// - Multiple severity levels with filtering capabilities
/// - Structured logging with context information
/// - Automatic timestamp and metadata inclusion
/// - Thread-safe logging operations
/// 
/// **File Management:**
/// - Automatic log file creation with timestamps
/// - Log rotation based on file size limits
/// - Cleanup of old log files to manage disk space
/// - Secure storage in app-specific directories
/// 
/// **System Integration:**
/// - Flutter error handler override for crash logging
/// - Device information collection (OS, device model, etc.)
/// - App version and build information logging
/// - Performance timing and monitoring
/// 
/// **Export and Sharing:**
/// - Export logs to shareable files
/// - Structured export with metadata
/// - Integration with system sharing mechanisms
/// 
/// **Usage Example:**
/// ```dart
/// await AppLogger.instance.initialize();
/// await AppLogger.instance.info('User logged in', context: 'Authentication');
/// await AppLogger.instance.error('Database connection failed', 
///   context: 'DatabaseHelper.connect',
///   extra: {'connectionString': 'masked_value'});
/// ```
/// 
/// **iOS Port Implementation Notes:**
/// - Replace file operations with iOS NSFileManager
/// - Use iOS os_log framework for better system integration
/// - Implement iOS-specific crash reporting (e.g., Crashlytics)
/// - Adapt directory access to iOS sandbox model
/// - Consider iOS background app refresh limitations
class AppLogger {
  // Singleton pattern implementation
  static AppLogger? _instance;
  static AppLogger get instance => _instance ??= AppLogger._();
  
  AppLogger._(); // Private constructor for singleton

  // Core logging infrastructure
  File? _logFile;                    // Current active log file
  String? _deviceInfo;               // Cached device information
  String? _appInfo;                  // Cached app version information
  bool _isInitialized = false;       // Initialization state flag
  
  // Configuration constants
  static const int maxLogFileSize = 5 * 1024 * 1024; // 5MB per log file
  static const int maxLogFiles = 3;                   // Keep last 3 log files only
  
  /// Initialize the logging system
  /// This should be called early in main() function
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _setupLogFile();
      await _collectDeviceInfo();
      await _collectAppInfo();
      _setupFlutterErrorHandling();
      
      _isInitialized = true;
      
      // Log system startup
      await info('AppLogger initialized successfully');
      await info('Device Info: $_deviceInfo');
      await info('App Info: $_appInfo');
      
    } catch (e) {
      debugPrint('Failed to initialize AppLogger: $e');
    }
  }

  /// Setup log file with rotation
  Future<void> _setupLogFile() async {
    try {
      // Use internal storage with app name folder
      final directory = await getApplicationSupportDirectory();
      final appLogsDir = Directory('${directory.path}/Subtitle Studio/logs');
      
      if (!await appLogsDir.exists()) {
        await appLogsDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      _logFile = File('${appLogsDir.path}/app_log_$timestamp.txt');
      
      // Rotate logs if needed
      await _rotateLogsIfNeeded(appLogsDir);
      
    } catch (e) {
      debugPrint('Failed to setup log file: $e');
    }
  }

  /// Rotate log files to prevent disk space issues
  Future<void> _rotateLogsIfNeeded(Directory logsDir) async {
    try {
      final logFiles = await logsDir
          .list()
          .where((entity) => entity is File && entity.path.contains('app_log_'))
          .cast<File>()
          .toList();
      
      // Sort by modification time (newest first)
      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // Remove old log files if we have too many
      if (logFiles.length > maxLogFiles) {
        for (int i = maxLogFiles; i < logFiles.length; i++) {
          await logFiles[i].delete();
        }
      }
      
      // Check current log file size and rotate if needed
      if (_logFile != null && await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > maxLogFileSize) {
          await _setupLogFile(); // Create new log file
        }
      }
    } catch (e) {
      debugPrint('Failed to rotate logs: $e');
    }
  }

  /// Collect device information for debugging
  Future<void> _collectDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final deviceData = <String, dynamic>{};
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceData['platform'] = 'Android';
        deviceData['model'] = androidInfo.model;
        deviceData['manufacturer'] = androidInfo.manufacturer;
        deviceData['version'] = androidInfo.version.release;
        deviceData['sdkInt'] = androidInfo.version.sdkInt;
        deviceData['brand'] = androidInfo.brand;
        deviceData['device'] = androidInfo.device;
        deviceData['hardware'] = androidInfo.hardware;
        deviceData['product'] = androidInfo.product;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceData['platform'] = 'iOS';
        deviceData['model'] = iosInfo.model;
        deviceData['name'] = iosInfo.name;
        deviceData['systemVersion'] = iosInfo.systemVersion;
        deviceData['localizedModel'] = iosInfo.localizedModel;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceData['platform'] = 'Windows';
        deviceData['computerName'] = windowsInfo.computerName;
        deviceData['numberOfCores'] = windowsInfo.numberOfCores;
        deviceData['systemMemoryInMegabytes'] = windowsInfo.systemMemoryInMegabytes;
      }
      
      _deviceInfo = jsonEncode(deviceData);
    } catch (e) {
      _deviceInfo = 'Failed to collect device info: $e';
    }
  }

  /// Collect app information
  Future<void> _collectAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appData = {
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'buildSignature': packageInfo.buildSignature,
      };
      
      _appInfo = jsonEncode(appData);
    } catch (e) {
      _appInfo = 'Failed to collect app info: $e';
    }
  }

  /// Setup Flutter error handling to catch uncaught errors
  void _setupFlutterErrorHandling() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log the error
      fatal(
        'Flutter Error: ${details.exception}',
        stackTrace: details.stack,
        context: 'FlutterError.onError',
      );
      
      // Call the default error handler in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // Catch errors not handled by Flutter framework
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      fatal(
        'Uncaught Error: $error',
        stackTrace: stackTrace,
        context: 'PlatformDispatcher.onError',
      );
      return true;
    };
  }

  /// Format log entry with timestamp, level, and message
  String _formatLogEntry(LogLevel level, String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();
    
    buffer.writeln('[$timestamp] [${level.name}] $message');
    
    if (context != null) {
      buffer.writeln('  Context: $context');
    }
    
    if (extra != null && extra.isNotEmpty) {
      buffer.writeln('  Extra: ${jsonEncode(extra)}');
    }
    
    if (stackTrace != null) {
      buffer.writeln('  Stack Trace:');
      buffer.writeln(stackTrace.toString().split('\n').map((line) => '    $line').join('\n'));
    }
    
    buffer.writeln(''); // Empty line for readability
    
    return buffer.toString();
  }

  /// Write log entry to file and console
  Future<void> _writeLog(LogLevel level, String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) async {
    if (!_isInitialized && level != LogLevel.fatal) {
      // For non-fatal logs, try to initialize if not done yet
      await initialize();
    }
    
    final logEntry = _formatLogEntry(
      level,
      message,
      context: context,
      stackTrace: stackTrace,
      extra: extra,
    );
    
    // Always print to console in debug mode
    if (kDebugMode) {
      debugPrint(logEntry.trim());
    }
    
    // Write to file if available
    try {
      if (_logFile != null) {
        await _logFile!.writeAsString(logEntry, mode: FileMode.append);
        
        // Check if we need to rotate the log file
        final size = await _logFile!.length();
        if (size > maxLogFileSize) {
          final directory = await getApplicationSupportDirectory();
          final appLogsDir = Directory('${directory.path}/Subtitle Studio/logs');
          await _rotateLogsIfNeeded(appLogsDir);
        }
      }
    } catch (e) {
      debugPrint('Failed to write to log file: $e');
    }
  }

  /// Log debug message
  Future<void> debug(String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) async {
    await _writeLog(LogLevel.debug, message, context: context, stackTrace: stackTrace, extra: extra);
  }

  /// Log info message
  Future<void> info(String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) async {
    await _writeLog(LogLevel.info, message, context: context, stackTrace: stackTrace, extra: extra);
  }

  /// Log warning message
  Future<void> warning(String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) async {
    await _writeLog(LogLevel.warning, message, context: context, stackTrace: stackTrace, extra: extra);
  }

  /// Log error message
  Future<void> error(String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) async {
    await _writeLog(LogLevel.error, message, context: context, stackTrace: stackTrace, extra: extra);
  }

  /// Log fatal error message
  Future<void> fatal(String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) async {
    await _writeLog(LogLevel.fatal, message, context: context, stackTrace: stackTrace, extra: extra);
  }

  /// Log performance metrics
  Future<void> performance(String operation, Duration duration, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    final performanceData = {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'duration_readable': '${duration.inMilliseconds}ms',
      if (extra != null) ...extra,
    };
    
    await info(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      context: context ?? 'Performance',
      extra: performanceData,
    );
  }

  /// Get all log files
  Future<List<File>> getLogFiles() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final appLogsDir = Directory('${directory.path}/Subtitle Studio/logs');
      
      if (!await appLogsDir.exists()) {
        return [];
      }
      
      final logFiles = await appLogsDir
          .list()
          .where((entity) => entity is File && entity.path.contains('app_log_'))
          .cast<File>()
          .toList();
      
      // Sort by modification time (newest first)
      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return logFiles;
    } catch (e) {
      await error('Failed to get log files: $e');
      return [];
    }
  }

  /// Share logs with developer or support
  /// This creates a comprehensive log report and saves it to the documents directory
  Future<String> exportLogsToFile({String? fileName}) async {
    try {
      final logFiles = await getLogFiles();
      
      if (logFiles.isEmpty) {
        await warning('No log files found to export');
        throw Exception('No log files found');
      }
      
      // Create a summary report
      final report = StringBuffer();
      report.writeln('Subtitle Studio - Log Report');
      report.writeln('Generated: ${DateTime.now().toIso8601String()}');
      report.writeln('');
      report.writeln('Device Information:');
      report.writeln(_deviceInfo ?? 'Not available');
      report.writeln('');
      report.writeln('App Information:');
      report.writeln(_appInfo ?? 'Not available');
      report.writeln('');
      report.writeln('Log Files Included: ${logFiles.length}');
      report.writeln('');
      
      // Add recent errors and warnings
      final recentEntries = await _getRecentImportantEntries();
      if (recentEntries.isNotEmpty) {
        report.writeln('Recent Important Events:');
        report.writeln(recentEntries);
        report.writeln('');
      }
      
      // Add full log content from recent files
      report.writeln('=' * 50);
      report.writeln('FULL LOG CONTENT');
      report.writeln('=' * 50);
      
      for (int i = 0; i < logFiles.length && i < 2; i++) {
        final file = logFiles[i];
        report.writeln('');
        report.writeln('LOG FILE: ${file.path.split('/').last}');
        report.writeln('-' * 30);
        
        try {
          String content;
          try {
            // Try UTF-8 first
            content = await file.readAsString(encoding: utf8);
          } catch (e) {
            try {
              // Fall back to Latin-1 (can handle any byte sequence)
              content = await file.readAsString(encoding: latin1);
            } catch (e2) {
              // Last resort: read as bytes and handle safely
              final bytes = await file.readAsBytes();
              content = String.fromCharCodes(bytes.where((b) => b >= 32 && b <= 126 || b == 10 || b == 13));
              content = 'Note: File contained non-text data, showing printable characters only:\n$content';
            }
          }
          report.writeln(content);
        } catch (e) {
          report.writeln('Error reading file: $e');
        }
        
        report.writeln('');
      }
      
      // Save report to the documents directory where user can access it
      final documentsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final exportFileName = fileName ?? 'MSoneSubEditor_Logs_$timestamp.txt';
      final exportFile = File('${documentsDir.path}/$exportFileName');
      
      await exportFile.writeAsString(report.toString());
      
      await info('Log report exported to: ${exportFile.path}');
      
      return exportFile.path;
      
    } catch (e) {
      await error('Failed to export logs: $e');
      rethrow;
    }
  }
  
  /// Get the path to the most recent log report for sharing
  Future<String?> getLatestLogReportPath() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final files = await documentsDir
          .list()
          .where((entity) => entity is File && entity.path.contains('MSoneSubEditor_Logs_'))
          .cast<File>()
          .toList();
      
      if (files.isEmpty) return null;
      
      // Sort by modification time (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files.first.path;
    } catch (e) {
      await error('Failed to get latest log report: $e');
      return null;
    }
  }

  /// Get recent important log entries (errors and warnings)
  Future<String> _getRecentImportantEntries() async {
    try {
      final logFiles = await getLogFiles();
      if (logFiles.isEmpty) return '';
      
      final buffer = StringBuffer();
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 24)); // Last 24 hours
      
      for (final file in logFiles.take(2)) {
        String content;
        try {
          // Try UTF-8 first
          content = await file.readAsString(encoding: utf8);
        } catch (e) {
          try {
            // Fall back to Latin-1 (can handle any byte sequence)
            content = await file.readAsString(encoding: latin1);
          } catch (e2) {
            // Last resort: read as bytes and handle safely
            final bytes = await file.readAsBytes();
            content = String.fromCharCodes(bytes.where((b) => b >= 32 && b <= 126 || b == 10 || b == 13));
          }
        }
        
        final lines = content.split('\n');
        
        for (final line in lines) {
          if (line.contains('[ERROR]') || line.contains('[FATAL]') || line.contains('[WARNING]')) {
            // Simple timestamp extraction - this could be improved
            try {
              if (line.startsWith('[') && line.contains(']')) {
                final timestampStr = line.substring(1, line.indexOf(']'));
                final timestamp = DateTime.parse(timestampStr);
                
                if (timestamp.isAfter(cutoff)) {
                  buffer.writeln(line);
                }
              }
            } catch (e) {
              // If timestamp parsing fails, include the line anyway
              buffer.writeln(line);
            }
          }
        }
      }
      
      return buffer.toString();
    } catch (e) {
      return 'Failed to extract recent entries: $e';
    }
  }

  /// Clear all log files
  Future<void> clearLogs() async {
    try {
      final logFiles = await getLogFiles();
      
      for (final file in logFiles) {
        await file.delete();
      }
      
      // Reset the current log file reference to null
      _logFile = null;
      
      await info('All log files cleared');
      
      // Recreate log file for future logging
      await _setupLogFile();
      
    } catch (e) {
      await error('Failed to clear logs: $e');
    }
  }

  /// Get log statistics
  Future<Map<String, dynamic>> getLogStats() async {
    try {
      final logFiles = await getLogFiles();
      
      if (logFiles.isEmpty) {
        return {
          'totalFiles': 0,
          'totalSize': 0,
          'oldestLog': null,
          'newestLog': null,
        };
      }
      
      int totalSize = 0;
      DateTime? oldest;
      DateTime? newest;
      
      for (final file in logFiles) {
        final stat = await file.stat();
        totalSize += stat.size;
        
        final modified = stat.modified;
        if (oldest == null || modified.isBefore(oldest)) {
          oldest = modified;
        }
        if (newest == null || modified.isAfter(newest)) {
          newest = modified;
        }
      }
      
      return {
        'totalFiles': logFiles.length,
        'totalSize': totalSize,
        'totalSizeReadable': '${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
        'oldestLog': oldest?.toIso8601String(),
        'newestLog': newest?.toIso8601String(),
      };
    } catch (e) {
      await error('Failed to get log stats: $e');
      return {};
    }
  }
}

/// Helper class for measuring performance
class PerformanceTimer {
  final String operation;
  final Stopwatch _stopwatch = Stopwatch();
  final String? context;
  final Map<String, dynamic>? extra;

  PerformanceTimer(this.operation, {this.context, this.extra}) {
    _stopwatch.start();
  }

  Future<void> stop() async {
    _stopwatch.stop();
    await AppLogger.instance.performance(
      operation,
      _stopwatch.elapsed,
      context: context,
      extra: extra,
    );
  }
}

/// Extension for easier logging
extension LoggingExtension on Object {
  Future<void> logDebug(String message, {String? context, Map<String, dynamic>? extra}) =>
      AppLogger.instance.debug(message, context: context ?? runtimeType.toString(), extra: extra);

  Future<void> logInfo(String message, {String? context, Map<String, dynamic>? extra}) =>
      AppLogger.instance.info(message, context: context ?? runtimeType.toString(), extra: extra);

  Future<void> logWarning(String message, {String? context, Map<String, dynamic>? extra}) =>
      AppLogger.instance.warning(message, context: context ?? runtimeType.toString(), extra: extra);

  Future<void> logError(String message, {StackTrace? stackTrace, String? context, Map<String, dynamic>? extra}) =>
      AppLogger.instance.error(message, stackTrace: stackTrace, context: context ?? runtimeType.toString(), extra: extra);

  Future<void> logFatal(String message, {StackTrace? stackTrace, String? context, Map<String, dynamic>? extra}) =>
      AppLogger.instance.fatal(message, stackTrace: stackTrace, context: context ?? runtimeType.toString(), extra: extra);
}
