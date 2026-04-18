import 'package:flutter/material.dart';
import 'package:subtitle_studio/utils/app_logger.dart';

/// A utility class for showing snackbars that work properly in all contexts,
/// including bottom modal sheets where regular snackbars are often hidden.
class SnackbarHelper {
  /// Shows a snackbar that works properly in bottom modal sheets by using overlay
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool useOverlay = true,
  }) async {
    // Log the snackbar being shown
    await AppLogger.instance.info(
      'Showing snackbar: $message',
      context: 'SnackbarHelper.showSnackBar',
      extra: {
        'backgroundColor': backgroundColor?.toString(),
        'duration': duration.inSeconds,
        'useOverlay': useOverlay,
      },
    );

    if (useOverlay) {
      _showOverlaySnackBar(context, message, backgroundColor, icon, duration, action);
    } else {
      _showRegularSnackBar(context, message, backgroundColor, icon, duration, action);
    }
  }

  /// Show SnackBar using overlay (works properly in modal sheets)
  static void _showOverlaySnackBar(
    BuildContext context,
    String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration,
    SnackBarAction? action,
  ) {
    // Check if the context is still mounted and valid
    if (!context.mounted) {
      // Fall back to regular snackbar if context is not mounted
      _showRegularSnackBar(context, message, backgroundColor, icon, duration, action);
      return;
    }

    try {
      // Get the overlay state from the root navigator to show snackbar above modal
      final overlay = Overlay.of(context, rootOverlay: true);
      late OverlayEntry overlayEntry;
    
      // Determine background color
      final bgColor = backgroundColor ?? Colors.grey[800]!;
      
      // Determine icon
      final iconWidget = Icon(
        icon ?? _getDefaultIcon(backgroundColor),
        color: Colors.white,
        size: 20,
      );
      
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  iconWidget,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        try {
                          overlayEntry.remove();
                        } catch (e) {
                          // Overlay might already be removed
                        }
                        action.onPressed();
                      },
                      child: Text(
                        action.label,
                        style: TextStyle(
                          color: action.textColor ?? Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
      
      overlay.insert(overlayEntry);
      
      // Remove the overlay after specified duration
      Future.delayed(duration, () {
        try {
          overlayEntry.remove();
        } catch (e) {
          // Overlay might already be removed
        }
      });
    } catch (e) {
      // If overlay operations fail (e.g., deactivated context), fall back to regular snackbar
      // Only call fallback if context is still mounted to avoid infinite recursion
      if (context.mounted) {
        try {
          _showRegularSnackBar(context, message, backgroundColor, icon, duration, action);
        } catch (fallbackError) {
          // If both overlay and regular snackbar fail, silently fail to prevent crashes
        }
      }
    }
  }

  /// Show regular SnackBar (fallback method)
  static void _showRegularSnackBar(
    BuildContext context,
    String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration,
    SnackBarAction? action,
  ) {
    // Check if context is still mounted before attempting to show snackbar
    if (!context.mounted) {
      return; // Simply return if context is not mounted
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          duration: duration,
          margin: const EdgeInsets.all(16.0),
          action: action,
        ),
      );
    } catch (e) {
      // If ScaffoldMessenger also fails, we can't show any snackbar
      // This could happen if the context is deactivated between the mount check and this call
      // We'll silently fail rather than crash the app
    }
  }

  /// Get default icon based on background color
  static IconData _getDefaultIcon(Color? backgroundColor) {
    if (backgroundColor == Colors.red) return Icons.error;
    if (backgroundColor == Colors.green) return Icons.check_circle;
    if (backgroundColor == Colors.orange) return Icons.warning;
    return Icons.info;
  }

  /// Convenience methods for common snackbar types
  
  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showError(BuildContext context, String message, {Duration? duration}) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void showWarning(BuildContext context, String message, {Duration? duration}) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}
