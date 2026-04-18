import 'package:flutter/material.dart';

/// Subtitle Positioning Parser
/// 
/// This utility class parses ASS/SSA positioning codes and provides
/// Flutter-compatible positioning information for subtitle rendering.
/// 
/// Supported positioning codes:
/// {\an1} - Bottom Left
/// {\an2} - Bottom Center (default)  
/// {\an3} - Bottom Right
/// {\an4} - Middle Left
/// {\an5} - Middle Center
/// {\an6} - Middle Right
/// {\an7} - Top Left
/// {\an8} - Top Center
/// {\an9} - Top Right

class SubtitlePositioning {
  final AlignmentGeometry alignment;
  final double? left;
  final double? right; 
  final double? top;
  final double? bottom;
  final TextAlign textAlign;
  final String cleanText;
  final bool isMiddlePosition; // Add flag to identify middle positions

  const SubtitlePositioning({
    required this.alignment,
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.textAlign,
    required this.cleanText,
    this.isMiddlePosition = false,
  });
}

class SubtitlePositioningParser {
  
  /// Parse positioning code from subtitle text and return positioning information
  static SubtitlePositioning parsePositioning(String subtitleText, {
    double horizontalPadding = 30.0,
    double verticalPadding = 50.0,
    double topPadding = 30.0,
  }) {
    // Extract positioning code using regex
    final RegExp positionRegex = RegExp(r'^\{\\an([1-9])\}');
    final match = positionRegex.firstMatch(subtitleText);
    
    // Remove positioning code from text
    final cleanText = subtitleText.replaceFirst(positionRegex, '');
    
    // Default to bottom center if no positioning code found
    final positionCode = match != null ? int.parse(match.group(1)!) : 2;
    
    return getPositionFromCode(positionCode, cleanText, horizontalPadding, verticalPadding, topPadding);
  }
  
  /// Convert position code to Flutter positioning
  static SubtitlePositioning getPositionFromCode(
    int code, 
    String cleanText,
    double horizontalPadding,
    double verticalPadding,
    double topPadding,
  ) {
    switch (code) {
      case 1: // Bottom Left
        return SubtitlePositioning(
          alignment: Alignment.bottomLeft,
          left: horizontalPadding,
          bottom: verticalPadding,
          textAlign: TextAlign.left,
          cleanText: cleanText,
        );
        
      case 2: // Bottom Center (default)
        return SubtitlePositioning(
          alignment: Alignment.bottomCenter,
          left: horizontalPadding,
          right: horizontalPadding,
          bottom: verticalPadding,
          textAlign: TextAlign.center,
          cleanText: cleanText,
        );
        
      case 3: // Bottom Right
        return SubtitlePositioning(
          alignment: Alignment.bottomRight,
          right: horizontalPadding,
          bottom: verticalPadding,
          textAlign: TextAlign.right,
          cleanText: cleanText,
        );
        
      case 4: // Middle Left
        return SubtitlePositioning(
          alignment: Alignment.centerLeft,
          left: horizontalPadding,
          textAlign: TextAlign.left,
          cleanText: cleanText,
          isMiddlePosition: true,
        );
        
      case 5: // Middle Center
        return SubtitlePositioning(
          alignment: Alignment.center,
          left: horizontalPadding,
          right: horizontalPadding,
          textAlign: TextAlign.center,
          cleanText: cleanText,
          isMiddlePosition: true,
        );
        
      case 6: // Middle Right
        return SubtitlePositioning(
          alignment: Alignment.centerRight,
          right: horizontalPadding,
          textAlign: TextAlign.right,
          cleanText: cleanText,
          isMiddlePosition: true,
        );
        
      case 7: // Top Left
        return SubtitlePositioning(
          alignment: Alignment.topLeft,
          left: horizontalPadding,
          top: topPadding,
          textAlign: TextAlign.left,
          cleanText: cleanText,
        );
        
      case 8: // Top Center
        return SubtitlePositioning(
          alignment: Alignment.topCenter,
          left: horizontalPadding,
          right: horizontalPadding,
          top: topPadding,
          textAlign: TextAlign.center,
          cleanText: cleanText,
        );
        
      case 9: // Top Right
        return SubtitlePositioning(
          alignment: Alignment.topRight,
          right: horizontalPadding,
          top: topPadding,
          textAlign: TextAlign.right,
          cleanText: cleanText,
        );
        
      default: // Fallback to bottom center
        return SubtitlePositioning(
          alignment: Alignment.bottomCenter,
          left: horizontalPadding,
          right: horizontalPadding,
          bottom: verticalPadding,
          textAlign: TextAlign.center,
          cleanText: cleanText,
        );
    }
  }
  
  /// Get available positioning options for UI display
  static Map<int, String> getPositioningOptions() {
    return {
      1: 'Bottom Left',
      2: 'Bottom Center',
      3: 'Bottom Right',
      4: 'Middle Left', 
      5: 'Middle Center',
      6: 'Middle Right',
      7: 'Top Left',
      8: 'Top Center',
      9: 'Top Right',
    };
  }
  
  /// Check if text contains a positioning code
  static bool hasPositioningCode(String text) {
    final RegExp positionRegex = RegExp(r'^\{\\an[1-9]\}');
    return positionRegex.hasMatch(text);
  }
  
  /// Extract just the positioning code number from text
  static int? getPositionCode(String text) {
    final RegExp positionRegex = RegExp(r'^\{\\an([1-9])\}');
    final match = positionRegex.firstMatch(text);
    return match != null ? int.parse(match.group(1)!) : null;
  }
  
  /// Remove positioning code from text
  static String removePositioningCode(String text) {
    final RegExp positionRegex = RegExp(r'^\{\\an[1-9]\}');
    return text.replaceFirst(positionRegex, '');
  }
}
