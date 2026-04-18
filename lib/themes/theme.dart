import 'package:flutter/material.dart';

class AppThemes {
  // Base Typography
  static final Typography _typography = Typography.material2021();

  // Light Theme Text
  static final TextTheme _lightTextTheme = _typography.black.copyWith(
      bodyLarge: const TextStyle(color: Color(0xFF264653)),
      bodyMedium: const TextStyle(color: Color(0xFF264653)),
      bodySmall: const TextStyle(
          color: Color(0xFF264653), fontSize: 14),
      titleLarge: const TextStyle(
        color: Color(0xFF355070),
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      titleMedium: const TextStyle(
        color: Color(0xFF001219),
        fontWeight: FontWeight.bold,
      ),
      titleSmall: const TextStyle(color: Color(0xFF264653)),
      labelSmall: TextStyle(color: Color(0xFFE76F51), fontSize: 14));

  // Dark Theme Text
  static final TextTheme _darkTextTheme = _typography.white.copyWith(
      bodyLarge: const TextStyle(color: Color(0xFFE9C46A)),
      bodyMedium: const TextStyle(color: Color(0xFFE9C46A)),
      bodySmall: const TextStyle(
          color: Color.fromARGB(255, 255, 255, 255), fontSize: 14),
      titleLarge: const TextStyle(
        color: Color(0xFFF4A261),
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      titleMedium: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontWeight: FontWeight.bold,
      ),
      titleSmall: const TextStyle(color: Color(0xFFE9C46A)),
      labelSmall: TextStyle(color: Color(0xFFE76F51), fontSize: 14));

  // Classic Theme Text
  static final TextTheme _classicTextTheme = _typography.white.copyWith(
      bodyLarge: const TextStyle(color: Color(0xFFFFFFFF)),
      bodyMedium: const TextStyle(color: Color(0xFFFFFFFF)),
      bodySmall: const TextStyle(
          color: Color.fromARGB(255, 255, 255, 255), fontSize: 14),
      titleLarge: const TextStyle(
        color: Color(0xFFE76F51),
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      titleMedium: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontWeight: FontWeight.bold,
      ),
      titleSmall: const TextStyle(color: Color(0xFFFFFFFF)),
      labelSmall: TextStyle(color: Color(0xFFE76F51), fontSize: 14));

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF355070),
    scaffoldBackgroundColor: Colors.white,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Color.fromARGB(255, 1, 54, 64),
      selectionColor: Color(0xFF2A9D8F),
      selectionHandleColor: Colors.blue,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF355070),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: _lightTextTheme,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF355070),
      secondary: Color(0xFF6D597A),
      surface: Color(0xFFced4da),
      error: Color(0xFFE56B6F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onError: Colors.white,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: _classicTextTheme.bodySmall?.copyWith(
        color: _classicTextTheme.bodySmall?.color,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      floatingLabelStyle: TextStyle(color: Color(0xFF2A9D8F)),
      
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    primaryColor: const Color(0xFF264653),
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.white,
      selectionColor: Color(0xFF2A9D8F),
      selectionHandleColor: Colors.blue,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: _darkTextTheme,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF264653),
      secondary: Color(0xFF2A9D8F),
      surface: Color.fromARGB(255, 26, 25, 25),
      error: Color(0xFFE56B6F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.black,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
    ),
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: _classicTextTheme.bodySmall?.copyWith(
        color: _classicTextTheme.bodySmall?.color,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      floatingLabelStyle: TextStyle(color: Color(0xFFE9C46A)),
      labelStyle: TextStyle(color: Colors.grey[300]),
      
    ),
  );

  // Classic Theme
  static final ThemeData classicTheme = ThemeData(
    primaryColor: const Color(0xFF355070),
    scaffoldBackgroundColor: Colors.black,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.white,
      selectionColor: Color(0xFF2A9D8F),
      selectionHandleColor: Colors.blue,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.normal,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: _classicTextTheme,
    colorScheme: const ColorScheme.dark(
      primary: Color.fromARGB(255, 1, 54, 64),
      secondary: Color(0xFFB56576),
      surface: Color(0xFF0B192C),
      error: Color(0xFFE76F51),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF001219),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.blueGrey,
      inactiveTrackColor: Colors.grey[600],
      thumbColor: Colors.white,
      overlayColor: Colors.white.withValues(alpha: 0.2),
      trackHeight: 2.0,
    ),
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: _classicTextTheme.bodySmall?.copyWith(
        color: _classicTextTheme.bodySmall?.color,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      floatingLabelStyle: TextStyle(color: Color(0xFF3a86ff)),
      labelStyle: TextStyle(color: Colors.grey[300]),
      
    ),
  );
}
