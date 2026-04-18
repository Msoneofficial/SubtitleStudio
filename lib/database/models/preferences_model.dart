import 'dart:io';
import 'package:isar_community/isar.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/main.dart';

/// Preferences Model - Manages application preferences using Isar database
/// 
/// This class provides a unified interface for all application preferences
/// that were previously stored using SharedPreferences. Now all preferences
/// are stored in the Isar database as a single Preferences collection.
///
/// All methods ensure a single Preferences instance exists and update it atomically.
class PreferencesModel {
  /// Get the singleton Preferences instance, creating one if it doesn't exist
  static Future<Preferences> _getPreferences() async {
    var prefs = await isar.preferences.where().findFirst();
    if (prefs == null) {
      prefs = Preferences(autoSave: true);
      await isar.writeTxn(() async {
        await isar.preferences.put(prefs!);
      });
    }
    return prefs;
  }

  /// Update preferences with a transaction
  static Future<void> _updatePreferences(void Function(Preferences) update) async {
    await isar.writeTxn(() async {
      final prefs = await _getPreferences();
      update(prefs);
      await isar.preferences.put(prefs);
    });
  }

  // MSone features enabled status
  static Future<bool> getMsoneEnabled() async {
    final prefs = await _getPreferences();
    return prefs.msoneEnabled;
  }

  static Future<void> setMsoneEnabled(bool value) async {
    await _updatePreferences((prefs) => prefs.msoneEnabled = value);
  }

  // Color history
  static Future<List<String>> getColorHistory() async {
    final prefs = await _getPreferences();
    return prefs.colorHistory;
  }

  static Future<void> saveColorHistory(List<String> colorHistory) async {
    await _updatePreferences((prefs) => prefs.colorHistory = colorHistory);
  }

  // Floating controls preferences
  static Future<bool> getFloatingControlsEnabled() async {
    final prefs = await _getPreferences();
    return prefs.floatingControlsEnabled;
  }

  static Future<void> setFloatingControlsEnabled(bool value) async {
    await _updatePreferences((prefs) => prefs.floatingControlsEnabled = value);
  }

  // Show original line status
  static Future<bool> getShowOriginalLine() async {
    final prefs = await _getPreferences();
    return prefs.showOriginalLine;
  }

  static Future<void> setShowOriginalLine(bool value) async {
    await _updatePreferences((prefs) => prefs.showOriginalLine = value);
  }

  // Auto-save with navigation status
  static Future<bool> getAutoSaveWithNavigation() async {
    final prefs = await _getPreferences();
    return prefs.autoSaveWithNavigation;
  }

  static Future<void> setAutoSaveWithNavigation(bool value) async {
    await _updatePreferences((prefs) => prefs.autoSaveWithNavigation = value);
  }

  // Save-to-file setting
  static Future<bool> getSaveToFileEnabled() async {
    final prefs = await _getPreferences();
    return prefs.saveToFileEnabled;
  }

  static Future<void> setSaveToFileEnabled(bool value) async {
    await _updatePreferences((prefs) => prefs.saveToFileEnabled = value);
  }

  // Translator information
  static Future<String?> getTranslatorName() async {
    final prefs = await _getPreferences();
    return prefs.translatorName;
  }

  static Future<void> setTranslatorName(String name) async {
    await _updatePreferences((prefs) => prefs.translatorName = name);
  }

  static Future<String?> getTranslatorEmail() async {
    final prefs = await _getPreferences();
    return prefs.translatorEmail;
  }

  static Future<void> setTranslatorEmail(String email) async {
    await _updatePreferences((prefs) => prefs.translatorEmail = email);
  }

  static Future<String?> getTranslatorContactId() async {
    final prefs = await _getPreferences();
    return prefs.translatorContactId;
  }

  static Future<void> setTranslatorContactId(String contactId) async {
    await _updatePreferences((prefs) => prefs.translatorContactId = contactId);
  }

  // MSone Dictionary (hidden feature)
  static Future<bool> getMsoneDictionaryEnabled() async {
    final prefs = await _getPreferences();
    return prefs.msoneDictionaryEnabled;
  }

  static Future<void> setMsoneDictionaryEnabled(bool value) async {
    await _updatePreferences((prefs) => prefs.msoneDictionaryEnabled = value);
  }

  // Hide video on keyboard visibility
  static Future<bool> getHideVideoOnKeyboard() async {
    final prefs = await _getPreferences();
    return prefs.hideVideoOnKeyboard;
  }

  static Future<void> setHideVideoOnKeyboard(bool value) async {
    await _updatePreferences((prefs) => prefs.hideVideoOnKeyboard = value);
  }

  // Olam Dictionary last update date
  static Future<String?> getOlamLastUpdateDate() async {
    final prefs = await _getPreferences();
    return prefs.olamLastUpdateDate;
  }

  static Future<void> setOlamLastUpdateDate(String date) async {
    await _updatePreferences((prefs) => prefs.olamLastUpdateDate = date);
  }

  // Olam Dictionary search filters
  static Future<bool> getOlamWholeWordSearch() async {
    final prefs = await _getPreferences();
    return prefs.olamWholeWordSearch;
  }

  static Future<void> setOlamWholeWordSearch(bool value) async {
    await _updatePreferences((prefs) => prefs.olamWholeWordSearch = value);
  }

  static Future<bool> getOlamCaseSensitiveSearch() async {
    final prefs = await _getPreferences();
    return prefs.olamCaseSensitiveSearch;
  }

  static Future<void> setOlamCaseSensitiveSearch(bool value) async {
    await _updatePreferences((prefs) => prefs.olamCaseSensitiveSearch = value);
  }

  // Max line length
  static Future<int> getMaxLineLength() async {
    final prefs = await _getPreferences();
    return prefs.maxLineLength;
  }

  static Future<void> setMaxLineLength(int value) async {
    await _updatePreferences((prefs) => prefs.maxLineLength = value);
  }

  // Show original text field
  static Future<bool> getShowOriginalTextField() async {
    final prefs = await _getPreferences();
    return prefs.showOriginalTextField;
  }

  static Future<void> setShowOriginalTextField(bool value) async {
    await _updatePreferences((prefs) => prefs.showOriginalTextField = value);
  }

  // Subtitle font path
  static Future<String?> getSubtitleFontPath() async {
    final prefs = await _getPreferences();
    return prefs.subtitleFontPath;
  }

  static Future<void> setSubtitleFontPath(String? path) async {
    await _updatePreferences((prefs) => prefs.subtitleFontPath = path);
  }

  // Subtitle font size
  static Future<double> getSubtitleFontSize() async {
    final prefs = await _getPreferences();
    return prefs.subtitleFontSize;
  }

  static Future<void> setSubtitleFontSize(double size) async {
    await _updatePreferences((prefs) => prefs.subtitleFontSize = size);
  }

  // Subtitle background visibility preference
  static Future<bool> getShowSubtitleBackground() async {
    final prefs = await _getPreferences();
    return prefs.showSubtitleBackground;
  }

  static Future<void> setShowSubtitleBackground(bool value) async {
    await _updatePreferences((prefs) => prefs.showSubtitleBackground = value);
  }

  // Edit screen resize ratio
  static Future<double> getEditScreenResizeRatio() async {
    final prefs = await _getPreferences();
    return prefs.editScreenResizeRatio;
  }

  static Future<void> setEditScreenResizeRatio(double ratio) async {
    await _updatePreferences((prefs) => prefs.editScreenResizeRatio = ratio);
  }

  // Edit line resize ratio
  static Future<double> getEditLineResizeRatio() async {
    final prefs = await _getPreferences();
    return prefs.editLineResizeRatio;
  }

  static Future<void> setEditLineResizeRatio(double ratio) async {
    await _updatePreferences((prefs) => prefs.editLineResizeRatio = ratio);
  }

  // Mobile video resize ratio
  static Future<double> getMobileVideoResizeRatio() async {
    final prefs = await _getPreferences();
    return prefs.mobileVideoResizeRatio;
  }

  static Future<void> setMobileVideoResizeRatio(double ratio) async {
    await _updatePreferences((prefs) => prefs.mobileVideoResizeRatio = ratio);
  }

  // Auto resize on keyboard
  static Future<bool> getAutoResizeOnKeyboard() async {
    final prefs = await _getPreferences();
    return prefs.autoResizeOnKeyboard;
  }

  static Future<void> setAutoResizeOnKeyboard(bool value) async {
    await _updatePreferences((prefs) => prefs.autoResizeOnKeyboard = value);
  }

  // Skip duration (for fast forward/reverse)
  static Future<int> getSkipDurationSeconds() async {
    final prefs = await _getPreferences();
    return prefs.skipDurationSeconds;
  }

  static Future<void> setSkipDurationSeconds(int seconds) async {
    await _updatePreferences((prefs) => prefs.skipDurationSeconds = seconds);
  }

  // Primary subtitle vertical position
  static Future<double> getPrimarySubtitleVerticalPosition() async {
    final prefs = await _getPreferences();
    return prefs.primarySubtitleVerticalPosition;
  }

  static Future<void> setPrimarySubtitleVerticalPosition(double position) async {
    await _updatePreferences((prefs) => prefs.primarySubtitleVerticalPosition = position);
  }

  // Secondary subtitle vertical position
  static Future<double> getSecondarySubtitleVerticalPosition() async {
    final prefs = await _getPreferences();
    return prefs.secondarySubtitleVerticalPosition;
  }

  static Future<void> setSecondarySubtitleVerticalPosition(double position) async {
    await _updatePreferences((prefs) => prefs.secondarySubtitleVerticalPosition = position);
  }

  // Video volume
  static Future<double> getVideoVolume() async {
    final prefs = await _getPreferences();
    return prefs.videoVolume;
  }

  static Future<void> setVideoVolume(double volume) async {
    await _updatePreferences((prefs) => prefs.videoVolume = volume);
  }

  // Show all comments preference
  static Future<bool> getShowAllComments() async {
    final prefs = await _getPreferences();
    return prefs.showAllComments;
  }

  static Future<void> setShowAllComments(bool value) async {
    await _updatePreferences((prefs) => prefs.showAllComments = value);
  }

  // Switch layout preference
  static Future<String> getSwitchLayout() async {
    final prefs = await _getPreferences();
    return prefs.switchLayout;
  }

  static Future<void> setSwitchLayout(String value) async {
    await _updatePreferences((prefs) => prefs.switchLayout = value);
  }

  // App font path
  static Future<String?> getAppFontPath() async {
    final prefs = await _getPreferences();
    return prefs.appFontPath;
  }

  static Future<void> setAppFontPath(String? path) async {
    await _updatePreferences((prefs) => prefs.appFontPath = path);
  }

  // App font name
  static Future<String?> getAppFontName() async {
    final prefs = await _getPreferences();
    return prefs.appFontName;
  }

  static Future<void> setAppFontName(String? name) async {
    await _updatePreferences((prefs) => prefs.appFontName = name);
  }

  // Last used directory
  static Future<String?> getLastUsedDirectory() async {
    final prefs = await _getPreferences();
    return prefs.lastUsedDirectory;
  }

  static Future<void> setLastUsedDirectory(String? path) async {
    await _updatePreferences((prefs) => prefs.lastUsedDirectory = path);
  }

  // Checkpoint system preferences
  static Future<int> getMaxCheckpoints() async {
    final prefs = await _getPreferences();
    return prefs.maxCheckpoints;
  }

  static Future<void> setMaxCheckpoints(int value) async {
    await _updatePreferences((prefs) => prefs.maxCheckpoints = value);
  }

  static Future<int> getSnapshotInterval() async {
    final prefs = await _getPreferences();
    return prefs.snapshotInterval;
  }

  static Future<void> setSnapshotInterval(int value) async {
    await _updatePreferences((prefs) => prefs.snapshotInterval = value);
  }

  static Future<String> getCheckpointStrategy() async {
    final prefs = await _getPreferences();
    return prefs.checkpointStrategy;
  }

  static Future<void> setCheckpointStrategy(String value) async {
    await _updatePreferences((prefs) => prefs.checkpointStrategy = value);
  }

  // Gemini AI settings
  static Future<String?> getGeminiApiKey() async {
    final prefs = await _getPreferences();
    return prefs.geminiApiKey;
  }

  static Future<void> setGeminiApiKey(String? value) async {
    await _updatePreferences((prefs) => prefs.geminiApiKey = value);
  }

  static Future<String> getGeminiModel() async {
    final prefs = await _getPreferences();
    return prefs.geminiModel;
  }

  static Future<void> setGeminiModel(String value) async {
    await _updatePreferences((prefs) => prefs.geminiModel = value);
  }

  // AI Explanation custom prompt
  static Future<String?> getAiExplanationPrompt() async {
    final prefs = await _getPreferences();
    return prefs.aiExplanationPrompt;
  }

  static Future<void> setAiExplanationPrompt(String? value) async {
    await _updatePreferences((prefs) => prefs.aiExplanationPrompt = value);
  }

  // AI Explanation context lines count
  static Future<int> getAiExplanationContextLines() async {
    final prefs = await _getPreferences();
    return prefs.aiExplanationContextLines ?? 3;
  }

  static Future<void> setAiExplanationContextLines(int value) async {
    await _updatePreferences((prefs) => prefs.aiExplanationContextLines = value);
  }

  // Utility methods
  static Future<void> clearAllPreferences() async {
    await isar.writeTxn(() async {
      await isar.preferences.clear();
    });
  }

  static Future<void> clearResizeSettings() async {
    await _updatePreferences((prefs) {
      prefs.editScreenResizeRatio = 0.35;
      prefs.editLineResizeRatio = 0.35;
      prefs.mobileVideoResizeRatio = 0.4;
      prefs.autoResizeOnKeyboard = true;
    });
  }

  // Video-specific preferences (per subtitle collection)
  
  /// Get or create VideoPreferences for a subtitle collection
  static Future<VideoPreferences> getVideoPreferences(int subtitleCollectionId) async {
    var videoPrefs = await isar.videoPreferences
        .filter()
        .subtitleCollectionIdEqualTo(subtitleCollectionId)
        .findFirst();
    
    if (videoPrefs == null) {
      videoPrefs = VideoPreferences(subtitleCollectionId: subtitleCollectionId);
      await isar.writeTxn(() async {
        await isar.videoPreferences.put(videoPrefs!);
      });
    }
    return videoPrefs;
  }
  
  /// Update video preferences with a transaction
  static Future<void> _updateVideoPreferences(
    int subtitleCollectionId,
    void Function(VideoPreferences) update,
  ) async {
    await isar.writeTxn(() async {
      final videoPrefs = await getVideoPreferences(subtitleCollectionId);
      update(videoPrefs);
      await isar.videoPreferences.put(videoPrefs);
    });
  }
  
  // Video path management
  static Future<String?> getVideoPath(int subtitleCollectionId) async {
    final videoPrefs = await getVideoPreferences(subtitleCollectionId);
    return videoPrefs.videoPath;
  }

  static Future<void> saveVideoPath(int subtitleCollectionId, String path, {String? macOsBookmark}) async {
    await _updateVideoPreferences(
      subtitleCollectionId,
      (prefs) {
        prefs.videoPath = path;
        prefs.macOsBookmark = macOsBookmark;
      },
    );
  }

  static Future<void> removeVideoPath(int subtitleCollectionId) async {
    await _updateVideoPreferences(
      subtitleCollectionId,
      (prefs) {
        prefs.videoPath = null;
        prefs.macOsBookmark = null;
        // Also clear audio track selection when video is removed
        prefs.selectedAudioTrackId = null;
        prefs.selectedAudioTrackTitle = null;
        prefs.selectedAudioTrackLanguage = null;
        // Clear waveform cache when video is removed
        prefs.waveformPcmPath = null;
        prefs.waveformSampleRate = null;
        prefs.waveformTotalSamples = null;
        prefs.waveformChannels = null;
        prefs.waveformGeneratedAt = null;
      },
    );
  }
  
  // Audio track management
  static Future<String?> getSelectedAudioTrackId(int subtitleCollectionId) async {
    final videoPrefs = await getVideoPreferences(subtitleCollectionId);
    return videoPrefs.selectedAudioTrackId;
  }
  
  static Future<Map<String, String?>> getSelectedAudioTrack(int subtitleCollectionId) async {
    final videoPrefs = await getVideoPreferences(subtitleCollectionId);
    return {
      'id': videoPrefs.selectedAudioTrackId,
      'title': videoPrefs.selectedAudioTrackTitle,
      'language': videoPrefs.selectedAudioTrackLanguage,
    };
  }
  
  static Future<void> saveSelectedAudioTrack(
    int subtitleCollectionId, {
    required String trackId,
    String? trackTitle,
    String? trackLanguage,
  }) async {
    await _updateVideoPreferences(
      subtitleCollectionId,
      (prefs) {
        prefs.selectedAudioTrackId = trackId;
        prefs.selectedAudioTrackTitle = trackTitle;
        prefs.selectedAudioTrackLanguage = trackLanguage;
      },
    );
  }
  
  static Future<void> clearSelectedAudioTrack(int subtitleCollectionId) async {
    await _updateVideoPreferences(
      subtitleCollectionId,
      (prefs) {
        prefs.selectedAudioTrackId = null;
        prefs.selectedAudioTrackTitle = null;
        prefs.selectedAudioTrackLanguage = null;
      },
    );
  }

  // Secondary subtitle path management
  static Future<String?> getSecondarySubtitlePath(int subtitleCollectionId) async {
    final videoPrefs = await getVideoPreferences(subtitleCollectionId);
    return videoPrefs.secondarySubtitlePath;
  }

  static Future<void> saveSecondarySubtitlePath(int subtitleCollectionId, String path) async {
    await _updateVideoPreferences(
      subtitleCollectionId,
      (prefs) => prefs.secondarySubtitlePath = path,
    );
  }

  static Future<void> removeSecondarySubtitlePath(int subtitleCollectionId) async {
    await _updateVideoPreferences(
      subtitleCollectionId,
      (prefs) => prefs.secondarySubtitlePath = null,
    );
  }

  static Future<bool> getSecondaryIsOriginal(int subtitleCollectionId) async {
    final videoPrefs = await getVideoPreferences(subtitleCollectionId);
    return videoPrefs.secondaryIsOriginal;
  }

  static Future<void> setSecondaryIsOriginal(int subtitleCollectionId, bool value) async {
    await _updateVideoPreferences(
      subtitleCollectionId,
      (prefs) => prefs.secondaryIsOriginal = value,
    );
  }
  
  // Waveform cache management
  
  /// Save waveform cache data
  static Future<void> saveWaveformCache({
    required int subtitleCollectionId,
    required String pcmPath,
    required int sampleRate,
    required int totalSamples,
    required int channels,
  }) async {
    await _updateVideoPreferences(
      subtitleCollectionId,
      (prefs) {
        prefs.waveformPcmPath = pcmPath;
        prefs.waveformSampleRate = sampleRate;
        prefs.waveformTotalSamples = totalSamples;
        prefs.waveformChannels = channels;
        prefs.waveformGeneratedAt = DateTime.now();
      },
    );
  }
  
  /// Get waveform cache data
  static Future<Map<String, dynamic>?> getWaveformCache(int subtitleCollectionId) async {
    final videoPrefs = await getVideoPreferences(subtitleCollectionId);
    
    // Check if all required waveform data is present
    if (videoPrefs.waveformPcmPath == null ||
        videoPrefs.waveformSampleRate == null ||
        videoPrefs.waveformTotalSamples == null ||
        videoPrefs.waveformChannels == null) {
      return null;
    }
    
    return {
      'pcmPath': videoPrefs.waveformPcmPath,
      'sampleRate': videoPrefs.waveformSampleRate,
      'totalSamples': videoPrefs.waveformTotalSamples,
      'channels': videoPrefs.waveformChannels,
      'generatedAt': videoPrefs.waveformGeneratedAt,
    };
  }
  
  /// Clear waveform cache data
  static Future<void> clearWaveformCache(int subtitleCollectionId) async {
    await _updateVideoPreferences(
      subtitleCollectionId,
      (prefs) {
        prefs.waveformPcmPath = null;
        prefs.waveformSampleRate = null;
        prefs.waveformTotalSamples = null;
        prefs.waveformChannels = null;
        prefs.waveformGeneratedAt = null;
      },
    );
  }
  
  /// Check if waveform cache exists and is valid
  static Future<bool> hasValidWaveformCache(int subtitleCollectionId) async {
    final cache = await getWaveformCache(subtitleCollectionId);
    if (cache == null) return false;
    
    // Check if PCM file still exists
    final pcmPath = cache['pcmPath'] as String;
    final file = File(pcmPath);
    return await file.exists();
  }
  
  // Waveform zoom preferences management
  
  /// Save waveform zoom levels
  static Future<void> saveWaveformZoomLevels({
    required int subtitleCollectionId,
    required int zoomIndex,
    required double verticalZoom,
  }) async {
    await _updateVideoPreferences(
      subtitleCollectionId,
      (prefs) {
        prefs.waveformZoomIndex = zoomIndex;
        prefs.waveformVerticalZoom = verticalZoom;
      },
    );
  }
  
  /// Get waveform zoom levels
  static Future<Map<String, dynamic>?> getWaveformZoomLevels(int subtitleCollectionId) async {
    final videoPrefs = await getVideoPreferences(subtitleCollectionId);
    
    if (videoPrefs.waveformZoomIndex == null || videoPrefs.waveformVerticalZoom == null) {
      return null;
    }
    
    return {
      'zoomIndex': videoPrefs.waveformZoomIndex,
      'verticalZoom': videoPrefs.waveformVerticalZoom,
    };
  }
  
  // Tutorial status management
  
  /// Get or create TutorialStatus for a screen
  static Future<TutorialStatus> _getTutorialStatus(String screenName) async {
    var tutorialStatus = await isar.tutorialStatus
        .filter()
        .screenNameEqualTo(screenName)
        .findFirst();
    
    if (tutorialStatus == null) {
      tutorialStatus = TutorialStatus(screenName: screenName);
      await isar.writeTxn(() async {
        await isar.tutorialStatus.put(tutorialStatus!);
      });
    }
    return tutorialStatus;
  }

  static Future<bool> getHasSeenTutorial(String screenName) async {
    final tutorialStatus = await _getTutorialStatus(screenName);
    return tutorialStatus.hasSeenTutorial;
  }

  static Future<void> setHasSeenTutorial(String screenName, bool value) async {
    await isar.writeTxn(() async {
      final tutorialStatus = await _getTutorialStatus(screenName);
      tutorialStatus.hasSeenTutorial = value;
      await isar.tutorialStatus.put(tutorialStatus);
    });
  }
  
  // Waveform settings
  /// Get maximum pixels for detailed waveform view
  /// Default: 500000 (500K pixels)
  /// Higher values = more zoom detail but slower generation
  static Future<int> getWaveformMaxPixels() async {
    final prefs = await _getPreferences();
    return prefs.waveformMaxPixels ?? 500000;
  }

  static Future<void> setWaveformMaxPixels(int value) async {
    await _updatePreferences((prefs) => prefs.waveformMaxPixels = value);
  }

  /// Get waveform sample rate downsampling factor
  /// Default: 16 (44100Hz / 16 ≈ 2756Hz)
  /// Lower values = more detail but larger data size
  static Future<int> getWaveformSampleRateFactor() async {
    final prefs = await _getPreferences();
    return prefs.waveformSampleRateFactor ?? 16;
  }

  static Future<void> setWaveformSampleRateFactor(int value) async {
    await _updatePreferences((prefs) => prefs.waveformSampleRateFactor = value);
  }

  /// Get waveform zoom multiplier base
  /// Default: 1.25 (used for calculating zoom levels)
  /// Smaller values = more zoom steps but more processing
  static Future<double> getWaveformZoomMultiplier() async {
    final prefs = await _getPreferences();
    return prefs.waveformZoomMultiplier ?? 1.25;
  }

  static Future<void> setWaveformZoomMultiplier(double value) async {
    await _updatePreferences((prefs) => prefs.waveformZoomMultiplier = value);
  }

  // Session sorting
  static Future<SessionSortOption> getSessionSortOption() async {
    final prefs = await _getPreferences();
    return prefs.sessionSortOption;
  }

  static Future<void> setSessionSortOption(SessionSortOption value) async {
    await _updatePreferences((prefs) => prefs.sessionSortOption = value);
  }
  
  // Utility method to clear all video preferences for a subtitle collection
  static Future<void> clearVideoPreferences(int subtitleCollectionId) async {
    await isar.writeTxn(() async {
      final videoPrefs = await isar.videoPreferences
          .filter()
          .subtitleCollectionIdEqualTo(subtitleCollectionId)
          .findFirst();
      if (videoPrefs != null) {
        await isar.videoPreferences.delete(videoPrefs.id);
      }
    });
  }
  
}
