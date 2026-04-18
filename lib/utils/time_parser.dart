Duration parseTimeString(String time) {
  // Normalize input and handle different separators
  final normalized = time.trim().replaceAll('.', ',').replaceAll(';', ',');
  final parts = normalized.split(RegExp(r'[,]'));
  
  // Parse time components
  final timeComponents = parts[0].split(':').map(int.parse).toList();
  
  // Parse milliseconds (support 1-3 digits)
  int milliseconds = 0;
  if (parts.length > 1) {
    final millisStr = parts[1].padRight(3, '0').substring(0, 3);
    milliseconds = int.parse(millisStr);
  }

  // Handle different time formats
  switch (timeComponents.length) {
    case 3: // HH:mm:ss
      return Duration(
        hours: timeComponents[0],
        minutes: timeComponents[1],
        seconds: timeComponents[2],
        milliseconds: milliseconds,
      );
    
    case 2: // mm:ss
      return Duration(
        minutes: timeComponents[0],
        seconds: timeComponents[1],
        milliseconds: milliseconds,
      );
    
    case 1: // ss
      return Duration(
        seconds: timeComponents[0],
        milliseconds: milliseconds,
      );
    
    default:
      throw FormatException('Invalid time format: $time');
  }
}
