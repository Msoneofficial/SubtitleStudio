import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:subtitle_studio/features/waveform/bloc/waveform_bloc.dart';
import 'package:subtitle_studio/features/waveform/bloc/waveform_state.dart';
import 'package:subtitle_studio/features/waveform/bloc/waveform_event.dart';
import 'package:subtitle_studio/features/waveform/widgets/waveform_painter.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/themes/theme_provider.dart';
import 'package:subtitle_studio/widgets/settings_sheet.dart';
import 'package:subtitle_studio/utils/time_parser.dart';
import 'package:subtitle_studio/database/database_helper.dart' as db_helper;
import 'package:subtitle_studio/services/checkpoint_manager.dart';

/// Main waveform visualization widget with interaction support
class WaveformWidget extends StatefulWidget {
  final List<SubtitleLine> subtitles;
  final Duration? playbackPosition;
  final Function(Duration)? onSeek;
  final Function(int)? onSubtitleHighlight; // Callback to highlight subtitle in list
  final Function()? onSubtitlesUpdated; // Callback when subtitles are updated (for refreshing parent)
  final Function(Duration startTime, Duration endTime)? onAddLineConfirmed; // Callback when add line is confirmed with selected times
  final double height;
  final int? subtitleCollectionId; // For database updates
  final int? sessionId; // For checkpoint creation
  final int? highlightedSubtitleIndex; // Index of currently highlighted subtitle (0-based)

  const WaveformWidget({
    super.key,
    required this.subtitles,
    this.playbackPosition,
    this.onSeek,
    this.onSubtitleHighlight,
    this.onSubtitlesUpdated,
    this.onAddLineConfirmed,
    this.height = 180.0,
    this.subtitleCollectionId,
    this.sessionId,
    this.highlightedSubtitleIndex,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  // Cache current subtitles for change detection
  List<SubtitleLine> _currentSubtitles = [];
  
  // For detecting double taps on subtitle boxes (single tap → double tap now)
  int? _lastTappedSubtitleIndex;
  DateTime? _lastTapTime;
  static const _doubleTapDuration = Duration(milliseconds: 500);
  
  // For detecting double taps on empty waveform areas
  DateTime? _lastWaveformTapTime;
  
  // For detecting double taps/clicks on playhead
  DateTime? _lastPlayheadTapTime;
  
  // For dragging time adjustment bars (edit mode)
  bool _isDraggingStartBar = false;
  bool _isDraggingEndBar = false;
  
  // For dragging add line overlay bars
  bool _isDraggingAddLineStartBar = false;
  bool _isDraggingAddLineEndBar = false;
  
  // For moving entire overlays
  bool _isMovingEditOverlay = false;
  bool _isMovingAddLineOverlay = false;
  double? _overlayDragStartX;
  Duration? _overlayDragOriginalStart;
  Duration? _overlayDragOriginalEnd;
  
  // For waveform scrolling
  double? _lastScrollDragPosition;
  
  // Static variables for mouse double-click (persist across rebuilds)
  static DateTime? _staticLastMouseClickTime;
  static Offset? _staticLastMouseClickPosition;
  static int? _staticLastMouseClickSubtitleIndex;

  @override
  void initState() {
    super.initState();
    // Initialize current subtitles from widget
    _currentSubtitles = List.from(widget.subtitles);
  }

  @override
  void didUpdateWidget(WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update playback position if changed
    if (widget.playbackPosition != oldWidget.playbackPosition &&
        widget.playbackPosition != null) {
      context.read<WaveformBloc>().add(
            UpdatePlaybackPosition(widget.playbackPosition!),
          );
    }
    
    // Check if subtitles changed and update internal cache
    if (widget.subtitles != oldWidget.subtitles) {
      _updateSubtitlesInternal(widget.subtitles);
    }
  }
  
  /// Update subtitles and force repaint
  /// This method should be called externally when subtitle list changes
  void updateSubtitles(List<SubtitleLine> newSubtitles) {
    if (!mounted) return;
    
    _updateSubtitlesInternal(newSubtitles);
  }
  
  /// Internal method to update subtitles and trigger repaint
  void _updateSubtitlesInternal(List<SubtitleLine> newSubtitles) {
    // Check if subtitles actually changed
    bool hasChanges = false;
    
    if (_currentSubtitles.length != newSubtitles.length) {
      hasChanges = true;
    } else {
      // Compare subtitle content for changes
      for (int i = 0; i < _currentSubtitles.length; i++) {
        final current = _currentSubtitles[i];
        final newSub = newSubtitles[i];
        
        if (current.index != newSub.index ||
            current.startTime != newSub.startTime ||
            current.endTime != newSub.endTime ||
            current.original != newSub.original ||
            current.edited != newSub.edited ||
            current.marked != newSub.marked) {
          hasChanges = true;
          break;
        }
      }
    }
    
    if (hasChanges) {
      setState(() {
        _currentSubtitles = List.from(newSubtitles);
      });
      
      // Force waveform repaint
      context.read<WaveformBloc>().add(const ForceRepaint());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaveformBloc, WaveformState>(
      builder: (context, state) {
        if (state is WaveformInitial) {
          return _buildEmptyState();
        } else if (state is WaveformLoading) {
          return _buildLoadingState(state);
        } else if (state is WaveformError) {
          return _buildErrorState(state);
        } else if (state is WaveformReady) {
          return _buildWaveformView(state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.graphic_eq,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No waveform loaded',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(WaveformLoading state) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final brightness = Theme.of(context).brightness;
    
    // Use white for dark/classic themes, primary color for light theme
    final loaderColor = (brightness == Brightness.dark || themeProvider.themeMode == ThemeMode.system)
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loader13 widget
            SizedBox(
              height: 60,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return _BouncingDot(
                      delay: Duration(milliseconds: i * 100),
                      color: loaderColor,
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Generating waveform...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WaveformError state) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading waveform',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: widget.height - 140, // Reserve space for icon and title
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveformView(WaveformReady state) {
    // Update viewport width when widget size changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          // Account for border and vertical zoom bar width
          final width = renderBox.size.width - 50; // 50px for vertical zoom bar and borders
          if (width != state.viewportWidth) {
            context.read<WaveformBloc>().add(UpdateViewportWidth(width));
          }
        }
      }
    });

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Horizontal bar with zoom controls on left and menu button box on right
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate width for left section (total width - menu button width)
              final leftSectionWidth = constraints.maxWidth - 48;
              final isMobile = MediaQuery.of(context).size.width <= 600;
              final spacing = isMobile ? 1.0 : 8.0;
              final smallSpacing = isMobile ? 0.0 : 4.0;
              
              return Row(
                children: [
                  // Left side: Narrower zoom controls bar
                  SizedBox(
                    width: leftSectionWidth,
                    child: Container(
                      height: 40,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.surface,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Zoom out button (- icon for less detail)
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        tooltip: 'Zoom Out',
                        onPressed: state.canZoomOut
                            ? () => context.read<WaveformBloc>().add(const ZoomOut())
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      // Zoom slider (only on desktop/tablet)
                      if (MediaQuery.of(context).size.width > 600)
                        SizedBox(
                          width: 120,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              activeTrackColor: Colors.orange,
                              inactiveTrackColor: Colors.grey[700],
                              thumbColor: Colors.orange,
                            ),
                            child: Slider(
                              // Invert value: slider right (max) = index 0 (zoomed in), slider left (min) = max index (zoomed out)
                              value: (state.buffer.zoomLevelCount - 1 - state.currentZoomIndex).toDouble(),
                              min: 0,
                              max: (state.buffer.zoomLevelCount - 1).toDouble(),
                              divisions: state.buffer.zoomLevelCount > 1 ? state.buffer.zoomLevelCount - 1 : null,
                              onChanged: state.buffer.zoomLevelCount > 1 ? (value) {
                                // Convert slider value back to zoom index
                                final newIndex = state.buffer.zoomLevelCount - 1 - value.round();
                                final diff = newIndex - state.currentZoomIndex;
                                if (diff < 0) {
                                  // Index decreased = zoom in (more detail)
                                  for (int i = 0; i < -diff; i++) {
                                    context.read<WaveformBloc>().add(const ZoomIn());
                                  }
                                } else if (diff > 0) {
                                  // Index increased = zoom out (less detail)
                                  for (int i = 0; i < diff; i++) {
                                    context.read<WaveformBloc>().add(const ZoomOut());
                                  }
                                }
                              } : null,
                            ),
                          ),
                        ),
                      if (MediaQuery.of(context).size.width > 600) SizedBox(width: smallSpacing),
                      // Zoom in button (+ icon for more detail)
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'Zoom In',
                        onPressed: state.canZoomIn
                            ? () => context.read<WaveformBloc>().add(const ZoomIn())
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      SizedBox(width: spacing),
                      // Zoom level indicator (as percentage)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          // Convert to percentage: 0% = most zoomed out, 100% = most zoomed in
                          // Since lower index = more detail, we reverse: (maxIndex - currentIndex) / maxIndex * 100
                          '${(((state.buffer.zoomLevelCount - 1 - state.currentZoomIndex) / (state.buffer.zoomLevelCount - 1)) * 100).round()}%',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: spacing),
                      // Vertical divider
                      Container(
                        width: 1,
                        height: 24,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      SizedBox(width: spacing),
                      // Overlap toggle button
                      IconButton(
                        icon: Icon(
                          Icons.swap_horiz,
                          size: 20,
                          color: state.allowOverlap ? Colors.orange : Colors.grey,
                        ),
                        tooltip: state.allowOverlap ? 'Overlap Enabled' : 'Overlap Disabled',
                        onPressed: () => context.read<WaveformBloc>().add(const ToggleOverlapMode()),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      if (smallSpacing > 0) SizedBox(width: smallSpacing),
                      // Magnet snap button
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/magnet-solid.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            state.magnetSnapEnabled ? Colors.red : Colors.grey,
                            BlendMode.srcIn,
                          ),
                        ),
                        tooltip: state.magnetSnapEnabled ? 'Magnet Snap Enabled' : 'Magnet Snap Disabled',
                        onPressed: () => context.read<WaveformBloc>().add(const ToggleMagnetSnap()),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      if (smallSpacing > 0) SizedBox(width: smallSpacing),
                      // Add line button (hidden when in edit or add line mode)
                      if (!state.isEditMode && !state.isAddLineMode)
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            size: 20,
                            color: Color(0xFF00695C), // Dark teal - matches add line overlay
                          ),
                          tooltip: 'Add New Subtitle Line',
                          onPressed: () => _triggerAddLineMode(state),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      if (!state.isEditMode && !state.isAddLineMode && smallSpacing > 0) 
                        SizedBox(width: smallSpacing),
                      SizedBox(width: spacing),
                      // Apply and Cancel buttons (shown when in edit mode)
                      if (state.isEditMode) ...[
                        IconButton(
                          icon: const Icon(Icons.check, size: 20, color: Colors.green),
                          tooltip: 'Apply Time Changes',
                          onPressed: () => _applyTimeChanges(state),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        if (smallSpacing > 0) SizedBox(width: smallSpacing),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Colors.red),
                          tooltip: 'Cancel Edit Mode',
                          onPressed: () => context.read<WaveformBloc>().add(const ExitTimeEditMode()),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        if (smallSpacing > 0) SizedBox(width: smallSpacing),
                      ],
                      // Add and Close buttons (shown when in add line mode)
                      if (state.isAddLineMode) ...[
                        IconButton(
                          icon: const Icon(Icons.check, size: 20, color: Colors.green),
                          tooltip: 'Add Line with Selected Times',
                          onPressed: () => _confirmAddLine(state),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        if (smallSpacing > 0) SizedBox(width: smallSpacing),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Colors.red),
                          tooltip: 'Cancel Add Line Mode',
                          onPressed: () => context.read<WaveformBloc>().add(const ExitAddLineMode()),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        if (smallSpacing > 0) SizedBox(width: smallSpacing),
                      ],
                    ],
                  ),
                ),
              ),
              // Right side: Menu button box (matches vertical zoom bar width)
              Container(
                width: 48,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1,
                    ),
                  ),
                ),
                child: Center(
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    tooltip: 'Waveform Options',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onSelected: (value) {
                      if (value == 'toggle_autoscroll') {
                        context.read<WaveformBloc>().add(const ToggleAutoScroll());
                      } else if (value == 'settings') {
                        _openWaveformSettings();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'toggle_autoscroll',
                        child: Row(
                          children: [
                            Icon(
                              state.autoScroll ? Icons.sync : Icons.sync_disabled,
                              size: 20,
                              color: state.autoScroll ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(state.autoScroll ? 'Disable Auto-Scroll' : 'Enable Auto-Scroll'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, size: 20),
                            SizedBox(width: 12),
                            Text('Waveform Settings'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                ],
              );
            },
          ),
          // Waveform display with vertical zoom on the right
          Expanded(
            child: Row(
              children: [
                // Left side: Waveform with overlaid subtitle boxes
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Stack(
                      children: [
                        // Waveform background with tap detection
                        ClipRect(
                          child: Listener(
                            onPointerSignal: (event) {
                              if (event is PointerScrollEvent) {
                                _handleScroll(event, state);
                              }
                            },
                            onPointerDown: (event) {
                              // Handle mouse clicks (primary button for double-click, secondary for add line mode)
                              if (event.kind == PointerDeviceKind.mouse) {
                                if (event.buttons == 1) {
                                  // Primary button (left click)
                                  _handleMouseClick(event, state);
                                } else if (event.buttons == 2) {
                                  // Secondary button (right click) - prepare for add line mode
                                  _handleMouseRightClick(event, state);
                                }
                              }
                            },
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (details) => _handleTapUp(details, state),
                              onLongPressStart: (details) => _handleLongPressStart(details, state),
                              onLongPressMoveUpdate: (details) => _handleLongPressMoveUpdate(details, state),
                              onLongPressEnd: (details) => _handleLongPressEnd(details, state),
                              onPanStart: (details) => _handleWaveformPanStart(details, state),
                              onPanUpdate: (details) => _handleWaveformPanUpdate(details, state),
                              onPanEnd: (details) => _handleWaveformPanEnd(),
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: WaveformPainter(
                                  zoomLevel: state.currentZoomLevel,
                                  scrollOffset: state.scrollPosition,
                                  playbackPosition: state.playbackPosition,
                                  subtitles: _currentSubtitles,
                                  sampleRate: state.buffer.sampleRate,
                                  samplesPerPixel: state.samplesPerPixel,
                                  verticalZoom: state.verticalZoom,
                                  waveformColor: _getWaveformColor(context),
                                  subtitleColor: Theme.of(context).colorScheme.primary,
                                  playbackColor: Colors.red,
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  showSubtitlesOnly: false,
                                  showWaveformOnly: true,
                                  subtitleHighlightColor: _getSubtitleHighlightColor(context),
                                  showPlaybackIndicator: true,
                                  isEditMode: state.isEditMode,
                                  editingSubtitleIndex: state.editingSubtitleIndex,
                                  tempStartTime: state.tempStartTime,
                                  tempEndTime: state.tempEndTime,
                                  isAddLineMode: state.isAddLineMode,
                                  addLineStartTime: state.addLineStartTime,
                                  addLineEndTime: state.addLineEndTime,
                                  highlightedSubtitleIndex: widget.highlightedSubtitleIndex,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Subtitle boxes overlaid on top (visual only, no interaction)
                        IgnorePointer(
                          child: ClipRect(
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: WaveformPainter(
                                  zoomLevel: state.currentZoomLevel,
                                  scrollOffset: state.scrollPosition,
                                  playbackPosition: state.playbackPosition,
                                  subtitles: _currentSubtitles,
                                  sampleRate: state.buffer.sampleRate,
                                  samplesPerPixel: state.samplesPerPixel,
                                  verticalZoom: state.verticalZoom,
                                  waveformColor: _getWaveformColor(context),
                                  subtitleColor: Theme.of(context).colorScheme.primary,
                                  playbackColor: Colors.red,
                                  backgroundColor: Colors.transparent,
                                  showSubtitlesOnly: true,
                                  showWaveformOnly: false,
                                  subtitleHighlightColor: _getSubtitleHighlightColor(context),
                                  showPlaybackIndicator: false,
                                  isEditMode: state.isEditMode,
                                  editingSubtitleIndex: state.editingSubtitleIndex,
                                tempStartTime: state.tempStartTime,
                                tempEndTime: state.tempEndTime,
                                isAddLineMode: state.isAddLineMode,
                                addLineStartTime: state.addLineStartTime,
                                addLineEndTime: state.addLineEndTime,
                                highlightedSubtitleIndex: widget.highlightedSubtitleIndex,
                              ),
                            ),
                          ),
                        ),
                        // Time position overlay
                        Positioned(
                          left: 12,
                          bottom: 1,
                          child: GestureDetector(
                            onTap: () => _copyTimeToClipboard(state),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatDisplayTime(state),
                                style: TextStyle(
                                  color: Color(0x99EE9B00),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  fontFamily: GoogleFonts.spaceMono().fontFamily,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right side: Vertical zoom control
                Container(
                  width: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.surface,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Zoom in button (increase amplitude)
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        tooltip: 'Increase Amplitude',
                        onPressed: state.verticalZoom < 3.0
                            ? () {
                                final newZoom = (state.verticalZoom + 0.1).clamp(0.5, 3.0);
                                context.read<WaveformBloc>().add(UpdateVerticalZoom(newZoom));
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(state.verticalZoom * 100).round()}%',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      // Zoom out button (decrease amplitude)
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        tooltip: 'Decrease Amplitude',
                        onPressed: state.verticalZoom > 0.5
                            ? () {
                                final newZoom = (state.verticalZoom - 0.1).clamp(0.5, 3.0);
                                context.read<WaveformBloc>().add(UpdateVerticalZoom(newZoom));
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get waveform color based on current theme
  Color _getWaveformColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final brightness = Theme.of(context).brightness;
    
    // For dark mode or classic theme, use blue
    if (brightness == Brightness.dark || themeProvider.themeMode == ThemeMode.system) {
      return Colors.blue.shade400;
    }
    
    // For light mode, use theme secondary color
    return Theme.of(context).colorScheme.secondary;
  }

  /// Get subtitle highlight color for waveform background regions
  Color _getSubtitleHighlightColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    // Use a more vibrant contrasting color
    if (brightness == Brightness.dark) {
      return Colors.amber.shade600.withOpacity(0.4);
    }
    
    return Colors.orange.shade400.withOpacity(0.45);
  }

  void _handleScroll(PointerScrollEvent event, WaveformReady state) {
    // Handle mouse wheel scroll
    if (event.scrollDelta.dy != 0) {
      // Horizontal scroll with mouse wheel
      final newScrollPosition =
          state.scrollPosition + event.scrollDelta.dy * 0.5;
      context.read<WaveformBloc>().add(
            ScrollSeekToTime(newScrollPosition),
          );
      
      // Calculate center viewport time and seek video
      final centerPixel = newScrollPosition + state.viewportWidth / 2;
      final centerTime = state.pixelToTime(centerPixel);
      widget.onSeek?.call(centerTime);
    }
  }

  // Waveform drag-scrolling handlers (also handles bar dragging and overlay moving)
  void _handleWaveformPanStart(DragStartDetails details, WaveformReady state) {
    final panX = details.localPosition.dx;
    const barTolerance = 20.0;
    
    // Check if we're in edit mode and starting pan near a draggable bar
    if (state.isEditMode && state.editingSubtitleIndex != null) {
      final subtitle = _currentSubtitles[state.editingSubtitleIndex!];
      final startTime = state.tempStartTime ?? parseTimeString(subtitle.startTime);
      final endTime = state.tempEndTime ?? parseTimeString(subtitle.endTime);
      
      final startPixel = state.timeToPixel(startTime) - state.scrollPosition;
      final endPixel = state.timeToPixel(endTime) - state.scrollPosition;
      
      // If pan starts near a bar, enable bar dragging mode
      if ((panX - startPixel).abs() < barTolerance) {
        setState(() => _isDraggingStartBar = true);
        return;
      } else if ((panX - endPixel).abs() < barTolerance) {
        setState(() => _isDraggingEndBar = true);
        return;
      }
      
      // Check if pan starts inside the overlay (for moving entire overlay)
      if (panX >= startPixel && panX <= endPixel) {
        setState(() {
          _isMovingEditOverlay = true;
          _overlayDragStartX = panX;
          _overlayDragOriginalStart = startTime;
          _overlayDragOriginalEnd = endTime;
        });
        return;
      }
    }
    
    // Check if we're in add line mode and starting pan near a draggable bar
    if (state.isAddLineMode && state.addLineStartTime != null && state.addLineEndTime != null) {
      final startPixel = state.timeToPixel(state.addLineStartTime!) - state.scrollPosition;
      final endPixel = state.timeToPixel(state.addLineEndTime!) - state.scrollPosition;
      
      // If pan starts near a bar, enable bar dragging mode
      if ((panX - startPixel).abs() < barTolerance) {
        setState(() => _isDraggingAddLineStartBar = true);
        return;
      } else if ((panX - endPixel).abs() < barTolerance) {
        setState(() => _isDraggingAddLineEndBar = true);
        return;
      }
      
      // Check if pan starts inside the overlay (for moving entire overlay)
      if (panX >= startPixel && panX <= endPixel) {
        setState(() {
          _isMovingAddLineOverlay = true;
          _overlayDragStartX = panX;
          _overlayDragOriginalStart = state.addLineStartTime;
          _overlayDragOriginalEnd = state.addLineEndTime;
        });
        return;
      }
    }
    
    // Normal waveform scrolling
    _lastScrollDragPosition = details.globalPosition.dx;
  }

  void _handleWaveformPanUpdate(DragUpdateDetails details, WaveformReady state) {
    final tapX = details.localPosition.dx;
    final pixelPosition = state.scrollPosition + tapX;
    final newTime = state.pixelToTime(pixelPosition);
    
    // Handle moving edit overlay
    if (_isMovingEditOverlay && _overlayDragStartX != null && _overlayDragOriginalStart != null && _overlayDragOriginalEnd != null) {
      final dragDelta = tapX - _overlayDragStartX!;
      final timeDelta = state.pixelToTime(state.scrollPosition + dragDelta) - state.pixelToTime(state.scrollPosition);
      
      var newStart = _overlayDragOriginalStart! + timeDelta;
      var newEnd = _overlayDragOriginalEnd! + timeDelta;
      
      // Apply overlap prevention and magnet snap
      final constrained = _constrainTimeRange(
        newStart, 
        newEnd, 
        state, 
        excludeIndex: state.editingSubtitleIndex,
        isMovingOverlay: true,
      );
      newStart = constrained.$1;
      newEnd = constrained.$2;
      
      context.read<WaveformBloc>().add(UpdateTempStartTime(newStart));
      context.read<WaveformBloc>().add(UpdateTempEndTime(newEnd));
      return;
    }
    
    // Handle moving add line overlay
    if (_isMovingAddLineOverlay && _overlayDragStartX != null && _overlayDragOriginalStart != null && _overlayDragOriginalEnd != null) {
      final dragDelta = tapX - _overlayDragStartX!;
      final timeDelta = state.pixelToTime(state.scrollPosition + dragDelta) - state.pixelToTime(state.scrollPosition);
      
      var newStart = _overlayDragOriginalStart! + timeDelta;
      var newEnd = _overlayDragOriginalEnd! + timeDelta;
      
      // Apply overlap prevention and magnet snap
      final constrained = _constrainTimeRange(
        newStart, 
        newEnd, 
        state,
        isMovingOverlay: true,
      );
      newStart = constrained.$1;
      newEnd = constrained.$2;
      
      context.read<WaveformBloc>().add(UpdateAddLineStartTime(newStart));
      context.read<WaveformBloc>().add(UpdateAddLineEndTime(newEnd));
      return;
    }
    
    // Handle edit mode bar dragging
    if (_isDraggingStartBar) {
      var adjustedTime = newTime;
      
      // Get current end time
      final currentEnd = state.tempEndTime ?? (state.editingSubtitleIndex != null 
          ? parseTimeString(_currentSubtitles[state.editingSubtitleIndex!].endTime)
          : Duration.zero);
      
      // Apply overlap prevention and magnet snap
      final constrained = _constrainTimeRange(
        adjustedTime, 
        currentEnd, 
        state,
        excludeIndex: state.editingSubtitleIndex,
      );
      adjustedTime = constrained.$1;
      
      context.read<WaveformBloc>().add(UpdateTempStartTime(adjustedTime));
      return;
    } else if (_isDraggingEndBar) {
      var adjustedTime = newTime;
      
      // Get current start time
      final currentStart = state.tempStartTime ?? (state.editingSubtitleIndex != null 
          ? parseTimeString(_currentSubtitles[state.editingSubtitleIndex!].startTime)
          : Duration.zero);
      
      // Apply overlap prevention and magnet snap
      final constrained = _constrainTimeRange(
        currentStart, 
        adjustedTime, 
        state,
        excludeIndex: state.editingSubtitleIndex,
      );
      adjustedTime = constrained.$2;
      
      context.read<WaveformBloc>().add(UpdateTempEndTime(adjustedTime));
      return;
    }
    
    // Handle add line mode bar dragging
    if (_isDraggingAddLineStartBar) {
      var adjustedTime = newTime;
      
      // Get current end time
      final currentEnd = state.addLineEndTime ?? newTime + const Duration(seconds: 2);
      
      // Apply overlap prevention and magnet snap
      final constrained = _constrainTimeRange(
        adjustedTime, 
        currentEnd, 
        state,
      );
      adjustedTime = constrained.$1;
      
      context.read<WaveformBloc>().add(UpdateAddLineStartTime(adjustedTime));
      return;
    } else if (_isDraggingAddLineEndBar) {
      var adjustedTime = newTime;
      
      // Get current start time
      final currentStart = state.addLineStartTime ?? Duration.zero;
      
      // Apply overlap prevention and magnet snap
      final constrained = _constrainTimeRange(
        currentStart, 
        adjustedTime, 
        state,
      );
      adjustedTime = constrained.$2;
      
      context.read<WaveformBloc>().add(UpdateAddLineEndTime(adjustedTime));
      return;
    }
    
    // Normal waveform scrolling
    if (_lastScrollDragPosition == null) return;
    
    final delta = details.globalPosition.dx - _lastScrollDragPosition!;
    final newScrollPosition = state.scrollPosition - delta;
    
    // Update scroll position and seek video to center viewport time
    context.read<WaveformBloc>().add(
      ScrollSeekToTime(newScrollPosition),
    );
    
    // Calculate center viewport time and seek video
    final centerPixel = newScrollPosition + state.viewportWidth / 2;
    final centerTime = state.pixelToTime(centerPixel);
    widget.onSeek?.call(centerTime);

    _lastScrollDragPosition = details.globalPosition.dx;
  }

  void _handleWaveformPanEnd() {
    // Reset all dragging flags
    if (_isMovingEditOverlay || _isMovingAddLineOverlay || 
        _isDraggingStartBar || _isDraggingEndBar ||
        _isDraggingAddLineStartBar || _isDraggingAddLineEndBar) {
      setState(() {
        _isMovingEditOverlay = false;
        _isMovingAddLineOverlay = false;
        _isDraggingStartBar = false;
        _isDraggingEndBar = false;
        _isDraggingAddLineStartBar = false;
        _isDraggingAddLineEndBar = false;
        _overlayDragStartX = null;
        _overlayDragOriginalStart = null;
        _overlayDragOriginalEnd = null;
      });
      return;
    }
    
    // Normal waveform scrolling cleanup
    _lastScrollDragPosition = null;
  }

  // Handle mouse click (for double-click detection to seek/highlight/add line)
  void _handleMouseClick(PointerDownEvent event, WaveformReady state) {
    final now = DateTime.now();
    final position = event.localPosition;
    
    // Check if click is on playhead
    if (position.dy <= 12) {
      final playheadX = _getPlayheadXPosition(state);
      
      if ((position.dx - playheadX).abs() <= 16) {
        // Click on playhead - check for double-click
        if (_staticLastMouseClickTime != null &&
            _staticLastMouseClickPosition != null &&
            now.difference(_staticLastMouseClickTime!) < const Duration(milliseconds: 500) &&
            (position - _staticLastMouseClickPosition!).distance < 20) {
          // Double-click on playhead - enter add line mode with 2-second default duration
          // Use viewport center time (where playhead visually appears)
          final startTime = _getViewportCenterTime(state);
          final endTime = startTime + const Duration(seconds: 2);
          
          context.read<WaveformBloc>().add(const EnterAddLineMode());
          context.read<WaveformBloc>().add(UpdateAddLineStartTime(startTime));
          context.read<WaveformBloc>().add(UpdateAddLineEndTime(endTime));
          _staticLastMouseClickTime = null;
          _staticLastMouseClickPosition = null;
          _staticLastMouseClickSubtitleIndex = null;
          return;
        } else {
          // Single click - remember for potential double-click
          _staticLastMouseClickTime = now;
          _staticLastMouseClickPosition = position;
          _staticLastMouseClickSubtitleIndex = null;
          return;
        }
      }
    }
    
    // Regular mouse click logic
    final subtitleIndex = _getSubtitleAtPosition(position, state);
    
    // Check for double-click (within 500ms, at similar position, and on same subtitle)
    if (_staticLastMouseClickTime != null &&
        _staticLastMouseClickPosition != null &&
        now.difference(_staticLastMouseClickTime!) < const Duration(milliseconds: 500) &&
        (position - _staticLastMouseClickPosition!).distance < 20 &&
        subtitleIndex == _staticLastMouseClickSubtitleIndex) {
      // Double-click detected
      
      if (subtitleIndex != null) {
        // Double-click on subtitle - seek and highlight
        final subtitle = _currentSubtitles[subtitleIndex];
        final startTime = parseTimeString(subtitle.startTime);
        widget.onSeek?.call(startTime);
        context.read<WaveformBloc>().add(SeekToTime(startTime));
        // Pass 1-based index (subtitle.index) for highlighting
        widget.onSubtitleHighlight?.call(subtitle.index);
      } else {
        // Double-click on waveform
        if (state.isEditMode) {
          // Exit edit mode if we're in it
          context.read<WaveformBloc>().add(const ExitTimeEditMode());
        } else if (state.isAddLineMode) {
          // Exit add line mode if we're in it
          context.read<WaveformBloc>().add(const ExitAddLineMode());
        } else {
          // Seek to position if not in edit mode
          _seekToPosition(position, state);
        }
      }
      
      // Reset for next potential double-click
      _staticLastMouseClickTime = null;
      _staticLastMouseClickPosition = null;
      _staticLastMouseClickSubtitleIndex = null;
    } else {
      // Single click - just remember for potential double-click
      _staticLastMouseClickTime = now;
      _staticLastMouseClickPosition = position;
      _staticLastMouseClickSubtitleIndex = subtitleIndex;
    }
  }

  // Handle mouse right-click (for entering edit mode on subtitle)
  void _handleMouseRightClick(PointerDownEvent event, WaveformReady state) {
    final position = event.localPosition;
    final subtitleIndex = _getSubtitleAtPosition(position, state);
    
    if (subtitleIndex != null) {
      // Right-click on subtitle - enter edit mode
      context.read<WaveformBloc>().add(EnterTimeEditMode(subtitleIndex));
    }
  }

  // Handle tap up - GestureDetector fires this only for actual taps (not after pans)
  void _handleTapUp(TapUpDetails details, WaveformReady state) {
    // Skip if this is a mouse click (handled by _handleMouseClick)
    // GestureDetector will fire onTapUp for both touch and mouse
    if (details.kind == PointerDeviceKind.mouse) {
      return;
    }
    
    final position = details.localPosition;
    final subtitleIndex = _getSubtitleAtPosition(position, state);
    
    if (subtitleIndex != null) {
      // Tapped on a subtitle box - check for double tap
      _handleSubtitleTapAtPosition(position, state, subtitleIndex);
    } else {
      // Tapped on empty area (waveform) - check for double tap
      _handleWaveformTapAtPosition(position, state);
    }
  }

  // Handle long press start - enter edit mode on subtitle or add line mode on playhead
  void _handleLongPressStart(LongPressStartDetails details, WaveformReady state) {
    final position = details.localPosition;
    
    // Check if long press is on the playhead arrow area (top 12 pixels)
    if (position.dy <= 12) {
      final playheadX = _getPlayheadXPosition(state);
      
      // Check if long press is within 16 pixels of the playhead
      if ((position.dx - playheadX).abs() <= 16) {
        // Long press on playhead - enter add line mode with 2-second default duration
        // Use viewport center time (where playhead visually appears)
        final startTime = _getViewportCenterTime(state);
        final endTime = startTime + const Duration(seconds: 2);
        
        context.read<WaveformBloc>().add(const EnterAddLineMode());
        context.read<WaveformBloc>().add(UpdateAddLineStartTime(startTime));
        context.read<WaveformBloc>().add(UpdateAddLineEndTime(endTime));
        return;
      }
    }
    
    // Check if long press is on a subtitle
    final subtitleIndex = _getSubtitleAtPosition(position, state);
    
    if (subtitleIndex != null) {
      // Long press on subtitle - enter edit mode
      context.read<WaveformBloc>().add(EnterTimeEditMode(subtitleIndex));
    }
  }

  // Handle long press move - not used in new implementation
  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details, WaveformReady state) {
    // Empty - we handle dragging in pan handlers
  }

  // Handle long press end - not used in new implementation
  void _handleLongPressEnd(LongPressEndDetails details, WaveformReady state) {
    // Empty - we handle cleanup in pan end
  }

  // Get playhead X position on screen
  double _getPlayheadXPosition(WaveformReady state) {
    final pixelsPerSec = state.buffer.sampleRate / state.samplesPerPixel;
    final playbackPixel = (state.playbackPosition.inMilliseconds / 1000.0) * pixelsPerSec;
    final centerPosition = state.viewportWidth / 2;
    final totalWidth = state.currentZoomLevel.pixelCount.toDouble();
    
    double playheadX;
    if (playbackPixel <= centerPosition) {
      playheadX = playbackPixel - state.scrollPosition;
    } else if (playbackPixel >= totalWidth - centerPosition) {
      playheadX = playbackPixel - state.scrollPosition;
    } else {
      playheadX = centerPosition;
    }
    return playheadX.clamp(0.0, state.viewportWidth);
  }

  // Get viewport center time
  Duration _getViewportCenterTime(WaveformReady state) {
    final centerPixel = state.scrollPosition + state.viewportWidth / 2;
    final centerSample = (centerPixel * state.samplesPerPixel).round();
    final centerMilliseconds = (centerSample * 1000 / state.buffer.sampleRate).round();
    return Duration(milliseconds: centerMilliseconds);
  }

  // Handle tap on waveform (empty area) - double tap to seek or exit edit mode or enter add line mode on playhead
  void _handleWaveformTapAtPosition(Offset localPosition, WaveformReady state) {
    final now = DateTime.now();
    
    // Check if tap is on playhead
    if (localPosition.dy <= 12) {
      final playheadX = _getPlayheadXPosition(state);
      
      if ((localPosition.dx - playheadX).abs() <= 16) {
        // Tap on playhead - check for double tap
        if (_lastPlayheadTapTime != null &&
            now.difference(_lastPlayheadTapTime!) < _doubleTapDuration) {
          // Double tap on playhead - enter add line mode with 2-second default duration
          // Use viewport center time (where playhead visually appears)
          final startTime = _getViewportCenterTime(state);
          final endTime = startTime + const Duration(seconds: 2);
          
          context.read<WaveformBloc>().add(const EnterAddLineMode());
          context.read<WaveformBloc>().add(UpdateAddLineStartTime(startTime));
          context.read<WaveformBloc>().add(UpdateAddLineEndTime(endTime));
          _lastPlayheadTapTime = null;
          return;
        } else {
          // Single tap - remember for potential double tap
          _lastPlayheadTapTime = now;
          return;
        }
      }
    }
    
    // Regular waveform double tap logic
    if (_lastWaveformTapTime != null &&
        now.difference(_lastWaveformTapTime!) < _doubleTapDuration) {
      // Double tap on waveform
      if (state.isEditMode) {
        // Exit edit mode if we're in it
        context.read<WaveformBloc>().add(const ExitTimeEditMode());
      } else if (state.isAddLineMode) {
        // Exit add line mode if we're in it
        context.read<WaveformBloc>().add(const ExitAddLineMode());
      } else {
        // Seek to position if not in edit mode
        _seekToPosition(localPosition, state);
      }
      _lastWaveformTapTime = null;
    } else {
      // Single tap - just remember for potential double tap
      _lastWaveformTapTime = now;
    }
  }

  /// Format the display time based on playback position or viewport center
  String _formatDisplayTime(WaveformReady state) {
    // Always show viewport center time (where user is looking)
    final centerPixel = state.scrollPosition + state.viewportWidth / 2;
    final centerSample = (centerPixel * state.samplesPerPixel).round();
    final centerMilliseconds = (centerSample * 1000 / state.buffer.sampleRate).round();
    final displayTime = Duration(milliseconds: centerMilliseconds);
    
    // Format time as HH:mm:ss,SSS (matching subtitle format with comma)
    final hours = displayTime.inHours.toString().padLeft(2, '0');
    final minutes = (displayTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (displayTime.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = (displayTime.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$milliseconds';
  }

  /// Copy the current time position to clipboard
  void _copyTimeToClipboard(WaveformReady state) {
    final timeString = _formatDisplayTime(state);
    Clipboard.setData(ClipboardData(text: timeString));
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Time copied: $timeString',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF323232), // Dark gray background
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 250,
      ),
    );
  }

  /// Open waveform settings in the settings sheet
  void _openWaveformSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SettingsSheet(initialSection: 'waveform'),
    );
  }

  /// Handle tap on subtitle box area (double tap seeks/highlights, long press enters edit mode)
  void _handleSubtitleTapAtPosition(Offset localPosition, WaveformReady state, int subtitleIndex) {
    final now = DateTime.now();
    final subtitle = _currentSubtitles[subtitleIndex];
    final startTime = parseTimeString(subtitle.startTime);
    
    // Check for double tap to seek and highlight
    if (_lastTappedSubtitleIndex == subtitleIndex &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < _doubleTapDuration) {
      // Double tap - seek to subtitle start and highlight in list
      widget.onSeek?.call(startTime);
      context.read<WaveformBloc>().add(SeekToTime(startTime));
      // Pass 1-based index (subtitle.index) for highlighting
      widget.onSubtitleHighlight?.call(subtitle.index);
      
      _lastTappedSubtitleIndex = null;
      _lastTapTime = null;
    } else {
      // Single tap - just remember for potential double tap
      _lastTappedSubtitleIndex = subtitleIndex;
      _lastTapTime = now;
    }
  }

  /// Seek to the tapped position
  void _seekToPosition(Offset localPosition, WaveformReady state) {
    final tapX = localPosition.dx;
    final pixelPosition = state.scrollPosition + tapX;
    final time = state.pixelToTime(pixelPosition);

    // Notify parent
    widget.onSeek?.call(time);

    // Update state
    context.read<WaveformBloc>().add(SeekToTime(time));
  }

  /// Detect which subtitle was tapped (returns subtitle index or null)
  int? _getSubtitleAtPosition(Offset localPosition, WaveformReady state) {
    final tapX = localPosition.dx;
    final pixelPosition = state.scrollPosition + tapX;
    final time = state.pixelToTime(pixelPosition);
    
    // Find subtitle that contains this time
    for (int i = 0; i < _currentSubtitles.length; i++) {
      final subtitle = _currentSubtitles[i];
      final startTime = parseTimeString(subtitle.startTime);
      final endTime = parseTimeString(subtitle.endTime);
      if (time >= startTime && time <= endTime) {
        return i;
      }
    }
    return null;
  }

  /// Apply magnet snap to nearby playhead or subtitle boundaries
  /// Returns adjusted time if snap occurred, or original time if no snap
  Duration _applyMagnetSnap(Duration time, WaveformReady state, {bool isStart = true, int? excludeIndex}) {
    if (!state.magnetSnapEnabled) return time;
    
    const snapThreshold = Duration(milliseconds: 150); // 150ms snap threshold (reverted to original)
    const minGap = Duration(milliseconds: 25); // 0.025s minimum gap between subtitles after snapping
    Duration closestTime = time;
    Duration minDistance = snapThreshold + const Duration(milliseconds: 1); // Set slightly higher to allow equal distance snaps
    bool snappedToPlayhead = false;
    
    // Check snap to playhead first (priority)
    final playheadTime = state.playbackPosition;
    final playheadDistance = (time - playheadTime).abs();
    if (playheadDistance <= snapThreshold) {
      closestTime = playheadTime;
      minDistance = playheadDistance;
      snappedToPlayhead = true;
    }
    
    // Check snap to subtitle boundaries with minimum gap enforcement
    // Only override playhead if subtitle boundary is significantly closer (at least 20ms closer)
    const playheadPriorityMargin = Duration(milliseconds: 20);
    for (int i = 0; i < _currentSubtitles.length; i++) {
      // Skip the subtitle being edited
      if (excludeIndex != null && i == excludeIndex) continue;
      
      final subtitle = _currentSubtitles[i];
      final subStart = parseTimeString(subtitle.startTime);
      final subEnd = parseTimeString(subtitle.endTime);
      
      // Check distance to start
      final startDistance = (time - subStart).abs();
      final requiredDistance = snappedToPlayhead ? minDistance - playheadPriorityMargin : minDistance;
      if (startDistance < requiredDistance) {
        // Apply minimum gap: if we're snapping start time to a subtitle boundary,
        // snap to end + minGap; if snapping end time, snap to start - minGap
        if (isStart) {
          closestTime = subEnd + minGap;
        } else {
          closestTime = subStart - minGap;
        }
        minDistance = startDistance;
        snappedToPlayhead = false;
      }
      
      // Check distance to end
      final endDistance = (time - subEnd).abs();
      final requiredDistanceEnd = snappedToPlayhead ? minDistance - playheadPriorityMargin : minDistance;
      if (endDistance < requiredDistanceEnd) {
        // Apply minimum gap: if we're snapping start time to a subtitle boundary,
        // snap to end + minGap; if snapping end time, snap to start - minGap
        if (isStart) {
          closestTime = subEnd + minGap;
        } else {
          closestTime = subStart - minGap;
        }
        minDistance = endDistance;
        snappedToPlayhead = false;
      }
    }
    
    return closestTime;
  }

  /// Constrain time range to avoid overlap (if allowOverlap is false)
  /// Returns adjusted start and end times
  (Duration, Duration) _constrainTimeRange(
    Duration startTime, 
    Duration endTime, 
    WaveformReady state, 
    {int? excludeIndex, 
    bool isMovingOverlay = false}
  ) {
    if (state.allowOverlap) {
      // Apply magnet snap if enabled
      final snappedStart = _applyMagnetSnap(startTime, state, isStart: true, excludeIndex: excludeIndex);
      final snappedEnd = _applyMagnetSnap(endTime, state, isStart: false, excludeIndex: excludeIndex);
      return (snappedStart, snappedEnd);
    }
    
    Duration constrainedStart = startTime;
    Duration constrainedEnd = endTime;
    
    // Find the closest boundaries that would cause overlap
    Duration? maxAllowedStart;
    Duration? minAllowedEnd;
    
    for (int i = 0; i < _currentSubtitles.length; i++) {
      // Skip the subtitle being edited
      if (excludeIndex != null && i == excludeIndex) continue;
      
      final subtitle = _currentSubtitles[i];
      final subStart = parseTimeString(subtitle.startTime);
      final subEnd = parseTimeString(subtitle.endTime);
      
      // Check if this subtitle would overlap with our range
      if (startTime < subEnd && endTime > subStart) {
        // There's an overlap - constrain the range
        if (isMovingOverlay) {
          // When moving entire overlay, stop at the nearest boundary
          if (startTime < subStart && endTime > subStart) {
            // Moving forward into a subtitle - stop at its start
            constrainedStart = startTime;
            constrainedEnd = subStart;
            return (constrainedStart, constrainedEnd);
          } else if (startTime < subEnd && endTime > subEnd) {
            // Moving backward into a subtitle - stop at its end
            constrainedStart = subEnd;
            constrainedEnd = endTime;
            return (constrainedStart, constrainedEnd);
          }
        } else {
          // When adjusting individual boundaries
          if (subEnd <= startTime) {
            // Subtitle is before our range - update max start
            maxAllowedStart = maxAllowedStart == null ? subEnd : (subEnd > maxAllowedStart ? subEnd : maxAllowedStart);
          }
          if (subStart >= endTime) {
            // Subtitle is after our range - update min end
            minAllowedEnd = minAllowedEnd == null ? subStart : (subStart < minAllowedEnd ? subStart : minAllowedEnd);
          } else if (subStart > startTime && subStart < endTime) {
            // Subtitle starts within our range - constrain end
            minAllowedEnd = subStart;
          } else if (subEnd > startTime && subEnd < endTime) {
            // Subtitle ends within our range - constrain start
            maxAllowedStart = subEnd;
          }
        }
      }
    }
    
    // Apply constraints
    if (maxAllowedStart != null && constrainedStart < maxAllowedStart) {
      constrainedStart = maxAllowedStart;
    }
    if (minAllowedEnd != null && constrainedEnd > minAllowedEnd) {
      constrainedEnd = minAllowedEnd;
    }
    
    // Ensure start < end
    if (constrainedStart >= constrainedEnd) {
      // If they cross, keep the original end and adjust start
      constrainedStart = constrainedEnd - const Duration(milliseconds: 100);
    }
    
    // Apply magnet snap to constrained values
    constrainedStart = _applyMagnetSnap(constrainedStart, state, isStart: true, excludeIndex: excludeIndex);
    constrainedEnd = _applyMagnetSnap(constrainedEnd, state, isStart: false, excludeIndex: excludeIndex);
    
    return (constrainedStart, constrainedEnd);
  }

  /// Format Duration to SRT timecode string (HH:mm:ss,SSS)
  String _formatDurationToSRT(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds = duration.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$milliseconds';
  }

  /// Apply time changes to database
  Future<void> _applyTimeChanges(WaveformReady state) async {
    if (!state.isEditMode || state.editingSubtitleIndex == null) return;
    if (widget.subtitleCollectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot update: No subtitle collection ID',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final subtitleIndex = state.editingSubtitleIndex!;
    if (subtitleIndex < 0 || subtitleIndex >= _currentSubtitles.length) return;
    
    final subtitle = _currentSubtitles[subtitleIndex];
    final currentStartTime = parseTimeString(subtitle.startTime);
    final currentEndTime = parseTimeString(subtitle.endTime);
    final newStartTime = state.tempStartTime ?? currentStartTime;
    final newEndTime = state.tempEndTime ?? currentEndTime;
    
    // Validate times
    if (newStartTime >= newEndTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Start time must be before end time',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Create a copy of the subtitle with BEFORE state for checkpoint
    final beforeSubtitle = SubtitleLine()
      ..index = subtitle.index
      ..startTime = subtitle.startTime
      ..endTime = subtitle.endTime
      ..original = subtitle.original
      ..edited = subtitle.edited
      ..marked = subtitle.marked
      ..comment = subtitle.comment
      ..resolved = subtitle.resolved;
    
    // Update subtitle with new times (AFTER state)
    final afterSubtitle = SubtitleLine()
      ..index = subtitle.index
      ..startTime = _formatDurationToSRT(newStartTime)
      ..endTime = _formatDurationToSRT(newEndTime)
      ..original = subtitle.original
      ..edited = subtitle.edited
      ..marked = subtitle.marked
      ..comment = subtitle.comment
      ..resolved = subtitle.resolved;
    
    // Update subtitle in database
    try {
      // Create checkpoint BEFORE updating (if sessionId is provided)
      if (widget.sessionId != null) {
        await CheckpointManager.createEditCheckpoint(
          sessionId: widget.sessionId!,
          subtitleCollectionId: widget.subtitleCollectionId!,
          beforeLine: beforeSubtitle,
          afterLine: afterSubtitle,
        );
      }
      
      // Apply changes to the actual subtitle
      subtitle.startTime = afterSubtitle.startTime;
      subtitle.endTime = afterSubtitle.endTime;
      
      // Save to database using the database helper
      final success = await db_helper.updateMultipleSubtitleLines(
        widget.subtitleCollectionId!,
        [subtitle],
      );
      
      if (!success) {
        throw Exception('Failed to update subtitle in database');
      }
      
      // Update internal cache
      setState(() {
        _currentSubtitles[subtitleIndex] = subtitle;
      });
      
      // Notify parent to refresh subtitle list and video player
      widget.onSubtitlesUpdated?.call();
      
      // Exit edit mode
      if (mounted) {
        context.read<WaveformBloc>().add(const ExitTimeEditMode());
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Time updated successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF323232),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating time: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFD32F2F),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Confirm add line and call callback with selected times
  void _confirmAddLine(WaveformReady state) {
    // Validate that both start and end times are set
    if (state.addLineStartTime == null || state.addLineEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please drag to select start and end times',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Exit add line mode
    context.read<WaveformBloc>().add(const ExitAddLineMode());
    
    // Call the callback with selected times
    widget.onAddLineConfirmed?.call(
      state.addLineStartTime!,
      state.addLineEndTime!,
    );
  }

  /// Trigger add line mode from toolbar button
  void _triggerAddLineMode(WaveformReady state) {
    // Use viewport center time (where user is currently looking)
    final startTime = _getViewportCenterTime(state);
    final endTime = startTime + const Duration(seconds: 2);
    
    context.read<WaveformBloc>().add(const EnterAddLineMode());
    context.read<WaveformBloc>().add(UpdateAddLineStartTime(startTime));
    context.read<WaveformBloc>().add(UpdateAddLineEndTime(endTime));
  }
}

/// Bouncing dot widget for Loader13-style animation
class _BouncingDot extends StatefulWidget {
  final Duration delay;
  final Color color;

  const _BouncingDot({
    required this.delay,
    required this.color,
  });

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -30 * _controller.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
