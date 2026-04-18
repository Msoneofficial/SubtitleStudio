import 'package:flutter/material.dart';
import 'package:subtitle_studio/operations/subtitle_banner_operations.dart';
import 'package:subtitle_studio/database/models/models.dart';

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
  
  bool _isProcessing = false;
  BannerValidationResult? _validationResult;
  BannerPositions? _bannerPositions;
  
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
    
    // Calculate banner positions and validate
    _calculatePositions();
  }

  @override
  void dispose() {
    _beginningController.dispose();
    _middleController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _calculatePositions() {
    _bannerPositions = SubtitleBannerOperations.calculateBannerPositions(widget.subtitleLines);
    _validationResult = SubtitleBannerOperations.validateBannerInsertion(widget.subtitleLines);
    
    // Set recommended positions if available
    if (_validationResult?.recommendedPositions != null) {
      _recommendedPositions = _validationResult!.recommendedPositions;
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

  Future<void> _insertBanners() async {
    // Validate that at least one banner is selected
    if (!_includeBeginning && !_includeMiddle && !_includeEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one banner to insert'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
      return;
    }

    // Validate that enabled banners have text
    if ((_includeBeginning && _beginningController.text.trim().isEmpty) ||
        (_includeMiddle && _middleController.text.trim().isEmpty) ||
        (_includeEnd && _endController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All enabled banner texts must be filled'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Use recommended positions if selected
      BannerPositions? positionsToUse;
      if (_useRecommendedPositions && _recommendedPositions != null) {
        positionsToUse = _recommendedPositions;
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
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$insertedCount banner${insertedCount == 1 ? '' : 's'} inserted successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to insert banners');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inserting banners: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Insert Subtitle Banners',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    'Add promotional banners at the beginning, middle, and end of your subtitle file. Each banner will display for 10 seconds.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Banner positions info
                  if (_bannerPositions != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calculated Banner Positions:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('• Beginning: ${_formatDuration(_bannerPositions!.beginningPosition)}', 
                               style: Theme.of(context).textTheme.bodySmall),
                          Text('• Middle: ${_formatDuration(_bannerPositions!.middlePosition)}', 
                               style: Theme.of(context).textTheme.bodySmall),
                          Text('• End: ${_formatDuration(_bannerPositions!.endPosition)}', 
                               style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Warnings and recommendations
                  if (_validationResult?.warnings.isNotEmpty == true) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                          const SizedBox(height: 8),
                          ...(_validationResult!.warnings.map((warning) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $warning', 
                                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                           color: Colors.orange.shade700,
                                         )),
                            ),
                          )),
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
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
                            value: _useRecommendedPositions,
                            onChanged: (value) {
                              setState(() {
                                _useRecommendedPositions = value ?? false;
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _insertBanners,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: _isProcessing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.add_circle_outline, size: 20),
                  label: Text(_isProcessing ? 'Inserting...' : 'Insert Banners'),
                ),
              ],
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnabled 
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled 
              ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: isEnabled,
                onChanged: onToggle,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
              Icon(
                icon, 
                size: 20, 
                color: isEnabled 
                    ? Theme.of(context).primaryColor 
                    : Theme.of(context).disabledColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isEnabled 
                        ? null 
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              enabled: isEnabled,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
