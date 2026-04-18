import 'package:flutter/material.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
// Removed platform_check - using pure SAF implementation without permission checks
import 'package:subtitle_studio/utils/ffmpeg_helper.dart';
import 'package:subtitle_studio/utils/subtitle_processor.dart';
import 'package:subtitle_studio/widgets/subtitle_tracks_sheet.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/widgets/loading_overlay.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/app_logger.dart';
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'package:subtitle_studio/database/database_helper.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
// Removed permission_handler - not needed with pure SAF implementation
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:convert';

// Global key for accessing navigator state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SubtitleExtractOptionsSheet extends StatefulWidget {
  final Function(Session) onSubtitleExtracted;

  const SubtitleExtractOptionsSheet({
    super.key,
    required this.onSubtitleExtracted,
  });

  @override
  State<SubtitleExtractOptionsSheet> createState() =>
      _SubtitleExtractOptionsSheetState();
}

class _SubtitleExtractOptionsSheetState
    extends State<SubtitleExtractOptionsSheet> {
  bool _removeHearingImpairedLines = false;
  bool _mergeOverlappingSubtitles = false;
  bool _isLoading = false;
  String? _selectedVideoPath;
  String _fileName = '';
  List<Map<String, dynamic>> _subtitleTracks = [];
  String? _currentSafUri; // Store SAF URI for current extraction

  // Save root context for operations that need to outlive this widget
  late BuildContext _rootContext;

  @override
  void initState() {
    super.initState();
    AppLogger.instance.info(
      'SubtitleExtractOptionsSheet initialized',
      context: 'SubtitleExtractOptionsSheet.initState',
    );
    // We'll capture the navigator context in didChangeDependencies instead
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the Navigator's context which should remain valid
    _rootContext = Navigator.of(context).context;
  }

  /// SAF-based video file selection - no permissions needed
  Future<void> _selectVideoFile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use SAF-based file picker - no permissions needed
      final videoFileInfo = await FilePickerConvenience.pickVideoFileWithInfo(
        context: context,
      );

      if (videoFileInfo != null) {
        final videoPath = videoFileInfo['uri'] ?? videoFileInfo['displayPath']!;
        String fileName = videoFileInfo['displayName'] ?? '';
        
        // Fallback filename extraction if displayName is empty
        if (fileName.isEmpty) {
          final displayPath = videoFileInfo['displayPath'];
          if (displayPath != null && displayPath.isNotEmpty) {
            // Handle both forward slashes and backslashes for cross-platform compatibility
            final backslashIndex = displayPath.lastIndexOf('\\');
            final forwardSlashIndex = displayPath.lastIndexOf('/');
            
            // Use the last occurring separator
            final lastSeparatorIndex = backslashIndex > forwardSlashIndex ? backslashIndex : forwardSlashIndex;
            
            if (lastSeparatorIndex >= 0) {
              fileName = displayPath.substring(lastSeparatorIndex + 1);
            } else {
              fileName = displayPath; // No separators found, use whole path
            }
          } else {
            fileName = 'Selected Video';
          }
        }
        
        // For Android content URIs, clean up the filename if it's still encoded
        if (Platform.isAndroid && videoPath.startsWith('content://') && fileName.contains('%')) {
          try {
            fileName = Uri.decodeFull(fileName);
          } catch (e) {
            if (kDebugMode) {
              print('Could not decode filename: $e');
            }
            // Keep the original filename if decoding fails
          }
        }

        // Get subtitle tracks
        final ffmpegHelper = FFmpegHelper();
        final allSubtitleTracks = await ffmpegHelper.getSubtitleTracks(videoPath);
        
        // Filter to only include text-based subtitle formats (exclude bitmap formats like PGS, DVB, etc.)
        final List<String> textBasedCodecs = [
          'subrip', 'srt',           // SubRip (.srt)
          'ass', 'ssa',              // Advanced SubStation Alpha (.ass, .ssa)
          'webvtt', 'vtt',           // WebVTT (.vtt)
          'mov_text',                // QuickTime text
          'text', 'txt',             // Plain text
          'microdvd',                // MicroDVD
          'subviewer', 'subviewer1', // SubViewer
          'mpl2',                    // MPL2
          'dvbsub',                  // DVB Subtitle (text variant)
          'ttml',                    // Timed Text Markup Language
          'stl',                     // Spruce subtitle format
        ];
        
        final subtitleTracks = allSubtitleTracks.where((track) {
          final codec = (track['codec'] as String?)?.toLowerCase() ?? '';
          return textBasedCodecs.contains(codec);
        }).toList();

        if (!mounted) return;

        setState(() {
          _selectedVideoPath = videoPath;
          _fileName = fileName;
          _subtitleTracks = subtitleTracks;
          _isLoading = false;
        });

        // Show message if no text-based subtitle tracks found
        if (subtitleTracks.isEmpty && mounted) {
          if (allSubtitleTracks.isEmpty) {
            await AppLogger.instance.warning(
              'No subtitle tracks found in video file: $_selectedVideoPath',
              context: 'SubtitleExtractOptionsSheet._selectVideoFile',
            );
            SnackbarHelper.showWarning(
              context,
              'No subtitle tracks found in this video file',
              duration: const Duration(seconds: 3),
            );
          } else {
            // Found subtitle tracks but they're all bitmap format
            await AppLogger.instance.warning(
              'Found ${allSubtitleTracks.length} subtitle track(s) but they are bitmap format (not extractable): $_selectedVideoPath',
              context: 'SubtitleExtractOptionsSheet._selectVideoFile',
            );
            SnackbarHelper.showWarning(
              context,
              'This video contains ${allSubtitleTracks.length} subtitle track(s) in bitmap format (e.g., PGS) which cannot be extracted as text. Please use a separate subtitle file.',
              duration: const Duration(seconds: 4),
            );
          }
        }
      } else {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      await AppLogger.instance.error(
        'Error selecting video: $e',
        context: 'SubtitleExtractOptionsSheet._selectVideoFile',
      );
      if (!mounted) return;

      SnackbarHelper.showError(context, 'Error selecting video: $e');

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _viewSubtitleTracks() async {
    if (_subtitleTracks.isEmpty) {
      await AppLogger.instance.warning(
        'No subtitle tracks available to view',
        context: 'SubtitleExtractOptionsSheet._viewSubtitleTracks',
      );
      SnackbarHelper.showWarning(
        context,
        'No subtitle tracks found in this video file',
      );
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SubtitleTracksSheet(
            subtitleTracks: _subtitleTracks,
            onTrackSelected: (track) => _extractSubtitle(track),
          ),
    );
  }

  Future<void> _extractSubtitle(Map<String, dynamic> track) async {
    if (_selectedVideoPath == null) {
      await AppLogger.instance.warning(
        'No video file selected for subtitle extraction',
        context: 'SubtitleExtractOptionsSheet._extractSubtitle',
      );
      if (!mounted) return;

      SnackbarHelper.showError(context, 'Please select a video file first');
      return;
    }

    try {
      // Clear any previous SAF URI
      _currentSafUri = null;

      if (kDebugMode) {
        print('Starting subtitle extraction for track: ${track['title']}');
        print('Selected video path: $_selectedVideoPath');
      }

      // Close the tracks sheet if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        if (kDebugMode) {
          print('Closed tracks sheet');
        }
      }

      // Get a reference to the root context
      final BuildContext rootContext = _rootContext;

      // Select output directory
      if (!mounted) return;

      // Generate suggested filename
      String suggestedFileName = '';
      if (_fileName.isNotEmpty) {
        // Decode URL encoding and extract clean filename
        String cleanVideoFileName = _fileName;
        try {
          // Decode URL-encoded characters
          cleanVideoFileName = Uri.decodeFull(_fileName);

          // Extract just the filename from path-like structures
          if (cleanVideoFileName.contains('/') || cleanVideoFileName.contains('\\')) {
            // Handle both forward slashes and backslashes for cross-platform compatibility
            final backslashIndex = cleanVideoFileName.lastIndexOf('\\');
            final forwardSlashIndex = cleanVideoFileName.lastIndexOf('/');
            
            // Use the last occurring separator
            final lastSeparatorIndex = backslashIndex > forwardSlashIndex ? backslashIndex : forwardSlashIndex;
            
            if (lastSeparatorIndex >= 0) {
              cleanVideoFileName = cleanVideoFileName.substring(lastSeparatorIndex + 1);
            }
          }
          if (cleanVideoFileName.contains(':')) {
            cleanVideoFileName = cleanVideoFileName.split(':').last;
          }

          // Remove only the actual video file extension (preserve dots in filename)
          final commonVideoExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp', '.ogv'];
          for (final ext in commonVideoExtensions) {
            if (cleanVideoFileName.toLowerCase().endsWith(ext)) {
              cleanVideoFileName = cleanVideoFileName.substring(0, cleanVideoFileName.length - ext.length);
              break;
            }
          }

          // Remove any remaining invalid filename characters
          cleanVideoFileName = cleanVideoFileName.replaceAll(
            RegExp(r'[<>:"/\\|?*]'),
            '_',
          );

          if (kDebugMode) {
            print('Original filename: $_fileName');
            print('Cleaned filename: $cleanVideoFileName');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error cleaning filename, using fallback: $e');
          }
          cleanVideoFileName = 'video';
        }

        // Generate a better filename with language code or track number before extension
        String trackIdentifier;
        final language = track['language'] as String?;
        final trackIndex = track['subtitle_index'] as int?;
        
        // Use language code if available and not "und" (undefined), otherwise use track number
        if (language != null && language.isNotEmpty && language != 'und') {
          trackIdentifier = language;
        } else {
          trackIdentifier = 'track${trackIndex ?? 0}';
        }
        
        // Insert track identifier before the file extension with dot notation
        suggestedFileName = '$cleanVideoFileName.$trackIdentifier.srt';
      } else {
        // Fallback for cases where video filename is not available
        final language = track['language'] as String?;
        final trackIndex = track['subtitle_index'] as int?;
        
        String trackIdentifier;
        if (language != null && language.isNotEmpty && language != 'und') {
          trackIdentifier = language;
        } else {
          trackIdentifier = 'track${trackIndex ?? 0}';
        }
        
        suggestedFileName = 'subtitle.$trackIdentifier.srt';
      }

      if (kDebugMode) {
        print(
          'Opening save dialog with suggested filename: $suggestedFileName',
        );
      }

      // Use platform-specific file save approach
      String? outputFilePath;
      bool useDirectSave = false;

      if (Platform.isAndroid) {
        // On Android, we'll extract to temp and then use SAF save
        // For now, get the suggested filename to use later
        outputFilePath = suggestedFileName; // Just store the filename for later
        useDirectSave = true;
      } else if (Platform.isIOS) {
        // On iOS, skip the folder picker and go directly to file picker during extraction
        // Just set a placeholder path - the actual saving will be handled in _performExtraction
        outputFilePath = suggestedFileName;
        useDirectSave = true;
      } else {
        // On desktop, use folder picker and construct path
        final outputDir = await FilePickerConvenience.pickExportFolder(
          context: context,
        );
        if (outputDir != null) {
          // Use path.join for proper path construction and then normalize
          outputFilePath = FFmpegHelper.normalizePath(path.join(outputDir, suggestedFileName));
        }
      }

      if (kDebugMode) {
        print('Save dialog result: ${outputFilePath ?? "canceled"}');
      }

      if (outputFilePath == null) {
        if (kDebugMode) {
          print('File save canceled');
        }
        return;
      }

      // Close the options sheet before starting extraction
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show extraction started message using snackbar instead of blocking overlay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (rootContext.mounted) {
            SnackbarHelper.showInfo(
              rootContext,
              'Extracting subtitle... This may take a minute.',
              duration: const Duration(seconds: 4),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error showing extraction started message: $e');
          }
        }
      });

      // Launch extraction in a separate isolate or at least separate future
      // Since outputFilePath is checked for null above, we can safely use it
      await Future.microtask(
        () => _performExtraction(
          videoPath: _selectedVideoPath!,
          outputFilePath: outputFilePath!, // Use ! since we checked null above
          useDirectSave: useDirectSave,
          subtitleIndex: track['subtitle_index'],
          removeHI: _removeHearingImpairedLines,
          mergeOverlapping: _mergeOverlappingSubtitles,
          track: track,
          rootContext: rootContext,
          callback: widget.onSubtitleExtracted,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting subtitle: $e');
        if (e is Exception) {
          print('Exception details: ${e.toString()}');
        }
      }

      // Try to show error on the root context if available
      try {
        final message = 'Error extracting subtitle: $e';

        await AppLogger.instance.error(
          message,
          context: 'SubtitleExtractOptionsSheet._extractSubtitle',
        );
        if (_rootContext.mounted) {
          SnackbarHelper.showError(
            _rootContext,
            message,
            duration: const Duration(seconds: 5),
          );
        }
      } catch (_) {
        // If even this fails, we can't show errors to the user
        if (kDebugMode) {
          print('Could not show error message to user');
        }
      }
    }
  }

  // Separate method to handle extraction that can continue even if widget unmounts
  Future<void> _performExtraction({
    required String videoPath,
    required String outputFilePath,
    required bool useDirectSave,
    required int subtitleIndex,
    required bool removeHI,
    required bool mergeOverlapping,
    required Map<String, dynamic> track,
    required BuildContext rootContext,
    required Function(Session) callback,
  }) async {
    Session? extractedSession;

    try {
      // Handle directory and filename based on save method and platform
      String outputDir;
      String outputFileName;

      if (useDirectSave && Platform.isAndroid) {
        // For SAF, outputFilePath is just the filename, create a temp directory
        outputFileName = outputFilePath;
        try {
          final tempDir = await getTemporaryDirectory();
          outputDir = tempDir.path;
        } catch (e) {
          if (kDebugMode) {
            print('Error getting temp directory, using fallback: $e');
          }
          outputDir = '/data/data/org.msone.subeditor/cache';
        }
      } else if (Platform.isIOS) {
        // For iOS, use temp directory for extraction, then use file picker for final save
        outputFileName = path.basename(outputFilePath);
        try {
          final tempDir = await getTemporaryDirectory();
          outputDir = tempDir.path;
        } catch (e) {
          if (kDebugMode) {
            print('Error getting iOS temp directory, using fallback: $e');
          }
          final appDocsDir = await getApplicationDocumentsDirectory();
          outputDir = appDocsDir.path;
        }
      } else {
        // For desktop, use temp directory for extraction, then copy to final location
        outputFileName = path.basename(outputFilePath);
        try {
          final tempDir = await getTemporaryDirectory();
          outputDir = tempDir.path;
          if (kDebugMode) {
            print('Using temp directory for desktop extraction: $outputDir');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting temp directory, using system temp: $e');
          }
          // Fallback to system temp directory
          outputDir = Directory.systemTemp.path;
        }
      }

      if (kDebugMode) {
        print('Starting extraction in separate method');
        print('Use direct save: $useDirectSave');
        print('Selected output file: $outputFilePath');
        print('Output directory: $outputDir');
        print('Output filename: $outputFileName');
        print('Checking directory access...');
      }

      // SAF implementation doesn't require storage permissions
      // All file operations are handled through user-selected content URIs
      
      // Directory permission checking (skip detailed checks for SAF and iOS)
      if (!useDirectSave || (!Platform.isAndroid && !Platform.isIOS)) {
        try {
          // Check if directory exists first
          final outputDirObj = Directory(outputDir);
          final dirExists = await outputDirObj.exists();

          if (kDebugMode) {
            print('Directory exists: $dirExists');
          }

          if (!dirExists) {
            try {
              await outputDirObj.create(recursive: true);
              if (kDebugMode) {
                print('Created output directory: $outputDir');
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error creating directory: $e');
              }
              throw Exception('Cannot create directory: $e');
            }
          }

          // Generate a unique temporary filename
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final testFileName = '$outputDir/test_write_$timestamp.tmp';

          if (kDebugMode) {
            print('Testing write permissions with file: $testFileName');
          }

          // Try to create a test file to verify write permissions
          final testFile = File(testFileName);
          await testFile.writeAsString('test');

          // Verify the file was created
          final testFileExists = await testFile.exists();
          if (kDebugMode) {
            print('Test file created successfully: $testFileExists');
          }

          // Clean up the test file
          if (testFileExists) {
            await testFile.delete();
            if (kDebugMode) {
              print('Test file deleted');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Directory permission check failed: $e');
            print('This may be due to Android storage permissions');
          }

          // Try to hide loading overlay and show an error
          try {
            await AppLogger.instance.warning(
              'Cannot write to selected directory',
              context: 'SubtitleExtractOptionsSheet._extractSubtitleWithAsync',
            );
            if (rootContext.mounted) {
              LoadingOverlay.hide(rootContext);

              SnackbarHelper.showError(
                rootContext,
                'Cannot write to selected directory. Please select a different location.',
                duration: const Duration(seconds: 5),
              );
            }
          } catch (_) {
            // If this fails, we can't show errors to the user
          }

          return; // Return instead of throwing to allow user to try again
        }
      } else {
        // For SAF, ensure cache directory exists
        try {
          final cacheDir = Directory(outputDir);
          if (!await cacheDir.exists()) {
            await cacheDir.create(recursive: true);
            if (kDebugMode) {
              print('Created cache directory for SAF temp files: $outputDir');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error creating cache directory: $e');
          }
          // Use a fallback temp directory
          outputDir = '/tmp';
        }
      }

      // For desktop, check if file will already exist and ask for confirmation BEFORE extraction
      if (!useDirectSave || (!Platform.isAndroid && !Platform.isIOS)) {
        // On desktop, outputFilePath contains the full path to the final destination file
        final destinationFile = File(FFmpegHelper.normalizePath(outputFilePath));
        
        if (kDebugMode) {
          print('Checking if destination file exists: ${destinationFile.path}');
          print('File exists: ${await destinationFile.exists()}');
        }
        
        // Check if file already exists and ask for confirmation
        if (await destinationFile.exists()) {
          // Hide loading overlay before showing dialog
          try {
            if (rootContext.mounted) {
              LoadingOverlay.hide(rootContext);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error hiding loading overlay: $e');
            }
          }
          
          // Show confirmation dialog
          final shouldReplace = await showDialog<bool>(
            context: rootContext,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('File Already Exists'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('A file with this name already exists at the selected location:'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        path.basename(destinationFile.path),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Do you want to replace it?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Replace'),
                  ),
                ],
              );
            },
          );
          
          // If user cancels, exit the extraction process
          if (shouldReplace != true) {
            try {
              if (rootContext.mounted) {
                SnackbarHelper.showInfo(
                  rootContext,
                  'Subtitle extraction cancelled by user',
                  duration: const Duration(seconds: 3),
                );
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error showing cancellation message: $e');
              }
            }
            return; // Exit the method early
          }
          
          // Restore loading overlay after user confirms
          try {
            if (rootContext.mounted) {
              LoadingOverlay.show(
                rootContext,
                message: 'Extracting subtitle...',
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error showing loading overlay: $e');
            }
          }
        }
      }

      // Extract subtitle with a timeout to prevent hanging
      if (kDebugMode) {
        print('Extracting subtitle with FFmpegHelper...');
        print('Video path: $videoPath');
        print('Output directory: $outputDir');
        print('Subtitle index: $subtitleIndex');
      }

      // Fix: Declare outputFile as non-nullable with proper initialization
      late String tempOutputFile;
      try {
        final ffmpegHelper = FFmpegHelper();
        // Extract to directory first, then move to final location
        tempOutputFile = await ffmpegHelper.extractSubtitleWithTrackInfo(
          videoPath,
          outputDir,
          subtitleIndex,
          track, // Pass the full track information
        );

        if (kDebugMode) {
          print('FFmpeg extracted to temp file: $tempOutputFile');
          final tempFileObj = File(tempOutputFile);
          final tempExists = await tempFileObj.exists();
          print('Temp file exists after extraction: $tempExists');
          if (tempExists) {
            final tempSize = await tempFileObj.length();
            print('Temp file size immediately after extraction: $tempSize bytes');
          }
          if (Platform.isIOS) {
            print('iOS: Temp file created at: $tempOutputFile');
          }
        }

        // Update loading message
        try {
          if (rootContext.mounted) {
            LoadingOverlay.hide(rootContext);
            LoadingOverlay.show(
              rootContext,
              message: 'Moving file to selected location...',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error updating loading message: $e');
          }
        }

        // Handle file saving based on platform
        String finalOutputPath;
        final tempFile = File(tempOutputFile);

        if (await tempFile.exists()) {
          if (useDirectSave && Platform.isAndroid) {
            // On Android, use SAF save dialog with actual content
            final content = await tempFile.readAsString();
            
            // Verify content is not empty
            if (content.trim().isEmpty) {
              // Clean up empty temp file
              await tempFile.delete();
              throw Exception('FFmpeg extraction produced an empty file. The subtitle track may be empty or corrupted.');
            }
            
            if (kDebugMode) {
              print('Temp file content length: ${content.length} characters');
            }

            // Update loading message
            try {
              if (rootContext.mounted) {
                LoadingOverlay.hide(rootContext);
                LoadingOverlay.show(
                  rootContext,
                  message: 'Choosing save location...',
                );
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error updating loading message: $e');
              }
            }

            // Use SAF save dialog with the actual content
            final savedFileInfo = await PlatformFileHandler.saveNewFile(
              content: content,
              fileName: outputFilePath, // This is the suggested filename
              mimeType:
                  'application/x-subrip', // Proper MIME type for SRT files
            );

            if (savedFileInfo == null) {
              throw Exception('User canceled save operation');
            }

            // Clean up the SAF display path to remove URL encoding
            String cleanPath = savedFileInfo.path;
            String? safUri = savedFileInfo.safUri;

            try {
              // Decode URL-encoded characters like %3A (colon) and %2F (slash)
              cleanPath = Uri.decodeFull(savedFileInfo.path);

              // Remove any extra .txt extension that SAF might add
              if (cleanPath.endsWith('.srt.txt')) {
                cleanPath = cleanPath.substring(
                  0,
                  cleanPath.length - 4,
                ); // Remove .txt
              }

              if (kDebugMode) {
                print('Original SAF path: ${savedFileInfo.path}');
                print('Cleaned path: $cleanPath');
                print('SAF URI: $safUri');
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error cleaning path, using original: $e');
              }
              // Use original path if decoding fails
              cleanPath = savedFileInfo.path;
            }

            finalOutputPath = cleanPath;
            // Store the SAF URI for database update
            _currentSafUri = safUri ?? cleanPath;
            
            // Store the content before deleting temp file (will be used later for processing)
            tempOutputFile = tempOutputFile; // Keep the temp file path for now - will delete after processing

            if (kDebugMode) {
              print('Saved via SAF to: $finalOutputPath');
            }
          } else if (Platform.isIOS) {
            // On iOS, use file picker to save the file
            final content = await tempFile.readAsString();
            
            // Verify content is not empty
            if (content.trim().isEmpty) {
              // Clean up empty temp file
              await tempFile.delete();
              throw Exception('FFmpeg extraction produced an empty file. The subtitle track may be empty or corrupted.');
            }
            
            if (kDebugMode) {
              print('Temp file content length: ${content.length} characters');
            }
            
            final contentBytes = Uint8List.fromList(utf8.encode(content));

            // Update loading message
            try {
              if (rootContext.mounted) {
                LoadingOverlay.hide(rootContext);
                LoadingOverlay.show(
                  rootContext,
                  message: 'Choosing save location...',
                );
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error updating loading message: $e');
              }
            }

            // Use iOS file picker to save the file
            final result = await fp.FilePicker.platform.saveFile(
              dialogTitle: 'Save Subtitle File',
              fileName: outputFileName,
              type: fp.FileType.custom,
              allowedExtensions: ['srt'],
              bytes: contentBytes,
            );

            if (result == null) {
              throw Exception('User canceled save operation');
            }

            finalOutputPath = result;
            
            // For iOS, we need to preserve the original temp file path for content reading
            // The temp file will be cleaned up later after content processing
            if (kDebugMode) {
              print('Saved via iOS file picker to: $finalOutputPath');
              print('Original temp file path preserved: $tempOutputFile');
              print('Temp file still exists: ${await tempFile.exists()}');
            }
          } else {
            // On desktop, copy extracted file from temp to user-selected location
            final normalizedOutputFilePath = FFmpegHelper.normalizePath(outputFilePath);
            final destinationFile = File(normalizedOutputFilePath);
            final normalizedTempPath = FFmpegHelper.normalizePath(tempOutputFile);
            
            if (kDebugMode) {
              print('Desktop extraction complete');
              print('Temp file path: $tempOutputFile');
              print('Normalized temp path: $normalizedTempPath');
              print('Final output path: $normalizedOutputFilePath');
            }
            
            // Verify temp file has content before copying
            if (!await tempFile.exists()) {
              throw Exception('Temp file not found: $tempOutputFile');
            }
            
            final tempFileSize = await tempFile.length();
            if (kDebugMode) {
              print('Temp file size: $tempFileSize bytes');
            }
            
            if (tempFileSize == 0) {
              // Clean up empty temp file
              await tempFile.delete();
              throw Exception('FFmpeg extraction produced an empty file. The subtitle track may be empty or corrupted.');
            }
            
            // Delete destination file first if it exists (user already confirmed replacement)
            if (await destinationFile.exists()) {
              await destinationFile.delete();
              if (kDebugMode) {
                print('Deleted existing file at: $normalizedOutputFilePath');
              }
            }
            
            // Copy file from temp to final location
            await tempFile.copy(normalizedOutputFilePath);
            if (kDebugMode) {
              print('Copied file from temp to final location: $normalizedOutputFilePath');
              print('Verifying copied file...');
            }
            
            // Verify the copied file
            final copiedFileSize = await destinationFile.length();
            if (kDebugMode) {
              print('Copied file size: $copiedFileSize bytes');
            }
            
            if (copiedFileSize != tempFileSize) {
              if (kDebugMode) {
                print('WARNING: File size mismatch! Temp: $tempFileSize, Copied: $copiedFileSize');
              }
            }
            
            // Clean up temp file
            await tempFile.delete();
            if (kDebugMode) {
              print('Cleaned up temp file: $tempOutputFile');
            }
            
            finalOutputPath = normalizedOutputFilePath;
            
            // Add a small delay to ensure file system operations complete
            await Future.delayed(const Duration(milliseconds: 100));
          }
        } else {
          throw Exception(
            'Temporary extraction file not found: $tempOutputFile',
          );
        }

        // Update outputFilePath to the final saved location for later processing
        outputFilePath = FFmpegHelper.normalizePath(finalOutputPath);

        // Update loading message
        try {
          if (rootContext.mounted) {
            LoadingOverlay.hide(rootContext);
            LoadingOverlay.show(rootContext, message: 'Processing subtitle...');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error updating loading message: $e');
          }
        }

        if (kDebugMode) {
          print(
            'Extraction completed successfully! Final output: $outputFilePath',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('FFmpeg extraction error: $e');
        }

        // Try to hide loading overlay and show an error
        try {
          await AppLogger.instance.error(
            'Failed to extract subtitle: $e',
            context: 'SubtitleExtractOptionsSheet._extractSubtitleWithAsync',
          );
          if (rootContext.mounted) {
            LoadingOverlay.hide(rootContext);

            SnackbarHelper.showError(
              rootContext,
              'Failed to extract subtitle: $e',
              duration: const Duration(seconds: 5),
            );
          }
        } catch (_) {
          // If this fails, we can't show errors to the user
        }

        return; // Return instead of throwing
      }

      // Verify the file exists - normalize the path first for consistent checking
      final normalizedOutputPath = FFmpegHelper.normalizePath(outputFilePath);
      final extractedFile = File(normalizedOutputPath);
      
      // Skip file verification for iOS since the file picker handles saving
      // and we don't have access to verify files outside the app sandbox
      bool fileExists = true;
      int fileSize = 0;
      
      if (!Platform.isIOS) {
        // Add retry logic for file existence and size check to handle timing issues
        int retryCount = 0;
        const maxRetries = 10;
        const retryDelay = Duration(milliseconds: 200);
        
        while (retryCount < maxRetries) {
          fileExists = await extractedFile.exists();
          
          if (fileExists) {
            fileSize = await extractedFile.length();
            
            // If file exists and has content, we're done
            if (fileSize > 0) {
              break;
            }
            
            // File exists but has 0 bytes - might be a timing issue
            if (retryCount < maxRetries - 1) {
              if (kDebugMode) {
                print('File exists but shows 0 bytes, retrying... (attempt ${retryCount + 1}/$maxRetries)');
              }
              await Future.delayed(retryDelay);
            }
          } else {
            // File doesn't exist yet
            if (retryCount < maxRetries - 1) {
              if (kDebugMode) {
                print('File not found, retrying... (attempt ${retryCount + 1}/$maxRetries)');
              }
              await Future.delayed(retryDelay);
            }
          }
          
          retryCount++;
        }

        if (kDebugMode) {
          print('Original output path: $outputFilePath');
          print('Normalized output path: $normalizedOutputPath');
          print('File exists: $fileExists (after $retryCount attempts)');
          if (fileExists) {
            print('File size: $fileSize bytes');
          }
        }

        if (!fileExists || fileSize == 0) {
          // Provide more detailed error information
          String errorMessage;
          if (!fileExists) {
            errorMessage = 'Subtitle extraction failed - extracted file could not be found at: $normalizedOutputPath';
          } else {
            errorMessage = 'Subtitle extraction failed - extracted file is empty (0 bytes)';
          }
          
          // Try to hide loading overlay and show an error
          try {
            await AppLogger.instance.error(
              errorMessage,
              context: 'SubtitleExtractOptionsSheet._extractSubtitleWithAsync',
            );
            if (rootContext.mounted) {
              LoadingOverlay.hide(rootContext);

              SnackbarHelper.showError(
                rootContext,
                !fileExists 
                  ? 'File could not be found after extraction. Please try again or select a different location.'
                  : 'Extracted file is empty. The subtitle track may not contain any data.',
                duration: const Duration(seconds: 5),
              );
            }
          } catch (_) {
            // If this fails, we can't show errors to the user
          }

          return; // Return instead of throwing
        }
      } else {
        if (kDebugMode) {
          print('iOS: Skipping file verification - file picker handles saving');
          print('Final output path: $normalizedOutputPath');
        }
      }

      // Process the subtitle file with selected options
      if (kDebugMode) {
        print('Processing subtitle file with options:');
        print('Remove hearing impaired lines: $removeHI');
        print('Merge overlapping subtitles: $mergeOverlapping');
      }

      Map? subtitleData;
      try {
        // Try to use context if available, otherwise use the contextless version
        String srtContent;
        String fileName = _fileName.isNotEmpty ? _fileName : 'extracted_subtitle.srt';
        
        try {
          // Read content from the appropriate file based on platform
          // For iOS: temp file is preserved until after processing
          // For Android/Desktop: read from final destination (temp is already deleted)
          File fileToRead;
          
          if (Platform.isIOS) {
            // iOS preserves temp file for content reading
            fileToRead = File(tempOutputFile);
            if (kDebugMode) {
              print('iOS: Reading from temp file: $tempOutputFile');
            }
          } else if (Platform.isAndroid && useDirectSave) {
            // Android SAF: read from temp file (should still exist)
            fileToRead = File(tempOutputFile);
            if (kDebugMode) {
              print('Android SAF: Reading from temp file: $tempOutputFile');
            }
          } else {
            // Desktop: read from final destination (temp is deleted)
            fileToRead = File(outputFilePath);
            if (kDebugMode) {
              print('Desktop: Reading from final destination: $outputFilePath');
            }
          }
          
          if (kDebugMode) {
            print('Attempting to read file: ${fileToRead.path}');
            print('File exists: ${await fileToRead.exists()}');
          }
          
          if (await fileToRead.exists()) {
            srtContent = await fileToRead.readAsString();
            if (kDebugMode) {
              print('Successfully read SRT content: ${srtContent.length} characters');
            }
          } else {
            if (kDebugMode) {
              print('File not found at: ${fileToRead.path}');
              print('Current working directory: ${Directory.current.path}');
            }
            throw Exception('Subtitle file not found: ${fileToRead.path}');
          }
        } catch (e) {
          throw Exception('Failed to read extracted subtitle content: $e');
        }

      try {
        if (rootContext.mounted) {
          subtitleData = await processAndImportSubtitleContent(
            srtContent, // Use content directly instead of file path
            fileName,
            outputFilePath, // Display path for UI
            rootContext,
            removeHearingImpairedLines: removeHI,
            mergeOverlappingSubtitles: mergeOverlapping,
            contentUri: null, // No SAF URI for extracted files
          );
        } else {
          throw Exception('Context not available');
        }
      } catch (e) {
        // Fall back to context-free processing with content
        if (kDebugMode) {
          print('Using alternative processing approach: $e');
        }

        // Process the SRT content directly without file path
        subtitleData = await processSubtitleContentWithoutContext(
          srtContent, // Use content instead of file path
          fileName,
          outputFilePath, // Display path for UI  
          removeHearingImpairedLines: removeHI,
          mergeOverlappingSubtitles: mergeOverlapping,
        );
      }        if (kDebugMode) {
          print(
            'Subtitle processing result: ${'success'}',
          );
          print(
            'Subtitle collection ID: ${subtitleData!['subtitleCollectionId']}',
          );
          print('Filename: ${subtitleData['fileName']}');
          print('Session ID: ${subtitleData['sessionId']}');
                }

        // Update the originalFileUri with the SAF URI if available
        if (_currentSafUri != null && _currentSafUri != outputFilePath) {
          try {
            final subtitleCollectionId = subtitleData!['subtitleCollectionId'];
            if (subtitleCollectionId != null) {
              // Get the subtitle collection from database
              final subtitle = await fetchSubtitle(subtitleCollectionId);
              if (subtitle != null) {
                // Update the originalFileUri
                subtitle.originalFileUri = _currentSafUri!;
                await updateSubtitleCollection(subtitle);

                if (kDebugMode) {
                  print('Updated originalFileUri to: $_currentSafUri');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error updating originalFileUri: $e');
            }
            // Continue with the process even if this fails
          }
        }

        // Create session object
        extractedSession = Session(
          subtitleCollectionId: subtitleData!['subtitleCollectionId'],
          fileName: subtitleData['fileName'] ?? '',
          lastEditedIndex: subtitleData['lastEditedIndex'] ?? 0,
        );

        // Clean up temporary file after successful processing
        try {
          final tempFile = File(tempOutputFile);
          if (await tempFile.exists()) {
            await tempFile.delete();
            if (kDebugMode) {
              print('Cleaned up temporary extraction file: $tempOutputFile');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Warning: Could not clean up temporary file: $e');
          }
          // Continue with the process even if cleanup fails
        }

        // Hide loading overlay and call callback
        try {
          if (rootContext.mounted) {
            LoadingOverlay.hide(rootContext);
            
            if (kDebugMode) {
              print('Loading overlay hidden, calling callback');
            }
            
            // Call the callback immediately after hiding overlay
            callback(extractedSession);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error hiding loading overlay or calling callback: $e');
          }
        }

        return; // Successful completion
            } catch (e) {
        if (kDebugMode) {
          print('Error processing subtitle file: $e');
        }

        // Clean up temp file on error
        try {
          final tempFile = File(tempOutputFile);
          if (await tempFile.exists()) {
            await tempFile.delete();
            if (kDebugMode) {
              print('Cleaned up temporary file after error: $tempOutputFile');
            }
          }
        } catch (cleanupError) {
          if (kDebugMode) {
            print('Warning: Could not clean up temp file after error: $cleanupError');
          }
        }

        // Try to hide loading overlay and show an error
        try {
          await AppLogger.instance.error(
            'Failed to process subtitle file: $e',
            context: 'SubtitleExtractOptionsSheet._extractSubtitleWithAsync',
          );
          if (rootContext.mounted) {
            LoadingOverlay.hide(rootContext);

            SnackbarHelper.showError(
              rootContext,
              'Failed to process subtitle file: $e',
              duration: const Duration(seconds: 5),
            );
          }
        } catch (_) {
          // If this fails, we can't show errors to the user
        }

        return; // Return instead of throwing
      }

      // If we get here, something went wrong but no specific error was thrown
    } catch (e) {
      // Global error handler
      if (kDebugMode) {
        print('Error in _performExtraction: $e');
      }

      // Try to hide loading overlay and show an error
      try {
        await AppLogger.instance.error(
          'Error extracting subtitle: $e',
          context: 'SubtitleExtractOptionsSheet._extractSubtitleWithAsync',
        );
        if (rootContext.mounted) {
          LoadingOverlay.hide(rootContext);

          SnackbarHelper.showError(
            rootContext,
            'Error extracting subtitle: $e',
            duration: const Duration(seconds: 5),
          );
        }
      } catch (_) {
        // If this fails, we can't show errors to the user
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.movie_filter_outlined,
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
                          'Extract Subtitle',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Extract subtitles from video files with processing options',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Video File Selection Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _selectVideoFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? onSurfaceColor.withValues(alpha: 0.05)
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.video_file_outlined,
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
                              _selectedVideoPath != null
                                  ? 'Selected Video'
                                  : 'Select Video File',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedVideoPath != null
                                  ? _fileName
                                  : 'Choose a video file to extract subtitles from',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: mutedColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          color: mutedColor,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle Tracks Card (only visible if video is selected)
            if (_selectedVideoPath != null)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      _subtitleTracks.isEmpty || _isLoading
                          ? null
                          : _viewSubtitleTracks,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _subtitleTracks.isEmpty
                              ? (isDark
                                  ? Colors.orange.shade900.withValues(
                                    alpha: 0.2,
                                  )
                                  : Colors.orange.shade50)
                              : (isDark
                                  ? Colors.green.shade900.withValues(alpha: 0.2)
                                  : Colors.green.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _subtitleTracks.isEmpty
                                ? Colors.orange.withValues(alpha: 0.3)
                                : Colors.green.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                _subtitleTracks.isEmpty
                                    ? Colors.orange
                                    : Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _subtitleTracks.isEmpty
                                ? Icons.warning_outlined
                                : Icons.subtitles_outlined,
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
                                _subtitleTracks.isEmpty
                                    ? 'No Subtitle Tracks'
                                    : 'Subtitle Tracks Found',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _subtitleTracks.isEmpty
                                    ? 'This video file contains no subtitle tracks'
                                    : 'Found ${_subtitleTracks.length} subtitle track${_subtitleTracks.length > 1 ? 's' : ''}',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      _subtitleTracks.isEmpty
                                          ? Colors.orange.shade700
                                          : Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_subtitleTracks.isNotEmpty)
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.green.shade600,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_selectedVideoPath != null) const SizedBox(height: 24),

            // Processing Options Section
            if (_selectedVideoPath != null && _subtitleTracks.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Processing Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Remove Hearing Impaired Option
              Container(
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? onSurfaceColor.withValues(alpha: 0.05)
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: CheckboxListTile(
                  title: Text(
                    'Remove Hearing Impaired Lines',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Removes text inside "[ ]" brackets like [Music] or [Door slams]',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: mutedColor),
                  ),
                  value: _removeHearingImpairedLines,
                  onChanged: (value) {
                    setState(() {
                      _removeHearingImpairedLines = value ?? false;
                    });
                  },
                  activeColor: primaryColor,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Merge Overlapping Option
              Container(
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? onSurfaceColor.withValues(alpha: 0.05)
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: CheckboxListTile(
                  title: Text(
                    'Merge Overlapping Subtitles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Combines subtitles that have the same or overlapping timing',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: mutedColor),
                  ),
                  value: _mergeOverlappingSubtitles,
                  onChanged: (value) {
                    setState(() {
                      _mergeOverlappingSubtitles = value ?? false;
                    });
                  },
                  activeColor: primaryColor,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Extract Button
              Container(
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (_isLoading ||
                              _selectedVideoPath == null ||
                              _subtitleTracks.isEmpty)
                          ? null
                          : _viewSubtitleTracks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Select Subtitle Track',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
