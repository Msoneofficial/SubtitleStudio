import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtitle_studio/themes/theme_provider.dart';
import 'package:subtitle_studio/widgets/colour_picker_widget.dart';

class FormattingMenu extends StatelessWidget {
  final TextEditingController controller;
  final List<Color> colorHistory;
  final VoidCallback? onColorHistoryUpdate;

  const FormattingMenu({
    super.key, 
    required this.controller,
    required this.colorHistory,
    this.onColorHistoryUpdate,
  });

  void _toggleFormatting(String tag, TextEditingController controller) {
    // Ensure the controller and selection are valid
    if (controller.text.isEmpty || !controller.selection.isValid) {
      return;
    }

    final originalText = controller.text;
    final selection = controller.selection;
    final selectedText = selection.textInside(originalText);

    if (selectedText.isNotEmpty) {
      final start = selection.start;
      final end = selection.end;

      // Preserve leading and trailing white spaces
      final leadingSpaces = selectedText.length > selectedText.trimLeft().length
          ? selectedText.substring(0, selectedText.indexOf(selectedText.trimLeft()))
          : '';
      final trailingSpaces = selectedText.length > selectedText.trimRight().length
          ? selectedText.substring(selectedText.lastIndexOf(selectedText.trimRight()) + selectedText.trimRight().length)
          : '';

      final trimmedText = selectedText.trim();

      if (trimmedText.startsWith("<$tag>") && trimmedText.endsWith("</$tag>")) {
        // Remove tags and restore white spaces
        final unwrappedText = trimmedText.substring(tag.length + 2, trimmedText.length - (tag.length + 3));
        controller.text = originalText.replaceRange(start, end, "$leadingSpaces$unwrappedText$trailingSpaces");
        controller.selection = TextSelection.collapsed(offset: start + unwrappedText.length + leadingSpaces.length);
      } else {
        // Add tags and preserve white spaces
        final wrappedText = "<$tag>$trimmedText</$tag>";
        controller.text = originalText.replaceRange(start, end, "$leadingSpaces$wrappedText$trailingSpaces");
        controller.selection = TextSelection.collapsed(offset: start + wrappedText.length + leadingSpaces.length);
      }
    } else {
      // Handle the entire text if no selection
      final trimmedText = originalText.trim();
      if (trimmedText.startsWith("<$tag>") && trimmedText.endsWith("</$tag>")) {
        controller.text = originalText.substring(tag.length + 2, originalText.length - (tag.length + 3));
      } else if (originalText.isNotEmpty) {
        controller.text = "<$tag>$trimmedText</$tag>";
      }
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }
  }

  void _showColorPicker(BuildContext context) {
    final colorPickerKey = GlobalKey<ColorPickerWithTextEditingState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'Text Color Editor',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
            elevation: 1,
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 80, // Space for floating button
            ),
            child: ColorPickerWithTextEditing(
              key: colorPickerKey,
              controller: controller,
              initialSelection: controller.selection,
              initialColor: Colors.white,
              colorHistory: colorHistory,
              showApplyButton: false, // Hide the apply button from the widget
            ),
          ),
          floatingActionButton: Container(
            width: MediaQuery.of(context).size.width - 32,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: FloatingActionButton.extended(
              onPressed: () {
                // Apply the color changes
                colorPickerKey.currentState?.applyChanges();
                if (onColorHistoryUpdate != null) {
                  onColorHistoryUpdate!();
                }
                Navigator.of(context).pop(true);
              },
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              label: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 24),
                  SizedBox(width: 12),
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
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  void _showClearFormattingDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header section with cleaning icon and title
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.cleaning_services_rounded,
                          color: Colors.orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clear All Formatting',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This action cannot be undone',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.orange.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Warning message in a card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Warning',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Are you sure you want to remove all formatting tags from the text? This will permanently remove all HTML tags, color codes, and styling elements.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            controller.text = controller.text
                              .replaceAll(RegExp(r'(<[^>]+>|\{[^}]+\})'), '');
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cleaning_services_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Clear All',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.format_size, 
        size: 32,
        color: Provider.of<ThemeProvider>(context).themeMode ==
                                      ThemeMode.light
                                  ? const Color.fromARGB(255, 0, 45, 54)
                                  : const Color.fromARGB(255, 233, 216, 166),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      offset: const Offset(0, 8),
      onSelected: (String value) {
        if (value == "color") {
          _showColorPicker(context);
        } else if (value == "clear") {
          _showClearFormattingDialog(context);
        } else {
          _toggleFormatting(value, controller);
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: "b",
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.format_bold,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  "Bold",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: "i",
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.format_italic,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  "Italic",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: "u",
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.format_underline,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  "Underline",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: "s",
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.format_strikethrough,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  "Strikethrough",
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
          value: "color",
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Colors.purple,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  "Text Color",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: "clear",
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.cleaning_services,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  "Clear Formatting",
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
}
