import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtitle_studio/themes/theme_provider.dart';
import 'package:subtitle_studio/operations/subtitle_operations.dart';
import 'package:subtitle_studio/widgets/positioning_buttons_widget.dart';
import 'package:subtitle_studio/widgets/subtitle_effects_sheet.dart';
import 'package:subtitle_studio/operations/subtitle_effect_operations.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/services/checkpoint_manager.dart';

class SubtitleActionsMenu extends StatelessWidget {
  final TextEditingController editedController;
  final String startTime;
  final String endTime;
  final int subtitleId;
  final SubtitleLine currentLine;
  final SubtitleCollection collection;
  final VoidCallback refreshCallback; // For split, merge, effects (refresh current line)
  final Function(int newLineIndex) refreshToLineCallback; // For add (navigate to new line)
  final int sessionId;
  final Future<bool> Function() onBeforeAdd; // Callback to save current line before adding
  final bool isVideoLoaded;
  final Duration? Function()? getCurrentVideoPosition;

  const SubtitleActionsMenu({
    super.key,
    required this.editedController,
    required this.startTime,
    required this.endTime,
    required this.subtitleId,
    required this.currentLine,
    required this.collection,
    required this.refreshCallback,
    required this.refreshToLineCallback,
    required this.sessionId,
    required this.onBeforeAdd,
    this.isVideoLoaded = false,
    this.getCurrentVideoPosition,
  });

  void _showPositioningDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return PositioningButtonsWidget(controller: editedController);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.movie_edit,
        size: 32,
        color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.light
            ? const Color.fromARGB(255, 0, 45, 54)
            : const Color.fromARGB(255, 233, 216, 166),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      offset: const Offset(0, 8),
      onSelected: (String value) {
        switch (value) {
          case "split":
            SubtitleOperations.handleSplitButton(
              context: context,
              editedController: editedController,
              startTime: startTime,
              endTime: endTime,
              subtitleId: subtitleId,
              currentLine: currentLine,
              refreshCallback: refreshCallback,
              sessionId: sessionId,
            );
            break;
          case "merge":
            SubtitleOperations.showMergeConfirmation(
              context: context,
              currentLine: currentLine,
              collection: collection,
              subtitleId: subtitleId,
              refreshCallback: refreshToLineCallback,
              sessionId: sessionId,
            );
            break;
          case "add":
            SubtitleOperations.showAddLineConfirmation(
              context: context,
              currentLine: currentLine,
              collection: collection,
              currentStartTime: startTime,
              currentEndTime: endTime,
              subtitleId: subtitleId,
              refreshCallback: refreshToLineCallback, // Use the new callback with line index
              sessionId: sessionId,
              onBeforeAdd: onBeforeAdd, // Pass the callback
              isVideoLoaded: isVideoLoaded,
              getCurrentVideoPosition: getCurrentVideoPosition,
            );
            break;
          case "positioning":
            _showPositioningDialog(context);
            break;
          case "effects":
            _showEffectsDialog(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: "split",
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.call_split,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  "Split Subtitle",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: "merge",
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.merge,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  "Merge Subtitles",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: "add",
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.playlist_add,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  "Add New Line",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: "positioning",
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.control_camera,
                  color: Colors.purple,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  "Subtitle Position",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: "effects",
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  "Add Effects",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEffectsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SubtitleEffectsSheet(
          selectedIndices: [currentLine.index - 1], // Convert to 0-based index
          onApplyEffect: (effectType, effectConfig) {
            _applyEffectToSingleLine(context, effectType, effectConfig);
          },
        );
      },
    );
  }

  Future<void> _applyEffectToSingleLine(BuildContext context, String effectType, Map<String, dynamic> effectConfig) async {
    try {
      List<SubtitleLine> effectLines = [];
      
      if (effectType == 'karaoke') {
        final colorHex = effectConfig['color'] as String;
        final color = colorHex.substring(2); // Remove alpha channel
        final endDelay = effectConfig['endDelay'] as double? ?? 0.0;
        final effectTypeKaraoke = effectConfig['effectType'] as String? ?? 'word';
        
        effectLines = await SubtitleEffectOperations.generateKaraokeEffect(
          originalLine: currentLine,
          color: color,
          effectType: effectTypeKaraoke,
          endDelay: endDelay,
        );
      } else if (effectType == 'typewriter') {
        final colorHex = effectConfig['color'] as String;
        final color = colorHex.substring(2); // Remove alpha channel
        final endDelay = effectConfig['endDelay'] as double? ?? 0.0;
        
        effectLines = await SubtitleEffectOperations.generateTypewriterEffect(
          originalLine: currentLine,
          color: color,
          endDelay: endDelay,
        );
      }
      
      if (effectLines.isNotEmpty) {
        // Apply the effect to the database
        final success = await SubtitleEffectOperations.applyEffectToSubtitleCollection(
          subtitleCollectionId: subtitleId,
          originalLineIndex: currentLine.index - 1, // Convert to 0-based
          effectLines: effectLines,
        );
        
        if (success) {
          // Create a checkpoint for the effect
          await CheckpointManager.createCheckpoint(
            sessionId: sessionId,
            subtitleCollectionId: subtitleId,
            operationType: 'effect',
            description: 'Applied $effectType effect to line ${currentLine.index} (${effectLines.length} lines)',
            deltas: [], // Effects don't use deltas
            forceSnapshot: true, // IMPORTANT: Force snapshot because effects replace entire sections
          );
          
          // Close the sheet and refresh
          Navigator.of(context).pop();
          refreshCallback();
          
          // Show success message
          SnackbarHelper.showSuccess(
            context,
            '$effectType effect applied successfully! Generated ${effectLines.length} subtitle lines.',
            duration: const Duration(seconds: 3),
          );
        } else {
          throw Exception('Failed to apply effect to database');
        }
      } else {
        throw Exception('No effect lines generated');
      }
    } catch (e) {
      // Show error message
      SnackbarHelper.showError(
        context,
        'Error applying effect: $e',
        duration: const Duration(seconds: 3),
      );
    }
  }
}
