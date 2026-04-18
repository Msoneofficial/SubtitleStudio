import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:subtitle_studio/features/ai_explanation/ai_explanation_cubit.dart';
import 'package:subtitle_studio/features/ai_explanation/ai_explanation_state.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/themes/theme_provider.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/services/gemini_models_service.dart';

/// Widget for showing AI-powered explanations of subtitle text
/// Uses Google Gemini to provide context-aware explanations
class AiExplanationSheet {
  /// Default AI prompt template
  static const String defaultPrompt = '''You are a helpful assistant that explains dialogue in movies, TV shows, or videos.
Analyze the following dialogue and provide a clear, concise explanation:

{CONTEXT}

Please provide:
1. The meaning of the dialogue in simple terms
2. Any cultural references, idioms, or wordplay explained
3. The emotional tone or subtext if relevant
4. How it relates to the surrounding context

Keep the explanation concise and easy to understand.''';
  
  /// Available Gemini models (with models/ prefix as used by Gemini API)
  static const List<String> availableModels = [
    'models/gemini-2.5-flash',
    'models/gemini-2.5-flash-lite',
    'models/gemini-2.0-flash',
    'models/gemini-1.5-flash',
    'models/gemini-1.5-pro',
  ];

  /// Show AI explanation for the given text with optional context
  static Future<void> show({
    required BuildContext context,
    required AiExplanationCubit aiExplanationCubit,
    required String currentText,
    List<String>? previousLines,
    List<String>? nextLines,
    List<String>? allLines,
    int? currentIndex,
    List<String>? originalAllLines,
    List<String>? editedAllLines,
  }) async {
    // Validate input text
    if (currentText.trim().isEmpty) {
      if (!context.mounted) return;
      SnackbarHelper.showError(
        context,
        'Please enter some text to get an explanation.',
      );
      return;
    }

    // Check if API key is configured
    final apiKey = await PreferencesModel.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      if (!context.mounted) return;
      SnackbarHelper.showError(
        context,
        'Gemini API key not configured. Please add your API key in settings.',
      );
      return;
    }

    // Show the sheet
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AiExplanationSheetContent(
        aiExplanationCubit: aiExplanationCubit,
        currentText: currentText,
        initialPreviousLines: previousLines ?? [],
        initialNextLines: nextLines ?? [],
        allLines: allLines ?? [],
        currentIndex: currentIndex ?? 0,
        originalAllLines: originalAllLines,
        editedAllLines: editedAllLines,
      ),
    );
  }

  /// Build prompt from template by replacing placeholders
  static String buildPromptFromTemplate({
    required String template,
    required String currentText,
    required List<String> previousLines,
    required List<String> nextLines,
  }) {
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
    contextBuffer.writeln('>>> $currentText');
    contextBuffer.writeln();
    
    // Add next context if available
    if (nextLines.isNotEmpty) {
      contextBuffer.writeln('Following dialogue (for context):');
      for (final line in nextLines) {
        contextBuffer.writeln('- $line');
      }
      contextBuffer.writeln();
    }
    
    return template.replaceAll('{CONTEXT}', contextBuffer.toString().trim());
  }
}

/// Stateful content widget for the AI Explanation Sheet
class _AiExplanationSheetContent extends StatefulWidget {
  final AiExplanationCubit aiExplanationCubit;
  final String currentText;
  final List<String> initialPreviousLines;
  final List<String> initialNextLines;
  final List<String> allLines;
  final int currentIndex;
  final List<String>? originalAllLines;
  final List<String>? editedAllLines;

  const _AiExplanationSheetContent({
    required this.aiExplanationCubit,
    required this.currentText,
    required this.initialPreviousLines,
    required this.initialNextLines,
    required this.allLines,
    required this.currentIndex,
    this.originalAllLines,
    this.editedAllLines,
  });

  @override
  State<_AiExplanationSheetContent> createState() => _AiExplanationSheetContentState();
}

class _AiExplanationSheetContentState extends State<_AiExplanationSheetContent> {
  bool _isEditingPrompt = false;
  late TextEditingController _promptController;
  String? _customPrompt;
  String? _currentModel;
  int _contextLinesCount = 3;
  late List<String> _currentPreviousLines;
  late List<String> _currentNextLines;
  List<GeminiModel> _availableModels = [];
  bool _isLoadingModels = false;
  bool _hasGeneratedExplanation = false;
  String _contextMode = 'Original'; // 'Original' or 'Edited'
  late String _currentAnalyzedText;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    // Initialize context lines with initial values from widget
    _currentPreviousLines = widget.initialPreviousLines;
    _currentNextLines = widget.initialNextLines;
    // Initialize analyzed text based on context mode
    _currentAnalyzedText = _getAnalyzedText();
    _loadSettings();
    _fetchAvailableModels();
  }

  Future<void> _loadSettings() async {
    final prompt = await PreferencesModel.getAiExplanationPrompt();
    final model = await PreferencesModel.getGeminiModel();
    final contextLines = await PreferencesModel.getAiExplanationContextLines();
    
    setState(() {
      _customPrompt = prompt;
      _currentModel = model;
      _contextLinesCount = contextLines;
      _promptController.text = prompt ?? AiExplanationSheet.defaultPrompt;
    });

    // Recalculate context lines based on saved setting
    _recalculateContextLines();
  }

  void _recalculateContextLines() {
    setState(() {
      _currentPreviousLines = [];
      _currentNextLines = [];

      // Determine which lines to use based on context mode
      final List<String> linesToUse = _getContextLines();

      if (linesToUse.isNotEmpty && widget.currentIndex >= 0) {
        // Get previous lines
        for (int i = widget.currentIndex - 1; i >= 0 && i >= widget.currentIndex - _contextLinesCount; i--) {
          _currentPreviousLines.insert(0, linesToUse[i]);
        }

        // Get next lines
        for (int i = widget.currentIndex + 1; i < linesToUse.length && i <= widget.currentIndex + _contextLinesCount; i++) {
          _currentNextLines.add(linesToUse[i]);
        }
      }
    });
  }

  List<String> _getContextLines() {
    // If both original and edited lines are available, use the selected mode
    if (widget.originalAllLines != null && widget.editedAllLines != null) {
      return _contextMode == 'Original' ? widget.originalAllLines! : widget.editedAllLines!;
    }
    // Otherwise, fall back to the default allLines
    return widget.allLines;
  }

  String _getAnalyzedText() {
    // If both original and edited lines are available, get text from the appropriate list
    if (widget.originalAllLines != null && widget.editedAllLines != null && widget.currentIndex >= 0) {
      final lines = _contextMode == 'Original' ? widget.originalAllLines! : widget.editedAllLines!;
      if (widget.currentIndex < lines.length) {
        return lines[widget.currentIndex];
      }
    }
    // Otherwise, use the current text passed to the widget
    return widget.currentText;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _savePrompt() async {
    await PreferencesModel.setAiExplanationPrompt(_promptController.text);
    setState(() {
      _customPrompt = _promptController.text;
      _isEditingPrompt = false;
    });
    if (!mounted) return;
    SnackbarHelper.showSuccess(context, 'Prompt saved successfully');
  }

  Future<void> _resetPrompt() async {
    await PreferencesModel.setAiExplanationPrompt(null);
    setState(() {
      _customPrompt = null;
      _promptController.text = AiExplanationSheet.defaultPrompt;
    });
    if (!mounted) return;
    SnackbarHelper.showSuccess(context, 'Prompt reset to default');
  }

  Future<void> _generateExplanation({bool closeEditMode = false}) async {
    // Close edit mode if requested (e.g., from "Try Without Saving")
    if (closeEditMode && _isEditingPrompt) {
      setState(() {
        _isEditingPrompt = false;
      });
    }
    
    setState(() {
      _hasGeneratedExplanation = true;
    });
    
    // Trigger AI explanation with current context, model, and prompt
    widget.aiExplanationCubit.getExplanation(
      currentLine: _currentAnalyzedText,
      previousLines: _currentPreviousLines,
      nextLines: _currentNextLines,
      modelName: _currentModel,
      customPrompt: _isEditingPrompt ? _promptController.text : _customPrompt,
    );
  }

  void _adjustContextLines(int delta) {
    final newCount = (_contextLinesCount + delta).clamp(0, 10);
    if (newCount == _contextLinesCount) return;

    setState(() {
      _contextLinesCount = newCount;
    });

    _recalculateContextLines();
    PreferencesModel.setAiExplanationContextLines(newCount);
  }

  Future<void> _changeModel(String? newModel) async {
    if (newModel == null || newModel == _currentModel) return;
    await PreferencesModel.setGeminiModel(newModel);
    setState(() {
      _currentModel = newModel;
    });
    if (!mounted) return;
    final modelName = newModel.replaceFirst('models/', '');
    SnackbarHelper.showSuccess(context, 'Model changed to $modelName');
  }

  /// Get a valid dropdown value that exists in the available models list
  String? _getValidDropdownValue() {
    if (_availableModels.isEmpty) return null;
    
    // Normalize current model name
    final normalizedCurrentModel = _currentModel != null
        ? (_currentModel!.startsWith('models/')
            ? _currentModel
            : 'models/$_currentModel')
        : null;
    
    // Check if current model exists in available models
    if (normalizedCurrentModel != null) {
      final modelExists = _availableModels.any((m) => m.name == normalizedCurrentModel);
      if (modelExists) return normalizedCurrentModel;
    }
    
    // If current model doesn't exist, return the first available model
    return _availableModels.first.name;
  }

  /// Fetch available Gemini models from API
  Future<void> _fetchAvailableModels() async {
    setState(() {
      _isLoadingModels = true;
    });

    try {
      final models = await GeminiModelsService.fetchAvailableModels();
      if (mounted) {
        setState(() {
          _availableModels = models;
          _isLoadingModels = false;
        });

        // Validate current model against fetched models
        if (_availableModels.isNotEmpty && _currentModel != null) {
          final normalizedCurrentModel = _currentModel!.startsWith('models/')
              ? _currentModel!
              : 'models/$_currentModel';
          
          final currentModelExists = _availableModels.any(
            (m) => m.name == normalizedCurrentModel,
          );

          if (!currentModelExists) {
            // Set to first available model
            final newModel = _availableModels.first.name ?? 'models/gemini-2.5-flash';
            await PreferencesModel.setGeminiModel(newModel);
            setState(() {
              _currentModel = newModel;
            });
          } else if (_currentModel != normalizedCurrentModel) {
            // Update to normalized format
            setState(() {
              _currentModel = normalizedCurrentModel;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Provider.of<ThemeProvider>(context, listen: false).themeMode == ThemeMode.light;
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    return DraggableScrollableSheet(
      initialChildSize: 0.99,
      minChildSize: 0.5,
      maxChildSize: 0.99,
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
                      // Header with model info and actions
                      _buildHeader(context, primaryColor, mutedColor),

                      const SizedBox(height: 16),

                      // Model and Context Controls
                      _buildControlsRow(context, primaryColor, mutedColor, borderColor),

                      const SizedBox(height: 24),

                      // Prompt Editor (if editing)
                      if (_isEditingPrompt) ...[
                        _buildPromptEditor(context, primaryColor, mutedColor, borderColor),
                        const SizedBox(height: 24),
                      ],

                      // Context Information
                      if (!_isEditingPrompt && (_currentPreviousLines.isNotEmpty || _currentNextLines.isNotEmpty))
                        _buildContextInfo(context, isLightTheme, onSurfaceColor, mutedColor, borderColor),

                      // Current Line
                      if (!_isEditingPrompt)
                        _buildAnalyzedText(context, primaryColor),

                      if (!_isEditingPrompt) const SizedBox(height: 24),

                      // Explanation with StreamBuilder
                      if (!_isEditingPrompt && _hasGeneratedExplanation)
                        _buildExplanation(context, isLightTheme, primaryColor, onSurfaceColor, mutedColor, borderColor),

                      const SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButtons(context, primaryColor),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor, Color mutedColor) {
    return Container(
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
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isEditingPrompt = !_isEditingPrompt;
                if (!_isEditingPrompt) {
                  _promptController.text = _customPrompt ?? AiExplanationSheet.defaultPrompt;
                }
              });
            },
            icon: Icon(
              _isEditingPrompt ? Icons.close : Icons.edit,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            label: Text(
              _isEditingPrompt ? 'Cancel' : 'Edit Prompt',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(BuildContext context, Color primaryColor, Color mutedColor, Color borderColor) {
    final bool hasOriginalAndEdited = widget.originalAllLines != null && widget.editedAllLines != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model Selection
          Row(
            children: [
              Icon(Icons.memory, size: 16, color: mutedColor),
              const SizedBox(width: 8),
              Text(
                'Model:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              if (_isLoadingModels)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_availableModels.isEmpty)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  iconSize: 20,
                  onPressed: _fetchAvailableModels,
                  tooltip: 'Refresh models',
                )
              else
                Expanded(
                  child: DropdownButton<String>(
                    value: _getValidDropdownValue(),
                    isExpanded: true,
                    underline: Container(),
                    items: _availableModels.map((model) {
                      final modelName = model.name ?? '';
                      final displayName = model.displayName ?? 
                          GeminiModelsService.getModelDisplayName(modelName);
                      return DropdownMenuItem(
                        value: modelName,
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }).toList(),
                    onChanged: _changeModel,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Context Mode Selector (only show if both original and edited are available)
          if (hasOriginalAndEdited) ...[
            Row(
              children: [
                Icon(Icons.swap_horiz, size: 16, color: mutedColor),
                const SizedBox(width: 8),
                Text(
                  'Context:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'Original',
                        label: Text('Original'),
                        // icon: Icon(Icons.source, size: 16),
                      ),
                      ButtonSegment<String>(
                        value: 'Edited',
                        label: Text('Edited'),
                        // icon: Icon(Icons.edit, size: 16),
                      ),
                    ],
                    selected: {_contextMode},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _contextMode = newSelection.first;
                        _currentAnalyzedText = _getAnalyzedText();
                      });
                      _recalculateContextLines();
                    },
                    style: ButtonStyle(
                      textStyle: WidgetStateProperty.all(
                        Theme.of(context).textTheme.bodySmall,
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return primaryColor;
                          }
                          return Colors.transparent;
                        },
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return Theme.of(context).colorScheme.onSurface;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Context Lines Adjustment
          Row(
            children: [
              Icon(Icons.format_list_numbered, size: 16, color: mutedColor),
              const SizedBox(width: 8),
              Text(
                'Context lines: $_contextLinesCount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove),
                iconSize: 20,
                onPressed: () => _adjustContextLines(-1),
                tooltip: 'Decrease context',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                iconSize: 20,
                onPressed: () => _adjustContextLines(1),
                tooltip: 'Increase context',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptEditor(BuildContext context, Color primaryColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Custom Prompt',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _resetPrompt,
              icon: const Icon(Icons.restore, size: 16),
              label: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Use {CONTEXT} as a placeholder for the dialogue context',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: mutedColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _promptController,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: 'Enter your custom prompt...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Buttons layout: Column on mobile, Row on desktop
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            if (isMobile) {
              // Mobile: Stack buttons vertically
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _savePrompt();
                        _generateExplanation();
                      },
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save & Generate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _generateExplanation(closeEditMode: true),
                      icon: Icon(
                        Icons.refresh,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      label: Text(
                        'Generate Without Saving',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Desktop: Buttons side by side
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _savePrompt();
                        _generateExplanation();
                      },
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save & Generate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _generateExplanation(closeEditMode: true),
                      icon: Icon(
                        Icons.refresh,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      label: Text(
                        'Generate Without Saving',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildContextInfo(BuildContext context, bool isLightTheme, Color onSurfaceColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            color: !isLightTheme ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentPreviousLines.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.arrow_back, color: mutedColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentPreviousLines.length} previous line(s)',
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
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
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
              if (_currentNextLines.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.arrow_forward, color: mutedColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentNextLines.length} next line(s)',
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
    );
  }

  Widget _buildAnalyzedText(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            _currentAnalyzedText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExplanation(BuildContext context, bool isLightTheme, Color primaryColor, Color onSurfaceColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explanation',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity, // Make loading indicator span full width
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: !isLightTheme ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: StreamBuilder<AiExplanationState>(
            stream: widget.aiExplanationCubit.stream,
            initialData: widget.aiExplanationCubit.state,
            builder: (context, snapshot) {
              final state = snapshot.data;

              if (state is AiExplanationLoading) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Generating explanation...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              } else if (state is AiExplanationError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              } else if (state is AiExplanationSuccess) {
                return MarkdownBody(
                  data: state.explanation,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: onSurfaceColor,
                    ),
                    h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurfaceColor,
                    ),
                    h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurfaceColor,
                    ),
                    h3: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurfaceColor,
                    ),
                    code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      backgroundColor: onSurfaceColor.withValues(alpha: 0.1),
                      color: onSurfaceColor,
                    ),
                    blockquote: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: mutedColor,
                    ),
                    listBullet: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: onSurfaceColor,
                    ),
                    listIndent: 16,
                  ),
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Initializing...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: _hasGeneratedExplanation
                ? OutlinedButton.icon(
                    onPressed: _generateExplanation,
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    label: Text(
                      'Retry',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _generateExplanation,
                    icon: const Icon(Icons.auto_awesome, size: 20),
                    label: const Text(
                      'Generate Explanation',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
        ),
        if (_hasGeneratedExplanation)
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
    );
  }
}
