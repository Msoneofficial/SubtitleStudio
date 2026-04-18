import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subtitle_studio/features/ai_explanation/ai_explanation_cubit.dart';
import 'package:subtitle_studio/features/ai_explanation/ai_explanation_state.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';

/// AI Explanation Button Widget
/// 
/// Displays a button below the subtitle text field that triggers AI explanations
/// Only visible when a Gemini API key is configured
/// Follows clean architecture with separated UI and business logic
class AiExplanationButton extends StatefulWidget {
  final String currentLine;
  final List<String> previousLines;
  final List<String> nextLines;

  const AiExplanationButton({
    super.key,
    required this.currentLine,
    this.previousLines = const [],
    this.nextLines = const [],
  });

  @override
  State<AiExplanationButton> createState() => _AiExplanationButtonState();
}

class _AiExplanationButtonState extends State<AiExplanationButton> {
  bool _hasApiKey = false;
  bool _isCheckingApiKey = true;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  /// Check if API key is configured
  Future<void> _checkApiKey() async {
    final apiKey = await PreferencesModel.getGeminiApiKey();
    if (mounted) {
      setState(() {
        _hasApiKey = apiKey != null && apiKey.isNotEmpty;
        _isCheckingApiKey = false;
      });
    }
  }

  /// Show explanation bottom sheet with AI response
  void _showExplanationSheet(String explanation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: mutedColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: primaryColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Explanation',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Powered by Google Gemini',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Context Information
                        if (widget.previousLines.isNotEmpty || widget.nextLines.isNotEmpty) ...[
                          Text(
                            'Context Used',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.previousLines.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        color: mutedColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${widget.previousLines.length} previous line(s)',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: mutedColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Current line',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: mutedColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.nextLines.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_forward,
                                        color: mutedColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${widget.nextLines.length} next line(s)',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: mutedColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Current Line
                        Text(
                          'Analyzed Text',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: SelectableText(
                            widget.currentLine,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Explanation
                        Text(
                          'Explanation',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: SelectableText(
                            explanation,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Close Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Got it',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Trigger AI explanation
  void _getExplanation(BuildContext context) {
    final cubit = context.read<AiExplanationCubit>();
    
    // Validate that current line is not empty
    if (widget.currentLine.trim().isEmpty) {
      _showErrorDialog('Please enter some text to get an explanation.');
      return;
    }

    logInfo('Requesting AI explanation for dialogue');
    cubit.getExplanation(
      currentLine: widget.currentLine,
      previousLines: widget.previousLines,
      nextLines: widget.nextLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show button while checking API key
    if (_isCheckingApiKey) {
      return const SizedBox.shrink();
    }

    // Don't show button if no API key is configured
    if (!_hasApiKey) {
      return const SizedBox.shrink();
    }

    return BlocConsumer<AiExplanationCubit, AiExplanationState>(
      listener: (context, state) {
        if (state is AiExplanationSuccess) {
          _showExplanationSheet(state.explanation);
          // Reset state after showing sheet
          context.read<AiExplanationCubit>().reset();
        } else if (state is AiExplanationError) {
          _showErrorDialog(state.message);
          // Reset state after showing error
          context.read<AiExplanationCubit>().reset();
        } else if (state is AiExplanationNoApiKey) {
          _showErrorDialog(
            'Gemini API key not configured. Please add your API key in settings.',
          );
          context.read<AiExplanationCubit>().reset();
        }
      },
      builder: (context, state) {
        final isLoading = state is AiExplanationLoading;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: isLoading
                    ? [Colors.grey.shade300, Colors.grey.shade400]
                    : [
                        Colors.deepPurple.withOpacity(0.1),
                        Colors.purple.withOpacity(0.1),
                      ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : () => _getExplanation(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.deepPurple,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.deepPurple,
                          size: 20,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        isLoading
                            ? 'Getting AI Explanation...'
                            : 'Explain with AI',
                        style: TextStyle(
                          color: isLoading ? Colors.grey : Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
