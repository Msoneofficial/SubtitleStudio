import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subtitle_studio/database/models/models.dart';

class AddLineConfirmationSheet extends StatefulWidget {
  final int lineIndex;
  final String currentStartTime;
  final String currentEndTime;
  final String? previousEndTime;
  final String? nextStartTime;
  final bool isSingleLine;
  final bool isVideoLoaded;
  final Duration? Function()? getCurrentVideoPosition;
  final SubtitleCollection? collection;
  final Future<void> Function(bool addBefore, bool useVideoPosition, int durationMs) onConfirm;

  const AddLineConfirmationSheet({
    super.key,
    required this.lineIndex,
    required this.currentStartTime,
    required this.currentEndTime,
    this.previousEndTime,
    this.nextStartTime,
    this.isSingleLine = false,
    this.isVideoLoaded = false,
    this.getCurrentVideoPosition,
    this.collection,
    required this.onConfirm,
  });

  @override
  State<AddLineConfirmationSheet> createState() => _AddLineConfirmationSheetState();
}

class _AddLineConfirmationSheetState extends State<AddLineConfirmationSheet> {
  late bool _useVideoPosition;
  late TextEditingController _durationController;
  final _formKey = GlobalKey<FormState>();
  
  String? _videoPositionTime;
  String? _nearestPreviousEndTime;
  String? _nearestNextStartTime;

  @override
  void initState() {
    super.initState();
    _useVideoPosition = false;
    _durationController = TextEditingController(text: '2000'); // Default 2 seconds
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  // Helper method to parse SRT time format to Duration
  Duration _parseTime(String time) {
    final parts = time.split(',');
    final hms = parts[0].split(':');
    return Duration(
      hours: int.parse(hms[0]),
      minutes: int.parse(hms[1]),
      seconds: int.parse(hms[2]),
      milliseconds: int.parse(parts[1]),
    );
  }

  // Helper method to format Duration to SRT time format
  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);
    
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)},${threeDigits(milliseconds)}';
  }

  // Find nearest subtitles before and after the video position
  void _updateVideoPositionInfo() {
    if (!_useVideoPosition || 
        widget.getCurrentVideoPosition == null || 
        widget.collection == null) {
      setState(() {
        _videoPositionTime = null;
        _nearestPreviousEndTime = null;
        _nearestNextStartTime = null;
      });
      return;
    }

    final videoPos = widget.getCurrentVideoPosition!();
    if (videoPos == null) return;

    setState(() {
      _videoPositionTime = _formatTime(videoPos);
      
      // Find nearest subtitle before video position
      SubtitleLine? nearestBefore;
      SubtitleLine? nearestAfter;
      
      for (final line in widget.collection!.lines) {
        final lineEnd = _parseTime(line.endTime);
        final lineStart = _parseTime(line.startTime);
        
        // Find subtitle that ends before or at video position
        if (lineEnd <= videoPos) {
          if (nearestBefore == null || _parseTime(line.endTime).compareTo(_parseTime(nearestBefore.endTime)) > 0) {
            nearestBefore = line;
          }
        }
        
        // Find subtitle that starts at or after video position
        if (lineStart >= videoPos) {
          if (nearestAfter == null || _parseTime(line.startTime).compareTo(_parseTime(nearestAfter.startTime)) < 0) {
            nearestAfter = line;
          }
        }
      }
      
      _nearestPreviousEndTime = nearestBefore?.endTime;
      _nearestNextStartTime = nearestAfter?.startTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic color variables for adaptive theming
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Header Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
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
                            "Add New Line",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Choose where to insert the new subtitle line",
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
      
              const SizedBox(height: 16),
      
              // Current Line Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
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
                    Text(
                      "Current Line: ${widget.lineIndex}",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "${widget.currentStartTime} → ${widget.currentEndTime}",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              color: mutedColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Show video position when checkbox is enabled
                    if (_useVideoPosition && _videoPositionTime != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Video Position: ",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _videoPositionTime!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      
              const SizedBox(height: 20),

              // Video Position Checkbox (only shown when video is loaded)
              if (widget.isVideoLoaded && widget.getCurrentVideoPosition != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Icon(
                          Icons.video_library,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Use current video position",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      "Set new line time codes from current playback position",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                      ),
                    ),
                    value: _useVideoPosition,
                    onChanged: (bool? value) {
                      setState(() {
                        _useVideoPosition = value ?? false;
                        if (_useVideoPosition) {
                          _updateVideoPositionInfo();
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),

              if (widget.isVideoLoaded && widget.getCurrentVideoPosition != null)
                const SizedBox(height: 16),

              // Duration Text Field
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
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
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "New Line Duration",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: "Duration in milliseconds",
                        suffixText: "ms",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter duration';
                        }
                        final duration = int.tryParse(value);
                        if (duration == null || duration <= 0) {
                          return 'Please enter a valid positive number';
                        }
                        if (duration < 100) {
                          return 'Duration must be at least 100ms';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Recommended: 2000ms (2 seconds)",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
      
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          
                          final durationMs = int.parse(_durationController.text);
                          Navigator.pop(context); // Close dialog first
                          await widget.onConfirm(true, _useVideoPosition, durationMs); // Add before current line
                        },
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
                            Icon(Icons.arrow_upward_rounded, size: 18, color: onSurfaceColor,),
                            const SizedBox(width: 6),
                            Text(
                              "Before",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          
                          final durationMs = int.parse(_durationController.text);
                          Navigator.pop(context); // Close dialog first
                          await widget.onConfirm(false, _useVideoPosition, durationMs); // Add after current line
                        },
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
                            Text(
                              "After",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_downward_rounded, size: 18, color: onSurfaceColor,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      
              const SizedBox(height: 16),
      
              // Context Information
              if (widget.isSingleLine)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "This is the only subtitle. New lines will be created with appropriate timing.",
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_useVideoPosition && _videoPositionTime != null)
                // Show nearest subtitles when using video position
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
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
                            Icons.info_outline,
                            color: mutedColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Nearest Subtitles to Video Position",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_nearestPreviousEndTime != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: mutedColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Previous subtitle ends: $_nearestPreviousEndTime",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (_nearestNextStartTime != null)
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              color: mutedColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Next subtitle starts: $_nearestNextStartTime",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_nearestPreviousEndTime == null && _nearestNextStartTime == null)
                        Text(
                          "No nearby subtitles found",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                )
              else if (widget.previousEndTime != null || widget.nextStartTime != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.previousEndTime != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: mutedColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Previous line ends at: ${widget.previousEndTime}",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.nextStartTime != null) const SizedBox(height: 4),
                      ],
                      if (widget.nextStartTime != null)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: mutedColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Next line starts at: ${widget.nextStartTime}",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
      
              const SizedBox(height: 12),
      
              // Cancel Button
              Container(
                height: 45,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
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
      ),
    );
  }
}
