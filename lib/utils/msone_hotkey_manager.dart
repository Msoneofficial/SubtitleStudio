// Subtitle Studio - Hotkey Manager Utility
//
// This utility provides centralized keyboard shortcut management using the hotkey_manager package.
// It handles global and application-level shortcuts for desktop platforms.
//
// Features:
// - Global shortcuts that work even when app is not focused
// - Application shortcuts that only work when app is focused
// - Platform-specific hotkey management
// - Easy registration and unregistration of shortcuts
// - Callback-based action handling

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// Callback function signatures for hotkey actions
typedef HotkeyCallback = void Function();
typedef SaveCallback = void Function();
typedef VideoPlayerCallback = void Function();
typedef NavigationCallback = void Function();
typedef FormattingCallback = void Function(TextFormattingType type);
typedef SelectionCallback = void Function();
typedef DeleteCallback = void Function();
typedef DictionaryCallback = void Function();
typedef UtilityCallback = void Function();

/// Text formatting types for shortcuts
enum TextFormattingType { bold, italic, underline }

/// Hotkey action types
enum HotkeyAction {
  playPause,
  nextLine,
  previousLine,
  boldFormat,
  italicFormat,
  save,
  delete,
  toggleSelection,
  copy,
  // New actions for EditSubtitleScreen
  msoneDictionary,
  olamDictionary,
  urbanDictionary,
  colorPicker,
  markLine,
  markLineAndComment,
  jumpToLine,
  help,
  settings,
  // New actions for EditScreen
  editCurrentLine,
  findReplace,
  gotoLine,
  saveProject,
  // Split and merge actions
  splitLine,
  mergeLine,
  // Navigation action
  popScreen,
  // HomeScreen actions
  openSrtFile,
  importMsoneFile,
  extractSubtitleFromVideo,
  createNew,
  // Video playback actions
  toggleRepeat,
  toggleRepeatRange,
  toggleFullscreen,
  // Video sync action
  syncWithVideo,
  // Marked lines sheet action
  showMarkedLines,
  // Paste original text action
  pasteOriginal,
}

/// Centralized hotkey management using hotkey_manager package
class MSoneHotkeyManager {
  static MSoneHotkeyManager? _instance;
  static MSoneHotkeyManager get instance =>
      _instance ??= MSoneHotkeyManager._();

  MSoneHotkeyManager._();

  final Map<HotkeyAction, HotkeyCallback> _callbacks = {};
  final Map<HotkeyAction, HotKey> _registeredHotkeys = {};
  bool _isInitialized = false;

  /// Initialize the hotkey manager (call once at app startup)
  static Future<void> initialize() async {
    final manager = MSoneHotkeyManager.instance;

    // Only initialize on desktop platforms
    if (!_isDesktopPlatform()) {
      return;
    }

    try {
      // Initialize hotkey_manager package
      await hotKeyManager.unregisterAll();

      manager._isInitialized = true;
      debugPrint('MSoneHotkeyManager initialized for desktop platform');
    } catch (e) {
      debugPrint('Failed to initialize MSoneHotkeyManager: $e');
    }
  }

  /// Check if running on desktop platform
  static bool _isDesktopPlatform() {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Register a callback for a specific hotkey action
  Future<void> registerCallback(
    HotkeyAction action,
    HotkeyCallback callback,
  ) async {
    // Removed excessive debug logging that was causing performance issues
    // debugPrint('DEBUG: Storing callback for $action in _callbacks map');
    _callbacks[action] = callback;
    // debugPrint('DEBUG: _callbacks now contains: ${_callbacks.keys.toList()}');
    await _registerSystemHotkey(action);
  }

  /// Unregister a callback for a specific hotkey action
  Future<void> unregisterCallback(HotkeyAction action) async {
    _callbacks.remove(action);
    await _unregisterSystemHotkey(action);
  }

  /// Register all standard shortcuts for the application
  Future<void> registerStandardShortcuts({
    SaveCallback? onSave,
    VideoPlayerCallback? onPlayPause,
    NavigationCallback? onNextLine,
    NavigationCallback? onPreviousLine,
    FormattingCallback? onTextFormatting,
    SelectionCallback? onToggleSelection,
    DeleteCallback? onDelete,
    // New EditSubtitleScreen callbacks
    DictionaryCallback? onMsoneDictionary,
    DictionaryCallback? onOlamDictionary,
    DictionaryCallback? onUrbanDictionary,
    UtilityCallback? onColorPicker,
    UtilityCallback? onMarkLine,
    UtilityCallback? onMarkLineAndComment,
    UtilityCallback? onJumpToLine,
    UtilityCallback? onHelp,
    UtilityCallback? onSettings,
    // New EditScreen callbacks
    UtilityCallback? onEditCurrentLine,
    UtilityCallback? onFindReplace,
    UtilityCallback? onGotoLine,
    SaveCallback? onSaveProject,
    // Split and merge callbacks
    UtilityCallback? onSplitLine,
    UtilityCallback? onMergeLine,
    // Navigation callback
    UtilityCallback? onPopScreen,
    // Video sync callback
    UtilityCallback? onSyncWithVideo,
    // Marked lines sheet callback
    UtilityCallback? onShowMarkedLines,
    // Paste original callback
    UtilityCallback? onPasteOriginal,
  }) async {
    if (onSave != null) {
      await registerCallback(HotkeyAction.save, onSave);
    }
    if (onPlayPause != null) {
      await registerCallback(HotkeyAction.playPause, onPlayPause);
    }
    if (onNextLine != null) {
      await registerCallback(HotkeyAction.nextLine, onNextLine);
    }
    if (onPreviousLine != null) {
      await registerCallback(HotkeyAction.previousLine, onPreviousLine);
    }
    if (onTextFormatting != null) {
      await registerCallback(
        HotkeyAction.boldFormat,
        () => onTextFormatting(TextFormattingType.bold),
      );
      await registerCallback(
        HotkeyAction.italicFormat,
        () => onTextFormatting(TextFormattingType.italic),
      );
    }
    if (onToggleSelection != null) {
      await registerCallback(HotkeyAction.toggleSelection, onToggleSelection);
    }
    if (onDelete != null) {
      await registerCallback(HotkeyAction.delete, onDelete);
    }
    // Register new EditSubtitleScreen shortcuts
    if (onMsoneDictionary != null) {
      await registerCallback(HotkeyAction.msoneDictionary, onMsoneDictionary);
    }
    if (onOlamDictionary != null) {
      await registerCallback(HotkeyAction.olamDictionary, onOlamDictionary);
    }
    if (onUrbanDictionary != null) {
      await registerCallback(HotkeyAction.urbanDictionary, onUrbanDictionary);
    }
    if (onColorPicker != null) {
      await registerCallback(HotkeyAction.colorPicker, onColorPicker);
    }
    if (onMarkLine != null) {
      await registerCallback(HotkeyAction.markLine, onMarkLine);
    }
    if (onMarkLineAndComment != null) {
      await registerCallback(HotkeyAction.markLineAndComment, onMarkLineAndComment);
    }
    if (onJumpToLine != null) {
      await registerCallback(HotkeyAction.jumpToLine, onJumpToLine);
    }
    if (onHelp != null) {
      await registerCallback(HotkeyAction.help, onHelp);
    }
    if (onSettings != null) {
      await registerCallback(HotkeyAction.settings, onSettings);
    }
    // Register new EditScreen shortcuts
    if (onEditCurrentLine != null) {
      await registerCallback(HotkeyAction.editCurrentLine, onEditCurrentLine);
    }
    if (onFindReplace != null) {
      await registerCallback(HotkeyAction.findReplace, onFindReplace);
    }
    if (onGotoLine != null) {
      await registerCallback(HotkeyAction.gotoLine, onGotoLine);
    }
    if (onSaveProject != null) {
      await registerCallback(HotkeyAction.saveProject, onSaveProject);
    }
    // Register split and merge shortcuts
    if (onSplitLine != null) {
      await registerCallback(HotkeyAction.splitLine, onSplitLine);
    }
    if (onMergeLine != null) {
      debugPrint('DEBUG: Registering mergeLine callback');
      await registerCallback(HotkeyAction.mergeLine, onMergeLine);
      debugPrint('DEBUG: mergeLine callback registered successfully');
    } else {
      debugPrint('DEBUG: onMergeLine callback is null - NOT registering');
    }
    // Register navigation shortcuts
    if (onPopScreen != null) {
      await registerCallback(HotkeyAction.popScreen, onPopScreen);
    }
    // Register video sync shortcuts
    if (onSyncWithVideo != null) {
      await registerCallback(HotkeyAction.syncWithVideo, onSyncWithVideo);
    }
    // Register marked lines sheet shortcuts
    if (onShowMarkedLines != null) {
      await registerCallback(HotkeyAction.showMarkedLines, onShowMarkedLines);
    }
    // Register paste original shortcuts
    if (onPasteOriginal != null) {
      await registerCallback(HotkeyAction.pasteOriginal, onPasteOriginal);
    }
  }

  /// Get the primary modifier key based on platform
  /// Returns Command (meta) on macOS, Control on other platforms
  HotKeyModifier get _primaryModifier {
    return defaultTargetPlatform == TargetPlatform.macOS
        ? HotKeyModifier.meta
        : HotKeyModifier.control;
  }

  /// Get hotkey configuration for an action
  HotKey? _getHotkeyForAction(HotkeyAction action) {
    switch (action) {
      case HotkeyAction.playPause:
        // Use Shift+Space for macOS, Ctrl+Space for Windows/Linux
        return HotKey(
          key: PhysicalKeyboardKey.space,
          modifiers: [
            defaultTargetPlatform == TargetPlatform.macOS
                ? HotKeyModifier.shift
                : HotKeyModifier.control
          ],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.save:
        return HotKey(
          key: PhysicalKeyboardKey.keyS,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.nextLine:
        return HotKey(
          key: PhysicalKeyboardKey.period,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.previousLine:
        return HotKey(
          key: PhysicalKeyboardKey.comma,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.boldFormat:
        return HotKey(
          key: PhysicalKeyboardKey.keyB,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.italicFormat:
        return HotKey(
          key: PhysicalKeyboardKey.keyI,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.delete:
        return HotKey(
          key: PhysicalKeyboardKey.delete,
          modifiers: [HotKeyModifier.shift],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.toggleSelection:
        // This is handled via mouse events, not hotkeys
        return null;
      case HotkeyAction.copy:
        return HotKey(
          key: PhysicalKeyboardKey.keyC,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      // New EditSubtitleScreen shortcuts
      case HotkeyAction.msoneDictionary:
        return HotKey(
          key: PhysicalKeyboardKey.keyM,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.olamDictionary:
        return HotKey(
          key: PhysicalKeyboardKey.keyO,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.urbanDictionary:
        return HotKey(
          key: PhysicalKeyboardKey.keyU,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.colorPicker:
        return HotKey(
          key: PhysicalKeyboardKey.keyC,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.markLine:
        return HotKey(
          key: PhysicalKeyboardKey.keyM,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.markLineAndComment:
        return HotKey(
          key: PhysicalKeyboardKey.keyM,
          modifiers: [_primaryModifier, HotKeyModifier.shift],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.jumpToLine:
        return HotKey(
          key: PhysicalKeyboardKey.keyJ,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.help:
        // On macOS, use Cmd+Shift+H to avoid conflict with system hide window shortcut
        return HotKey(
          key: PhysicalKeyboardKey.keyH,
          modifiers: defaultTargetPlatform == TargetPlatform.macOS
              ? [HotKeyModifier.meta, HotKeyModifier.shift]
              : [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.settings:
        return HotKey(
          key: PhysicalKeyboardKey.keyS,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.inapp,
        );
      // New EditScreen shortcuts
      case HotkeyAction.editCurrentLine:
        return HotKey(
          key: PhysicalKeyboardKey.enter,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.findReplace:
        return HotKey(
          key: PhysicalKeyboardKey.keyF,
          modifiers: [HotKeyModifier.control],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.gotoLine:
        return HotKey(
          key: PhysicalKeyboardKey.keyJ,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.saveProject:
        return HotKey(
          key: PhysicalKeyboardKey.keyE,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      // Navigation shortcuts
      case HotkeyAction.popScreen:
        return HotKey(
          key: PhysicalKeyboardKey.backspace,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      // HomeScreen shortcuts
      case HotkeyAction.openSrtFile:
        return HotKey(
          key: PhysicalKeyboardKey.keyO,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.importMsoneFile:
        return HotKey(
          key: PhysicalKeyboardKey.keyP,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.extractSubtitleFromVideo:
        return HotKey(
          key: PhysicalKeyboardKey.keyE,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.createNew:
        return HotKey(
          key: PhysicalKeyboardKey.keyN,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      // Video playback shortcuts
      case HotkeyAction.toggleRepeat:
        return HotKey(
          key: PhysicalKeyboardKey.keyR,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.toggleRepeatRange:
        return HotKey(
          key: PhysicalKeyboardKey.keyR,
          modifiers: [_primaryModifier, HotKeyModifier.shift],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.toggleFullscreen:
        // On macOS, use Cmd+F; on other platforms, use F11
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          return HotKey(
            key: PhysicalKeyboardKey.keyF,
            modifiers: [HotKeyModifier.meta],
            scope: HotKeyScope.inapp,
          );
        } else {
          return HotKey(
            key: PhysicalKeyboardKey.f11,
            modifiers: [],
            scope: HotKeyScope.inapp,
          );
        }
      // Split and merge shortcuts
      case HotkeyAction.splitLine:
        return HotKey(
          key: PhysicalKeyboardKey.keyV,
          modifiers: [_primaryModifier, HotKeyModifier.alt],
          scope: HotKeyScope.inapp,
        );
      case HotkeyAction.mergeLine:
        return HotKey(
          key: PhysicalKeyboardKey.keyL,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.inapp,
        );
      // Video sync shortcut
      case HotkeyAction.syncWithVideo:
        return HotKey(
          key: PhysicalKeyboardKey.slash,
          modifiers: [_primaryModifier],
          scope: HotKeyScope.inapp,
        );
      // Marked lines sheet shortcut
      case HotkeyAction.showMarkedLines:
        return HotKey(
          key: PhysicalKeyboardKey.keyL,
          modifiers: [_primaryModifier, HotKeyModifier.shift],
          scope: HotKeyScope.inapp,
        );
      // Paste original shortcut
      case HotkeyAction.pasteOriginal:
        return HotKey(
          key: PhysicalKeyboardKey.keyV,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.inapp,
        );
    }
  }

  /// Register system-level hotkey for an action
  Future<void> _registerSystemHotkey(HotkeyAction action) async {
    if (!_isInitialized || !_isDesktopPlatform()) {
      return;
    }

    final hotkey = _getHotkeyForAction(action);
    if (hotkey == null) {
      return;
    }

    try {
      // Unregister existing hotkey if any
      await _unregisterSystemHotkey(action);

      // Register the new hotkey
      await hotKeyManager.register(
        hotkey,
        keyDownHandler: (_) {
          debugPrint('DEBUG: Hotkey pressed for action: $action');
          final callback = _callbacks[action];
          if (callback != null) {
            debugPrint('DEBUG: Executing callback for action: $action');
            callback();
          } else {
            debugPrint('DEBUG: No callback found for action: $action');
          }
        },
      );

      _registeredHotkeys[action] = hotkey;
      debugPrint('Registered system hotkey for: $action');
    } catch (e) {
      debugPrint('Failed to register hotkey for $action: $e');
    }
  }

  /// Unregister system-level hotkey for an action
  Future<void> _unregisterSystemHotkey(HotkeyAction action) async {
    if (!_isInitialized || !_isDesktopPlatform()) {
      return;
    }

    final hotkey = _registeredHotkeys[action];
    if (hotkey != null) {
      try {
        await hotKeyManager.unregister(hotkey);
        _registeredHotkeys.remove(action);
        debugPrint('Unregistered system hotkey for: $action');
      } catch (e) {
        debugPrint('Failed to unregister hotkey for $action: $e');
      }
    }
  }

  /// Unregister all hotkeys
  Future<void> unregisterAll() async {
    if (!_isInitialized || !_isDesktopPlatform()) {
      return;
    }

    try {
      await hotKeyManager.unregisterAll();
      _callbacks.clear();
      _registeredHotkeys.clear();
      debugPrint('All MSone hotkeys unregistered');
    } catch (e) {
      debugPrint('Failed to unregister all hotkeys: $e');
    }
  }

  /// Unregister EditSubtitleScreen specific shortcuts only
  Future<void> unregisterEditSubtitleScreenShortcuts() async {
    if (!_isInitialized || !_isDesktopPlatform()) {
      return;
    }

    // List of actions specific to EditSubtitleScreen that don't conflict with other screens
    // Note: help, settings, popScreen, nextLine, previousLine, markLine, and markLineAndComment are NOT included because they're shared with EditScreen
    final editSubtitleSpecificActions = [
      HotkeyAction.save,
      // HotkeyAction.nextLine,        // Removed: shared with EditScreen
      // HotkeyAction.previousLine,    // Removed: shared with EditScreen
      HotkeyAction.boldFormat,
      HotkeyAction.italicFormat,
      HotkeyAction.delete,
      HotkeyAction.msoneDictionary,
      HotkeyAction.olamDictionary,
      HotkeyAction.urbanDictionary,
      HotkeyAction.colorPicker,
      // HotkeyAction.markLine,           // Removed: shared with EditScreen (Ctrl+M)
      // HotkeyAction.markLineAndComment, // Removed: shared with EditScreen (Ctrl+Shift+M)
      HotkeyAction.jumpToLine,
      // Split and merge shortcuts specific to EditSubtitleScreen
      HotkeyAction.splitLine,
      HotkeyAction.mergeLine,
      // Video control shortcuts specific to EditSubtitleScreen
      HotkeyAction.toggleRepeat,
      HotkeyAction.toggleRepeatRange,
      // Video sync shortcut specific to EditSubtitleScreen
      HotkeyAction.syncWithVideo,
      // Note: toggleFullscreen is shared between EditScreen and EditSubtitleScreen, so it's not unregistered here
      // Note: showMarkedLines is shared between EditScreen and EditSubtitleScreen, so it's not unregistered here
      // Note: markLine and markLineAndComment are shared between EditScreen and EditSubtitleScreen, so they're not unregistered here
    ];

    try {
      for (final action in editSubtitleSpecificActions) {
        await unregisterCallback(action);
      }
      debugPrint(
        'EditSubtitleScreen specific hotkeys unregistered (shared shortcuts preserved)',
      );
    } catch (e) {
      debugPrint('Failed to unregister EditSubtitleScreen hotkeys: $e');
    }
  }

  /// Unregister MainEditScreen specific shortcuts only
  Future<void> unregisterMainEditScreenShortcuts() async {
    if (!_isInitialized || !_isDesktopPlatform()) {
      return;
    }

    // List of actions specific to MainEditScreen that don't conflict with other screens
    final editScreenActions = [
      HotkeyAction.playPause,
      HotkeyAction.toggleSelection,
      HotkeyAction.delete,
      HotkeyAction.save,
      HotkeyAction.copy,
      // HotkeyAction.nextLine,        // Removed: shared with EditSubtitleScreen
      // HotkeyAction.previousLine,    // Removed: shared with EditSubtitleScreen
      HotkeyAction.editCurrentLine,
      HotkeyAction.markLine,
      HotkeyAction.markLineAndComment,
      HotkeyAction.findReplace,
      HotkeyAction.gotoLine,
      HotkeyAction.saveProject,
      HotkeyAction.toggleFullscreen, // Only fullscreen, no repeat mode
      // Note: We don't unregister 'help', 'settings', 'popScreen', and 'showMarkedLines' here because
      // they are shared across screens and should remain active when going back to HomeScreen.
    ];

    try {
      for (final action in editScreenActions) {
        await unregisterCallback(action);
      }
      debugPrint(
        'MainEditScreen hotkeys unregistered (excluding shared shortcuts)',
      );
    } catch (e) {
      debugPrint('Failed to unregister MainEditScreen hotkeys: $e');
    }
  }

  /// Force re-register shared shortcuts that might have been overridden
  Future<void> forceRegisterSharedShortcuts({
    UtilityCallback? onHelp,
    UtilityCallback? onSettings,
    NavigationCallback? onNextLine,
    NavigationCallback? onPreviousLine,
  }) async {
    if (!_isInitialized || !_isDesktopPlatform()) {
      return;
    }

    try {
      // Force re-register help and settings shortcuts
      if (onHelp != null) {
        // Unregister first to clear any existing callback
        await _unregisterSystemHotkey(HotkeyAction.help);
        _callbacks.remove(HotkeyAction.help);
        // Then register with new callback
        await registerCallback(HotkeyAction.help, onHelp);
      }

      if (onSettings != null) {
        // Unregister first to clear any existing callback
        await _unregisterSystemHotkey(HotkeyAction.settings);
        _callbacks.remove(HotkeyAction.settings);
        // Then register with new callback
        await registerCallback(HotkeyAction.settings, onSettings);
      }

      // Force re-register navigation shortcuts
      if (onNextLine != null) {
        // Unregister first to clear any existing callback
        await _unregisterSystemHotkey(HotkeyAction.nextLine);
        _callbacks.remove(HotkeyAction.nextLine);
        // Then register with new callback
        await registerCallback(HotkeyAction.nextLine, onNextLine);
      }

      if (onPreviousLine != null) {
        // Unregister first to clear any existing callback
        await _unregisterSystemHotkey(HotkeyAction.previousLine);
        _callbacks.remove(HotkeyAction.previousLine);
        // Then register with new callback
        await registerCallback(HotkeyAction.previousLine, onPreviousLine);
      }

      debugPrint('Shared shortcuts force re-registered');
    } catch (e) {
      debugPrint('Failed to force re-register shared shortcuts: $e');
    }
  }

  /// Dispose of all hotkeys (call on app shutdown)
  Future<void> dispose() async {
    await unregisterAll();
    _isInitialized = false;
    debugPrint('MSoneHotkeyManager disposed');
  }

  /// Check if hotkeys are supported on current platform
  bool get isSupported => _isDesktopPlatform();
}

/// Extension for easy screen-specific shortcut registration
extension MSoneHotkeyManagerExt on MSoneHotkeyManager {
  /// Register edit screen shortcuts
  Future<void> registerEditScreenShortcuts({
    required SaveCallback onSave,
    required NavigationCallback onNextLine,
    required NavigationCallback onPreviousLine,
    required FormattingCallback onTextFormatting,
    required DeleteCallback onDelete,
    VideoPlayerCallback? onPlayPause,
    // New EditSubtitleScreen shortcuts
    DictionaryCallback? onMsoneDictionary,
    DictionaryCallback? onOlamDictionary,
    DictionaryCallback? onUrbanDictionary,
    UtilityCallback? onColorPicker,
    UtilityCallback? onMarkLine,
    UtilityCallback? onJumpToLine,
    UtilityCallback? onHelp,
    UtilityCallback? onSettings,
    UtilityCallback? onPopScreen,
    // Video control shortcuts for EditSubtitleScreen
    UtilityCallback? onToggleRepeat,
    UtilityCallback? onToggleRepeatRange,
    UtilityCallback? onToggleFullscreen,
  }) async {
    await registerStandardShortcuts(
      onSave: onSave,
      onNextLine: onNextLine,
      onPreviousLine: onPreviousLine,
      onTextFormatting: onTextFormatting,
      onDelete: onDelete,
      onPlayPause: onPlayPause,
      onMsoneDictionary: onMsoneDictionary,
      onOlamDictionary: onOlamDictionary,
      onUrbanDictionary: onUrbanDictionary,
      onColorPicker: onColorPicker,
      onMarkLine: onMarkLine,
      onJumpToLine: onJumpToLine,
      onHelp: onHelp,
      onSettings: onSettings,

      onPopScreen: onPopScreen,
    );

    // Register video control shortcuts specific to EditSubtitleScreen
    if (onToggleRepeat != null) {
      await registerCallback(HotkeyAction.toggleRepeat, onToggleRepeat);
    }
    if (onToggleRepeatRange != null) {
      await registerCallback(
        HotkeyAction.toggleRepeatRange,
        onToggleRepeatRange,
      );
    }
    if (onToggleFullscreen != null) {
      await registerCallback(HotkeyAction.toggleFullscreen, onToggleFullscreen);
    }
  }

  /// Register hotkey shortcuts specific to EditSubtitleScreen
  Future<void> registerEditSubtitleScreenShortcuts({
    required SaveCallback onSave,
    required NavigationCallback onNextLine,
    required NavigationCallback onPreviousLine,
    required FormattingCallback onTextFormatting,
    required DeleteCallback onDelete,
    VideoPlayerCallback? onPlayPause,
    // EditSubtitleScreen-specific shortcuts
    DictionaryCallback? onMsoneDictionary,
    DictionaryCallback? onOlamDictionary,
    DictionaryCallback? onUrbanDictionary,
    UtilityCallback? onColorPicker,
    UtilityCallback? onMarkLine,
    UtilityCallback? onMarkLineAndComment,
    UtilityCallback? onJumpToLine,
    UtilityCallback? onHelp,
    UtilityCallback? onSettings,
    UtilityCallback? onPopScreen,
    // Split and merge shortcuts
    UtilityCallback? onSplitLine,
    UtilityCallback? onMergeLine,
    // Video control shortcuts for EditSubtitleScreen
    UtilityCallback? onToggleRepeat,
    UtilityCallback? onToggleRepeatRange,
    UtilityCallback? onToggleFullscreen,
    // Video sync shortcut
    UtilityCallback? onSyncWithVideo,
    // Marked lines sheet shortcut
    UtilityCallback? onShowMarkedLines,
    // Paste original shortcut
    UtilityCallback? onPasteOriginal,
  }) async {
    await registerStandardShortcuts(
      onSave: onSave,
      onNextLine: onNextLine,
      onPreviousLine: onPreviousLine,
      onTextFormatting: onTextFormatting,
      onDelete: onDelete,
      onPlayPause: onPlayPause,
      onMsoneDictionary: onMsoneDictionary,
      onOlamDictionary: onOlamDictionary,
      onUrbanDictionary: onUrbanDictionary,
      onColorPicker: onColorPicker,
      onMarkLine: onMarkLine,
      onMarkLineAndComment: onMarkLineAndComment,
      onJumpToLine: onJumpToLine,
      onHelp: onHelp,
      onSettings: onSettings,
      onSplitLine: onSplitLine,
      onMergeLine: onMergeLine,
      onPopScreen: onPopScreen,
      onSyncWithVideo: onSyncWithVideo,
      onShowMarkedLines: onShowMarkedLines,
      onPasteOriginal: onPasteOriginal,
    );

    // Register video control shortcuts specific to EditSubtitleScreen
    if (onToggleRepeat != null) {
      await registerCallback(HotkeyAction.toggleRepeat, onToggleRepeat);
    }
    if (onToggleRepeatRange != null) {
      await registerCallback(
        HotkeyAction.toggleRepeatRange,
        onToggleRepeatRange,
      );
    }
    if (onToggleFullscreen != null) {
      await registerCallback(HotkeyAction.toggleFullscreen, onToggleFullscreen);
    }
  }

  /// Register main edit screen shortcuts
  Future<void> registerMainEditScreenShortcuts({
    required VideoPlayerCallback onPlayPause,
    required SelectionCallback onToggleSelection,
    required DeleteCallback onDelete,
    SaveCallback? onSave,
    UtilityCallback? onCopy,
    // Navigation callbacks
    NavigationCallback? onNextLine,
    NavigationCallback? onPreviousLine,
    // New EditScreen shortcuts
    UtilityCallback? onEditCurrentLine,
    UtilityCallback? onMarkLine,
    UtilityCallback? onMarkLineAndComment,
    UtilityCallback? onFindReplace,
    UtilityCallback? onGotoLine,
    UtilityCallback? onHelp,
    UtilityCallback? onSettings,
    SaveCallback? onSaveProject,
    UtilityCallback? onPopScreen,
    // Video playback shortcuts (only fullscreen, no repeat mode)
    UtilityCallback? onToggleFullscreen,
    // Marked lines sheet shortcut
    UtilityCallback? onShowMarkedLines,
  }) async {
    await registerStandardShortcuts(
      onPlayPause: onPlayPause,
      onToggleSelection: onToggleSelection,
      onDelete: onDelete,
      onSave: onSave,
      onNextLine: onNextLine,
      onPreviousLine: onPreviousLine,
      onEditCurrentLine: onEditCurrentLine,
      onMarkLine: onMarkLine,
      onMarkLineAndComment: onMarkLineAndComment,
      onFindReplace: onFindReplace,
      onGotoLine: onGotoLine,
      onHelp: onHelp,
      onSettings: onSettings,
      onSaveProject: onSaveProject,
      onPopScreen: onPopScreen,
      onShowMarkedLines: onShowMarkedLines,
    );

    // Register copy shortcut
    if (onCopy != null) {
      await registerCallback(HotkeyAction.copy, onCopy);
    }

    // Register video playback shortcuts (only fullscreen)
    if (onToggleFullscreen != null) {
      await registerCallback(HotkeyAction.toggleFullscreen, onToggleFullscreen);
    }
  }

  /// Register HomeScreen shortcuts
  Future<void> registerHomeScreenShortcuts({
    UtilityCallback? onOpenSrtFile,
    UtilityCallback? onImportMsoneFile,
    UtilityCallback? onExtractSubtitleFromVideo,
    UtilityCallback? onCreateNew,
    UtilityCallback? onHelp,
    UtilityCallback? onSettings,
  }) async {
    if (onOpenSrtFile != null) {
      await registerCallback(HotkeyAction.openSrtFile, onOpenSrtFile);
    }
    if (onImportMsoneFile != null) {
      await registerCallback(HotkeyAction.importMsoneFile, onImportMsoneFile);
    }
    if (onExtractSubtitleFromVideo != null) {
      await registerCallback(
        HotkeyAction.extractSubtitleFromVideo,
        onExtractSubtitleFromVideo,
      );
    }
    if (onCreateNew != null) {
      await registerCallback(HotkeyAction.createNew, onCreateNew);
    }
    if (onHelp != null) {
      await registerCallback(HotkeyAction.help, onHelp);
    }
    if (onSettings != null) {
      await registerCallback(HotkeyAction.settings, onSettings);
    }
  }

  /// Unregister HomeScreen specific shortcuts
  Future<void> unregisterHomeScreenShortcuts() async {
    if (!_isInitialized || !MSoneHotkeyManager._isDesktopPlatform()) {
      return;
    }

    // List of HomeScreen-specific actions that should not be active in other screens
    final homeScreenActions = [
      HotkeyAction.openSrtFile,        // Ctrl+O
      HotkeyAction.importMsoneFile,    // Ctrl+P
      HotkeyAction.extractSubtitleFromVideo, // Ctrl+E (conflicts with EditScreen exportProject)
      HotkeyAction.createNew,          // Ctrl+N
    ];

    try {
      for (final action in homeScreenActions) {
        await unregisterCallback(action);
      }
      debugPrint('HomeScreen specific hotkeys unregistered');
    } catch (e) {
      debugPrint('Failed to unregister HomeScreen hotkeys: $e');
    }
  }
}
