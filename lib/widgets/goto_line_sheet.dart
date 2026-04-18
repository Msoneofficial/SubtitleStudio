import 'package:flutter/material.dart';
import 'package:subtitle_studio/utils/app_logger.dart';

void showGotToLineModal({
  required BuildContext context,
  String initialValue = '',
  int hintText = 0,
  String title = 'Input',
  required ValueChanged<String> onSubmitted,
}) async {
  await AppLogger.instance.info('Showing goto line modal', context: 'showGotToLineModal', extra: {
    'initialValue': initialValue,
    'hintText': hintText,
    'title': title,
  });
  
  // Initialize with default value or provided value
  int initialLineNumber = int.tryParse(initialValue) ?? 1;
  
  // Ensure initial value is within range
  initialLineNumber = initialLineNumber.clamp(1, hintText > 0 ? hintText : 1);
  
  final TextEditingController controller = TextEditingController(
      text: initialLineNumber.toString());
  
  // Value notifier to keep slider and text field in sync
  final ValueNotifier<double> sliderValue = ValueNotifier<double>(initialLineNumber.toDouble());

  // Show snackbar at the top
  void showTopSnackBar(BuildContext context, String message) async {
    await AppLogger.instance.warning('Invalid input in goto line: $message', context: 'showGotToLineModal.showTopSnackBar');
    
    // Get the overlay state from the root navigator to show snackbar at the top
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20, // Position at top with safe area padding
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red,
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
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Remove the overlay after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Function to validate and process input
  void processInput() {
    // Close the keyboard first
    FocusScope.of(context).unfocus();
    
    final value = controller.text.trim();
    if (value.isEmpty) {
      // Show error for empty input
      showTopSnackBar(context, 'Please enter a line number');
      return;
    }
    
    // Try to parse the input as an integer
    int? lineNumber = int.tryParse(value);
    if (lineNumber == null) {
      showTopSnackBar(context, 'Please enter a valid number');
      return;
    }
    
    // Validate range
    if (lineNumber < 1 || lineNumber > hintText) {
      showTopSnackBar(context, 'Please enter a number between 1 and $hintText');
      return;
    }
    
    AppLogger.instance.info('Goto line successful: $lineNumber', context: 'showGotToLineModal.processInput');
    onSubmitted(value);
    Navigator.pop(context);
  }

  // Update text field from slider
  void updateTextField(double value) {
    final intValue = value.round();
    controller.text = intValue.toString();
    sliderValue.value = value;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      // Dynamic color variables for adaptive theming
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final primaryColor = Theme.of(context).primaryColor;
      final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
      final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
      final borderColor = onSurfaceColor.withValues(alpha: 0.12);

      return SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Go to Line',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Jump to a specific line number (1-$hintText)',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Input Section
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Line Number',
                            prefixIcon: Icon(
                              Icons.format_list_numbered,
                              color: primaryColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            labelStyle: TextStyle(
                              color: primaryColor,
                            ),
                          ),
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (value) {
                            processInput();
                          },
                          onChanged: (value) {
                            // Update slider when text changes
                            final intValue = int.tryParse(value);
                            if (intValue != null && intValue >= 1 && intValue <= hintText) {
                              sliderValue.value = intValue.toDouble();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '/ $hintText',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Slider Section
                if (hintText > 1) ...[
                  const SizedBox(height: 24),
                  ValueListenableBuilder<double>(
                    valueListenable: sliderValue,
                    builder: (context, value, child) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tune,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Quick Navigation',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Line ${value.round()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  '1',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: mutedColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                                      inactiveTrackColor: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                                      thumbColor: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                                      overlayColor: (isDark ? Colors.blue.shade300 : Colors.blue.shade700).withValues(alpha: 0.2),
                                      valueIndicatorColor: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                                      valueIndicatorTextStyle: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      trackHeight: 4.0,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                                    ),
                                    child: Slider(
                                      min: 1,
                                      max: hintText.toDouble(),
                                      divisions: hintText > 1000 ? 1000 : hintText - 1,
                                      value: value,
                                      label: value.round().toString(),
                                      onChanged: updateTextField,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$hintText',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: mutedColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: onSurfaceColor,
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close,
                                size: 20,
                                color: onSurfaceColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: onSurfaceColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: processInput,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_upward_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Jump',
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
              ],
            ),
          ),
        ),
      );
    },
  );
}
