import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:subtitle_studio/widgets/custom_text_render.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorPickerWithTextEditing extends StatefulWidget {
  final TextEditingController controller;
  final TextSelection? initialSelection;
  final Color initialColor;
  final List<Color> colorHistory; // Pass color history to persist it
  final bool showApplyButton; // Control whether to show the apply button
  final VoidCallback? onApply; // Callback for when apply is pressed

  const ColorPickerWithTextEditing({
    super.key,
    required this.controller,
    this.initialSelection,
    required this.initialColor,
    required this.colorHistory,
    this.showApplyButton = true,
    this.onApply,
  });

  @override
  ColorPickerWithTextEditingState createState() =>
      ColorPickerWithTextEditingState();
}

class ColorPickerWithTextEditingState
    extends State<ColorPickerWithTextEditing> {
  late Color _selectedColor;
  TextSelection? _currentSelection;
  late String _previewText;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _currentSelection = widget.initialSelection;
    _previewText = widget.controller.text;
  }

  String _applyTextColorToSelection(String text,
      {required TextSelection selection, required Color color}) {
    final red = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final green = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final blue = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    final colorHex = '#$red$green$blue'.toUpperCase();

    String cleanedText = text;

    if (selection.isCollapsed) {
      return '<font color="$colorHex">$cleanedText</font>';
    } else {
      final selectedTextContent = selection.textInside(cleanedText);
      final beforeSelection = selection.textBefore(cleanedText);
      final afterSelection = selection.textAfter(cleanedText);

      String coloredSelection =
          '<font color="$colorHex">$selectedTextContent</font>';
      return '$beforeSelection$coloredSelection$afterSelection';
    }
  }

  void _updatePreviewText(Color color) {
    setState(() {
      _currentSelection = widget.controller.selection;
      _previewText = _applyTextColorToSelection(
        widget.controller.text,
        selection: _currentSelection ?? TextSelection.collapsed(offset: 0),
        color: color,
      );
    });
  }

  void _applyChanges() {
    if (widget.controller.text.isNotEmpty) {
      setState(() {
        widget.controller.text = _previewText;
        _addColorToHistory(_selectedColor); // Add color to history on apply
      });
      // Notify parent to save the updated color history
      _saveColorHistory();
      
      // Call the external callback if provided, otherwise pop
      if (widget.onApply != null) {
        widget.onApply!();
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  // Expose this method for external access
  void applyChanges() {
    if (widget.controller.text.isNotEmpty) {
      setState(() {
        widget.controller.text = _previewText;
        _addColorToHistory(_selectedColor); // Add color to history on apply
      });
      // Notify parent to save the updated color history
      _saveColorHistory();
    }
  }

  // Expose current state for external access
  Color get selectedColor => _selectedColor;

  void _addColorToHistory(Color color) {
    if (!widget.colorHistory.contains(color)) {
      setState(() {
        widget.colorHistory.insert(0, color);
        if (widget.colorHistory.length > 5) {
          widget.colorHistory.removeLast(); // Limit history to the last 5 colors
        }
      });
    }
  }

  Future<void> _saveColorHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final colorStrings = widget.colorHistory.map((color) => 
      '${(color.a * 255).round() << 24 | (color.r * 255).round() << 16 | (color.g * 255).round() << 8 | (color.b * 255).round()}').toList();
    await prefs.setStringList('colorHistory', colorStrings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const highlightColor = Color(0xFF4A90E2); // Blue color for consistency

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview container
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(
                color: highlightColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: CustomHtmlText(
                htmlContent: _previewText.replaceAll('\n', '<br>'),
                textAlign: TextAlign.center,
                defaultStyle: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Color picker with larger size for fullscreen
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ColorPicker(
              color: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                  _updatePreviewText(color);
                });
              },
              width: 30,
              height: 30,
              borderRadius: 25,
              spacing: 10,
              runSpacing: 10,
              wheelDiameter: 220,
              enableOpacity: false,
              showColorCode: true,
              showColorName: false,
              showMaterialName: false,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.wheel: true,
              },
              copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                copyButton: false,
                pasteButton: false,
                longPressMenu: false,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Color history section with modern styling
          if (widget.colorHistory.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: highlightColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Recent Colors',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: highlightColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.colorHistory.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                            _updatePreviewText(color);
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? highlightColor : theme.colorScheme.outline.withValues(alpha: 0.3),
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: highlightColor.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Apply button - only show if showApplyButton is true
          if (widget.showApplyButton) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: highlightColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _applyChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: highlightColor,
                  foregroundColor: Colors.white,
                  overlayColor: highlightColor.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Apply Color",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
