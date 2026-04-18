import 'package:flutter/material.dart';
import 'package:subtitle_studio/operations/subtitle_banner_operations.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/app_logger.dart';

class BannerConfigurationSheet extends StatefulWidget {
  final List<SubtitleLine> subtitleLines;
  final int subtitleCollectionId;
  final int sessionId;
  final Function() onBannersInserted;

  const BannerConfigurationSheet({
    super.key,
    required this.subtitleLines,
    required this.subtitleCollectionId,
    required this.sessionId,
    required this.onBannersInserted,
  });

  @override
  State<BannerConfigurationSheet> createState() => _BannerConfigurationSheetState();
}

class _BannerConfigurationSheetState extends State<BannerConfigurationSheet> {
  late TextEditingController _beginningController;
  late TextEditingController _middleController;
  late TextEditingController _endController;
  
  // Position time controllers
  late TextEditingController _beginningPositionController;
  late TextEditingController _middlePositionController;
  late TextEditingController _endPositionController;
    bool _isProcessing = false;
  BannerValidationResult? _validationResult;
  BannerPositions? _bannerPositions;
  BannerPositions? _originalPositions; // Store original calculated positions
  
  // Toggle switches for including banners
  bool _includeBeginning = true;
  bool _includeMiddle = true;
  bool _includeEnd = true;
  
  // Recommended positions and user choice
  BannerPositions? _recommendedPositions;
  bool _useRecommendedPositions = false;
  @override
  void initState() {
    super.initState();
    AppLogger.instance.info('BannerConfigurationSheet initialized', context: 'BannerConfigurationSheet.initState');
    
    // Initialize controllers with default banner texts
    _beginningController = TextEditingController(
      text: SubtitleBannerOperations.defaultBeginningBanner,
    );
    _middleController = TextEditingController(
      text: SubtitleBannerOperations.defaultMiddleBanner,
    );
    _endController = TextEditingController(
      text: SubtitleBannerOperations.defaultEndBanner,
    );
      // Initialize position controllers
    _beginningPositionController = TextEditingController();
    _middlePositionController = TextEditingController();
    _endPositionController = TextEditingController();
    
    // Add listeners to position controllers
    _beginningPositionController.addListener(_onPositionChanged);
    _middlePositionController.addListener(_onPositionChanged);
    _endPositionController.addListener(_onPositionChanged);
    
    // Calculate banner positions and validate
    _calculatePositions();
  }
  @override
  void dispose() {
    AppLogger.instance.info('BannerConfigurationSheet disposing', context: 'BannerConfigurationSheet.dispose');
    _beginningController.dispose();
    _middleController.dispose();
    _endController.dispose();
    _beginningPositionController.dispose();
    _middlePositionController.dispose();
    _endPositionController.dispose();
    super.dispose();
  }  void _calculatePositions() {
    _bannerPositions = SubtitleBannerOperations.calculateBannerPositions(widget.subtitleLines);
    _originalPositions = _bannerPositions; // Store original calculated positions
    _validationResult = SubtitleBannerOperations.validateBannerInsertion(widget.subtitleLines);
    
    // Set recommended positions if available
    if (_validationResult?.recommendedPositions != null) {
      _recommendedPositions = _validationResult!.recommendedPositions;
    }
    
    // Update position controllers with calculated values
    if (_bannerPositions != null) {
      _beginningPositionController.text = _formatDuration(_bannerPositions!.beginningPosition);
      _middlePositionController.text = _formatDuration(_bannerPositions!.middlePosition);
      _endPositionController.text = _formatDuration(_bannerPositions!.endPosition);
    }
    
    setState(() {});
  }
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')},'
           '${milliseconds.toString().padLeft(3, '0')}';
  }

  Duration? _parseDuration(String timeStr) {
    try {
      // Expected format: HH:MM:SS,mmm
      final parts = timeStr.split(',');
      if (parts.length != 2) return null;
      
      final timeParts = parts[0].split(':');
      if (timeParts.length != 3) return null;
      
      final hours = int.parse(timeParts[0]);
      final minutes = int.parse(timeParts[1]);
      final seconds = int.parse(timeParts[2]);
      final milliseconds = int.parse(parts[1]);
      
      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    } catch (e) {
      return null;
    }
  }

  void _onPositionChanged() {
    // Parse the position text fields and update banner positions
    final beginningPos = _parseDuration(_beginningPositionController.text);
    final middlePos = _parseDuration(_middlePositionController.text);
    final endPos = _parseDuration(_endPositionController.text);
    
    if (beginningPos != null && middlePos != null && endPos != null) {
      _bannerPositions = BannerPositions(
        beginningPosition: beginningPos,
        middlePosition: middlePos,
        endPosition: endPos,
      );
      
      // Re-validate with new positions
      _validationResult = SubtitleBannerOperations.validateBannerInsertion(
        widget.subtitleLines,
        customPositions: _bannerPositions,
      );
      
      setState(() {});
    }
  }

  Future<void> _insertBanners() async {
    await AppLogger.instance.info('Starting banner insertion process', context: 'BannerConfigurationSheet._insertBanners');
    
    // Validate that at least one banner is selected
    if (!_includeBeginning && !_includeMiddle && !_includeEnd) {
      await AppLogger.instance.warning('No banners selected for insertion', context: 'BannerConfigurationSheet._insertBanners');
      SnackbarHelper.showError(context, 'Please select at least one banner to insert');
      return;
    }

    // Validate that enabled banners have text
    if ((_includeBeginning && _beginningController.text.trim().isEmpty) ||
        (_includeMiddle && _middleController.text.trim().isEmpty) ||
        (_includeEnd && _endController.text.trim().isEmpty)) {
      await AppLogger.instance.warning('Some enabled banner texts are empty', context: 'BannerConfigurationSheet._insertBanners');
      SnackbarHelper.showError(context, 'All enabled banner texts must be filled');
      return;
    }

    setState(() {
      _isProcessing = true;
    });    try {
      // Use recommended positions if selected, otherwise use custom positions from text fields
      BannerPositions? positionsToUse;
      if (_useRecommendedPositions && _recommendedPositions != null) {
        positionsToUse = _recommendedPositions;
      } else if (_bannerPositions != null) {
        // Use the positions from the text fields (which may have been manually edited)
        positionsToUse = _bannerPositions;
      }

      final success = await SubtitleBannerOperations.insertBanners(
        subtitleCollectionId: widget.subtitleCollectionId,
        sessionId: widget.sessionId,
        currentSubtitleLines: widget.subtitleLines,
        beginningText: _beginningController.text.trim(),
        middleText: _middleController.text.trim(),
        endText: _endController.text.trim(),
        includeBeginning: _includeBeginning,
        includeMiddle: _includeMiddle,
        includeEnd: _includeEnd,
        customPositions: positionsToUse,
      );

      if (success) {
        if (context.mounted) {
          Navigator.pop(context);
          widget.onBannersInserted();
          
          // Count inserted banners for success message
          int insertedCount = 0;
          if (_includeBeginning) insertedCount++;
          if (_includeMiddle) insertedCount++;
          if (_includeEnd) insertedCount++;
          
          await AppLogger.instance.info('$insertedCount banner(s) inserted successfully', context: 'BannerConfigurationSheet._insertBanners');
          SnackbarHelper.showSuccess(
            context,
            '$insertedCount banner${insertedCount == 1 ? '' : 's'} inserted successfully!',
          );
        }
      } else {
        throw Exception('Failed to insert banners');
      }
    } catch (e) {
      await AppLogger.instance.error('Error inserting banners: $e', context: 'BannerConfigurationSheet._insertBanners');
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Error inserting banners: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 18.0),
            // Header section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bookmark_add,
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
                          'Insert Subtitle Banners',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: onSurfaceColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add promotional banners at strategic positions in your subtitle file',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: onSurfaceColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      'Each banner will display for 10 seconds at the specified positions. You can customize the text and timing for each banner.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Warnings and recommendations
                    if (_validationResult?.warnings.isNotEmpty == true) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Potential Issues:',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),                          ...(_validationResult!.warnings.map((warning) => 
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• $warning', 
                                           style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                             color: Colors.orange.shade700,
                                           )),
                              ),
                            )),
                            const SizedBox(height: 8),
                            Text(
                              'Use the recommended positions or edit the time codes manually to fix these issues.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue.shade600,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Recommended positions card
                    if (_recommendedPositions != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Recommended Positions (No Overlaps):',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('• Beginning: ${_formatDuration(_recommendedPositions!.beginningPosition)}', 
                                 style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue.shade700)),
                            Text('• Middle: ${_formatDuration(_recommendedPositions!.middlePosition)}', 
                                 style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue.shade700)),
                            Text('• End: ${_formatDuration(_recommendedPositions!.endPosition)}', 
                                 style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue.shade700)),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              title: Text(
                                'Use recommended positions',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: _useRecommendedPositions,                            onChanged: (value) {
                                setState(() {
                                  _useRecommendedPositions = value ?? false;
                                  // Update position text fields when recommended positions are toggled
                                  if (_useRecommendedPositions && _recommendedPositions != null) {
                                    _beginningPositionController.text = _formatDuration(_recommendedPositions!.beginningPosition);
                                    _middlePositionController.text = _formatDuration(_recommendedPositions!.middlePosition);                                  _endPositionController.text = _formatDuration(_recommendedPositions!.endPosition);
                                    // Update banner positions to recommended ones
                                    _bannerPositions = _recommendedPositions;
                                  } else if (_originalPositions != null) {
                                    // Restore original calculated positions
                                    _beginningPositionController.text = _formatDuration(_originalPositions!.beginningPosition);
                                    _middlePositionController.text = _formatDuration(_originalPositions!.middlePosition);
                                    _endPositionController.text = _formatDuration(_originalPositions!.endPosition);
                                    _bannerPositions = _originalPositions;
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Banner configuration section
                    Text(
                      'Banner Configuration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Beginning banner
                    _buildBannerConfiguration(
                      controller: _beginningController,
                      label: 'Beginning Banner',
                      hint: 'Text for the banner at the start',
                      icon: Icons.play_arrow,
                      isEnabled: _includeBeginning,
                      onToggle: (value) {
                        setState(() {
                          _includeBeginning = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Middle banner
                    _buildBannerConfiguration(
                      controller: _middleController,
                      label: 'Middle Banner',
                      hint: 'Text for the banner in the middle',
                      icon: Icons.pause,
                      isEnabled: _includeMiddle,
                      onToggle: (value) {
                        setState(() {
                          _includeMiddle = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // End banner
                    _buildBannerConfiguration(
                      controller: _endController,
                      label: 'End Banner',
                      hint: 'Text for the banner at the end',
                      icon: Icons.stop,
                      isEnabled: _includeEnd,
                      onToggle: (value) {
                        setState(() {
                          _includeEnd = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Action buttons (fixed at bottom)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: onSurfaceColor.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : () => Navigator.pop(context),
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
                              'Cancel',
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
                        onPressed: _isProcessing ? null : _insertBanners,
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 20, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Insert',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }

  Widget _buildBannerConfiguration({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine which position controller to use based on the label
    TextEditingController? positionController;
    if (label == 'Beginning Banner') {
      positionController = _beginningPositionController;
    } else if (label == 'Middle Banner') {
      positionController = _middlePositionController;
    } else if (label == 'End Banner') {
      positionController = _endPositionController;
    }

    return Container(
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
          // Header with toggle and icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnabled ? primaryColor : mutedColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
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
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? null : mutedColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnabled ? 'Banner will be inserted' : 'Banner will be skipped',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: onToggle,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          
          if (isEnabled) ...[
            const SizedBox(height: 16),
            
            // Position field
            if (positionController != null) ...[
              Text(
                'Position',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: onSurfaceColor,
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
                  controller: positionController,
                  enabled: isEnabled && !_useRecommendedPositions,
                  decoration: InputDecoration(
                    labelText: 'Timing (HH:MM:SS,mmm)',
                    prefixIcon: Icon(
                      Icons.access_time,
                      color: primaryColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: TextStyle(
                      color: mutedColor,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: (_useRecommendedPositions || !isEnabled)
                        ? mutedColor
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Banner text field
            Text(
              'Banner Text',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: onSurfaceColor,
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
                controller: controller,
                enabled: isEnabled,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: hint,
                  prefixIcon: Icon(
                    Icons.text_fields,
                    color: primaryColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  labelStyle: TextStyle(
                    color: mutedColor,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
