// Subtitle Studio v3 - Flutter Application Main Entry Point
// 
// This is a comprehensive subtitle editor application with the following key features:
// - SRT subtitle file editing and creation
// - Video playback with subtitle synchronization
// - Multi-language support with Malayalam normalization
// - Dark/Light theme switching
// - Export functionality
// - Advanced search and replace operations
// - Subtitle timing adjustments
// - Dual subtitle support
// - File association handling for .srt files
//
// Architecture Overview:
// - Uses Isar database for local data persistence
// - Provider pattern for state management (theme, preferences)
// - Media Kit for video playback functionality
// - Custom logging system for debugging and error tracking
// - Modular widget structure for reusable components

import 'package:flutter/material.dart';         // Core Flutter framework
import 'package:flutter/services.dart';        // System services (orientation, clipboard)
import 'package:flutter/foundation.dart';      // Platform detection
import 'package:provider/provider.dart';       // State management
import 'package:isar_community/isar.dart';              // Local database
import 'package:path_provider/path_provider.dart'; // File system access
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Environment variables
import 'dart:async';                          // Async programming utilities

// Application-specific imports
import 'package:subtitle_studio/utils/app_info.dart';        // App version and info utilities
import 'package:subtitle_studio/utils/app_logger.dart';      // Logging system
import 'package:subtitle_studio/utils/intent_handler.dart';  // File association handling
import 'package:subtitle_studio/utils/msone_hotkey_manager.dart'; // Keyboard shortcuts
import 'package:subtitle_studio/widgets/splash_screen.dart'; // Initial splash screen
import 'screens/screen_home.dart';                        // Main home screen
import 'screens/screen_source_view.dart';                 // Source view screen
import 'database/models/models.dart';                     // Database models
import 'themes/theme_provider.dart';                      // Theme management
import 'package:media_kit/media_kit.dart';               // Video playback support

/// Global Isar database instance
/// This is accessible throughout the app for data operations
/// Initialized in main() before app startup
late Isar isar;

/// Application entry point
/// 
/// Initializes all core systems in the correct order:
/// 1. Flutter widget system
/// 2. Logging system for debugging and error tracking
/// 3. Media Kit for video playback
/// 4. App info (version, build number, etc.)
/// 5. Isar database with retry mechanism
/// 6. Device orientation settings
/// 7. Command line arguments processing for file associations
/// 
/// The initialization order is critical for proper app functionality
Future<void> main(List<String> args) async {
  // Ensure Flutter widget system is initialized before other operations
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file (optional, used for Telegram integration)
  await dotenv.load();
  
  // Initialize logging system first - essential for debugging startup issues
  await AppLogger.instance.initialize();
  await AppLogger.instance.info('Application starting...');
  
  // Process command line arguments for file associations (Windows)
  String? initialFile;
  if (args.isNotEmpty) {
    final filePath = args[0];
    final lowercasePath = filePath.toLowerCase();
    if (lowercasePath.endsWith('.srt') || 
        lowercasePath.endsWith('.ass') || 
        lowercasePath.endsWith('.vtt') || 
        lowercasePath.endsWith('.msone')) {
      initialFile = filePath;
      await AppLogger.instance.info('Opening file from command line: $filePath');
    }
  }
  
  // Initialize Media Kit for video playback functionality
  // This must be done before any video-related operations
  MediaKit.ensureInitialized();
  await AppLogger.instance.info('Media Kit initialized');

  // Initialize app information (version, build number, platform details)
  await AppInfo.init();
  await AppLogger.instance.info('App info initialized');
  
  // Initialize hotkey manager for desktop keyboard shortcuts
  await MSoneHotkeyManager.initialize();
  await AppLogger.instance.info('Hotkey manager initialized');
  
  // Initialize Isar database with retry mechanism for better reliability
  // The database stores user preferences, sessions, and subtitle collections
  Isar.initializeIsarCore(download: false);
  await initializeIsarWithRetry();
  
  // Set supported device orientations
  // Supports both portrait and landscape modes for better usability
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Configure system UI overlay style to handle navigation bars properly
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  
  // Enable edge-to-edge mode for proper handling of system bars
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  // Optimize for keyboard performance
  if (defaultTargetPlatform == TargetPlatform.android) {
    // Force immediate keyboard rendering
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      ),
    );
  }
  
  await AppLogger.instance.info('Application initialization completed');
  runApp(MainApp(initialFile: initialFile));
}

/// Initialize Isar database with retry mechanism and exponential backoff
/// 
/// This function handles database initialization failures gracefully by:
/// 1. Attempting to open the database with predefined schemas
/// 2. Retrying on failure with exponential backoff delay
/// 3. Logging all attempts and failures for debugging
/// 4. Throwing error after maximum retries exceeded
/// 
/// The database stores three main collections:
/// - PreferencesSchema: User settings and app preferences
/// - SessionSchema: Editing sessions with file metadata
/// - SubtitleCollectionSchema: Subtitle entries with timing and text
/// 
/// Parameters:
/// - [maxRetries]: Maximum number of retry attempts (default: 3)
/// 
/// Throws: Database initialization error after max retries exceeded
Future<void> initializeIsarWithRetry({int maxRetries = 3}) async {
  final dir = await getApplicationDocumentsDirectory();
  int retryCount = 0;
  Duration delay = const Duration(milliseconds: 500); // Initial delay
  
  while (true) {
    try {
      // Attempt to open Isar database with all required schemas
      isar = await Isar.open(
        [PreferencesSchema, SessionSchema, SubtitleCollectionSchema, DictionaryEntrySchema, CheckpointSchema, VideoPreferencesSchema, TutorialStatusSchema],
        directory: dir.path, 
        name: "subtitlesInstance", // Unique database instance name
      );
      debugPrint('Isar database initialized successfully');
      await AppLogger.instance.info('Isar database initialized successfully');
      return; // Success - exit the retry loop
    } catch (e) {
      retryCount++;
      
      // Check if maximum retries exceeded
      if (retryCount >= maxRetries) {
        debugPrint('Failed to initialize Isar after $maxRetries attempts: $e');
        await AppLogger.instance.fatal(
          'Failed to initialize Isar after $maxRetries attempts',
          context: 'initializeIsarWithRetry',
          extra: {'maxRetries': maxRetries, 'error': e.toString()},
        );
        rethrow; // Give up after max retries
      }
      
      // Log retry attempt and wait before next attempt
      debugPrint('Isar initialization failed (attempt $retryCount/$maxRetries): $e');
      debugPrint('Retrying in ${delay.inMilliseconds}ms...');
      await AppLogger.instance.warning(
        'Isar initialization failed (attempt $retryCount/$maxRetries): $e',
        context: 'initializeIsarWithRetry',
        extra: {
          'retryCount': retryCount,
          'maxRetries': maxRetries,
          'delayMs': delay.inMilliseconds,
          'error': e.toString(),
        },
      );
      await Future.delayed(delay);
      delay *= 2; // Exponential backoff - double the delay each time
    }
  }
}

/// Root application widget using Provider for state management
/// 
/// Sets up the MaterialApp with:
/// - ThemeProvider for dynamic theme switching (dark/light mode)
/// - Custom theme data based on user preferences
/// - Initial navigation to splash screen
/// 
/// The Provider pattern is used for:
/// - Theme management across the entire app
/// - Reactive UI updates when theme changes
/// - Centralized state management for app-wide settings
class MainApp extends StatelessWidget {
  const MainApp({super.key, this.initialFile});
  
  final String? initialFile;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Update system UI overlay style based on theme
          final isDark = themeProvider.themeMode == ThemeMode.dark;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ));
          
          return MaterialApp(
            title: 'Subtitle Studio ${AppInfo.version}',
            theme: themeProvider.getThemeData(),
            home: _getInitialScreen(),
            // Performance optimizations for keyboard responsiveness
            debugShowCheckedModeBanner: false,
            // Enable hardware acceleration for smoother animations
            builder: (context, child) {
              return MediaQuery(
                // Optimize text scaling for consistent performance
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }

  /// Get the appropriate initial screen based on platform
  Widget _getInitialScreen() {
    // On desktop platforms (Windows, macOS, Linux), skip splash screen
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return _buildHomeScreen();
    }
    
    // On mobile platforms, show splash screen
    return SplashTransitionWrapper(initialFile: initialFile);
  }

  /// Build the home screen with initial file handling
  Widget _buildHomeScreen() {
    String? intentFilePath;
    bool isMsoneFile = false;
    
    if (initialFile != null) {
      intentFilePath = initialFile;
      isMsoneFile = IntentHandler.isMsoneFile(initialFile!);
    }
    
    return HomeScreen(
      initialFilePath: intentFilePath,
      initialFileName: intentFilePath != null 
          ? IntentHandler.getFileName(intentFilePath) 
          : null,
      isProjectFile: isMsoneFile,
    );
  }
}

/// Splash screen wrapper that handles app initialization and file intent processing
/// 
/// This widget serves as a transition between the splash screen and main app:
/// 1. Displays splash screen for 5 seconds
/// 2. Checks for file association intents (when app opened via .srt file)
/// 3. Processes initial file data if available
/// 4. Navigates to HomeScreen with optional initial file
/// 
/// File Association Support:
/// - Handles .srt files opened with the app
/// - Extracts file path and name from intent data
/// - Passes file information to HomeScreen for immediate processing
class SplashTransitionWrapper extends StatefulWidget {
  const SplashTransitionWrapper({super.key, this.initialFile});
  
  final String? initialFile;

  @override
  State<SplashTransitionWrapper> createState() => _SplashTransitionWrapperState();
}

/// State class for SplashTransitionWrapper with file intent handling
class _SplashTransitionWrapperState extends State<SplashTransitionWrapper> {
  /// File path from intent data (when app opened via file association)
  String? _intentFilePath;
  /// Additional data for intent file processing
  String? _originalIntentUri;  // Store original content URI for SAF
  /// Whether the intent file is a .msone project file
  bool _isMsoneFile = false;
  /// Whether the app should navigate directly to source view (skip home navigation)
  bool _navigatedToSourceView = false;

  @override
  void initState() {
    super.initState();
    _checkForIntentData();  // Check for file association data
    _navigateToHome();      // Start navigation timer
  }

  /// Check for initial intent data when app is opened via file association
  /// 
  /// This handles scenarios where:
  /// - User double-clicks an .srt file (Android intent or Windows command line)
  /// - App is opened via "Open with" context menu
  /// - File manager sends file to app
  /// 
  /// The file path is stored and passed to HomeScreen for processing
  Future<void> _checkForIntentData() async {
    try {
      // First check for command line argument (Windows)
      if (widget.initialFile != null) {
        final processedPath = await IntentHandler.processFilePath(widget.initialFile!);
        if (processedPath != null) {
          setState(() {
            _intentFilePath = processedPath;
            _isMsoneFile = IntentHandler.isMsoneFile(widget.initialFile!); // Check file type using original path
          });
          await AppLogger.instance.info('File from command line: $_intentFilePath, isMsoneFile: $_isMsoneFile');
        }
        return;
      }
      
      // Then check for Android intent data
      final intentActionInfo = await IntentHandler.getInitialIntentDataWithAction();
      if (intentActionInfo != null) {
        if (IntentHandler.isSrtFile(intentActionInfo.path)) {
          if (intentActionInfo.action == 'source_view') {
            // Navigate directly to Source View and mark that we've navigated
            setState(() {
              _navigatedToSourceView = true;
            });
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SourceViewScreen(
                    filePath: intentActionInfo.path,
                    safUri: intentActionInfo.safUri,
                  ),
                ),
              );
            }
          } else {
            // Default import behavior
            setState(() {
              _intentFilePath = intentActionInfo.path;
              _originalIntentUri = intentActionInfo.safUri;
              _isMsoneFile = false;
            });
          }
        } else if (IntentHandler.isMsoneFile(intentActionInfo.path)) {
          // MSONE files always go to import (no source view for MSONE)
          setState(() {
            _intentFilePath = intentActionInfo.path;
            _originalIntentUri = intentActionInfo.safUri;
            _isMsoneFile = true;
          });
        }
      }
    } catch (e) {
      await AppLogger.instance.warning('Error checking intent data: $e');
    }
  }

  /// Navigate to HomeScreen after splash screen duration
  /// 
  /// Timing considerations:
  /// - 5-second delay allows splash screen animation to complete
  /// - Provides time for background initialization
  /// - Ensures smooth user experience transition
  /// 
  /// Passes file data if available from intent processing
  /// Skips navigation if already navigated to source view
  void _navigateToHome() async {
    // Keep 5 seconds delay since we're now handling the splash screen entirely in Flutter
    await Future.delayed(const Duration(seconds: 5));
    
    // Skip navigation to home if we've already navigated to source view
    if (_navigatedToSourceView) {
      return;
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            initialFilePath: _intentFilePath,
            initialFileName: _intentFilePath != null 
                ? IntentHandler.getFileName(_intentFilePath!) 
                : null,
            isProjectFile: _isMsoneFile,
            originalSafUri: _originalIntentUri,  // Pass original SAF URI
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SvgSplashScreen();
  }
}
