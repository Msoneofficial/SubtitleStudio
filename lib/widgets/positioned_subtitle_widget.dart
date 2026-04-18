import 'package:flutter/material.dart';
import 'package:subtitle_studio/widgets/custom_text_render.dart';
import 'package:subtitle_studio/utils/subtitle_positioning_parser.dart';

/// Helper function to check if subtitle text has positioning tags
bool hasPositioningTag(String text) {
  final RegExp positionRegex = RegExp(r'^\{\\an[1-9]\}');
  return positionRegex.hasMatch(text);
}

/// Helper function to check if subtitle has top positioning tag ({\an7}, {\an8}, {\an9})
bool hasTopPositioningTag(String text) {
  final RegExp topPositionRegex = RegExp(r'^\{\\an[7-9]\}');
  return topPositionRegex.hasMatch(text);
}

/// A widget that renders subtitles with proper positioning based on ASS/SSA codes
/// 
/// This widget parses positioning codes like {\an1}, {\an2}, etc. and positions
/// the subtitle text accordingly within the video player area.
/// 
/// Features:
/// - Support for all 9 ASS/SSA positioning codes
/// - Automatic text cleaning (removes positioning codes from display)
/// - Configurable padding and styling
/// - Responsive positioning for different screen sizes
/// - Integration with existing CustomHtmlText renderer
class PositionedSubtitleWidget extends StatelessWidget {
  final String subtitleText;
  final TextStyle textStyle;
  final double horizontalPadding;
  final double verticalPadding;
  final double topPadding;
  final bool isFullscreen;
  
  const PositionedSubtitleWidget({
    super.key,
    required this.subtitleText,
    required this.textStyle,
    this.horizontalPadding = 30.0,
    this.verticalPadding = 50.0,
    this.topPadding = 30.0,
    this.isFullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    // Parse the positioning from the subtitle text
    final positioning = SubtitlePositioningParser.parsePositioning(
      subtitleText,
      horizontalPadding: horizontalPadding,
      verticalPadding: isFullscreen ? 40.0 : verticalPadding,
      topPadding: isFullscreen ? 40.0 : topPadding,
    );

    // If no text after cleaning, return empty widget
    if (positioning.cleanText.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Handle middle positions differently using Align instead of Positioned
    if (positioning.isMiddlePosition) {
      return Align(
        alignment: positioning.alignment,
        child: Padding(
          padding: EdgeInsets.only(
            left: positioning.left ?? 0,
            right: positioning.right ?? 0,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: CustomHtmlText(
              htmlContent: positioning.cleanText.replaceAll('\n', '<br>'),
              defaultStyle: textStyle,
              textAlign: positioning.textAlign,
              expanded: false,
              maxLines: null,
            ),
          ),
        ),
      );
    }

    // Use Positioned for top and bottom positions
    return Positioned(
      left: positioning.left,
      right: positioning.right,
      top: positioning.top,
      bottom: positioning.bottom,
      child: Material(
        type: MaterialType.transparency,
        child: CustomHtmlText(
          htmlContent: positioning.cleanText.replaceAll('\n', '<br>'),
          defaultStyle: textStyle,
          textAlign: positioning.textAlign,
          expanded: true,
          maxLines: null,
        ),
      ),
    );
  }
}

/// A widget that renders multiple overlapping subtitles with proper positioning
/// 
/// This widget intelligently handles multiple subtitles at the same timecode:
/// - Subtitles WITH positioning tags ({\an8}, etc.) are displayed at their specified positions
/// - Subtitles WITHOUT positioning tags are combined and displayed at the default bottom position
/// - If forceTopPosition is true, ignores all positioning tags and displays at top center
/// - If primarySubtitleTexts provided, checks for top collision and adjusts spacing
/// 
/// Example: If subtitle 1 is "Hello" and subtitle 2 is "{\an8}Top text",
/// they will both display simultaneously - "Hello" at bottom, "Top text" at top
class MultipleOverlappingSubtitlesWidget extends StatelessWidget {
  final List<String> subtitleTexts;
  final TextStyle textStyle;
  final double horizontalPadding;
  final double verticalPadding;
  final double topPadding;
  final bool isFullscreen;
  final double verticalOffset;
  final bool forceTopPosition; // Force all subtitles to display at top (for secondary subtitles)
  final List<String>? primarySubtitleTexts; // Used to detect collision with primary subtitles
  
  const MultipleOverlappingSubtitlesWidget({
    super.key,
    required this.subtitleTexts,
    required this.textStyle,
    this.horizontalPadding = 30.0,
    this.verticalPadding = 50.0,
    this.topPadding = 30.0,
    this.isFullscreen = false,
    this.verticalOffset = 0.0,
    this.forceTopPosition = false,
    this.primarySubtitleTexts,
  });

  @override
  Widget build(BuildContext context) {
    if (subtitleTexts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // If forceTopPosition is true, ignore all positioning tags and display at top
    if (forceTopPosition) {
      // Check if any primary subtitle has top positioning tags (collision detection)
      bool hasTopCollision = false;
      if (primarySubtitleTexts != null && primarySubtitleTexts!.isNotEmpty) {
        hasTopCollision = primarySubtitleTexts!.any((text) => hasTopPositioningTag(text));
      }
      
      final combinedText = subtitleTexts
          .map((text) => SubtitlePositioningParser.removePositioningCode(text))
          .join('\n');
      
      if (combinedText.trim().isEmpty) {
        return const SizedBox.shrink();
      }
      
      // If there's a collision, add extra top padding to push secondary subtitle down
      // This creates a column effect with primary on top and secondary below it
      final adjustedTopPadding = hasTopCollision 
          ? (isFullscreen ? 40.0 : topPadding) + verticalOffset + 60.0 // Add extra spacing
          : (isFullscreen ? 40.0 : topPadding) + verticalOffset;
      
      return SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              left: horizontalPadding,
              right: horizontalPadding,
              top: adjustedTopPadding,
              child: Material(
                type: MaterialType.transparency,
                child: CustomHtmlText(
                  htmlContent: combinedText.replaceAll('\n', '<br>'),
                  defaultStyle: textStyle,
                  textAlign: TextAlign.center,
                  expanded: true,
                  maxLines: null,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Normal mode: respect positioning tags
    // Separate subtitles with positioning tags from those without
    final positioned = <String>[];
    final nonPositioned = <String>[];
    
    for (final text in subtitleTexts) {
      if (hasPositioningTag(text)) {
        positioned.add(text);
      } else {
        nonPositioned.add(text);
      }
    }
    
    final List<Widget> subtitleWidgets = [];
    
    // Add each positioned subtitle at its specified location
    for (final text in positioned) {
      final positioning = SubtitlePositioningParser.parsePositioning(
        text,
        horizontalPadding: horizontalPadding,
        verticalPadding: (isFullscreen ? 40.0 : verticalPadding) + verticalOffset,
        topPadding: (isFullscreen ? 40.0 : topPadding) + verticalOffset,
      );
      
      if (positioning.cleanText.trim().isEmpty) continue;
      
      if (positioning.isMiddlePosition) {
        subtitleWidgets.add(
          Align(
            alignment: positioning.alignment,
            child: Padding(
              padding: EdgeInsets.only(
                left: positioning.left ?? 0,
                right: positioning.right ?? 0,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: CustomHtmlText(
                  htmlContent: positioning.cleanText.replaceAll('\n', '<br>'),
                  defaultStyle: textStyle,
                  textAlign: positioning.textAlign,
                  expanded: false,
                  maxLines: null,
                ),
              ),
            ),
          ),
        );
      } else {
        subtitleWidgets.add(
          Positioned(
            left: positioning.left,
            right: positioning.right,
            top: positioning.top,
            bottom: positioning.bottom,
            child: Material(
              type: MaterialType.transparency,
              child: CustomHtmlText(
                htmlContent: positioning.cleanText.replaceAll('\n', '<br>'),
                defaultStyle: textStyle,
                textAlign: positioning.textAlign,
                expanded: true,
                maxLines: null,
              ),
            ),
          ),
        );
      }
    }
    
    // Combine all non-positioned subtitles and display at default bottom position
    if (nonPositioned.isNotEmpty) {
      final combinedText = nonPositioned.join('\n');
      final positioning = SubtitlePositioningParser.parsePositioning(
        combinedText, // No positioning tag, will use default bottom center
        horizontalPadding: horizontalPadding,
        verticalPadding: (isFullscreen ? 40.0 : verticalPadding) + verticalOffset,
        topPadding: (isFullscreen ? 40.0 : topPadding) + verticalOffset,
      );
      
      if (positioning.cleanText.trim().isNotEmpty) {
        subtitleWidgets.add(
          Positioned(
            left: positioning.left,
            right: positioning.right,
            top: positioning.top,
            bottom: positioning.bottom,
            child: Material(
              type: MaterialType.transparency,
              child: CustomHtmlText(
                htmlContent: positioning.cleanText.replaceAll('\n', '<br>'),
                defaultStyle: textStyle,
                textAlign: positioning.textAlign,
                expanded: true,
                maxLines: null,
              ),
            ),
          ),
        );
      }
    }
    
    if (subtitleWidgets.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return SizedBox.expand(
      child: Stack(children: subtitleWidgets),
    );
  }
}
/// A widget that renders multiple positioned subtitles in a stack
/// 
/// This widget handles primary and secondary subtitles with intelligent positioning
/// to avoid conflicts. If both subtitles have the same position, it adjusts the
/// secondary subtitle position automatically.
class PositionedSubtitlesOverlay extends StatelessWidget {
  final String? primarySubtitle;
  final String? secondarySubtitle;
  final TextStyle primaryStyle;
  final TextStyle secondaryStyle;
  final double horizontalPadding;
  final double verticalPadding;
  final double topPadding;
  final bool isFullscreen;
  final double primaryVerticalOffset;
  final double secondaryVerticalOffset;
  
  const PositionedSubtitlesOverlay({
    super.key,
    this.primarySubtitle,
    this.secondarySubtitle,
    required this.primaryStyle,
    required this.secondaryStyle,
    this.horizontalPadding = 30.0,
    this.verticalPadding = 50.0,
    this.topPadding = 30.0,
    this.isFullscreen = false,
    this.primaryVerticalOffset = 0.0,
    this.secondaryVerticalOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> subtitleWidgets = [];
    
    // Parse positioning for primary subtitle only
    SubtitlePositioning? primaryPositioning;
    
    if (primarySubtitle != null && primarySubtitle!.trim().isNotEmpty) {
      primaryPositioning = SubtitlePositioningParser.parsePositioning(
        primarySubtitle!,
        horizontalPadding: horizontalPadding,
        verticalPadding: (isFullscreen ? 40.0 : verticalPadding) + primaryVerticalOffset,
        topPadding: (isFullscreen ? 40.0 : topPadding) + primaryVerticalOffset,
      );
    }
    
    // Add primary subtitle with positioning
    if (primaryPositioning != null && primaryPositioning.cleanText.trim().isNotEmpty) {
      if (primaryPositioning.isMiddlePosition) {
        // Handle middle positions with Align
        subtitleWidgets.add(
          Align(
            alignment: primaryPositioning.alignment,
            child: Padding(
              padding: EdgeInsets.only(
                left: primaryPositioning.left ?? 0,
                right: primaryPositioning.right ?? 0,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: CustomHtmlText(
                  htmlContent: primaryPositioning.cleanText.replaceAll('\n', '<br>'),
                  defaultStyle: primaryStyle,
                  textAlign: primaryPositioning.textAlign,
                  expanded: false,
                  maxLines: null,
                ),
              ),
            ),
          ),
        );
      } else {
        // Handle top and bottom positions with Positioned
        subtitleWidgets.add(
          _buildPositionedSubtitle(
            positioning: primaryPositioning,
            style: primaryStyle,
          ),
        );
      }
    }
    
    // Add secondary subtitle ALWAYS at the top (ignore positioning codes)
    if (secondarySubtitle != null && secondarySubtitle!.trim().isNotEmpty) {
      final cleanSecondaryText = SubtitlePositioningParser.removePositioningCode(secondarySubtitle!);
      subtitleWidgets.add(
        Positioned(
          left: horizontalPadding,
          right: horizontalPadding,
          top: (isFullscreen ? 40.0 : topPadding) + secondaryVerticalOffset,
          child: Material(
            type: MaterialType.transparency,
            child: CustomHtmlText(
              htmlContent: cleanSecondaryText.replaceAll('\n', '<br>'),
              defaultStyle: secondaryStyle,
              textAlign: TextAlign.center,
              expanded: true,
              maxLines: null,
            ),
          ),
        ),
      );
    }
    
    if (subtitleWidgets.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return SizedBox.expand(
      child: Stack(children: subtitleWidgets),
    );
  }
  
  Widget _buildPositionedSubtitle({
    required SubtitlePositioning positioning,
    required TextStyle style,
  }) {
    return Positioned(
      left: positioning.left,
      right: positioning.right,
      top: positioning.top,
      bottom: positioning.bottom,
      child: Material(
        type: MaterialType.transparency,
        child: CustomHtmlText(
          htmlContent: positioning.cleanText.replaceAll('\n', '<br>'),
          defaultStyle: style,
          textAlign: positioning.textAlign,
          expanded: true,
          maxLines: null,
        ),
      ),
    );
  }
}
