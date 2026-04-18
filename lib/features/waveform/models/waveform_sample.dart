import 'dart:typed_data';

/// Represents min/max amplitude for a single pixel/point in the waveform
class WaveformSample {
  final double min;
  final double max;

  const WaveformSample(this.min, this.max);

  factory WaveformSample.zero() => const WaveformSample(0.0, 0.0);

  /// Create from raw sample value (normalized -1.0 to 1.0)
  factory WaveformSample.fromValue(double value) => WaveformSample(value, value);

  /// Merge two samples (useful for downsampling)
  WaveformSample merge(WaveformSample other) {
    return WaveformSample(
      min < other.min ? min : other.min,
      max > other.max ? max : other.max,
    );
  }

  @override
  String toString() => 'WaveformSample(min: $min, max: $max)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaveformSample && min == other.min && max == other.max;

  @override
  int get hashCode => Object.hash(min, max);
}

/// Raw waveform data containing all audio samples
class WaveformData {
  final int channels;
  final int sampleRate;
  final int totalSamples;
  final List<Int16List> rawSamples; // [channel][sample]

  WaveformData({
    required this.channels,
    required this.sampleRate,
    required this.totalSamples,
    required this.rawSamples,
  });

  /// Total duration of the audio
  Duration get duration => Duration(
        milliseconds: (totalSamples * 1000 / sampleRate).round(),
      );

  /// Get sample at specific time for a channel
  int? getSampleAtTime(Duration time, int channel) {
    if (channel < 0 || channel >= channels) return null;

    final sampleIndex = (time.inMicroseconds * sampleRate / 1000000).round();
    if (sampleIndex < 0 || sampleIndex >= totalSamples) return null;

    return rawSamples[channel][sampleIndex];
  }

  @override
  String toString() =>
      'WaveformData(channels: $channels, sampleRate: $sampleRate, samples: $totalSamples, duration: $duration)';
}

/// Zoom level data - pre-computed min/max samples for efficient rendering
class ZoomLevel {
  final int samplesPerPixel;
  final List<List<WaveformSample>> data; // [channel][pixel]

  ZoomLevel({
    required this.samplesPerPixel,
    required this.data,
  });

  int get channels => data.length;
  int get pixelCount => data.isEmpty ? 0 : data[0].length;

  /// Get sample data for a specific channel
  List<WaveformSample>? getChannelData(int channel) {
    if (channel < 0 || channel >= channels) return null;
    return data[channel];
  }

  /// Get sample at specific pixel for a channel
  WaveformSample? getSample(int channel, int pixel) {
    if (channel < 0 || channel >= channels) return null;
    if (pixel < 0 || pixel >= pixelCount) return null;
    return data[channel][pixel];
  }

  @override
  String toString() =>
      'ZoomLevel(samplesPerPixel: $samplesPerPixel, pixels: $pixelCount, channels: $channels)';
}

/// Complete waveform with all zoom levels
class WaveformBuffer {
  final WaveformData rawData;
  final List<ZoomLevel> zoomLevels;
  final int defaultZoomIndex;

  WaveformBuffer({
    required this.rawData,
    required this.zoomLevels,
    this.defaultZoomIndex = 0,
  });

  /// Get zoom level by index
  ZoomLevel? getZoomLevel(int index) {
    if (index < 0 || index >= zoomLevels.length) return null;
    return zoomLevels[index];
  }

  /// Get optimal zoom level for given samples per pixel
  ZoomLevel getOptimalZoomLevel(int targetSamplesPerPixel) {
    if (zoomLevels.isEmpty) {
      throw StateError('No zoom levels available');
    }

    // Find closest zoom level
    ZoomLevel closest = zoomLevels[0];
    int minDiff = (closest.samplesPerPixel - targetSamplesPerPixel).abs();

    for (final level in zoomLevels) {
      final diff = (level.samplesPerPixel - targetSamplesPerPixel).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = level;
      }
    }

    return closest;
  }

  int get zoomLevelCount => zoomLevels.length;
  Duration get duration => rawData.duration;
  int get channels => rawData.channels;
  int get sampleRate => rawData.sampleRate;

  @override
  String toString() =>
      'WaveformBuffer(duration: $duration, channels: $channels, zoomLevels: $zoomLevelCount)';
}
