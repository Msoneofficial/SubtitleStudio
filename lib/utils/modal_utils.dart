import 'package:flutter/material.dart';

/// Utility class for creating responsive modal bottom sheets that handle
/// device navigation bars and system UI overlays properly.
class ModalUtils {
  /// Shows a modal bottom sheet that properly handles navigation bars
  /// and system UI overlays. This ensures the content is not covered
  /// by the device navigation buttons.
  static Future<T?> showResponsiveBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    String? barrierLabel,
    bool useRootNavigator = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape ?? const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      useSafeArea: true, // This ensures proper handling of safe areas
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: builder(context),
        ),
      ),
    );
  }

  /// Wraps content with proper padding to handle system UI overlays
  /// in modal bottom sheets. Includes keyboard padding and navigation bar padding.
  static Widget wrapModalContent({
    required Widget child,
    required BuildContext context,
    EdgeInsets? additionalPadding,
  }) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Padding(
      padding: EdgeInsets.only(
        left: (additionalPadding?.left ?? 0) + 16.0,
        right: (additionalPadding?.right ?? 0) + 16.0,
        top: (additionalPadding?.top ?? 0) + 16.0,
        bottom: (additionalPadding?.bottom ?? 0) + 
                bottomPadding + 
                keyboardPadding + 
                16.0,
      ),
      child: child,
    );
  }

  /// Creates a standardized container for modal bottom sheets with proper theming
  static Widget createModalContainer({
    required Widget child,
    required BuildContext context,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: borderRadius ?? const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: child,
    );
  }
}
