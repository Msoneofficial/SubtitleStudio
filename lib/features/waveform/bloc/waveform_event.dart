import 'package:equatable/equatable.dart';

/// Events for waveform BLoC
abstract class WaveformEvent extends Equatable {
  const WaveformEvent();

  @override
  List<Object?> get props => [];
}

/// Load audio from file path
class LoadAudioFile extends WaveformEvent {
  final String filePath;
  final int? subtitleCollectionId; // For caching waveform data
  final String? audioTrackId; // Selected audio track ID for multi-track videos

  const LoadAudioFile(this.filePath, {this.subtitleCollectionId, this.audioTrackId});

  @override
  List<Object?> get props => [filePath, subtitleCollectionId, audioTrackId];
}

/// Zoom in (increase samples per pixel)
class ZoomIn extends WaveformEvent {
  const ZoomIn();
}

/// Zoom out (decrease samples per pixel)
class ZoomOut extends WaveformEvent {
  const ZoomOut();
}

/// Set specific zoom level by index
class SetZoomLevel extends WaveformEvent {
  final int zoomIndex;

  const SetZoomLevel(this.zoomIndex);

  @override
  List<Object?> get props => [zoomIndex];
}

/// Update scroll position (in pixels)
class UpdateScrollPosition extends WaveformEvent {
  final double scrollPosition;

  const UpdateScrollPosition(this.scrollPosition);

  @override
  List<Object?> get props => [scrollPosition];
}

/// Update playback position (in time)
class UpdatePlaybackPosition extends WaveformEvent {
  final Duration position;

  const UpdatePlaybackPosition(this.position);

  @override
  List<Object?> get props => [position];
}

/// Seek to specific time
class SeekToTime extends WaveformEvent {
  final Duration time;

  const SeekToTime(this.time);

  @override
  List<Object?> get props => [time];
}

/// Toggle auto-scroll following playback
class ToggleAutoScroll extends WaveformEvent {
  const ToggleAutoScroll();
}

/// Update vertical zoom (amplitude)
class UpdateVerticalZoom extends WaveformEvent {
  final double zoom; // 0.5 = 50%, 1.0 = 100%, 2.0 = 200%

  const UpdateVerticalZoom(this.zoom);

  @override
  List<Object?> get props => [zoom];
}

/// Clear waveform data
class ClearWaveform extends WaveformEvent {
  const ClearWaveform();
}

/// Update viewport width (when widget resizes)
class UpdateViewportWidth extends WaveformEvent {
  final double width;

  const UpdateViewportWidth(this.width);

  @override
  List<Object?> get props => [width];
}

/// Enter time edit mode for a subtitle
class EnterTimeEditMode extends WaveformEvent {
  final int subtitleIndex;

  const EnterTimeEditMode(this.subtitleIndex);

  @override
  List<Object?> get props => [subtitleIndex];
}

/// Exit time edit mode without saving
class ExitTimeEditMode extends WaveformEvent {
  const ExitTimeEditMode();
}

/// Update temporary start time during edit
class UpdateTempStartTime extends WaveformEvent {
  final Duration startTime;

  const UpdateTempStartTime(this.startTime);

  @override
  List<Object?> get props => [startTime];
}

/// Update temporary end time during edit
class UpdateTempEndTime extends WaveformEvent {
  final Duration endTime;

  const UpdateTempEndTime(this.endTime);

  @override
  List<Object?> get props => [endTime];
}

/// Apply time changes and save to database
class ApplyTimeChanges extends WaveformEvent {
  const ApplyTimeChanges();
}

/// Force waveform repaint (e.g., when subtitles changed externally)
class ForceRepaint extends WaveformEvent {
  const ForceRepaint();
}

/// Enter add line mode
class EnterAddLineMode extends WaveformEvent {
  const EnterAddLineMode();
}

/// Exit add line mode without adding
class ExitAddLineMode extends WaveformEvent {
  const ExitAddLineMode();
}

/// Update temporary start time during add line mode
class UpdateAddLineStartTime extends WaveformEvent {
  final Duration startTime;

  const UpdateAddLineStartTime(this.startTime);

  @override
  List<Object?> get props => [startTime];
}

/// Update temporary end time during add line mode
class UpdateAddLineEndTime extends WaveformEvent {
  final Duration endTime;

  const UpdateAddLineEndTime(this.endTime);

  @override
  List<Object?> get props => [endTime];
}

/// Toggle overlap mode (allow overlapping with other subtitles)
class ToggleOverlapMode extends WaveformEvent {
  const ToggleOverlapMode();
}

/// Toggle magnet snap (snap to nearby playhead or subtitle)
class ToggleMagnetSnap extends WaveformEvent {
  const ToggleMagnetSnap();
}

/// Update scroll position and seek video to center viewport time
/// Used for manual scrolling to sync video with waveform position
class ScrollSeekToTime extends WaveformEvent {
  final double scrollPosition;

  const ScrollSeekToTime(this.scrollPosition);

  @override
  List<Object?> get props => [scrollPosition];
}
