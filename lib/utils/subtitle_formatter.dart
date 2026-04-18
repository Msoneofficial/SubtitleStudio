import 'package:subtitle_studio/database/models/models.dart';

/// Subtitle formatter for various subtitle formats
/// 
/// This class provides static methods to format subtitle lines
/// into different subtitle file formats.
class SubtitleFormatter {
  /// Format subtitle lines to SRT format
  static String formatToSRT(List<SubtitleLine> lines) {
    final buffer = StringBuffer();
    
    for (final line in lines) {
      // Use edited text if available, otherwise original
      String text = line.edited?.isNotEmpty == true ? line.edited! : line.original;
      
      // Replace <br> tags with actual line breaks
      text = text.replaceAll('<br>', '\n');
      
      // Write subtitle entry
      buffer.writeln(line.index);
      buffer.writeln('${line.startTime} --> ${line.endTime}');
      buffer.writeln(text);
      buffer.writeln(); // Empty line between entries
    }
    
    return buffer.toString();
  }

  /// Format subtitle lines to WebVTT format
  static String formatToVTT(List<SubtitleLine> lines) {
    final buffer = StringBuffer();
    
    // WebVTT header
    buffer.writeln('WEBVTT');
    buffer.writeln();
    
    for (final line in lines) {
      // Use edited text if available, otherwise original
      String text = line.edited?.isNotEmpty == true ? line.edited! : line.original;
      
      // Replace <br> tags with actual line breaks
      text = text.replaceAll('<br>', '\n');
      
      // WebVTT uses the same time format as SRT
      buffer.writeln('${line.startTime} --> ${line.endTime}');
      buffer.writeln(text);
      buffer.writeln(); // Empty line between entries
    }
    
    return buffer.toString();
  }

  /// Format subtitle lines to Advanced SSA/ASS format
  static String formatToASS(List<SubtitleLine> lines) {
    final buffer = StringBuffer();
    
    // ASS header
    buffer.writeln('[Script Info]');
    buffer.writeln('Title: Exported Subtitle');
    buffer.writeln('ScriptType: v4.00+');
    buffer.writeln();
    buffer.writeln('[V4+ Styles]');
    buffer.writeln('Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');
    buffer.writeln('Style: Default,Arial,20,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,2,0,2,10,10,10,1');
    buffer.writeln();
    buffer.writeln('[Events]');
    buffer.writeln('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');
    
    for (final line in lines) {
      // Use edited text if available, otherwise original
      String text = line.edited?.isNotEmpty == true ? line.edited! : line.original;
      
      // Convert time format from SRT to ASS (h:mm:ss,mmm to h:mm:ss.mm)
      final startTime = _convertTimeToASS(line.startTime);
      final endTime = _convertTimeToASS(line.endTime);
      
      // Replace <br> tags with ASS line break format
      text = text.replaceAll('<br>', '\\N');
      
      // ASS dialogue line
      buffer.writeln('Dialogue: 0,$startTime,$endTime,Default,,0,0,0,,$text');
    }
    
    return buffer.toString();
  }

  /// Format subtitle lines to plain text format
  static String formatToTXT(List<SubtitleLine> lines) {
    final buffer = StringBuffer();
    
    for (final line in lines) {
      // Use edited text if available, otherwise original
      String text = line.edited?.isNotEmpty == true ? line.edited! : line.original;
      
      // Replace <br> tags with actual line breaks
      text = text.replaceAll('<br>', '\n');
      
      // Simple format: [time] text
      buffer.writeln('[${line.startTime} --> ${line.endTime}]');
      buffer.writeln(text);
      buffer.writeln(); // Empty line between entries
    }
    
    return buffer.toString();
  }

  /// Convert time format from SRT (h:mm:ss,mmm) to ASS (h:mm:ss.mm)
  static String _convertTimeToASS(String srtTime) {
    // SRT format: 00:01:23,456
    // ASS format: 0:01:23.45
    
    if (srtTime.contains(',')) {
      final parts = srtTime.split(',');
      final timePart = parts[0];
      final milliseconds = parts[1];
      
      // Take only first 2 digits of milliseconds for ASS format
      final centiseconds = milliseconds.length >= 2 
          ? milliseconds.substring(0, 2)
          : milliseconds.padRight(2, '0');
      
      // Remove leading zero from hours if present
      String formattedTime = timePart;
      if (formattedTime.startsWith('0') && formattedTime.length > 1) {
        formattedTime = formattedTime.substring(1);
      }
      
      return '$formattedTime.$centiseconds';
    }
    
    return srtTime; // Return as-is if format is unexpected
  }
}
