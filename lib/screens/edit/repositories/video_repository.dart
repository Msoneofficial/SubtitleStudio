import 'dart:io';

import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';
import 'package:subtitle_studio/utils/subtitle_parser.dart';

/// Repository layer for video-related operations
/// 
/// This class abstracts video path management, secondary subtitle loading,
/// and video-related preferences, following clean architecture principles.
/// 
/// Responsibilities:
/// - Video path persistence
/// - Secondary subtitle management
/// - Video-related preference loading
class VideoRepository {
  static final VideoRepository _instance = VideoRepository._internal();
  factory VideoRepository() => _instance;
  VideoRepository._internal();

  /// Get saved video path for a subtitle collection
  Future<String?> getSavedVideoPath(int collectionId) async {
    logInfo('VideoRepository: Fetching saved video path for collection $collectionId');
    try {
      final path = await PreferencesModel.getVideoPath(collectionId);
      if (path != null) {
        logInfo('VideoRepository: Found saved video path: $path');
      } else {
        logInfo('VideoRepository: No saved video path found');
      }
      return path;
    } catch (e) {
      logError('VideoRepository: Error fetching video path: $e');
      rethrow;
    }
  }

  /// Save video path for a subtitle collection
  Future<void> saveVideoPath(int collectionId, String path) async {
    logInfo('VideoRepository: Saving video path for collection $collectionId: $path');
    try {
      await PreferencesModel.saveVideoPath(collectionId, path);
      logInfo('VideoRepository: Successfully saved video path');
    } catch (e) {
      logError('VideoRepository: Error saving video path: $e');
      rethrow;
    }
  }

  /// Remove saved video path for a subtitle collection
  Future<void> removeVideoPath(int collectionId) async {
    logInfo('VideoRepository: Removing video path for collection $collectionId');
    try {
      await PreferencesModel.removeVideoPath(collectionId);
      logInfo('VideoRepository: Successfully removed video path');
    } catch (e) {
      logError('VideoRepository: Error removing video path: $e');
      rethrow;
    }
  }

  /// Load saved secondary subtitle for a collection
  /// Returns null if no secondary subtitle is configured
  Future<SecondarySubtitleData?> loadSavedSecondarySubtitle(int collectionId) async {
    logInfo('VideoRepository: Loading saved secondary subtitle for collection $collectionId');
    try {
      final secondaryPath = await PreferencesModel.getSecondarySubtitlePath(collectionId);
      final useOriginalAsSecondary = await PreferencesModel.getSecondaryIsOriginal(collectionId);
      
      if (useOriginalAsSecondary) {
        logInfo('VideoRepository: Using original text as secondary subtitle');
        return SecondarySubtitleData(useOriginal: true);
      } else if (secondaryPath != null) {
        logInfo('VideoRepository: Loading secondary subtitle from file: $secondaryPath');
        // Parse the secondary subtitle file
        final subtitles = await _parseSubtitleFile(secondaryPath);
        return SecondarySubtitleData(
          useOriginal: false,
          externalPath: secondaryPath,
          subtitles: subtitles,
        );
      }
      
      logInfo('VideoRepository: No secondary subtitle configured');
      return null;
    } catch (e) {
      logError('VideoRepository: Error loading secondary subtitle: $e');
      rethrow;
    }
  }

  /// Parse subtitle file based on extension
  Future<List<SimpleSubtitleLine>> _parseSubtitleFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Subtitle file not found: $path');
    }

    final content = await file.readAsString();
    List<SimpleSubtitleLine> parsedSubtitles = [];

    if (path.endsWith('.srt')) {
      parsedSubtitles = SubtitleParser.parseSrt(content);
    } else if (path.endsWith('.vtt')) {
      parsedSubtitles = SubtitleParser.parseVtt(content);
    } else if (path.endsWith('.ass') || path.endsWith('.ssa')) {
      parsedSubtitles = SubtitleParser.parseAss(content);
    } else {
      throw Exception('Unsupported subtitle format: $path');
    }

    return parsedSubtitles;
  }

  /// Save secondary subtitle path for a collection and parse the file
  Future<SecondarySubtitleData> saveAndLoadSecondarySubtitle(
      int collectionId, String path) async {
    logInfo('VideoRepository: Saving and loading secondary subtitle for collection $collectionId: $path');
    try {
      await PreferencesModel.saveSecondarySubtitlePath(collectionId, path);
      // Clear the "use original as secondary" flag
      await PreferencesModel.setSecondaryIsOriginal(collectionId, false);
      
      // Parse the subtitle file
      final subtitles = await _parseSubtitleFile(path);
      logInfo('VideoRepository: Successfully saved and loaded secondary subtitle');
      
      return SecondarySubtitleData(
        useOriginal: false,
        externalPath: path,
        subtitles: subtitles,
      );
    } catch (e) {
      logError('VideoRepository: Error saving secondary subtitle path: $e');
      rethrow;
    }
  }

  /// Set to use original text as secondary subtitle
  Future<void> setUseOriginalAsSecondary(int collectionId, bool use) async {
    logInfo('VideoRepository: Setting use original as secondary for collection $collectionId: $use');
    try {
      await PreferencesModel.setSecondaryIsOriginal(collectionId, use);
      if (use) {
        // Clear external path when using original
        await PreferencesModel.removeSecondarySubtitlePath(collectionId);
      }
      logInfo('VideoRepository: Successfully set use original as secondary');
    } catch (e) {
      logError('VideoRepository: Error setting use original as secondary: $e');
      rethrow;
    }
  }

  /// Clear secondary subtitle configuration
  Future<void> clearSecondarySubtitle(int collectionId) async {
    logInfo('VideoRepository: Clearing secondary subtitle for collection $collectionId');
    try {
      await PreferencesModel.removeSecondarySubtitlePath(collectionId);
      await PreferencesModel.setSecondaryIsOriginal(collectionId, false);
      logInfo('VideoRepository: Successfully cleared secondary subtitle');
    } catch (e) {
      logError('VideoRepository: Error clearing secondary subtitle: $e');
      rethrow;
    }
  }

  /// Get floating controls enabled preference
  Future<bool> getFloatingControlsEnabled() async {
    logInfo('VideoRepository: Fetching floating controls preference');
    try {
      final enabled = await PreferencesModel.getFloatingControlsEnabled();
      logInfo('VideoRepository: Floating controls enabled: $enabled');
      return enabled;
    } catch (e) {
      logError('VideoRepository: Error fetching floating controls preference: $e');
      return false;
    }
  }

  /// Save floating controls enabled preference
  Future<void> saveFloatingControlsEnabled(bool enabled) async {
    logInfo('VideoRepository: Saving floating controls preference: $enabled');
    try {
      await PreferencesModel.setFloatingControlsEnabled(enabled);
      logInfo('VideoRepository: Successfully saved floating controls preference');
    } catch (e) {
      logError('VideoRepository: Error saving floating controls preference: $e');
      rethrow;
    }
  }

  /// Get MSone features enabled preference
  Future<bool> getMsoneEnabled() async {
    logInfo('VideoRepository: Fetching MSone features preference');
    try {
      final enabled = await PreferencesModel.getMsoneEnabled();
      logInfo('VideoRepository: MSone features enabled: $enabled');
      return enabled;
    } catch (e) {
      logError('VideoRepository: Error fetching MSone features preference: $e');
      return false;
    }
  }

  /// Save MSone features enabled preference
  Future<void> saveMsoneEnabled(bool enabled) async {
    logInfo('VideoRepository: Saving MSone features preference: $enabled');
    try {
      await PreferencesModel.setMsoneEnabled(enabled);
      logInfo('VideoRepository: Successfully saved MSone features preference');
    } catch (e) {
      logError('VideoRepository: Error saving MSone features preference: $e');
      rethrow;
    }
  }

  /// Get layout preference
  Future<String> getLayoutPreference() async {
    logInfo('VideoRepository: Fetching layout preference');
    try {
      final layout = await PreferencesModel.getSwitchLayout();
      logInfo('VideoRepository: Layout preference: $layout');
      return layout;
    } catch (e) {
      logError('VideoRepository: Error fetching layout preference: $e');
      return 'layout1'; // Default
    }
  }

  /// Save layout preference
  Future<void> saveLayoutPreference(String layout) async {
    logInfo('VideoRepository: Saving layout preference: $layout');
    try {
      await PreferencesModel.setSwitchLayout(layout);
      logInfo('VideoRepository: Successfully saved layout preference');
    } catch (e) {
      logError('VideoRepository: Error saving layout preference: $e');
      rethrow;
    }
  }

  /// Get edit screen resize ratio
  Future<double> getEditScreenResizeRatio() async {
    logInfo('VideoRepository: Fetching edit screen resize ratio');
    try {
      final ratio = await PreferencesModel.getEditScreenResizeRatio();
      logInfo('VideoRepository: Edit screen resize ratio: $ratio');
      return ratio;
    } catch (e) {
      logError('VideoRepository: Error fetching resize ratio: $e');
      return 0.35; // Default
    }
  }

  /// Save edit screen resize ratio
  Future<void> saveEditScreenResizeRatio(double ratio) async {
    logInfo('VideoRepository: Saving edit screen resize ratio: $ratio');
    try {
      await PreferencesModel.setEditScreenResizeRatio(ratio);
      logInfo('VideoRepository: Successfully saved resize ratio');
    } catch (e) {
      logError('VideoRepository: Error saving resize ratio: $e');
      rethrow;
    }
  }

  /// Get mobile video resize ratio
  Future<double> getMobileVideoResizeRatio() async {
    logInfo('VideoRepository: Fetching mobile video resize ratio');
    try {
      final ratio = await PreferencesModel.getMobileVideoResizeRatio();
      logInfo('VideoRepository: Mobile video resize ratio: $ratio');
      return ratio;
    } catch (e) {
      logError('VideoRepository: Error fetching mobile resize ratio: $e');
      return 0.4; // Default
    }
  }

  /// Save mobile video resize ratio
  Future<void> saveMobileVideoResizeRatio(double ratio) async {
    logInfo('VideoRepository: Saving mobile video resize ratio: $ratio');
    try {
      await PreferencesModel.setMobileVideoResizeRatio(ratio);
      logInfo('VideoRepository: Successfully saved mobile resize ratio');
    } catch (e) {
      logError('VideoRepository: Error saving mobile resize ratio: $e');
      rethrow;
    }
  }
}

/// Data class for secondary subtitle information
class SecondarySubtitleData {
  final bool useOriginal;
  final String? externalPath;
  final List<SimpleSubtitleLine>? subtitles;

  SecondarySubtitleData({
    required this.useOriginal,
    this.externalPath,
    this.subtitles,
  });
}
