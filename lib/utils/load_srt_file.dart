import 'package:flutter/material.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:subtitle_studio/utils/intent_handler.dart';
import 'dart:io';

Future<Map?> pickSRT(BuildContext context) async {
  // Use the new platform-specific file picker with both display path and SAF URI
  final fileInfo = await FilePickerConvenience.pickSubtitleFileWithInfo(context: context);
  
  if (fileInfo != null) {
    final displayPath = fileInfo['displayPath']!;
    final safUri = fileInfo['safUri'];
    final content = fileInfo['content']; // Get the already-read content
    
    // Extract filename from the best available source
    String fileName;
    if (safUri != null && safUri.isNotEmpty) {
      // For SAF URIs, use the IntentHandler to get proper filename
      fileName = IntentHandler.getFileName(safUri);
    } else {
      // For regular paths, extract filename from path
      fileName = displayPath.split(Platform.pathSeparator).last;
    }
    
    // Ensure the filename has the correct extension
    if (!fileName.toLowerCase().endsWith('.srt') && 
        !fileName.toLowerCase().endsWith('.vtt') &&
        !fileName.toLowerCase().endsWith('.ass') &&
        !fileName.toLowerCase().endsWith('.ssa')) {
      fileName += '.srt'; // Default to .srt if no extension
    }
    
    return {
      'filePath': displayPath,
      'fileName': fileName,
      'safUri': safUri, // Include SAF URI for proper file operations
      'content': content, // Include the already-read content to avoid double reading
    };
  }
  return null;
}



