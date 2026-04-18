import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:subtitle_studio/features/waveform/models/waveform_sample.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';

/// Service for generating zoom levels from waveform data
class ZoomBufferGenerator {
  /// Generate multiple zoom levels for smooth zooming
  /// Based on Subtitle Composer's zoom buffer implementation
  Future<List<ZoomLevel>> generateZoomLevels(
    WaveformData rawData, {
    Function(double)? onProgress,
  }) async {
    if (kDebugMode) {
      print('ZoomBufferGenerator: Generating zoom levels...');
    }

    final zoomLevels = <ZoomLevel>[];

    // Generate zoom levels with different samples per pixel
    // Start with fine detail (fewer samples per pixel) and go to overview (more samples per pixel)
    final samplesPerPixelValues = await _calculateZoomLevels(rawData.totalSamples);
    final totalLevels = samplesPerPixelValues.length;

    for (var i = 0; i < totalLevels; i++) {
      final samplesPerPixel = samplesPerPixelValues[i];
      final zoomLevel = _generateZoomLevel(rawData, samplesPerPixel);
      zoomLevels.add(zoomLevel);

      // Report progress for this zoom level
      if (onProgress != null) {
        final progress = (i + 1) / totalLevels;
        onProgress(progress);
      }

      if (kDebugMode) {
        print('ZoomBufferGenerator: Generated zoom level ${i + 1}/$totalLevels with $samplesPerPixel samples/pixel (${zoomLevel.pixelCount} pixels)');
      }
    }

    if (kDebugMode) {
      print('ZoomBufferGenerator: Generated ${zoomLevels.length} zoom levels');
    }

    return zoomLevels;
  }

  /// Calculate optimal zoom levels for given total samples
  /// Creates logarithmic zoom levels for smooth zooming with more intermediate steps
  /// Optimized to provide extra detail in useful ranges without performance penalty
  Future<List<int>> _calculateZoomLevels(int totalSamples) async {
    final levels = <int>[];

    // Get configurable settings from preferences
    final maxPixelsForDetailedView = await PreferencesModel.getWaveformMaxPixels();
    final sampleRateFactor = await PreferencesModel.getWaveformSampleRateFactor();
    final zoomMultiplier = await PreferencesModel.getWaveformZoomMultiplier();
    
    // Minimum samples per pixel (most zoomed in) - adjusted for long audio
    final minSamplesPerPixel = math.max(1, totalSamples ~/ maxPixelsForDetailedView);
    
    // Maximum samples per pixel (most zoomed out)
    // Ensure at least 100 pixels for overview
    final minPixelsForOverview = 100;
    final maxSamplesPerPixel = math.max(
      minPixelsForOverview,
      totalSamples ~/ minPixelsForOverview,
    );

    if (kDebugMode) {
      print('ZoomBufferGenerator: Total samples: $totalSamples');
      print('ZoomBufferGenerator: Config - MaxPixels: $maxPixelsForDetailedView, SampleRateFactor: $sampleRateFactor, ZoomMultiplier: $zoomMultiplier');
      print('ZoomBufferGenerator: Min samples/pixel: $minSamplesPerPixel (${totalSamples ~/ minSamplesPerPixel} pixels)');
      print('ZoomBufferGenerator: Max samples/pixel: $maxSamplesPerPixel (${totalSamples ~/ maxSamplesPerPixel} pixels)');
    }

    // Generate zoom levels using a smoother logarithmic progression
    // Extra detail in useful ranges for better user experience
    int samplesPerPixel = minSamplesPerPixel;
    while (samplesPerPixel <= maxSamplesPerPixel) {
      levels.add(samplesPerPixel);
      
      // Use smaller increments for smoother zoom progression
      // Extra detail where users need it most (configurable ranges based on sampleRateFactor)
      final threshold1 = sampleRateFactor ~/ 8; // Default: 2
      final threshold2 = sampleRateFactor ~/ 2.67; // Default: ~6
      final threshold3 = sampleRateFactor; // Default: 16
      final threshold4 = sampleRateFactor * 3; // Default: 48
      final threshold5 = sampleRateFactor * 12; // Default: 192
      final threshold6 = sampleRateFactor * 48; // Default: 768
      final threshold7 = sampleRateFactor * 192; // Default: 3072
      final threshold8 = sampleRateFactor * 768; // Default: 12288
      final threshold9 = sampleRateFactor * 3072; // Default: 49152
      
      if (samplesPerPixel < threshold1) {
        // Ultra detailed: increment by 1 for precise editing
        samplesPerPixel += 1;
      } else if (samplesPerPixel < threshold2) {
        // Very detailed: use 1.2x multiplier (maximum smoothness)
        samplesPerPixel = (samplesPerPixel * 1.2).round();
        if (samplesPerPixel == levels.last) samplesPerPixel++; // Ensure progress
      } else if (samplesPerPixel < threshold3) {
        // Very detailed: use 1.25x multiplier (extra smooth)
        samplesPerPixel = (samplesPerPixel * 1.25).round();
        if (samplesPerPixel == levels.last) samplesPerPixel++; // Ensure progress
      } else if (samplesPerPixel < threshold4) {
        // Detailed: use 1.3x multiplier (more granular)
        samplesPerPixel = (samplesPerPixel * 1.3).round();
      } else if (samplesPerPixel < threshold5) {
        // Medium detail: use configurable zoom multiplier (common working range)
        samplesPerPixel = (samplesPerPixel * zoomMultiplier).round();
      } else if (samplesPerPixel < threshold6) {
        // Lower detail: use slightly higher multiplier
        samplesPerPixel = (samplesPerPixel * (zoomMultiplier + 0.05)).round();
      } else if (samplesPerPixel < threshold7) {
        // Overview: use higher multiplier
        samplesPerPixel = (samplesPerPixel * (zoomMultiplier + 0.15)).round();
      } else if (samplesPerPixel < threshold8) {
        // Far overview: use much higher multiplier
        samplesPerPixel = (samplesPerPixel * (zoomMultiplier + 0.35)).round();
      } else if (samplesPerPixel < threshold9) {
        // Very far overview: use 2x multiplier
        samplesPerPixel = (samplesPerPixel * 2).round();
      } else {
        // Extreme overview: use 2.5x multiplier
        samplesPerPixel = (samplesPerPixel * 2.5).round();
      }
      
      // Prevent infinite loop if multiplier rounds to same value
      if (levels.length > 1 && levels.last == samplesPerPixel) {
        samplesPerPixel++;
      }
    }

    // Ensure we have overview level
    if (levels.isEmpty || levels.last < maxSamplesPerPixel) {
      levels.add(maxSamplesPerPixel);
    }

    if (kDebugMode) {
      print('ZoomBufferGenerator: Generated ${levels.length} zoom levels');
      if (levels.length <= 25) {
        print('ZoomBufferGenerator: Zoom levels: $levels');
      } else {
        print('ZoomBufferGenerator: First 10: ${levels.take(10).toList()}');
        print('ZoomBufferGenerator: Last 10: ${levels.skip(levels.length - 10).toList()}');
      }
    }

    return levels;
  }

  /// Generate single zoom level with specified samples per pixel
  /// Optimized for fast processing with efficient min/max calculation
  ZoomLevel _generateZoomLevel(WaveformData rawData, int samplesPerPixel) {
    final pixelCount = (rawData.totalSamples / samplesPerPixel).ceil();
    final channelData = <List<WaveformSample>>[];

    // Pre-calculate normalization factor
    const normalizationFactor = 1.0 / 32768.0;

    // Process each channel
    for (var ch = 0; ch < rawData.channels; ch++) {
      final samples = rawData.rawSamples[ch];
      final pixelSamples = List<WaveformSample>.filled(
        pixelCount,
        const WaveformSample(0, 0),
        growable: false,
      );

      // Aggregate samples into pixels - optimized loop
      for (var pixel = 0; pixel < pixelCount; pixel++) {
        final startSample = pixel * samplesPerPixel;
        final endSample = math.min(startSample + samplesPerPixel, samples.length);

        // Find min/max in this pixel range - optimized
        var minValue = 1.0;
        var maxValue = -1.0;

        // Unrolled loop for better performance on small ranges
        final rangeSize = endSample - startSample;
        if (rangeSize == 1) {
          // Single sample - fast path
          final value = samples[startSample] * normalizationFactor;
          minValue = value;
          maxValue = value;
        } else if (rangeSize <= 4) {
          // Small range - unroll manually
          for (var i = startSample; i < endSample; i++) {
            final normalizedValue = samples[i] * normalizationFactor;
            if (normalizedValue < minValue) minValue = normalizedValue;
            if (normalizedValue > maxValue) maxValue = normalizedValue;
          }
        } else {
          // Larger range - normal loop
          for (var i = startSample; i < endSample; i++) {
            final normalizedValue = samples[i] * normalizationFactor;
            if (normalizedValue < minValue) minValue = normalizedValue;
            if (normalizedValue > maxValue) maxValue = normalizedValue;
          }
        }

        pixelSamples[pixel] = WaveformSample(minValue, maxValue);
      }

      channelData.add(pixelSamples);
    }

    return ZoomLevel(
      samplesPerPixel: samplesPerPixel,
      data: channelData,
    );
  }

  /// Apply square root scaling for better visual representation
  /// This makes quieter parts more visible
  List<ZoomLevel> applyScaling(List<ZoomLevel> zoomLevels) {
    final scaledLevels = <ZoomLevel>[];

    for (final level in zoomLevels) {
      final scaledChannelData = <List<WaveformSample>>[];

      for (final channelSamples in level.data) {
        final scaledSamples = channelSamples.map((sample) {
          final minScaled = _applySquareRootScaling(sample.min);
          final maxScaled = _applySquareRootScaling(sample.max);
          return WaveformSample(minScaled, maxScaled);
        }).toList();

        scaledChannelData.add(scaledSamples);
      }

      scaledLevels.add(ZoomLevel(
        samplesPerPixel: level.samplesPerPixel,
        data: scaledChannelData,
      ));
    }

    return scaledLevels;
  }

  /// Apply square root scaling to a value
  double _applySquareRootScaling(double value) {
    if (value >= 0) {
      return math.sqrt(value);
    } else {
      return -math.sqrt(-value);
    }
  }
}
