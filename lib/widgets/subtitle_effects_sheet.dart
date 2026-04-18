import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:subtitle_studio/database/models/models.dart';
import '../utils/time_parser.dart';

class SubtitleEffectsSheet extends StatefulWidget {
  final List<int> selectedIndices;
  final Function(String effectType, Map<String, dynamic> effectConfig) onApplyEffect;
  final List<SubtitleLine>? subtitleLines; // Optional: for single line effects
  final int? subtitleCollectionId; // Optional: for database operations
  final String? lineText; // Optional: for single line text selection

  const SubtitleEffectsSheet({
    super.key,
    required this.selectedIndices,
    required this.onApplyEffect,
    this.subtitleLines,
    this.subtitleCollectionId,
    this.lineText,
  });

  @override
  State<SubtitleEffectsSheet> createState() => _SubtitleEffectsSheetState();
}

class _SubtitleEffectsSheetState extends State<SubtitleEffectsSheet> with SingleTickerProviderStateMixin {
  String _selectedEffect = 'karaoke';
  Color _karaokeColor = Colors.yellow;
  Color _typewriterColor = Colors.white;
  double _endDelay = 0.0; // End delay in seconds (0.0 to 1.0)
  String _karaokeEffectType = 'word'; // 'word' or 'character'
  bool _isProcessing = false;
  // Preview animation
  late AnimationController _previewController;
  double _previewProgress = 0.0; // 0.0 - 1.0 across the animation part
  bool _isPreviewPlaying = false;
  Duration _lineDuration = const Duration(seconds: 3); // total available duration (from subtitle times)
  Duration _animDuration = const Duration(seconds: 3); // duration used for the animated reveal (subtracting endDelay)
  Duration _endDelayDuration = Duration.zero;
  Timer? _postDelayTimer;
  
  // Text selection for karaoke effect
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    // Initialize text controller with the line text if available
    final initialText = widget.lineText ?? '';
    _textController = TextEditingController(text: initialText);
    _previewController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))
      ..addListener(() {
        setState(() {
          _previewProgress = _previewController.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Keep full text visible for endDelay, then stop
          if (_endDelayDuration > Duration.zero) {
            _postDelayTimer?.cancel();
            _postDelayTimer = Timer(_endDelayDuration, () {
              setState(() => _isPreviewPlaying = false);
            });
          } else {
            setState(() => _isPreviewPlaying = false);
          }
        }
      });
    _recomputePreviewDurations();
  }

  @override
  void dispose() {
  _previewController.dispose();
  _postDelayTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic color variables for adaptive theming
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
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
                            "Add Effects",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Apply visual effects to ${widget.selectedIndices.length} selected subtitle${widget.selectedIndices.length > 1 ? 's' : ''}",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: mutedColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "This is a beta feature. Use with caution.",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Effect Selection Cards
              Column(
                children: [
                  // Karaoke Effect Card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedEffect = 'karaoke'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedEffect == 'karaoke' 
                              ? primaryColor.withValues(alpha: 0.1)
                              : (isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedEffect == 'karaoke' 
                                ? primaryColor.withValues(alpha: 0.3)
                                : borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.music_note,
                                color: onSurfaceColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Karaoke Effect",
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Highlight words as they are spoken",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: mutedColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedEffect == 'karaoke')
                              Icon(
                                Icons.check_circle,
                                color: primaryColor,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Typewriter Effect Card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedEffect = 'typewriter'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedEffect == 'typewriter' 
                              ? primaryColor.withValues(alpha: 0.1)
                              : (isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedEffect == 'typewriter' 
                                ? primaryColor.withValues(alpha: 0.3)
                                : borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.keyboard,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Typewriter Effect",
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Reveal text character by character",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: mutedColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedEffect == 'typewriter')
                              Icon(
                                Icons.check_circle,
                                color: primaryColor,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Effect Configuration Section
              if (_selectedEffect == 'karaoke') _buildKaraokeConfig(isDark, onSurfaceColor, mutedColor, borderColor),
              if (_selectedEffect == 'typewriter') _buildTypewriterConfig(isDark, onSurfaceColor, mutedColor, borderColor),

              const SizedBox(height: 24),

              // Preview
              _buildPreviewCard(),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: onSurfaceColor,
                          side: BorderSide(
                            color: onSurfaceColor.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close,
                              size: 20,
                              color: onSurfaceColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Cancel",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: onSurfaceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _applyEffect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Apply",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKaraokeConfig(bool isDark, Color onSurfaceColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Karaoke Configuration",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Text Selection Field (only show if we have line text)
        if (widget.lineText != null) ...[
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
                Row(
                  children: [
                    Icon(
                      Icons.text_format,
                      color: onSurfaceColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Text Selection",
                      style: TextStyle(
                        color: onSurfaceColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Select part of the text to apply effect only to that selection",
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  // readOnly: true,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(
                    color: onSurfaceColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: "Select text to apply karaoke effect...",
                    hintStyle: TextStyle(
                      color: mutedColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: (text) {
                    // Text changed - selection state is handled in _applyEffect
                  },
                  onTap: () {
                    // User tapped - selection state is handled in _applyEffect
                  },
                ),
                const SizedBox(height: 8),
                if (_textController.selection.start != _textController.selection.end)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _karaokeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Selected: \"${_textController.selection.textInside(_textController.text)}\"",
                      style: TextStyle(
                        color: onSurfaceColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_textController.selection.start == _textController.selection.end && _textController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Effect will be applied to entire text",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Color Selection
        Container(
          decoration: BoxDecoration(
            color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _karaokeColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
            ),
            title: Text(
              "Highlight Color",
              style: TextStyle(
                color: onSurfaceColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              "Choose the karaoke highlight color",
              style: TextStyle(
                color: mutedColor,
              ),
            ),
            trailing: Icon(
              Icons.color_lens,
              color: onSurfaceColor,
            ),
            onTap: _showKaraokeColorPicker,
          ),
        ),

        const SizedBox(height: 16),

        // Effect Type Selection
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
              Row(
                children: [
                  Icon(
                    Icons.text_fields,
                    color: onSurfaceColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Effect Type",
                    style: TextStyle(
                      color: onSurfaceColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text(
                        "Word",
                        style: TextStyle(color: onSurfaceColor),
                      ),
                      subtitle: Text(
                        "Highlight word by word",
                        style: TextStyle(color: mutedColor, fontSize: 12),
                      ),
                      value: 'word',
                      groupValue: _karaokeEffectType,
                      onChanged: (value) => setState(() => _karaokeEffectType = value!),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text(
                        "Character",
                        style: TextStyle(color: onSurfaceColor),
                      ),
                      subtitle: Text(
                        "Highlight character by character",
                        style: TextStyle(color: mutedColor, fontSize: 12),
                      ),
                      value: 'character',
                      groupValue: _karaokeEffectType,
                      onChanged: (value) => setState(() => _karaokeEffectType = value!),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // End Delay Configuration
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
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: onSurfaceColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "End Delay",
                    style: TextStyle(
                      color: onSurfaceColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${(_endDelay * 1000).round()}ms - Show full text before end",
                style: TextStyle(
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: borderColor,
                  thumbColor: Theme.of(context).primaryColor,
                  overlayColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _endDelay,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) => setState(() => _endDelay = value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypewriterConfig(bool isDark, Color onSurfaceColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Typewriter Configuration",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Color Selection
        Container(
          decoration: BoxDecoration(
            color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _typewriterColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
            ),
            title: Text(
              "Text Color",
              style: TextStyle(
                color: onSurfaceColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              "Choose the typewriter text color",
              style: TextStyle(
                color: mutedColor,
              ),
            ),
            trailing: Icon(
              Icons.color_lens,
              color: onSurfaceColor,
            ),
            onTap: _showTypewriterColorPicker,
          ),
        ),

        const SizedBox(height: 16),

        // End Delay Configuration
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
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: onSurfaceColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "End Delay",
                    style: TextStyle(
                      color: onSurfaceColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${(_endDelay * 1000).round()}ms - Show full text before end",
                style: TextStyle(
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: borderColor,
                  thumbColor: Theme.of(context).primaryColor,
                  overlayColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _endDelay,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) => setState(() => _endDelay = value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showKaraokeColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        Color selectedColor = _karaokeColor;
        
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
            final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
            
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selectedColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.palette,
                              color: selectedColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Karaoke Highlight Color",
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Choose the color for highlighted text",
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

                    const SizedBox(height: 20),

                    // Color Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: onSurfaceColor.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Preview",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                              ),
                              children: [
                                TextSpan(
                                  text: "Highlighted ",
                                  style: TextStyle(color: selectedColor, fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: "normal text",
                                  style: TextStyle(color: onSurfaceColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Color Picker
                    SizedBox(
                      height: 300,
                      child: SingleChildScrollView(
                        child: ColorPicker(
                          color: selectedColor,
                          onColorChanged: (color) => setState(() => selectedColor = color),
                          pickersEnabled: const <ColorPickerType, bool>{
                            ColorPickerType.primary: false,
                            ColorPickerType.accent: false,
                            ColorPickerType.wheel: true,
                          },
                          enableShadesSelection: true,
                          showColorCode: true,
                          showMaterialName: true,
                          showRecentColors: true,
                          maxRecentColors: 8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: onSurfaceColor,
                                side: BorderSide(
                                  color: onSurfaceColor.withValues(alpha: 0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: onSurfaceColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                this.setState(() => _karaokeColor = selectedColor);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedColor,
                                foregroundColor: selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Select Color",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTypewriterColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        Color selectedColor = _typewriterColor;
        
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
            final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
            
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selectedColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.text_format,
                              color: selectedColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Typewriter Text Color",
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Choose the color for typewriter text",
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

                    const SizedBox(height: 20),

                    // Color Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: onSurfaceColor.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Preview",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Sample typewriter text",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: selectedColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Color Picker
                    SizedBox(
                      height: 300,
                      child: SingleChildScrollView(
                        child: ColorPicker(
                          color: selectedColor,
                          onColorChanged: (color) => setState(() => selectedColor = color),
                          pickersEnabled: const <ColorPickerType, bool>{
                            ColorPickerType.primary: false,
                            ColorPickerType.accent: false,
                            ColorPickerType.wheel: true,
                          },
                          enableShadesSelection: true,
                          showColorCode: true,
                          showMaterialName: true,
                          showRecentColors: true,
                          maxRecentColors: 8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: onSurfaceColor,
                                side: BorderSide(
                                  color: onSurfaceColor.withValues(alpha: 0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: onSurfaceColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                this.setState(() => _typewriterColor = selectedColor);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedColor,
                                foregroundColor: selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Select Color",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _recomputePreviewDurations() {
    // If subtitleLines provided, use first selected line to compute durations
    if (widget.subtitleLines != null && widget.subtitleLines!.isNotEmpty) {
      final line = widget.subtitleLines!.first;
      try {
        final start = parseTimeString(line.startTime);
        final end = parseTimeString(line.endTime);
        _lineDuration = end - start;
      } catch (e) {
        _lineDuration = const Duration(seconds: 3);
      }
    } else {
      // Otherwise infer duration from UI defaults
      _lineDuration = const Duration(seconds: 3);
    }

    // Compute end delay from _endDelay (value 0.0-1.0 representing seconds up to 1s)
    _endDelayDuration = Duration(milliseconds: (_endDelay * 1000).round());

    // Animation duration is lineDuration minus endDelay (minimum 200ms)
    final raw = _lineDuration - _endDelayDuration;
    _animDuration = raw > const Duration(milliseconds: 200) ? raw : const Duration(milliseconds: 200);

    // Update controller
    _previewController.duration = _animDuration;
    _previewProgress = 0.0;
  }

  Widget _buildPreviewCard() {
    final text = _textController.text.isNotEmpty ? _textController.text : (widget.subtitleLines?.first.original ?? 'Sample text for preview');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_fill, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text('Preview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(_formatDuration(_lineDuration), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
          const SizedBox(height: 12),

          // Animated preview area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.03) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _selectedEffect == 'karaoke' ? _karaokePreview(text) : _typewriterPreview(text),
          ),

          const SizedBox(height: 12),

          // Controls: progress slider and play/pause
          Row(
            children: [
              IconButton(
                icon: Icon(_isPreviewPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  _recomputePreviewDurations();
                  if (_isPreviewPlaying) {
                    _previewController.stop();
                    setState(() => _isPreviewPlaying = false);
                  } else {
                    setState(() => _isPreviewPlaying = true);
                    _previewController.forward(from: 0.0);
                  }
                },
              ),
              Expanded(
                child: Slider(
                  value: _previewProgress.clamp(0.0, 1.0),
                  onChanged: (v) {
                    final pos = v.clamp(0.0, 1.0);
                    setState(() {
                      _previewProgress = pos;
                      _previewController.value = pos;
                      _isPreviewPlaying = false;
                      _previewController.stop();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(_formatDuration(_animDuration * _previewProgress), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final ms = d.inMilliseconds;
    final seconds = (ms / 1000).toStringAsFixed(2);
    return '${seconds}s';
  }

  Widget _karaokePreview(String text) {
    // split words and compute current index
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final totalWords = words.isNotEmpty ? words.length : 1;
    final revealFraction = _previewController.value.clamp(0.0, 1.0);

    // Word mode: color entire word when its turn arrives.
    if (_karaokeEffectType == 'word') {
      final revealCount = (revealFraction * totalWords).floor();
      return Wrap(
        children: List.generate(words.length, (i) {
          final w = words[i];
          final isHighlighted = i < revealCount || (i == revealCount && (revealFraction * totalWords - revealCount) > 0.999);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Text(
              w + (i < words.length - 1 ? ' ' : ''),
              style: TextStyle(
                color: isHighlighted ? _karaokeColor : Theme.of(context).colorScheme.onSurface,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      );
    }

    // Character mode: reveal characters progressively across words (preserve spaces)
    final totalChars = words.fold<int>(0, (s, w) => s + w.length);
    final charsToHighlight = (revealFraction * totalChars).floor();
    int remaining = charsToHighlight;
    List<InlineSpan> spans = [];
    for (int wi = 0; wi < words.length; wi++) {
      final w = words[wi];
      final take = remaining > 0 ? remaining.clamp(0, w.length) : 0;
      if (take > 0) {
        spans.add(TextSpan(text: w.substring(0, take), style: TextStyle(color: _karaokeColor, fontWeight: FontWeight.w600)));
      }
      if (take < w.length) {
        spans.add(TextSpan(text: w.substring(take), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
      }
      // add space between words
      if (wi < words.length - 1) spans.add(TextSpan(text: ' ', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
      remaining -= take;
    }

    return RichText(
      text: TextSpan(style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16), children: spans),
    );
  }

  Widget _typewriterPreview(String text) {
    final totalChars = text.length > 0 ? text.length : 1;
    final revealed = (_previewController.value * totalChars).floor();
    final visible = text.substring(0, revealed.clamp(0, text.length));
    final remaining = text.substring(revealed.clamp(0, text.length));
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
        children: [
          TextSpan(text: visible, style: TextStyle(color: _typewriterColor)),
          TextSpan(text: remaining, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }

  void _applyEffect() {
    setState(() => _isProcessing = true);

    Map<String, dynamic> effectConfig = {};

    if (_selectedEffect == 'karaoke') {
      // Get text selection info
      final selection = _textController.selection;
      final hasSelection = selection.start != selection.end;
      final selectedText = hasSelection ? selection.textInside(_textController.text) : '';
      
      effectConfig = {
        'color': _karaokeColor.value.toRadixString(16).padLeft(8, '0'),
        'endDelay': _endDelay,
        'effectType': _karaokeEffectType,
        // Add text selection information
        'hasTextSelection': hasSelection,
        'selectionStart': selection.start,
        'selectionEnd': selection.end,
        'selectedText': selectedText,
        'fullText': _textController.text,
      };
    } else if (_selectedEffect == 'typewriter') {
      effectConfig = {
        'color': _typewriterColor.value.toRadixString(16).padLeft(8, '0'),
        'endDelay': _endDelay,
      };
    }

    // Call the callback with effect type and configuration
    widget.onApplyEffect(_selectedEffect, effectConfig);

    setState(() => _isProcessing = false);
    // Don't pop here - let the calling method handle navigation
  }
}
