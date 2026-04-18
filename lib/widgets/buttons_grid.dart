import 'package:flutter/material.dart';

/// A custom grid widget that displays a collection of buttons with icons and labels.
/// Each button is created using the [ButtonData] class which contains the button's
/// name, icon, and onTap callback function.
class CustomButtonGrid extends StatelessWidget {
  /// List of [ButtonData] objects that define each button's properties
  final List<ButtonData> buttons;

  const CustomButtonGrid({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Creates a 3-column grid
        childAspectRatio: 2, // Width:Height ratio of each button
        mainAxisSpacing: 10, // Vertical spacing between buttons
        crossAxisSpacing: 10, // Horizontal spacing between buttons
      ),
      shrinkWrap: true, // Grid takes minimum required space
      physics: const NeverScrollableScrollPhysics(), // Disables scrolling
      itemCount: buttons.length,
      itemBuilder: (context, index) {
        final button = buttons[index];
        return _buildButton(
          name: button.name,
          icon: button.icon,
          onTap: button.onTap,
        );
      },
    );
  }

  /// Builds an individual button widget with the specified properties
  ///
  /// Parameters:
  /// - [name]: The text label displayed below the icon
  /// - [icon]: The IconData to display
  /// - [onTap]: Callback function executed when button is pressed
  Widget _buildButton({
    required String name,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color.fromARGB(255, 1, 54, 64),
      elevation: 5,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.blue.withValues(alpha: 0.2), // Splash effect color
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Button icon
              Icon(icon,
                  size: 18, color: const Color.fromARGB(255, 255, 255, 255)),
              const SizedBox(height: 1),
              // Button label
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class that holds the properties for a single button
///
/// Properties:
/// - [name]: The text label for the button
/// - [icon]: The icon to display above the text
/// - [onTap]: The callback function to execute when pressed
class ButtonData {
  final String name;
  final IconData icon;
  final VoidCallback onTap;

  ButtonData({required this.name, required this.icon, required this.onTap});
}
