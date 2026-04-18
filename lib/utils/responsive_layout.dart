// Subtitle Studio v3 - Responsive Layout Utilities
//
// This utility class provides methods to detect screen sizes and platform types
// to enable adaptive layouts across mobile and desktop platforms.
//
// Features:
// - Platform detection (mobile vs desktop)
// - Screen size breakpoints for responsive design
// - Layout helper methods for different screen configurations

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveLayout {
  // Breakpoint constants
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;
  
  /// Check if the current platform is desktop
  static bool isDesktopPlatform() {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }
  
  /// Check if the current platform is mobile
  static bool isMobilePlatform() {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
  
  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// Check if screen is mobile sized (regardless of platform)
  static bool isMobileScreen(BuildContext context) {
    return getScreenWidth(context) < mobileBreakpoint;
  }
  
  /// Check if screen is tablet sized
  static bool isTabletScreen(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }
  
  /// Check if screen is desktop sized
  static bool isDesktopScreen(BuildContext context) {
    return getScreenWidth(context) >= desktopBreakpoint;
  }
  
  /// Check if screen is large (tablet or desktop)
  static bool isLargeScreen(BuildContext context) {
    return getScreenWidth(context) >= mobileBreakpoint;
  }
  
  /// Determine if we should use desktop layout
  /// Uses both platform and screen size to make the decision
  static bool shouldUseDesktopLayout(BuildContext context) {
    // If it's a desktop platform and screen is large enough, use desktop layout
    if (isDesktopPlatform() && isLargeScreen(context)) {
      return true;
    }
    // If it's a mobile platform but screen is very large (like tablet in landscape), use desktop layout
    if (isMobilePlatform() && isDesktopScreen(context)) {
      return true;
    }
    return false;
  }
  
  /// Determine if we should use mobile layout
  static bool shouldUseMobileLayout(BuildContext context) {
    return !shouldUseDesktopLayout(context);
  }
  
  /// Get the number of columns for grid layout based on screen size
  static int getGridColumns(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < mobileBreakpoint) {
      return 1; // Mobile: single column
    } else if (width < tabletBreakpoint) {
      return 2; // Tablet: two columns
    } else if (width < desktopBreakpoint) {
      return 3; // Small desktop: three columns
    } else {
      return 4; // Large desktop: four columns
    }
  }
  
  /// Get video player width ratio for desktop layout
  static double getVideoWidthRatio(BuildContext context) {
    if (shouldUseDesktopLayout(context)) {
      return 0.65; // 65% for video, 35% for content
    }
    return 1.0; // Full width for mobile
  }
  
  /// Get content width ratio for desktop layout
  static double getContentWidthRatio(BuildContext context) {
    if (shouldUseDesktopLayout(context)) {
      return 0.35; // 35% for content, 65% for video
    }
    return 1.0; // Full width for mobile
  }
  
  /// Get sidebar width for desktop layout
  static double getSidebarWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (shouldUseDesktopLayout(context)) {
      // Minimum 300px, maximum 400px, or 35% of screen width
      return (screenWidth * 0.35).clamp(300.0, 400.0);
    }
    return screenWidth; // Full width for mobile
  }
  
  /// Get main content width for desktop layout
  static double getMainContentWidth(BuildContext context) {
    if (shouldUseDesktopLayout(context)) {
      return getScreenWidth(context) - getSidebarWidth(context);
    }
    return getScreenWidth(context); // Full width for mobile
  }

  /// Get responsive subtitle font size based on screen size and layout
  static double getSubtitleFontSize(BuildContext context, double baseFontSize) {
    if (shouldUseDesktopLayout(context)) {
      // Increase font size for desktop layouts where video is larger
      final screenWidth = getScreenWidth(context);
      if (screenWidth >= desktopBreakpoint) {
        // Large desktop: increase by 50%
        return baseFontSize * 1.5;
      } else if (screenWidth >= tabletBreakpoint) {
        // Medium desktop/tablet: increase by 25%
        return baseFontSize * 1.25;
      } else {
        // Small desktop: increase by 12.5%
        return baseFontSize * 1.125;
      }
    }
    return baseFontSize; // Mobile: use base size
  }

  /// Get mobile video height based on screen size and resize ratio
  /// If includeWaveformHeight is true, adds waveform height to the video section
  static double getMobileVideoHeight(BuildContext context, double resizeRatio, {bool includeWaveformHeight = false}) {
    final screenHeight = getScreenHeight(context);
    final availableHeight = screenHeight - kToolbarHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;
    
    // Calculate base video height
    // Apply resize ratio to available height
    // Clamp between 150px minimum and 60% of available height maximum
    final baseVideoHeight = (availableHeight * resizeRatio).clamp(150.0, availableHeight * 0.6);
    
    // Add waveform height if needed (default waveform height is 180px)
    if (includeWaveformHeight) {
      const waveformHeight = 180.0;
      return baseVideoHeight + waveformHeight;
    }
    
    return baseVideoHeight;
  }

  /// Check if we should use mobile resize feature
  static bool shouldUseMobileResize(BuildContext context) {
    // Use mobile resize when using mobile layout
    return shouldUseMobileLayout(context);
  }

  /// Get default mobile video resize ratio based on screen orientation
  static double getDefaultMobileVideoRatio(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.landscape) {
      return 0.5; // 50% in landscape for better video viewing
    } else {
      return 0.4; // 40% in portrait to leave more space for content
    }
  }
}

/// Widget that adapts its child based on screen size and platform
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.shouldUseDesktopLayout(context)) {
      return desktop;
    } else if (tablet != null && ResponsiveLayout.isTabletScreen(context)) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

/// Widget that provides responsive padding based on screen size
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;
  
  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });
  
  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry padding;
    
    if (ResponsiveLayout.isDesktopScreen(context)) {
      padding = desktopPadding ?? const EdgeInsets.all(24.0);
    } else if (ResponsiveLayout.isTabletScreen(context)) {
      padding = tabletPadding ?? const EdgeInsets.all(16.0);
    } else {
      padding = mobilePadding ?? const EdgeInsets.all(12.0);
    }
    
    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Widget that provides a resizable split layout between two widgets
class ResizableSplitView extends StatefulWidget {
  final Widget leftChild;
  final Widget rightChild;
  final double initialRatio;
  final double minRatio;
  final double maxRatio;
  final bool vertical;
  final Color? dividerColor;
  final double dividerThickness;
  final void Function(double ratio)? onRatioChanged;
  
  const ResizableSplitView({
    super.key,
    required this.leftChild,
    required this.rightChild,
    this.initialRatio = 0.35,
    this.minRatio = 0.2,
    this.maxRatio = 0.8,
    this.vertical = false,
    this.dividerColor,
    this.dividerThickness = 4.0,
    this.onRatioChanged,
  });

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  late double _ratio;
  bool _isDragging = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio.clamp(widget.minRatio, widget.maxRatio);
    _isInitialized = true;
  }

  @override
  void didUpdateWidget(ResizableSplitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update ratio if it's a significant change and we're not currently dragging
    if (_isInitialized && !_isDragging && 
        (widget.initialRatio != oldWidget.initialRatio) && 
        ((_ratio - widget.initialRatio).abs() > 0.01)) {
      setState(() {
        _ratio = widget.initialRatio.clamp(widget.minRatio, widget.maxRatio);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      final delta = widget.vertical 
          ? details.delta.dy / constraints.maxHeight
          : details.delta.dx / constraints.maxWidth;
      _ratio = (_ratio + delta).clamp(widget.minRatio, widget.maxRatio);
    });
    widget.onRatioChanged?.call(_ratio);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dividerColor = widget.dividerColor ?? 
            Theme.of(context).colorScheme.outline.withOpacity(0.2);
            
        if (widget.vertical) {
          return Column(
            children: [
              SizedBox(
                height: constraints.maxHeight * _ratio,
                child: widget.leftChild,
              ),
              GestureDetector(
                onPanStart: (_) => setState(() => _isDragging = true),
                onPanEnd: (_) => setState(() => _isDragging = false),
                onPanUpdate: (details) => _onPanUpdate(details, constraints),
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeRow,
                  child: Container(
                    height: widget.dividerThickness,
                    color: _isDragging 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                        : dividerColor,
                    child: Center(
                      child: Container(
                        height: 2,
                        width: 40,
                        decoration: BoxDecoration(
                          color: _isDragging 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: widget.rightChild,
              ),
            ],
          );
        } else {
          return Row(
            children: [
              SizedBox(
                width: constraints.maxWidth * _ratio,
                child: widget.leftChild,
              ),
              GestureDetector(
                onPanStart: (_) => setState(() => _isDragging = true),
                onPanEnd: (_) => setState(() => _isDragging = false),
                onPanUpdate: (details) => _onPanUpdate(details, constraints),
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: widget.dividerThickness,
                    color: _isDragging 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                        : dividerColor,
                    child: Center(
                      child: Container(
                        width: 2,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isDragging 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: widget.rightChild,
              ),
            ],
          );
        }
      },
    );
  }
}
