import 'package:flutter/material.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';

class FirstTimeInstructions extends StatefulWidget {
  final String screenName;
  final Widget child;
  final List<String> instructions;

  const FirstTimeInstructions({
    super.key,
    required this.screenName,
    required this.child,
    required this.instructions,
  });

  @override
  State<FirstTimeInstructions> createState() => _FirstTimeInstructionsState();
}

class _FirstTimeInstructionsState extends State<FirstTimeInstructions> {
  bool _showInstructions = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final hasSeenInstructions = await PreferencesModel.getHasSeenTutorial(widget.screenName);
    if (!hasSeenInstructions && mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _showInstructions = true;
        });
      }
    }
  }

  Future<void> _dismissInstructions() async {
    await PreferencesModel.setHasSeenTutorial(widget.screenName, true);
    setState(() {
      _showInstructions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showInstructions) _buildInstructionsOverlay(),
      ],
    );
  }

  Widget _buildInstructionsOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Quick Start Guide',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...widget.instructions.map((instruction) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 8, right: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          instruction,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _dismissInstructions,
                      child: Text(
                        'Got it!',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
