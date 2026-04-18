import 'package:flutter/material.dart';
import 'package:subtitle_studio/utils/subtitle_positioning_parser.dart';

class PositioningButtonsWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onApply;

  const PositioningButtonsWidget({
    super.key, 
    required this.controller,
    this.onApply,
  });

  @override
  State<PositioningButtonsWidget> createState() => _PositioningButtonsWidgetState();
}

class _PositioningButtonsWidgetState extends State<PositioningButtonsWidget> {
  int? _selectedPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = _getCurrentPosition();
  }

  int? _getCurrentPosition() {
    final position = SubtitlePositioningParser.getPositionCode(widget.controller.text);
    // If no position code is found, default to position 2 (bottom center)
    return position ?? 2;
  }

  void _applyPositionCode(int position) {
    String text = widget.controller.text;
    
    // Remove any existing position code
    final RegExp positionRegex = RegExp(r'^\{\\an[1-9]\}');
    text = text.replaceFirst(positionRegex, '');

    // Only add position code if it's not the default (position 2)
    if (position != 2) {
      String newPositionCode = '{\\an$position}';
      widget.controller.text = '$newPositionCode$text';
    } else {
      // For default position (2), just remove any existing codes
      widget.controller.text = text;
    }
    
    setState(() {
      _selectedPosition = position;
    });
  }

  void _removePositionCode() {
    final RegExp positionRegex = RegExp(r'^\{\\an[1-9]\}');
    widget.controller.text = widget.controller.text.replaceFirst(positionRegex, '');
    
    setState(() {
      _selectedPosition = null;
    });
  }

  Future<void> _handleApply() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate a brief delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _isLoading = false;
    });

    if (widget.onApply != null) {
      widget.onApply!();
    }
  }

  Map<int, String> _getPositionLabels() {
    return SubtitlePositioningParser.getPositioningOptions();
  }

  IconData _getIconForPosition(int position) {
    const iconMap = {
      1: Icons.south_west,     // Bottom Left
      2: Icons.south,          // Bottom Center
      3: Icons.south_east,     // Bottom Right
      4: Icons.west,           // Middle Left
      5: Icons.control_camera, // Middle Center
      6: Icons.east,           // Middle Right
      7: Icons.north_west,     // Top Left
      8: Icons.north,          // Top Center
      9: Icons.north_east,     // Top Right
    };
    return iconMap[position] ?? Icons.control_camera;
  }

  Color _getColorForPosition(int position) {
    // Use a color scheme that differentiates position groups
    if (position >= 1 && position <= 3) {
      return Colors.blue; // Bottom positions
    } else if (position >= 4 && position <= 6) {
      return Colors.orange; // Middle positions
    } else {
      return Colors.green; // Top positions
    }
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.place,
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
                        "Subtitle Positioning",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Choose where subtitles appear on screen",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
      
            // Current Position Display
            if (_selectedPosition != null)
              Container(
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
                        color: _getColorForPosition(_selectedPosition!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForPosition(_selectedPosition!),
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
                            "Current Position",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getPositionLabels()[_selectedPosition!] ?? "Unknown",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getColorForPosition(_selectedPosition!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedPosition == 2 ? "Default" : "{\\an$_selectedPosition}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),              if (_selectedPosition != null) const SizedBox(height: 16),
      
                // Position Grid
                Text(
                  "Select Position",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
      
                // Position selection grid arranged like a 3x3 grid representing screen positions
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Top row (7, 8, 9)
                        Row(
                          children: [
                            Expanded(child: _buildPositionButton(7)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildPositionButton(8)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildPositionButton(9)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Middle row (4, 5, 6)
                        Row(
                          children: [
                            Expanded(child: _buildPositionButton(4)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildPositionButton(5)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildPositionButton(6)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Bottom row (1, 2, 3)
                        Row(
                          children: [
                            Expanded(child: _buildPositionButton(1)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildPositionButton(2)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildPositionButton(3)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
      
                const SizedBox(height: 16),
      
                // Remove Position Button
                if (_selectedPosition != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _removePositionCode,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.clear,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Remove Positioning",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      
                if (_selectedPosition != null) const SizedBox(height: 16),
      
                const SizedBox(height: 24),
      
                // Apply Button
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
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
                              const Icon(Icons.check, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Apply Position",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
      
                const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionButton(int position) {
    final isSelected = _selectedPosition == position;
    final positionColor = _getColorForPosition(position);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _applyPositionCode(position),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? positionColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? positionColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForPosition(position),
                color: isSelected ? positionColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                position == 2 ? "Default" : "$position",
                style: TextStyle(
                  color: isSelected ? positionColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: position == 2 ? 10 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
