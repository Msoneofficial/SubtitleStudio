import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';

class ThemeSwitcherButton extends StatefulWidget {
  const ThemeSwitcherButton({super.key});

  @override
  ThemeSwitcherButtonState createState() => ThemeSwitcherButtonState();
}

class ThemeSwitcherButtonState extends State<ThemeSwitcherButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _rotationAnimation =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(begin: 1, end: 1.2).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _sparkleAnimation =
        Tween<double>(begin: 1, end: 1.2).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  IconData _getIconForTheme(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.wb_sunny_outlined;
      case ThemeMode.dark:
        return Icons.nights_stay_outlined;
      case ThemeMode.system:
        return Icons.auto_awesome;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // Cycle through the themes
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        themeProvider.setTheme(ThemeMode.dark);
        _controller.forward(from: 0);
        break;
      case ThemeMode.dark:
        themeProvider.setTheme(ThemeMode.system); // Classic theme
        _controller.forward(from: 0);
        break;
      default: // Classic theme
        themeProvider.setTheme(ThemeMode.light);
        _controller.forward(from: 0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentIcon = _getIconForTheme(themeProvider.themeMode);

    return IconButton(
      onPressed: _switchTheme,
      icon: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Choose animation based on the current icon
          if (currentIcon == Icons.wb_sunny_outlined) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.1415926535,
              child: Icon(currentIcon),
            );
          } else if (currentIcon == Icons.nights_stay_outlined) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(currentIcon),
            );
          } else {
            return Transform.scale(
              scale: _sparkleAnimation.value,
              child: Icon(
                currentIcon,
                color: Colors.white,
              ),
            );
          }
        },
      ),
    );
  }
}
