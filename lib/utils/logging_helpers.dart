import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

/// Helper functions to transition from debugPrint to AppLogger
/// 
/// These functions maintain the same API as debugPrint but use the AppLogger
/// underneath for better logging capabilities.

/// Enhanced debug print that logs to both console and file
Future<void> logPrint(String message, {String? context}) async {
  // Always print to console in debug mode (like debugPrint)
  if (kDebugMode) {
    debugPrint(message);
  }
  
  // Also log to file system through AppLogger
  await AppLogger.instance.debug(message, context: context);
}

/// Log info message (similar to print, but with logging)
Future<void> logInfo(String message, {String? context}) async {
  if (kDebugMode) {
    debugPrint('[INFO] $message');
  }
  await AppLogger.instance.info(message, context: context);
}

/// Log warning message
Future<void> logWarning(String message, {String? context, StackTrace? stackTrace}) async {
  if (kDebugMode) {
    debugPrint('[WARNING] $message');
  }
  await AppLogger.instance.warning(message, context: context, stackTrace: stackTrace);
}

/// Log error message
Future<void> logError(String message, {String? context, StackTrace? stackTrace, dynamic error}) async {
  if (kDebugMode) {
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('[ERROR] Details: $error');
    }
  }
  await AppLogger.instance.error(
    message, 
    context: context, 
    stackTrace: stackTrace,
    extra: error != null ? {'error_details': error.toString()} : null,
  );
}

/// Log fatal error message
Future<void> logFatal(String message, {String? context, StackTrace? stackTrace, dynamic error}) async {
  if (kDebugMode) {
    debugPrint('[FATAL] $message');
    if (error != null) {
      debugPrint('[FATAL] Details: $error');
    }
  }
  await AppLogger.instance.fatal(
    message, 
    context: context, 
    stackTrace: stackTrace,
    extra: error != null ? {'error_details': error.toString()} : null,
  );
}

/// Measure and log performance of an operation
Future<T> logPerformance<T>(
  String operation,
  Future<T> Function() task, {
  String? context,
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    final result = await task();
    stopwatch.stop();
    await AppLogger.instance.performance(operation, stopwatch.elapsed, context: context);
    return result;
  } catch (e, stackTrace) {
    stopwatch.stop();
    await AppLogger.instance.error(
      'Performance tracking failed for $operation: $e',
      context: context,
      stackTrace: stackTrace,
      extra: {'operation': operation, 'duration_ms': stopwatch.elapsedMilliseconds},
    );
    rethrow;
  }
}

/// Extension methods for easy logging from any object
extension EasyLogging on Object {
  Future<void> logDebug(String message) async {
    await AppLogger.instance.debug(message, context: runtimeType.toString());
  }
  
  Future<void> logInfo(String message) async {
    await AppLogger.instance.info(message, context: runtimeType.toString());
  }
  
  Future<void> logWarning(String message, [StackTrace? stackTrace]) async {
    await AppLogger.instance.warning(message, context: runtimeType.toString(), stackTrace: stackTrace);
  }
  
  Future<void> logError(String message, [dynamic error, StackTrace? stackTrace]) async {
    await AppLogger.instance.error(
      message, 
      context: runtimeType.toString(), 
      stackTrace: stackTrace,
      extra: error != null ? {'error_details': error.toString()} : null,
    );
  }
  
  Future<void> logFatal(String message, [dynamic error, StackTrace? stackTrace]) async {
    await AppLogger.instance.fatal(
      message, 
      context: runtimeType.toString(), 
      stackTrace: stackTrace,
      extra: error != null ? {'error_details': error.toString()} : null,
    );
  }
}
