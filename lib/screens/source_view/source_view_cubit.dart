import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subtitle_studio/screens/source_view/source_view_state.dart';
import 'package:subtitle_studio/utils/app_logger.dart';
import 'package:subtitle_studio/utils/saf_file_handler.dart';

/// Cubit for managing the Source View Screen state
/// 
/// This Cubit encapsulates all business logic for the source view screen,
/// following the BLoC pattern for state management. It handles:
/// - File loading with encoding detection
/// - Content editing and change tracking
/// - Save operations with multiple fallback strategies
/// - SAF URI management and persistence
/// - Error handling with user-friendly messages
/// 
/// State Flow:
/// 1. Initial loading state
/// 2. Load file content (SAF or direct file access)
/// 3. Parse SRT content into subtitle entries
/// 4. Handle content changes and track modifications
/// 5. Save with robust fallback strategies
/// 6. Provide appropriate user feedback
class SourceViewCubit extends Cubit<SourceViewState> {
  late File _file;
  
  SourceViewCubit({
    required String filePath,
    String? displayName,
    String? safUri,
    String? fileContent,
  }) : super(SourceViewState.initial(
          filePath: filePath,
          displayName: displayName,
          safUri: safUri,
        )) {
    _file = File(filePath);
    _initialize(fileContent);
  }

  /// Initialize the source view cubit
  Future<void> _initialize(String? preloadedContent) async {
    await AppLogger.instance.info('SourceViewCubit: Initializing for file: ${state.filePath}');
    await _checkForExistingSafUri();
    await _loadFileContent(preloadedContent);
  }

  /// Check shared preferences for existing SAF URI information for this file path
  Future<void> _checkForExistingSafUri() async {
    try {
      await AppLogger.instance.info('Checking shared preferences for existing SAF URI for file: ${state.filePath}');
      
      final prefs = await SharedPreferences.getInstance();
      final key = 'saf_uri_${state.filePath}';
      final storedSafUri = prefs.getString(key);
      
      if (storedSafUri != null) {
        emit(state.copyWith(safUri: storedSafUri));
        await AppLogger.instance.info('Found existing SAF URI in preferences: $storedSafUri');
      } else if (state.safUri != null) {
        await AppLogger.instance.info('Using SAF URI from constructor parameter: ${state.safUri}');
        // Store this SAF URI in preferences for future use
        await _storeSafUriInPreferences();
      }
      
    } catch (e) {
      await AppLogger.instance.error('Error checking for existing SAF URI: $e');
      // Continue with provided SAF URI or null
    }
  }
  
  /// Store the SAF URI information in shared preferences for future access
  Future<void> _storeSafUriInPreferences() async {
    if (state.safUri == null) return;
    
    try {
      await AppLogger.instance.info('Storing SAF URI in shared preferences for future access');
      
      final prefs = await SharedPreferences.getInstance();
      final key = 'saf_uri_${state.filePath}';
      await prefs.setString(key, state.safUri!);
      
      await AppLogger.instance.info('SAF URI stored in preferences for file: ${state.filePath}');
    } catch (e) {
      await AppLogger.instance.error('Error storing SAF URI in preferences: $e');
    }
  }

  /// Load file content from storage with encoding detection
  Future<void> _loadFileContent(String? preloadedContent) async {
    try {
      emit(state.toLoading());

      String content;
      Encoding encoding = utf8;
      
      if (preloadedContent != null) {
        // Use pre-loaded content (from SAF file selection)
        content = preloadedContent;
        encoding = utf8; // Assume UTF-8 for pre-loaded content
        await AppLogger.instance.info('Using preloaded content: ${content.length} chars');
      } else {
        // Read file content - use SAF if available, otherwise direct file access
        List<int> bytes;
        
        if (state.safUri != null && Platform.isAndroid) {
          // For SAF files, try reading using the intent handler method
          try {
            await AppLogger.instance.info('Reading SAF URI content using intent handler: ${state.safUri}');
            
            // Use IntentHandler to read the content URI
            const MethodChannel channel = MethodChannel('org.malayalamsubtitles.studio/intent');
            final Uint8List? fileBytes = await channel.invokeMethod('readFileFromContentUri', {'uri': state.safUri});
            
            if (fileBytes != null && fileBytes.isNotEmpty) {
              bytes = fileBytes;
              await AppLogger.instance.info('Successfully read ${bytes.length} bytes from SAF URI');
            } else {
              // Fallback: try reading from the cached file path if available
              await AppLogger.instance.warning('No content from SAF URI, trying cached file path');
              if (await _file.exists()) {
                bytes = await _file.readAsBytes();
                await AppLogger.instance.info('Fallback: Read ${bytes.length} bytes from cached file');
              } else {
                throw Exception('Unable to read SAF file: no content available and cached file not found');
              }
            }
          } catch (e) {
            await AppLogger.instance.error('Error reading SAF URI: $e');
            // Final fallback: try reading from cached file path
            if (await _file.exists()) {
              bytes = await _file.readAsBytes();
              await AppLogger.instance.info('Final fallback: Read ${bytes.length} bytes from cached file');
            } else {
              throw Exception('Cannot read SAF file: $e. Cached file also not available.');
            }
          }
        } else {
          // Direct file access for non-SAF files
          if (!await _file.exists()) {
            throw Exception('File not found: ${state.filePath}');
          }
          bytes = await _file.readAsBytes();
        }
        
        // Try to detect encoding (simple detection - UTF-8 first, then fallback)
        try {
          content = utf8.decode(bytes);
          encoding = utf8;
        } catch (e) {
          // If UTF-8 fails, try Latin-1 as fallback
          content = latin1.decode(bytes);
          encoding = latin1;
        }
      }
      
      // Parse SRT content into subtitle entries
      await AppLogger.instance.info('Parsing SRT content: ${content.length} chars');
      final entries = _parseSrtContent(content);
      await AppLogger.instance.info('Parsed ${entries.length} subtitle entries');
      
      emit(state.toLoaded(entries: entries, encoding: encoding));
      await AppLogger.instance.info('Loaded source view for file: ${state.filePath}');
      
    } catch (e) {
      emit(state.toError('Failed to load file: $e'));
      await AppLogger.instance.error(
        'Error loading file in source view: $e',
        context: 'SourceViewCubit._loadFileContent',
        extra: {'filePath': state.filePath, 'safUri': state.safUri},
      );
    }
  }

  /// Parse SRT content into a list of subtitle entries
  List<SubtitleEntry> _parseSrtContent(String content) {
    final entries = <SubtitleEntry>[];
    final blocks = content.trim().split(RegExp(r'\n\s*\n'));
    
    AppLogger.instance.info('Parsing SRT: ${blocks.length} blocks found');
    
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      
      final entry = SubtitleEntry.fromSrtText(block);
      if (entry != null) {
        entries.add(entry);
      } else {
        AppLogger.instance.warning('Failed to parse block $i');
      }
    }
    
    AppLogger.instance.info('Parsing completed: ${entries.length}/${blocks.length} entries parsed');
    return entries;
  }

  /// Handle content changes by updating a specific subtitle entry
  void updateSubtitleEntry(int index, SubtitleEntry updatedEntry) {
    if (index < 0 || index >= state.subtitleEntries.length) {
      AppLogger.instance.warning('Invalid subtitle entry index: $index');
      return;
    }

    // Check if the content actually changed to prevent unnecessary updates
    final currentEntry = state.subtitleEntries[index];
    if (currentEntry == updatedEntry) {
      return; // No change, skip update
    }

    final updatedEntries = List<SubtitleEntry>.from(state.subtitleEntries);
    updatedEntries[index] = updatedEntry;
    
    emit(state.toContentChanged(entries: updatedEntries));
  }

  /// Handle changes to subtitle entry index
  void updateSubtitleIndex(int entryIndex, String newIndex) {
    final currentEntry = state.subtitleEntries[entryIndex];
    final updatedEntry = currentEntry.copyWith(index: newIndex);
    updateSubtitleEntry(entryIndex, updatedEntry);
  }

  /// Handle changes to subtitle entry start time
  void updateSubtitleStartTime(int entryIndex, String newStartTime) {
    final currentEntry = state.subtitleEntries[entryIndex];
    final updatedEntry = currentEntry.copyWith(startTime: newStartTime);
    updateSubtitleEntry(entryIndex, updatedEntry);
  }

  /// Handle changes to subtitle entry end time
  void updateSubtitleEndTime(int entryIndex, String newEndTime) {
    final currentEntry = state.subtitleEntries[entryIndex];
    final updatedEntry = currentEntry.copyWith(endTime: newEndTime);
    updateSubtitleEntry(entryIndex, updatedEntry);
  }

  /// Handle changes to subtitle entry text
  void updateSubtitleText(int entryIndex, String newText) {
    final currentEntry = state.subtitleEntries[entryIndex];
    final updatedEntry = currentEntry.copyWith(text: newText);
    updateSubtitleEntry(entryIndex, updatedEntry);
  }

  /// Simple method to mark content as changed (for performance optimization)
  /// Used by direct object mutation approach like EditScreen
  void markContentChanged() {
    // Simply emit the current state with hasUnsavedChanges = true
    // This is much more performant than complex BLoC updates
    if (!state.hasUnsavedChanges) {
      emit(state.toContentChanged(entries: state.subtitleEntries));
    }
  }

  /// Reload file content
  Future<void> reloadFile() async {
    await _loadFileContent(null);
  }

  /// Save current file content back to storage with original encoding
  Future<void> saveFile() async {
    try {
      emit(state.toSaving());
      
      final content = state.toSrtContent();
      
      // Encode using the detected encoding
      final bytes = state.fileEncoding.encode(content);
      
      await AppLogger.instance.info('=== SOURCE VIEW SAVE DEBUG ===');
      await AppLogger.instance.info('Content length: ${content.length} chars');
      await AppLogger.instance.info('Encoded bytes length: ${bytes.length}');
      await AppLogger.instance.info('SAF URI: ${state.safUri}');
      await AppLogger.instance.info('File path: ${state.filePath}');
      await AppLogger.instance.info('File exists: ${await _file.exists()}');
      
      bool saveSuccessful = false;
      String saveMethod = '';
      
      // Strategy 1: Try SAF URI if available
      if (state.safUri != null && state.safUri!.isNotEmpty) {
        await AppLogger.instance.info('Attempting Strategy 1: SAF URI save');
        try {
          // Check if we have persistent permissions (informational only)
          final hasPermission = await SafFileHandler.hasUriPermission(uri: state.safUri!);
          await AppLogger.instance.info('URI persistent permission check: $hasPermission');
          
          // ALWAYS try to write to the original URI
          await AppLogger.instance.info('Attempting write to original SAF URI');
          final success = await SafFileHandler.writeSafUri(state.safUri!, Uint8List.fromList(bytes));
          if (success) {
            saveSuccessful = true;
            saveMethod = 'SAF URI (original file)';
            await AppLogger.instance.info('Strategy 1 SUCCESS: Saved to original SAF URI');
          } else {
            await AppLogger.instance.warning('Strategy 1 FAILED: writeSafUri returned false');
          }
        } catch (e) {
          await AppLogger.instance.error('Strategy 1 ERROR: $e');
        }
      } else {
        await AppLogger.instance.info('Strategy 1 SKIPPED: No SAF URI available');
      }
      
      // Strategy 2: Try direct file write if SAF failed
      if (!saveSuccessful) {
        await AppLogger.instance.info('Attempting Strategy 2: Direct file write');
        try {
          if (await _file.exists()) {
            await _file.writeAsBytes(bytes);
            saveSuccessful = true;
            saveMethod = 'Direct file';
            await AppLogger.instance.info('Strategy 2 SUCCESS: Saved to direct file path');
          } else {
            await AppLogger.instance.warning('Strategy 2 FAILED: File does not exist at path');
          }
        } catch (e) {
          await AppLogger.instance.error('Strategy 2 ERROR: $e');
        }
      }
      
      // Handle save results
      if (saveSuccessful) {
        String successMessage;
        if (saveMethod == 'SAF URI (original file)') {
          successMessage = 'File saved to original location ✓';
        } else if (saveMethod == 'Direct file' && state.safUri != null) {
          successMessage = 'File saved to app cache (original location unavailable)';
        } else {
          successMessage = 'File saved successfully';
        }
        
        emit(state.toSaveSuccess(successMessage));
        await AppLogger.instance.info('=== SAVE COMPLETED SUCCESSFULLY ===');
      } else {
        await AppLogger.instance.warning('All save strategies failed');
        emit(state.toSaveError('Unable to save file. All save strategies failed.'));
      }
      
    } catch (e) {
      emit(state.toSaveError('Failed to save file: $e'));
      await AppLogger.instance.error(
        'Error saving file in source view: $e',
        context: 'SourceViewCubit.saveFile',
        extra: {'filePath': state.filePath, 'safUri': state.safUri},
      );
    }
  }

  /// Save file to a new location using SAF
  Future<void> saveAsFile() async {
    try {
      emit(state.toSaving());
      
      // Get the current file name as a default
      final currentFileName = state.filePath.split('/').last;
      
      // Ensure the file has .srt extension and proper name
      String fileName;
      if (currentFileName.toLowerCase().endsWith('.srt')) {
        fileName = currentFileName;
      } else {
        // Remove any existing extension and add .srt
        final nameWithoutExt = currentFileName.replaceAll(RegExp(r'\.[^.]*$'), '');
        fileName = '$nameWithoutExt.srt';
      }
      
      await AppLogger.instance.info('Save As filename: $fileName');
      
      // Use SAF to create a new document
      final safInfo = await SafFileHandler.createDocument(
        fileName: fileName,
        mimeType: '*/*',
      );
      
      if (safInfo == null) {
        // User cancelled the save dialog
        await AppLogger.instance.info('Save As cancelled by user');
        emit(state.copyWith(isSaving: false));
        return;
      }
      
      await AppLogger.instance.info('Save As location: ${safInfo.displayPath}');
      
      final content = state.toSrtContent();
      
      if (content.isEmpty) {
        emit(state.toSaveError('No content to save. The file appears to be empty.'));
        await AppLogger.instance.warning('Save As aborted: no content available');
        return;
      }
      
      // Always use UTF-8 encoding for new files
      final encoder = utf8;
      final bytes = encoder.encode(content);
      await AppLogger.instance.info('Save As encoded bytes length: ${bytes.length}');
      
      // Save to the new location
      final writeResult = await SafFileHandler.writeSafUri(safInfo.uri, Uint8List.fromList(bytes));
      
      if (writeResult) {
        await AppLogger.instance.info('Save As successful to: ${safInfo.displayPath}');
        emit(state.toSaveSuccess('File saved to: ${safInfo.displayPath}'));
      } else {
        emit(state.toSaveError('Failed to write file content'));
      }
      
    } catch (e) {
      emit(state.toSaveError('Failed to save file as: $e'));
      await AppLogger.instance.error(
        'Error saving file as in source view: $e',
        context: 'SourceViewCubit.saveAsFile',
        extra: {'filePath': state.filePath},
      );
    }
  }

  /// Clear any error or save messages
  void clearMessages() {
    emit(state.copyWith(
      errorMessage: null,
      saveMessage: null,
    ));
  }
}