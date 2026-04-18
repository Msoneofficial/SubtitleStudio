import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';
import 'ai_explanation_state.dart';

/// Cubit for managing AI explanation feature
/// Handles business logic separate from UI
/// Uses Gemini AI to explain subtitle dialogues in context
class AiExplanationCubit extends Cubit<AiExplanationState> {
  AiExplanationCubit() : super(const AiExplanationInitial());

  /// Get explanation for a dialogue with context
  /// 
  /// Parameters:
  /// - currentLine: The subtitle line to explain
  /// - previousLines: Previous subtitle lines for context (max 3)
  /// - nextLines: Next subtitle lines for context (max 3)
  /// - modelName: The Gemini model to use (defaults to stored preference)
  /// - customPrompt: Custom prompt template to use (defaults to stored preference)
  Future<void> getExplanation({
    required String currentLine,
    List<String>? previousLines,
    List<String>? nextLines,
    String? modelName,
    String? customPrompt,
  }) async {
    // Get model and prompt early so they're available for error messages
    String? model;
    String prompt = '';
    
    try {
      // Check if API key is configured
      final apiKey = await PreferencesModel.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        emit(const AiExplanationNoApiKey());
        return;
      }

      emit(const AiExplanationLoading());

      // Initialize Gemini with API key if not already initialized
      // Note: Reinitializing is safe and updates the API key
      Gemini.init(apiKey: apiKey);
      final gemini = Gemini.instance;

      // Get model name from parameter or preferences
      model = modelName ?? await PreferencesModel.getGeminiModel();
      
      logInfo('API Key (first 10 chars): ${apiKey.substring(0, apiKey.length > 10 ? 10 : apiKey.length)}...');
      logInfo('Selected model: $model');

      // Get prompt template from parameter or preferences
      final promptTemplate = customPrompt ?? await PreferencesModel.getAiExplanationPrompt();

      // Build context-aware prompt
      prompt = _buildPrompt(
        currentLine: currentLine,
        previousLines: previousLines ?? [],
        nextLines: nextLines ?? [],
        promptTemplate: promptTemplate,
      );

      logInfo('Requesting AI explanation for dialogue using model: $model');
      logDebug('Prompt: $prompt');

      // Use the deprecated text() method for compatibility
      // The newer prompt() method seems to have issues on Windows
      final response = await gemini.text(prompt, modelName: model);

      if (response?.output == null || response!.output!.isEmpty) {
        emit(const AiExplanationError(
          'No explanation received from AI. Please try again.',
        ));
        return;
      }

      final explanation = response.output!;
      logInfo('Received AI explanation successfully');
      emit(AiExplanationSuccess(explanation));
    } catch (e, stackTrace) {
      // Log full error details for debugging
      logError('Error getting AI explanation: $e');
      logError('Stack trace: $stackTrace');
      logError('Model used: $model');
      logError('Prompt length: ${prompt.length} characters');
      
      String errorMessage = 'Failed to get explanation. ';
      
      // Check if it's a GeminiException and try to get more details
      if (e.runtimeType.toString().contains('GeminiException')) {
        logError('GeminiException details: $e');
        
        // Try to extract HTTP response details if available
        final errorString = e.toString();
        
        // Look for specific error patterns in the exception
        if (errorString.contains('429')) {
          // Rate limit exceeded - most common issue
          errorMessage += 'Rate limit exceeded (429). You have made too many requests to the Gemini API.\n\n';
          errorMessage += 'Solutions:\n';
          errorMessage += '• Wait a few minutes before trying again\n';
          errorMessage += '• Check your API quota in Google Cloud Console\n';
          errorMessage += '• Consider upgrading your API plan for higher limits\n';
          errorMessage += '• Free tier: 15 requests per minute, 1500 per day';
        } else if (errorString.contains('API_KEY_INVALID') || errorString.contains('invalid api key')) {
          errorMessage += 'Your API key is invalid. Please check your Gemini API key in settings.';
        } else if (errorString.contains('MODEL_NOT_FOUND') || errorString.contains('model not found')) {
          errorMessage += 'The model "$model" was not found. Try using "models/gemini-1.5-flash" instead.';
        } else if (errorString.contains('PERMISSION_DENIED') || errorString.contains('permission denied')) {
          errorMessage += 'Permission denied. Your API key may not have access to the model "$model". Check your Google Cloud Console settings.';
        } else if (errorString.contains('RESOURCE_EXHAUSTED') || errorString.contains('quota')) {
          errorMessage += 'API quota exceeded. Please check your quota limits in Google Cloud Console or try again later.';
        } else if (errorString.contains('400')) {
          // Generic 400 error - could be various issues
          errorMessage += 'Bad Request (400). This usually means:\n\n';
          errorMessage += '• The model "$model" may not be available\n';
          errorMessage += '• Your API key lacks permissions for this model\n';
          errorMessage += '• The request format is incorrect\n\n';
          errorMessage += 'Try:\n';
          errorMessage += '1. Use "models/gemini-1.5-flash" instead\n';
          errorMessage += '2. Verify your API key is correct\n';
          errorMessage += '3. Check Google Cloud Console for API restrictions\n\n';
          errorMessage += 'Full error: ${e.toString().substring(0, e.toString().length > 200 ? 200 : e.toString().length)}...';
        } else {
          errorMessage += 'Unexpected error.\n\nError details: ${errorString.substring(0, errorString.length > 300 ? 300 : errorString.length)}...';
        }
      } else {
        // Non-GeminiException errors
        final errorString = e.toString().toLowerCase();
        
        if (errorString.contains('401') || errorString.contains('unauthorized')) {
          errorMessage += 'Unauthorized (401). Your API key is invalid or expired.';
        } else if (errorString.contains('403') || errorString.contains('forbidden')) {
          errorMessage += 'Access forbidden (403). Your API key may not have permission to use this model.';
        } else if (errorString.contains('404')) {
          errorMessage += 'Model not found (404). The model "$model" does not exist.';
        } else if (errorString.contains('429')) {
          errorMessage += 'Rate limit exceeded (429). Too many requests. Please wait and try again.';
        } else if (errorString.contains('500') || errorString.contains('503')) {
          errorMessage += 'Server error (${errorString.contains('500') ? '500' : '503'}). Gemini service is temporarily unavailable.';
        } else if (errorString.contains('network') || errorString.contains('connection') || errorString.contains('socket')) {
          errorMessage += 'Network error. Please check your internet connection.';
        } else {
          errorMessage += 'Unexpected error occurred.\n\nError: ${e.toString().substring(0, e.toString().length > 300 ? 300 : e.toString().length)}';
        }
      }
      
      emit(AiExplanationError(errorMessage));
    }
  }

  /// Build a context-aware prompt for the AI
  String _buildPrompt({
    required String currentLine,
    required List<String> previousLines,
    required List<String> nextLines,
    String? promptTemplate,
  }) {
    // Use default prompt if no custom template provided
    final template = promptTemplate ?? '''You are a helpful assistant that explains dialogue in movies, TV shows, or videos.
Analyze the following dialogue and provide a clear, concise explanation:

{CONTEXT}

Please provide:
1. The meaning of the dialogue in simple terms
2. Any cultural references, idioms, or wordplay explained
3. The emotional tone or subtext if relevant
4. How it relates to the surrounding context

Keep the explanation concise and easy to understand.''';

    final contextBuffer = StringBuffer();
    
    // Add previous context if available
    if (previousLines.isNotEmpty) {
      contextBuffer.writeln('Previous dialogue (for context):');
      for (final line in previousLines) {
        contextBuffer.writeln('- $line');
      }
      contextBuffer.writeln();
    }
    
    // Add current line (the main focus)
    contextBuffer.writeln('Current dialogue (explain this):');
    contextBuffer.writeln('>>> $currentLine');
    contextBuffer.writeln();
    
    // Add next context if available
    if (nextLines.isNotEmpty) {
      contextBuffer.writeln('Following dialogue (for context):');
      for (final line in nextLines) {
        contextBuffer.writeln('- $line');
      }
      contextBuffer.writeln();
    }
    
    // Replace {CONTEXT} placeholder with actual context
    return template.replaceAll('{CONTEXT}', contextBuffer.toString().trim());
  }

  /// Reset to initial state
  void reset() {
    emit(const AiExplanationInitial());
  }
}
