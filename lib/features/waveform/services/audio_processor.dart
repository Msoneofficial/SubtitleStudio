import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:subtitle_studio/features/waveform/models/waveform_sample.dart';
import 'package:subtitle_studio/features/waveform/services/zoom_buffer_generator.dart';
import 'package:subtitle_studio/utils/ffmpeg_helper.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';

/// Service for processing audio files into waveform data
class AudioProcessor {
  /// Process audio file and generate waveform with zoom levels
  /// If subtitleCollectionId is provided, will check for cached data and save new data
  /// If audioTrackId is provided, will extract that specific audio track
  Future<WaveformBuffer> processAudioFile(
    String audioFilePath, {
    Function(double)? onProgress,
    int? subtitleCollectionId,
    String? audioTrackId,
  }) async {
    try {
      if (kDebugMode) {
        print('AudioProcessor: Starting audio processing for: $audioFilePath');
      }

      WaveformData waveformData;

      // Check for cached waveform data if subtitle collection ID is provided
      if (subtitleCollectionId != null) {
        final cache = await PreferencesModel.getWaveformCache(subtitleCollectionId);
        if (cache != null) {
          final pcmPath = cache['pcmPath'] as String;
          final pcmFile = File(pcmPath);
          
          if (await pcmFile.exists()) {
            if (kDebugMode) {
              print('AudioProcessor: Loading from cached PCM file: $pcmPath');
            }
            
            // Load from cached PCM
            onProgress?.call(0.1);
            waveformData = await _loadFromCachedPCM(
              pcmPath,
              cache['sampleRate'] as int,
              cache['totalSamples'] as int,
              cache['channels'] as int,
            );
            onProgress?.call(0.2);
            
            if (kDebugMode) {
              print('AudioProcessor: Successfully loaded from cache');
            }
          } else {
            if (kDebugMode) {
              print('AudioProcessor: Cached PCM file not found, will regenerate');
            }
            // Cache is invalid, clear it
            await PreferencesModel.clearWaveformCache(subtitleCollectionId);
            
            // Extract and cache new PCM
            waveformData = await _extractAndCachePCM(audioFilePath, subtitleCollectionId, onProgress, audioTrackId);
          }
        } else {
          // No cache exists, extract and save
          waveformData = await _extractAndCachePCM(audioFilePath, subtitleCollectionId, onProgress, audioTrackId);
        }
      } else {
        // No subtitle collection ID provided, process without caching
        if (Platform.isWindows || Platform.isLinux) {
          await _checkFFmpegAvailability();
        }
        
        onProgress?.call(0.05);
        waveformData = await _extractAudioToPCM(audioFilePath, audioTrackId: audioTrackId);
        onProgress?.call(0.15);
      }

      // Step 2: Downsample (20% of total work)
      if (kDebugMode) print('AudioProcessor: Step 2 - Downsampling...');
      final processedData = await _downsampleAudioAsync(waveformData);
      if (kDebugMode) print('AudioProcessor: Downsampling complete');
      onProgress?.call(0.35);

      // Step 3: Generate zoom levels (60% of total work)
      if (kDebugMode) print('AudioProcessor: Step 3 - Generating zoom levels...');
      final zoomLevels = await _generateZoomLevelsInIsolate(
        processedData, 
        (zoomProgress) {
          // Map zoom progress (0.0-1.0) to overall progress (0.35-0.95)
          final overallProgress = 0.35 + (zoomProgress * 0.6);
          if (kDebugMode) print('AudioProcessor: Progress: ${(overallProgress * 100).toStringAsFixed(1)}%');
          onProgress?.call(overallProgress);
        },
      );
      
      if (kDebugMode) print('AudioProcessor: Zoom levels complete');
      onProgress?.call(0.95);

      // Step 4: Create buffer (5% of total work)
      if (kDebugMode) print('AudioProcessor: Step 4 - Creating buffer...');
      final buffer = WaveformBuffer(
        rawData: processedData,
        zoomLevels: zoomLevels,
        defaultZoomIndex: zoomLevels.length ~/ 2,
      );

      if (kDebugMode) print('AudioProcessor: Processing complete!');
      onProgress?.call(1.0);
      return buffer;
    } catch (e) {
      if (kDebugMode) {
        print('AudioProcessor: Error processing audio: $e');
      }
      rethrow;
    }
  }

  /// Extract audio and cache the PCM file for future use
  Future<WaveformData> _extractAndCachePCM(
    String audioFilePath,
    int subtitleCollectionId,
    Function(double)? onProgress,
    String? audioTrackId,
  ) async {
    if (Platform.isWindows || Platform.isLinux) {
      await _checkFFmpegAvailability();
    }

    onProgress?.call(0.05);
    
    // Extract audio to PCM (this saves the file before returning)
    final waveformData = await _extractAudioToPCM(
      audioFilePath, 
      cacheForCollection: subtitleCollectionId,
      audioTrackId: audioTrackId,
    );
    
    onProgress?.call(0.15);
    return waveformData;
  }

  /// Load waveform data from cached PCM file
  Future<WaveformData> _loadFromCachedPCM(
    String pcmPath,
    int sampleRate,
    int totalSamples,
    int channels,
  ) async {
    final file = File(pcmPath);
    final bytes = await file.readAsBytes();
    
    // Convert bytes to Int16List
    final buffer = bytes.buffer;
    final samples = Int16List.view(buffer);
    
    if (kDebugMode) {
      print('AudioProcessor: Loaded ${samples.length} samples from cache');
    }
    
    return WaveformData(
      channels: channels,
      sampleRate: sampleRate,
      totalSamples: samples.length,
      rawSamples: [samples],
    );
  }

  /// Generate zoom levels in a background isolate
  Future<List<ZoomLevel>> _generateZoomLevelsInIsolate(
    WaveformData data,
    Function(double)? onProgress,
  ) async {
    // For now, run on main isolate to avoid complexity
    // Can be moved to isolate later if performance is an issue
    final zoomGenerator = ZoomBufferGenerator();
    
    // Generate zoom levels with progress reporting (0.0 to 0.9 of this step)
    final zoomLevels = await zoomGenerator.generateZoomLevels(
      data,
      onProgress: (levelProgress) {
        // This step represents 90% of zoom generation work
        onProgress?.call(levelProgress * 0.9);
      },
    );
    
    // Apply square root scaling to make quieter parts more visible (0.9 to 1.0 of this step)
    onProgress?.call(0.95);
    final scaledLevels = zoomGenerator.applyScaling(zoomLevels);
    onProgress?.call(1.0);
    
    return scaledLevels;
  }

  /// Downsample audio asynchronously
  Future<WaveformData> _downsampleAudioAsync(WaveformData data) async {
    // Run compute-intensive downsampling
    return _downsampleAudio(data);
  }

  /// Convert SAF URI to FFmpeg-compatible parameter for reading (Android only)
  Future<String> _getSafReadableParameter(String filePath) async {
    if (Platform.isAndroid && filePath.startsWith('content://')) {
      try {
        final safParameter = await FFmpegKitConfig.getSafParameterForRead(filePath);
        if (safParameter != null) {
          if (kDebugMode) {
            print('AudioProcessor: Converted SAF URI to FFmpeg parameter: $safParameter');
          }
          return safParameter;
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioProcessor: Error converting SAF URI: $e, using original path');
        }
      }
    }
    return filePath;
  }

  /// Check if FFmpeg is available on the system
  Future<void> _checkFFmpegAvailability() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      if (result.exitCode != 0) {
        throw Exception('FFmpeg is not properly installed');
      }
      
      if (kDebugMode) {
        print('AudioProcessor: FFmpeg is available');
      }
    } catch (e) {
      throw Exception(
        'FFmpeg is not available on this system. '
        'Please install FFmpeg and ensure it is in your PATH.\n\n'
        'Installation instructions:\n'
        '• Windows: Download from ffmpeg.org or use: winget install ffmpeg\n'
        '• Linux: sudo apt install ffmpeg (Ubuntu/Debian)\n\n'
        'Error: $e'
      );
    }
  }

  /// Extract audio from file using FFmpeg and convert to PCM
  /// If cacheForCollection is provided, saves the PCM file for future use
  /// If audioTrackId is provided, extracts that specific audio track
  Future<WaveformData> _extractAudioToPCM(
    String audioFilePath, {
    int? cacheForCollection,
    String? audioTrackId,
  }) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final outputPath = cacheForCollection != null
          ? '${tempDir.path}/waveform_audio_$cacheForCollection.raw' // Persistent name for caching
          : '${tempDir.path}/waveform_audio_${DateTime.now().millisecondsSinceEpoch}.raw'; // Temporary name

      if (kDebugMode) {
        print('AudioProcessor: Extracting audio to PCM: $outputPath');
        if (cacheForCollection != null) {
          print('AudioProcessor: Will cache for collection ID: $cacheForCollection');
        }
      }

      // Use FFmpegHelper to extract audio
      // We need to use FFmpeg command directly for raw PCM extraction
      final normalizedPath = FFmpegHelper.normalizePath(audioFilePath);
      
      // Build FFmpeg command for PCM extraction
      // -ac 1: mono output (single channel)
      // -ar 44100: 44.1kHz sample rate
      // -f s16le: 16-bit signed little-endian PCM
      // -y: overwrite output file

      if (kDebugMode) {
        print('AudioProcessor: Executing FFmpeg on ${Platform.operatingSystem}');
      }

      // Execute FFmpeg command based on platform
      if (Platform.isWindows || Platform.isLinux) {
        // Desktop platforms: Use system FFmpeg via Process.run
        bool useTrackSelection = audioTrackId != null && 
                                 audioTrackId != 'auto' && 
                                 audioTrackId.isNotEmpty;
        int? trackIndex;
        
        if (useTrackSelection) {
          final parsedId = int.tryParse(audioTrackId);
          if (parsedId != null) {
            // Media kit may use 1-based indexing, FFmpeg uses 0-based
            // Try subtracting 1 if the ID seems to be 1-based (>= 1)
            trackIndex = parsedId >= 1 ? parsedId - 1 : parsedId;
            useTrackSelection = trackIndex >= 0;
            
            if (kDebugMode) {
              print('AudioProcessor: Media kit track ID "$audioTrackId" -> FFmpeg index $trackIndex');
            }
          } else {
            useTrackSelection = false;
          }
        }
        
        final args = [
          '-y',
          '-i', normalizedPath,
        ];
        
        // Add audio track selection if specified
        if (useTrackSelection && trackIndex != null) {
          args.addAll(['-map', '0:a:$trackIndex']);
          if (kDebugMode) {
            print('AudioProcessor: Attempting to select audio track index $trackIndex');
          }
        }
        
        args.addAll([
          '-ac', '1', // Mono output
          '-ar', '44100',
          '-f', 's16le',
          '-acodec', 'pcm_s16le',
          outputPath,
        ]);
        
        var result = await Process.run('ffmpeg', args);

        // If track selection failed, retry without it
        if (result.exitCode != 0 && useTrackSelection) {
          if (kDebugMode) {
            print('AudioProcessor: Track selection failed, retrying with default audio track');
          }
          
          // Rebuild args without track selection
          final retryArgs = [
            '-y',
            '-i', normalizedPath,
            '-ac', '1',
            '-ar', '44100',
            '-f', 's16le',
            '-acodec', 'pcm_s16le',
            outputPath,
          ];
          
          result = await Process.run('ffmpeg', retryArgs);
        }
        
        if (result.exitCode != 0) {
          throw Exception('FFmpeg failed with exit code ${result.exitCode}: ${result.stderr}');
        }
      } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        // Mobile/macOS platforms: Use FFmpegKit
        final inputPath = await _getSafReadableParameter(normalizedPath);
        
        bool useTrackSelection = audioTrackId != null && 
                                 audioTrackId != 'auto' && 
                                 audioTrackId.isNotEmpty;
        int? trackIndex;
        
        if (useTrackSelection) {
          final parsedId = int.tryParse(audioTrackId);
          if (parsedId != null) {
            // Media kit may use 1-based indexing, FFmpeg uses 0-based
            // Try subtracting 1 if the ID seems to be 1-based (>= 1)
            trackIndex = parsedId >= 1 ? parsedId - 1 : parsedId;
            useTrackSelection = trackIndex >= 0;
            
            if (kDebugMode) {
              print('AudioProcessor: Media kit track ID "$audioTrackId" -> FFmpeg index $trackIndex');
            }
          } else {
            useTrackSelection = false;
          }
        }
        
        // Build command with optional audio track selection
        String command = '-y -i "$inputPath"';
        
        if (useTrackSelection && trackIndex != null) {
          command += ' -map 0:a:$trackIndex';
          if (kDebugMode) {
            print('AudioProcessor: Attempting to select audio track index $trackIndex');
          }
        }
        
        command += ' -ac 1 -ar 44100 -f s16le -acodec pcm_s16le "$outputPath"';
        
        if (kDebugMode) {
          print('AudioProcessor: FFmpegKit command: $command');
        }
        
        var session = await FFmpegKit.execute(command);
        var returnCode = await session.getReturnCode();
        
        // If track selection failed, retry without it (use default audio track)
        if ((returnCode == null || !returnCode.isValueSuccess()) && useTrackSelection) {
          if (kDebugMode) {
            print('AudioProcessor: Track selection failed, retrying with default audio track');
          }
          
          // Retry without track selection
          command = '-y -i "$inputPath" -ac 1 -ar 44100 -f s16le -acodec pcm_s16le "$outputPath"';
          session = await FFmpegKit.execute(command);
          returnCode = await session.getReturnCode();
        }
        
        if (returnCode == null || !returnCode.isValueSuccess()) {
          final logs = await session.getLogs();
          final logMessages = logs.map((log) => log.getMessage()).join('\n');
          throw Exception('FFmpegKit failed with code ${returnCode?.getValue()}: $logMessages');
        }
      } else {
        throw UnsupportedError(
          'Waveform generation is not supported on ${Platform.operatingSystem}.'
        );
      }

      if (kDebugMode) {
        print('AudioProcessor: FFmpeg extraction successful');
      }

      // Read raw PCM data
      final file = File(outputPath);
      if (!await file.exists()) {
        throw Exception('FFmpeg failed to create output file');
      }

      final bytes = await file.readAsBytes();
      if (kDebugMode) {
        print('AudioProcessor: Read ${bytes.length} bytes of PCM data');
      }

      // Convert bytes to Int16List
      final buffer = bytes.buffer;
      final samples = Int16List.view(buffer);

      // Use mono (1 channel)
      const channels = 1;
      const sampleRate = 44100;
      final channelSamples = <Int16List>[samples]; // Single channel

      // Save cache information if requested
      if (cacheForCollection != null) {
        await PreferencesModel.saveWaveformCache(
          subtitleCollectionId: cacheForCollection,
          pcmPath: outputPath,
          sampleRate: sampleRate,
          totalSamples: samples.length,
          channels: channels,
        );
        
        if (kDebugMode) {
          print('AudioProcessor: Waveform cache saved for collection $cacheForCollection');
        }
      } else {
        // Clean up temporary file if not caching
        await file.delete();
      }

      if (kDebugMode) {
        print('AudioProcessor: Successfully extracted ${samples.length} samples (mono)');
      }

      return WaveformData(
        channels: channels,
        sampleRate: sampleRate,
        totalSamples: channelSamples[0].length,
        rawSamples: channelSamples,
      );
    } catch (e) {
      if (kDebugMode) {
        print('AudioProcessor: Error extracting audio: $e');
      }
      rethrow;
    }
  }

  /// Downsample audio to reduce data size (~3000 samples/sec max)
  WaveformData _downsampleAudio(WaveformData input) {
    const maxSamplesPerSec = 3000;

    if (input.sampleRate <= maxSamplesPerSec) {
      return input; // No downsampling needed
    }

    final sampleShift = _calculateSampleShift(input.sampleRate, maxSamplesPerSec);
    final newSampleRate = input.sampleRate >> sampleShift;
    final frameSize = 1 << sampleShift;

    if (kDebugMode) {
      print('AudioProcessor: Downsampling from ${input.sampleRate}Hz to ${newSampleRate}Hz');
    }

    final newChannelSamples = <Int16List>[];

    for (var ch = 0; ch < input.channels; ch++) {
      final oldSamples = input.rawSamples[ch];
      final newLength = oldSamples.length ~/ frameSize;
      final newSamples = Int16List(newLength);

      for (var i = 0; i < newLength; i++) {
        var sum = 0;
        final start = i * frameSize;
        final end = (start + frameSize < oldSamples.length)
            ? start + frameSize
            : oldSamples.length;

        // Average samples in frame
        for (var j = start; j < end; j++) {
          sum += oldSamples[j];
        }

        newSamples[i] = (sum / (end - start)).round();
      }

      newChannelSamples.add(newSamples);
    }

    return WaveformData(
      channels: input.channels,
      sampleRate: newSampleRate,
      totalSamples: newChannelSamples[0].length,
      rawSamples: newChannelSamples,
    );
  }

  /// Calculate sample shift for downsampling
  static int _calculateSampleShift(int currentRate, int targetRate) {
    var shift = 0;
    var rate = currentRate;
    while (rate > targetRate) {
      rate >>= 1;
      shift++;
    }
    return shift;
  }

  /// Cleanup resources
  void dispose() {
    // Cleanup if needed
  }
}
