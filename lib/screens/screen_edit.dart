import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:subtitle_studio/utils/srt_compiler.dart';
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'package:subtitle_studio/operations/subtitle_sync_operations.dart';
import 'package:subtitle_studio/utils/subtitle_parser.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/subtitle_processor.dart';
import 'package:subtitle_studio/widgets/custom_text_render.dart';
import 'package:subtitle_studio/widgets/goto_line_sheet.dart';
import 'package:subtitle_studio/widgets/video_player_widget.dart';
import 'package:subtitle_studio/screens/edit/widgets/video_player_section.dart';
import 'package:subtitle_studio/screens/screen_help.dart';
import 'package:subtitle_studio/utils/responsive_layout.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/themes/theme_provider.dart';
import 'package:subtitle_studio/themes/theme_switcher_button.dart';
import 'package:subtitle_studio/utils/project_manager.dart';
import 'package:subtitle_studio/widgets/export_file_widget.dart';
import 'package:subtitle_studio/widgets/project_settings_sheet.dart';
import 'package:subtitle_studio/screens/edit_line/edit_line_bloc.dart'; // EditSubtitleScreenBloc wrapper
import 'package:subtitle_studio/utils/time_parser.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:subtitle_studio/widgets/bottom_modal_sheet.dart';
import 'package:subtitle_studio/operations/subtitle_operations.dart';
import 'package:subtitle_studio/widgets/search_replace_sheet.dart';
import 'package:subtitle_studio/widgets/isolated_loader.dart';
import 'package:subtitle_studio/widgets/secondary_subtitle_sheet.dart';
import 'package:subtitle_studio/widgets/settings_sheet.dart';
import 'package:subtitle_studio/widgets/banner_configuration_sheet.dart';
import 'package:subtitle_studio/widgets/subtitle_sync_sheet.dart';
import 'package:subtitle_studio/widgets/malayalam_normalization_sheet.dart';
import 'package:subtitle_studio/widgets/first_time_instructions.dart';
import 'package:subtitle_studio/widgets/scrolling_title_widget.dart';
import 'package:subtitle_studio/widgets/marked_lines_sheet.dart';
import 'package:subtitle_studio/widgets/checkpoint_sheet.dart';
import 'package:subtitle_studio/services/checkpoint_manager.dart';
import 'package:subtitle_studio/widgets/subtitle_effects_sheet.dart';
import 'package:subtitle_studio/widgets/comment_dialog.dart';
import 'package:subtitle_studio/widgets/import_comments_sheet.dart';
import 'package:subtitle_studio/operations/subtitle_effect_operations.dart';
import 'package:subtitle_studio/utils/macos_bookmark_manager.dart';
import 'package:subtitle_studio/utils/msone_hotkey_manager.dart' as hotkey;
import 'package:subtitle_studio/utils/unicode_text_input_formatter.dart';
import 'package:subtitle_studio/main.dart';
import 'msone_submission_screen.dart';
import 'package:subtitle_studio/screens/edit/edit_cubit.dart';
import 'package:subtitle_studio/screens/edit/edit_state.dart';
import 'package:subtitle_studio/features/waveform/bloc/waveform_bloc.dart';
import 'package:subtitle_studio/features/waveform/bloc/waveform_event.dart';
import 'package:subtitle_studio/features/waveform/bloc/waveform_state.dart';
import 'package:subtitle_studio/features/waveform/widgets/waveform_widget.dart';

class EditScreen extends StatefulWidget {
  final int subtitleCollectionId;
  final int? lastEditedIndex;
  final int sessionId;

  const EditScreen({
    super.key,
    required this.subtitleCollectionId,
    this.lastEditedIndex,
    required this.sessionId,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class SubtitleController extends GetxController {
  var subtitleLines = <SubtitleLine>[].obs;

  void updateSubtitleLine(int index, SubtitleLine newLine) {
    subtitleLines[index] = newLine;
  }

  void setSubtitleLines(List<SubtitleLine> lines) {
    subtitleLines.value = lines;
  }
}

/// Represents a single subtitle entry with all its components for source view
class SubtitleEntry {
  String index;
  String startTime;
  String endTime;
  String text;

  SubtitleEntry({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  /// Convert to SRT format string
  String toSrtString() {
    return '$index\n$startTime --> $endTime\n$text\n';
  }

  /// Parse a single SRT entry from text
  static SubtitleEntry? fromSrtText(String srtText) {
    final lines = srtText.trim().split('\n');
    if (lines.length < 3) return null;

    final index = lines[0].trim();
    final timecode = lines[1].trim();
    final text = lines.skip(2).join('\n').trim();

    // Parse timecode
    final timeParts = timecode.split(' --> ');
    if (timeParts.length != 2) return null;

    return SubtitleEntry(
      index: index,
      startTime: timeParts[0].trim(),
      endTime: timeParts[1].trim(),
      text: text,
    );
  }

  /// Create from SubtitleLine
  static SubtitleEntry fromSubtitleLine(SubtitleLine line, int index) {
    return SubtitleEntry(
      index: (index + 1).toString(),
      startTime: line.startTime,
      endTime: line.endTime,
      text: line.edited ?? line.original,
    );
  }
}

class _EditScreenState extends State<EditScreen> with TickerProviderStateMixin {
  // BLoC integration helper - provides access to EditCubit
  EditCubit get _cubit => context.read<EditCubit>();
  
  final Set<int> _selectedIndices = {};
  bool _isSelectionMode = false;
  final SubtitleController subtitleController = Get.put(SubtitleController());
  SubtitleCollection? subtitleCollection; // Make nullable to avoid late initialization error
  List<SubtitleLine> subtitleLines = []; // Initialize with empty list
  late String fileName;
  late Future<List<SubtitleLine>> subtitleLinesFuture;
  String? _selectedVideoPath;
  bool _isVideoVisible = false;
  bool _isVideoLoaded = false;  List<Subtitle> _subtitles = [];
  List<Subtitle> _secondarySubtitles = []; // To store secondary subtitles for video player
  List<SimpleSubtitleLine> _originalSecondarySubtitles = []; // Store original format for passing to EditSubtitleScreen
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final ScrollController _scrollbarController = ScrollController(); // For custom scrollbar
  double _scrollbarThumbOffset = 0.0;
  bool _isDraggingScrollbar = false;
  int? _highlightedIndex;  final GlobalKey<VideoPlayerWidgetState> _videoPlayerKey = GlobalKey();
  final GlobalKey _waveformKey = GlobalKey(); // Add waveform key
  final bool _isLoading = false;
  Duration _lastVideoPosition = Duration.zero; // Add this to store video position
  late TextEditingController _goToController;  bool _showSecondarySubtitles = true; // Add this field
  bool _isRangeSelectionActive = false;
  int? _rangeStartIndex;
  bool _floatingControlsEnabled = false; // Track floating controls state
  bool _isMsoneEnabled = false; // Track MSone features status
  double _resizeRatio = 0.35; // Track the resize ratio for desktop layout
  Timer? _resizeRatioSaveTimer; // Timer for debouncing resize ratio saves
  bool _isResizeRatioLoaded = false; // Track if resize ratio has been loaded from preferences
  bool _isCommentDialogOpen = false; // Track if comment dialog is currently visible
  
  // Mobile video resize support
  double _mobileVideoResizeRatio = 0.4; // Track the mobile video resize ratio
  Timer? _mobileResizeRatioSaveTimer; // Timer for debouncing mobile resize ratio saves
  
  // Subtitle change debouncer - reduces rebuilds during video playback
  Timer? _subtitleChangeDebouncer;
  bool _isMobileResizeRatioLoaded = false; // Track if mobile resize ratio has been loaded from preferences
  
  // Subtitle version tracking - increment to trigger VideoPlayerSection rebuild
  int _subtitleVersion = 0;
  
  // Store callbacks as late final members to prevent recreation and rebuilds
  late final Function(int) _onActiveSubtitleChangedStable;
  late final Function() _onSubtitlesUpdatedStable;
  late final Function() _onFullscreenExitedStable;
  late final Function(int, bool) _onSubtitleMarkedStable;
  late final Function(int, String?) _onSubtitleCommentUpdatedStable;

  // Navigation debouncing
  Timer? _navigationDebounceTimer;
  bool _isNavigating = false;

  // Source view support
  bool _isSourceView = false; // Track if we're in source view mode
  List<SubtitleEntry> _sourceViewEntries = []; // Store subtitle entries for source view
  final ScrollController _sourceScrollController = ScrollController(); // Separate scroll controller for source view

  // Layout switching support
  bool _isLayout1 = true; // Track layout preference (layout1 = default, layout2 = swapped)
  
  // Waveform support
  bool _isWaveformVisible = false; // Track if waveform is visible
  late WaveformBloc _waveformBloc; // Waveform BLoC instance
  
  // Hotkey registration guard - prevent repeated registration in didChangeDependencies
  bool _hotkeysRegistered = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize waveform BLoC
    _waveformBloc = WaveformBloc();
    
    // Initialize stable callbacks once to prevent rebuild cascades
    _onActiveSubtitleChangedStable = (arrayIndex) {
      if (arrayIndex >= 0 && arrayIndex < subtitleLines.length) {
        _onSubtitleChange(arrayIndex);
      }
    };
    
    _onSubtitlesUpdatedStable = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshSubtitleLines();
        }
      });
    };
    
    _onFullscreenExitedStable = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshSubtitleLines();
        }
      });
    };
    
    _onSubtitleMarkedStable = (subtitleIndex, isMarked) async {
      await _handleVideoPlayerMarkToggle(subtitleIndex, isMarked);
    };
    
    _onSubtitleCommentUpdatedStable = (subtitleIndex, comment) async {
      try {
        await updateSubtitleLineComment(widget.subtitleCollectionId, subtitleIndex, comment);
        if (subtitleIndex < subtitleLines.length) {
          setState(() {
            subtitleLines[subtitleIndex].comment = comment;
          });
          subtitleController.updateSubtitleLine(subtitleIndex, subtitleLines[subtitleIndex]);
          _updateSubtitlesWithVersion(subtitleLines);
          if (_videoPlayerKey.currentState != null) {
            _videoPlayerKey.currentState!.updateSubtitles(_subtitles);
          }
        }
        if (mounted && context.mounted) {
          SnackbarHelper.showSuccess(context, 
            comment != null ? 'Comment updated' : 'Comment deleted');
        }
      } catch (e) {
        if (mounted && context.mounted) {
          SnackbarHelper.showError(context, 'Failed to update comment: $e');
        } else {
          debugPrint('Failed to update comment (context unavailable): $e');
        }
      }
    };
    
    _goToController = TextEditingController();
    
    // Listen to scroll position changes to update custom scrollbar
    _itemPositionsListener.itemPositions.addListener(_updateScrollbarPosition);
    
    updateLastEditedSession(widget.sessionId);
    _loadFloatingControlsPreference();
    _loadMsonePreference();
    _loadLayoutPreference(); // Load layout preference
    _loadResizeRatio(); // Load saved resize ratio
    _loadMobileResizeRatio(); // Load saved mobile resize ratio
    _registerHotkeyShortcuts(); // Register hotkey shortcuts
    
    // Create initial checkpoint snapshot for this session
    _createInitialCheckpoint();
    
    subtitleLinesFuture = _fetchSubtitleLines().then((subtitles) async {
      subtitleController.setSubtitleLines(subtitles);
      subtitleCollection = (await fetchSubtitle(widget.subtitleCollectionId))!;
      
  await _loadSavedVideoPath();
  // Attempt to restore previously loaded secondary subtitles using the freshly fetched subtitles
  await _loadSavedSecondarySubtitle(subtitles);
      
      // Ensure video player gets subtitles after initialization
      _ensureVideoPlayerSubtitles();
      
      if (widget.lastEditedIndex != null && widget.lastEditedIndex! > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          
          await _scrollToIndexWithLoading(widget.lastEditedIndex!);
          
          // Initialize waveform playback position to last edited line
          if (mounted && widget.lastEditedIndex! < subtitles.length) {
            final startTime = parseTimeString(subtitles[widget.lastEditedIndex!].startTime);
            setState(() {
              _lastVideoPosition = startTime;
            });
            // Update waveform bloc with the position
            _waveformBloc.add(UpdatePlaybackPosition(startTime));
          }
          
          // Wait for video player to be ready
          if (mounted && _videoPlayerKey.currentState != null) {
            await Future.delayed(Duration(milliseconds: 500));
            if (mounted) {
              _seekToSubtitle(widget.lastEditedIndex!);
            }
          }
        });
      }
      return subtitles;
    });

    // Check if tutorial should be shown
    _checkTutorial();
  }
  
  /// Creates initial checkpoint snapshot for accurate restoration
  Future<void> _createInitialCheckpoint() async {
    try {
      await CheckpointManager.createInitialSnapshot(
        sessionId: widget.sessionId,
        subtitleCollectionId: widget.subtitleCollectionId,
      );
      if (kDebugMode) {
        print('Initial checkpoint snapshot created for session ${widget.sessionId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create initial checkpoint snapshot: $e');
      }
    }
  }

  // Ensure video player gets subtitles after widget initialization
  void _ensureVideoPlayerSubtitles() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Try to update video player subtitles once the widget tree is built
      _updateVideoPlayerSubtitles();
      
      // Set up a periodic check to ensure subtitles are loaded if video player takes time to initialize
      int attempts = 0;
      const maxAttempts = 10;
      const interval = Duration(milliseconds: 500);
      
      void checkAndUpdate() {
        if (attempts >= maxAttempts) return;
        
        if (_videoPlayerKey.currentState != null && 
            _videoPlayerKey.currentState!.isInitialized() &&
            _subtitles.isNotEmpty) {
          _updateVideoPlayerSubtitles();
        } else {
          attempts++;
          Future.delayed(interval, checkAndUpdate);
        }
      }
      
      checkAndUpdate();
    });
  }

  // Helper method to update video player subtitles
  void _updateVideoPlayerSubtitles() {
    if (_videoPlayerKey.currentState != null && _subtitles.isNotEmpty) {
      _videoPlayerKey.currentState!.updateSubtitles(_subtitles);
      
      // Also update secondary subtitles if they exist
      if (_secondarySubtitles.isNotEmpty && _showSecondarySubtitles) {
        _videoPlayerKey.currentState!.updateSecondarySubtitles(_secondarySubtitles);
      }
    }
    
    // Update waveform with subtitle lines
    if (_waveformKey.currentState != null && subtitleLines.isNotEmpty) {
      (_waveformKey.currentState as dynamic).updateSubtitles(subtitleLines);
    }
  }
  
  // Helper method to update both video and waveform when subtitles change
  void _updateAllSubtitleDisplays() {
    // Regenerate subtitles for video player if needed
    if (subtitleLines.isNotEmpty) {
      _subtitles = _generateSubtitles(subtitleLines);
    }
    
    // Update video player
    if (_videoPlayerKey.currentState != null) {
      _videoPlayerKey.currentState!.updateSubtitles(_subtitles);
    }
    
    // Update waveform
    if (_waveformKey.currentState != null) {
      (_waveformKey.currentState as dynamic).updateSubtitles(subtitleLines);
    }
  }

  // Load floating controls preference
  Future<void> _loadFloatingControlsPreference() async {
    // Migrated to BLoC - floating controls already loaded by cubit.initialize()
    // Just sync local state from cubit state
    final state = _cubit.state;
    if (!mounted) return;
    
    setState(() {
      _floatingControlsEnabled = state.floatingControlsEnabled;
    });
  }

  // Load MSone features preference
  Future<void> _loadMsonePreference() async {
    // Migrated to BLoC - MSone preference already loaded by cubit.initialize()
    // Just sync local state from cubit state
    final state = _cubit.state;
    if (!mounted) return;
    
    setState(() {
      _isMsoneEnabled = state.isMsoneEnabled;
    });
  }

  // Load layout preference
  Future<void> _loadLayoutPreference() async {
    // Migrated to BLoC - layout preference already loaded by cubit.initialize()
    // Just sync local state from cubit state
    final state = _cubit.state;
    if (!mounted) return;
    
    if (kDebugMode) {
      print('DEBUG: Layout preference loaded from cubit: ${state.isLayout1 ? 'layout1' : 'layout2'}');
    }
    
    setState(() {
      _isLayout1 = state.isLayout1;
    });
  }

  // Build subtitle list interface
  Widget _buildSubtitleListInterface(List<SubtitleLine> subtitleLines) {
    return Column(
      children: [
        // Title bar for subtitle list
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.subtitles,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Subtitle Lines',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${subtitleLines.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Subtitle list
        Expanded(
          child: Obx(() {
            return Stack(
              children: [
                ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    bottom: 16, 
                    top: 8,
                    left: 8,
                    right: 8,
                  ),
                  itemCount: subtitleController.subtitleLines.length,
                  itemBuilder: (context, index) {
                    final line = subtitleController.subtitleLines[index];
                    final textContent = line.edited ?? line.original;
                    return _buildSubtitleCard(line, index, textContent);
                  },
                ),
                _buildCustomScrollbar(),
              ],
            );
          }),
        ),
      ],
    );
  }

  // Build video player interface
  Widget _buildVideoPlayerInterface(List<SubtitleLine> subtitleLines) {
    return Column(
      children: [
        if (_isVideoVisible && _selectedVideoPath != null) ...[
          // Video player takes most of the available space
          Expanded(
            child: Column(
              children: [
                // Video player - takes all available space, waveform is added below
                if (!_isWaveformVisible)
                  Expanded(
                    child: VideoPlayerSection(
                      videoPlayerKey: _videoPlayerKey,
                      videoPath: _selectedVideoPath!,
                      subtitleCollectionId: widget.subtitleCollectionId,
                      subtitles: _subtitles,
                      secondarySubtitles: _secondarySubtitles,
                      subtitleVersion: _subtitleVersion,
                      onPositionChanged: _onVideoPositionChanged,
                      onActiveSubtitleChanged: _onActiveSubtitleChangedStable,
                      onSubtitlesUpdated: _onSubtitlesUpdatedStable,
                      onFullscreenExited: _onFullscreenExitedStable,
                      onSubtitleMarked: _onSubtitleMarkedStable,
                      onSubtitleCommentUpdated: _onSubtitleCommentUpdatedStable,
                    ),
                  )
                else
                  // When waveform is visible, use LayoutBuilder to get available space
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate video player height (available space minus waveform height)
                        // Use taller waveform on desktop for better visibility
                        final waveformHeight = Platform.isWindows || Platform.isMacOS || Platform.isLinux 
                            ? 240.0 
                            : 180.0;
                        final videoHeight = constraints.maxHeight - waveformHeight - 1; // -1 for divider
                        
                        return Column(
                          children: [
                            // Video player with calculated height
                            SizedBox(
                              height: videoHeight > 0 ? videoHeight : constraints.maxHeight * 0.7,
                              child: VideoPlayerSection(
                                videoPlayerKey: _videoPlayerKey,
                                videoPath: _selectedVideoPath!,
                                subtitleCollectionId: widget.subtitleCollectionId,
                                subtitles: _subtitles,
                                secondarySubtitles: _secondarySubtitles,
                                subtitleVersion: _subtitleVersion,
                                onPositionChanged: _onVideoPositionChanged,
                                onActiveSubtitleChanged: _onActiveSubtitleChangedStable,
                                onSubtitlesUpdated: _onSubtitlesUpdatedStable,
                                onFullscreenExited: _onFullscreenExitedStable,
                                onSubtitleMarked: _onSubtitleMarkedStable,
                                onSubtitleCommentUpdated: _onSubtitleCommentUpdatedStable,
                              ),
                            ),
                            // Waveform section with fixed height
                            const Divider(height: 1),
                            SizedBox(
                              height: waveformHeight,
                              child: BlocProvider<WaveformBloc>.value(
                                value: _waveformBloc,
                                child: WaveformWidget(
                                  key: _waveformKey,
                                  subtitles: subtitleLines,
                                  playbackPosition: _lastVideoPosition,
                                  subtitleCollectionId: widget.subtitleCollectionId,
                                  sessionId: widget.sessionId,
                                  highlightedSubtitleIndex: _highlightedIndex,
                                  onSeek: (Duration position) {
                                    // Seek video to the selected position
                                    if (_videoPlayerKey.currentState != null) {
                                      _videoPlayerKey.currentState!.seekTo(position);
                                    }
                                  },
                                  onSubtitleHighlight: (int index) {
                                    // Scroll to and highlight the subtitle in the list
                                    _scrollToIndexWithLoading(index);
                                    setState(() {
                                      _highlightedIndex = index;
                                    });
                                  },
                                  onSubtitlesUpdated: () async {
                                    // Refresh subtitle lines from database
                                    await _refreshSubtitleLines();
                                  },
                                  onAddLineConfirmed: (Duration startTime, Duration endTime) {
                                    // Open add line sheet with selected times
                                    _openAddLineSheetWithTimes(startTime, endTime);
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ] else ...[
          // Placeholder when no video is loaded
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.movie_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No video loaded',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickVideoFile,
                    icon: const Icon(Icons.video_file),
                    label: const Text('Load Video'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // // Build editing interface without video (for layout2)
  // Widget _buildEditingInterfaceWithoutVideo(List<SubtitleLine> subtitleLines) {
  //   return Column(
  //     children: [
  //       // Title bar for editing interface
  //       Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: Theme.of(context).colorScheme.surfaceContainer,
  //           border: Border(
  //             bottom: BorderSide(
  //               color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
  //             ),
  //           ),
  //         ),
  //         child: Row(
  //           children: [
  //             Icon(
  //               Icons.edit,
  //               size: 20,
  //               color: Theme.of(context).colorScheme.primary,
  //             ),
  //             const SizedBox(width: 8),
  //             Text(
  //               'Editing Interface',
  //               style: Theme.of(context).textTheme.titleSmall?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       // Placeholder for editing interface - this would be your custom editing interface
  //       Expanded(
  //         child: Center(
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Icon(
  //                 Icons.edit_note,
  //                 size: 80,
  //                 color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
  //               ),
  //               const SizedBox(height: 16),
  //               Text(
  //                 'Editing Interface',
  //                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
  //                   color: Theme.of(context).colorScheme.outline,
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               Text(
  //                 'This is where your custom editing interface would go',
  //                 textAlign: TextAlign.center,
  //                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                   color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Load resize ratio preference
  Future<void> _loadResizeRatio() async {
    // Migrated to BLoC - resize ratio already loaded by cubit.initialize()
    // Just sync local state from cubit state
    final state = _cubit.state;
    if (!mounted) return;
    
    if (kDebugMode) {
      print('DEBUG: EditScreen - Loading resize ratio from cubit: ${state.resizeRatio}');
    }
    
    setState(() {
      _resizeRatio = state.resizeRatio;
      _isResizeRatioLoaded = true;
    });
    
    if (kDebugMode) {
      print('DEBUG: EditScreen - Updated _resizeRatio to: $_resizeRatio, loaded: $_isResizeRatioLoaded');
    }
  }

  // Save resize ratio preference with debouncing
  Future<void> _saveResizeRatio(double ratio) async {
    if (mounted) {
      setState(() {
        _resizeRatio = ratio;
      });
    }
    
    // Cancel any existing timer
    _resizeRatioSaveTimer?.cancel();
    
    // Start a new timer to save after a short delay
    _resizeRatioSaveTimer = Timer(const Duration(milliseconds: 300), () async {
      // Migrated to BLoC - delegate to cubit
      if (mounted) {
        await _cubit.updateResizeRatio(ratio);
      }
    });
  }

  /// Load mobile video resize ratio from preferences
  Future<void> _loadMobileResizeRatio() async {
    // Migrated to BLoC - mobile resize ratio already loaded by cubit.initialize()
    // Just sync local state from cubit state
    final state = _cubit.state;
    if (!mounted) return;
    
    setState(() {
      _mobileVideoResizeRatio = state.mobileVideoResizeRatio;
      _isMobileResizeRatioLoaded = true;
    });
  }

  /// Save mobile video resize ratio with debouncing
  void _saveMobileResizeRatio(double ratio) {
    if (mounted) {
      setState(() {
        _mobileVideoResizeRatio = ratio;
      });
    }
    
    // Cancel any existing timer
    _mobileResizeRatioSaveTimer?.cancel();
    
    // Set up a new timer with 500ms delay
    _mobileResizeRatioSaveTimer = Timer(Duration(milliseconds: 500), () async {
      // Migrated to BLoC - delegate to cubit
      if (mounted) {
        await _cubit.updateMobileResizeRatio(ratio);
      }
    });
  }

  // Toggle floating controls
  void _toggleFloatingControls(bool value) {
    // Migrated to BLoC - delegate to cubit
    _cubit.updateFloatingControls(value);
    
    // Update local state from cubit
    if (mounted) {
      final state = _cubit.state;
      setState(() {
        _floatingControlsEnabled = state.floatingControlsEnabled;
      });
    }
  }

  /// Toggle waveform visibility
  void _toggleWaveform() async {
    if (!_isVideoLoaded || _selectedVideoPath == null) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Please load a video first');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isWaveformVisible = !_isWaveformVisible;
      });
    }

    // Only load audio if showing waveform and it's not already loaded for this video
    if (_isWaveformVisible && mounted) {
      final currentState = _waveformBloc.state;
      final isAlreadyLoaded = currentState is WaveformReady && 
                              currentState.sourceFilePath == _selectedVideoPath;
      
      if (!isAlreadyLoaded) {
        _waveformBloc.add(LoadAudioFile(
          _selectedVideoPath!,
          subtitleCollectionId: widget.subtitleCollectionId,
        ));
      }
    }
  }

  /// Register hotkey shortcuts using MSoneHotkeyManager
  Future<void> _registerHotkeyShortcuts() async {
    debugPrint('DEBUG: _registerHotkeyShortcuts() called in EditScreen');
    
    // Unregister HomeScreen shortcuts to prevent conflicts (e.g., Ctrl+E)
    await hotkey.MSoneHotkeyManager.instance.unregisterHomeScreenShortcuts();
    
    await hotkey.MSoneHotkeyManager.instance.registerMainEditScreenShortcuts(
      onPlayPause: _handlePlayPauseShortcut,
      onToggleSelection: _handleToggleSelectionModeShortcut,
      onDelete: _handleDeleteSelectionShortcut,
      onSave: _handleSaveShortcut,
      onCopy: _handleCopyShortcut,
      // Navigation shortcuts
      onNextLine: _handleNextLineShortcut,
      onPreviousLine: _handlePreviousLineShortcut,
      // New shortcuts
      onEditCurrentLine: _handleEditCurrentLineShortcut,
      onMarkLine: _handleMarkLineShortcut,
      onMarkLineAndComment: _handleMarkLineAndCommentShortcut,
      onFindReplace: _handleFindReplaceShortcut,
      onGotoLine: _handleGotoLineShortcut,
      onHelp: _handleHelpShortcut,
      onSettings: _handleSettingsShortcut,
      onSaveProject: _handleSaveProject,
      onPopScreen: _handlePopScreenShortcut,
      // Video playback shortcuts (only fullscreen)
      onToggleFullscreen: _handleToggleFullscreenShortcut,
      // Marked lines sheet shortcut
      onShowMarkedLines: _showMarkedLinesModal,
    );
    debugPrint('DEBUG: _registerHotkeyShortcuts() completed in EditScreen');
  }

  @override
  void dispose() {
    _resizeRatioSaveTimer?.cancel(); // Cancel resize ratio save timer
    _mobileResizeRatioSaveTimer?.cancel(); // Cancel mobile resize ratio save timer
    _navigationDebounceTimer?.cancel(); // Cancel navigation debounce timer
    _subtitleChangeDebouncer?.cancel(); // Cancel subtitle change debouncer
    
    // Unregister only this screen's hotkey shortcuts
    hotkey.MSoneHotkeyManager.instance.unregisterMainEditScreenShortcuts();
    
    _sourceScrollController.dispose(); // Dispose source view scroll controller
    _scrollbarController.dispose(); // Dispose custom scrollbar controller
    _goToController.dispose();
    _waveformBloc.close(); // Dispose waveform BLoC
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure video player subtitles are updated when screen comes back into focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isVideoLoaded && _subtitles.isNotEmpty) {
        _updateVideoPlayerSubtitles();
      }
      // Only register hotkeys once, not on every dependency change
      if (!_hotkeysRegistered) {
        _ensureHotkeysRegistered();
      }
    });
  }

  /// Ensure hotkeys are properly registered when returning to this screen
  Future<void> _ensureHotkeysRegistered() async {
    if (_hotkeysRegistered) return; // Guard against multiple registrations
    
    try {
      // Force re-register shared shortcuts that might have been affected
      await hotkey.MSoneHotkeyManager.instance.forceRegisterSharedShortcuts(
        onHelp: _handleHelpShortcut,
        onSettings: _handleSettingsShortcut,
        onNextLine: _handleNextLineShortcut,
        onPreviousLine: _handlePreviousLineShortcut,
      );
      
      // Also ensure mark line shortcuts are re-registered (Ctrl+M and Ctrl+Shift+M)
      await hotkey.MSoneHotkeyManager.instance.registerCallback(
        hotkey.HotkeyAction.markLine,
        _handleMarkLineShortcut,
      );
      await hotkey.MSoneHotkeyManager.instance.registerCallback(
        hotkey.HotkeyAction.markLineAndComment,
        _handleMarkLineAndCommentShortcut,
      );
      await hotkey.MSoneHotkeyManager.instance.registerCallback(
        hotkey.HotkeyAction.showMarkedLines,
        _showMarkedLinesModal,
      );
      
      _hotkeysRegistered = true; // Mark as registered
      debugPrint('DEBUG: Hotkeys registered successfully');
    } catch (e) {
      debugPrint('DEBUG: Failed to ensure hotkeys in didChangeDependencies: $e');
    }
  }

  Future<List<SubtitleLine>> _fetchSubtitleLines() async {
    final subtitles = await fetchSubtitleLines(widget.subtitleCollectionId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          subtitleLines = subtitles;
          _subtitles = _generateSubtitles(subtitles);
        });
        
        // Ensure video player gets the updated subtitles
        if (_isVideoLoaded) {
          _updateVideoPlayerSubtitles();
        }
      }
    });
    return subtitles;
  }

  Future<void> _loadSavedVideoPath() async {
    // Migrated to BLoC - video path already loaded by cubit.initialize()
    // Just sync local state from cubit state
    final state = _cubit.state;
    if (!mounted) return;
    
    setState(() {
      _selectedVideoPath = state.selectedVideoPath;
      _isVideoVisible = state.selectedVideoPath != null;
      _isVideoLoaded = state.isVideoLoaded;
    });
    
    // Ensure video player gets subtitles after video is loaded
    _ensureVideoPlayerSubtitles();
  }

  Future<void> _pickVideoFile() async {
    final filePath = await FilePickerConvenience.pickVideoFile(context: context);

    if (filePath != null) {
      // Clear waveform cache and reset waveform state when loading new video
      await PreferencesModel.clearWaveformCache(widget.subtitleCollectionId);
      _waveformBloc.add(const ClearWaveform());
      setState(() {
        _isWaveformVisible = false;
      });
      
      // Migrated to BLoC - delegate to cubit
      await _cubit.loadVideo(filePath);
      
      // Update local state from cubit state
      final state = _cubit.state;
      if (!mounted) return;
      
      setState(() {
        _selectedVideoPath = state.selectedVideoPath;
        _isVideoVisible = true;
        _isVideoLoaded = state.isVideoLoaded;
      });
      
      // Ensure video player gets subtitles after video is loaded
      _ensureVideoPlayerSubtitles();
    }
  }
  Future<void> _unloadVideo() async {
    // Migrated to BLoC - delegate to cubit
    await _cubit.unloadVideo();
    
    // Update local state from cubit state
    final state = _cubit.state;
    if (!mounted) return;
    
    setState(() {
      _selectedVideoPath = state.selectedVideoPath;
      _isVideoVisible = false;
      _isVideoLoaded = state.isVideoLoaded;
    });
  }

  // Source view methods
  void _switchToSourceView() {
    // Migrated to BLoC - delegate to cubit
    _cubit.switchToSourceView();
    
    // Update local state from cubit
    final state = _cubit.state;
    setState(() {
      _isSourceView = state.isSourceView;
      _sourceViewEntries = state.sourceViewEntries;
    });
  }

  void _switchToTimelineView() {
    // Migrated to BLoC - delegate to cubit
    _cubit.switchToCardsView();
    
    // Update local state from cubit
    final state = _cubit.state;
    setState(() {
      _isSourceView = state.isSourceView;
    });
  }

  List<SubtitleEntry> _convertSubtitleLinesToEntries(List<SubtitleLine> lines) {
    return lines.asMap().entries.map((entry) {
      return SubtitleEntry.fromSubtitleLine(entry.value, entry.key);
    }).toList();
  }

  // String _convertEntriesToSrtContent() {
  //   final buffer = StringBuffer();
  //   for (int i = 0; i < _sourceViewEntries.length; i++) {
  //     if (i > 0) buffer.write('\n');
  //     buffer.write(_sourceViewEntries[i].toSrtString());
  //   }
  //   return buffer.toString();
  // }

  void _onSourceViewContentChanged() {
    // Mark that changes have been made (you can add unsaved changes tracking here)
  }

  // Future<void> _saveSourceViewChanges() async {
  //   try {
  //     // Convert source view entries back to subtitle lines and save
  //     // This would integrate with your existing save logic
  //     await _handleSave();
  //     SnackbarHelper.showSuccess(context, 'Source view changes saved');
  //   } catch (e) {
  //     SnackbarHelper.showError(context, 'Failed to save source view changes: $e');
  //   }
  // }

  /// Sync source view entries back to the database
  Future<void> _syncSourceViewToDatabase() async {
    try {
      // Migrated to BLoC - delegate to cubit
      await _cubit.syncSourceViewToDatabase(_sourceViewEntries);
      
      // Refresh the subtitle lines cache
      await _refreshSubtitleLines();
      
    } catch (e) {
      throw Exception('Failed to sync source view to database: $e');
    }
  }

  List<Subtitle> _generateSubtitles(List<SubtitleLine> subtitleLines) {
    return subtitleLines.asMap().entries.map((entry) {
      final index = entry.key; // Use array index instead of database index
      final line = entry.value;
      return Subtitle(
        index: index, // This ensures video player uses same indexing as list
        start: parseTimeString(line.startTime),
        end: parseTimeString(line.endTime),
        text: line.edited ?? line.original,
        marked: line.marked,
      );
    }).toList();
  }
  
  /// Update subtitles and increment version to trigger VideoPlayerSection rebuild
  /// This helper ensures consistent version tracking across all subtitle updates
  void _updateSubtitlesWithVersion(List<SubtitleLine> subtitleLines) {
    _subtitles = _generateSubtitles(subtitleLines);
    _subtitleVersion++;
    
    // Update waveform if it exists
    if (_waveformKey.currentState != null) {
      (_waveformKey.currentState as dynamic).updateSubtitles(subtitleLines);
    }
  }

  // Add this method to generate subtitles from SimpleSubtitleLine
  List<Subtitle> _generateSimpleSubtitles(List<SimpleSubtitleLine> subtitleLines) {
    return subtitleLines.asMap().entries.map((entry) {
      final index = entry.key; // Use array index instead of database index
      final line = entry.value;
      return Subtitle(
        index: index, // This ensures video player uses same indexing as list
        start: parseTimeString(line.startTime),
        end: parseTimeString(line.endTime),
        text: line.text,
        marked: false, // SimpleSubtitleLine doesn't have marked field
      );
    }).toList();
  }

  Future<void> _scrollToIndexWithLoading(int indx) async {
    print('Scrolling to index: $indx');
    int index = indx - 1;
    
    // Validate index first
    if (index < -1 || index >= subtitleLines.length) {
      return;
    }
    
    // Show the isolated loader
    IsolatedLoaderController.show(context);
    
    try {
      // More aggressive approach to prevent UI blocking
      // First, yield to allow the loader to render
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Wait for widget to be fully mounted and ready
      if (!mounted) {
        return;
      }
      
      // Ensure the scroll controller is attached before using it
      // This prevents the assertion error when called right after modal close
      int retries = 0;
      const maxRetries = 10;
      while (!_itemScrollController.isAttached && retries < maxRetries) {
        await Future.delayed(const Duration(milliseconds: 50));
        retries++;
      }
      
      // If still not attached after retries, skip scrolling
      if (!_itemScrollController.isAttached) {
        print('Warning: ItemScrollController not attached after $maxRetries retries, skipping scroll');
        if (mounted) {
          setState(() {
            _highlightedIndex = index;
          });
        }
        return;
      }

      // Use ScrollablePositionedList's scrollTo method
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
      
      // Set the highlight after scrolling completes
      await Future.delayed(const Duration(milliseconds: 350));
      
      if (mounted) {
        setState(() {
          _highlightedIndex = index;
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 50));
    } finally {
      // Always ensure the loader is hidden
      IsolatedLoaderController.hide();
    }
  }

  void _updateScrollbarPosition() {
    if (_isDraggingScrollbar) return; // Don't update while dragging
    if (!mounted) return; // Don't update if widget is disposed
    
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || subtitleLines.isEmpty) return;
    
    // Get the first visible item
    final firstVisible = positions.where((pos) => pos.itemLeadingEdge >= 0).firstOrNull;
    if (firstVisible != null) {
      final progress = firstVisible.index / subtitleLines.length;
      setState(() {
        _scrollbarThumbOffset = progress;
      });
    }
  }

  void scrollToIndex(int index) {
    if (index < 0 || index >= subtitleLines.length) return;
    
    // Use ScrollablePositionedList's built-in scrollTo method
    // which handles index-based scrolling accurately
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.5, // Center the item in the viewport (0.0 = top, 1.0 = bottom)
    );
  }

  // Direct navigation method that only updates UI state without side effects
  void _navigateToIndex(int index) async {
    if (index < 0 || index >= subtitleLines.length) return;

    // Debounce navigation to prevent multiple rapid calls
    if (_isNavigating) {
      debugPrint('_navigateToIndex: Ignoring call due to ongoing navigation (index: $index)');
      return;
    }

    _isNavigating = true;
    debugPrint('=== _navigateToIndex called: updating _highlightedIndex from $_highlightedIndex to $index ===');
    debugPrint('_navigateToIndex: Full stack trace:');
    debugPrint(StackTrace.current.toString());
    
    // Add delay to ensure modal close animation completes and UI is ready
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) {
      _isNavigating = false;
      return;
    }
    
    setState(() {
      _highlightedIndex = index;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        scrollToIndex(index);
      }
    });

    // Clear the navigation flag after a short delay
    _navigationDebounceTimer?.cancel();
    _navigationDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      _isNavigating = false;
      debugPrint('_navigateToIndex: Navigation debounce cleared');
    });
  }

  void _onSubtitleChange(int index) {
    if (index < 0 || index >= subtitleLines.length) return;

    // Cancel previous timer to implement debouncing
    _subtitleChangeDebouncer?.cancel();
    
    // Debounce: only update after 50ms of no changes
    // This reduces rebuilds from ~25 per change to 1
    _subtitleChangeDebouncer = Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      
      debugPrint('_onSubtitleChange called: updating _highlightedIndex from $_highlightedIndex to $index');
      
      setState(() {
        _highlightedIndex = index;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          scrollToIndex(index);
        }
      });
    });
  }

  void _onVideoPositionChanged(Duration position) {
    if (mounted) {
      setState(() {
        _lastVideoPosition = position;
      });
    }
  }

  void _highlightIndex(int index) {
    if (index < 0 || index >= subtitleLines.length) return;

    if (mounted) {
      setState(() {
        _highlightedIndex = index;
      });
    }
  }

  void _seekToSubtitle(int index) {
    if (index < 0 || index >= subtitleLines.length) return;

    final startTime = parseTimeString(subtitleLines[index].startTime);
    if (_videoPlayerKey.currentState != null &&
        _videoPlayerKey.currentState!.isInitialized()) {
      // Add 50ms offset to ensure subtitle is visible after seeking
      // This prevents the subtitle from disappearing when seeking to exact start time
      final seekPosition = startTime + const Duration(milliseconds: 50);
      _videoPlayerKey.currentState!.seekTo(seekPosition);
      // Update _lastVideoPosition for video sync
      if (mounted) {
        setState(() {
          _lastVideoPosition = seekPosition;
        });
      }
      _onSubtitleChange(index);
    }
  }

  // Seek video to currently highlighted subtitle (useful for manual sync)
  void _seekVideoToHighlightedSubtitle() {
    if (_highlightedIndex != null && _highlightedIndex! >= 0 && _highlightedIndex! < subtitleLines.length) {
      _seekToSubtitle(_highlightedIndex!);
    }
  }

  void _showBottomModalSheet(BuildContext context, int index, String text) {
    final isMarked = subtitleLines[index].marked;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => BottomModalSheet(
        onEdit: () async {
          Navigator.pop(context);
          if (_videoPlayerKey.currentState != null &&
              _videoPlayerKey.currentState!.isInitialized()) {
            _videoPlayerKey.currentState!.pause(); // Pause the video
          }
          await _navigateToEditSubtitleScreen(index);
        },
        onAddLine: () async {
          Navigator.pop(context);
          if (subtitleCollection != null) {
            SubtitleOperations.showAddLineConfirmation(
              context: context,
              currentLine: subtitleController.subtitleLines[index],
              collection: subtitleCollection!,
              currentStartTime: subtitleController.subtitleLines[index].startTime,
              currentEndTime: subtitleController.subtitleLines[index].endTime,
              subtitleId: widget.subtitleCollectionId,
              refreshCallback: (newLineIndex) => _refreshSubtitleLines(), // Refresh list view
              sessionId: widget.sessionId,
              onBeforeAdd: () async => true, // No need to save anything in list view
              isVideoLoaded: _isVideoLoaded,
              getCurrentVideoPosition: _isVideoLoaded && _videoPlayerKey.currentState != null
                  ? () => _videoPlayerKey.currentState!.getCurrentPosition()
                  : null,
            );
          }
        },
        onDelete: () async {
          Navigator.pop(context);
          if (subtitleCollection != null) {
            SubtitleOperations.showDeleteConfirmation(
              context: context,
              subtitleId: widget.subtitleCollectionId,
              currentLine: subtitleController.subtitleLines[index],
              collection: subtitleCollection!,
              onSuccess: _refreshSubtitleLines,
              sessionId: widget.sessionId,
            );
          }
        },
        onSelect: () {
        Navigator.pop(context);
        _toggleSelection(index);
        },
        onCopy: () {
          Navigator.pop(context);
          Clipboard.setData(ClipboardData(text: text));
          SnackbarHelper.showSuccess(context, 'Copied to clipboard', duration: const Duration(seconds: 2));
        },
        onMark: () async {
          Navigator.pop(context);
          await _toggleMarkLine(index);
        },
        onEffects: () {
          Navigator.pop(context);
          _showEffectsForSingleLine(index);
        },
        onShowInMarkedLines: isMarked ? () {
          Navigator.pop(context);
          _showMarkedLinesModalWithHighlight(subtitleLines[index].index);
        } : null,
        isMarked: isMarked,
      ),
    );
  }

  void _showEffectsForSingleLine(int index) {
    final currentLine = subtitleLines[index];
    final lineText = currentLine.edited ?? currentLine.original;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SubtitleEffectsSheet(
          selectedIndices: [index], // Convert to 0-based index
          onApplyEffect: (effectType, effectConfig) {
            _applyEffectToSingleLineFromBottomSheet(context, index, effectType, effectConfig);
          },
          subtitleLines: [currentLine], // Pass the current line
          lineText: lineText, // Pass the line text
        );
      },
    );
  }

  Future<void> _applyEffectToSingleLineFromBottomSheet(BuildContext context, int index, String effectType, Map<String, dynamic> effectConfig) async {
    try {
      final currentLine = subtitleLines[index];
      List<SubtitleLine> effectLines = [];
      
      if (effectType == 'karaoke') {
        final colorHex = effectConfig['color'] as String;
        final color = colorHex.substring(2); // Remove alpha channel
        final endDelay = effectConfig['endDelay'] as double? ?? 0.0;
        final effectTypeKaraoke = effectConfig['effectType'] as String? ?? 'word';
        
        // Extract text selection parameters
        final hasTextSelection = effectConfig['hasTextSelection'] as bool? ?? false;
        final selectionStart = effectConfig['selectionStart'] as int? ?? 0;
        final selectionEnd = effectConfig['selectionEnd'] as int? ?? 0;
        final selectedText = effectConfig['selectedText'] as String? ?? '';
        final fullText = effectConfig['fullText'] as String? ?? '';
        
        effectLines = await SubtitleEffectOperations.generateKaraokeEffect(
          originalLine: currentLine,
          color: color,
          effectType: effectTypeKaraoke,
          endDelay: endDelay,
          hasTextSelection: hasTextSelection,
          selectionStart: selectionStart,
          selectionEnd: selectionEnd,
          selectedText: selectedText,
          fullText: fullText,
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
          subtitleCollectionId: widget.subtitleCollectionId,
          originalLineIndex: index, // Convert to 0-based
          effectLines: effectLines,
        );
        
        if (success) {
          // Create a checkpoint for the effect
          await CheckpointManager.createCheckpoint(
            sessionId: widget.sessionId,
            subtitleCollectionId: widget.subtitleCollectionId,
            operationType: 'effect',
            description: 'Applied $effectType effect to line ${index + 1} (${effectLines.length} lines)',
            deltas: [], // Effects don't use deltas
            forceSnapshot: true, // IMPORTANT: Force snapshot because effects replace entire sections
          );
          
          // Update the last edited index to the first effect line
          if (effectLines.isNotEmpty) {
            final firstEffectLineIndex = effectLines.first.index;
            await updateLastEditedIndex(widget.sessionId, firstEffectLineIndex);
          }
          
          // Close the sheet and refresh
          Navigator.of(context).pop();
          await _refreshSubtitleLines();
          
          // Scroll to the first effect line to show where the effect was applied
          if (effectLines.isNotEmpty) {
            final firstEffectLineIndex = effectLines.first.index;
            await _scrollToIndexWithLoading(firstEffectLineIndex);
          }
          
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

  void _showSubmitToMsoneModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Submit to Msone',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(
              context: context,
              title: 'Existing Translator',
              subtitle: 'For translators with existing accounts',
              icon: Icons.person,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MsoneSubmissionScreen(
                      submissionType: 'main',
                      subtitleCollectionId: widget.subtitleCollectionId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildSubmitButton(
              context: context,
              title: 'Fresher',
              subtitle: 'For new translators',
              icon: Icons.person_add,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MsoneSubmissionScreen(
                      submissionType: 'fresher',
                      subtitleCollectionId: widget.subtitleCollectionId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

    void _toggleSelection(int index) {
    // Migrated to BLoC - delegate to cubit
    // BlocListener handles state synchronization automatically
    _cubit.toggleSelection(index);
  }

  void _clearSelection() {
    // Migrated to BLoC - delegate to cubit
    // BlocListener handles state synchronization automatically
    _cubit.clearSelection();
  }

  void _showBatchDeleteConfirmation() {
    void handleKeyEvent(KeyEvent event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          Navigator.pop(context);
          _deleteSelectedSubtitles().then((_) => _clearSelection());
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: handleKeyEvent,
        child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Selected Subtitles',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This action cannot be undone',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Warning message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Are you sure you want to delete ${_selectedIndices.length} subtitle lines? This action cannot be undone.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, size: 20, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 8),
                            Text(
                              'Cancel',
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _deleteSelectedSubtitles();
                          _clearSelection();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, size: 20, color: Theme.of(context).colorScheme.onSurface,),
                            const SizedBox(width: 8),
                            Text(
                              'Delete All',
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
      ), // Close KeyboardListener
      )
    );
  }

Future<void> _deleteSelectedSubtitles() async {
  if (_selectedIndices.isEmpty) {
    _clearSelection();
    return;
  }
  
  final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
  
  // Create checkpoint before deletion
  final List<SubtitleLineDelta> batchDeltas = [];
  for (final index in sortedIndices) {
    if (index >= 0 && index < subtitleLines.length) {
      final line = subtitleLines[index];
      
      final lineCopy = SubtitleLine()
        ..index = line.index
        ..startTime = line.startTime
        ..endTime = line.endTime
        ..original = line.original
        ..edited = line.edited
        ..marked = line.marked
        ..comment = line.comment;
      
      final delta = SubtitleLineDelta()
        ..changeType = 'delete'
        ..lineIndex = index
        ..beforeState = lineCopy
        ..afterState = null;
      batchDeltas.add(delta);
    }
  }
  
  if (batchDeltas.isNotEmpty) {
    try {
      await CheckpointManager.createCheckpoint(
        sessionId: widget.sessionId,
        subtitleCollectionId: widget.subtitleCollectionId,
        operationType: 'delete',
        description: 'Batch deleted ${batchDeltas.length} lines',
        deltas: batchDeltas,
      );
    } catch (e) {
      if (kDebugMode) print('Error creating batch checkpoint: $e');
    }
  }
  
  // Migrated to BLoC - use repository through cubit for deletion
  int successCount = 0;
  int failCount = 0;
  
  for (final index in sortedIndices) {
    try {
      await _cubit.deleteLine(index);
      successCount++;
    } catch (e) {
      failCount++;
      if (kDebugMode) print('Error deleting index $index: $e');
    }
  }
  
  // Update local state from cubit state
  final state = _cubit.state;
  setState(() {
    subtitleLines = state.subtitleLines;
  });
  
  // Update controller with all new lines
  subtitleController.setSubtitleLines(subtitleLines);
  
  // Regenerate subtitles for video player and update version
  _updateSubtitlesWithVersion(subtitleLines);
  
  // Update video player
  if (_videoPlayerKey.currentState != null) {
    _videoPlayerKey.currentState!.updateSubtitles(_subtitles);
  }
  
  if (!mounted) return;
  
  final message = 'Deleted $successCount subtitles${failCount > 0 ? ' (Failed: $failCount)' : ''}';
  SubtitleOperations.showSuccessSnackbar(context, message);
  
  _clearSelection();
}

  Future<void> _refreshSubtitleLines() async {
    // Migrated to BLoC - delegate to cubit
    await _cubit.refreshSubtitleLines();
    
    // Update local state from cubit state
    final state = _cubit.state;
    final updatedSubtitles = state.subtitleLines;
    
    subtitleController.setSubtitleLines(updatedSubtitles);
    final newGeneratedSubtitles = _generateSubtitles(updatedSubtitles);

    if (!mounted) return;
    
    // Update the state with new data
    setState(() {
      subtitleLines = updatedSubtitles;
      _subtitles = newGeneratedSubtitles;
    });

    // Update the video player's subtitles directly
    if (_videoPlayerKey.currentState != null) {
      _videoPlayerKey.currentState!.updateSubtitles(newGeneratedSubtitles);
    }
    
    // Update the waveform's subtitles
    if (_waveformKey.currentState != null) {
      (_waveformKey.currentState as dynamic).updateSubtitles(updatedSubtitles);
    }
  }

  /// Open add line sheet with pre-filled start and end times from waveform
  void _openAddLineSheetWithTimes(Duration startTime, Duration endTime) async {
    final startTimeStr = _formatDurationToSRT(startTime);
    final endTimeStr = _formatDurationToSRT(endTime);
    
    if (subtitleCollection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subtitle collection not loaded'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }
    
    try {
      // Find the correct insertion position based on the start time
      int insertIndex = subtitleLines.length; // Default to end
      int displayIndex = subtitleLines.length + 1; // 1-based display index
      
      for (int i = 0; i < subtitleLines.length; i++) {
        final lineStartTime = parseTimeString(subtitleLines[i].startTime);
        if (startTime.inMilliseconds < lineStartTime.inMilliseconds) {
          insertIndex = i;
          displayIndex = i + 1;
          break;
        }
      }
      
      // Create a new line with the selected times from waveform
      final newLine = SubtitleLine()
        ..index = displayIndex
        ..original = ''
        ..edited = null
        ..startTime = startTimeStr
        ..endTime = endTimeStr;
      
      // Create checkpoint before adding
      await CheckpointManager.createAddCheckpoint(
        sessionId: widget.sessionId,
        subtitleCollectionId: widget.subtitleCollectionId,
        addedLine: newLine,
        insertIndex: insertIndex, // 0-based insertion index
      );
      
      // Add the line to database
      final success = await addSubtitleLine(
        widget.subtitleCollectionId, 
        newLine, 
        insertIndex, // 0-based insertion index
      );
      
      if (success) {
        // Refresh the subtitle lines
        await _refreshSubtitleLines();
        
        // Navigate to the new line (0-based index)
        _navigateToIndex(insertIndex);
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New line added successfully at line $displayIndex'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } else {
        throw Exception('Failed to add new line to database');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add new line: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  /// Format Duration to SRT time string (HH:MM:SS,mmm)
  String _formatDurationToSRT(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds = duration.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$milliseconds';
  }

  // Toggle mark status of a subtitle line
  Future<void> _toggleMarkLine(int index) async {
    // Store the current highlighted index to maintain scroll position
    final previousHighlightedIndex = _highlightedIndex;
    
    // Migrated to BLoC - delegate to cubit which handles all business logic
    await _cubit.markLine(index);
    
    // Update local state from cubit state
    final state = _cubit.state;
    setState(() {
      subtitleLines = state.subtitleLines;
      // Restore the highlighted index to prevent unwanted scrolling
      _highlightedIndex = previousHighlightedIndex;
    });
    
    // Update the controller
    if (index >= 0 && index < subtitleLines.length) {
      subtitleController.updateSubtitleLine(index, subtitleLines[index]);
    }
    
    // Regenerate subtitles for video player
    _updateSubtitlesWithVersion(subtitleLines);
    
    // Update video player with new subtitles (for fullscreen mark button state)
    if (_videoPlayerKey.currentState != null) {
      _videoPlayerKey.currentState!.updateSubtitles(_subtitles);
    }
    
    // Show feedback based on cubit state
    if (!mounted) return;
    if (index >= 0 && index < subtitleLines.length) {
      final marked = subtitleLines[index].marked;
      SnackbarHelper.showSuccess(
        context,
        marked ? 'Line marked' : 'Line unmarked',
        duration: const Duration(seconds: 1),
      );
    }
  }

  // Show comment dialog for a specific line
  void _showCommentDialogForLine(int index) {
    if (index < 0 || index >= subtitleLines.length) return;
    
    final line = subtitleLines[index];
    
    // Check if video player is in fullscreen mode for different user experience
    final videoPlayerState = _videoPlayerKey.currentState;
    final isInFullscreenMode = videoPlayerState?.isInFullscreenMode() ?? false;
    
    if (isInFullscreenMode) {
      debugPrint('Showing comment dialog for fullscreen mode - line $index');
      
      // In fullscreen mode, find corresponding subtitle and use video player's fullscreen comment dialog
      if (index < _subtitles.length && videoPlayerState != null) {
        final subtitle = _subtitles[index];
        
        // Create a subtitle with current comment for the fullscreen dialog
        final subtitleWithComment = Subtitle(
          index: subtitle.index,
          start: subtitle.start,
          end: subtitle.end,
          text: subtitle.text,
          comment: line.comment,
        );
        
        // Mark dialog as open
        setState(() => _isCommentDialogOpen = true);
        
        // Use the video player's fullscreen-specific comment dialog
        videoPlayerState.showFullscreenCommentDialog(subtitleWithComment,
          originalText: line.original,
          editedText: line.edited,
        );
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _isCommentDialogOpen = false);
          }
        });
        return;
      }
    } else {
      debugPrint('Showing comment dialog for normal mode - line $index');
    }
    
    // Store the current playing state before showing dialog (for normal mode)
    bool wasPlaying = false;
    if (videoPlayerState != null && !isInFullscreenMode) {
      wasPlaying = videoPlayerState.isPlaying();
      debugPrint('Comment dialog opening in normal mode - video was ${wasPlaying ? 'playing' : 'paused'}');
      
      // Pause video if it was playing when comment dialog opens
      if (wasPlaying) {
        videoPlayerState.pause();
        debugPrint('Paused video for comment input in edit screen');
      }
    }
    
    // Flag to track if video has been resumed to prevent double resuming
    bool hasResumed = false;
    
    // Mark dialog as open
    setState(() => _isCommentDialogOpen = true);
    
    // Normal mode or fallback - use the standard comment dialog
    CommentDialog.show(
      context,
      existingComment: line.comment,
      originalText: line.original,
      editedText: line.edited,
      subtitleIndex: line.index,
      onCommentSaved: (comment) async {
        // If the line is not marked, mark it first
        if (!line.marked) {
          _toggleMarkLine(index);
          // Small delay to ensure mark operation completes
          await Future.delayed(const Duration(milliseconds: 50));
        }
        
        // Migrated to BLoC - delegate to cubit which handles all business logic
        await _cubit.updateComment(index, comment);
        
        // Update local state from cubit state
        final state = _cubit.state;
        setState(() {
          subtitleLines = state.subtitleLines;
        });
        
        // Update controller
        if (index >= 0 && index < subtitleLines.length) {
          subtitleController.updateSubtitleLine(index, subtitleLines[index]);
        }
        
        // Update all subtitle displays (video + waveform)
        _updateAllSubtitleDisplays();
        
        if (!mounted) return;
        final modeText = isInFullscreenMode ? 'fullscreen' : 'normal';
        SnackbarHelper.showSuccess(context, 'Comment updated ($modeText mode)');
        
        // Resume video if it was playing before dialog opened and not already resumed
        if (wasPlaying && videoPlayerState != null && !hasResumed) {
          hasResumed = true;
          videoPlayerState.play();
          debugPrint('Resumed video after comment save in edit screen');
        }
      },
      onCommentDeleted: line.comment?.isNotEmpty == true ? () async {
        // Migrated to BLoC - delegate to cubit which handles all business logic
        await _cubit.updateComment(index, null);
        
        // Update local state from cubit state
        final state = _cubit.state;
        setState(() {
          subtitleLines = state.subtitleLines;
        });
        
        // Update controller
        if (index >= 0 && index < subtitleLines.length) {
          subtitleController.updateSubtitleLine(index, subtitleLines[index]);
        }
        
        // Update all subtitle displays (video + waveform)
        _updateAllSubtitleDisplays();
        
        if (!mounted) return;
        SnackbarHelper.showSuccess(context, 'Comment deleted');
        
        // Resume video if it was playing before dialog opened and not already resumed
        if (wasPlaying && videoPlayerState != null && !hasResumed) {
          hasResumed = true;
          videoPlayerState.play();
          debugPrint('Resumed video after comment delete in edit screen');
        }
      } : null,
    ).then((_) {
      // Mark dialog as closed when dismissed
      if (mounted) {
        setState(() => _isCommentDialogOpen = false);
      }
      
      // This executes when the dialog is dismissed (by canceling without save/delete)
      // Resume video if it was playing before dialog opened and we haven't already resumed it
      if (wasPlaying && videoPlayerState != null && !hasResumed) {
        videoPlayerState.play();
        debugPrint('Resumed video after comment dialog dismissed in edit screen');
      }
    });
  }

  // Show marked lines modal
  Future<void> _showMarkedLinesModal() async {
    try {
      final markedLines = await getMarkedSubtitleLines(widget.subtitleCollectionId);
      final allLinesWithComments = await getAllSubtitleLinesWithComments(widget.subtitleCollectionId);
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (modalContext) => SizedBox(
          height: MediaQuery.of(modalContext).size.height,
          child: MarkedLinesSheet(
            markedLines: markedLines,
            allLinesWithComments: allLinesWithComments,
            onLineSelected: (index) async {
              // Close the modal first using the modal's context
              Navigator.of(modalContext).pop();
              
              // Wait for modal close animation to complete
              await Future.delayed(const Duration(milliseconds: 300));
              
              if (!mounted) return;
              
              // Navigate to the selected line
              await _scrollToIndexWithLoading(index + 1); // Convert back to 1-based index
              _highlightIndex(index);
              
              // Seek video to the selected subtitle if video is loaded
              if (_isVideoLoaded) {
                _seekToSubtitle(index);
              }
            },
            onCommentUpdated: (index, comment) async {
              // Update comment in database and refresh UI
              try {
                await updateSubtitleLineComment(widget.subtitleCollectionId, index, comment);
                // Refresh the subtitle line in UI
                if (index < subtitleLines.length) {
                  setState(() {
                    subtitleLines[index].comment = comment;
                  });
                  // Update controller
                  subtitleController.updateSubtitleLine(index, subtitleLines[index]);
                  
                  // Update all subtitle displays (video + waveform)
                  _updateAllSubtitleDisplays();
                }
                
                SnackbarHelper.showSuccess(context, 
                  comment != null ? 'Comment updated' : 'Comment deleted');
              } catch (e) {
                SnackbarHelper.showError(context, 'Failed to update comment: $e');
              }
            },
            onLineUnmarked: (index) async {
              // Unmark line and delete comment
              try {
                await unmarkSubtitleLine(widget.subtitleCollectionId, index);
                // Refresh the subtitle line in UI
                if (index < subtitleLines.length) {
                  setState(() {
                    subtitleLines[index].marked = false;
                    subtitleLines[index].comment = null;
                    subtitleLines[index].resolved = false;
                  });
                  // Update controller
                  subtitleController.updateSubtitleLine(index, subtitleLines[index]);
                  
                  // Update all subtitle displays (video + waveform)
                  _updateAllSubtitleDisplays();
                }
                
                SnackbarHelper.showSuccess(context, 'Line unmarked and comment deleted');
              } catch (e) {
                SnackbarHelper.showError(context, 'Failed to unmark line: $e');
              }
            },
            onResolvedUpdated: (index, resolved) async {
              // Update resolved status in database
              try {
                await updateSubtitleLineResolved(widget.subtitleCollectionId, index, resolved);
                // Refresh the subtitle line in UI
                if (index < subtitleLines.length) {
                  setState(() {
                    subtitleLines[index].resolved = resolved;
                  });
                  // Update controller
                  subtitleController.updateSubtitleLine(index, subtitleLines[index]);
                }
                
                SnackbarHelper.showSuccess(context, 
                  resolved ? 'Comment marked as resolved' : 'Comment marked as unresolved');
              } catch (e) {
                SnackbarHelper.showError(context, 'Failed to update resolved status: $e');
              }
            },
            onTextEdited: (index, newText) async {
              // Update edited text in database and refresh UI
              try {
                // Update the subtitle line
                if (index < subtitleLines.length) {
                  final updatedLine = subtitleLines[index];
                  updatedLine.edited = newText;
                  
                  // Save to database
                  await saveSubtitleChangesToDatabase(
                    widget.subtitleCollectionId,
                    updatedLine,
                    (String time) {
                      // Parse time format "HH:mm:ss,SSS" to DateTime
                      final parts = time.split(',');
                      final hms = parts[0].split(':');
                      return DateTime(0, 1, 1, 
                        int.parse(hms[0]), 
                        int.parse(hms[1]), 
                        int.parse(hms[2]), 
                        int.parse(parts[1]));
                    },
                    sessionId: widget.sessionId,
                  );
                  
                  // Update UI
                  setState(() {
                    subtitleLines[index] = updatedLine;
                  });
                  
                  // Update controller
                  subtitleController.updateSubtitleLine(index, updatedLine);
                  
                  // Update all subtitle displays (video + waveform)
                  _updateAllSubtitleDisplays();
                  
                  SnackbarHelper.showSuccess(context, 'Subtitle text updated');
                }
              } catch (e) {
                SnackbarHelper.showError(context, 'Failed to update subtitle text: $e');
              }
            },
          ),
        ),
      );
    } catch (e) {
      SnackbarHelper.showError(context, 'Error loading marked lines: $e');
    }
  }

  // Show marked lines modal with specific line highlighted
  Future<void> _showMarkedLinesModalWithHighlight(int databaseIndex) async {
    try {
      final markedLines = await getMarkedSubtitleLines(widget.subtitleCollectionId);
      final allLinesWithComments = await getAllSubtitleLinesWithComments(widget.subtitleCollectionId);
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (modalContext) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => MarkedLinesSheet(
            markedLines: markedLines,
            allLinesWithComments: allLinesWithComments,
            initialHighlightLineIndex: databaseIndex, // Pass the database index to highlight
            onLineSelected: (index) {
              Navigator.of(modalContext).pop();
              _navigateToIndex(index);
              _seekToSubtitle(index);
            },
            onCommentUpdated: (index, comment) async {
              // Update comment in database
              try {
                await updateSubtitleLineComment(widget.subtitleCollectionId, index, comment);
                // Refresh the subtitle line in UI
                if (index < subtitleLines.length) {
                  setState(() {
                    subtitleLines[index].comment = comment;
                  });
                  // Update controller
                  subtitleController.updateSubtitleLine(index, subtitleLines[index]);
                  
                  // Update all subtitle displays (video + waveform)
                  _updateAllSubtitleDisplays();
                }
                
                SnackbarHelper.showSuccess(context, 
                  comment != null ? 'Comment updated' : 'Comment deleted');
              } catch (e) {
                SnackbarHelper.showError(context, 'Failed to update comment: $e');
              }
            },
            onLineUnmarked: (index) async {
              // Unmark line and delete comment
              try {
                await unmarkSubtitleLine(widget.subtitleCollectionId, index);
                // Refresh the subtitle line in UI
                if (index < subtitleLines.length) {
                  setState(() {
                    subtitleLines[index].marked = false;
                    subtitleLines[index].comment = null;
                    subtitleLines[index].resolved = false;
                  });
                  // Update controller
                  subtitleController.updateSubtitleLine(index, subtitleLines[index]);
                  
                  // Update all subtitle displays (video + waveform)
                  _updateAllSubtitleDisplays();
                }
                
                SnackbarHelper.showSuccess(context, 'Line unmarked and comment deleted');
              } catch (e) {
                SnackbarHelper.showError(context, 'Failed to unmark line: $e');
              }
            },
            onResolvedUpdated: (index, resolved) async {
              // Update resolved status in database
              try {
                await updateSubtitleLineResolved(widget.subtitleCollectionId, index, resolved);
                // Refresh the subtitle line in UI
                if (index < subtitleLines.length) {
                  setState(() {
                    subtitleLines[index].resolved = resolved;
                  });
                  // Update controller
                  subtitleController.updateSubtitleLine(index, subtitleLines[index]);
                }
                
                SnackbarHelper.showSuccess(context, 
                  resolved ? 'Comment marked as resolved' : 'Comment marked as unresolved');
              } catch (e) {
                SnackbarHelper.showError(context, 'Failed to update resolved status: $e');
              }
            },
            onTextEdited: (index, newText) async {
              // Update edited text in database and refresh UI
              try {
                // Update the subtitle line
                if (index < subtitleLines.length) {
                  final updatedLine = subtitleLines[index];
                  updatedLine.edited = newText;
                  
                  // Save to database
                  await saveSubtitleChangesToDatabase(
                    widget.subtitleCollectionId,
                    updatedLine,
                    (String time) {
                      // Parse time format "HH:mm:ss,SSS" to DateTime
                      final parts = time.split(',');
                      final hms = parts[0].split(':');
                      return DateTime(0, 1, 1, 
                        int.parse(hms[0]), 
                        int.parse(hms[1]), 
                        int.parse(hms[2]), 
                        int.parse(parts[1]));
                    },
                    sessionId: widget.sessionId,
                  );
                  
                  // Update UI
                  setState(() {
                    subtitleLines[index] = updatedLine;
                  });
                  
                  // Update controller
                  subtitleController.updateSubtitleLine(index, updatedLine);
                  
                  // Update all subtitle displays (video + waveform)
                  _updateAllSubtitleDisplays();
                  
                  SnackbarHelper.showSuccess(context, 'Subtitle text updated');
                }
              } catch (e) {
                SnackbarHelper.showError(context, 'Failed to update subtitle text: $e');
              }
            },
          ),
        ),
      );
    } catch (e) {
      SnackbarHelper.showError(context, 'Error loading marked lines: $e');
    }
  }

  // Show Edit History modal (responsive dialog)
  void _showCheckpointHistoryModal() {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    
    if (isLargeScreen) {
      // Show as dialog on large screens
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 800,
              maxHeight: 700,
            ),
            child: CheckpointSheet(
              sessionId: widget.sessionId,
              subtitleCollectionId: widget.subtitleCollectionId,
              onCheckpointRestored: () async {
                // Reload subtitle lines after checkpoint restoration
                setState(() {
                  subtitleLinesFuture = fetchSubtitleLines(widget.subtitleCollectionId);
                });
                
                // Wait for the future to complete and update the UI
                final lines = await subtitleLinesFuture;
                setState(() {
                  subtitleLines = lines;
                  subtitleController.setSubtitleLines(lines);
                });
                
                // Update all subtitle displays (video + waveform)
                _updateAllSubtitleDisplays();
              },
            ),
          ),
        ),
      );
    } else {
      // Show fullscreen on mobile
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => CheckpointSheet(
            sessionId: widget.sessionId,
            subtitleCollectionId: widget.subtitleCollectionId,
            onCheckpointRestored: () async {
              // Reload subtitle lines after checkpoint restoration
              setState(() {
                subtitleLinesFuture = fetchSubtitleLines(widget.subtitleCollectionId);
              });
              
              // Wait for the future to complete and update the UI
              final lines = await subtitleLinesFuture;
              setState(() {
                subtitleLines = lines;
                subtitleController.setSubtitleLines(lines);
              });
              
              // Update all subtitle displays (video + waveform)
              _updateAllSubtitleDisplays();
            },
          ),
        ),
      );
    }
  }

  // Show import comments modal
  void _showImportCommentsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImportCommentsSheet(
        subtitleCollectionId: widget.subtitleCollectionId,
        onCommentsImported: () async {
          // Refresh the subtitle lines to show imported comments
          await _refreshSubtitleLines();
        },
      ),
    );
  }

  // Handle mark/unmark from video player fullscreen controls
  Future<void> _handleVideoPlayerMarkToggle(int subtitleIndex, bool isMarked) async {
    try {
      final success = await markSubtitleLine(widget.subtitleCollectionId, subtitleIndex, isMarked);
      if (success) {
        // Update the subtitle line in the list
        if (subtitleIndex < subtitleLines.length) {
          setState(() {
            subtitleLines[subtitleIndex].marked = isMarked;
          });
          
          // Update the controller
          subtitleController.updateSubtitleLine(subtitleIndex, subtitleLines[subtitleIndex]);
          
          // Update all subtitle displays (video + waveform)
          _updateAllSubtitleDisplays();
        }
        
        // Show success message
        SnackbarHelper.showSuccess(
          context,
          isMarked ? 'Line marked' : 'Line unmarked',
          duration: const Duration(seconds: 1),
        );
      } else {
        SnackbarHelper.showError(context, 'Failed to update mark status');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Error updating mark status: $e');
    }
  }

  // Helper method to format Duration with only 3 millisecond digits
  String _formatDurationToThreeDigits(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);
    
    return '${hours.toString().padLeft(1, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}.'
           '${milliseconds.toString().padLeft(3, '0')}';
  }

  Widget _buildSubtitleCard(SubtitleLine line, int index, String textContent) {
  final formattedStart = _formatDurationToThreeDigits(parseTimeString(line.startTime));
  final formattedEnd = _formatDurationToThreeDigits(parseTimeString(line.endTime));
  final isSelected = _selectedIndices.contains(index);

  return Dismissible(
    key: ValueKey('subtitle_${line.index}_$index'), // Use ValueKey with unique identifier
    direction: DismissDirection.horizontal,
    background: Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 20),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.green,
      ),
      child: Icon(Icons.edit, color: Colors.white, size: 30),
    ),
    secondaryBackground: Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 20),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.blue,
      ),
      child: Icon(Icons.select_all, color: Colors.white, size: 30),
    ),
    // confirmDismiss is used to trigger the navigation/selection without actually removing the widget.
    confirmDismiss: (direction) async {
      if (direction == DismissDirection.startToEnd && !_isSelectionMode) {
        // Right swipe: Navigate to edit screen
        if (_videoPlayerKey.currentState != null &&
            _videoPlayerKey.currentState!.isInitialized()) {
          _videoPlayerKey.currentState!.pause(); // Pause the video
        }
        await _navigateToEditSubtitleScreen(index);
      } else if (direction == DismissDirection.endToStart) {
        // Left swipe: Enter selection mode and select this item
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
          });
        }
        _toggleSelection(index);
      }
      // Returning false prevents the card from being dismissed (removed)
      return false;
    },
    child: Card(
      color: isSelected 
          ? Color(0xFF2A9D8F).withAlpha(77) // Selection color
          : (_highlightedIndex == index ? (
            Provider.of<ThemeProvider>(context)
                                              .themeMode ==
                                          ThemeMode.light ? Color(0xFF6c757d)
                                          :Color(0xFF005F73)
                                          ) : null),
      margin: EdgeInsets.only(left: 8, right: 8, bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      child: Listener(
        onPointerDown: (PointerDownEvent event) {
          // Handle right-click (secondary button)
          if (event.buttons == 2) {
            if (_isSelectionMode || _isRangeSelectionActive) {
              // In selection mode: show selection menu at click position
              _showSelectionMenuModal(position: event.position);
            } else {
              // Normal mode: show subtitle action menu
              _showBottomModalSheet(context, index, textContent);
            }
          }
        },
        child: InkWell(
          onTap: () {
            if (_isRangeSelectionActive) {
              _handleRangeSelectionTap(index);
            } else if (_isSelectionMode) {
              _toggleSelection(index);
            } else {
              _highlightIndex(index);
              _seekToSubtitle(index);
            }
          },
          onDoubleTap: () async {
            if (_isSelectionMode || _isRangeSelectionActive) return; // Disable double tap in selection mode
            
            if (_videoPlayerKey.currentState != null &&
                _videoPlayerKey.currentState!.isInitialized()) {
              _videoPlayerKey.currentState!.pause(); // Pause the video
            }
            await _navigateToEditSubtitleScreen(index);
          },
          onLongPress: () {
            if (_isSelectionMode || _isRangeSelectionActive) return; // Disable long press in selection mode
            _showBottomModalSheet(context, index, textContent);
          },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$formattedStart -> $formattedEnd',
                        style: TextStyle(
                          color: Provider.of<ThemeProvider>(context)
                                      .themeMode ==
                                  ThemeMode.light
                              ? (_highlightedIndex == line.index - 1 ? Color.fromARGB(200, 244, 163, 97)
                                  : Color.fromARGB(158, 0, 45, 54))
                              : Color.fromARGB(158, 244, 163, 97),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily:
                              GoogleFonts.spaceMono().fontFamily,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (line.marked) ...[
                            Listener(
                              onPointerDown: (PointerDownEvent event) {
                                // Handle mouse right-click for comment dialog
                                if (event.kind == PointerDeviceKind.mouse && 
                                    event.buttons == kSecondaryMouseButton) {
                                  _showCommentDialogForLine(index);
                                }
                              },
                              child: GestureDetector(
                                onLongPress: () {
                                  // Show comment dialog for marked lines (touch devices)
                                  _showCommentDialogForLine(index);
                                },
                                onTap: () {
                                  // Optional: quick toggle mark status on tap
                                  _toggleMarkLine(index);
                                },
                                child: Container(
                                  padding: EdgeInsets.only(left: 8, right: 4), // Increase touch area
                                  child: Icon(
                                    Icons.bookmark_added,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${line.index}',
                            style: TextStyle(
                              color: Provider.of<ThemeProvider>(context)
                                          .themeMode ==
                                      ThemeMode.light
                                  ? (_highlightedIndex == line.index - 1 ? Color.fromARGB(200, 244, 163, 97)
                                           : Color.fromARGB(158, 0, 45, 54))
                                  
                                  : Color.fromARGB(158, 244, 163, 97),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomHtmlText(
                          htmlContent:
                              textContent.replaceAll('\n', '<br>'),
                          defaultStyle: TextStyle(
                              color: Provider.of<ThemeProvider>(context)
                                          .themeMode ==
                                      ThemeMode.light
                                  ? (_highlightedIndex == line.index - 1 ? Color.fromARGB(255, 255, 255, 255)
                                      : Color.fromARGB(158, 0, 45, 54)
                                    )
                                  : Color.fromARGB(255, 255, 255, 255),
                              fontSize: 14,
                            ),
                          textAlign: TextAlign.start,
                          expanded: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Selection indicator
              if (isSelected)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF3a86ff),
                    size: 24,
                  ),
                ),
            ],
          ),
        ), // Container
        ), // InkWell
      ), // Listener
    ),
  );
}

  // Copy the text of all selected subtitles
  void _copySelectedSubtitles() {
    if (_selectedIndices.isEmpty) return;
    
    final List<int> sortedIndices = _selectedIndices.toList()..sort();
    final StringBuffer buffer = StringBuffer();
    
    for (final index in sortedIndices) {
      if (index < 0 || index >= subtitleLines.length) continue;
      final textContent = subtitleLines[index].edited ?? subtitleLines[index].original;
      buffer.write('${textContent.trim()}\n\n');
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    SnackbarHelper.showSuccess(context, '${sortedIndices.length} subtitles copied to clipboard', duration: const Duration(seconds: 2));
  }
  
  // Copy the highlighted line
  void _copyHighlightedLine() {
    if (_highlightedIndex == null || _highlightedIndex! < 0 || _highlightedIndex! >= subtitleLines.length) {
      SnackbarHelper.showError(context, 'No line highlighted to copy');
      return;
    }
    
    final textContent = subtitleLines[_highlightedIndex!].edited ?? subtitleLines[_highlightedIndex!].original;
    Clipboard.setData(ClipboardData(text: textContent.trim()));
    SnackbarHelper.showSuccess(context, 'Line ${_highlightedIndex! + 1} copied to clipboard', duration: const Duration(seconds: 2));
  }
  
  // Unified copy handler - copies selected lines in selection mode, highlighted line in normal mode
  void _handleCopyShortcut() {
    if (_isSelectionMode && _selectedIndices.isNotEmpty) {
      _copySelectedSubtitles();
    } else if (_highlightedIndex != null) {
      _copyHighlightedLine();
    } else {
      SnackbarHelper.showError(context, 'No line to copy. Select lines or highlight a line first.');
    }
  }
  
  // Show dialog to shift timecodes for only selected subtitles
  void _showShiftSelectedTimesDialog() {
    if (_selectedIndices.isEmpty) return;
    
    final firstSelectedIndex = _selectedIndices.reduce((a, b) => a < b ? a : b);
    final lastSelectedIndex = _selectedIndices.reduce((a, b) => a > b ? a : b);
    
    final TextEditingController startTimeController = TextEditingController(
      text: subtitleLines[firstSelectedIndex].startTime
    );
    final TextEditingController endTimeController = TextEditingController(
      text: subtitleLines[lastSelectedIndex].endTime
    );
    
    bool isProcessing = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Dynamic color variables for adaptive theming
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primaryColor = Theme.of(context).primaryColor;
          final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
          final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
          final borderColor = onSurfaceColor.withValues(alpha: 0.12);

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
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
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.timer,
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
                                'Shift Selected Subtitles',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Adjust timing for selected subtitle lines',
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
                  
                  // Description
                  Text(
                    'Enter new timecodes for the first and last selected subtitles. Only the selected subtitles will be affected.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // First selected subtitle field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'First selected subtitle starts at:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: startTimeController,
                          decoration: InputDecoration(
                            hintText: '00:00:00,000',
                            prefixIcon: Icon(
                              Icons.access_time,
                              color: primaryColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Last selected subtitle field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last selected subtitle ends at:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: endTimeController,
                          decoration: InputDecoration(
                            hintText: '00:00:00,000',
                            prefixIcon: Icon(
                              Icons.access_time,
                              color: primaryColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
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
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    setState(() => isProcessing = true);
                                    
                                    _selectedIndices.map((idx) => subtitleLines[idx]).toList();
                                    
                                    final result = await SubtitleSyncOperations.shiftSelectedTimecodes(
                                      subtitleId: widget.subtitleCollectionId,
                                      allSubtitleLines: subtitleLines,
                                      selectedIndices: _selectedIndices.toList(),
                                      newStartTime: startTimeController.text,
                                      newEndTime: endTimeController.text,
                                    );
                                    
                                    setState(() => isProcessing = false);
                                    
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      
                                      if (result.success) {
                                        _refreshSubtitleLines();
                                        SnackbarHelper.showSuccess(context, 'Selected subtitles shifted successfully');
                                      } else {
                                        SnackbarHelper.showError(context, 'Error: ${result.message}');
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check, size: 20, color: onSurfaceColor,),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Apply',
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
            )
          );
        },
      ),
    );
  }
  
  // Show dialog to select subtitles by index range
  void _showSelectByIndexDialog() {
    final TextEditingController startIndexController = TextEditingController();
    final TextEditingController endIndexController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
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
                        Icons.format_list_numbered,
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
                            'Select by Index Range',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select subtitles between specified indices',
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

              // Description
              Text(
                'Enter the start and end indices to select a range of subtitle lines (e.g., 1 to ${subtitleLines.length}).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedColor,
                ),
              ),

              const SizedBox(height: 24),

              // Input fields
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
                        controller: startIndexController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Start Index',
                          hintText: '1',
                          prefixIcon: Icon(
                            Icons.play_arrow,
                            color: primaryColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          labelStyle: TextStyle(
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                        controller: endIndexController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'End Index',
                          hintText: '${subtitleLines.length}',
                          prefixIcon: Icon(
                            Icons.stop,
                            color: primaryColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          labelStyle: TextStyle(
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
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
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final startIndex = int.tryParse(startIndexController.text);
                          final endIndex = int.tryParse(endIndexController.text);
                          
                          if (startIndex == null || endIndex == null) {
                            SnackbarHelper.showError(context, 'Please enter valid numbers');
                            return;
                          }
                          
                          if (startIndex < 1 || 
                              endIndex > subtitleLines.length || 
                              startIndex > endIndex) {
                            SnackbarHelper.showError(context, 'Invalid range (valid: 1-${subtitleLines.length})');
                            return;
                          }
                          
                          Navigator.pop(context);
                          
                          setState(() {
                            _selectedIndices.clear();
                            for (int i = startIndex - 1; i < endIndex; i++) {
                              _selectedIndices.add(i);
                            }
                            _isSelectionMode = _selectedIndices.isNotEmpty;
                          });
                        },
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
                            Icon(Icons.check, size: 20, color: onSurfaceColor,),
                            const SizedBox(width: 8),
                            Text(
                              'Select',
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
  }
  
  // Toggle range selection mode
  void _toggleRangeSelectionMode() {
    setState(() {
      _isRangeSelectionActive = !_isRangeSelectionActive;
      _rangeStartIndex = null;
      
      if (_isRangeSelectionActive) {
        SnackbarHelper.showInfo(context, 'Tap on the first subtitle, then tap on the last subtitle', duration: const Duration(seconds: 5));
      }
    });
  }
  
  // Process tap during range selection mode
  void _handleRangeSelectionTap(int index) {
    if (_rangeStartIndex == null) {
      setState(() {
        _rangeStartIndex = index;
      });
      SnackbarHelper.showInfo(context, 'Now tap on the last subtitle to select the range', duration: const Duration(seconds: 3));
    } else {
      final start = min(_rangeStartIndex!, index);
      final end = max(_rangeStartIndex!, index);
      
      // Migrated to BLoC - use cubit for selection updates
      _cubit.clearSelection();
      for (int i = start; i <= end; i++) {
        _cubit.toggleSelection(i);
      }
      
      // Update local state from cubit
      final state = _cubit.state;
      setState(() {
        _selectedIndices
          ..clear()
          ..addAll(state.selectedIndices);
        _isSelectionMode = state.isSelectionMode;
        _isRangeSelectionActive = false;
        _rangeStartIndex = null;
      });
    }
  }

  // Add this method to toggle secondary subtitle visibility
  void _toggleSecondarySubtitles(bool value) {
    // For now, keep simple state management here since cubit only has toggle
    // TODO: Add setSecondarySubtitlesVisible(bool) to cubit for direct state setting
    setState(() {
      _showSecondarySubtitles = value;
      if (_videoPlayerKey.currentState != null) {
        if (value) {
          // Use cubit state for subtitles
          final state = _cubit.state;
          _videoPlayerKey.currentState!.updateSecondarySubtitles(state.secondarySubtitles);
        } else {
          _videoPlayerKey.currentState!.updateSecondarySubtitles([]);
        }
      }
    });
  }

  // Main menu popup
  void _showMainMenuModal() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 10,
        kToolbarHeight + 10,
        10,
        0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).cardColor,
      elevation: 8,
      items: _isSourceView ? _buildSourceViewMenuItems() : _buildTimelineViewMenuItems(),
    ).then((value) => _handleMainMenuSelection(value));
  }

  List<PopupMenuEntry<String>> _buildTimelineViewMenuItems() {
    return <PopupMenuEntry<String>>[
      // View Mode Switch
      PopupMenuItem<String>(
        value: 'switch_to_source',
        child: _buildMenuItemRow(
          icon: Icons.code,
          title: 'Switch to Source View',
          color: Colors.purple,
        ),
      ),
      
      const PopupMenuDivider(),
      
      // Video Controls
      PopupMenuItem<String>(
        value: 'load_video',
        child: _buildMenuItemRow(
          icon: _isVideoLoaded ? Icons.videocam_off : Icons.video_file,
          title: _isVideoLoaded ? 'Unload Video' : 'Load Video',
          color: Colors.blue,
        ),
      ),
      if (_isVideoLoaded)
        PopupMenuItem<String>(
          value: 'toggle_controls',
          child: _buildMenuItemRow(
            icon: _floatingControlsEnabled ? Icons.close_fullscreen : Icons.open_in_full,
            title: _floatingControlsEnabled ? 'Hide Floating Controls' : 'Show Floating Controls',
            color: Colors.indigo,
          ),
        ),
      if (_isVideoLoaded)
        PopupMenuItem<String>(
          value: 'generate_waveform',
          child: _buildMenuItemRow(
            icon: Icons.graphic_eq,
            title: () {
              final currentState = _waveformBloc.state;
              final isWaveformLoaded = currentState is WaveformReady;
              
              if (isWaveformLoaded) {
                return _isWaveformVisible ? 'Hide Waveform' : 'Show Waveform';
              } else {
                return 'Generate Waveform';
              }
            }(),
            color: Colors.deepPurple,
          ),
        ),
      if (_isVideoLoaded && _waveformBloc.state is WaveformReady)
        PopupMenuItem<String>(
          value: 'regenerate_waveform',
          child: _buildMenuItemRow(
            icon: Icons.refresh,
            title: 'Regenerate Waveform',
            color: Colors.orange,
          ),
        ),
        // Secondary Subtitles
      PopupMenuItem<String>(
        value: 'secondary_subtitle',
        child: _buildMenuItemRow(
          icon: Icons.subtitles,
          title: 'Load Secondary Subtitle',
          color: Colors.teal,
        ),
      ),
      if (_secondarySubtitles.isNotEmpty)
        PopupMenuItem<String>(
          value: 'toggle_secondary',
          child: _buildMenuItemRow(
            icon: _showSecondarySubtitles ? Icons.visibility : Icons.visibility_off,
            title: _showSecondarySubtitles ? 'Hide Secondary' : 'Show Secondary',
            color: Colors.cyan,
          ),
        ),
      // Divider
      const PopupMenuDivider(),
      
      // File Operations
      PopupMenuItem<String>(
        value: 'save',
        child: _buildMenuItemRow(
          icon: Icons.save,
          title: 'Save',
          color: Colors.green,
        ),
      ),
      PopupMenuItem<String>(
        value: 'save_file_as',
        child: _buildMenuItemRow(
          icon: Icons.file_open_outlined,
          title: 'Save File As',
          color: Colors.orange,
        ),
      ),
      PopupMenuItem<String>(
        value: 'save_project',
        child: _buildMenuItemRow(
          icon: Icons.save_alt,
          title: 'Save Project',
          color: Colors.blue,
        ),
      ),

      // Project Management
      PopupMenuItem<String>(
        value: 'project_settings',
        child: _buildMenuItemRow(
          icon: Icons.settings,
          title: 'Project Settings',
          color: Colors.indigo,
        ),
      ),
      
      const PopupMenuDivider(),
      
      
      // Navigation & Search
      PopupMenuItem<String>(
        value: 'goto',
        child: _buildMenuItemRow(
          icon: Icons.menu_open,
          title: 'Go to Line',
          color: Colors.orange,
        ),
      ),
      PopupMenuItem<String>(
        value: 'find_replace',
        child: _buildMenuItemRow(
          icon: Icons.find_replace,
          title: 'Find & Replace',
          color: Colors.purple,
        ),
      ),
      PopupMenuItem<String>(
        value: 'marked_lines',
        child: _buildMenuItemRow(
          icon: Icons.bookmark_added,
          title: 'Show Marked Lines',
          color: Colors.red,
        ),
      ),
      
      // Edit History
      PopupMenuItem<String>(
        value: 'checkpoint_history',
        child: _buildMenuItemRow(
          icon: Icons.history,
          title: 'Edit History',
          color: Colors.deepPurple,
        ),
      ),
      
      // Import Comments
      PopupMenuItem<String>(
        value: 'import_comments',
        child: _buildMenuItemRow(
          icon: Icons.comment_outlined,
          title: 'Import Comments',
          color: Colors.green,
        ),
      ),
      
      // Divider
      const PopupMenuDivider(),
      
      
      // Sync & Tools
      PopupMenuItem<String>(
        value: 'sync',
        child: _buildMenuItemRow(
          icon: Icons.sync,
          title: 'Sync Subtitles',
          color: Colors.amber,
        ),
      ),
      PopupMenuItem<String>(
        value: 'remove_hearing_impaired',
        child: _buildMenuItemRow(
          icon: Icons.hearing_disabled,
          title: 'Remove Hearing Impaired',
          color: Colors.brown,
        ),
      ),
      
      if (_isMsoneEnabled) ...[
        PopupMenuItem<String>(
          value: 'banners',
          child: _buildMenuItemRow(
            icon: Icons.add_box,
            title: 'Insert Banners',
            color: Colors.lightGreen,
          ),
        ),
        PopupMenuItem<String>(
          value: 'malayalam_normalize',
          child: _buildMenuItemRow(
            icon: Icons.translate,
            title: 'Malayalam Normalize',
            color: Colors.deepOrange,
          ),
        ),
        PopupMenuItem<String>(
          value: 'submit_msone',
          child: _buildMenuItemRow(
            icon: Icons.cloud_upload,
            title: 'Submit to Msone',
            color: Colors.pink,
          ),
        ),
      ],
      
      // Divider
      const PopupMenuDivider(),
      
      // Settings & Help
      PopupMenuItem<String>(
        value: 'settings',
        child: _buildMenuItemRow(
          icon: Icons.settings,
          title: 'Settings',
          color: Colors.grey,
        ),
      ),
      PopupMenuItem<String>(
        value: 'help',
        child: _buildMenuItemRow(
          icon: Icons.help_outline,
          title: 'Help & Documentation',
          color: Colors.blueGrey,
        ),
      ),
    ];
  }

  List<PopupMenuEntry<String>> _buildSourceViewMenuItems() {
    return <PopupMenuEntry<String>>[
      // View Mode Switch
      PopupMenuItem<String>(
        value: 'switch_to_timeline',
        child: _buildMenuItemRow(
          icon: Icons.timeline,
          title: 'Switch to Timeline View',
          color: Colors.blue,
        ),
      ),
      
      const PopupMenuDivider(),
      
      // File Operations
      PopupMenuItem<String>(
        value: 'save',
        child: _buildMenuItemRow(
          icon: Icons.save,
          title: 'Save',
          color: Colors.green,
        ),
      ),
      
      const PopupMenuDivider(),
      
      // Settings & Help
      PopupMenuItem<String>(
        value: 'settings',
        child: _buildMenuItemRow(
          icon: Icons.settings,
          title: 'Settings',
          color: Colors.grey,
        ),
      ),
      PopupMenuItem<String>(
        value: 'help',
        child: _buildMenuItemRow(
          icon: Icons.help_outline,
          title: 'Help & Documentation',
          color: Colors.blueGrey,
        ),
      ),
    ];
  }

  // Build menu item row for popup menu
  Widget _buildMenuItemRow({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Handle main menu selection
  void _handleMainMenuSelection(String? value) async {
    if (value == null) return;

    switch (value) {
      case 'switch_to_source':
        _switchToSourceView();
        break;
      case 'switch_to_timeline':
        _switchToTimelineView();
        break;
      case 'load_video':
        if (_isVideoLoaded) {
          _unloadVideo();
        } else {
          _pickVideoFile();
        }
        break;
      case 'toggle_controls':
        _toggleFloatingControls(!_floatingControlsEnabled);
        break;
      case 'generate_waveform':
        _toggleWaveform();
        break;
      case 'regenerate_waveform':
        // Force regenerate waveform by clearing cache and reloading
        if (_selectedVideoPath != null) {
          await PreferencesModel.clearWaveformCache(widget.subtitleCollectionId);
          _waveformBloc.add(const ClearWaveform());
          setState(() {
            _isWaveformVisible = true;
          });
          _waveformBloc.add(LoadAudioFile(
            _selectedVideoPath!,
            subtitleCollectionId: widget.subtitleCollectionId,
          ));
        }
        break;
      case 'save':
        _handleSave();
        break;
      case 'save_project':
        _handleSaveProject();
        break;
      case 'save_file_as':
        _handleSaveFileAs();
        break;
      case 'project_settings':
        _showProjectSettings();
        break;
      case 'goto':
        _showGoToLineModal();
        break;
      case 'find_replace':
        _showFindReplaceModal();
        break;
      case 'marked_lines':
        _showMarkedLinesModal();
        break;
      case 'checkpoint_history':
        _showCheckpointHistoryModal();
        break;
      case 'import_comments':
        _showImportCommentsModal();
        break;
      case 'secondary_subtitle':
        _showSecondarySubtitleModal();
        break;
      case 'toggle_secondary':
        _toggleSecondarySubtitles(!_showSecondarySubtitles);
        break;
      case 'sync':
        _showSyncModal();
        break;
      case 'remove_hearing_impaired':
        _removeHearingImpairedLines();
        break;
      case 'banners':
        _showInsertBannersModal();
        break;
      case 'malayalam_normalize':
        _showMalayalamNormalizationModal();
        break;
      case 'submit_msone':
        _showSubmitToMsoneModal();
        break;
      case 'settings':
        _showSettingsModal();
        break;
      case 'help':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HelpScreen()),
        );
        break;
    }
  }

  // Selection menu popup
  void _showSelectionMenuModal({Offset? position}) {
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    
    // Calculate menu position
    RelativeRect menuPosition;
    if (position != null && overlay != null) {
      // Use click position for mouse clicks
      menuPosition = RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      );
    } else {
      // Default position (top-right) for non-mouse triggers
      menuPosition = RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 10,
        kToolbarHeight + 10,
        10,
        0,
      );
    }
    
    showMenu(
      context: context,
      position: menuPosition,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).cardColor,
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        // Actions
        PopupMenuItem<String>(
          value: 'copy',
          child: _buildMenuItemRow(
            icon: Icons.content_copy,
            title: 'Copy Selected',
            color: Colors.purple,
          ),
        ),
        PopupMenuItem<String>(
          value: 'shift_times',
          child: _buildMenuItemRow(
            icon: Icons.timer,
            title: 'Shift Times',
            color: Colors.blue,
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: _buildMenuItemRow(
            icon: Icons.delete,
            title: 'Delete Selected',
            color: Colors.red,
          ),
        ),
        
        // Divider
        const PopupMenuDivider(),
        
        // Selection Tools
        PopupMenuItem<String>(
          value: 'select_by_index',
          child: _buildMenuItemRow(
            icon: Icons.format_list_numbered,
            title: 'Select by Index',
            color: Colors.orange,
          ),
        ),
        PopupMenuItem<String>(
          value: 'range_selection',
          child: _buildMenuItemRow(
            icon: Icons.format_line_spacing,
            title: 'Select by Range',
            color: Colors.green,
          ),
        ),
      ],
    ).then((value) => _handleSelectionMenuSelection(value));
  }

  // Handle selection menu selection
  void _handleSelectionMenuSelection(String? value) {
    if (value == null) return;

    switch (value) {
      case 'copy':
        _copySelectedSubtitles();
        break;
      case 'shift_times':
        _showShiftSelectedTimesDialog();
        break;
      case 'delete':
        _showBatchDeleteConfirmation();
        break;
      case 'select_by_index':
        _showSelectByIndexDialog();
        break;
      case 'range_selection':
        _toggleRangeSelectionMode();
        break;
    }
  }

  // Helper methods for menu actions
  void _showGoToLineModal() {
    showGotToLineModal(
      context: context,
      initialValue: '',
      hintText: subtitleLines.length,
      title: 'Go to line',
      onSubmitted: (value) async {
        final lineNumber = int.parse(value); // Keep as 1-based
        await _scrollToIndexWithLoading(lineNumber);
        _highlightIndex(lineNumber - 1); // Convert to 0-based for highlighting
        
        if (_isVideoLoaded) {
          _seekToSubtitle(lineNumber - 1); // Convert to 0-based for seeking
        }
      },
    );
  }

  Future<void> _handleSave() async {
    try {
      if (_isSourceView) {
        await _syncSourceViewToDatabase();
      }

      final subtitleCollection = await isar.subtitleCollections.get(widget.subtitleCollectionId);
      if (subtitleCollection == null) {
        if (mounted) SnackbarHelper.showError(context, 'Failed to load subtitle data');
        return;
      }

      final currentLines = await fetchSubtitleLines(widget.subtitleCollectionId);
      final srtContent = SrtCompiler.generateSrtContent(currentLines);
      bool saveSuccessful = false;

      // Attempt to save directly
      try {
        if (Platform.isMacOS) {
          final srtBookmark = subtitleCollection.macOsSrtBookmark;
          if (srtBookmark != null) {
            String? srtPath;
            try {
              srtPath = await MacOSBookmarkManager.resolveBookmark(base64Decode(srtBookmark));
              await File(srtPath!).writeAsString(srtContent);
              saveSuccessful = true;
                        } finally {
              if (srtPath != null) {
                await MacOSBookmarkManager.stopAccessingSecurityScopedResource(srtPath);
              }
            }
          }
        } else {
          // Try originalFileUri first, fall back to filePath for older entries
          String? originalFileUri = subtitleCollection.originalFileUri;
          String? filePath = subtitleCollection.filePath;
          
          // Use originalFileUri if available, otherwise fall back to filePath
          String? targetPath = (originalFileUri!.isNotEmpty) 
              ? originalFileUri 
              : filePath;
          
          if (targetPath!.isNotEmpty) {
            print('Attempting to save to: $targetPath');
            if (await PlatformFileHandler.writeFile(
              content: srtContent,
              filePath: targetPath,
              fileName: subtitleCollection.fileName,
              mimeType: 'application/x-subrip',
            )) {
              saveSuccessful = true;
              print('Save successful to: $targetPath');
              
              // Update originalFileUri if it wasn't set (for older entries)
              if (originalFileUri.isEmpty) {
                subtitleCollection.originalFileUri = targetPath;
                await updateSubtitleCollection(subtitleCollection);
                print('Updated originalFileUri to: $targetPath');
              }
            } else {
              print('PlatformFileHandler.writeFile returned false for: $targetPath');
            }
          } else {
            print('No valid file path found (originalFileUri and filePath are both empty)');
          }
        }
      } catch (e) {
        print('Direct save failed: $e');
        print('Stack trace: ${StackTrace.current}');
      }

      if (saveSuccessful) {
        if (mounted) SnackbarHelper.showSuccess(context, 'File saved successfully!');
        return;
      }
      
      // Fallback to "Save As"
      await _handleSaveFileAs();

    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Error saving file: $e');
    }
  }

  Future<void> _handleSaveFileAs() async {
    try {
      final subtitle = await fetchSubtitle(widget.subtitleCollectionId);

      if (subtitle == null) {
        throw Exception('Could not find subtitle with ID: ${widget.subtitleCollectionId}');
      }

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
          ),
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ExportBottomSheet(
                subtitle: subtitle,
                onExportComplete: () {
                  SnackbarHelper.showSuccess(context, 'Export completed successfully!', duration: const Duration(seconds: 1));
                },
              ),
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Error preparing export: $e');
      }
    }
  }

  Future<void> _handleSaveProject() async {
    try {
      // Get current session and subtitle collection
      final session = await isar.sessions.get(widget.sessionId);
      final subtitleCollection = await isar.subtitleCollections.get(widget.subtitleCollectionId);
      
      if (session == null || subtitleCollection == null) {
        if (context.mounted) {
          SnackbarHelper.showError(context, 'Failed to load session data');
        }
        return;
      }

      if (context.mounted) {
        final projectPath = await ProjectManager.saveProject(
          context: context,
          session: session,
          subtitleCollection: subtitleCollection,
        );

        if (projectPath != null) {
          // Update the session with the project file path
          await ProjectManager.updateSessionProjectPath(
            sessionId: widget.sessionId,
            projectFilePath: projectPath,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Error saving project: $e');
      }
    }
  }



  Future<void> _showFindReplaceModal() async {
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
        ),
        builder: (context) {
          return SearchReplaceSheet(
            subtitleLines: subtitleLines,
            subtitleId: widget.subtitleCollectionId,
            isReplaceMode: true,
            onRefresh: _refreshSubtitleLines,
            onLineSelected: (index) async {
              Navigator.pop(context);
              await _scrollToIndexWithLoading(index + 1); // Convert from 0-based to 1-based
              _highlightIndex(index); // Use 0-based for highlighting
            },
          );
        },
      );
    }
  }

  Future<void> _showSecondarySubtitleModal() async {
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
        ),
        builder: (context) {
            return SecondarySubtitleSheet(
              originalSubtitles: subtitleLines,
              subtitleCollectionId: widget.subtitleCollectionId,
              videoPlayerState: _videoPlayerKey.currentState,
              onSecondarySubtitlesLoaded: (secondarySubtitles) {
                setState(() {
                  _originalSecondarySubtitles = secondarySubtitles;
                  _secondarySubtitles = _generateSimpleSubtitles(secondarySubtitles);
                  if (_videoPlayerKey.currentState != null) {
                    _videoPlayerKey.currentState!.updateSecondarySubtitles(_secondarySubtitles);
                  }
                });
                SnackbarHelper.showSuccess(context, 'Secondary subtitles loaded');
              },
            );
        },
      );
    }
  }

  Future<void> _showProjectSettings() async {
    if (context.mounted) {
      // Fetch the current session and subtitle collection
      final session = await isar.sessions.get(widget.sessionId);
      final subtitleCollection = await isar.subtitleCollections.get(widget.subtitleCollectionId);
      
      if (session != null && subtitleCollection != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 1.0, // Make fullscreen
            minChildSize: 1.0,
            maxChildSize: 1.0,
            builder: (context, scrollController) => ProjectSettingsSheet(
              session: session,
              subtitleCollection: subtitleCollection,
              onProjectUpdated: () {
                // Refresh the current view if needed
                setState(() {});
              },
              onSecondarySubtitlesLoaded: (secondarySubtitles) {
                setState(() {
                  _originalSecondarySubtitles = secondarySubtitles;
                  _secondarySubtitles = _generateSimpleSubtitles(secondarySubtitles);
                  if (_videoPlayerKey.currentState != null) {
                    _videoPlayerKey.currentState!.updateSecondarySubtitles(_secondarySubtitles);
                  }
                });
                SnackbarHelper.showSuccess(context, 'Secondary subtitles loaded');
              },
              onSecondarySubtitlesCleared: () {
                setState(() {
                  _originalSecondarySubtitles = [];
                  _secondarySubtitles = [];
                  if (_videoPlayerKey.currentState != null) {
                    _videoPlayerKey.currentState!.updateSecondarySubtitles(_secondarySubtitles);
                  }
                });
                SnackbarHelper.showSuccess(context, 'Secondary subtitles cleared');
              },
              onSaveProject: () {
                _handleSaveProject();
              },
              onLoadVideo: () {
                // Use the EditScreen's video loading function
                _pickVideoFile();
              },
            ),
          ),
        );
      } else {
        SnackbarHelper.showSnackBar(
          context,
          'Error: Could not load project data',
          backgroundColor: Colors.red,
        );
      }
    }
  }

    // Load saved secondary subtitle (external path or original flag)
    // baseSubtitles can be provided (the freshly fetched subtitles) to ensure original-text restoration uses the right data
    Future<void> _loadSavedSecondarySubtitle([List<SubtitleLine>? baseSubtitles]) async {
      // Migrated to BLoC - secondary subtitles already loaded by cubit.initialize()
      // Just sync local state from cubit state
      final state = _cubit.state;
      if (!mounted) return;
      
      setState(() {
        _secondarySubtitles = state.secondarySubtitles;
        _originalSecondarySubtitles = state.originalSecondarySubtitles;
      });
      
      // Ensure video player gets updates
      _ensureVideoPlayerSubtitles();
    }

  Future<void> _showSyncModal() async {
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        builder: (context) {
          return SafeArea(
            child: SubtitleSyncSheet(
              subtitleLines: subtitleLines,
              subtitleId: widget.subtitleCollectionId,
              isVideoLoaded: _isVideoLoaded,
              videoPlayerKey: _videoPlayerKey,
              onRefresh: () {
                _refreshSubtitleLines();
                Navigator.pop(context);
              },
            ),
          );
        },
      );
    }
  }

  Future<void> _showInsertBannersModal() async {
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        builder: (context) => BannerConfigurationSheet(
          subtitleCollectionId: widget.subtitleCollectionId,
          sessionId: widget.sessionId,
          subtitleLines: subtitleLines,
          onBannersInserted: () {
            _refreshSubtitleLines();
            // Removed Navigator.pop(context) - the sheet already handles navigation
          },
        ),
      );
    }
  }

  Future<void> _showMalayalamNormalizationModal() async {
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        builder: (context) => MalayalamNormalizationSheet(
          subtitleCollectionId: widget.subtitleCollectionId,
          subtitleLines: subtitleLines,
          onNormalizationComplete: () {
            _refreshSubtitleLines();
          },
        ),
      );
    }
  }

  Future<void> _removeHearingImpairedLines() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Hearing Impaired Text'),
          content: const Text(
            'This will remove hearing impaired annotations such as:\n'
            '• Text in square brackets [like this]\n'
            '• Sound effects and music notes ♪\n'
            '• Speaker labels (NAME:)\n'
            '• Sound descriptions in parentheses\n\n'
            'Lines that become empty after removal will be deleted.\n\n'
            'This action cannot be undone. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Remove', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing subtitles...'),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Get current subtitle lines
      final currentLines = List<SubtitleLine>.from(subtitleLines);
      final originalCount = currentLines.length;

      // Apply hearing impaired text removal
      final cleanedLines = removeHearingImpairedText(currentLines);
      final removedCount = originalCount - cleanedLines.length;
      final modifiedCount = cleanedLines.where((cleaned) {
        final original = currentLines.firstWhere((c) => c.index == cleaned.index, orElse: () => cleaned);
        return original.original != cleaned.original;
      }).length;

      // Create checkpoint before making changes
      final List<SubtitleLineDelta> batchDeltas = [];
      
      // Track deletions and modifications
      for (int i = 0; i < currentLines.length; i++) {
        final originalLine = currentLines[i];
        final cleanedIndex = cleanedLines.indexWhere((cl) => cl.index == originalLine.index);
        
        if (cleanedIndex == -1) {
          // Line was removed
          final lineCopy = SubtitleLine()
            ..index = originalLine.index
            ..startTime = originalLine.startTime
            ..endTime = originalLine.endTime
            ..original = originalLine.original
            ..edited = originalLine.edited
            ..marked = originalLine.marked
            ..comment = originalLine.comment;
          
          final delta = SubtitleLineDelta()
            ..changeType = 'delete'
            ..lineIndex = i
            ..beforeState = lineCopy
            ..afterState = null;
          batchDeltas.add(delta);
        } else {
          final cleanedLine = cleanedLines[cleanedIndex];
          if (originalLine.original != cleanedLine.original) {
            // Line was modified
            final beforeCopy = SubtitleLine()
              ..index = originalLine.index
              ..startTime = originalLine.startTime
              ..endTime = originalLine.endTime
              ..original = originalLine.original
              ..edited = originalLine.edited
              ..marked = originalLine.marked
              ..comment = originalLine.comment;
            
            final afterCopy = SubtitleLine()
              ..index = cleanedLine.index
              ..startTime = cleanedLine.startTime
              ..endTime = cleanedLine.endTime
              ..original = cleanedLine.original
              ..edited = cleanedLine.edited
              ..marked = cleanedLine.marked
              ..comment = cleanedLine.comment;
            
            final delta = SubtitleLineDelta()
              ..changeType = 'modify'
              ..lineIndex = i
              ..beforeState = beforeCopy
              ..afterState = afterCopy;
            batchDeltas.add(delta);
          }
        }
      }

      if (batchDeltas.isNotEmpty) {
        try {
          await CheckpointManager.createCheckpoint(
            sessionId: widget.sessionId,
            subtitleCollectionId: widget.subtitleCollectionId,
            operationType: 'batch',
            description: 'Remove hearing impaired text',
            deltas: batchDeltas,
          );
        } catch (e) {
          if (kDebugMode) print('Error creating checkpoint: $e');
        }
      }

      // Update subtitle collection with cleaned lines
      await isar.writeTxn(() async {
        // Fetch the subtitle collection
        final collection = await isar.subtitleCollections.get(widget.subtitleCollectionId);
        if (collection != null) {
          // Replace lines with cleaned lines (re-index them properly)
          collection.lines = cleanedLines.map((line) {
            return SubtitleLine()
              ..index = line.index
              ..startTime = line.startTime
              ..endTime = line.endTime
              ..original = line.original
              ..edited = line.edited
              ..marked = line.marked
              ..comment = line.comment
              ..resolved = line.resolved;
          }).toList();
          
          // Reindex to ensure sequential numbering
          for (int i = 0; i < collection.lines.length; i++) {
            collection.lines[i].index = i + 1;
          }
          
          // Save the updated collection
          await isar.subtitleCollections.put(collection);
        }
      });

      // Refresh subtitle lines from database
      await _refreshSubtitleLines();

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show success message
      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        'Processed $originalCount lines. '
        '${removedCount > 0 ? "$removedCount lines deleted. " : ""}'
        '${modifiedCount > 0 ? "$modifiedCount lines modified. " : ""}'
        '${cleanedLines.length} lines remaining.',
      );
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      SnackbarHelper.showError(
        context,
        'Failed to remove hearing impaired text: $e',
      );
    }
  }

  Future<void> _showSettingsModal() async {
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        builder: (context) => SettingsSheet(
          onSettingsChanged: () async {
            // Reload preferences from database to sync cubit state
            await _cubit.reloadPreferences();
            // The BlocListener will automatically update local state from cubit
          },
        ),
      );
    }
  }
  
  Future<void> _navigateToEditSubtitleScreen(int index) async {
    // Unregister EditScreen hotkeys to prevent conflicts with EditSubtitleScreen
    await hotkey.MSoneHotkeyManager.instance.unregisterMainEditScreenShortcuts();
    
    // Fetch the session's edit mode before navigating
    final isEditMode = await getSessionEditMode(widget.sessionId);
    
    if (!mounted) return;
    
    // Pause the video before navigating
    if (_videoPlayerKey.currentState != null &&
        _videoPlayerKey.currentState!.isInitialized()) {
      _videoPlayerKey.currentState!.pause();
    }
    
    // Calculate start video position based on subtitle line timing
    Duration? startVideoPosition;
    if (_isVideoLoaded && index >= 0 && index < subtitleLines.length) {
      startVideoPosition = parseTimeString(subtitleLines[index].startTime);
    }
    
    final result = await Navigator.push<int?>(
      context,
      MaterialPageRoute(        builder: (context) => EditSubtitleScreenBloc(
          subtitleId: widget.subtitleCollectionId,
          index: index + 1,
          sessionId: widget.sessionId,
          editMode: isEditMode, // Pass the session's edit mode
          videoPath: _selectedVideoPath,
          isVideoLoaded: _isVideoLoaded,
          startVideoPosition: startVideoPosition,
          secondarySubtitles: _originalSecondarySubtitles.isNotEmpty ? _originalSecondarySubtitles : null,
        ),
      ),
    );

    // Re-register hotkey shortcuts after returning from EditSubtitleScreen
    // This is necessary because EditSubtitleScreen unregisters some shortcuts on dispose
    debugPrint('DEBUG: Re-registering EditScreen hotkeys after returning from EditSubtitleScreen');
    await _registerHotkeyShortcuts();
    
    // Force re-register shared shortcuts that might have been overridden
    debugPrint('DEBUG: Force re-registering shared shortcuts');
    await hotkey.MSoneHotkeyManager.instance.forceRegisterSharedShortcuts(
      onHelp: _handleHelpShortcut,
      onSettings: _handleSettingsShortcut,
      onNextLine: _handleNextLineShortcut,
      onPreviousLine: _handlePreviousLineShortcut,
    );
    debugPrint('DEBUG: Hotkey re-registration complete');

    if (result != null) {
      _refreshSubtitleLines();
      // Use the returned index from EditSubtitleScreen (result is 0-based, so add 1)
      await _scrollToIndexWithLoading(result + 1);
    }
    
    // Reload secondary subtitles after returning from EditSubtitleScreen
    // This ensures any changes made in EditSubtitleScreen are reflected here
    await _loadSavedSecondarySubtitle(subtitleLines);
  }

  // Tutorial methods
  Future<void> _checkTutorial() async {
    // This is now handled by FirstTimeInstructions widget
  }

  List<String> _getEditInstructions() {
    return [
      'Tap any subtitle line to seek video to that exact time.',
      'Double-tap or swipe a line to the right to edit the subtitle text.',
      'Long press a line to enter selection mode for batch operations.',
      'Use the menu (⋮) in the top right corner to access video loading, save, search & replace, and more features.',
      'The app does not save the changes to the file. Use the "Save" or "Save File As" option in the menu to save your changes to file.',
      'Selected lines can be copied, deleted, or have their timecodes shifted together.',
    ];
  }

  // Keyboard shortcut handlers
  void _handlePlayPauseShortcut() {
    if (_isVideoLoaded && _videoPlayerKey.currentState != null) {
      final isPlaying = _videoPlayerKey.currentState!.isPlaying();
      if (isPlaying) {
        _videoPlayerKey.currentState!.pause();
      } else {
        _videoPlayerKey.currentState!.play();
      }
    }
  }

  void _handleSaveShortcut() {
    // Use the new save function for keyboard shortcut
    _handleSave();
  }

  void _handleToggleSelectionModeShortcut() {
    // Use existing selection toggle logic
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _clearSelection();
      }
    });
  }

  void _handleDeleteSelectionShortcut() {
    // If in selection mode with selected items, use batch delete
    if (_isSelectionMode && _selectedIndices.isNotEmpty) {
      _showBatchDeleteConfirmation();
    } 
    // If there's a highlighted line, delete that specific line
    else if (_highlightedIndex != null && _highlightedIndex! < subtitleLines.length) {
      final lineToDelete = subtitleLines[_highlightedIndex!];
      if (subtitleCollection != null) {
        SubtitleOperations.showDeleteConfirmation(
          context: context,
          subtitleId: widget.subtitleCollectionId,
          currentLine: lineToDelete,
          collection: subtitleCollection!,
          onSuccess: _refreshSubtitleLines,
          sessionId: widget.sessionId,
        );
      }
    }
  }

  void _handleEditCurrentLineShortcut() {
    // Edit the highlighted line if available
    if (_highlightedIndex != null && _highlightedIndex! < subtitleLines.length) {
      _navigateToEditSubtitleScreen(_highlightedIndex!);
    }
    // If no highlighted line, edit the first line if available
    else if (subtitleLines.isNotEmpty) {
      _navigateToEditSubtitleScreen(0);
    }
  }

  void _handleMarkLineShortcut() {
    // Mark the highlighted line if available
    if (_highlightedIndex != null && _highlightedIndex! < subtitleLines.length) {
      _toggleMarkLine(_highlightedIndex!);
    }
    // If no highlighted line, mark the first line if available
    else if (subtitleLines.isNotEmpty) {
      _toggleMarkLine(0);
    }
  }

  void _handleMarkLineAndCommentShortcut() {
    // Don't open a new dialog if one is already visible
    if (_isCommentDialogOpen) {
      return;
    }
    
    int targetIndex;
    
    // Determine which line to operate on
    if (_highlightedIndex != null && _highlightedIndex! < subtitleLines.length) {
      targetIndex = _highlightedIndex!;
    } else if (subtitleLines.isNotEmpty) {
      targetIndex = 0;
    } else {
      return; // No lines available
    }

    // Always show comment dialog - marking happens when user presses 'Add' button
    _showCommentDialogForLine(targetIndex);
  }

  void _handleFindReplaceShortcut() {
    _showFindReplaceModal();
  }

  void _handleGotoLineShortcut() {
    _showGoToLineModal();
  }

  void _handleHelpShortcut() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpScreen()),
    );
  }

  void _handleSettingsShortcut() {
    _showSettingsModal();
  }

  void _handlePopScreenShortcut() {
    // Navigate back to the previous screen
    Navigator.of(context).pop();
  }

  // Navigation shortcut handlers for next/previous subtitle
  void _handleNextLineShortcut() {
    debugPrint('=== _handleNextLineShortcut CALLED ===');
    
    if (!_isVideoLoaded || _videoPlayerKey.currentState == null) {
      debugPrint('Ctrl+. pressed - video not loaded');
      return;
    }

    final videoPlayer = _videoPlayerKey.currentState!;
    
    // If in fullscreen mode, use video player's skip function
    if (videoPlayer.isInFullscreenMode()) {
      debugPrint('Ctrl+. pressed in fullscreen mode - using video skip to next subtitle');
      videoPlayer.seekToNextSubtitle();
      return;
    }
    
    // In normal mode, navigate to next subtitle and seek video
    debugPrint('Ctrl+. pressed in normal mode - navigating to next subtitle');
    
    int currentIndex = _highlightedIndex ?? -1; // Start from -1 if no highlighted index
    int nextIndex = currentIndex + 1;
    
    debugPrint('Navigation: current highlighted index = $currentIndex, next index = $nextIndex');
    
    // Navigate to next subtitle if valid index found
    if (nextIndex >= 0 && nextIndex < subtitleLines.length) {
      debugPrint('Navigating to subtitle at index $nextIndex (line ${subtitleLines[nextIndex].index})');
      // Use the direct navigation method to update highlighted index and scroll
      _navigateToIndex(nextIndex);
      
      // Seek video to the newly highlighted subtitle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _seekVideoToHighlightedSubtitle();
      });
    } else {
      debugPrint('No next subtitle found (nextIndex: $nextIndex, total: ${subtitleLines.length})');
    }
    
    debugPrint('=== _handleNextLineShortcut COMPLETED ===');
  }

  void _handlePreviousLineShortcut() {
    if (!_isVideoLoaded || _videoPlayerKey.currentState == null) {
      debugPrint('Ctrl+, pressed - video not loaded');
      return;
    }

    final videoPlayer = _videoPlayerKey.currentState!;
    
    // If in fullscreen mode, use video player's skip function
    if (videoPlayer.isInFullscreenMode()) {
      debugPrint('Ctrl+, pressed in fullscreen mode - using video skip to previous subtitle');
      videoPlayer.seekToPreviousSubtitle();
      return;
    }
    
    // In normal mode, navigate to previous subtitle and seek video
    debugPrint('Ctrl+, pressed in normal mode - navigating to previous subtitle');
    
    int currentIndex = _highlightedIndex ?? 0;
    int prevIndex = currentIndex - 1;
    
    debugPrint('Navigation: current highlighted index = $currentIndex, previous index = $prevIndex');
    
    // Navigate to previous subtitle if valid index found
    if (prevIndex >= 0 && prevIndex < subtitleLines.length) {
      debugPrint('Navigating to subtitle at index $prevIndex (line ${subtitleLines[prevIndex].index})');
      // Use the direct navigation method to update highlighted index and scroll
      _navigateToIndex(prevIndex);
      
      // Seek video to the newly highlighted subtitle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _seekVideoToHighlightedSubtitle();
      });
    } else {
      debugPrint('No previous subtitle found (prevIndex: $prevIndex, total: ${subtitleLines.length})');
    }
  }

  // Video playback shortcut handlers
  void _handleToggleFullscreenShortcut() {
    if (_videoPlayerKey.currentState != null) {
      _videoPlayerKey.currentState!.toggleCustomFullscreen();
    }
  }

  Widget _buildCustomScrollbar() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use the actual height of the list view container
          final scrollableHeight = constraints.maxHeight;
          final thumbHeight = max(50.0, scrollableHeight * 0.1);
          final trackHeight = scrollableHeight - thumbHeight;
          final thumbTop = _scrollbarThumbOffset * trackHeight;
          
          return GestureDetector(
            onVerticalDragStart: (details) {
              setState(() {
                _isDraggingScrollbar = true;
              });
            },
            onVerticalDragUpdate: (details) {
              if (subtitleLines.isEmpty) return;
              
              // Use the actual scrollable height from constraints
              final currentThumbHeight = max(50.0, scrollableHeight * 0.1);
              final currentTrackHeight = scrollableHeight - currentThumbHeight;
              
              // Calculate new offset based on drag position
              final localY = details.localPosition.dy - 8; // Account for top margin
              final newOffset = (localY / currentTrackHeight).clamp(0.0, 1.0);
              
              setState(() {
                _scrollbarThumbOffset = newOffset;
              });
              
              // Scroll to corresponding index
              final targetIndex = (newOffset * subtitleLines.length).round().clamp(0, subtitleLines.length - 1);
              if (_itemScrollController.isAttached) {
                _itemScrollController.jumpTo(
                  index: targetIndex,
                  alignment: 0.0,
                );
              }
            },
            onVerticalDragEnd: (details) {
              setState(() {
                _isDraggingScrollbar = false;
              });
            },
            child: Container(
              width: 20,
              margin: const EdgeInsets.only(right: 0, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: thumbTop,
                    left: 4,
                    right: 4,
                    child: Container(
                      height: thumbHeight,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditCubit, EditState>(
      listener: (context, state) {
        // Sync local state from cubit without triggering full rebuild
        // This eliminates the need for setState in migrated methods
        if (!setEquals(_selectedIndices, state.selectedIndices)) {
          _selectedIndices
            ..clear()
            ..addAll(state.selectedIndices);
        }
        
        if (_isSelectionMode != state.isSelectionMode) {
          _isSelectionMode = state.isSelectionMode;
        }
        
        // Sync preferences from cubit state on initialization and updates
        if (_floatingControlsEnabled != state.floatingControlsEnabled) {
          setState(() {
            _floatingControlsEnabled = state.floatingControlsEnabled;
          });
        }
        
        if (_isMsoneEnabled != state.isMsoneEnabled) {
          setState(() {
            _isMsoneEnabled = state.isMsoneEnabled;
          });
        }
        
        if (_isLayout1 != state.isLayout1) {
          setState(() {
            _isLayout1 = state.isLayout1;
          });
        }
      },
      child: PopScope(
        canPop: !_isSelectionMode, // Prevent pop when in selection mode
        onPopInvokedWithResult: (bool didPop, Object? result) async {
        // Pause video when going back
        if (_videoPlayerKey.currentState != null &&
            _videoPlayerKey.currentState!.isInitialized()) {
          _videoPlayerKey.currentState!.pause();
        }
        
        if (_isRangeSelectionActive) {
          // Exit range selection mode first
          setState(() {
            _isRangeSelectionActive = false;
            _rangeStartIndex = null;
          });
        } else if (_isSelectionMode) {
          // Handle selection mode back press
          _clearSelection();
        } else {
          // Handle normal back navigation
          if (!didPop) {
            Navigator.of(context).pop(true);
          }
        }
      },
        child: FirstTimeInstructions(
          screenName: 'edit',
          instructions: _getEditInstructions(),
          child: Stack(
          children: [
          Scaffold(
            appBar: AppBar(
              leading: _isSelectionMode || _isRangeSelectionActive
              ? IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    if (_isRangeSelectionActive) {
                      setState(() {
                        _isRangeSelectionActive = false;
                        _rangeStartIndex = null;
                      });
                    } else {
                      _clearSelection();
                    }
                  },
                )
              : IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              title: _isRangeSelectionActive
                  ? Text('Select range: tap first & last')
                  : (_isSelectionMode
                     ? Text('${_selectedIndices.length} selected')
                     : Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           if (_isSourceView) ...[
                             Icon(
                               Icons.code,
                               size: 16,
                               color: Theme.of(context).colorScheme.primary,
                             ),
                             const SizedBox(width: 4),
                           ],
                           Flexible(
                             child: ScrollingTitleWidget(
                               title: subtitleCollection?.fileName ?? 'Subtitle Studio',
                               style: const TextStyle(fontSize: 16),
                               maxWidth: MediaQuery.of(context).size.width * 0.4,
                             ),
                           ),
                           if (_isSourceView) ...[
                             const SizedBox(width: 8),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Text(
                                 'SOURCE',
                                 style: TextStyle(
                                   fontSize: 10,
                                   fontWeight: FontWeight.bold,
                                   color: Theme.of(context).colorScheme.primary,
                                 ),
                               ),
                             ),
                           ],
                         ],
                       )),
              actions: [
                if (_isSelectionMode) ...[
                  // Selection mode actions - now using modal sheet
                  IconButton(
                    tooltip: 'Selection options',
                    icon: Icon(Icons.more_vert),
                    onPressed: () => _showSelectionMenuModal(),
                  ),
                ] else ...[
                  // Normal mode actions (unchanged)
                  const ThemeSwitcherButton(),
                  if (_isVideoLoaded && !_isSourceView) // Hide video toggle in source view
                    IconButton(
                      onPressed: () {
                        // Store current position when hiding video
                        if (_isVideoVisible && _videoPlayerKey.currentState != null) {
                          _lastVideoPosition = _videoPlayerKey.currentState!.getCurrentPosition();
                        }
                          setState(() {
                          _isVideoVisible = !_isVideoVisible;
                        });
                        
                        // If making the video visible again, restore position
                        if (_isVideoVisible) {
                          // Give time for video player to initialize
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Future.delayed(Duration(milliseconds: 300), () {
                              if (_videoPlayerKey.currentState != null &&
                                  _videoPlayerKey.currentState!.isInitialized()) {
                                _videoPlayerKey.currentState!.seekTo(_lastVideoPosition);
                                // Ensure subtitles are updated when video becomes visible
                                _updateVideoPlayerSubtitles();
                              }
                            });
                          });
                        }
                      },
                      icon: _isVideoVisible
                          ? SvgPicture.asset(
                              'assets/movie_off.svg',
                              semanticsLabel: 'Movie off',
                              height: 25,
                              width: 35,
                            )                          : Icon(Icons.movie_outlined),
                    ),
                  if (_isVideoLoaded && !_isSourceView) // Hide waveform toggle in source view
                    IconButton(
                      tooltip: _isWaveformVisible ? 'Hide Waveform' : 'Show Waveform',
                      onPressed: _toggleWaveform,
                      icon: Icon(
                        _isWaveformVisible ? Icons.graphic_eq : Icons.graphic_eq_outlined,
                        color: Colors.white.withOpacity(_isWaveformVisible ? 1.0 : 0.5),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Main menu',
                    icon: const Icon(Icons.menu),
                    onPressed: () => _showMainMenuModal(),
                  ),
                ],
              ],
            ),
            body: SafeArea(
              child: FutureBuilder<List<SubtitleLine>>(
                future: subtitleLinesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: IsolatedLoader(isVisible: true,));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySubtitleView(context);
                  }
                  
                  // Switch between source view and timeline view
                  if (_isSourceView) {
                    return _buildSourceView(snapshot.data!);
                  } else {
                    return _buildResponsiveContent(snapshot.data!);
                  }
                },
              ),
            ),
          ),

          // Add floating play/pause button when enabled (hide in source view)
          if (!_isSourceView && _floatingControlsEnabled && _isVideoVisible && _isVideoLoaded && _videoPlayerKey.currentState != null)
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                heroTag: 'floatingPlayPause',
                onPressed: () {
                  if (_videoPlayerKey.currentState!.isInitialized()) {
                    _videoPlayerKey.currentState!.playOrPause();
                  }
                },
                backgroundColor: Colors.blue,
                child: StreamBuilder<bool>(
                  stream: _videoPlayerKey.currentState!.player.stream.playing,
                  builder: (context, snapshot) {
                    // Use the player's current state as the fallback value
                    final isPlaying = snapshot.data ?? _videoPlayerKey.currentState!.player.state.playing;
                    return Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
            
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const IsolatedLoader(isVisible: true,), // Use the new loader
            ),
        ],
      )
      ) // FirstTimeInstructions  
      ), // PopScope
    ); // BlocListener
  }

  // New method to build the empty state view
  Widget _buildEmptySubtitleView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.subtitles_outlined,
            size: 80,
            color: Color(0xFF0A9396),
          ),
          const SizedBox(height: 24),
          const Text(
            "No subtitles yet",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Get started by adding your first subtitle line",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addInitialSubtitleLine,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 1, 54, 64),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Add Subtitle Line",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to add the initial subtitle line
  Future<void> _addInitialSubtitleLine() async {
    try {
      // Create an empty subtitle line
      final newLine = SubtitleLine()
        ..index = 1
        ..original = ""
        ..startTime = "00:00:00,000"
        ..endTime = "00:00:02,000";

      // Add to database
      final success = await addSubtitleLine(widget.subtitleCollectionId, newLine, 0);
      
      if (success) {
        // Navigate to the editor to edit this new line
        if (!mounted) return;
        
        // Unregister EditScreen hotkeys to prevent conflicts with EditSubtitleScreen
        await hotkey.MSoneHotkeyManager.instance.unregisterMainEditScreenShortcuts();
        
        // Pause video if it's playing
        if (_videoPlayerKey.currentState != null &&
            _videoPlayerKey.currentState!.isInitialized()) {
          _videoPlayerKey.currentState!.pause();
        }
        
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(            builder: (context) => EditSubtitleScreenBloc(
              subtitleId: widget.subtitleCollectionId,
              index: 1, // First subtitle
              sessionId: widget.sessionId,
              isNewSubtitle: true, // Mark as new subtitle
              videoPath: _selectedVideoPath,
              isVideoLoaded: _isVideoLoaded,
              secondarySubtitles: _originalSecondarySubtitles.isNotEmpty ? _originalSecondarySubtitles : null,
            ),
          ),
        );

        // Re-register hotkey shortcuts after returning from EditSubtitleScreen
        // This is necessary because EditSubtitleScreen unregisters some shortcuts on dispose
        debugPrint('DEBUG: Re-registering EditScreen hotkeys after returning from EditSubtitleScreen (new subtitle path)');
        await _registerHotkeyShortcuts();
        
        // Force re-register shared shortcuts that might have been overridden
        debugPrint('DEBUG: Force re-registering shared shortcuts (new subtitle path)');
        await hotkey.MSoneHotkeyManager.instance.forceRegisterSharedShortcuts(
          onHelp: _handleHelpShortcut,
          onSettings: _handleSettingsShortcut,
        );
        debugPrint('DEBUG: Hotkey re-registration complete (new subtitle path)');

        if (result == true) {
          // Force complete refresh of the subtitle data
          final updatedSubtitles = await fetchSubtitleLines(widget.subtitleCollectionId);
          
          if (!mounted) return;
          
          // Update state with new data
          setState(() {
            subtitleLines = updatedSubtitles;
            subtitleController.setSubtitleLines(updatedSubtitles);
            _subtitles = _generateSubtitles(updatedSubtitles);
            
            // Recreate the FutureBuilder's future to force it to rebuild
            subtitleLinesFuture = Future.value(updatedSubtitles);
          });
          
          // Refresh the collection reference as well
          subtitleCollection = (await fetchSubtitle(widget.subtitleCollectionId))!;
          
          // After a short delay, scroll to the edited line
          await Future.delayed(Duration(milliseconds: 300));
          final lastIndex = await getLastEditedIndex(widget.sessionId);
          
          if (lastIndex != null && mounted) {
            await _scrollToIndexWithLoading(lastIndex);
          }
        }
      } else {
        if (!mounted) return;
        SnackbarHelper.showError(context, 'Failed to add subtitle line');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Error: $e');
    }
  }

  Widget _buildResponsiveContent(List<SubtitleLine> subtitleLines) {
    if (ResponsiveLayout.shouldUseDesktopLayout(context)) {
      // Don't build the ResizableSplitView until the resize ratio is loaded
      if (!_isResizeRatioLoaded) {
        print('DEBUG: EditScreen - Waiting for resize ratio to load...');
        // Return a temporary layout while loading
        return Row(
          children: [
            Expanded(
              flex: 35, // Default 35% while loading
              child: Column(
                children: [
                  // Title bar for subtitle list
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.subtitles,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${subtitleLines.length} Subtitles',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Subtitle list
                  Expanded(
                    child: Obx(() {
                      return Stack(
                        children: [
                          ScrollablePositionedList.builder(
                            itemScrollController: _itemScrollController,
                            itemPositionsListener: _itemPositionsListener,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                              bottom: 16, 
                              top: 8,
                              left: 8,
                              right: 8,
                            ),
                            itemCount: subtitleController.subtitleLines.length,
                            itemBuilder: (context, index) {
                              final line = subtitleController.subtitleLines[index];
                              final textContent = line.edited ?? line.original;
                              return _buildSubtitleCard(line, index, textContent);
                            },
                          ),
                          _buildCustomScrollbar(),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 65, // Default 65% while loading
              child: Column(
                children: [
                  if (_isVideoVisible && _selectedVideoPath != null) ...[
                    // Video player takes most of the available space
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        child: VideoPlayerWidget(
                          key: _videoPlayerKey,
                          videoPath: _selectedVideoPath!,
                          subtitleCollectionId: widget.subtitleCollectionId,
                          subtitles: _subtitles,
                          secondarySubtitles: _secondarySubtitles,
                          onPositionChanged: _onVideoPositionChanged,
                          // onActiveSubtitleChanged: null, // Temporarily disable to test if this is causing interference
                          onActiveSubtitleChanged: (arrayIndex) {
                            debugPrint('onActiveSubtitleChanged called with arrayIndex: $arrayIndex, current _highlightedIndex: $_highlightedIndex');
                            debugPrint('onActiveSubtitleChanged: Stack trace:');
                            debugPrint(StackTrace.current.toString().split('\n').take(5).join('\n'));
                            
                            if (arrayIndex >= 0 && arrayIndex < subtitleLines.length) {
                              if (_highlightedIndex != arrayIndex) {
                                debugPrint('Updating highlighted index from $_highlightedIndex to $arrayIndex via video player callback');
                                _onSubtitleChange(arrayIndex);
                              } else {
                                debugPrint('Highlighted index already matches, skipping update to prevent redundant state change');
                              }
                            }
                          },
                          onSubtitlesUpdated: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                // Refresh subtitle lines from database to get latest changes
                                _refreshSubtitleLines();
                              }
                            });
                          },
                          onFullscreenExited: () {
                            // Refresh subtitle list when returning from fullscreen mode
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _refreshSubtitleLines();
                              }
                            });
                          },
                          onSubtitleMarked: (subtitleIndex, isMarked) async {
                            await _handleVideoPlayerMarkToggle(subtitleIndex, isMarked);
                          },
                          onSubtitleCommentUpdated: (subtitleIndex, comment) async {
                            // Update comment in database and refresh UI
                            debugPrint('SCREEN_EDIT COMMENT DEBUG:');
                            debugPrint('  - Received subtitleIndex: $subtitleIndex');
                            debugPrint('  - Comment: "$comment"');
                            debugPrint('  - Total subtitleLines.length: ${subtitleLines.length}');
                            debugPrint('  - Index within bounds: ${subtitleIndex < subtitleLines.length}');
                            
                            if (subtitleIndex < subtitleLines.length) {
                              debugPrint('  - SubtitleLine at index $subtitleIndex: "${subtitleLines[subtitleIndex].original.substring(0, subtitleLines[subtitleIndex].original.length.clamp(0, 30))}..."');
                            }
                            
                            try {
                              debugPrint('  - Calling database updateSubtitleLineComment with:');
                              debugPrint('    - subtitleCollectionId: ${widget.subtitleCollectionId}');
                              debugPrint('    - lineIndex: $subtitleIndex');
                              debugPrint('    - comment: "$comment"');
                              
                              await updateSubtitleLineComment(widget.subtitleCollectionId, subtitleIndex, comment);
                              debugPrint('  - Database update successful');
                              
                              // Refresh the subtitle line in UI
                              if (subtitleIndex < subtitleLines.length) {
                                setState(() {
                                  subtitleLines[subtitleIndex].comment = comment;
                                });
                                // Update controller
                                subtitleController.updateSubtitleLine(subtitleIndex, subtitleLines[subtitleIndex]);
                                
                                // Regenerate subtitles for video player
                                _subtitles = _generateSubtitles(subtitleLines);
                                
                                // Update video player with new subtitles
                                if (_videoPlayerKey.currentState != null) {
                                  _videoPlayerKey.currentState!.updateSubtitles(_subtitles);
                                }
                              }
                              
                              SnackbarHelper.showSuccess(context, 
                                comment != null ? 'Comment updated' : 'Comment deleted');
                            } catch (e) {
                              debugPrint('  - Error: $e');
                              SnackbarHelper.showError(context, 'Failed to update comment: $e');
                            }
                          },
                        ),
                      ),
                    ),
                  ] else ...[
                    // Placeholder when no video is loaded
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.movie_outlined,
                              size: 80,
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No video loaded',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickVideoFile,
                              icon: const Icon(Icons.video_file),
                              label: const Text('Load Video'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }
      
      // Desktop layout: resizable sidebar + video player side by side
      // Swap leftChild and rightChild based on layout preference
      final leftChild = _isLayout1
          ? _buildSubtitleListInterface(subtitleLines)
          : _buildVideoPlayerInterface(subtitleLines);
      
      final rightChild = _isLayout1
          ? _buildVideoPlayerInterface(subtitleLines)
          : _buildSubtitleListInterface(subtitleLines);

      return ResizableSplitView(
        initialRatio: _resizeRatio,
        minRatio: 0.2,
        maxRatio: 0.8,
        dividerThickness: 6.0, // Increased from default 4.0 for better touch interaction
        onRatioChanged: (ratio) {
          _saveResizeRatio(ratio);
        },
        leftChild: leftChild,
        rightChild: rightChild,
      );
    } else {
      // Mobile layout: vertical layout with resizable video
      // Don't build until both resize ratios are loaded
      if (!_isMobileResizeRatioLoaded) {
        if (kDebugMode) {
          print('DEBUG: EditScreen - Waiting for mobile resize ratio to load...');
        }
        // Return a temporary layout while loading
        return Column(
          children: [
            if (_isVideoVisible && _selectedVideoPath != null)
              SizedBox(
                height: 250, // Default height while loading
                child: VideoPlayerWidget(
                  key: _videoPlayerKey,
                  videoPath: _selectedVideoPath!,
                  subtitleCollectionId: widget.subtitleCollectionId,
                  subtitles: _subtitles,
                  secondarySubtitles: _secondarySubtitles,
                  onPositionChanged: _onVideoPositionChanged,
                  onActiveSubtitleChanged: (arrayIndex) {
                    if (arrayIndex >= 0 && arrayIndex < subtitleLines.length) {
                      _onSubtitleChange(arrayIndex);
                    }
                  },
                  onSubtitlesUpdated: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _refreshSubtitleLines();
                      }
                    });
                  },
                  onFullscreenExited: () {
                    // Refresh subtitle list when returning from fullscreen mode
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _refreshSubtitleLines();
                      }
                    });
                  },
                  onSubtitleMarked: (subtitleIndex, isMarked) async {
                    await _handleVideoPlayerMarkToggle(subtitleIndex, isMarked);
                  },
                  onSubtitleCommentUpdated: (subtitleIndex, comment) async {
                    // Update comment in database and refresh UI
                    try {
                      await updateSubtitleLineComment(widget.subtitleCollectionId, subtitleIndex, comment);
                      // Refresh the subtitle line in UI
                      if (subtitleIndex < subtitleLines.length) {
                        setState(() {
                          subtitleLines[subtitleIndex].comment = comment;
                        });
                        // Update controller
                        subtitleController.updateSubtitleLine(subtitleIndex, subtitleLines[subtitleIndex]);
                        
                        // Regenerate subtitles for video player
                        _subtitles = _generateSubtitles(subtitleLines);
                        
                        // Update video player with new subtitles
                        if (_videoPlayerKey.currentState != null) {
                          _videoPlayerKey.currentState!.updateSubtitles(_subtitles);
                        }
                      }
                      
                      SnackbarHelper.showSuccess(context, 
                        comment != null ? 'Comment updated' : 'Comment deleted');
                    } catch (e) {
                      SnackbarHelper.showError(context, 'Failed to update comment: $e');
                    }
                  },
                ),
              ),
            if (_isVideoVisible && _selectedVideoPath != null)
              const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                return Stack(
                  children: [
                    ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 16, 
                        top: 16
                      ),
                      itemCount: subtitleController.subtitleLines.length,
                      itemBuilder: (context, index) {
                        final line = subtitleController.subtitleLines[index];
                        final textContent = line.edited ?? line.original;
                        return _buildSubtitleCard(line, index, textContent);
                      },
                    ),
                    _buildCustomScrollbar(),
                  ],
                );
              }),
            ),
          ],
        );
      }

      // Mobile layout with vertical ResizableSplitView - only if video is loaded and visible
      return ResponsiveLayout.shouldUseMobileResize(context) && _isVideoLoaded && _isVideoVisible
        ? ResizableSplitView(
            initialRatio: _mobileVideoResizeRatio,
            minRatio: 0.2,
            maxRatio: 0.8,
            vertical: true, // Vertical split for mobile
            dividerThickness: 6.0, // Increased for mobile touch interaction
            onRatioChanged: (ratio) {
              // Use post frame callback to avoid "Build scheduled during frame" error
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _mobileVideoResizeRatio = ratio;
                  });
                }
              });
              _saveMobileResizeRatio(ratio);
            },
            leftChild: _isVideoVisible && _selectedVideoPath != null
              ? Column(
                  children: [
                    // Video player
                    Expanded(
                      child: VideoPlayerWidget(
                        key: _videoPlayerKey,
                        videoPath: _selectedVideoPath!,
                        subtitleCollectionId: widget.subtitleCollectionId,
                        subtitles: _subtitles,
                        secondarySubtitles: _secondarySubtitles,
                        onPositionChanged: _onVideoPositionChanged,
                        onActiveSubtitleChanged: (arrayIndex) {
                          if (arrayIndex >= 0 && arrayIndex < subtitleLines.length) {
                            _onSubtitleChange(arrayIndex);
                          }
                        },
                        onSubtitlesUpdated: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _refreshSubtitleLines();
                            }
                          });
                        },
                        onFullscreenExited: () {
                          // Refresh subtitle list when returning from fullscreen mode
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _refreshSubtitleLines();
                            }
                          });
                        },
                        onSubtitleMarked: (subtitleIndex, isMarked) async {
                          await _handleVideoPlayerMarkToggle(subtitleIndex, isMarked);
                        },
                        onSubtitleCommentUpdated: (subtitleIndex, comment) async {
                          // Update comment in database and refresh UI
                          try {
                            await updateSubtitleLineComment(widget.subtitleCollectionId, subtitleIndex, comment);
                            // Refresh the subtitle line in UI
                            if (subtitleIndex < subtitleLines.length) {
                              setState(() {
                                subtitleLines[subtitleIndex].comment = comment;
                              });
                              // Update controller
                              subtitleController.updateSubtitleLine(subtitleIndex, subtitleLines[subtitleIndex]);
                              
                              // Regenerate subtitles for video player
                              _subtitles = _generateSubtitles(subtitleLines);
                              
                              // Update video player with new subtitles
                              if (_videoPlayerKey.currentState != null) {
                                _videoPlayerKey.currentState!.updateSubtitles(_subtitles);
                              }
                            }
                            
                            SnackbarHelper.showSuccess(context, 
                              comment != null ? 'Comment updated' : 'Comment deleted');
                          } catch (e) {
                            SnackbarHelper.showError(context, 'Failed to update comment: $e');
                          }
                        },
                      ),
                    ),
                    // Waveform section (when visible)
                    if (_isWaveformVisible) ...[
                      const Divider(height: 1),
                      SizedBox(
                        height: Platform.isWindows || Platform.isMacOS || Platform.isLinux 
                            ? 240.0 
                            : 180.0, // Taller on desktop for better visibility
                        child: BlocProvider<WaveformBloc>.value(
                          value: _waveformBloc,
                          child: WaveformWidget(
                            key: _waveformKey,
                            subtitles: subtitleLines,
                            playbackPosition: _lastVideoPosition,
                            subtitleCollectionId: widget.subtitleCollectionId,
                            sessionId: widget.sessionId,
                            highlightedSubtitleIndex: _highlightedIndex,
                            onSeek: (Duration position) {
                              // Seek video to the selected position
                              if (_videoPlayerKey.currentState != null) {
                                _videoPlayerKey.currentState!.seekTo(position);
                              }
                            },
                            onSubtitleHighlight: (int index) {
                              // Scroll to and highlight the subtitle in the list
                              _scrollToIndexWithLoading(index);
                              setState(() {
                                _highlightedIndex = index;
                              });
                            },
                            onSubtitlesUpdated: () async {
                              // Refresh subtitle lines from database
                              await _refreshSubtitleLines();
                            },
                            onAddLineConfirmed: (Duration startTime, Duration endTime) {
                              // Open add line sheet with selected times
                              _openAddLineSheetWithTimes(startTime, endTime);
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : Container(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.movie_outlined,
                                size: 60,
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No video loaded',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _pickVideoFile,
                                icon: const Icon(Icons.video_file),
                                label: const Text('Load Video'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            rightChild: Obx(() {
              return Stack(
                children: [
                  ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16, 
                      top: 16
                    ),
                    itemCount: subtitleController.subtitleLines.length,
                    itemBuilder: (context, index) {
                      final line = subtitleController.subtitleLines[index];
                      final textContent = line.edited ?? line.original;
                      return _buildSubtitleCard(line, index, textContent);
                    },
                  ),
                  _buildCustomScrollbar(),
                ],
              );
            }),
          )
        : // Fallback to original mobile layout for very small screens or when no video is loaded
          Column(
            children: [
              if (_isVideoVisible && _selectedVideoPath != null && _isVideoLoaded)
                SizedBox(
                  height: ResponsiveLayout.getMobileVideoHeight(
                    context, 
                    _mobileVideoResizeRatio,
                    includeWaveformHeight: false, // Don't include waveform in video height
                  ),
                  child: VideoPlayerWidget(
                    key: _videoPlayerKey,
                    videoPath: _selectedVideoPath!,
                    subtitleCollectionId: widget.subtitleCollectionId,
                    subtitles: _subtitles,
                    secondarySubtitles: _secondarySubtitles,
                    onPositionChanged: _onVideoPositionChanged,
                    onActiveSubtitleChanged: (arrayIndex) {
                      if (arrayIndex >= 0 && arrayIndex < subtitleLines.length) {
                        _onSubtitleChange(arrayIndex);
                      }
                    },
                    onSubtitlesUpdated: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _refreshSubtitleLines();
                        }
                      });
                    },
                    onFullscreenExited: () {
                      // Refresh subtitle list when returning from fullscreen mode
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _refreshSubtitleLines();
                        }
                      });
                    },
                    onSubtitleMarked: (subtitleIndex, isMarked) async {
                      await _handleVideoPlayerMarkToggle(subtitleIndex, isMarked);
                    },
                    onSubtitleCommentUpdated: (subtitleIndex, comment) async {
                      // Update comment in database and refresh UI
                      try {
                        await updateSubtitleLineComment(widget.subtitleCollectionId, subtitleIndex, comment);
                        // Refresh the subtitle line in UI
                        if (subtitleIndex < subtitleLines.length) {
                          setState(() {
                            subtitleLines[subtitleIndex].comment = comment;
                          });
                          // Update controller
                          subtitleController.updateSubtitleLine(subtitleIndex, subtitleLines[subtitleIndex]);
                          
                          // Regenerate subtitles for video player
                          _subtitles = _generateSubtitles(subtitleLines);
                          
                          // Update video player with new subtitles
                          if (_videoPlayerKey.currentState != null) {
                            _videoPlayerKey.currentState!.updateSubtitles(_subtitles);
                          }
                        }
                        
                        SnackbarHelper.showSuccess(context, 
                          comment != null ? 'Comment updated' : 'Comment deleted');
                      } catch (e) {
                        SnackbarHelper.showError(context, 'Failed to update comment: $e');
                      }
                    },
                  ),
                ),
              // Waveform section for mobile layout (when visible)
              if (_isVideoVisible && _selectedVideoPath != null && _isVideoLoaded && _isWaveformVisible) ...[
                const Divider(height: 1),
                SizedBox(
                  height: 180.0,
                  child: BlocProvider<WaveformBloc>.value(
                    value: _waveformBloc,
                    child: WaveformWidget(
                      key: _waveformKey,
                      subtitles: subtitleLines,
                      playbackPosition: _lastVideoPosition,
                      subtitleCollectionId: widget.subtitleCollectionId,
                      sessionId: widget.sessionId,
                      highlightedSubtitleIndex: _highlightedIndex,
                      onSeek: (Duration position) {
                        // Seek video to the selected position
                        if (_videoPlayerKey.currentState != null) {
                          _videoPlayerKey.currentState!.seekTo(position);
                        }
                      },
                      onSubtitleHighlight: (int index) {
                        // Scroll to and highlight the subtitle in the list
                        _scrollToIndexWithLoading(index);
                        setState(() {
                          _highlightedIndex = index;
                        });
                      },
                      onSubtitlesUpdated: () async {
                        // Refresh subtitle lines from database
                        await _refreshSubtitleLines();
                      },
                      onAddLineConfirmed: (Duration startTime, Duration endTime) {
                        // Open add line sheet with selected times
                        _openAddLineSheetWithTimes(startTime, endTime);
                      },
                    ),
                  ),
                ),
              ],
              if (_isVideoVisible && _selectedVideoPath != null && _isVideoLoaded)
                const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  return Stack(
                    children: [
                      ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 16, 
                          top: 16
                        ),
                        itemCount: subtitleController.subtitleLines.length,
                        itemBuilder: (context, index) {
                          final line = subtitleController.subtitleLines[index];
                          final textContent = line.edited ?? line.original;
                          return _buildSubtitleCard(line, index, textContent);
                        },
                      ),
                      _buildCustomScrollbar(),
                    ],
                  );
                }),
              ),
            ],
          );
    }
  }

  /// Build source view widget for direct text editing
  Widget _buildSourceView(List<SubtitleLine> subtitleLines) {
    // Ensure source entries are up to date
    if (_sourceViewEntries.isEmpty || _sourceViewEntries.length != subtitleLines.length) {
      _sourceViewEntries = _convertSubtitleLinesToEntries(subtitleLines);
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header with source view indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.code,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Source View - ${_sourceViewEntries.length} Subtitles',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Direct text editing mode',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // Source view list
          Expanded(
            child: Scrollbar(
              controller: _sourceScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              thickness: 8.0,
              child: ListView.builder(
                controller: _sourceScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                itemCount: _sourceViewEntries.length,
                itemBuilder: (context, index) {
                  return _buildSourceViewSubtitleTile(_sourceViewEntries[index], index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a source view subtitle tile for editing
  Widget _buildSourceViewSubtitleTile(SubtitleEntry entry, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index number (editable)
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: entry.index,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                entry.index = value;
                _onSourceViewContentChanged();
              },
            ),
          ),
          const SizedBox(height: 4),
          // Timecode line (editable)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start time
              IntrinsicWidth(
                child: TextFormField(
                  initialValue: entry.startTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    entry.startTime = value;
                    _onSourceViewContentChanged();
                  },
                ),
              ),
              Text(
                ' --> ',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontFamily: 'monospace',
                ),
              ),
              // End time
              IntrinsicWidth(
                child: TextFormField(
                  initialValue: entry.endTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    entry.endTime = value;
                    _onSourceViewContentChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Subtitle text (editable, multiline)
          TextFormField(
            initialValue: entry.text,
            maxLines: null,
            inputFormatters: [
              UnicodeTextInputFormatter(),
            ],
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              entry.text = value;
              _onSourceViewContentChanged();
            },
          ),
          const SizedBox(height: 16), // Space between entries like in SRT format
        ],
      ),
    );
  }
}
