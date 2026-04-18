import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';

/// Service to fetch and manage available Gemini AI models
class GeminiModelsService {
  static List<GeminiModel>? _cachedModels;
  static DateTime? _lastFetch;
  static const _cacheDuration = Duration(hours: 24);

  /// Fetch available models from Gemini API
  /// Returns cached models if available and not expired
  static Future<List<GeminiModel>> fetchAvailableModels({
    bool forceRefresh = false,
  }) async {
    // Return cached models if available and not expired
    if (!forceRefresh &&
        _cachedModels != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      logInfo('Returning cached Gemini models (${_cachedModels!.length} models)');
      return _cachedModels!;
    }

    try {
      final apiKey = await PreferencesModel.getGeminiApiKey();
      
      if (apiKey == null || apiKey.isEmpty) {
        logWarning('No Gemini API key configured, returning empty model list');
        return [];
      }

      // Initialize Gemini if not already initialized
      try {
        Gemini.init(apiKey: apiKey);
      } catch (e) {
        // Already initialized, ignore
      }

      logInfo('Fetching available Gemini models from API...');
      final models = await Gemini.instance.listModels();
      
      // Filter only models that support generateContent
      final supportedModels = models.where((model) {
        return model.supportedGenerationMethods
                ?.contains('generateContent') ??
            false;
      }).toList();

      // Sort by name
      supportedModels.sort((a, b) {
        final nameA = a.name ?? '';
        final nameB = b.name ?? '';
        return nameA.compareTo(nameB);
      });

      _cachedModels = supportedModels;
      _lastFetch = DateTime.now();

      logInfo('Fetched ${supportedModels.length} supported Gemini models');
      return supportedModels;
    } catch (e) {
      logError('Failed to fetch Gemini models: $e');
      
      // Return default models as fallback
      return _getDefaultModels();
    }
  }

  /// Get display name for a model
  static String getModelDisplayName(String modelName) {
    if (_cachedModels != null) {
      final model = _cachedModels!.firstWhere(
        (m) => m.name == modelName,
        orElse: () => GeminiModel(name: modelName, displayName: modelName),
      );
      return model.displayName ?? _formatModelName(modelName);
    }
    return _formatModelName(modelName);
  }

  /// Format model name for display
  static String _formatModelName(String modelName) {
    // Remove 'models/' prefix
    final name = modelName.replaceFirst('models/', '');
    
    // Convert to title case and add spaces
    return name
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get default models as fallback
  static List<GeminiModel> _getDefaultModels() {
    return [
      GeminiModel(
        name: 'models/gemini-2.5-flash',
        displayName: 'Gemini 2.5 Flash',
        description: 'Fast and efficient for most tasks',
      ),
      GeminiModel(
        name: 'models/gemini-2.5-pro',
        displayName: 'Gemini 2.5 Pro',
        description: 'Most powerful for complex tasks',
      ),
      GeminiModel(
        name: 'models/gemini-2.0-flash-exp',
        displayName: 'Gemini 2.0 Flash (Experimental)',
        description: 'Experimental features',
      ),
    ];
  }

  /// Clear cached models
  static void clearCache() {
    _cachedModels = null;
    _lastFetch = null;
    logInfo('Cleared Gemini models cache');
  }
}
