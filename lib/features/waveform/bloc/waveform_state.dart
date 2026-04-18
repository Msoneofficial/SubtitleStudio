import 'package:equatable/equatable.dart';
import 'package:subtitle_studio/features/waveform/models/waveform_sample.dart';

/// States for waveform BLoC
abstract class WaveformState extends Equatable {
  const WaveformState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no waveform loaded
class WaveformInitial extends WaveformState {
  const WaveformInitial();
}

/// Loading audio file and processing
class WaveformLoading extends WaveformState {
  final String filePath;
  final double progress; // 0.0 to 1.0

  const WaveformLoading(this.filePath, {this.progress = 0.0});

  @override
  List<Object?> get props => [filePath, progress];
}

/// Waveform loaded and ready
class WaveformReady extends WaveformState {
  final WaveformBuffer buffer;
  final int currentZoomIndex;
  final double scrollPosition; // in pixels
  final Duration playbackPosition;
  final bool autoScroll;
  final double viewportWidth; // in pixels
  final String? sourceFilePath;
  final double verticalZoom; // 1.0 = 100%, 2.0 = 200% amplitude
  final int? subtitleCollectionId; // For saving zoom preferences
  
  // Time edit mode fields
  final bool isEditMode;
  final int? editingSubtitleIndex;
  final Duration? tempStartTime;
  final Duration? tempEndTime;
  
  // Add line mode fields
  final bool isAddLineMode;
  final Duration? addLineStartTime;
  final Duration? addLineEndTime;
  
  // Overlap toggle
  final bool allowOverlap;
  
  // Magnet snap toggle
  final bool magnetSnapEnabled;

  const WaveformReady({
    required this.buffer,
    required this.currentZoomIndex,
    this.scrollPosition = 0.0,
    this.playbackPosition = Duration.zero,
    this.autoScroll = true,
    this.viewportWidth = 800.0,
    this.sourceFilePath,
    this.verticalZoom = 1.7, // Default 170% for better visibility
    this.subtitleCollectionId,
    this.isEditMode = false,
    this.editingSubtitleIndex,
    this.tempStartTime,
    this.tempEndTime,
    this.isAddLineMode = false,
    this.addLineStartTime,
    this.addLineEndTime,
    this.allowOverlap = false, // Default: prevent overlap
    this.magnetSnapEnabled = true, // Default: magnet snap enabled
  });

  /// Get current zoom level
  ZoomLevel get currentZoomLevel => buffer.zoomLevels[currentZoomIndex];

  /// Get samples per pixel for current zoom
  int get samplesPerPixel => currentZoomLevel.samplesPerPixel;

  /// Get total width in pixels at current zoom
  double get totalWidth =>
      (buffer.rawData.totalSamples / samplesPerPixel).toDouble();

  /// Get visible time range based on scroll position and viewport
  Duration get visibleStartTime {
    final startSample = (scrollPosition * samplesPerPixel).round();
    return Duration(
      microseconds: (startSample * 1000000 / buffer.sampleRate).round(),
    );
  }

  Duration get visibleEndTime {
    final endSample =
        ((scrollPosition + viewportWidth) * samplesPerPixel).round();
    return Duration(
      microseconds: (endSample * 1000000 / buffer.sampleRate).round(),
    );
  }

  /// Convert time to pixel position
  double timeToPixel(Duration time) {
    final sample = (time.inMicroseconds * buffer.sampleRate / 1000000).round();
    return sample / samplesPerPixel;
  }

  /// Convert pixel position to time
  Duration pixelToTime(double pixel) {
    final sample = (pixel * samplesPerPixel).round();
    return Duration(
      microseconds: (sample * 1000000 / buffer.sampleRate).round(),
    );
  }

  /// Check if can zoom in (increase detail = decrease index, go to lower zoom levels)
  bool get canZoomIn => currentZoomIndex > 0;

  /// Check if can zoom out (decrease detail = increase index, go to higher zoom levels)
  bool get canZoomOut => currentZoomIndex < buffer.zoomLevelCount - 1;

  WaveformReady copyWith({
    WaveformBuffer? buffer,
    int? currentZoomIndex,
    double? scrollPosition,
    Duration? playbackPosition,
    bool? autoScroll,
    double? viewportWidth,
    String? sourceFilePath,
    double? verticalZoom,
    int? subtitleCollectionId,
    bool? isEditMode,
    int? editingSubtitleIndex,
    Duration? tempStartTime,
    Duration? tempEndTime,
    bool? isAddLineMode,
    Duration? addLineStartTime,
    Duration? addLineEndTime,
    bool? allowOverlap,
    bool? magnetSnapEnabled,
    bool clearEditingSubtitleIndex = false,
    bool clearTempStartTime = false,
    bool clearTempEndTime = false,
    bool clearAddLineStartTime = false,
    bool clearAddLineEndTime = false,
  }) {
    return WaveformReady(
      buffer: buffer ?? this.buffer,
      currentZoomIndex: currentZoomIndex ?? this.currentZoomIndex,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      autoScroll: autoScroll ?? this.autoScroll,
      viewportWidth: viewportWidth ?? this.viewportWidth,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      verticalZoom: verticalZoom ?? this.verticalZoom,
      subtitleCollectionId: subtitleCollectionId ?? this.subtitleCollectionId,
      isEditMode: isEditMode ?? this.isEditMode,
      editingSubtitleIndex: clearEditingSubtitleIndex ? null : (editingSubtitleIndex ?? this.editingSubtitleIndex),
      tempStartTime: clearTempStartTime ? null : (tempStartTime ?? this.tempStartTime),
      tempEndTime: clearTempEndTime ? null : (tempEndTime ?? this.tempEndTime),
      isAddLineMode: isAddLineMode ?? this.isAddLineMode,
      addLineStartTime: clearAddLineStartTime ? null : (addLineStartTime ?? this.addLineStartTime),
      addLineEndTime: clearAddLineEndTime ? null : (addLineEndTime ?? this.addLineEndTime),
      allowOverlap: allowOverlap ?? this.allowOverlap,
      magnetSnapEnabled: magnetSnapEnabled ?? this.magnetSnapEnabled,
    );
  }

  @override
  List<Object?> get props => [
        buffer,
        currentZoomIndex,
        scrollPosition,
        playbackPosition,
        autoScroll,
        viewportWidth,
        sourceFilePath,
        verticalZoom,
        subtitleCollectionId,
        isEditMode,
        editingSubtitleIndex,
        tempStartTime,
        tempEndTime,
        isAddLineMode,
        addLineStartTime,
        addLineEndTime,
        allowOverlap,
        magnetSnapEnabled,
      ];
}

/// Error state
class WaveformError extends WaveformState {
  final String message;
  final String? filePath;

  const WaveformError(this.message, {this.filePath});

  @override
  List<Object?> get props => [message, filePath];
}
