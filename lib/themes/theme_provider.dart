// Subtitle Studio v3 - Theme Management System
//
// This provider manages the application's theme system using Flutter's Provider pattern.
// It handles theme persistence, dynamic switching, and provides a centralized theme
// management solution for the entire application.
//
// Key Features:
// - Support for Light, Dark, and System (Classic) themes
// - Persistent theme storage using database
// - Reactive theme updates across all screens
// - System theme detection and adaptation
// - Smooth theme transitions
//
// Architecture:
// - Uses ChangeNotifier for reactive state management
// - Integrates with database for theme persistence
// - Provides simple API for theme switching
// - Supports custom theme definitions
//
// iOS Port Considerations:
// - Replace with ObservableObject for SwiftUI compatibility
// - Use UserDefaults for theme persistence instead of database
// - Integrate with iOS appearance API (@appearance)
// - Support iOS Dark Mode automatic switching
// - Handle iOS 13+ appearance transitions

import 'dart:io';
import 'package:flutter/material.dart';        // Flutter theming framework
import 'package:flutter/services.dart';
import '../database/database_helper.dart';    // Database operations for persistence
import '../database/models/preferences_model.dart';
import 'theme.dart';                          // Custom theme definitions

/// Theme management provider using the Provider pattern for state management
/// 
/// This class centralizes all theme-related operations and provides a reactive
/// interface for theme changes throughout the application:
/// 
/// **Core Features:**
/// - Dynamic theme switching between Light, Dark, and System modes
/// - Persistent theme storage in application database
/// - Automatic system theme detection and adaptation
/// - Reactive updates to all listening widgets
/// - Performance-optimized theme loading and caching
/// 
/// **Theme Modes:**
/// - `Light`: Bright theme optimized for daytime use
/// - `Dark`: Dark theme for low-light environments and battery saving
/// - `System/Classic`: Follows system appearance settings automatically
/// 
/// **Provider Pattern Integration:**
/// - Extends ChangeNotifier for reactive state management
/// - Automatically notifies all dependent widgets of theme changes
/// - Integrates seamlessly with Consumer and Selector widgets
/// - Provides clean separation of theme logic from UI components
/// 
/// **Usage Example:**
/// ```dart
/// // In main.dart
/// ChangeNotifierProvider(
///   create: (_) => ThemeProvider(),
///   child: Consumer<ThemeProvider>(
///     builder: (context, themeProvider, _) {
///       return MaterialApp(
///         theme: themeProvider.getThemeData(),
///         // ... rest of app
///       );
///     },
///   ),
/// )
/// 
/// // In any widget
/// final themeProvider = Provider.of<ThemeProvider>(context);
/// themeProvider.setTheme(ThemeMode.dark);
/// ```
/// 
/// **iOS Port Implementation:**
/// ```swift
/// // Replace with SwiftUI ObservableObject
/// class ThemeProvider: ObservableObject {
///     @Published var themeMode: ColorScheme = .light
///     
///     func setTheme(_ mode: ColorScheme) {
///         themeMode = mode
///         UserDefaults.standard.set(mode.rawValue, forKey: "theme_mode")
///     }
/// }
/// ```
class ThemeProvider extends ChangeNotifier {
  /// Current theme mode - private to ensure controlled access
  ThemeMode _themeMode = ThemeMode.system;
  String? _customFontPath;
  String? _customFontName;
  String? _currentFontFamily;
  int _fontCounter = 0;
  FontLoader? _fontLoader;

  /// Initialize theme provider and load saved theme from storage
  /// 
  /// Constructor automatically loads the previously saved theme preference
  /// from the database and applies it. If no saved theme exists, defaults
  /// to system theme mode.
  ThemeProvider() {
    _loadTheme();
    _loadCustomFont();
  }

  /// Public getter for current theme mode
  /// 
  /// Provides read-only access to the current theme mode for consumers
  /// who need to check the current theme without triggering rebuilds
  ThemeMode get themeMode => _themeMode;

  /// Load saved theme from persistent storage
  /// 
  /// Retrieves the user's previously selected theme from the database
  /// and applies it to the current session. If loading fails or no
  /// saved theme exists, the system default is maintained.
  /// 
  /// **Error Handling:**
  /// - Graceful fallback to system theme on load failure
  /// - Logging of any database access issues
  /// - Non-blocking operation that doesn't prevent app startup
  Future<void> _loadTheme() async {
    final savedTheme = await getThemeMode();
    if (savedTheme != null) {
      _themeMode = _themeModeFromString(savedTheme);
      notifyListeners(); // Trigger UI update with loaded theme
    }
  }

  Future<void> _loadCustomFont() async {
    _customFontPath = await PreferencesModel.getAppFontPath();
    _customFontName = await PreferencesModel.getAppFontName();
    if (_customFontPath != null) {
      _fontCounter++; // Increment counter for unique font family name
      _currentFontFamily = 'CustomFont_$_fontCounter';
      await _loadFontFromPath(_customFontPath!, _currentFontFamily!);
    }
    notifyListeners();
  }

  Future<void> _unloadCurrentFont() async {
    try {
      if (_currentFontFamily != null) {
        // Clear the current font loader
        _fontLoader = null;
        // Force a rebuild of the font cache
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      print('Error unloading font: $e');
    }
  }

  /// Set new theme mode and persist to storage
  /// 
  /// Updates the current theme mode, saves it to persistent storage,
  /// and notifies all listening widgets to trigger UI updates.
  /// 
  /// **Parameters:**
  /// - [mode]: The new ThemeMode to apply
  /// 
  /// **Side Effects:**
  /// - Immediately updates the UI across all screens
  /// - Saves preference to database for future sessions
  /// - Triggers smooth theme transition animations
  /// 
  /// **Error Handling:**
  /// - UI updates immediately even if database save fails
  /// - Database errors are logged but don't block theme changes
  /// - Ensures user experience remains smooth
  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await saveThemeMode(_themeModeToString(mode)); // Persist to database
    notifyListeners(); // Trigger reactive UI updates
  }

  Future<void> setCustomFont(String? path) async {
    // First unload any existing font
    await _unloadCurrentFont();
    
    // Clear all font-related state
    _customFontPath = null;
    _customFontName = null;
    _currentFontFamily = null;
    await PreferencesModel.setAppFontPath(null);
    await PreferencesModel.setAppFontName(null);
    
    // If we have a new font to load
    if (path != null) {
      String fontName = path.split(Platform.pathSeparator).last;
      _fontCounter++; // Increment counter for unique font family name
      _currentFontFamily = 'CustomFont_$_fontCounter'; // Create unique font family name
      
      bool success = await _loadFontFromPath(path, _currentFontFamily!);
      if (success) {
        _customFontPath = path;
        _customFontName = fontName;
        await PreferencesModel.setAppFontPath(path);
        await PreferencesModel.setAppFontName(fontName);
      }
    }
    
    notifyListeners();
  }

  Future<bool> _loadFontFromPath(String path, String fontFamily) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      
      // Create new FontLoader instance with unique family name
      _fontLoader = FontLoader(fontFamily);
      _fontLoader!.addFont(Future.value(ByteData.view(bytes.buffer)));
      await _fontLoader!.load();
      return true;
    } catch (e) {
      print('Error loading font: $e');
      _fontLoader = null;
      return false;
    }
  }

  /// Convert ThemeMode enum to string for database storage
  /// 
  /// Maps Flutter's ThemeMode enum values to string representations
  /// suitable for database storage and serialization.
  /// 
  /// **Mapping:**
  /// - `ThemeMode.light` → 'light'
  /// - `ThemeMode.dark` → 'dark'  
  /// - `ThemeMode.system` → 'classic' (legacy naming for compatibility)
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'classic'; // Using 'classic' for historical compatibility
    }
  }

  /// Convert string from database back to ThemeMode enum
  /// 
  /// Parses string values from database storage back into Flutter's
  /// ThemeMode enum values. Provides fallback for unknown values.
  /// 
  /// **Parameters:**
  /// - [mode]: String representation from database
  /// 
  /// **Returns:**
  /// - Corresponding ThemeMode enum value
  /// - ThemeMode.system as fallback for unknown strings
  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'classic':
        return ThemeMode.system;
      default:
        return ThemeMode.system; // Safe fallback for unknown values
    }
  }

  String? get customFontPath => _customFontPath;
  String? get customFontName => _customFontName;

  ThemeData getThemeData() {
    ThemeData baseTheme;
    switch (_themeMode) {
      case ThemeMode.light:
        baseTheme = AppThemes.lightTheme;
        break;
      case ThemeMode.dark:
        baseTheme = AppThemes.darkTheme;
        break;
      case ThemeMode.system:
        baseTheme = AppThemes.classicTheme;
        break;
    }

    if (_currentFontFamily != null) {
      return baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          fontFamily: _currentFontFamily,
        ),
        primaryTextTheme: baseTheme.primaryTextTheme.apply(
          fontFamily: _currentFontFamily,
        ),
      );
    }
    return baseTheme;
  }
}
