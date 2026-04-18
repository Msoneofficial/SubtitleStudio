import 'package:flutter/material.dart';
import 'dart:async';

/// A loader that runs in an overlay, isolated from the rest of the UI operations
class IsolatedLoader extends StatefulWidget {
  final bool isVisible;
  final Color? backgroundColor;

  const IsolatedLoader({
    super.key,
    required this.isVisible,
    this.backgroundColor,
  });

  @override
  State<IsolatedLoader> createState() => _IsolatedLoaderState();
}

class _IsolatedLoaderState extends State<IsolatedLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Widget> _animatedDots = [];
  late Timer _redrawTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Create a dedicated animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    
    // Initialize the redraw timer but defer building dots
    _redrawTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && widget.isVisible && _isInitialized) {
        setState(() {
          // This empty setState forces the widget to rebuild
          // and keeps the animation running
        });
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now it's safe to access MediaQuery
    _buildAnimatedDots();
    _isInitialized = true;
  }
  
  void _buildAnimatedDots() {
    // Don't access MediaQuery before initialization
    if (!mounted) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = screenWidth * 0.015;
    final width1 = screenWidth * 0.09;
    final width2 = screenWidth * 0.06;
    final width3 = screenWidth * 0.10;
    
    _animatedDots.clear();
    _animatedDots.addAll([
      _buildAnimatedDot(0.0, 0.2, width1),
      SizedBox(width: spacing),
      _buildAnimatedDot(0.2, 0.4, width2),
      SizedBox(width: spacing),
      _buildAnimatedDot(0.4, 0.6, width3),
      SizedBox(width: spacing),
      _buildAnimatedDot(0.6, 0.8, width3),
      SizedBox(width: spacing),
      _buildAnimatedDot(0.8, 1.0, width1),
    ]);
  }
  
  Widget _buildAnimatedDot(double startInterval, double endInterval, double width) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isActive = _controller.value >= startInterval && 
                        _controller.value < endInterval;
        return Container(
          height: 8,
          width: width,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _redrawTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();
    
    // Rebuild dots if the screen size changes
    if (_isInitialized) {
      _buildAnimatedDots();
    }
    
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: widget.backgroundColor ?? Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _animatedDots.isNotEmpty 
                    ? _animatedDots.sublist(0, _animatedDots.length >= 5 ? 5 : _animatedDots.length)
                    : [const SizedBox()],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _animatedDots.length >= 6
                    ? _animatedDots.sublist(5)
                    : [const SizedBox()],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Utility class to manage the isolated loader overlay
class IsolatedLoaderController {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;
  
  /// Show the loader overlay
  static void show(BuildContext context) {
    if (_isVisible) return;
    
    _isVisible = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => IsolatedLoader(isVisible: true),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  /// Hide the loader overlay
  static void hide() {
    if (!_isVisible || _overlayEntry == null) return;
    
    _overlayEntry!.remove();
    _overlayEntry = null;
    _isVisible = false;
  }
}
