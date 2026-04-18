import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../themes/theme_provider.dart';

class Loader13 extends StatefulWidget {
  const Loader13({super.key});

  @override
  State<Loader13> createState() => _Loader13State();
}

class _Loader13State extends State<Loader13> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List<AnimationController>.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _controllers[i].reverse();
          } else if (status == AnimationStatus.dismissed) {
            int nextIndex = (i + 1) % _controllers.length;
            _controllers[nextIndex].forward();
          }
        }),
    );
    _startBouncing();
  }

  void _startBouncing() async {
    for (var i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        _controllers[i].forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _controllers.map((controller) {
            return AnimatedBuilder(
              animation: controller,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, -30 * controller.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Provider.of<ThemeProvider>(context).themeMode ==
                              ThemeMode.light
                          ? Color.fromARGB(255, 0, 45, 54)
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
