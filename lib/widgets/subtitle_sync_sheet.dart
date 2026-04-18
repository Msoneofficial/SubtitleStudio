import 'package:flutter/material.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/operations/subtitle_sync_operations.dart';
import 'package:subtitle_studio/widgets/video_player_widget.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/app_logger.dart';

class SubtitleSyncSheet extends StatefulWidget {
  final List<SubtitleLine> subtitleLines;
  final int subtitleId;
  final bool isVideoLoaded;
  final GlobalKey<VideoPlayerWidgetState> videoPlayerKey;
  final Function() onRefresh;

  const SubtitleSyncSheet({
    super.key,
    required this.subtitleLines,
    required this.subtitleId,
    required this.isVideoLoaded,
    required this.videoPlayerKey,
    required this.onRefresh,
  });

  @override
  State<SubtitleSyncSheet> createState() => _SubtitleSyncSheetState();
}

class _SubtitleSyncSheetState extends State<SubtitleSyncSheet> {
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _sourceFramerateController = TextEditingController(text: '23.976');
  final _targetFramerateController = TextEditingController();
  bool _isProcessing = false;
  double? _videoFramerate;

  @override
  void initState() {
    super.initState();
    AppLogger.instance.info('SubtitleSyncSheet initialized', context: 'SubtitleSyncSheet.initState');
    // Initialize the text fields with first and last subtitle timecodes
    if (widget.subtitleLines.isNotEmpty) {
      _startTimeController.text = widget.subtitleLines.first.startTime;
      _endTimeController.text = widget.subtitleLines.last.endTime;
    }
    
    // Get video framerate if available
    if (widget.isVideoLoaded && widget.videoPlayerKey.currentState != null) {
      try {
        _videoFramerate = widget.videoPlayerKey.currentState!.getFrameRate();
        if (_videoFramerate != null && _videoFramerate! > 0) {
          _targetFramerateController.text = _videoFramerate!.toStringAsFixed(3);
        } else {
          // Fallback to default value
          _targetFramerateController.text = '25.000';
        }
      } catch (e) {
        // Fallback to default value on error
        _targetFramerateController.text = '25.000';
      }
    } else {
      // No video loaded, use default value
      _targetFramerateController.text = '25.000';
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _sourceFramerateController.dispose();
    _targetFramerateController.dispose();
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

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                        Icons.sync,
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
                            'Subtitle Synchronization',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose a synchronization method to adjust timing',
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
              
              // Option 1: Shift Timecodes
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showShiftTimecodeDialog(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.timer,
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
                                'Shift Timecodes',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Shift all subtitle timecodes while preserving durations',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: mutedColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: mutedColor,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Option 2: Adjust Framerate
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isVideoLoaded
                      ? () => _showFramerateDialog()
                      : () => _showVideoRequiredAlert(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.isVideoLoaded
                          ? (isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50)
                          : (isDark ? onSurfaceColor.withValues(alpha: 0.02) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isVideoLoaded
                            ? borderColor
                            : borderColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.isVideoLoaded
                                ? Colors.orange
                                : Colors.grey.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.speed,
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
                                'Adjust Framerate',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: widget.isVideoLoaded
                                      ? null
                                      : mutedColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.isVideoLoaded
                                    ? 'Adjust timecodes for different framerates'
                                    : 'Load a video first to enable this feature',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: widget.isVideoLoaded
                                      ? mutedColor
                                      : mutedColor.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: widget.isVideoLoaded
                              ? mutedColor
                              : mutedColor.withValues(alpha: 0.5),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showShiftTimecodeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
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
                              Icons.timer,
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
                                  'Shift Timecodes',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enter new timecodes for first and last subtitles',
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
                    
                    // Description
                    Text(
                      'All other subtitles will be shifted proportionally while maintaining their durations.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // First subtitle field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'First subtitle starts at (HH:MM:SS,mmm):',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _startTimeController,
                            decoration: InputDecoration(
                              hintText: '00:00:00,000',
                              prefixIcon: Icon(
                                Icons.access_time,
                                color: primaryColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Last subtitle field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last subtitle ends at (HH:MM:SS,mmm):',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _endTimeController,
                            decoration: InputDecoration(
                              hintText: '00:00:00,000',
                              prefixIcon: Icon(
                                Icons.access_time,
                                color: primaryColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                      ],
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () async {
                                      setState(() => _isProcessing = true);
                                      
                                      final result = await SubtitleSyncOperations.shiftTimecodes(
                                        subtitleId: widget.subtitleId,
                                        subtitleLines: widget.subtitleLines,
                                        newStartTime: _startTimeController.text,
                                        newEndTime: _endTimeController.text,
                                      );
                                      
                                      setState(() => _isProcessing = false);
                                      
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        
                                        if (result.success) {
                                          await AppLogger.instance.info('Subtitles shifted successfully', context: 'SubtitleSyncSheet._showShiftTimecodeDialog');
                                          widget.onRefresh();
                                          SnackbarHelper.showSuccess(context, 'Subtitles shifted successfully');
                                        } else {
                                          await AppLogger.instance.error('Error shifting subtitles: ${result.message}', context: 'SubtitleSyncSheet._showShiftTimecodeDialog');
                                          SnackbarHelper.showError(context, 'Error: ${result.message}');
                                        }
                                      }
                                    },
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
                                        Icon(Icons.check, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Apply',
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
        },
      ),
    );
  }

  void _showFramerateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
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
                    // Header Section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.speed,
                              color: Colors.orange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Adjust Framerate',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Convert timecodes between framerates',
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
                    
                    // Description
                    Text(
                      'Enter the source and target framerates to adjust all subtitle timecodes.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Source framerate field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Source framerate (FPS):',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _sourceFramerateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '23.976',
                              prefixIcon: Icon(
                                Icons.videocam_outlined,
                                color: primaryColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Target framerate field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target framerate (FPS):',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _targetFramerateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '25.000',
                              prefixIcon: Icon(
                                Icons.play_circle_outline,
                                color: primaryColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                      ],
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () async {
                                      setState(() => _isProcessing = true);
                                      
                                      final result = await SubtitleSyncOperations.adjustFramerate(
                                        subtitleId: widget.subtitleId,
                                        subtitleLines: widget.subtitleLines,
                                        sourceFramerate: double.tryParse(_sourceFramerateController.text) ?? 23.976,
                                        targetFramerate: double.tryParse(_targetFramerateController.text) ?? 25.000,
                                      );
                                      
                                      setState(() => _isProcessing = false);
                                      
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        
                                        if (result.success) {
                                          await AppLogger.instance.info('Framerate adjusted successfully', context: 'SubtitleSyncSheet._showFramerateDialog');
                                          widget.onRefresh();
                                          SnackbarHelper.showSuccess(context, 'Framerate adjusted successfully');
                                        } else {
                                          await AppLogger.instance.error('Error adjusting framerate: ${result.message}', context: 'SubtitleSyncSheet._showFramerateDialog');
                                          SnackbarHelper.showError(context, 'Error: ${result.message}');
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
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
                                        Icon(Icons.speed, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Adjust',
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
        },
      ),
    );
  }

  void _showVideoRequiredAlert() {
    showDialog(
      context: context,
      builder: (context) {
        final primaryColor = Theme.of(context).primaryColor;
        final mutedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.video_file,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Video Required',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Please load a video file first to use this feature. The video provides framerate information needed for accurate adjustment.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: mutedColor,
            ),
          ),
          actions: [
            Container(
              height: 40,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
