import 'package:flutter/material.dart';
import 'package:subtitle_studio/features/waveform/models/waveform_sample.dart';
import 'package:subtitle_studio/database/models/models.dart';

/// Custom painter for rendering waveform visualization
class WaveformPainter extends CustomPainter {
  final ZoomLevel zoomLevel;
  final double scrollOffset; // in pixels
  final Duration playbackPosition;
  final List<SubtitleLine> subtitles;
  final Color waveformColor;
  final Color subtitleColor;
  final Color playbackColor;
  final double channelHeight;
  final double channelSpacing;
  final int sampleRate;
  final int samplesPerPixel;
  final double verticalZoom; // Amplitude multiplier
  final Color? backgroundColor;
  final bool showSubtitlesOnly; // Show only subtitle boxes
  final bool showWaveformOnly; // Show only waveform
  final Color? subtitleHighlightColor; // Color for highlighting subtitle regions in waveform
  final bool showPlaybackIndicator; // Whether to show the playback indicator
  
  // Edit mode parameters
  final bool isEditMode; // Whether in time edit mode
  final int? editingSubtitleIndex; // Index of subtitle being edited
  final Duration? tempStartTime; // Temporary start time during editing
  final Duration? tempEndTime; // Temporary end time during editing
  
  // Add line mode parameters
  final bool isAddLineMode; // Whether in add line mode
  final Duration? addLineStartTime; // Start time for new line
  final Duration? addLineEndTime; // End time for new line
  
  // Highlighting parameters
  final int? highlightedSubtitleIndex; // Index of currently highlighted subtitle (0-based)

  WaveformPainter({
    required this.zoomLevel,
    required this.scrollOffset,
    required this.playbackPosition,
    required this.subtitles,
    required this.sampleRate,
    required this.samplesPerPixel,
    this.waveformColor = const Color(0xFF00BCD4),
    this.subtitleColor = const Color(0xFFFF9800), // Orange color
    this.playbackColor = const Color(0xFFFF5252),
    this.channelHeight = 60.0,
    this.channelSpacing = 10.0,
    this.verticalZoom = 1.5,
    this.backgroundColor,
    this.showSubtitlesOnly = false,
    this.showWaveformOnly = false,
    this.subtitleHighlightColor,
    this.showPlaybackIndicator = true,
    this.isEditMode = false,
    this.editingSubtitleIndex,
    this.tempStartTime,
    this.tempEndTime,
    this.isAddLineMode = false,
    this.addLineStartTime,
    this.addLineEndTime,
    this.highlightedSubtitleIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final backgroundPaint = Paint()
      ..color = backgroundColor ?? Colors.black12
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Calculate dynamic channel height based on available space
    final channels = zoomLevel.channels;
    final totalSpacing = channelSpacing * (channels + 1);
    final availableHeight = size.height - totalSpacing;
    final dynamicChannelHeight = availableHeight / channels;

    // Draw waveform for each channel (only if not subtitle-only mode)
    if (!showSubtitlesOnly) {
      for (var ch = 0; ch < channels; ch++) {
        final yOffset = ch * (dynamicChannelHeight + channelSpacing) + channelSpacing;
        _drawChannel(
          canvas,
          size,
          ch,
          yOffset,
          dynamicChannelHeight,
        );
      }
    }

    // Draw subtitle boxes (only if not waveform-only mode)
    if (!showWaveformOnly) {
      _drawSubtitles(canvas, size);
    }

    // Draw add line mode overlay (if active)
    if (isAddLineMode && addLineStartTime != null && addLineEndTime != null) {
      _drawAddLineOverlay(canvas, size);
    }

    // Draw playback position (only if flag is enabled)
    if (showPlaybackIndicator) {
      _drawPlaybackPosition(canvas, size);
    }

    // Draw center line for each channel (only if showing waveform)
    if (!showSubtitlesOnly) {
      for (var ch = 0; ch < channels; ch++) {
        final yCenter = ch * (dynamicChannelHeight + channelSpacing) +
            channelSpacing +
            dynamicChannelHeight / 2;
        final centerLinePaint = Paint()
          ..color = Colors.white24
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(0, yCenter),
          Offset(size.width, yCenter),
          centerLinePaint,
        );
      }
    }
  }

  /// Draw waveform for a single channel
  void _drawChannel(Canvas canvas, Size size, int channel, double yOffset, double dynamicChannelHeight) {
    final channelData = zoomLevel.getChannelData(channel);
    if (channelData == null) return;

    final centerY = yOffset + dynamicChannelHeight / 2;
    // Apply vertical zoom to amplitude
    final amplitude = dynamicChannelHeight / 2 * 0.98 * verticalZoom;

    // Calculate visible range
    final startPixel = scrollOffset.floor();
    final endPixel = (scrollOffset + size.width).ceil();

    // Fill waveform area for better visibility (draw first, behind the stroke)
    final fillPath = Path();
    bool firstFillPoint = true;

    for (var pixel = startPixel; pixel < endPixel && pixel < channelData.length; pixel++) {
      final sample = channelData[pixel];
      final x = pixel - scrollOffset;
      final yMax = centerY - (sample.max * amplitude);

      if (firstFillPoint) {
        fillPath.moveTo(x, centerY);
        firstFillPoint = false;
      }
      fillPath.lineTo(x, yMax);
    }

    // Complete the fill path
    if (!firstFillPoint) {
      fillPath.lineTo((endPixel - scrollOffset).toDouble(), centerY);
      fillPath.close();

      final fillPaint = Paint()
        ..color = waveformColor.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw waveform stroke on top with thinner line
    final waveformPaint = Paint()
      ..color = waveformColor
      ..strokeWidth = 1.0 // Thinner stroke
      ..style = PaintingStyle.stroke;

    // Draw waveform using lines
    final path = Path();
    bool isFirstPoint = true;

    for (var pixel = startPixel; pixel < endPixel && pixel < channelData.length; pixel++) {
      final sample = channelData[pixel];
      final x = pixel - scrollOffset;

      // Draw from min to max for this pixel
      final yMin = centerY - (sample.min * amplitude);
      final yMax = centerY - (sample.max * amplitude);

      if (isFirstPoint) {
        path.moveTo(x, yMin);
        isFirstPoint = false;
      }

      // Draw vertical line from min to max
      path.lineTo(x, yMin);
      path.lineTo(x, yMax);
    }

    canvas.drawPath(path, waveformPaint);
  }

  /// Draw subtitle overlays
  void _drawSubtitles(Canvas canvas, Size size) {
    final subtitlePaint = Paint()
      ..color = subtitleColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final subtitleBorderPaint = Paint()
      ..color = subtitleColor
      ..strokeWidth = 1.0 // Reduced from 2.0 to 1.0 for thinner border
      ..style = PaintingStyle.stroke;
    
    // Highlighted subtitle paint (same as list)
    final highlightedSubtitlePaint = Paint()
      ..color = const Color.fromARGB(200, 244, 163, 97).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final highlightedSubtitleBorderPaint = Paint()
      ..color = const Color.fromARGB(200, 244, 163, 97)
      ..strokeWidth = 1.0 // Reduced from 3.0 to 1.0 for thinner border
      ..style = PaintingStyle.stroke;
    
    // Highlighted edit mode paint - dark colors
    final editHighlightPaint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.3) // Dark green
      ..style = PaintingStyle.fill;
    
    final editBorderPaint = Paint()
      ..color = const Color(0xFF2E7D32) // Dark green
      ..strokeWidth = 1.0 // Reduced from 3.0 to 1.0 for thinner border
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < subtitles.length; i++) {
      final subtitle = subtitles[i];
      final isEditing = isEditMode && editingSubtitleIndex == i;
      final isHighlighted = highlightedSubtitleIndex != null && highlightedSubtitleIndex == i;
      
      Duration startTime;
      Duration endTime;
      
      if (isEditing && tempStartTime != null) {
        startTime = tempStartTime!;
      } else {
        startTime = _parseTimeString(subtitle.startTime);
      }
      
      if (isEditing && tempEndTime != null) {
        endTime = tempEndTime!;
      } else {
        endTime = _parseTimeString(subtitle.endTime);
      }

      final startPixel = _timeToPixel(startTime);
      final endPixel = _timeToPixel(endTime);

      // Check if subtitle is visible
      if (endPixel < scrollOffset || startPixel > scrollOffset + size.width) {
        continue;
      }

      final left = (startPixel - scrollOffset).clamp(0.0, size.width);
      final right = (endPixel - scrollOffset).clamp(0.0, size.width);
      final width = right - left;

      if (width <= 0) continue;

      // Draw rectangle with reduced height (60% of total, centered vertically)
      const heightRatio = 0.6;
      final boxHeight = size.height * heightRatio;
      final topOffset = (size.height - boxHeight) / 2;
      final rect = Rect.fromLTWH(left, topOffset, width, boxHeight);

      // Use different colors for editing subtitle
      if (isEditing) {
        canvas.drawRect(rect, editHighlightPaint);
        canvas.drawRect(rect, editBorderPaint);
      } else if (isHighlighted) {
        canvas.drawRect(rect, highlightedSubtitlePaint);
        canvas.drawRect(rect, highlightedSubtitleBorderPaint);
      } else {
        canvas.drawRect(rect, subtitlePaint);
        canvas.drawRect(rect, subtitleBorderPaint);
      }

      // Draw subtitle text at top center if wide enough
      if (width > 15) {
        final displayText = subtitle.edited ?? subtitle.original;
        _drawSubtitleText(
          canvas,
          displayText,
          rect,
          subtitle.index, // Pass the subtitle index
        );
      }
      
      // Draw duration at bottom left corner
      _drawSubtitleDuration(canvas, rect, startTime, endTime);
      
      // Draw index at top right corner
      _drawSubtitleIndex(canvas, rect, subtitle.index);
      
      // Draw draggable bars if this subtitle is being edited
      if (isEditing) {
        _drawDraggableBars(canvas, size, left, right);
        
        // Draw move indicator icon in the center on top (drag from center to move)
        if (width > 60) {
          final iconTextPainter = TextPainter(
            text: TextSpan(
              text: String.fromCharCode(Icons.drag_indicator.codePoint),
              style: const TextStyle(
                fontFamily: 'MaterialIcons',
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          iconTextPainter.layout();
          iconTextPainter.paint(
            canvas,
            Offset(
              rect.left + (rect.width - iconTextPainter.width) / 2,
              rect.top + (rect.height - iconTextPainter.height) / 2,
            ),
          );
        }
      }
    }
  }
  
  /// Draw draggable bars at start and end of selected subtitle
  void _drawDraggableBars(Canvas canvas, Size size, double left, double right) {
    const barWidth = 1.0; // Reduced from 8.0 to 3.0 for less waveform coverage
    const barColor = Colors.amber;
    const handleSize = 16.0;
    
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    
    final handlePaint = Paint()
      ..color = barColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    // Get the current times being edited
    Duration? startTime = tempStartTime;
    Duration? endTime = tempEndTime;
    
    // Draw start bar
    if (left >= 0 && left <= size.width) {
      // Vertical bar
      final startBarRect = Rect.fromLTWH(
        left - barWidth / 2,
        0,
        barWidth,
        size.height,
      );
      canvas.drawRect(startBarRect, barPaint);
      
      // Handle at middle
      final startHandleRect = Rect.fromLTWH(
        left - handleSize / 2,
        size.height / 2 - handleSize / 2,
        handleSize,
        handleSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(startHandleRect, const Radius.circular(4)),
        handlePaint,
      );
      
      // Draw icon on handle
      _drawBarIcon(canvas, startHandleRect, Icons.arrow_left);
      
      // Draw time label at top left corner
      if (startTime != null) {
        _drawTimeLabel(canvas, left, 20, startTime, isStart: true);
      }
    }
    
    // Draw end bar
    if (right >= 0 && right <= size.width) {
      // Vertical bar
      final endBarRect = Rect.fromLTWH(
        right - barWidth / 2,
        0,
        barWidth,
        size.height,
      );
      canvas.drawRect(endBarRect, barPaint);
      
      // Handle at middle
      final endHandleRect = Rect.fromLTWH(
        right - handleSize / 2,
        size.height / 2 - handleSize / 2,
        handleSize,
        handleSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(endHandleRect, const Radius.circular(4)),
        handlePaint,
      );
      
      // Draw icon on handle
      _drawBarIcon(canvas, endHandleRect, Icons.arrow_right);
      
      // Draw time label at bottom right corner
      if (endTime != null) {
        _drawTimeLabel(canvas, right, size.height - 35, endTime, isStart: false);
      }
    }
  }
  
  /// Draw time label above draggable bar
  void _drawTimeLabel(Canvas canvas, double x, double y, Duration time, {required bool isStart}) {
    final hours = time.inHours.toString().padLeft(2, '0');
    final minutes = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds = time.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    final timeString = '$hours:$minutes:$seconds,$milliseconds';
    
    final textSpan = TextSpan(
      text: timeString,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        backgroundColor: Color(0xDD000000),
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Position label slightly to the right of start bar, or left of end bar
    final offsetX = isStart ? x + 10 : x - textPainter.width - 10;
    
    textPainter.paint(
      canvas,
      Offset(offsetX.clamp(0, double.infinity), y),
    );
  }
  
  /// Draw icon on draggable bar handle
  void _drawBarIcon(Canvas canvas, Rect rect, IconData icon) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      ),
    );
  }

  /// Draw add line mode overlay showing selected time range
  void _drawAddLineOverlay(Canvas canvas, Size size) {
    if (addLineStartTime == null || addLineEndTime == null) return;
    
    final startPixel = _timeToPixel(addLineStartTime!);
    final endPixel = _timeToPixel(addLineEndTime!);
    
    final left = (startPixel - scrollOffset).clamp(0.0, size.width);
    final right = (endPixel - scrollOffset).clamp(0.0, size.width);
    final width = right - left;
    
    if (width <= 0) return;
    
    // Draw selection overlay with teal tint (matching edit mode design)
    const heightRatio = 0.6;
    final boxHeight = size.height * heightRatio;
    final topOffset = (size.height - boxHeight) / 2;
    final rect = Rect.fromLTWH(left, topOffset, width, boxHeight);
    
    final overlayPaint = Paint()
      ..color = const Color(0xFF00695C).withOpacity(0.3) // Dark teal
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = const Color(0xFF00695C) // Dark teal
      ..strokeWidth = 1.0 // Reduced from 3.0 to 1.0 for thinner border
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(rect, overlayPaint);
    canvas.drawRect(rect, borderPaint);
    
    // Draw "NEW LINE" text at top center if wide enough
    if (width > 80) {
      final textSpan = TextSpan(
        text: 'NEW LINE',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          rect.left + (rect.width - textPainter.width) / 2,
          rect.top + 8,
        ),
      );
    }
    
    // Draw duration at bottom left corner
    _drawSubtitleDuration(canvas, rect, addLineStartTime!, addLineEndTime!);
    
    // Draw move indicator icon in the center (drag from center to move)
    if (width > 60) {
      final iconTextPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.drag_indicator.codePoint),
          style: const TextStyle(
            fontFamily: 'MaterialIcons',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconTextPainter.layout();
      iconTextPainter.paint(
        canvas,
        Offset(
          rect.left + (rect.width - iconTextPainter.width) / 2,
          rect.top + (rect.height - iconTextPainter.height) / 2,
        ),
      );
    }
    
    // Draw draggable bars at start and end (matching edit mode design)
    _drawAddLineBars(canvas, size, left, right);
  }
  
  /// Draw draggable bars at start and end of add line overlay
  void _drawAddLineBars(Canvas canvas, Size size, double left, double right) {
    const barWidth = 1.0; // Reduced from 8.0 to 3.0 for less waveform coverage
    final barColor = const Color(0xFF00695C); // Dark teal
    const handleSize = 16.0;
    
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    
    final handlePaint = Paint()
      ..color = barColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    // Draw start bar
    if (left >= 0 && left <= size.width) {
      // Vertical bar
      final startBarRect = Rect.fromLTWH(
        left - barWidth / 2,
        0,
        barWidth,
        size.height,
      );
      canvas.drawRect(startBarRect, barPaint);
      
      // Handle at middle
      final startHandleRect = Rect.fromLTWH(
        left - handleSize / 2,
        size.height / 2 - handleSize / 2,
        handleSize,
        handleSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(startHandleRect, const Radius.circular(4)),
        handlePaint,
      );
      
      // Draw icon on handle
      _drawBarIcon(canvas, startHandleRect, Icons.arrow_left);
      
      // Draw time label at top left corner
      if (addLineStartTime != null) {
        _drawAddLineTimeLabel(canvas, left, 20, addLineStartTime!, isStart: true);
      }
    }
    
    // Draw end bar
    if (right >= 0 && right <= size.width) {
      // Vertical bar
      final endBarRect = Rect.fromLTWH(
        right - barWidth / 2,
        0,
        barWidth,
        size.height,
      );
      canvas.drawRect(endBarRect, barPaint);
      
      // Handle at middle
      final endHandleRect = Rect.fromLTWH(
        right - handleSize / 2,
        size.height / 2 - handleSize / 2,
        handleSize,
        handleSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(endHandleRect, const Radius.circular(4)),
        handlePaint,
      );
      
      // Draw icon on handle
      _drawBarIcon(canvas, endHandleRect, Icons.arrow_right);
      
      // Draw time label at bottom right corner
      if (addLineEndTime != null) {
        _drawAddLineTimeLabel(canvas, right, size.height - 35, addLineEndTime!, isStart: false);
      }
    }
  }
  
  /// Draw time label for add line mode (start at top left, end at bottom right)
  void _drawAddLineTimeLabel(Canvas canvas, double x, double y, Duration time, {required bool isStart}) {
    final hours = time.inHours.toString().padLeft(2, '0');
    final minutes = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds = time.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    final timeString = '$hours:$minutes:$seconds,$milliseconds';
    
    final textSpan = TextSpan(
      text: timeString,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        backgroundColor: Color(0xDD000000),
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Position label slightly to the right of start bar (top left), or left of end bar (bottom right)
    final offsetX = isStart ? x + 10 : x - textPainter.width - 10;
    
    textPainter.paint(
      canvas,
      Offset(offsetX.clamp(0, double.infinity), y),
    );
  }

  /// Draw subtitle text on rectangle with wrapping
  void _drawSubtitleText(Canvas canvas, String text, Rect rect, int subtitleIndex) {
    // For very small boxes, show centered index number
    if (rect.width < 40) {
      final displayText = '$subtitleIndex';
      
      final textSpan = TextSpan(
        text: displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          rect.left + (rect.width - textPainter.width) / 2,
          rect.top + (rect.height - textPainter.height) / 2, // Center vertically
        ),
      );
      return;
    }

    // For medium and larger boxes, show text with adaptive sizing
    // Determine font size based on box width
    double fontSize;
    int maxLines;
    if (rect.width < 80) {
      fontSize = 10;
      maxLines = 1;
    } else if (rect.width < 150) {
      fontSize = 11;
      maxLines = 2;
    } else {
      fontSize = 12;
      maxLines = 2;
    }
    
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: maxLines,
      ellipsis: '...',
    );

    textPainter.layout(maxWidth: rect.width - 4);

    textPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - textPainter.width) / 2, // Center horizontally
        rect.top + (rect.height - textPainter.height) / 2, // Center vertically
      ),
    );
  }

  /// Draw subtitle duration at bottom left corner of the overlay
  void _drawSubtitleDuration(Canvas canvas, Rect rect, Duration startTime, Duration endTime) {
    final duration = endTime - startTime;
    final seconds = duration.inMilliseconds / 1000.0;
    final durationText = '${seconds.toStringAsFixed(2)}s';
    
    final textSpan = TextSpan(
      text: durationText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    // Draw at bottom left corner with small padding
    textPainter.paint(
      canvas,
      Offset(
        rect.left + 4, // 4px padding from left
        rect.bottom - textPainter.height - 4, // 4px padding from bottom
      ),
    );
  }

  /// Draw subtitle index at top right corner of the overlay
  void _drawSubtitleIndex(Canvas canvas, Rect rect, int index) {
    final indexText = '#$index';
    
    final textSpan = TextSpan(
      text: indexText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    // Draw at top right corner with small padding
    textPainter.paint(
      canvas,
      Offset(
        rect.right - textPainter.width - 4, // 4px padding from right
        rect.top + 4, // 4px padding from top
      ),
    );
  }

  /// Draw playback position indicator (smart positioning)
  void _drawPlaybackPosition(Canvas canvas, Size size) {
    // Calculate pixels per second from sample rate and samples per pixel
    final pixelsPerSec = sampleRate / samplesPerPixel;
    
    // Calculate indicator position based on playback and scroll
    final playbackPixel = (playbackPosition.inMilliseconds / 1000.0) * pixelsPerSec;
    final centerPosition = size.width / 2;
    final totalWidth = zoomLevel.pixelCount.toDouble();
    
    double indicatorX;
    
    // Smart positioning:
    // - Before center: moves from left (0 to center)
    // - Middle: stays at center
    // - At end: moves from center to right edge when scrolling stops
    
    if (playbackPixel <= centerPosition) {
      // Beginning phase: indicator moves from left
      indicatorX = playbackPixel - scrollOffset;
    } else if (playbackPixel >= totalWidth - centerPosition) {
      // End phase: waveform stops scrolling, indicator moves from center to right
      // Calculate position relative to visible portion
      final visibleStart = scrollOffset;
      indicatorX = playbackPixel - visibleStart;
    } else {
      // Middle phase: indicator stays centered
      indicatorX = centerPosition;
    }
    
    // Clamp to viewport bounds
    indicatorX = indicatorX.clamp(0.0, size.width);

    final playbackPaint = Paint()
      ..color = playbackColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(indicatorX, 0),
      Offset(indicatorX, size.height),
      playbackPaint,
    );

    // Draw playhead triangle at top (inverted arrow pointing down)
    final path = Path();
    path.moveTo(indicatorX, 12);
    path.lineTo(indicatorX - 8, 0);
    path.lineTo(indicatorX + 8, 0);
    path.close();

    final playheadPaint = Paint()
      ..color = playbackColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, playheadPaint);

    // Note: Time position is now displayed as an overlay widget in waveform_widget.dart
    // for tap-to-copy functionality, so we don't draw it here anymore
  }

  /// Convert time to pixel position
  double _timeToPixel(Duration time) {
    final sample = (time.inMicroseconds * sampleRate / 1000000).round();
    return sample / samplesPerPixel;
  }

  /// Parse time string to Duration
  Duration _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 3) return Duration.zero;

      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final secondsParts = parts[2].split(',');
      final seconds = int.parse(secondsParts[0]);
      final milliseconds = int.parse(secondsParts[1]);

      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    } catch (e) {
      return Duration.zero;
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.playbackPosition != playbackPosition ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.subtitles != subtitles ||
        oldDelegate.subtitles.length != subtitles.length ||
        oldDelegate.verticalZoom != verticalZoom ||
        oldDelegate.isEditMode != isEditMode ||
        oldDelegate.editingSubtitleIndex != editingSubtitleIndex ||
        oldDelegate.tempStartTime != tempStartTime ||
        oldDelegate.tempEndTime != tempEndTime ||
        oldDelegate.isAddLineMode != isAddLineMode ||
        oldDelegate.addLineStartTime != addLineStartTime ||
        oldDelegate.addLineEndTime != addLineEndTime;
  }
}