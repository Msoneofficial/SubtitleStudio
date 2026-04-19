// Subtitle Studio v3 - Video Player Widget with Subtitle Overlay
//
// This widget provides comprehensive video playback functionality with integrated
// subtitle display and synchronization. It serves as the core component for
// video-based subtitle editing workflows.
//
// Key Features:
// - Multi-format video playback using Media Kit
// - Real-time subtitle overlay rendering
// - Dual subtitle track support (primary + secondary)
// - Playback controls with frame-accurate seeking
// - Subtitle synchronization with video timeline
// - Custom subtitle styling and positioning
// - Performance optimized for large subtitle files
// - Fullscreen mode with responsive subtitle positioning
//
// Technical Implementation:
// - Media Kit integration for cross-platform video support
// - Custom subtitle rendering with text styling
// - Efficient subtitle lookup using time-based indexing
// - Memory management for long video sessions
// - Thread-safe subtitle updates
// - Responsive UI that adapts to fullscreen mode
//
// iOS Port Considerations:
// - Replace Media Kit with AVPlayer and AVPlayerViewController
// - Use iOS native video controls and AVPlayerLayer
// - Implement subtitle overlay with CATextLayer or UILabel
// - Handle iOS-specific video formats and codecs
// - Adapt to iOS background/foreground lifecycle
// - Use iOS native subtitle rendering if available

import 'package:flutter/material.dart';      // Flutter UI framework
import 'package:flutter/services.dart';     // System services integration
import 'package:flutter/foundation.dart';   // Flutter foundation for kDebugMode
import 'package:flutter/gestures.dart';     // Gesture detection and pointer events
import 'dart:async';                         // Timer functionality
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart'; // Duration utilities
import 'package:subtitle_studio/widgets/loader.dart';           // Loading indicators
import 'package:subtitle_studio/widgets/positioned_subtitle_widget.dart'; // Positioned subtitle rendering
import 'package:subtitle_studio/widgets/comment_dialog.dart';    // Comment dialog for marked lines
import 'package:media_kit/media_kit.dart';                   // Media Kit core functionality
import 'package:media_kit_video/media_kit_video.dart';       // Media Kit video widgets
import 'package:subtitle_studio/utils/ffmpeg_helper.dart';      // FFmpeg integration utilities
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';  // File picker utilities
import 'package:subtitle_studio/utils/platform_file_handler.dart';  // Platform file handler utilities
import 'package:subtitle_studio/utils/saf_path_converter.dart';   // SAF path conversion utilities
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// FontLoader is available via flutter services import above
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/responsive_layout.dart'; // Import responsive layout utilities
import 'package:subtitle_studio/screens/screen_edit_line.dart'; // Import EditSubtitleScreenState

/// Subtitle data structure for video overlay rendering
/// 
/// Represents a single subtitle entry with timing and content information.
/// This class is used throughout the video player for subtitle display
/// and synchronization operations.
/// 
/// **Properties:**
/// - `index`: Sequential number for subtitle ordering and identification
/// - `start`: Exact start time for subtitle display
/// - `end`: Exact end time for subtitle hiding
/// - `text`: Formatted text content with possible styling markup
/// 
/// **iOS Implementation:**
/// Replace with NSObject-based model or Swift struct for better
/// integration with iOS video frameworks
class Subtitle {
  final int index;         // Subtitle sequence number for ordering
  final Duration start;    // Precise start time for display
  final Duration end;      // Precise end time for hiding
  final String text;       // Formatted subtitle text content
  final bool marked;       // Whether this subtitle line is marked
  final String? comment;   // Optional comment for marked lines

  Subtitle({
    required this.index,   // Must be unique within subtitle collection
    required this.start,   // Must be >= 0 and < end time
    required this.end,     // Must be > start time
    required this.text,    // Can contain formatting markup
    this.marked = false,   // Default to false for backward compatibility
    this.comment,          // Optional comment for marked lines
  });
}

/// Advanced video player widget with integrated subtitle overlay system
/// 
/// This widget combines video playback with sophisticated subtitle rendering:
/// 
/// **Video Playback Features:**
/// - Support for multiple video formats (MP4, AVI, MKV, etc.)
/// - Hardware-accelerated decoding where available
/// - Smooth seeking and frame-accurate positioning
/// - Playback speed control and audio management
/// - Fullscreen mode with orientation handling
/// 
/// **Subtitle Integration:**
/// - Real-time subtitle synchronization with video timeline
/// - Dual subtitle track support for language learning
/// - Custom subtitle styling (font, color, outline, shadow)
/// - Subtitle positioning and alignment options
/// - Performance-optimized rendering for long files
/// 
/// **User Interaction:**
/// - Touch controls for play/pause and seeking
/// - Timeline scrubbing with subtitle preview
/// - Volume and brightness gesture controls
/// - Keyboard shortcuts for precise control
/// 
/// **Callback System:**
/// - Position change notifications for external synchronization
/// - Subtitle update callbacks for editing integration
/// - Error handling and recovery notifications
/// 
/// **iOS Port Implementation:**
/// - Replace with AVPlayerViewController for native iOS experience
/// - Use AVPlayerItem with custom subtitle tracks
/// - Implement subtitle overlay with Core Animation layers
/// - Handle iOS-specific video lifecycle and interruptions
/// - Integrate with iOS media center and lock screen controls
class VideoPlayerWidget extends StatefulWidget {
  /// Path to the video file for playback
  /// Supports local files and remote URLs
  final String videoPath;
  
  /// Subtitle collection ID for managing per-video preferences
  /// Used to save/restore audio track selection and other video-specific settings
  final int subtitleCollectionId;
  
  /// Primary subtitle track for display overlay
  /// Contains all subtitle entries with timing information
  final List<Subtitle> subtitles;
  
  /// Optional secondary subtitle track for dual language support
  /// Displayed below or alongside primary subtitles
  final List<Subtitle> secondarySubtitles;
  
  /// Callback fired when video position changes
  /// Used for external synchronization and progress tracking
  final Function(Duration)? onPositionChanged;
  
  /// Callback fired when subtitle data is updated
  /// Allows external components to react to subtitle changes
  final Function()? onSubtitlesUpdated;
  
  /// Callback fired when a subtitle line is marked/unmarked
  /// Parameters: (subtitleIndex, isMarked)
  final Function(int, bool)? onSubtitleMarked;

  /// Callback fired when a comment is added/updated for a subtitle line
  /// Parameters: (subtitleIndex, comment)
  final Function(int, String?)? onSubtitleCommentUpdated;

  /// Callback fired when the active subtitle changes
  /// Parameters: (arrayIndex) - The array index of the active subtitle, or -1 if none
  final Function(int)? onActiveSubtitleChanged;

  /// Callback fired when video play/pause state changes
  /// Parameters: (isPlaying)
  final Function(bool)? onPlayStateChanged;

  /// Callback fired when repeat mode is toggled
  /// Parameters: (isRepeatEnabled)
  final Function(bool)? onRepeatModeToggled;

  /// Whether repeat mode is currently enabled
  final bool isRepeatModeEnabled;

  /// Callback fired when fullscreen mode is exited
  /// Used to trigger subtitle list refresh or other UI updates
  final VoidCallback? onFullscreenExited;

  const VideoPlayerWidget({
    super.key,
    required this.videoPath,                      // Video file path (required)
    required this.subtitleCollectionId,           // Subtitle collection ID for preferences (required)
    required this.subtitles,                      // Primary subtitle track (required)
    this.secondarySubtitles = const [],           // Secondary track (optional)
    this.onPositionChanged,                       // Position callback (optional)
    this.onSubtitlesUpdated,                      // Update callback (optional)
    this.onSubtitleMarked,                        // Mark callback (optional)
    this.onSubtitleCommentUpdated,                // Comment callback (optional)
    this.onActiveSubtitleChanged,                 // Active subtitle callback (optional)
    this.onPlayStateChanged,                      // Play state callback (optional)
    this.onRepeatModeToggled,                     // Repeat mode callback (optional)
    this.isRepeatModeEnabled = false,             // Repeat mode state (optional)
    this.onFullscreenExited,                      // Fullscreen exit callback (optional)
  });

  @override
  VideoPlayerWidgetState createState() => VideoPlayerWidgetState();
}

/// State management class for VideoPlayerWidget
/// 
/// Handles all video playback operations, subtitle synchronization,
/// and user interface updates for the video player component.
/// 
/// **Core Responsibilities:**
/// - Media Kit player lifecycle management
/// - Subtitle timing and display synchronization
/// - User interface state management
/// - Error handling and recovery
/// - Performance optimization for smooth playback
class VideoPlayerWidgetState extends State<VideoPlayerWidget> with AutomaticKeepAliveClientMixin {
  // Media Kit player instances for video playback
  late final Player _player;           // Core media player
  late final VideoController _controller; // Video-specific controller
  
  // Stream subscriptions for proper cleanup
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Tracks>? _tracksSubscription;
  StreamSubscription<Track>? _trackSubscription;
  StreamSubscription<int?>? _widthSubscription;
  
  // Public getter for external access to player instance
  Player get player => _player;
  
  List<Subtitle> _currentSubtitles = [];
  List<Subtitle> _currentSecondarySubtitles = [];

  // Cached framerate value
  double? _cachedFramerate;

  // Custom font handling
  String? _subtitleFontFamily; // family name used in TextStyle
  String? _subtitleFontFilePath; // stored/copy path for display
  double _subtitleFontSize = 16.0; // default size for mobile devices, loaded from prefs

  // Subtitle position management
  double _primarySubtitleVerticalPosition = 0.0; // Vertical position offset for primary subtitles
  double _secondarySubtitleVerticalPosition = 0.0; // Vertical position offset for secondary subtitles

  // Subtitle background toggle
  bool _showSubtitleBackground = true;

  // Track loading and player readiness state
  bool _isLoading = true;
  bool _areSubtitlesEnabled = true;
  
  // Track current playback speed
  double _currentSpeed = 1.0;
  
  // Skip duration (loaded from preferences)
  int _skipDurationSeconds = 10;
  
  // Custom fullscreen management
  bool _isCustomFullscreen = false;
  OverlayEntry? _fullscreenOverlay;
  BuildContext? _originalContext; // Store original context for dialogs
  final GlobalKey<_FullscreenControlsWidgetState> _fullscreenControlsKey = GlobalKey();
  
  // Audio track management
  /// List of available audio tracks in the current video
  /// Updated automatically when tracks are detected
  List<AudioTrack> _availableAudioTracks = [];
  
  /// Currently selected audio track
  /// Null if no track is selected or available
  AudioTrack? _currentAudioTrack;
  
  // Subtitle track management
  /// List of available subtitle tracks in the current video
  /// Updated automatically when tracks are detected
  List<SubtitleTrack> _availableSubtitleTracks = [];
  
  /// Currently selected subtitle track
  /// Null if no track is selected or available
  SubtitleTrack? _currentSubtitleTrack;
  
  // Volume state management
  /// Current volume level (0-100) shared between normal and fullscreen modes
  double _currentVolume = 100.0;
  
  // Audio track initialization state
  /// Flag to prevent saving during initial track setup
  bool _isInitializingTracks = true;
  
  // Removed rebuild counter for better performance
  // int _buildCounter = 0;

  Duration getDuration() {
    return _player.state.duration;
  }

  @override
  void initState() {
    super.initState();
    _currentSubtitles = widget.subtitles;
    _currentSecondarySubtitles = widget.secondarySubtitles;
    _loadSubtitlePreferences();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update subtitles when the widget is updated with new data
    if (widget.subtitles != oldWidget.subtitles) {
      // Removed excessive logging causing performance issues during rebuilds
      // debugPrint('VideoPlayer: Updating subtitles due to widget change');
      updateSubtitles(widget.subtitles);
    }
    
    if (widget.secondarySubtitles != oldWidget.secondarySubtitles) {
      // Removed excessive logging causing performance issues during rebuilds
      // debugPrint('VideoPlayer: Updating secondary subtitles due to widget change');
      updateSecondarySubtitles(widget.secondarySubtitles);
    }

    // Update video if path changed
    if (widget.videoPath != oldWidget.videoPath) {
      debugPrint('VideoPlayer: Video path changed, reinitializing');
      _initializePlayer();
    }
  }

  Future<void> _loadSubtitlePreferences() async {
    try {
      final savedSize = await PreferencesModel.getSubtitleFontSize();
      final savedPath = await PreferencesModel.getSubtitleFontPath();
      final skipDuration = await PreferencesModel.getSkipDurationSeconds();
      final primaryPosition = await PreferencesModel.getPrimarySubtitleVerticalPosition();
      final secondaryPosition = await PreferencesModel.getSecondarySubtitleVerticalPosition();
      final savedVolume = await PreferencesModel.getVideoVolume();
      final showBackground = await PreferencesModel.getShowSubtitleBackground();
      setState(() {
        _subtitleFontSize = savedSize;
        _skipDurationSeconds = skipDuration;
        _primarySubtitleVerticalPosition = primaryPosition;
        _secondarySubtitleVerticalPosition = secondaryPosition;
        _currentVolume = savedVolume;
        _showSubtitleBackground = showBackground;
      });
      if (savedPath != null) {
        // If file exists at saved path, attempt to load it, else clear pref
        final f = File(savedPath);
        if (await f.exists()) {
          await _loadFontFromFile(f);
        } else {
          await PreferencesModel.setSubtitleFontPath(null);
        }
      }
    } catch (e) {
      // ignore errors and keep defaults
    }
  }

  Future<void> _loadFontFromFile(File file) async {
    try {
      final fileName = file.uri.pathSegments.last;
      final family = 'CustomSubtitleFont_${fileName.hashCode}';

      final bytes = await file.readAsBytes();
      final loader = FontLoader(family);
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();

      setState(() {
        _subtitleFontFamily = family;
        _subtitleFontFilePath = file.path;
      });
      await PreferencesModel.setSubtitleFontPath(file.path);
      // Rebuild any custom fullscreen overlay if present
      _fullscreenOverlay?.markNeedsBuild();
    } catch (e) {
      // ignore load failure
    }
  }

  /// Get responsive subtitle font size based on layout
  double _getResponsiveSubtitleFontSize() {
    return ResponsiveLayout.getSubtitleFontSize(context, _subtitleFontSize);
  }

  /// Pick and save a custom font file for subtitle rendering
  /// 
  /// Uses platform-specific file access:
  /// - Android: Storage Access Framework (SAF) for secure font file selection
  /// - Desktop: Traditional file picker with direct file system access
  /// 
  /// Supported font formats: TTF, OTF
  /// The selected font is copied to the app's documents directory and loaded
  /// for use in subtitle rendering across the application.
  Future<void> _pickAndSaveFont(BuildContext context) async {
    // Capture parent context and messenger before awaiting to avoid using deactivated contexts
    final BuildContext parentContext = context;
    
    try {
      PlatformFileInfo? fontFileInfo;
      
      if (Platform.isAndroid) {
        // Use SAF on Android for secure file access
        fontFileInfo = await PlatformFileHandler.readFile(
          mimeTypes: ['font/ttf', 'font/otf', 'application/x-font-ttf', 'application/x-font-opentype', 'application/octet-stream'],
        );
      } else {
        // Use traditional file picker on desktop platforms
        final fontFilePath = await FilePickerSAF.pickFile(
          context: context,
          title: 'Select Font File',
          allowedExtensions: ['.ttf', '.otf'],
        );
        
        if (fontFilePath != null) {
          // Read the file content for desktop platforms
          final sourceFile = File(fontFilePath);
          final content = await sourceFile.readAsBytes();
          
          fontFileInfo = PlatformFileInfo(
            path: fontFilePath,
            content: content,
            isFromSaf: false,
            safUri: null,
          );
        }
      }
      
      if (fontFileInfo == null) return;

      // Create fonts directory in app documents
      final appDoc = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${appDoc.path}${Platform.pathSeparator}fonts');
      if (!await fontsDir.exists()) await fontsDir.create(recursive: true);
      
      // Generate destination file path
      final fileName = fontFileInfo.fileName;
      final dest = File('${fontsDir.path}${Platform.pathSeparator}$fileName');

      // If a previous custom font exists, delete it to replace with new one
      try {
        final prevPath = await PreferencesModel.getSubtitleFontPath();
        if (prevPath != null && prevPath.isNotEmpty) {
          final prevFile = File(prevPath);
          if (await prevFile.exists()) {
            await prevFile.delete();
          }
        }
      } catch (e) {
        // ignore deletion errors
      }

      // Write font data to destination using bytes from PlatformFileInfo
      await dest.writeAsBytes(fontFileInfo.content);

      // Load the font from the saved file
      await _loadFontFromFile(dest);
      
      if (mounted) {
        setState(() {});
        _fullscreenOverlay?.markNeedsBuild();
      }
      
      // Show success message
      SnackbarHelper.showSuccess(parentContext, 'Font loaded successfully');
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(parentContext, 'Failed to load font: $e');
      }
    }
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions to prevent memory leaks
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _tracksSubscription?.cancel();
    _trackSubscription?.cancel();
    _widthSubscription?.cancel();
    
    // Clean up fullscreen overlay if active before disposing player
    if (_isCustomFullscreen) {
      _fullscreenOverlay?.remove();
      _fullscreenOverlay = null;
      _isCustomFullscreen = false;
      
      // Restore system UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    
    _player.dispose();
    super.dispose();
  }

  // Custom fullscreen management methods
  
  /// Enter custom fullscreen mode with our own overlay
  void _enterCustomFullscreen() {
    if (_isCustomFullscreen) return;
    
    // Store original context for dialogs
    _originalContext = context;
    
    setState(() {
      _isCustomFullscreen = true;
    });

    // Force a refresh of the widget state to ensure proper marked status display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // This refresh ensures all subtitle states are correctly synchronized in fullscreen
        });
      }
    });
    
    // Hide system UI for true fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Set orientation based on video aspect ratio
    final videoAspectRatio = _getVideoAspectRatio();
    if (videoAspectRatio > 1.0) {
      // Wide video - prefer landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Tall video - prefer portrait
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    
    // Create fullscreen overlay
    _fullscreenOverlay = OverlayEntry(
      builder: (context) => _buildCustomFullscreenWidget(),
    );
    
    // Insert overlay
    Overlay.of(context).insert(_fullscreenOverlay!);
  }
  
  /// Exit custom fullscreen mode
  void _exitCustomFullscreen() {
    if (!_isCustomFullscreen || !mounted) return;
    
    // Remove overlay safely
    _fullscreenOverlay?.remove();
    _fullscreenOverlay = null;
    
    // Clear original context
    _originalContext = null;
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    
    // Reset orientation to allow all orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Update state only if widget is still mounted
    if (mounted) {
      setState(() {
        _isCustomFullscreen = false;
      });
      
      // Notify parent widget that fullscreen has been exited
      widget.onFullscreenExited?.call();
    }
  }
  
  /// Toggle custom fullscreen mode
  void toggleCustomFullscreen() {
    if (_isCustomFullscreen) {
      _exitCustomFullscreen();
    } else {
      _enterCustomFullscreen();
    }
  }
  
  /// Toggle custom fullscreen mode (private method for internal use)
  void _toggleCustomFullscreen() {
    toggleCustomFullscreen();
  }
  
  /// Build the custom fullscreen widget with complete control
  Widget _buildCustomFullscreenWidget() {
    return Material(
      color: Colors.black,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          // Handle back button/gesture manually
          if (!didPop && mounted && _isCustomFullscreen) {
            _exitCustomFullscreen();
          }
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                _exitCustomFullscreen();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
                _exitCustomFullscreen();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.space) {
                playOrPause();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _seekRelative(const Duration(seconds: -5));
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _seekRelative(const Duration(seconds: 5));
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player taking full screen
              SizedBox.expand(
                child: GestureDetector(
                  // Remove conflicting onTap - let controls handle tap-to-show/hide
                  onDoubleTapDown: (details) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final tapPosition = details.globalPosition.dx;
                    
                    if (tapPosition < screenWidth / 2) {
                      _seekRelative(const Duration(seconds: -10));
                      _showSeekIndicator(context, false);
                    } else {
                      _seekRelative(const Duration(seconds: 10));
                      _showSeekIndicator(context, true);
                    }
                  },
                  child: Video(
                    controller: _controller,
                    controls: NoVideoControls, // No built-in controls in fullscreen
                    subtitleViewConfiguration: const SubtitleViewConfiguration(
                      visible: false, // Disable built-in subtitles
                    ),
                    fit: BoxFit.contain, // This will maintain aspect ratio while filling available space
                  ),
                ),
              ),
              
              // Subtitle overlay for fullscreen (behind controls)
              if (_areSubtitlesEnabled) _buildFullscreenSubtitles(),
              
              // Custom fullscreen controls overlay (on top)
              _buildFullscreenControls(),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Get video aspect ratio for fullscreen display
  double _getVideoAspectRatio() {
    final width = _player.state.width;
    final height = _player.state.height;
    if (width != null && height != null && height > 0) {
      return width / height;
    }
    return 16 / 9; // Default aspect ratio
  }
  
  /// Build fullscreen controls overlay
  Widget _buildFullscreenControls() {
    return StreamBuilder<bool>(
      stream: _player.stream.playing,
      builder: (context, playingSnapshot) {
        return StreamBuilder<Duration>(
          stream: _player.stream.position,
          builder: (context, positionSnapshot) {
            return StreamBuilder<Duration>(
              stream: _player.stream.duration,
              builder: (context, durationSnapshot) {
                final isPlaying = playingSnapshot.data ?? _player.state.playing;
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = durationSnapshot.data ?? _player.state.duration;
                
                return _FullscreenControlsWidget(
                  key: _fullscreenControlsKey,
                  isPlaying: isPlaying,
                  position: position,
                  duration: duration,
                  videoPath: widget.videoPath,
                  areSubtitlesEnabled: _areSubtitlesEnabled,
                  currentSpeed: _currentSpeed,
                  availableAudioTracks: _availableAudioTracks,
                  subtitles: _currentSubtitles,
                  secondarySubtitles: _currentSecondarySubtitles,
                  onExitFullscreen: _exitCustomFullscreen,
                  onToggleSubtitles: () {
                    setState(() {
                      _areSubtitlesEnabled = !_areSubtitlesEnabled;
                    });
                    if (_fullscreenOverlay != null) {
                      _fullscreenOverlay!.markNeedsBuild();
                    }
                  },
                  onSeek: (value) {
                    final newPosition = Duration(
                      milliseconds: (value * duration.inMilliseconds).round(),
                    );
                    _player.seek(newPosition);
                  },
                  onPlayPause: playOrPause,
                  onSeekRelative: _seekRelative,
                  onToggleMute: toggleMute,
                  onSpeedChange: (speed) {
                    setPlaybackSpeed(speed);
                    // Force rebuild of fullscreen overlay to update speed button display
                    if (_fullscreenOverlay != null) {
                      _fullscreenOverlay!.markNeedsBuild();
                    }
                  },
                  onAudioTrackChange: setAudioTrack,
                  onSeekToPreviousSubtitle: _seekToPreviousSubtitle,
                  onSeekToNextSubtitle: _seekToNextSubtitle,
                  formatDuration: _formatDuration,
                  onSubtitleMarked: widget.onSubtitleMarked,
                  onSubtitleCommentUpdated: widget.onSubtitleCommentUpdated,
                  player: _player,
                  originalContext: _originalContext, // Pass original context for dialogs
                  skipDurationSeconds: _skipDurationSeconds, // Pass skip duration
                  videoPlayerState: this, // Pass the video player state directly
                );
              },
            );
          },
        );
      },
    );
  }
  
  /// Build fullscreen subtitles overlay
  Widget _buildFullscreenSubtitles() {
    return StreamBuilder<Duration>(
      key: ValueKey('fullscreen_subtitle_${_subtitleFontSize}_$_subtitleFontFamily'),
      stream: _player.stream.position,
      builder: (context, snapshot) {
        // Use cached active subtitles (now lists) instead of recalculating
        final activeSubtitles = _currentActiveSubtitles;
        final activeSecondarySubtitles = _currentActiveSecondarySubtitles;
        
        final responsiveFontSize = _getResponsiveSubtitleFontSize();
        
        // Use new MultipleOverlappingSubtitlesWidget for intelligent positioning
        return Stack(
          children: [
            // Primary subtitles with intelligent positioning
            if (activeSubtitles.isNotEmpty)
              MultipleOverlappingSubtitlesWidget(
                subtitleTexts: activeSubtitles.map((s) => s.text).toList(),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: responsiveFontSize + 4.0,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  fontFamily: _subtitleFontFamily,
                  background: _showSubtitleBackground
                  ? (Paint()..color = const Color.fromARGB(180, 0, 0, 0))
                  : null,
                  shadows: const [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
                horizontalPadding: 40.0,
                verticalPadding: 30.0,
                topPadding: 30.0,
                isFullscreen: true,
                verticalOffset: _primarySubtitleVerticalPosition,
              ),
            
            // Secondary subtitles (always at top) - also handle positioning if needed
            if (activeSecondarySubtitles.isNotEmpty)
              MultipleOverlappingSubtitlesWidget(
                subtitleTexts: activeSecondarySubtitles.map((s) => s.text).toList(),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: responsiveFontSize + 4.0,
                  fontWeight: FontWeight.normal,
                  height: 1.3,
                  fontFamily: _subtitleFontFamily,
                  background:
                      _showSubtitleBackground
                          ? (Paint()
                            ..color = const Color.fromARGB(180, 0, 0, 0))
                          : null,
                  shadows: const [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
                horizontalPadding: 40.0,
                verticalPadding: 30.0,
                topPadding: 30.0,
                isFullscreen: true,
                verticalOffset: _secondarySubtitleVerticalPosition,
                forceTopPosition: true, // Always display secondary subtitles at top
                primarySubtitleTexts: activeSubtitles.map((s) => s.text).toList(), // Pass for collision detection
              ),
          ],
        );
      },
    );
  }
  


  void seekTo(Duration position) {
    _player.seek(position);
  }

  void pause() {
    _player.pause();
  }
  
  void play() {
    _player.play();
  }
  
  void playOrPause() {
    if (_player.state.playing) {
      pause();
    } else {
      play();
    }
  }

  void updateVideo(String newPath) async {
    // Reset initialization flag for new video
    setState(() {
      _isInitializingTracks = true;
    });
    
    _player.stop();
    _player.open(Media(newPath));
    
    // Clear audio track selection when video changes
    try {
      await PreferencesModel.clearSelectedAudioTrack(widget.subtitleCollectionId);
      debugPrint('Cleared audio track selection for new video');
    } catch (e) {
      debugPrint('Error clearing audio track selection: $e');
    }
    
    // Load saved track for new video (if any)
    _loadSavedAudioTrack();
  }

  void updateSubtitles(List<Subtitle> newSubtitles) {
    // Avoid unnecessary updates if subtitles haven't actually changed
    if (_currentSubtitles.length == newSubtitles.length) {
      bool hasChanges = false;
      for (int i = 0; i < _currentSubtitles.length; i++) {
        if (_currentSubtitles[i].index != newSubtitles[i].index ||
            _currentSubtitles[i].text != newSubtitles[i].text ||
            _currentSubtitles[i].start != newSubtitles[i].start ||
            _currentSubtitles[i].end != newSubtitles[i].end ||
            _currentSubtitles[i].marked != newSubtitles[i].marked) {
          hasChanges = true;
          // Debug marked state changes specifically
          if (_currentSubtitles[i].marked != newSubtitles[i].marked) {
            debugPrint('VideoPlayer: Subtitle ${newSubtitles[i].index} marked status changed: ${_currentSubtitles[i].marked} -> ${newSubtitles[i].marked}');
          }
          break;
        }
      }
      if (!hasChanges) {
        return; // No changes detected, skip update
      }
    }
    
    // Update subtitle data WITHOUT calling setState to avoid rebuilding the video player
    _currentSubtitles = newSubtitles;
    // Reset active subtitle cache when subtitles update
    _currentActiveSubtitles = [];
    _currentActiveSecondarySubtitles = [];
    
    // Notify external components without rebuilding this widget
    if (widget.onSubtitlesUpdated != null) {
      widget.onSubtitlesUpdated!();
    }
    
    // Force immediate recalculation of active subtitles for current position
    // This ensures the active subtitle index is correct after structural changes
    final currentPosition = _player.state.position;
    _updateActiveSubtitles(currentPosition);
    
    // Force rebuild of fullscreen overlay to update mark button states (debounced)
    if (_fullscreenOverlay != null) {
      // Use a future to avoid excessive rebuilds during rapid subtitle updates
      Future.microtask(() {
        if (_fullscreenOverlay != null && mounted) {
          _fullscreenOverlay!.markNeedsBuild();
        }
      });
    }
  }

  void updateSecondarySubtitles(List<Subtitle> newSubtitles) {
    // Update secondary subtitle data WITHOUT calling setState to avoid rebuilding the video player
    _currentSecondarySubtitles = newSubtitles;
    // Reset secondary subtitle cache
    _currentActiveSecondarySubtitles = [];
    
    // Force immediate recalculation of active subtitles for current position
    final currentPosition = _player.state.position;
    _updateActiveSubtitles(currentPosition);
  }

  void _initializePlayer() {
    // Initialize the player
    _player = Player();
    _controller = VideoController(_player);
    
    // Open the media file with autoplay disabled
    _player.open(Media(widget.videoPath), play: false);
    
    // Track when player is ready by listening to width stream directly
    _widthSubscription = _player.stream.width.listen((width) {
      // Check if mounted and still loading, and width is valid (non-null and > 0)
      if (mounted && _isLoading && width != null && width > 0) {
        setState(() {
          _isLoading = false;
        });
        
        // Apply volume after player is ready (second attempt, ensures proper application)
        // This guarantees the volume from preferences is applied after the player
        // has fully initialized, addressing timing issues with early volume setting
        _player.setVolume(_currentVolume);
      }
    });
    
    // Set up position listener with throttling for better performance
    Duration lastPositionUpdate = Duration.zero;
    DateTime lastCallTime = DateTime.now();
    _positionSubscription = _player.stream.position.listen((position) {
      // Safety checks: ensure widget is mounted and position is valid
      if (!mounted || position.isNegative) return;
      
      try {
        // Additional throttling: prevent excessive calls in short time periods
        final now = DateTime.now();
        if (now.difference(lastCallTime).inMilliseconds < 50) return; // Minimum 50ms between calls
        
        // Throttle position updates to reduce excessive callbacks
        if ((position - lastPositionUpdate).inMilliseconds.abs() >= 100) { // Update max every 100ms
          lastPositionUpdate = position;
          lastCallTime = now;
          
          if (widget.onPositionChanged != null) {
            widget.onPositionChanged!(position);
          }
          _updateActiveSubtitles(position);
        }
      } catch (e) {
        debugPrint('Error in position listener: $e');
      }
    });
    
    // Set up playback state listener
    _playingSubscription = _player.stream.playing.listen((isPlaying) {
      if (!mounted) return;
      try {
        // Notify external components of play state changes
        if (widget.onPlayStateChanged != null) {
          widget.onPlayStateChanged!(isPlaying);
        }
      } catch (e) {
        debugPrint('Error in playing state listener: $e');
      }
    });
    
    // Set up audio tracks listener
    _tracksSubscription = _player.stream.tracks.listen((tracks) {
      if (!mounted) return;
      try {
        setState(() {
          _availableAudioTracks = tracks.audio;
          _availableSubtitleTracks = tracks.subtitle;
        });
      } catch (e) {
        debugPrint('Error in tracks listener: $e');
      }
    });
    
    // Set up current audio track listener with persistence
    _trackSubscription = _player.stream.track.listen((track) {
      if (!mounted) return;
      try {
        final previousAudioTrack = _currentAudioTrack;
        setState(() {
          _currentAudioTrack = track.audio;
          _currentSubtitleTrack = track.subtitle;
        });
        
        // Save audio track selection when it changes (user selection)
        // Skip saving during initialization to preserve saved preferences
        if (!_isInitializingTracks && track.audio.id != previousAudioTrack?.id) {
          _saveAudioTrackSelection(track.audio);
        }
      } catch (e) {
        debugPrint('Error in track listener: $e');
      }
    });
    
    // Set initial volume from saved preferences (early attempt)
    // Note: This is called immediately, but volume may not be fully applied
    // until the player is ready. A second call is made in the width listener.
    _player.setVolume(_currentVolume);
    
    // Load and apply saved audio track after tracks are available
    _loadSavedAudioTrack();
  }

  // Performance optimization: Track current active subtitles to avoid unnecessary rebuilds
  // Changed to lists to support multiple overlapping subtitles with same timecode
  List<Subtitle> _currentActiveSubtitles = [];
  List<Subtitle> _currentActiveSecondarySubtitles = [];
  
  void _updateActiveSubtitles(Duration position) {
    // Safety check: don't update if widget is disposed or not mounted
    if (!mounted) return;
    
    try {
      // Find all active subtitles at current position (supports overlapping subtitles)
      final newActiveSubtitles = _findAllActiveSubtitles(_currentSubtitles, position);
      final newActiveSecondarySubtitles = _findAllActiveSubtitles(_currentSecondarySubtitles, position);
      
      
      // Check if primary subtitles changed (compare list contents)
      if (!_areSubtitleListsEqual(_currentActiveSubtitles, newActiveSubtitles)) {
        _currentActiveSubtitles = newActiveSubtitles;
        
        // Notify external components of the active subtitle array index
        // Use the first subtitle in the list for callback (if any)
        // Only call this callback when IN fullscreen mode so video player navigation 
        // only works in fullscreen, preventing interference with EditScreen shortcuts in normal mode
        if (widget.onActiveSubtitleChanged != null) {
          if (newActiveSubtitles.isNotEmpty) {
            // Find the array index of the first subtitle in the current list
            final arrayIndex = _currentSubtitles.indexOf(newActiveSubtitles.first);
            widget.onActiveSubtitleChanged!(arrayIndex >= 0 ? arrayIndex : -1);
          } else {
            widget.onActiveSubtitleChanged!(-1); // No active subtitle
          }
        }
      }
      
      // Check if secondary subtitles changed
      if (!_areSubtitleListsEqual(_currentActiveSecondarySubtitles, newActiveSecondarySubtitles)) {
        _currentActiveSecondarySubtitles = newActiveSecondarySubtitles;
      }
      
      // DO NOT call setState here - subtitle rendering is handled by StreamBuilder in build()
      // Calling setState here causes excessive rebuilds and frame drops during video playback
      // The subtitle overlay is already reactive through the position stream
      // Only update internal state for external callbacks
    } catch (e) {
      // Log error and continue gracefully
      debugPrint('Error updating active subtitles: $e');
    }
  }

  // Helper method to compare two subtitle lists for equality
  bool _areSubtitleListsEqual(List<Subtitle> list1, List<Subtitle> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].index != list2[i].index || list1[i].text != list2[i].text) {
        return false;
      }
    }
    
    return true;
  }

  // Find all active subtitles at the current position (supports overlapping subtitles)
  List<Subtitle> _findAllActiveSubtitles(List<Subtitle> subtitles, Duration position) {
    if (subtitles.isEmpty) return [];
    
    // Safety check: prevent operations on very large lists that could cause hangs
    if (subtitles.length > 10000) {
      debugPrint('Warning: Very large subtitle list (${subtitles.length} items), performance may be affected');
    }
    
    final positionMs = position.inMilliseconds;
    final activeSubtitles = <Subtitle>[];
    
    // Use binary search to find the first potential match, then scan nearby subtitles
    int left = 0;
    int right = subtitles.length - 1;
    int? firstMatchIndex;
    
    // Binary search to find any subtitle that contains the current position
    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final subtitle = subtitles[mid];
      
      final startMs = subtitle.start.inMilliseconds;
      final endMs = subtitle.end.inMilliseconds;
      
      if (positionMs >= startMs && positionMs < endMs) {
        firstMatchIndex = mid;
        break;
      } else if (positionMs < startMs) {
        right = mid - 1;
      } else {
        left = mid + 1;
      }
    }
    
    // If we found a match, scan backwards and forwards to find all overlapping subtitles
    if (firstMatchIndex != null) {
      // Scan backwards to find all subtitles that overlap with current position
      int scanIndex = firstMatchIndex;
      while (scanIndex >= 0) {
        final subtitle = subtitles[scanIndex];
        final startMs = subtitle.start.inMilliseconds;
        final endMs = subtitle.end.inMilliseconds;
        
        if (positionMs >= startMs && positionMs < endMs) {
          activeSubtitles.insert(0, subtitle); // Insert at beginning to maintain order
          scanIndex--;
        } else {
          break; // Stop scanning backwards once we're outside the range
        }
      }
      
      // Scan forwards to find additional overlapping subtitles (skip the firstMatchIndex as it's already added)
      scanIndex = firstMatchIndex + 1;
      while (scanIndex < subtitles.length) {
        final subtitle = subtitles[scanIndex];
        final startMs = subtitle.start.inMilliseconds;
        final endMs = subtitle.end.inMilliseconds;
        
        if (positionMs >= startMs && positionMs < endMs) {
          activeSubtitles.add(subtitle);
          scanIndex++;
        } else {
          break; // Stop scanning forwards once we're outside the range
        }
      }
    }
    
    return activeSubtitles;
  }

  Duration getCurrentPosition() {
    try {
      // Safety check to prevent accessing disposed player
      if (!mounted) return Duration.zero;
      return _player.state.position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return Duration.zero;
    }
  }

  bool isPlaying() {
    try {
      // Safety check to prevent accessing disposed player
      if (!mounted) return false;
      return _player.state.playing;
    } catch (e) {
      debugPrint('Error checking playing state: $e');
      return false;
    }
  }

  bool isInitialized() {
    try {
      // Safety check to prevent accessing disposed player
      if (!mounted) return false;
      // Check if media is loaded by ensuring a valid duration exists
      return _player.state.duration > Duration.zero;
    } catch (e) {
      debugPrint('Error checking initialization state: $e');
      return false;
    }
  }

  // Method to get video framerate
  Future<double?> _getFramerateInternal() async {
    try {
      final ffmpegHelper = FFmpegHelper();
      return await ffmpegHelper.getVideoFramerate(widget.videoPath);
    } catch (e) {
      debugPrint('Error getting framerate: $e');
      return null;
    }
  }
  
  // Public method to access the framerate
  double? getFrameRate() {
    // Return cached value if available
    if (_cachedFramerate != null) {
      return _cachedFramerate;
    }
    
    // Start fetching framerate in background if not already cached
    _getFramerateInternal().then((value) {
      if (value != null) {
        _cachedFramerate = value;
      }
    });
    
    // Return default value for now
    return 25.0;
  }

  // Toggle subtitles visibility
  void toggleSubtitles() {
    setState(() {
      _areSubtitlesEnabled = !_areSubtitlesEnabled;
    });
  }

  // Set playback speed
  void setPlaybackSpeed(double speed) {
    setState(() {
      _currentSpeed = speed;
    });
    _player.setRate(speed);
  }

  // Get current playback speed
  double getCurrentSpeed() {
    return _currentSpeed;
  }

  // Fullscreen state and subtitle seeking methods for external access
  
  /// Check if the video player is currently in fullscreen mode
  bool isInFullscreenMode() {
    return _isCustomFullscreen;
  }
  
  /// Seek to the previous subtitle start time
  /// This method provides external access to the fullscreen skip functionality
  void seekToPreviousSubtitle() {
    _seekToPreviousSubtitle();
  }
  
  /// Seek to the next subtitle start time  
  /// This method provides external access to the fullscreen skip functionality
  void seekToNextSubtitle() {
    _seekToNextSubtitle();
  }

  /// Show comment dialog for a specific subtitle in fullscreen mode
  /// This method provides external access to fullscreen comment dialog functionality
  void showFullscreenCommentDialog(Subtitle subtitle, {
    String? originalText,
    String? editedText,
  }) {
    if (_isCustomFullscreen && _fullscreenControlsKey.currentState != null) {
      debugPrint('showFullscreenCommentDialog: Triggering fullscreen comment dialog for subtitle ${subtitle.index}');
      _fullscreenControlsKey.currentState!.showCommentDialogForSubtitle(subtitle, 
        originalText: originalText, editedText: editedText);
    } else if (_isCustomFullscreen) {
      debugPrint('showFullscreenCommentDialog: Warning - fullscreen controls state is null');
    } else {
      debugPrint('showFullscreenCommentDialog: Not in fullscreen mode, falling back to regular comment dialog');
      showCommentDialog(subtitle, _originalContext ?? context);
    }
  }

  // Audio track management methods
  
  /// Save selected audio track to preferences
  Future<void> _saveAudioTrackSelection(AudioTrack track) async {
    try {
      debugPrint('Saving audio track for collection ${widget.subtitleCollectionId}: ${track.title} (${track.language}) [ID: ${track.id}]');
      await PreferencesModel.saveSelectedAudioTrack(
        widget.subtitleCollectionId,
        trackId: track.id,
        trackTitle: track.title,
        trackLanguage: track.language,
      );
      debugPrint('✓ Audio track saved successfully');
    } catch (e) {
      debugPrint('✗ Error saving audio track selection: $e');
    }
  }
  
  /// Load and apply saved audio track
  Future<void> _loadSavedAudioTrack() async {
    try {
      // Wait for tracks to be available
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted || _availableAudioTracks.isEmpty) {
        // Even if no tracks available, enable saving for future changes
        setState(() {
          _isInitializingTracks = false;
        });
        return;
      }
      
      // Get saved audio track
      final savedTrack = await PreferencesModel.getSelectedAudioTrack(widget.subtitleCollectionId);
      final savedTrackId = savedTrack['id'];
      
      if (savedTrackId == null) {
        // No saved track, use default and enable saving
        debugPrint('No saved audio track found, using default');
        setState(() {
          _isInitializingTracks = false;
        });
        return;
      }
      
      // Find matching track in available tracks
      final matchingTrack = _availableAudioTracks.firstWhere(
        (track) => track.id == savedTrackId,
        orElse: () => _availableAudioTracks.first,
      );
      
      // Apply the track if it's different from current
      if (matchingTrack.id != _currentAudioTrack?.id) {
        await _player.setAudioTrack(matchingTrack);
        debugPrint('Restored audio track: ${matchingTrack.title} (${matchingTrack.language})');
      } else {
        debugPrint('Audio track already set to: ${matchingTrack.title} (${matchingTrack.language})');
      }
      
      // Enable saving after restoration is complete
      setState(() {
        _isInitializingTracks = false;
      });
    } catch (e) {
      debugPrint('Error loading saved audio track: $e');
      // Enable saving even on error
      if (mounted) {
        setState(() {
          _isInitializingTracks = false;
        });
      }
    }
  }
  
  /// Get all available audio tracks in the current video
  /// Returns empty list if no tracks are available or video is not loaded
  List<AudioTrack> getAvailableAudioTracks() {
    return _availableAudioTracks;
  }

  /// Get the currently selected audio track
  /// Returns null if no track is selected
  AudioTrack? getCurrentAudioTrack() {
    return _currentAudioTrack;
  }

  /// Switch to a specific audio track
  /// [track] The audio track to switch to
  Future<void> setAudioTrack(AudioTrack track) async {
    await _player.setAudioTrack(track);
  }

  // Subtitle track management methods
  
  /// Get all available subtitle tracks in the current video
  /// Returns empty list if no tracks are available or video is not loaded
  List<SubtitleTrack> getAvailableSubtitleTracks() {
    return _availableSubtitleTracks;
  }

  /// Get the currently selected subtitle track
  /// Returns null if no track is selected
  SubtitleTrack? getCurrentSubtitleTrack() {
    return _currentSubtitleTrack;
  }

  /// Switch to a specific subtitle track
  /// [track] The subtitle track to switch to
  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    await _player.setSubtitleTrack(track);
  }

  /// Get the current video file path
  /// Returns the original video path, not the converted file descriptor URI
  String? getVideoPath() {
    // Return the original video path from the widget constructor
    // This ensures we get the content URI for Android SAF support
    // rather than the converted file descriptor URI from media kit
    return widget.videoPath;
  }

  /// Get detailed subtitle track information using FFmpeg
  /// This provides more detailed information than media_kit tracks
  Future<List<Map<String, dynamic>>> getDetailedSubtitleTracks() async {
    final videoPath = getVideoPath();
    if (videoPath == null) return [];
    
    try {
      final ffmpeg = FFmpegHelper();
      return await ffmpeg.getSubtitleTracks(videoPath);
    } catch (e) {
      debugPrint('Error getting detailed subtitle tracks: $e');
      return [];
    }
  }

  /// Extract subtitle content from a specific track
  /// [trackIndex] The subtitle index (0-based) for FFmpeg extraction (not the stream index)
  /// Returns the content as a string, or null if extraction fails
  Future<String?> extractSubtitleTrackContent(int trackIndex) async {
    final videoPath = getVideoPath();
    if (videoPath == null) return null;
    
    try {
      final ffmpeg = FFmpegHelper();
      // Create a temporary directory for extraction
      final tempDir = Directory.systemTemp;
      
      final extractedPath = await ffmpeg.extractSubtitle(
        videoPath,
        tempDir.path,
        trackIndex,
      );
      
      // Read the extracted subtitle content
      final extractedFile = File(extractedPath);
      if (await extractedFile.exists()) {
        final content = await extractedFile.readAsString();
        // Clean up the temporary file
        await extractedFile.delete();
        return content;
      }
    } catch (e) {
      debugPrint('Error extracting subtitle track content: $e');
    }
    
    return null;
  }

  /// Show dialog to select from available audio tracks
  /// Displays a snackbar message if no additional tracks are available
  void showAudioTrackDialog(BuildContext context) {
    // Use the State's context as a safe parent context and guard against disposed state
    if (!mounted) return;
    final BuildContext safeContext = this.context;

    if (_availableAudioTracks.isEmpty || _availableAudioTracks.length <= 1) {
      final messenger = ScaffoldMessenger.maybeOf(safeContext) ?? ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('No additional audio tracks available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Ensure state still mounted before showing dialog
    if (!mounted) return;

    showDialog(
      context: safeContext,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Row(
            children: [
              Icon(Icons.audiotrack, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              const Text('Audio Track'),
            ],
          ),
          content: SizedBox(
            width: double.minPositive,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _availableAudioTracks.map((track) {
                return _buildAudioTrackOption(context, track);
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioTrackOption(BuildContext context, AudioTrack track) {
    final isSelected = _currentAudioTrack?.id == track.id;
    
    // Get track display name
    String trackName = 'Track ${track.id}';
    if (track.id == 'auto') {
      trackName = 'Auto';
    } else if (track.id == 'no') {
      trackName = 'Off';
    } else if (track.title?.isNotEmpty == true) {
      trackName = track.title!;
    } else if (track.language?.isNotEmpty == true) {
      trackName = 'Track ${track.id} (${track.language})';
    }
    
    return InkWell(
      onTap: () {
        setAudioTrack(track);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Theme.of(context).primaryColor) : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: track.id,
              groupValue: _currentAudioTrack?.id,
              onChanged: (String? value) {
                if (value != null) {
                  setAudioTrack(track);
                  Navigator.of(context).pop();
                }
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trackName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.onSurface : null,
                    ),
                  ),
                  if (track.language?.isNotEmpty == true && track.title?.isNotEmpty == true)
                    Text(
                      'Language: ${track.language}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Show speed selection dialog
  void showSpeedDialog(BuildContext context) {
    // Prefer using the state's context to avoid passing a potentially disposed child context
    if (!mounted) return;
    final BuildContext safeContext = this.context;

    showDialog(
      context: safeContext,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Row(
            children: [
              Icon(Icons.speed, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              const Text('Playback Speed'),
            ],
          ),
          content: SizedBox(
            width: double.minPositive,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSpeedOption(context, 0.25, '0.25x'),
                _buildSpeedOption(context, 0.5, '0.5x'),
                _buildSpeedOption(context, 0.75, '0.75x'),
                _buildSpeedOption(context, 1.0, '1.0x (Normal)'),
                _buildSpeedOption(context, 1.25, '1.25x'),
                _buildSpeedOption(context, 1.5, '1.5x'),
                _buildSpeedOption(context, 1.75, '1.75x'),
                _buildSpeedOption(context, 2.0, '2.0x'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeedOption(BuildContext context, double speed, String label) {
    final isSelected = _currentSpeed == speed;
    return InkWell(
      onTap: () {
        setPlaybackSpeed(speed);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha:0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Theme.of(context).primaryColor) : null,
        ),
        child: Row(
          children: [
            Radio<double>(
              value: speed,
              groupValue: _currentSpeed,
              onChanged: (double? value) {
                if (value != null) {
                  setPlaybackSpeed(value);
                  Navigator.of(context).pop();
                }
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).colorScheme.onSurface : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Toggle mute
  void toggleMute() async {
    if (_currentVolume > 0) {
      _player.setVolume(0);
      setState(() {
        _currentVolume = 0;
      });
      await PreferencesModel.setVideoVolume(0);
    } else {
      _player.setVolume(100);
      setState(() {
        _currentVolume = 100;
      });
      await PreferencesModel.setVideoVolume(100);
    }
  }

  // Skip forward or backward
  void _seekRelative(Duration offset) {
    final currentPosition = _player.state.position;
    final newPosition = currentPosition + offset;
    // Ensure we don't seek past video bounds
    final clampedPosition = newPosition.clamp(
      Duration.zero,
      _player.state.duration,
    );
    _player.seek(clampedPosition);
  }

  // Skip to previous subtitle start time
  void _seekToPreviousSubtitle() {
    if (!mounted) return;
    
    // Capture the current position immediately to prevent it from changing during playback
    final currentPosition = _player.state.position;
    final wasPlaying = _player.state.playing;
    
    // Pause the video first to ensure stable position reference
    if (wasPlaying) {
      _player.pause();
    }
    
    // Find the previous subtitle start time with better logic
    Duration? previousStart;
    
    // Special case: if we're very close to a subtitle start (within 1 second), 
    // go to the previous one instead of the current one
    final threshold = const Duration(milliseconds: 1000);
    final adjustedPosition = currentPosition - threshold;
    
    // Look through primary subtitles
    for (int i = _currentSubtitles.length - 1; i >= 0; i--) {
      final subtitle = _currentSubtitles[i];
      if (subtitle.start < adjustedPosition) {
        if (previousStart == null || subtitle.start > previousStart) {
          previousStart = subtitle.start;
        }
        break; // Found the closest previous subtitle
      }
    }
    
    // Also check secondary subtitles for a potentially closer previous subtitle
    for (int i = _currentSecondarySubtitles.length - 1; i >= 0; i--) {
      final subtitle = _currentSecondarySubtitles[i];
      if (subtitle.start < adjustedPosition) {
        if (previousStart == null || subtitle.start > previousStart) {
          previousStart = subtitle.start;
        }
        break; // Found the closest previous subtitle
      }
    }
    
    // Seek to the previous subtitle start time, or beginning if none found
    if (previousStart != null) {
      // Add 50ms offset to ensure subtitle is visible after seeking
      // This prevents the subtitle from disappearing when seeking to exact start time
      final seekPosition = previousStart + const Duration(milliseconds: 50);
      _player.seek(seekPosition);
      
      // Notify external components about the seek operation
      if (widget.onPositionChanged != null) {
        widget.onPositionChanged!(seekPosition);
      }
      
      // Resume playback if video was playing before, unless repeat mode is enabled
      if (widget.isRepeatModeEnabled) {
        _player.pause();
      } else if (wasPlaying) {
        _player.play();
      }
    } else {
      _player.seek(Duration.zero);
      
      // Notify external components about the seek operation
      if (widget.onPositionChanged != null) {
        widget.onPositionChanged!(Duration.zero);
      }
      
      // Resume playback if video was playing before, unless repeat mode is enabled
      if (widget.isRepeatModeEnabled) {
        _player.pause();
      } else if (wasPlaying) {
        _player.play();
      }
    }
  }

  // Skip to next subtitle start time
  void _seekToNextSubtitle() {
    if (!mounted) return;
    
    // Capture the current position immediately to prevent it from changing during playback
    final currentPosition = _player.state.position;
    final wasPlaying = _player.state.playing;
    
    // Pause the video first to ensure stable position reference
    if (wasPlaying) {
      _player.pause();
    }
    
    // Find the next subtitle start time with better logic
    Duration? nextStart;
    
    // Add small threshold to handle edge cases where we're exactly at subtitle start
    final threshold = const Duration(milliseconds: 100);
    final adjustedPosition = currentPosition + threshold;
    
    // Look through primary subtitles first
    for (int i = 0; i < _currentSubtitles.length; i++) {
      final subtitle = _currentSubtitles[i];
      if (subtitle.start > adjustedPosition) {
        if (nextStart == null || subtitle.start < nextStart) {
          nextStart = subtitle.start;
        }
        break; // Found the first next subtitle
      }
    }
    
    // Also check secondary subtitles for a potentially closer next subtitle
    for (int i = 0; i < _currentSecondarySubtitles.length; i++) {
      final subtitle = _currentSecondarySubtitles[i];
      if (subtitle.start > adjustedPosition) {
        if (nextStart == null || subtitle.start < nextStart) {
          nextStart = subtitle.start;
        }
        break; // Found the first next subtitle
      }
    }
    
    // Seek to the next subtitle start time, or end if none found
    if (nextStart != null) {
      // Add 50ms offset to ensure subtitle is visible after seeking
      // This prevents the subtitle from disappearing when seeking to exact start time
      final seekPosition = nextStart + const Duration(milliseconds: 50);
      _player.seek(seekPosition);
      
      // Notify external components about the seek operation
      if (widget.onPositionChanged != null) {
        widget.onPositionChanged!(seekPosition);
      }
      
      // Resume playback if video was playing before, unless repeat mode is enabled
      if (widget.isRepeatModeEnabled) {
        _player.pause();
      } else if (wasPlaying) {
        _player.play();
      }
    } else {
      final duration = _player.state.duration;
      _player.seek(duration);
      
      // Notify external components about the seek operation
      if (widget.onPositionChanged != null) {
        widget.onPositionChanged!(duration);
      }
      
      // Resume playback if video was playing before, unless repeat mode is enabled
      if (widget.isRepeatModeEnabled) {
        _player.pause();
      } else if (wasPlaying) {
        _player.play();
      }
    }
  }

  // Format duration to always show HH:MM:SS format
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    // Always include hours for consistent format
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    // Removed rebuild counter logging for better performance
    // _buildCounter++;
    // if (_buildCounter % 25 == 0) {
    //   debugPrint('VideoPlayerWidget rebuild count: $_buildCounter');
    // }
    
    return RepaintBoundary(
      child: Container(
        color: Colors.black,
        child: _player.state.duration > Duration.zero
          ? Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  // Speed control shortcuts
                  if (event.logicalKey == LogicalKeyboardKey.minus) {
                    // Decrease speed
                    final newSpeed = (_currentSpeed - 0.25).clamp(0.25, 2.0);
                    setPlaybackSpeed(newSpeed);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.equal || 
                             event.logicalKey == LogicalKeyboardKey.add) {
                    // Increase speed
                    final newSpeed = (_currentSpeed + 0.25).clamp(0.25, 2.0);
                    setPlaybackSpeed(newSpeed);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.digit0) {
                    // Reset to normal speed
                    setPlaybackSpeed(1.0);
                    return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    // Exit fullscreen with Escape key
                    if (_isCustomFullscreen) {
                      _exitCustomFullscreen();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Stack(
                children: [
                  // Video player
                  MouseRegion(
                    onEnter: (_) {
                      // MaterialVideoControls handles this automatically
                    },
                    onExit: (_) {
                      // MaterialVideoControls handles this automatically
                    },
                    onHover: (_) {
                      // MaterialVideoControls handles this automatically
                    },
                    child: GestureDetector(
                      onTap: () {
                        // MaterialVideoControls handles tap-to-show/hide
                      },
                      onDoubleTapDown: (details) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final tapPosition = details.globalPosition.dx;
                        
                        // If tap is on left side, seek backward; if on right side, seek forward
                        if (tapPosition < screenWidth / 2) {
                          _seekRelative(const Duration(seconds: -10));
                          _showSeekIndicator(context, false);
                        } else {
                          _seekRelative(const Duration(seconds: 10));
                          _showSeekIndicator(context, true);
                        }
                      },
                    child: Stack(
                      children: [
                        // Video player without controls
                        Video(
                          controller: _controller,
                          controls: NoVideoControls, // Disable built-in controls
                          subtitleViewConfiguration: const SubtitleViewConfiguration(
                            visible: false, // Disable built-in subtitles
                          ),
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                ), // Close GestureDetector
              ), // Close MouseRegion

              // Subtitle overlay for normal (non-fullscreen) mode only
              // Positioned BELOW controls so controls appear above subtitles
              if (_areSubtitlesEnabled && !_isCustomFullscreen)
                IgnorePointer( // Allow touches to pass through to video controls
                  child: StreamBuilder<Duration>(
                    key: ValueKey('subtitle_${_subtitleFontSize}_$_subtitleFontFamily'),
                    stream: _player.stream.position,
                    builder: (context, snapshot) {
                      // Use cached active subtitles (now lists) instead of recalculating
                      final activeSubtitles = _currentActiveSubtitles;
                      final activeSecondarySubtitles = _currentActiveSecondarySubtitles;
                      
                      // Use standard positioning for normal mode
                      final mediaQuery = MediaQuery.of(context);
                      final topPadding = 30.0 + mediaQuery.viewPadding.top;
                      
                      // Use new MultipleOverlappingSubtitlesWidget for intelligent positioning
                      return Stack(
                        children: [
                          // Primary subtitles with intelligent positioning
                          if (activeSubtitles.isNotEmpty)
                            MultipleOverlappingSubtitlesWidget(
                              subtitleTexts: activeSubtitles.map((s) => s.text).toList(),
                              textStyle: TextStyle(
                                color: Colors.white,
                                fontSize: _getResponsiveSubtitleFontSize(),
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                fontFamily: _subtitleFontFamily,
                                background: _showSubtitleBackground
                                ? (Paint()..color = const Color.fromARGB(180, 0, 0, 0))
                                : null,
                                shadows: const [
                                  Shadow(
                                    blurRadius: 3.0,
                                    color: Colors.black,
                                    offset: Offset(2.0, 2.0),
                                  ),
                                  Shadow(
                                    blurRadius: 1.0,
                                    color: Colors.black,
                                    offset: Offset(1.0, 1.0),
                                  ),
                                ],
                              ),
                              horizontalPadding: 30.0,
                              verticalPadding: 30.0,
                              topPadding: topPadding,
                              isFullscreen: false,
                              verticalOffset: _primarySubtitleVerticalPosition,
                            ),
                          
                          // Secondary subtitles (also handle positioning if needed)
                          if (activeSecondarySubtitles.isNotEmpty)
                            MultipleOverlappingSubtitlesWidget(
                              subtitleTexts: activeSecondarySubtitles.map((s) => s.text).toList(),
                              textStyle: TextStyle(
                                color: Colors.white,
                                fontSize: _getResponsiveSubtitleFontSize(),
                                fontWeight: FontWeight.normal,
                                height: 1.3,
                                fontFamily: _subtitleFontFamily,
                                background: Paint()..color = const Color.fromARGB(156, 0, 0, 0),
                                shadows: const [
                                  Shadow(
                                    blurRadius: 3.0,
                                    color: Colors.black,
                                    offset: Offset(2.0, 2.0),
                                  ),
                                  Shadow(
                                    blurRadius: 1.0,
                                    color: Colors.black,
                                    offset: Offset(1.0, 1.0),
                                  ),
                                ],
                              ),
                              horizontalPadding: 30.0,
                              verticalPadding: 30.0,
                              topPadding: topPadding,
                              isFullscreen: false,
                              verticalOffset: _secondarySubtitleVerticalPosition,
                              forceTopPosition: true, // Always display secondary subtitles at top
                              primarySubtitleTexts: activeSubtitles.map((s) => s.text).toList(), // Pass for collision detection
                            ),
                        ],
                      );
                    },
                  ),
                ),

                // Custom controls overlay - positioned ABOVE subtitles
                CustomVideoControls(
                  player: _player,
                  subtitles: _currentSubtitles,
                  secondarySubtitles: _currentSecondarySubtitles,
                  onSubtitleMarked: widget.onSubtitleMarked,
                  onSubtitleCommentUpdated: widget.onSubtitleCommentUpdated,
                  onPlayStateChanged: widget.onPlayStateChanged,
                  onRepeatModeToggled: widget.onRepeatModeToggled,
                  isRepeatModeEnabled: widget.isRepeatModeEnabled,
                  skipDurationSeconds: _skipDurationSeconds,
                ),
                  
                // Loading overlay (shows only while loading)
                if (_isLoading)
                  const Center(child: Loader13()),
              ],
            ),
          )
          : const Center(child: Loader13()),
      ),
    );
  }

  // Show a temporary indicator when seeking forward/backward
  void _showSeekIndicator(BuildContext context, bool isForward) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(
              isForward ? Icons.skip_next : Icons.skip_previous,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Remove after a short duration
    Future.delayed(const Duration(milliseconds: 500), () {
      overlayEntry.remove();
    });
  }

  // Method to show comment dialog for marked subtitle (for non-fullscreen mode)
  void showCommentDialog(Subtitle subtitle, BuildContext dialogContext) {
    if (_isCustomFullscreen) {
      // For fullscreen mode, this shouldn't be called as it's handled by _FullscreenControlsWidget
      debugPrint('Warning: showCommentDialog called in fullscreen mode, use _FullscreenControlsWidget instead');
      return;
    }
    
    // Store the current playing state before showing dialog
    final wasPlaying = _player.state.playing;
    debugPrint('Comment dialog opening - video was ${wasPlaying ? 'playing' : 'paused'}');
    
    // Pause video if it was playing when comment dialog opens
    if (wasPlaying) {
      _player.pause();
      debugPrint('Paused video for comment input');
    }
    
    // Flag to track if video has been resumed to prevent double resuming
    bool hasResumed = false;
    
    // For normal mode, use the standard CommentDialog.show() which handles orientation automatically
    CommentDialog.show(
      dialogContext,
      existingComment: subtitle.comment,
      onCommentSaved: (comment) async {
        // If the subtitle is not marked, mark it first
        if (!subtitle.marked && widget.onSubtitleMarked != null) {
          try {
            debugPrint('Marking subtitle before saving comment in normal mode');
            widget.onSubtitleMarked!(subtitle.index, true);
            // Small delay to ensure mark operation completes
            await Future.delayed(const Duration(milliseconds: 50));
          } catch (e) {
            debugPrint('Error marking subtitle: $e');
          }
        }
        
        // Schedule callback for next frame to avoid unmounted widget issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Check if widget is still mounted before calling callback
          if (mounted && widget.onSubtitleCommentUpdated != null) {
            try {
              widget.onSubtitleCommentUpdated!(subtitle.index, comment);
            } catch (e) {
              debugPrint('Error updating subtitle comment: $e');
            }
          }
          
          // Resume video if it was playing before dialog opened and not already resumed
          if (wasPlaying && mounted && !hasResumed) {
            hasResumed = true;
            _player.play();
            debugPrint('Resumed video after comment save');
          }
        });
      },
      onCommentDeleted: () {
        // Schedule callback for next frame to avoid unmounted widget issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Check if widget is still mounted before calling callback
          if (mounted && widget.onSubtitleCommentUpdated != null) {
            try {
              widget.onSubtitleCommentUpdated!(subtitle.index, null);
            } catch (e) {
              debugPrint('Error deleting subtitle comment: $e');
            }
          }
          
          // Resume video if it was playing before dialog opened and not already resumed
          if (wasPlaying && mounted && !hasResumed) {
            hasResumed = true;
            _player.play();
            debugPrint('Resumed video after comment delete');
          }
        });
      },
    ).then((_) {
      // This executes when the dialog is dismissed (by canceling without save/delete)
      // Resume video if it was playing before dialog opened and we haven't already resumed it
      if (wasPlaying && mounted && !hasResumed) {
        _player.play();
        debugPrint('Resumed video after comment dialog dismissed');
      }
    });
  }
}

// Custom buttons for video controls

// Audio track button
class _AudioTrackButton extends StatefulWidget {
  const _AudioTrackButton();

  @override
  _AudioTrackButtonState createState() => _AudioTrackButtonState();
}

class _AudioTrackButtonState extends State<_AudioTrackButton> {
  @override
  Widget build(BuildContext context) {
    final videoPlayerState = context.findAncestorStateOfType<VideoPlayerWidgetState>();
    
    if (videoPlayerState == null) {
      return const SizedBox.shrink();
    }
    
  final availableTracks = videoPlayerState.getAvailableAudioTracks();
  // Exclude pseudo-tracks like 'auto' and 'no' from the user-facing count
  final realTracks = availableTracks.where((t) => t.id != 'auto' && t.id != 'no').toList();
  final hasMultipleTracks = realTracks.length > 1;
    
    return InkWell(
      onTap: () {
        videoPlayerState.showAudioTrackDialog(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: hasMultipleTracks ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: hasMultipleTracks ? 0.5 : 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.audiotrack,
              color: Colors.white.withValues(alpha: hasMultipleTracks ? 1.0 : 0.6),
              size: 16,
            ),
              if (hasMultipleTracks) ...[
              const SizedBox(width: 4),
              Text(
                '${realTracks.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Font size expandable control widget
class _FontSizeExpandableControl extends StatefulWidget {
  final VideoPlayerWidgetState videoPlayerState;
  final Color primaryColor;
  final Color onSurfaceColor;
  final bool isDark;
  final BuildContext sheetContext;

  const _FontSizeExpandableControl({
    required this.videoPlayerState,
    required this.primaryColor,
    required this.onSurfaceColor,
    required this.isDark,
    required this.sheetContext,
  });

  @override
  _FontSizeExpandableControlState createState() => _FontSizeExpandableControlState();
}

class _FontSizeExpandableControlState extends State<_FontSizeExpandableControl> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late double _tempFontSize;

  @override
  void initState() {
    super.initState();
    _tempFontSize = widget.videoPlayerState._subtitleFontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main font size item
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.format_size,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subtitle Font Size',
                          style: Theme.of(widget.sheetContext).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.videoPlayerState._subtitleFontSize.toStringAsFixed(1)} pt',
                          style: Theme.of(widget.sheetContext).textTheme.bodySmall?.copyWith(
                            color: Theme.of(widget.sheetContext).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: widget.primaryColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Expandable content with preview and slider
        AnimatedCrossFade(
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark ? widget.onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.onSurfaceColor.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.onSurfaceColor.withValues(alpha: 0.12)),
                  ),
                  child: Text(
                    'Preview: The quick brown fox – 12345',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _tempFontSize,
                      fontFamily: widget.videoPlayerState._subtitleFontFamily,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(
                          blurRadius: 3.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Slider control
                SliderTheme(
                  data: SliderTheme.of(widget.sheetContext).copyWith(
                    activeTrackColor: widget.primaryColor.withValues(alpha: 0.80),
                    inactiveTrackColor: widget.onSurfaceColor.withValues(alpha: 0.20),
                    thumbColor: widget.primaryColor,
                    overlayColor: widget.primaryColor.withValues(alpha: 0.12),
                    valueIndicatorColor: widget.primaryColor,
                  ),
                  child: Slider(
                    min: 8.0,
                    max: 48.0,
                    divisions: 40,
                    value: _tempFontSize,
                    label: _tempFontSize.toStringAsFixed(1),
                    onChanged: (v) {
                      setState(() => _tempFontSize = v);
                    },
                    onChangeEnd: (v) async {
                      // Apply the new font size
                      await PreferencesModel.setSubtitleFontSize(v);
                      if (widget.videoPlayerState.mounted) {
                        widget.videoPlayerState.setState(() {
                          widget.videoPlayerState._subtitleFontSize = v;
                        });
                        widget.videoPlayerState._updateActiveSubtitles(widget.videoPlayerState.getCurrentPosition());
                        widget.videoPlayerState._fullscreenOverlay?.markNeedsBuild();
                      }
                    },
                  ),
                ),
                
                // Control row with reset button and value display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() => _tempFontSize = 16.0);
                        // Also apply the reset immediately
                        PreferencesModel.setSubtitleFontSize(16.0).then((_) {
                          if (widget.videoPlayerState.mounted) {
                            widget.videoPlayerState.setState(() {
                              widget.videoPlayerState._subtitleFontSize = 16.0;
                            });
                            widget.videoPlayerState._updateActiveSubtitles(widget.videoPlayerState.getCurrentPosition());
                            widget.videoPlayerState._fullscreenOverlay?.markNeedsBuild();
                          }
                        });
                      },
                      child: Text('Reset', 
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    Text(
                      '${_tempFontSize.toStringAsFixed(1)} pt', 
                      style: Theme.of(widget.sheetContext).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.primaryColor,
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Speed button
class _SpeedButton extends StatefulWidget {
  const _SpeedButton();

  @override
  _SpeedButtonState createState() => _SpeedButtonState();
}

class _SpeedButtonState extends State<_SpeedButton> {
  @override
  Widget build(BuildContext context) {
    final videoPlayerState = context.findAncestorStateOfType<VideoPlayerWidgetState>();
    
    if (videoPlayerState == null) {
      return const SizedBox.shrink();
    }
    
    final currentSpeed = videoPlayerState.getCurrentSpeed();
    String speedText = '${currentSpeed}x';
    if (currentSpeed == 1.0) {
      speedText = '1x';
    } else if (currentSpeed == currentSpeed.toInt().toDouble()) {
      speedText = '${currentSpeed.toInt()}x';
    }
    
    return InkWell(
      onTap: () {
        videoPlayerState.showSpeedDialog(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: currentSpeed != 1.0 ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              speedText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Volume slider button with seeking functionality
class _VolumeSliderButton extends StatefulWidget {
  const _VolumeSliderButton();

  @override
  _VolumeSliderButtonState createState() => _VolumeSliderButtonState();
}

class _VolumeSliderButtonState extends State<_VolumeSliderButton> with TickerProviderStateMixin {
  // Static field to track if any volume slider is currently in use across all instances
  static bool _isAnyVolumeSliderInUse = false;
  
  bool _showSlider = false;
  bool _isSliding = false; // Track if user is actively sliding
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  OverlayEntry? _overlayEntry; // Use overlay for higher z-index
  Timer? _hideTimer; // Timer to auto-hide slider

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hideSlider();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMute() {
    if (!mounted) return;
    
    try {
      final videoPlayerState = context.findAncestorStateOfType<VideoPlayerWidgetState>();
      final player = videoPlayerState?._player;
      
      if (player != null) {
        final currentVolume = videoPlayerState?._currentVolume ?? 100.0;
        if (currentVolume > 0) {
          _setVolume(0);
        } else {
          _setVolume(100);
        }
      }
    } catch (e) {
      debugPrint('Volume slider error in _toggleMute: $e');
    }
  }

  void _setVolume(double volume) async {
    // Check mounted state before accessing context
    if (!mounted) return;
    
    try {
      final videoPlayerState = context.findAncestorStateOfType<VideoPlayerWidgetState>();
      final player = videoPlayerState?._player;
      
      if (player != null && mounted) {
        player.setVolume(volume);
        // Update the global volume state
        if (videoPlayerState != null && videoPlayerState.mounted) {
          videoPlayerState.setState(() {
            videoPlayerState._currentVolume = volume;
          });
        }
        // Rebuild the overlay to show updated volume
        if (_overlayEntry != null && mounted) {
          _overlayEntry!.markNeedsBuild();
        }
        // Save volume to preferences
        await PreferencesModel.setVideoVolume(volume);
      }
    } catch (e) {
      debugPrint('Volume slider error in _setVolume: $e');
    }
  }

  void _toggleSlider() {
    if (!mounted) return;
    
    try {
      setState(() {
        _showSlider = !_showSlider;
      });
      
      if (_showSlider) {
        _showVolumeSlider();
        _animationController.forward();
        _startHideTimer();
      } else {
        _hideSlider();
        _animationController.reverse();
        _cancelHideTimer();
      }
    } catch (e) {
      // Silently handle setState errors during widget disposal
    }
  }

  void _startHideTimer() {
    _cancelHideTimer();
    if (!_isSliding && mounted) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isSliding) {
          _hideSlider();
        }
      });
    }
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _showVolumeSlider() {
    if (_overlayEntry != null || !mounted) return;

    try {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;
      
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: position.dx + (size.width / 2) - 25, // Center the slider over the button
          bottom: MediaQuery.of(context).size.height - position.dy + 8, // Position above button
          child: Material(
            color: Colors.transparent,
            child: _buildVerticalVolumeSlider(),
          ),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
    } catch (e) {
      debugPrint('Volume slider error in _showVolumeSlider: $e');
    }
  }

  void _hideSlider() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    // Clear global flag when hiding slider
    _VolumeSliderButtonState._isAnyVolumeSliderInUse = false;
    
    // Check mounted before attempting setState to avoid lifecycle errors during rebuilds
    if (!mounted) return;
    
    try {
      setState(() {
        _showSlider = false;
      });
      _animationController.reverse();
    } catch (e) {
      // Silently handle setState errors during widget disposal
      // This can happen when keyboard animations trigger parent rebuilds
    }
  }

  void _onSliderStart() {
    if (!mounted) return;
    
    try {
      setState(() {
        _isSliding = true;
      });
    } catch (e) {
      // Silently handle setState errors during widget disposal
    }
    
    // Set global flag to prevent main controls from hiding
    _VolumeSliderButtonState._isAnyVolumeSliderInUse = true;
    _cancelHideTimer(); // Don't hide while sliding
    debugPrint('Volume slider: Started sliding - keeping controls visible');
  }

  void _onSliderEnd() {
    if (!mounted) return;
    
    try {
      setState(() {
        _isSliding = false;
      });
    } catch (e) {
      // Silently handle setState errors during widget disposal
    }
    
    // Clear global flag to allow main controls to hide again
    _VolumeSliderButtonState._isAnyVolumeSliderInUse = false;
    _startHideTimer(); // Resume hide timer after sliding
    debugPrint('Volume slider: Finished sliding');
  }

  // Getter to check if volume slider is being used (for external components)
  bool get isSliding => _isSliding;

  Widget _buildVerticalVolumeSlider() {
    // Check mounted state before accessing context
    if (!mounted) {
      return const SizedBox.shrink();
    }
    
    final videoPlayerState = context.findAncestorStateOfType<VideoPlayerWidgetState>();
    final currentVolume = videoPlayerState?._currentVolume ?? 100.0;
    final isMuted = currentVolume <= 0;
    final volumePercentage = isMuted ? 0 : currentVolume.round();

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.scale(
          scaleY: _slideAnimation.value,
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: _slideAnimation.value,
            child: MouseRegion(
              onEnter: (_) {
                // Set global flag to prevent main controls from hiding while hovering
                _VolumeSliderButtonState._isAnyVolumeSliderInUse = true;
                _cancelHideTimer(); // Keep visible while hovering
              },
              onExit: (_) {
                if (!_isSliding) {
                  // Clear global flag when not hovering and not sliding
                  _VolumeSliderButtonState._isAnyVolumeSliderInUse = false;
                  _startHideTimer(); // Resume timer when not hovering
                }
              },
              child: Container(
                width: 50,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9), // Higher opacity for better visibility
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Volume percentage text
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$volumePercentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Vertical slider
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: RotatedBox(
                          quarterTurns: 3, // Rotate to make it vertical
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                              trackHeight: 3.0,
                            ),
                            child: Slider(
                              value: isMuted ? 0.0 : currentVolume,
                              min: 0.0,
                              max: 100.0,
                              divisions: 100,
                              onChangeStart: (value) {
                                _onSliderStart();
                              },
                              onChanged: (value) {
                                _setVolume(value);
                              },
                              onChangeEnd: (value) {
                                _onSliderEnd();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return const SizedBox.shrink();
    }
    
    final videoPlayerState = context.findAncestorStateOfType<VideoPlayerWidgetState>();
    final player = videoPlayerState?._player;
    
    if (player == null) {
      return const SizedBox.shrink();
    }
    
    return StreamBuilder<double>(
      stream: player.stream.volume,
      initialData: player.state.volume,
      builder: (context, snapshot) {
        final currentVolume = videoPlayerState?._currentVolume ?? 100.0;
        final isMuted = currentVolume <= 0;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Volume button (slider is now in overlay)
            GestureDetector(
              onTap: _toggleSlider,
              onSecondaryTap: _toggleMute, // Right click to mute/unmute
              child: Container(
                width: 40,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (_showSlider || _isSliding) ? Colors.white.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isMuted ? Icons.volume_off : 
                  currentVolume < 33 ? Icons.volume_down :
                  currentVolume < 66 ? Icons.volume_up : Icons.volume_up,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Fullscreen volume slider button - similar to _VolumeSliderButton but with direct state access
class _FullscreenVolumeSliderButton extends StatefulWidget {
  final Player player;
  final VideoPlayerWidgetState? videoPlayerState;
  final VoidCallback onShowControls;

  const _FullscreenVolumeSliderButton({
    required this.player,
    required this.videoPlayerState,
    required this.onShowControls,
  });

  @override
  _FullscreenVolumeSliderButtonState createState() => _FullscreenVolumeSliderButtonState();
}

class _FullscreenVolumeSliderButtonState extends State<_FullscreenVolumeSliderButton> with TickerProviderStateMixin {
  bool _showSlider = false;
  bool _isSliding = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hideSlider();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMute() {
    if (!mounted) return;
    
    try {
      final videoPlayerState = widget.videoPlayerState;
      if (videoPlayerState != null && videoPlayerState.mounted) {
        videoPlayerState.toggleMute();
        widget.onShowControls();
      }
    } catch (e) {
      debugPrint('Fullscreen volume slider error in _toggleMute: $e');
    }
  }

  void _setVolume(double volume) async {
    if (!mounted) return;
    
    try {
      widget.player.setVolume(volume);
      
      final videoPlayerState = widget.videoPlayerState;
      if (videoPlayerState != null && videoPlayerState.mounted) {
        videoPlayerState.setState(() {
          videoPlayerState._currentVolume = volume;
        });
      }
      if (_overlayEntry != null && mounted) {
        _overlayEntry!.markNeedsBuild();
      }
      await PreferencesModel.setVideoVolume(volume);
    } catch (e) {
      debugPrint('Fullscreen volume slider error in _setVolume: $e');
    }
  }

  void _toggleSlider() {
    if (mounted) {
      try {
        if (_showSlider) {
          // If slider is currently shown, hide it
          _hideSlider();
        } else {
          // If slider is currently hidden, show it
          setState(() {
            _showSlider = true;
          });
          _showVolumeSlider();
        }
        widget.onShowControls();
      } catch (e) {
        debugPrint('Fullscreen volume slider error in _toggleSlider: $e');
      }
    }
  }

  void _startHideTimer() {
    _cancelHideTimer();
    if (!_isSliding && mounted) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isSliding) {
          _hideSlider();
        }
      });
    }
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _showVolumeSlider() {
    if (_overlayEntry != null || !mounted) return;

    try {
      _overlayEntry = OverlayEntry(
        builder: (context) => _buildVerticalVolumeSlider(),
      );
      Overlay.of(context).insert(_overlayEntry!);
      // Start hide timer after showing the slider
      _startHideTimer();
    } catch (e) {
      debugPrint('Fullscreen volume slider error in _showVolumeSlider: $e');
    }
  }

  void _hideSlider() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _VolumeSliderButtonState._isAnyVolumeSliderInUse = false;
    
    if (!mounted) return;
    
    try {
      setState(() {
        _showSlider = false;
        _isSliding = false;
      });
      _animationController.reverse();
    } catch (e) {
      // Silently handle setState errors during widget disposal
    }
  }

  void _onSliderStart() {
    if (mounted) {
      try {
        setState(() {
          _isSliding = true;
        });
      } catch (e) {
        debugPrint('Fullscreen volume slider error in _onSliderStart: $e');
      }
    }
    _VolumeSliderButtonState._isAnyVolumeSliderInUse = true;
    _cancelHideTimer();
    debugPrint('Fullscreen volume slider: Started sliding - keeping controls visible');
  }

  void _onSliderEnd() {
    if (mounted) {
      try {
        setState(() {
          _isSliding = false;
        });
      } catch (e) {
        debugPrint('Fullscreen volume slider error in _onSliderEnd: $e');
      }
    }
    _VolumeSliderButtonState._isAnyVolumeSliderInUse = false;
    _startHideTimer();
    debugPrint('Fullscreen volume slider: Finished sliding');
  }

  Widget _buildVerticalVolumeSlider() {
    if (!mounted) {
      return const SizedBox.shrink();
    }
    
    final videoPlayerState = widget.videoPlayerState;
    final currentVolume = videoPlayerState?._currentVolume ?? 100.0;
    final isMuted = currentVolume <= 0;
    final volumePercentage = isMuted ? 0 : currentVolume.round();

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: 120,
          left: 50,
          child: MouseRegion(
            onEnter: (_) {
              _VolumeSliderButtonState._isAnyVolumeSliderInUse = true;
              _cancelHideTimer();
            },
            onExit: (_) {
              _VolumeSliderButtonState._isAnyVolumeSliderInUse = false;
              _startHideTimer();
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 50,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      '$volumePercentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                            trackHeight: 4.0,
                          ),
                          child: Slider(
                            value: isMuted ? 0.0 : currentVolume,
                            min: 0.0,
                            max: 100.0,
                            divisions: 100,
                            onChangeStart: (_) => _onSliderStart(),
                            onChangeEnd: (_) => _onSliderEnd(),
                            onChanged: (value) {
                              _setVolume(value);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return const SizedBox.shrink();
    }
    
    final videoPlayerState = widget.videoPlayerState;
    final currentVolume = videoPlayerState?._currentVolume ?? 100.0;
    final isMuted = currentVolume <= 0;
    
    return StreamBuilder<double>(
      stream: widget.player.stream.volume,
      initialData: widget.player.state.volume,
      builder: (context, snapshot) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _toggleSlider,
              onSecondaryTap: _toggleMute,
              child: Container(
                width: 40,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (_showSlider || _isSliding) ? Colors.white.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isMuted ? Icons.volume_off : 
                  currentVolume < 33 ? Icons.volume_down :
                  currentVolume < 66 ? Icons.volume_up : Icons.volume_up,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Subtitle toggle button
class _SubtitleToggleButton extends StatefulWidget {
  const _SubtitleToggleButton();

  @override
  _SubtitleToggleButtonState createState() => _SubtitleToggleButtonState();
}

class _SubtitleToggleButtonState extends State<_SubtitleToggleButton> with WidgetsBindingObserver {
  bool _subtitlesEnabled = true;
  bool _isHovered = false;
  VideoPlayerWidgetState? _videoPlayerState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Schedule a post-frame callback to capture the initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSubtitleState();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateSubtitleState();
    }
  }

  void _updateSubtitleState() {
    final videoPlayerState = context.findAncestorStateOfType<VideoPlayerWidgetState>();
    if (videoPlayerState != null && mounted) {
      _videoPlayerState = videoPlayerState;
      if (_subtitlesEnabled != videoPlayerState._areSubtitlesEnabled) {
        setState(() {
          _subtitlesEnabled = videoPlayerState._areSubtitlesEnabled;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videoPlayerState == null) {
      _videoPlayerState = context.findAncestorStateOfType<VideoPlayerWidgetState>();
      if (_videoPlayerState != null) {
        _subtitlesEnabled = _videoPlayerState!._areSubtitlesEnabled;
      } else {
        return const SizedBox.shrink();
      }
    }
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          // Toggle local state immediately for instant UI feedback
          setState(() {
            _subtitlesEnabled = !_subtitlesEnabled;
          });
          
          // Then update the actual player state
          _videoPlayerState!.toggleSubtitles();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32, // Increased size for better usability
          height: 32, // Increased size for better usability
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered ? Colors.white.withOpacity(0.2) : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Icon(
            _subtitlesEnabled ? Icons.subtitles : Icons.subtitles_off,
            color: _isHovered ? Colors.blue.shade200 : Colors.white,
            size: 22, // Increased icon size
          ),
        ),
      ),
    );
  }
}

// Settings button - combines audio track and speed controls
class _SettingsButton extends StatefulWidget {
  const _SettingsButton();

  @override
  _SettingsButtonState createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<_SettingsButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final videoPlayerState = context.findAncestorStateOfType<VideoPlayerWidgetState>();
    
    if (videoPlayerState == null) {
      return const SizedBox.shrink();
    }
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          _showSettingsMenu(context, videoPlayerState);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32, // Increased size for better usability
          height: 32, // Increased size for better usability
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.tune, // Configuration/settings icon
            color: _isHovered ? Colors.blue.shade200 : Colors.white,
            size: 22, // Increased icon size
            shadows: const [
              Shadow(
                blurRadius: 3.0,
                color: Colors.black,
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsMenu(BuildContext context, VideoPlayerWidgetState videoPlayerState) {
    // Capture parent context so inner builders can call dialogs/snackbars safely after the sheet is popped
    final BuildContext parentContext = context;
    // Show settings sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Use a distinct name for the sheet's builder context to avoid shadowing the parent
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            // Dynamic color variables for adaptive theming
            final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
            final primaryColor = Theme.of(sheetContext).primaryColor;
            final surfaceColor = Theme.of(sheetContext).colorScheme.surface;
            final onSurfaceColor = Theme.of(sheetContext).colorScheme.onSurface;
            final mutedColor = onSurfaceColor.withValues(alpha: 0.6);

            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  controller: scrollController,
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
                                Icons.settings,
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
                                    'Video Settings',
                                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Adjust playback and subtitle settings',
                                    style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
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
              
                      
                      // Playback Speed Section
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setSpeedState) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.speed,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Playback Speed',
                                        style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${videoPlayerState.getCurrentSpeed()}x',
                                        style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(sheetContext).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<double>(
                                  onSelected: (double value) {
                                    videoPlayerState.setPlaybackSpeed(value);
                                    setSpeedState(() {}); // Trigger rebuild of this section
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: onSurfaceColor.withValues(alpha: 0.12),
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      color: Theme.of(sheetContext).iconTheme.color?.withValues(alpha: 0.6),
                                      size: 18,
                                    ),
                                  ),
                                  itemBuilder: (BuildContext context) {
                                    final speedOptions = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
                                    return speedOptions.map((double speed) {
                                      final isSelected = videoPlayerState.getCurrentSpeed() == speed;
                                      String label = '${speed}x';
                                      if (speed == 1.0) label = '1x (Normal)';
                                      
                                      return PopupMenuItem<double>(
                                        value: speed,
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                              color: isSelected ? primaryColor : onSurfaceColor.withValues(alpha: 0.6),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              label,
                                              style: TextStyle(
                                                color: isSelected ? primaryColor : onSurfaceColor,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Audio Track Section
                      Builder(
                        builder: (context) {
                          final availableTracks = videoPlayerState.getAvailableAudioTracks();
                          // Exclude pseudo-tracks 'auto' and 'no' when reporting available tracks
                          final realTracks = availableTracks.where((t) => t.id != 'auto' && t.id != 'no').toList();
                          final hasMultipleTracks = realTracks.length > 1;
                          
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.audiotrack,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Audio Track',
                                        style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        hasMultipleTracks 
                                          ? '${realTracks.length} tracks available'
                                          : 'Default track',
                                        style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(sheetContext).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                hasMultipleTracks 
                                  ? PopupMenuButton<AudioTrack>(
                                      onSelected: (AudioTrack track) async {
                                        await videoPlayerState.setAudioTrack(track);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: onSurfaceColor.withValues(alpha: 0.12),
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Icon(
                                          Icons.arrow_drop_down,
                                          color: Theme.of(sheetContext).iconTheme.color?.withValues(alpha: 0.6),
                                          size: 18,
                                        ),
                                      ),
                                      itemBuilder: (BuildContext context) {
                                        final currentTrack = videoPlayerState.getCurrentAudioTrack();
                                        return availableTracks.map((AudioTrack track) {
                                          final isSelected = currentTrack?.id == track.id;
                                          
                                          // Get track display name
                                          String trackName = 'Track ${track.id}';
                                          if (track.id == 'auto') {
                                            trackName = 'Auto';
                                          } else if (track.id == 'no') {
                                            trackName = 'Off';
                                          } else if (track.title?.isNotEmpty == true) {
                                            trackName = track.title!;
                                          } else if (track.language?.isNotEmpty == true) {
                                            trackName = 'Track ${track.id} (${track.language})';
                                          }
                                          
                                          return PopupMenuItem<AudioTrack>(
                                            value: track,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                                  color: isSelected ? Colors.orange : onSurfaceColor.withValues(alpha: 0.6),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    trackName,
                                                    style: TextStyle(
                                                      color: isSelected ? Colors.orange : onSurfaceColor,
                                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList();
                                      },
                                    )
                                  : Icon(
                                      Icons.not_interested,
                                      color: Theme.of(sheetContext).iconTheme.color?.withValues(alpha: 0.3),
                                      size: 18,
                                    ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Custom font loader
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            // Close sheet first (use sheetContext) then call pick using captured parentContext so lookups are safe
                            Navigator.pop(sheetContext);
                            await videoPlayerState._pickAndSaveFont(parentContext);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.font_download,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Load Custom Subtitle Font',
                                        style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        videoPlayerState._subtitleFontFilePath != null
                                            ? videoPlayerState._subtitleFontFilePath!.split(Platform.pathSeparator).last
                                            : 'No custom font',
                                        style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(sheetContext).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Theme.of(sheetContext).iconTheme.color?.withValues(alpha: 0.3),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Font size adjustment with expandable preview
                      _FontSizeExpandableControl(
                        videoPlayerState: videoPlayerState,
                        primaryColor: primaryColor,
                        onSurfaceColor: onSurfaceColor,
                        isDark: isDark,
                        sheetContext: sheetContext,
                      ),
                      const SizedBox(height: 16),
                      // Subtitle background toggle
                      StatefulBuilder(
                        builder: (
                          BuildContext context,
                          StateSetter setSheetState,
                        ) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final newValue =
                                    !videoPlayerState._showSubtitleBackground;
                                await PreferencesModel.setShowSubtitleBackground(
                                  newValue,
                                );
                                videoPlayerState.setState(() {
                                  videoPlayerState._showSubtitleBackground =
                                      newValue;
                                });
                                setSheetState(() {}); // Update sheet UI
                                videoPlayerState._updateActiveSubtitles(
                                  videoPlayerState.getCurrentPosition(),
                                );
                                videoPlayerState._fullscreenOverlay
                                    ?.markNeedsBuild();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.text_fields,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Subtitle Background',
                                            style: Theme.of(
                                              sheetContext,
                                            ).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            videoPlayerState
                                                    ._showSubtitleBackground
                                                ? 'Enabled'
                                                : 'Disabled',
                                            style: Theme.of(
                                              sheetContext,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(sheetContext)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withValues(alpha: 0.6),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value:
                                          videoPlayerState
                                              ._showSubtitleBackground,
                                      onChanged: (value) async {
                                        await PreferencesModel.setShowSubtitleBackground(
                                          value,
                                        );
                                        videoPlayerState.setState(() {
                                          videoPlayerState
                                              ._showSubtitleBackground = value;
                                        });
                                        setSheetState(() {}); // Update sheet UI
                                        videoPlayerState._updateActiveSubtitles(
                                          videoPlayerState.getCurrentPosition(),
                                        );
                                        videoPlayerState._fullscreenOverlay
                                            ?.markNeedsBuild();
                                      },
                                      activeColor: primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Primary subtitle position adjustment
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setSheetState) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: onSurfaceColor.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.vertical_align_bottom,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Primary Subtitle Position',
                                            style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Adjust vertical position: ${videoPlayerState._primarySubtitleVerticalPosition.round()}px',
                                            style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                                              color: mutedColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                  // Adjustment buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Down button
                                      ElevatedButton(
                                        onPressed: () async {
                                          final newPosition = (videoPlayerState._primarySubtitleVerticalPosition - 10).clamp(-1000.0, 1000.0);
                                          await PreferencesModel.setPrimarySubtitleVerticalPosition(newPosition);
                                          videoPlayerState.setState(() {
                                            videoPlayerState._primarySubtitleVerticalPosition = newPosition;
                                          });
                                          setSheetState(() {}); // Update the sheet UI
                                          videoPlayerState._updateActiveSubtitles(videoPlayerState.getCurrentPosition());
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          minimumSize: const Size(48, 48),
                                        ),
                                        child: Icon(Icons.keyboard_arrow_down, size: 18),
                                      ),
                                      // Position display
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: surfaceColor,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: onSurfaceColor.withValues(alpha: 0.12),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${videoPlayerState._primarySubtitleVerticalPosition.round()}px',
                                          style: TextStyle(
                                            color: onSurfaceColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      // Up button
                                      ElevatedButton(
                                        onPressed: () async {
                                          final newPosition = (videoPlayerState._primarySubtitleVerticalPosition + 10).clamp(-1000.0, 1000.0);
                                          await PreferencesModel.setPrimarySubtitleVerticalPosition(newPosition);
                                          videoPlayerState.setState(() {
                                            videoPlayerState._primarySubtitleVerticalPosition = newPosition;
                                          });
                                          setSheetState(() {}); // Update the sheet UI
                                          videoPlayerState._updateActiveSubtitles(videoPlayerState.getCurrentPosition());
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          minimumSize: const Size(48, 48),
                                        ),
                                        child: Icon(Icons.keyboard_arrow_up, size: 18),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Secondary subtitle position adjustment (only show if secondary subtitles are loaded)
                      if (videoPlayerState._currentSecondarySubtitles.isNotEmpty)
                        StatefulBuilder(
                          builder: (BuildContext context, StateSetter setSheetState) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: onSurfaceColor.withValues(alpha: 0.12),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.vertical_align_top,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Secondary Subtitle Position',
                                              style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Adjust vertical position: ${videoPlayerState._secondarySubtitleVerticalPosition.round()}px',
                                              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                                                color: mutedColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Adjustment buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Down button (moves up due to swapped functionality)
                                      ElevatedButton(
                                        onPressed: () async {
                                          final newPosition = (videoPlayerState._secondarySubtitleVerticalPosition + 10).clamp(-1000.0, 1000.0);
                                          await PreferencesModel.setSecondarySubtitleVerticalPosition(newPosition);
                                          videoPlayerState.setState(() {
                                            videoPlayerState._secondarySubtitleVerticalPosition = newPosition;
                                          });
                                          setSheetState(() {}); // Update the sheet UI
                                          videoPlayerState._updateActiveSubtitles(videoPlayerState.getCurrentPosition());
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          minimumSize: const Size(48, 48),
                                        ),
                                        child: Icon(Icons.keyboard_arrow_down, size: 18),
                                      ),
                                      // Position display
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: surfaceColor,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: onSurfaceColor.withValues(alpha: 0.12),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${videoPlayerState._secondarySubtitleVerticalPosition.round()}px',
                                          style: TextStyle(
                                            color: onSurfaceColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      // Up button (moves down due to swapped functionality)
                                      ElevatedButton(
                                        onPressed: () async {
                                          final newPosition = (videoPlayerState._secondarySubtitleVerticalPosition - 10).clamp(-1000.0, 1000.0);
                                          await PreferencesModel.setSecondarySubtitleVerticalPosition(newPosition);
                                          videoPlayerState.setState(() {
                                            videoPlayerState._secondarySubtitleVerticalPosition = newPosition;
                                          });
                                          setSheetState(() {}); // Update the sheet UI
                                          videoPlayerState._updateActiveSubtitles(videoPlayerState.getCurrentPosition());
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          minimumSize: const Size(48, 48),
                                        ),
                                        child: Icon(Icons.keyboard_arrow_up, size: 18),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Fullscreen button
class _FullscreenButton extends StatefulWidget {
  const _FullscreenButton();

  @override
  _FullscreenButtonState createState() => _FullscreenButtonState();
}

class _FullscreenButtonState extends State<_FullscreenButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final videoPlayerState = context.findAncestorStateOfType<VideoPlayerWidgetState>();
    
    if (videoPlayerState == null) {
      return const SizedBox.shrink();
    }
    
    // Use our custom fullscreen toggle instead of Material Design button
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          videoPlayerState._toggleCustomFullscreen();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32, // Increased size for better usability
          height: 32, // Increased size for better usability
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered ? Colors.white.withOpacity(0.2) : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Icon(
            videoPlayerState._isCustomFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: _isHovered ? Colors.blue.shade200 : Colors.white,
            size: 22, // Increased icon size
          ),
        ),
      ),
    );
  }
}

// Custom fullscreen controls widget with auto-hide functionality
class _FullscreenControlsWidget extends StatefulWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String videoPath;
  final bool areSubtitlesEnabled;
  final double currentSpeed;
  final List<AudioTrack> availableAudioTracks;
  final List<Subtitle> subtitles;
  final List<Subtitle> secondarySubtitles;
  final VoidCallback onExitFullscreen;
  final VoidCallback onToggleSubtitles;
  final Function(double) onSeek;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeekRelative;
  final VoidCallback onToggleMute;
  final Function(double) onSpeedChange;
  final Function(AudioTrack) onAudioTrackChange;
  final VoidCallback onSeekToPreviousSubtitle;
  final VoidCallback onSeekToNextSubtitle;
  final String Function(Duration) formatDuration;
  final Function(int, bool)? onSubtitleMarked;
  final Function(int, String?)? onSubtitleCommentUpdated;
  final Player player;
  final BuildContext? originalContext; // For showing dialogs over fullscreen
  final int skipDurationSeconds; // Skip duration parameter
  final VideoPlayerWidgetState? videoPlayerState; // Video player state for volume control

  const _FullscreenControlsWidget({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.videoPath,
    required this.areSubtitlesEnabled,
    required this.currentSpeed,
    required this.availableAudioTracks,
    required this.subtitles,
    required this.secondarySubtitles,
    required this.onExitFullscreen,
    required this.onToggleSubtitles,
    required this.onSeek,
    required this.onPlayPause,
    required this.onSeekRelative,
    required this.onToggleMute,
    required this.onSpeedChange,
    required this.onAudioTrackChange,
    required this.onSeekToPreviousSubtitle,
    required this.onSeekToNextSubtitle,
    required this.formatDuration,
    this.onSubtitleMarked,
    this.onSubtitleCommentUpdated,
    required this.player,
    this.originalContext, // For showing dialogs over fullscreen
    required this.skipDurationSeconds, // Add to constructor
    this.videoPlayerState, // Add video player state parameter
  });

  @override
  _FullscreenControlsWidgetState createState() => _FullscreenControlsWidgetState();
}

class _FullscreenControlsWidgetState extends State<_FullscreenControlsWidget> {
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _isCommentDialogOpen = false; // Track if comment dialog is currently visible
  
  // Cache active subtitle to avoid expensive searches every frame
  Subtitle? _cachedActiveSubtitle;
  Duration _cachedPosition = Duration.zero;
  int _cachedSubtitlesVersion = 0;

  @override
  void initState() {
    super.initState();
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FullscreenControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Invalidate cache when subtitles change (not just position)
    if (widget.subtitles != oldWidget.subtitles ||
        widget.secondarySubtitles != oldWidget.secondarySubtitles) {
      _cachedSubtitlesVersion++; // Force cache invalidation
    }
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    
    // Check if any volume slider is currently in use
    if (_VolumeSliderButtonState._isAnyVolumeSliderInUse) {
      debugPrint('Fullscreen controls: Volume slider in use, restarting timer instead of hiding');
      // Restart timer instead of hiding immediately
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && !_VolumeSliderButtonState._isAnyVolumeSliderInUse) {
          setState(() {
            _controlsVisible = false;
          });
        } else if (mounted) {
          // If volume slider still in use, restart timer again
          _resetHideTimer();
        }
      });
      return;
    }
    
    _hideTimer = Timer(const Duration(seconds: 4), () { // Increased from 3 to 4 seconds for better mouse hover experience
      if (mounted && !_VolumeSliderButtonState._isAnyVolumeSliderInUse) {
        setState(() {
          _controlsVisible = false;
        });
      } else if (mounted) {
        // If volume slider started during timer, restart timer
        _resetHideTimer();
      }
    });
  }

  void _toggleControls() {
    if (mounted) {
      setState(() {
        _controlsVisible = !_controlsVisible;
      });
      if (_controlsVisible) {
        _resetHideTimer();
      } else {
        _hideTimer?.cancel();
      }
    }
  }

  void _showControls() {
    if (mounted) {
      setState(() {
        _controlsVisible = true;
      });
      _resetHideTimer();
    }
  }

  String _getFileName() {
    final path = widget.videoPath;
    
    // Handle SAF content URIs on Android
    if (Platform.isAndroid && path.startsWith('content://')) {
      try {
        // Convert SAF URI to display path, then extract filename
        final displayPath = SafPathConverter.normalizePath(path);
        
        if (kDebugMode) {
          print('VideoPlayer _getFileName: originalPath=$path');
          print('VideoPlayer _getFileName: displayPath=$displayPath');
        }
        
        // Extract filename from the normalized path
        final lastSlash = displayPath.lastIndexOf('/');
        final lastBackslash = displayPath.lastIndexOf('\\');
        final lastSeparator = lastSlash > lastBackslash ? lastSlash : lastBackslash;
        
        if (lastSeparator != -1 && lastSeparator < displayPath.length - 1) {
          final fileName = displayPath.substring(lastSeparator + 1);
          if (kDebugMode) {
            print('VideoPlayer _getFileName: extracted fileName=$fileName');
          }
          return fileName;
        }
        
        // If no separators found in display path, try to extract from original URI
        if (displayPath == path) {
          // Fallback: extract filename from URI path segments
          final uri = Uri.parse(path);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            // Get the last segment and decode any URL encoding
            final lastSegment = Uri.decodeFull(pathSegments.last);
            // If it looks like a filename with extension, return it
            if (lastSegment.contains('.')) {
              if (kDebugMode) {
                print('VideoPlayer _getFileName: fallback fileName=$lastSegment');
              }
              return lastSegment;
            }
          }
        }
        
        return displayPath;
      } catch (e) {
        if (kDebugMode) {
          print('VideoPlayer _getFileName: SAF conversion error: $e');
        }
        // If SAF conversion fails, fall back to basic URI parsing
        try {
          final uri = Uri.parse(path);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            final fallbackName = Uri.decodeFull(pathSegments.last);
            if (kDebugMode) {
              print('VideoPlayer _getFileName: URI fallback fileName=$fallbackName');
            }
            return fallbackName;
          }
        } catch (e2) {
          if (kDebugMode) {
            print('VideoPlayer _getFileName: URI parsing error: $e2');
          }
          // Ultimate fallback: return the path as-is
        }
      }
    }
    
    // Handle regular file paths
    final lastSlash = path.lastIndexOf('/');
    final lastBackslash = path.lastIndexOf('\\');
    final lastSeparator = lastSlash > lastBackslash ? lastSlash : lastBackslash;
    if (lastSeparator != -1 && lastSeparator < path.length - 1) {
      final fileName = path.substring(lastSeparator + 1);
      if (kDebugMode && Platform.isAndroid) {
        print('VideoPlayer _getFileName: regular path fileName=$fileName');
      }
      return fileName;
    }
    
    if (kDebugMode && Platform.isAndroid) {
      print('VideoPlayer _getFileName: returning original path=$path');
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showControls(), // Show controls on mouse hover
      onExit: (_) => _resetHideTimer(), // Reset hide timer when mouse leaves
      onHover: (_) => _showControls(), // Show controls on mouse movement
      child: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.translucent,
        onDoubleTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
          
          // Left third of screen - skip backward
          if (tapPosition < screenWidth / 3) {
            final currentPosition = widget.player.state.position;
            final newPosition = currentPosition - Duration(seconds: widget.skipDurationSeconds);
            widget.player.seek(newPosition.isNegative ? Duration.zero : newPosition);
            _showControls();
          } 
          // Right third of screen - skip forward
          else if (tapPosition > (2 * screenWidth / 3)) {
            final currentPosition = widget.player.state.position;
            final duration = widget.player.state.duration;
            final newPosition = currentPosition + Duration(seconds: widget.skipDurationSeconds);
            widget.player.seek(newPosition > duration ? duration : newPosition);
            _showControls();
          }
          // Middle third - do nothing (let center controls handle play/pause)
        },
        child: AnimatedOpacity(
          opacity: _controlsVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !_controlsVisible,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
              child: Stack(
            children: [
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Reduced horizontal from 16 to 8
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: widget.onExitFullscreen,
                        ),
                        const SizedBox(width: 8), // Reduced from 16 to 8
                        Expanded(
                          child: Text(
                            _getFileName(),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Center play/pause and skip buttons
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous subtitle skip
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                      onPressed: () {
                        debugPrint('FullscreenControls: Previous subtitle button pressed');
                        widget.onSeekToPreviousSubtitle();
                        _showControls();
                      },
                    ),
                    
                    // Skip backward
                    _FullscreenSkipButton(
                      icon: Icons.fast_rewind,
                      size: 48,
                      onPressed: () {
                        widget.onSeekRelative(Duration(seconds: -widget.skipDurationSeconds));
                        _showControls();
                      },
                      onHoldSkip: () {
                        widget.onSeekRelative(const Duration(milliseconds: -500));
                        _showControls();
                      },
                    ),
                    
                    // Play/Pause
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: StreamBuilder<bool>(
                        stream: widget.player.stream.playing,
                        initialData: widget.player.state.playing,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? widget.player.state.playing;
                          return IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 60,
                            ),
                            onPressed: () {
                              widget.onPlayPause();
                              _showControls();
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Skip forward
                    _FullscreenSkipButton(
                      icon: Icons.fast_forward,
                      size: 48,
                      onPressed: () {
                        widget.onSeekRelative(Duration(seconds: widget.skipDurationSeconds));
                        _showControls();
                      },
                      onHoldSkip: () {
                        widget.onSeekRelative(const Duration(milliseconds: 500));
                        _showControls();
                      },
                    ),
                    
                    // Next subtitle skip
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                      onPressed: () {
                        debugPrint('FullscreenControls: Next subtitle button pressed');
                        widget.onSeekToNextSubtitle();
                        _showControls();
                      },
                    ),
                  ],
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0), // Reduced from 16.0 to 8.0 for low-res displays
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Seek bar
                        Row(
                          children: [
                            Text(
                              widget.formatDuration(widget.position),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(width: 8), // Reduced from 16 to 8
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.blue,
                                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                                  thumbColor: Colors.blue,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                ),
                                child: Slider(
                                  value: widget.duration.inMilliseconds > 0 
                                      ? (widget.position.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0)
                                      : 0.0,
                                  onChanged: (value) {
                                    widget.onSeek(value);
                                    _showControls();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8), // Reduced from 16 to 8
                            Text(
                              widget.formatDuration(widget.duration),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12), // Reduced from 16 to 12
                        
                        // Control buttons
                        Row(
                          children: [
                            // Left side buttons: volume, subtitle, audio track, speed control
                            // Volume slider control (vertical slider like normal controls)
                            _buildVolumeButton(),
                            
                            const SizedBox(width: 8),
                            
                            // Subtitle toggle
                            IconButton(
                              icon: Icon(
                                widget.areSubtitlesEnabled ? Icons.subtitles : Icons.subtitles_off,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                widget.onToggleSubtitles();
                                _showControls();
                              },
                            ),
                            
                            // Audio track control - wrapped in StreamBuilder for state updates
                            StreamBuilder<Track>(
                              stream: widget.player.stream.track,
                              builder: (context, trackSnapshot) {
                                return _buildAudioTrackButton();
                              },
                            ),
                            
                            const SizedBox(width: 4), // Reduced from 8 to 4
                            
                            // Speed control - will update when state changes
                            _buildSpeedButton(),
                            
                            const SizedBox(width: 4), // Reduced from 8 to 4
                            
                            // Mark/Unmark current subtitle line button
                            _buildMarkButton(),
                            
                            const Spacer(), // Push fullscreen button to the right
                            
                            // Fullscreen exit button on the right
                            IconButton(
                              icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
                              onPressed: () {
                                widget.onExitFullscreen();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    ); // Close MouseRegion
  }

  /// Build speed control button that cycles through speeds
  Widget _buildSpeedButton() {
    String speedText = '${widget.currentSpeed}x';
    if (widget.currentSpeed == 1.0) {
      speedText = '1x';
    } else if (widget.currentSpeed == widget.currentSpeed.toInt().toDouble()) {
      speedText = '${widget.currentSpeed.toInt()}x';
    }

    return GestureDetector(
      onTap: () {
        _cycleSpeed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.currentSpeed != 1.0 ? Theme.of(context).primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              speedText,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _cycleSpeed() {
    // Available speed options
    final speedOptions = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    
    // Find current speed index
    int currentIndex = speedOptions.indexWhere((speed) => speed == widget.currentSpeed);
    
    // If not found, default to normal speed (1.0x)
    if (currentIndex == -1) {
      currentIndex = 3; // 1.0x is at index 3
    }
    
    // Move to next speed, cycling back to start if at end
    int nextIndex = (currentIndex + 1) % speedOptions.length;
    double nextSpeed = speedOptions[nextIndex];
    
    // Apply the new speed
    widget.onSpeedChange(nextSpeed);
    
    // Force a rebuild to update the speed button display
    if (mounted) {
      setState(() {});
    }
    
    _showControls();
  }

  /// Get cached active subtitle to avoid expensive searches every frame
  /// When multiple subtitles overlap, returns the first one for marking operations
  Subtitle? _getCachedActiveSubtitle() {
    // Only recalculate if position changed by more than 100ms or subtitles changed
    final positionDiff = (widget.position - _cachedPosition).inMilliseconds.abs();
    final subtitlesHash = widget.subtitles.length;
    
    if (positionDiff > 100 || _cachedSubtitlesVersion != subtitlesHash) {
      // Get all active subtitles and take the first one for marking
      final activeSubtitles = _findAllActiveSubtitles(widget.subtitles, widget.position);
      _cachedActiveSubtitle = activeSubtitles.isEmpty ? null : activeSubtitles.first;
      _cachedPosition = widget.position;
      _cachedSubtitlesVersion = subtitlesHash;
    }
    
    return _cachedActiveSubtitle;
  }

  /// Build mark/unmark control button for current subtitle line
  Widget _buildMarkButton() {
    // Use cached active subtitle to avoid expensive searches every frame
    final activeSubtitle = _getCachedActiveSubtitle();
    final isMarked = activeSubtitle?.marked ?? false;
    
    // Minimal debug logging (only when subtitle changes)
    if (activeSubtitle != null && activeSubtitle != _cachedActiveSubtitle) {
      debugPrint('FullscreenMark: subtitle ${activeSubtitle.index} marked=$isMarked at position ${widget.position.inSeconds}s');
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Listener(
        onPointerDown: (PointerDownEvent event) {
          // Handle mouse right-click for comment dialog
          if (event.kind == PointerDeviceKind.mouse && 
              event.buttons == kSecondaryMouseButton && 
              activeSubtitle != null && isMarked) {
            _showCommentDialog(activeSubtitle);
          }
        },
        child: GestureDetector(
          onTap: activeSubtitle != null ? () {
            // Toggle mark status and trigger rebuild
            _toggleMarkCurrentSubtitle(activeSubtitle);
          } : null,
          onLongPress: activeSubtitle != null && isMarked ? () {
            // Show comment dialog for marked lines (touch devices)
            _showCommentDialog(activeSubtitle);
          } : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMarked ? Icons.bookmark_added : Icons.bookmark_add_outlined,
              color: activeSubtitle != null 
                ? (isMarked ? Colors.red : Colors.white) 
                : Colors.grey,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Find all active subtitles at the current position (handles overlaps)
  /// Uses binary search + bidirectional scanning for efficiency
  List<Subtitle> _findAllActiveSubtitles(List<Subtitle> subtitles, Duration position) {
    if (subtitles.isEmpty) return [];
    
    final positionMs = position.inMilliseconds;
    
    // Binary search to find first subtitle that could be active
    int left = 0;
    int right = subtitles.length - 1;
    int firstCandidate = -1;
    
    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final subtitle = subtitles[mid];
      
      if (positionMs >= subtitle.start.inMilliseconds && 
          positionMs <= subtitle.end.inMilliseconds) {
        firstCandidate = mid;
        right = mid - 1; // Continue searching left for earlier matches
      } else if (positionMs < subtitle.start.inMilliseconds) {
        right = mid - 1;
      } else {
        left = mid + 1;
      }
    }
    
    if (firstCandidate == -1) return [];
    
    // Collect all active subtitles starting from firstCandidate
    final activeSubtitles = <Subtitle>[];
    
    // Scan backwards from firstCandidate
    for (int i = firstCandidate; i >= 0; i--) {
      final subtitle = subtitles[i];
      if (positionMs >= subtitle.start.inMilliseconds && 
          positionMs <= subtitle.end.inMilliseconds) {
        activeSubtitles.insert(0, subtitle);
      } else if (positionMs > subtitle.end.inMilliseconds) {
        break; // No more matches possible going backwards
      }
    }
    
    // Scan forwards from firstCandidate + 1
    for (int i = firstCandidate + 1; i < subtitles.length; i++) {
      final subtitle = subtitles[i];
      if (positionMs >= subtitle.start.inMilliseconds && 
          positionMs <= subtitle.end.inMilliseconds) {
        activeSubtitles.add(subtitle);
      } else if (positionMs < subtitle.start.inMilliseconds) {
        break; // No more matches possible going forward
      }
    }
    
    return activeSubtitles;
  }
  
  // Method to toggle mark status using the callback
  void _toggleMarkCurrentSubtitle(Subtitle subtitle) {
    debugPrint('_toggleMarkCurrentSubtitle: Toggling subtitle ${subtitle.index}');
    debugPrint('  - Current marked state: ${subtitle.marked}');
    debugPrint('  - Will change to: ${!subtitle.marked}');
    debugPrint('  - Callback exists: ${widget.onSubtitleMarked != null}');
    
    if (widget.onSubtitleMarked != null) {
      final newMarked = !subtitle.marked;
      debugPrint('  - Calling onSubtitleMarked callback with index ${subtitle.index} and marked=$newMarked');
      widget.onSubtitleMarked!(subtitle.index, newMarked);
    } else {
      debugPrint('  - WARNING: No onSubtitleMarked callback provided!');
    }
    
    // Show the controls to provide visual feedback
    _showControls();
  }

  // Public method to trigger comment dialog from external keyboard shortcuts
  void showCommentDialogForSubtitle(Subtitle subtitle, {
    String? originalText,
    String? editedText,
  }) {
    // Don't open a new dialog if one is already visible
    if (_isCommentDialogOpen) {
      return;
    }
    
    debugPrint('showCommentDialogForSubtitle: Triggering fullscreen comment dialog for subtitle ${subtitle.index}');
    _showCommentDialog(subtitle, originalText: originalText, editedText: editedText);
  }

  // Method to show comment dialog for marked subtitle
  void _showCommentDialog(Subtitle subtitle, {
    String? originalText,
    String? editedText,
  }) {
    debugPrint('_showCommentDialog: Opening comment dialog for subtitle ${subtitle.index} - "${subtitle.text.substring(0, subtitle.text.length.clamp(0, 30))}..."');
    _showControls(); // Keep controls visible during dialog
    
    // Use original context if available, otherwise use current context
    final dialogContext = widget.originalContext ?? context;
    
    // Since we're in _FullscreenControlsWidget, we're already in fullscreen mode
    // So we always need to use the fullscreen comment dialog with orientation handling
    _showFullscreenCommentDialog(subtitle, dialogContext, 
      originalText: originalText, editedText: editedText);
  }

  // Method to show comment dialog specifically for fullscreen mode using custom overlay
  void _showFullscreenCommentDialog(Subtitle subtitle, BuildContext dialogContext, {
    String? originalText,
    String? editedText,
  }) async {
    // Mark dialog as open
    setState(() => _isCommentDialogOpen = true);
    
    // Store the current playing state before showing dialog
    final wasPlaying = widget.player.state.playing;
    debugPrint('Fullscreen comment dialog opening - video was ${wasPlaying ? 'playing' : 'paused'}');
    debugPrint('Comment dialog subtitle data:');
    debugPrint('  - originalText: ${originalText ?? 'null'}');
    debugPrint('  - editedText: ${editedText ?? 'null'}');
    debugPrint('  - subtitle.text: ${subtitle.text}');
    
    // Pause video if it was playing when comment dialog opens
    if (wasPlaying) {
      widget.player.pause();
      debugPrint('Paused video for fullscreen comment input');
    }
    
    // Store current orientation preferences before changing to portrait for better comment input
    List<DeviceOrientation>? originalOrientations;
    
    // Check if we're in landscape (likely fullscreen)
    final orientation = MediaQuery.of(dialogContext).orientation;
    final isLandscape = orientation == Orientation.landscape;
    
    // If in landscape, store current orientations and switch to portrait
    if (isLandscape) {
      originalOrientations = [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
      
      debugPrint('Switching to portrait for comment dialog');
      // Force portrait orientation for better comment input experience
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // Give a small delay for orientation change to complete
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Create overlay entry for the bottom modal sheet to ensure it appears above fullscreen
    OverlayEntry? dialogOverlay;
    
    // Helper function to safely remove overlay and restore orientation
    void safeRemoveOverlay() async {
      try {
        dialogOverlay?.remove();
        dialogOverlay = null;
        debugPrint('Removed dialog overlay');
      } catch (e) {
        // Ignore removal errors (overlay might already be removed)
        debugPrint('Error removing dialog overlay: $e');
      }
      
      // Mark dialog as closed
      if (mounted) {
        setState(() => _isCommentDialogOpen = false);
      }
      
      // Resume video if it was playing before dialog opened
      if (wasPlaying) {
        widget.player.play();
        debugPrint('Resumed video after fullscreen comment dialog closed');
      }
      
      // Restore original orientation when dialog is dismissed
      if (originalOrientations != null) {
        try {
          // Add a small delay to ensure overlay removal completes first
          await Future.delayed(const Duration(milliseconds: 150));
          await SystemChrome.setPreferredOrientations(originalOrientations);
          debugPrint('Restored original orientation after comment dialog');
        } catch (e) {
          debugPrint('Error restoring orientation: $e');
        }
      }
    }
    
    dialogOverlay = OverlayEntry(
      builder: (overlayContext) => Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          // Handle escape key to close the comment dialog
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            debugPrint('Escape key pressed - dismissing fullscreen comment dialog');
            safeRemoveOverlay();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              // Dismiss dialog when tapping outside
              debugPrint('Dismissing comment dialog via background tap');
              safeRemoveOverlay();
            },
            child: Container(
              color: Colors.black54, // Semi-transparent background
              child: GestureDetector(
                onTap: () {}, // Prevent tap from propagating to parent
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(overlayContext).viewInsets.bottom + 20, // Add extra space above keyboard
                      left: 16,
                      right: 16,
                      top: MediaQuery.of(overlayContext).padding.top + 50, // Add top padding to prevent dialog from going offscreen
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 600, // Restore normal width constraint
                        maxHeight: MediaQuery.of(overlayContext).size.height * 0.8, // Limit height to 80% of screen
                      ),
                      child: CommentDialog(
                      existingComment: subtitle.comment,
                      isOverlayMode: true, // Indicate this is used in overlay mode
                      originalText: originalText ?? subtitle.text, // Use passed originalText or fallback to subtitle.text
                      editedText: editedText, // Use passed editedText if available
                      subtitleIndex: subtitle.index, // Pass subtitle index
                      onCommentSaved: (comment) async {
                        debugPrint('═══════════════════════════════════');
                        debugPrint('FULLSCREEN COMMENT SAVE CALLBACK TRACE:');
                        debugPrint('  ► Original subtitle passed to dialog:');
                        debugPrint('    - subtitle.index: ${subtitle.index}');
                        debugPrint('    - subtitle.text: "${subtitle.text.substring(0, subtitle.text.length.clamp(0, 50))}..."');
                        debugPrint('    - subtitle.marked: ${subtitle.marked}');
                        debugPrint('    - subtitle object hashCode: ${subtitle.hashCode}');
                        debugPrint('  ► Comment being saved: "$comment"');
                        debugPrint('  ► Callback status:');
                        debugPrint('    - onSubtitleCommentUpdated exists: ${widget.onSubtitleCommentUpdated != null}');
                        debugPrint('    - Widget mounted: $mounted');
                        debugPrint('  ► About to call parent callback...');
                        
                        // If the subtitle is not marked, mark it first
                        if (mounted && !subtitle.marked && widget.onSubtitleMarked != null) {
                          try {
                            debugPrint('  ► Marking subtitle before saving comment');
                            widget.onSubtitleMarked!(subtitle.index, true);
                            // Small delay to ensure mark operation completes
                            await Future.delayed(const Duration(milliseconds: 50));
                          } catch (e) {
                            debugPrint('  ► ERROR marking subtitle: $e');
                          }
                        }
                        
                        // Update subtitle comment immediately 
                        if (mounted && widget.onSubtitleCommentUpdated != null) {
                          try {
                            debugPrint('  ► CALLING PARENT CALLBACK:');
                            debugPrint('    - Index parameter: ${subtitle.index}');
                            debugPrint('    - Comment parameter: "$comment"');
                            
                            widget.onSubtitleCommentUpdated!(subtitle.index, comment);
                            
                            debugPrint('  ► Parent callback completed successfully');
                          } catch (e) {
                            debugPrint('  ► ERROR in parent callback: $e');
                          }
                        } else {
                          debugPrint('  ► CALLBACK NOT CALLED - mounted=$mounted, callback exists=${widget.onSubtitleCommentUpdated != null}');
                        }
                        debugPrint('═══════════════════════════════════');
                        
                        // Close the overlay with a slight delay to allow callback completion
                        Future.delayed(const Duration(milliseconds: 100), () {
                          debugPrint('Closing comment dialog overlay after save');
                          safeRemoveOverlay();
                        });
                      },
                      onCommentDeleted: () {
                        debugPrint('Comment delete initiated: subtitleIndex=${subtitle.index}');
                        
                        // Remove subtitle comment immediately
                        if (mounted && widget.onSubtitleCommentUpdated != null) {
                          try {
                            widget.onSubtitleCommentUpdated!(subtitle.index, null);
                            debugPrint('Fullscreen comment deleted successfully from database');
                          } catch (e) {
                            debugPrint('Error deleting subtitle comment: $e');
                          }
                        }
                        
                        // Close the overlay with a slight delay to allow callback completion
                        Future.delayed(const Duration(milliseconds: 100), () {
                          debugPrint('Closing comment dialog overlay after delete');
                          safeRemoveOverlay();
                        });
                      },
                      onCancelled: () {
                        debugPrint('Comment dialog cancelled by user');
                        safeRemoveOverlay();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
        )
    );
    
    // Insert the dialog overlay above the fullscreen overlay
    try {
      if (dialogOverlay != null) {
        Overlay.of(dialogContext, rootOverlay: true).insert(dialogOverlay!);
      }
    } catch (e) {
      debugPrint('Error inserting dialog overlay: $e');
      safeRemoveOverlay();
    }
  }

  /// Build audio track control button that cycles through tracks
  Widget _buildAudioTrackButton() {
    final hasMultipleTracks = widget.availableAudioTracks.length > 1;

    if (!hasMultipleTracks) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.audiotrack, color: Colors.grey, size: 16),
            SizedBox(width: 4),
            Text('1 track', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    // Get current track info for display
    final currentTrack = widget.player.state.track.audio;
    String displayText = 'Track ${currentTrack.id}';
    if (currentTrack.id == 'auto') {
      displayText = 'Auto';
    } else if (currentTrack.id == 'no') {
      displayText = 'Off';
    } else if (currentTrack.language?.isNotEmpty == true) {
      displayText = currentTrack.language!.toUpperCase();
    } else if (currentTrack.title?.isNotEmpty == true) {
      displayText = currentTrack.title!;
    }

    return GestureDetector(
      onTap: () {
        _cycleAudioTrack();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.audiotrack, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(displayText, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _cycleAudioTrack() {
    if (widget.availableAudioTracks.length <= 1) return;
    
    // Find current track index
    final currentTrack = widget.player.state.track.audio;
    int currentIndex = widget.availableAudioTracks.indexWhere((track) => track.id == currentTrack.id);
    
    // If not found, start from first track
    if (currentIndex == -1) {
      currentIndex = 0;
    } else {
      // Move to next track, cycling back to start if at end
      currentIndex = (currentIndex + 1) % widget.availableAudioTracks.length;
    }
    
    // Apply the new audio track
    final nextTrack = widget.availableAudioTracks[currentIndex];
    widget.onAudioTrackChange(nextTrack);
    _showControls();
  }

  /// Build volume control with vertical slider (similar to normal player controls)
  Widget _buildVolumeButton() {
    return _FullscreenVolumeSliderButton(
      player: widget.player,
      videoPlayerState: widget.videoPlayerState,
      onShowControls: _showControls,
    );
  }
}

// Repeat mode button for video controls
class _RepeatButton extends StatefulWidget {
  const _RepeatButton();

  @override
  _RepeatButtonState createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  bool _isLongPressing = false;
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    final videoPlayerState = context.findAncestorStateOfType<VideoPlayerWidgetState>();
    
    if (videoPlayerState == null) {
      return const SizedBox.shrink();
    }
    
    // Use StatefulBuilder to force rebuilds when state changes
    return StatefulBuilder(
      builder: (context, setButtonState) {
        final isRepeatEnabled = videoPlayerState.widget.isRepeatModeEnabled;
        
        return MouseRegion(
          onEnter: (_) => setButtonState(() => _isHovered = true),
          onExit: (_) => setButtonState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () {
              if (!_isLongPressing && videoPlayerState.widget.onRepeatModeToggled != null) {
                videoPlayerState.widget.onRepeatModeToggled!(!isRepeatEnabled);
                // Force immediate rebuild using StatefulBuilder
                setButtonState(() {});
              }
            },
            onDoubleTap: () {
              // Double tap shows repeat range dialog (same as long press)
              setButtonState(() {
                _isLongPressing = true;
              });
              _showRepeatRangeDialog(context, videoPlayerState);
              // Reset long press flag after a delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setButtonState(() {
                    _isLongPressing = false;
                  });
                }
              });
            },
            onLongPress: () {
              setButtonState(() {
                _isLongPressing = true;
              });
              _showRepeatRangeDialog(context, videoPlayerState);
              // Reset long press flag after a delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setButtonState(() {
                    _isLongPressing = false;
                  });
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32, // Increased size for better usability
              height: 32, // Increased size for better usability
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLongPressing 
                  ? Colors.orange.withOpacity(0.3) 
                  : _isHovered 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.repeat_one,
                size: 22, // Increased icon size
                color: isRepeatEnabled 
                  ? Colors.orange 
                  : _isHovered 
                    ? Colors.blue.shade200 
                    : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showRepeatRangeDialog(BuildContext context, VideoPlayerWidgetState videoPlayerState) {
    // Find the EditSubtitleScreen state to access subtitle data and methods
    final editScreenState = context.findAncestorStateOfType<EditSubtitleScreenState>();
    if (editScreenState == null) return;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => RepeatRangeDialog(
        editScreenState: editScreenState,
        videoPlayerState: videoPlayerState,
      ),
    );
  }
}

/// Dialog for setting custom repeat range
class RepeatRangeDialog extends StatefulWidget {
  final EditSubtitleScreenState editScreenState;
  final VideoPlayerWidgetState videoPlayerState;

  const RepeatRangeDialog({
    super.key,
    required this.editScreenState,
    required this.videoPlayerState,
  });

  @override
  RepeatRangeDialogState createState() => RepeatRangeDialogState();
}

class RepeatRangeDialogState extends State<RepeatRangeDialog> {
  int _startIndex = 0;
  int _endIndex = 0;
  late TextEditingController _startController;
  late TextEditingController _endController;
  
  @override
  void initState() {
    super.initState();
    // Set default values
    final subtitleCount = widget.editScreenState.subtitles.length;
    if (subtitleCount > 0) {
      _endIndex = subtitleCount - 1;
    }
    
    // Initialize controllers
    _startController = TextEditingController(text: '${_startIndex + 1}');
    _endController = TextEditingController(text: '${_endIndex + 1}');
  }
  
  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitleCount = widget.editScreenState.subtitles.length;
    
    if (subtitleCount == 0) {
      return AlertDialog(
        title: const Text('No Subtitles'),
        content: const Text('No subtitles available for custom range repeat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.repeat_one, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          const Text('Custom Repeat Range', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select subtitle range for repeat playback:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            // Start and End Index Text Fields
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Subtitle:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _startController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          final intValue = int.tryParse(value);
                          if (intValue != null && intValue >= 1 && intValue <= subtitleCount) {
                            setState(() {
                              _startIndex = intValue - 1;
                              // Ensure end index is not less than start index
                              if (_endIndex < _startIndex) {
                                _endIndex = _startIndex;
                                _endController.text = '${_endIndex + 1}';
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Subtitle:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _endController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          final intValue = int.tryParse(value);
                          if (intValue != null && intValue >= _startIndex + 1 && intValue <= subtitleCount) {
                            setState(() {
                              _endIndex = intValue - 1;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Preview info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Range: ${_endIndex - _startIndex + 1} subtitle(s)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.editScreenState.subtitles.isNotEmpty) ...[
                    Text(
                      'Start: ${_formatDuration(widget.editScreenState.subtitles[_startIndex].start)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'End: ${_formatDuration(widget.editScreenState.subtitles[_endIndex].end)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Switch to normal repeat mode (clear custom range)
            widget.editScreenState.clearCustomRepeatRange();
            
            // Enable normal repeat mode if not already enabled
            if (!widget.editScreenState.isRepeatModeEnabled) {
              widget.editScreenState.toggleRepeatMode();
            } else {
              // Just restart with normal mode
              widget.editScreenState.startRepeatPlayback();
            }
            
            Navigator.of(context).pop();
            
            // Show confirmation
            SnackbarHelper.showSuccess(context, 'Normal repeat mode enabled');
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
          child: const Text('Normal Repeat'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validate inputs
            final startValue = int.tryParse(_startController.text);
            final endValue = int.tryParse(_endController.text);
            
            if (startValue == null || endValue == null ||
                startValue < 1 || startValue > subtitleCount ||
                endValue < startValue || endValue > subtitleCount) {
              SnackbarHelper.showError(context, 'Please enter valid range (1-$subtitleCount)');
              return;
            }
            
            // Set custom range and enable repeat mode
            widget.editScreenState.setCustomRepeatRange(startValue - 1, endValue - 1);
            
            // Enable repeat mode if not already enabled
            if (!widget.editScreenState.isRepeatModeEnabled) {
              widget.editScreenState.toggleRepeatMode();
            } else {
              // Just restart with new range
              widget.editScreenState.startRepeatPlayback();
            }
            
            Navigator.of(context).pop();
            
            // Show confirmation
            SnackbarHelper.showSuccess(context, 'Custom repeat range set: $startValue to $endValue');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply Range'),
        ),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(milliseconds / 10).round().toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(milliseconds / 10).round().toString().padLeft(2, '0')}';
    }
  }
}

/// Custom video controls widget that matches MaterialVideoControls design
/// with proper mouse hover functionality
class CustomVideoControls extends StatefulWidget {
  final Player player;
  final List<Subtitle> subtitles;
  final List<Subtitle> secondarySubtitles;
  final Function(int, bool)? onSubtitleMarked;
  final Function(int, String?)? onSubtitleCommentUpdated;
  final Function(bool)? onPlayStateChanged;
  final Function(bool)? onRepeatModeToggled;
  final bool isRepeatModeEnabled;
  final int skipDurationSeconds;

  const CustomVideoControls({
    super.key,
    required this.player,
    required this.subtitles,
    required this.secondarySubtitles,
    this.onSubtitleMarked,
    this.onSubtitleCommentUpdated,
    this.onPlayStateChanged,
    this.onRepeatModeToggled,
    this.isRepeatModeEnabled = false,
    required this.skipDurationSeconds,
  });

  @override
  CustomVideoControlsState createState() => CustomVideoControlsState();
}

class CustomVideoControlsState extends State<CustomVideoControls> {
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _isHovering = false;
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (!_isHovering && !_isSeeking) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isHovering && !_isSeeking) {
          // Check if any volume slider is currently in use
          if (!_VolumeSliderButtonState._isAnyVolumeSliderInUse) {
            setState(() {
              _controlsVisible = false;
            });
          } else {
            // If volume slider is in use, restart the timer
            _resetHideTimer();
          }
        }
      });
    }
  }

  void _showControls() {
    if (mounted) {
      setState(() {
        _controlsVisible = true;
      });
      _resetHideTimer();
    }
  }

  void _onHoverStart() {
    _isHovering = true;
    _showControls();
  }

  void _onHoverEnd() {
    _isHovering = false;
    _resetHideTimer();
  }

  void _onSeekStart() {
    _isSeeking = true;
    _showControls();
  }

  void _onSeekEnd() {
    _isSeeking = false;
    _resetHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      onExit: (_) => _onHoverEnd(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint('CustomVideoControls: Single tap detected');
          if (_controlsVisible) {
            setState(() {
              _controlsVisible = false;
            });
          } else {
            _showControls();
          }
        },
        onDoubleTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
          
          debugPrint('CustomVideoControls: Double tap at position ${tapPosition}, screen width: ${screenWidth}');
          debugPrint('CustomVideoControls: Skip duration: ${widget.skipDurationSeconds} seconds');
          
          // Left third of screen - skip backward
          if (tapPosition < screenWidth / 3) {
            debugPrint('CustomVideoControls: Skip backward by ${widget.skipDurationSeconds} seconds');
            final currentPosition = widget.player.state.position;
            final newPosition = currentPosition - Duration(seconds: widget.skipDurationSeconds);
            debugPrint('CustomVideoControls: Current position: ${currentPosition.inSeconds}s, new position: ${newPosition.inSeconds}s');
            widget.player.seek(newPosition.isNegative ? Duration.zero : newPosition);
            _showControls();
          } 
          // Right third of screen - skip forward
          else if (tapPosition > (2 * screenWidth / 3)) {
            debugPrint('CustomVideoControls: Skip forward by ${widget.skipDurationSeconds} seconds');
            final currentPosition = widget.player.state.position;
            final duration = widget.player.state.duration;
            final newPosition = currentPosition + Duration(seconds: widget.skipDurationSeconds);
            debugPrint('CustomVideoControls: Current position: ${currentPosition.inSeconds}s, new position: ${newPosition.inSeconds}s');
            widget.player.seek(newPosition > duration ? duration : newPosition);
            _showControls();
          }
          // Middle third - do nothing (let center controls handle play/pause)
          else {
            debugPrint('CustomVideoControls: Double tap in center area - ignoring');
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          child: Stack(
            children: [
              // Always present invisible touch area for gestures
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              // Controls that appear/disappear
              AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _controlsVisible ? _buildControls() : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Stack(
      children: [
        // Top controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Spacer(),
                _SettingsButton(),
                const SizedBox(width: 8),
                _FullscreenButton(),
              ],
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Control buttons - positioned on top with reduced spacing
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 1.0), // Reduced top padding from 8 to 4, bottom from 2 to 1
                  child: Row(
                    children: [
                      _TimeDisplay(),
                      const Spacer(),
                      if (widget.onRepeatModeToggled != null) _RepeatButton(),
                      if (widget.onRepeatModeToggled != null) const SizedBox(width: 8),
                      _VolumeSliderButton(),
                      const SizedBox(width: 8),
                      _SubtitleToggleButton(),
                    ],
                  ),
                ),
                // Progress bar - positioned at the bottom with reduced spacing
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 4.0), // Reduced bottom margin from 8 to 4 for tighter layout
                  child: _buildProgressBar(),
                ),
              ],
            ),
          ),
        ),

        // Play/Pause and skip buttons in center
        Center(
          child: StreamBuilder<bool>(
            stream: widget.player.stream.playing,
            initialData: widget.player.state.playing,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? widget.player.state.playing;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Backward button
                  _CenterControlButton(
                    icon: Icons.fast_rewind,
                    size: 40.0,
                    onTap: () {
                      final currentPosition = widget.player.state.position;
                      final newPosition = currentPosition - Duration(seconds: widget.skipDurationSeconds);
                      widget.player.seek(newPosition.isNegative ? Duration.zero : newPosition);
                    },
                    onHoldSkip: () {
                      final currentPosition = widget.player.state.position;
                      final newPosition = currentPosition - const Duration(milliseconds: 500);
                      widget.player.seek(newPosition.isNegative ? Duration.zero : newPosition);
                    },
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Play/Pause button (without background)
                  _CenterControlButton(
                    icon: isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 56.0,
                    extraShadows: true,
                    onTap: () {
                      if (isPlaying) {
                        widget.player.pause();
                      } else {
                        widget.player.play();
                      }
                      widget.onPlayStateChanged?.call(!isPlaying);
                    },
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Forward button
                  _CenterControlButton(
                    icon: Icons.fast_forward,
                    size: 40.0,
                    onTap: () {
                      final currentPosition = widget.player.state.position;
                      final duration = widget.player.state.duration;
                      final newPosition = currentPosition + Duration(seconds: widget.skipDurationSeconds);
                      widget.player.seek(newPosition > duration ? duration : newPosition);
                    },
                    onHoldSkip: () {
                      final currentPosition = widget.player.state.position;
                      final duration = widget.player.state.duration;
                      final newPosition = currentPosition + const Duration(milliseconds: 500);
                      widget.player.seek(newPosition > duration ? duration : newPosition);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          builder: (context, durationSnapshot) {
            // Use fallback to player state if stream data is invalid
            final position = (positionSnapshot.data?.inMilliseconds ?? 0) > 0 
                ? positionSnapshot.data!
                : widget.player.state.position;
            final duration = (durationSnapshot.data?.inMilliseconds ?? 0) > 0 
                ? durationSnapshot.data!
                : widget.player.state.duration;
            
            // REMOVED: Excessive debug logging that fires on every video frame (~60fps)
            // This causes severe performance degradation and log spam
            // Re-enable only for specific debugging sessions with throttling
            
            final progress = duration.inMilliseconds > 0 
                ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;

            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
                thumbColor: Colors.blue,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                trackHeight: 4.0,
              ),
              child: Slider(
                value: progress,
                onChanged: (value) {
                  _onSeekStart();
                  
                  // Ensure we have valid duration before seeking
                  if (duration.inMilliseconds > 0 && value >= 0.0 && value <= 1.0) {
                    final newPositionMs = (value * duration.inMilliseconds).round();
                    final newPosition = Duration(milliseconds: newPositionMs);
                    
                    if (kDebugMode) {
                      debugPrint('Seekbar - Seeking to: ${newPosition.inMilliseconds}ms (value: $value, duration: ${duration.inMilliseconds}ms)');
                    }
                    
                    widget.player.seek(newPosition);
                  } else {
                    if (kDebugMode) {
                      debugPrint('Seekbar - Invalid seek: value=$value, duration=${duration.inMilliseconds}ms');
                    }
                  }
                  _showControls();
                },
                onChangeEnd: (value) {
                  _onSeekEnd();
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Widget _TimeDisplay() {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      builder: (context, positionSnapshot) {
        // Get current position, fallback to state.position if stream data is null or zero
        final position = (positionSnapshot.data?.inMilliseconds ?? 0) > 0 
            ? positionSnapshot.data!
            : widget.player.state.position;
        
        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          builder: (context, durationSnapshot) {
            // Use player.state.duration if stream value is zero or null
            final duration = (durationSnapshot.data?.inMilliseconds ?? 0) > 0 
                ? durationSnapshot.data! 
                : widget.player.state.duration;
            
            // Format the time strings
            final positionStr = _formatDuration(position);
            final durationStr = _formatDuration(duration);
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0), // Reduced padding for low-res displays
              child: Text(
                '$positionStr / $durationStr',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Custom center control button with hover effects and hold functionality
class _CenterControlButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final VoidCallback? onHoldSkip; // Callback for 1-second skips while holding
  final bool extraShadows;

  const _CenterControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.onHoldSkip,
    this.extraShadows = false,
  });

  @override
  _CenterControlButtonState createState() => _CenterControlButtonState();
}

class _CenterControlButtonState extends State<_CenterControlButton> {
  bool _isHovered = false;
  Timer? _holdTimer;

  void _startHolding() {
    if (widget.onHoldSkip != null) {
      // Immediately skip once, then continue with fast periodic skips
      widget.onHoldSkip!();
      _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        widget.onHoldSkip!();
      });
    }
  }

  void _stopHolding() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _stopHolding();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPressStart: (_) => _startHolding(),
        onLongPressEnd: (_) => _stopHolding(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            color: _isHovered ? Colors.blue.shade200 : Colors.white,
            size: widget.size,
            shadows: widget.extraShadows ? [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4.0,
                offset: const Offset(0, 1),
              ),
            ] : [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom fullscreen skip button with hold functionality
class _FullscreenSkipButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onPressed;
  final VoidCallback onHoldSkip;

  const _FullscreenSkipButton({
    required this.icon,
    required this.size,
    required this.onPressed,
    required this.onHoldSkip,
  });

  @override
  _FullscreenSkipButtonState createState() => _FullscreenSkipButtonState();
}

class _FullscreenSkipButtonState extends State<_FullscreenSkipButton> {
  Timer? _holdTimer;

  void _startHolding() {
    // Immediately skip once, then continue with fast periodic skips
    widget.onHoldSkip();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      widget.onHoldSkip();
    });
  }

  void _stopHolding() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _stopHolding();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onLongPressStart: (_) => _startHolding(),
      onLongPressEnd: (_) => _stopHolding(),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: widget.size,
        ),
      ),
    );
  }
}
