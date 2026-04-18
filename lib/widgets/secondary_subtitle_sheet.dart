import 'package:flutter/material.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/utils/platform_check.dart';
import 'package:subtitle_studio/utils/subtitle_parser.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:subtitle_studio/widgets/video_player_widget.dart';
import 'dart:io';

class SecondarySubtitleSheet extends StatelessWidget {
  final List<SubtitleLine> originalSubtitles;
  final Function(List<SimpleSubtitleLine>) onSecondarySubtitlesLoaded;
  final int subtitleCollectionId; // to persist per-collection settings
  final VideoPlayerWidgetState? videoPlayerState; // for accessing video subtitle tracks

  const SecondarySubtitleSheet({
    super.key,
    required this.originalSubtitles,
    required this.onSecondarySubtitlesLoaded,
    required this.subtitleCollectionId,
    this.videoPlayerState,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic color variables for adaptive theming
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                        Icons.subtitles_outlined,
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
                            "Load Secondary Subtitle",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Add a secondary subtitle track for comparison or dual language support",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Cards
              _buildActionCard(
                context,
                icon: Icons.file_open_outlined,
                title: 'Load from File',
                description: 'Import subtitle from an external file (.srt)',
                onTap: () => _loadFromFile(context),
                themeColor: primaryColor,
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                context,
                icon: Icons.compare_arrows,
                title: 'Use Original Text',
                description: 'Display original text from current subtitles as secondary track',
                onTap: () => _useOriginalText(context),
                themeColor: Colors.orange,
              ),
              // Only show video subtitle track option if video player is available and has subtitle tracks
              if (videoPlayerState != null && _hasAvailableSubtitleTracks()) ...[
                const SizedBox(height: 12),
                _buildActionCard(
                  context,
                  icon: Icons.video_library_outlined,
                  title: 'Use Video Subtitle Track',
                  description: 'Select from subtitle tracks embedded in the video file',
                  onTap: () => _showVideoSubtitleTrackDialog(context),
                  themeColor: Colors.purple,
                ),
              ],
              const SizedBox(height: 24),
              
              // Cancel Button
              Container(
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Cancel",
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
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color themeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                  color: themeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
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
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: mutedColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadFromFile(BuildContext context) async {
    // Guard against context disposal at the beginning
    if (!context.mounted) return;

    // On Android with SAF, no storage permissions needed
    // On other platforms, request storage permissions  
    if (!Platform.isAndroid) {
      final hasPermission = await requestStoragePermissions();
      
      if (!hasPermission) {
        if (!context.mounted) return;
        
        SnackbarHelper.showSnackBar(
          context,
          'Storage permission is required to select subtitle files. Please grant permission in app settings.',
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () {
              openAppSettings();
            },
          ),
        );
        return;
      }
    }

    try {
      String? filePath;
      String? fileContent;
      String fileName = '';
      String? safUri; // Store SAF URI for Android
      
      if (Platform.isAndroid) {
        // On Android, use SAF which returns file content directly
        final fileInfo = await PlatformFileHandler.readFile(
          mimeTypes: ['text/plain', 'application/x-subrip', 'text/vtt'],
        );
        
        if (fileInfo != null) {
          filePath = fileInfo.path; // This is the display path
          fileContent = fileInfo.contentAsString;
          fileName = fileInfo.fileName;
          safUri = fileInfo.safUri; // Store the SAF URI for later use
        } else {
          // User cancelled
          return;
        }
      } else {
        // On other platforms, use traditional file picker
        filePath = await FilePickerSAF.pickFile(
          context: context,
          title: 'Pick a Subtitle File',
          allowedExtensions: ['.srt', '.vtt', '.ass', '.ssa'],
          pickText: 'Select Subtitle File',
        );
        
        final file = File(filePath!);
        fileContent = await file.readAsString();
        
        // Handle both forward slashes and backslashes for cross-platform compatibility
        final backslashIndex = filePath.lastIndexOf('\\');
        final forwardSlashIndex = filePath.lastIndexOf('/');
        
        // Use the last occurring separator
        final lastSeparatorIndex = backslashIndex > forwardSlashIndex ? backslashIndex : forwardSlashIndex;
        
        if (lastSeparatorIndex >= 0) {
          fileName = filePath.substring(lastSeparatorIndex + 1);
        } else {
          fileName = filePath; // No separators found, use whole path
        }
            }

      // Guard against context disposal after the picker
      if (!context.mounted) return;

      // Parse subtitle file based on extension
      List<SimpleSubtitleLine> parsedSubtitles = [];
      if (fileName.toLowerCase().endsWith('.srt')) {
        parsedSubtitles = SubtitleParser.parseSrt(fileContent);
      } else if (fileName.toLowerCase().endsWith('.vtt')) {
        parsedSubtitles = SubtitleParser.parseVtt(fileContent);
      } else if (fileName.toLowerCase().endsWith('.ass') || fileName.toLowerCase().endsWith('.ssa')) {
        parsedSubtitles = SubtitleParser.parseAss(fileContent);
      }

      if (parsedSubtitles.isNotEmpty) {
        // Delete any existing extracted subtitle file before loading a new one
        try {
          final existingPath = await PreferencesModel.getSecondarySubtitlePath(subtitleCollectionId);
          if (existingPath != null && existingPath.isNotEmpty) {
            final existingFile = File(existingPath);
            if (await existingFile.exists() && existingPath.contains('extracted_subtitle_')) {
              await existingFile.delete();
              print('Deleted previous extracted subtitle file: $existingPath');
            }
          }
        } catch (e) {
          print('Warning: Failed to delete previous extracted subtitle file: $e');
        }
        
        onSecondarySubtitlesLoaded(parsedSubtitles);
        
        // On Android, save the SAF URI instead of display path for proper file access
        String pathToSave = filePath;
        if (Platform.isAndroid && safUri != null) {
          pathToSave = safUri;
          print('Saving SAF URI for secondary subtitle: $pathToSave');
        }
        
        // Persist the path (or URI on Android) and mark that secondary is not original
        PreferencesModel.saveSecondarySubtitlePath(subtitleCollectionId, pathToSave);
        PreferencesModel.setSecondaryIsOriginal(subtitleCollectionId, false);
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          _showErrorDialog(context, 'Could not parse the subtitle file.');
        }
      }
        } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Error loading file: $e');
      }
    }
  }

  Future<void> _useOriginalText(BuildContext context) async {
    List<SimpleSubtitleLine> originalTextSubtitles = [];

    // Create a new list with original text using SimpleSubtitleLine
    for (var line in originalSubtitles) {
      if (line.original.isNotEmpty) {
        originalTextSubtitles.add(SimpleSubtitleLine(
          index: line.index,
          startTime: line.startTime,
          endTime: line.endTime,
          // Convert <br> tags back to newlines since the video player expects \n characters
          // to convert them to <br> tags for HTML rendering
          text: line.original.replaceAll('<br>', '\n'),
        ));
      }
    }

    if (originalTextSubtitles.isNotEmpty) {
      // Delete any existing extracted subtitle file when switching to original text
      try {
        final existingPath = await PreferencesModel.getSecondarySubtitlePath(subtitleCollectionId);
        if (existingPath != null && existingPath.isNotEmpty) {
          final existingFile = File(existingPath);
          if (await existingFile.exists() && existingPath.contains('extracted_subtitle_')) {
            await existingFile.delete();
            print('Deleted previous extracted subtitle file: $existingPath');
          }
        }
      } catch (e) {
        print('Warning: Failed to delete previous extracted subtitle file: $e');
      }
      
      onSecondarySubtitlesLoaded(originalTextSubtitles);
  // Persist that secondary subtitles should be the original text for this collection
  PreferencesModel.setSecondaryIsOriginal(subtitleCollectionId, true);
  // Also clear any saved external path
  PreferencesModel.removeSecondarySubtitlePath(subtitleCollectionId);
      if (context.mounted) {
        Navigator.pop(context);
      }
    } else {
      if (context.mounted) {
        _showErrorDialog(context, 'No original text available in the current subtitles.');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Check if video player has available subtitle tracks
  bool _hasAvailableSubtitleTracks() {
    if (videoPlayerState == null) return false;
    final tracks = videoPlayerState!.getAvailableSubtitleTracks();
    // Filter out 'auto' and 'no' tracks which are not real subtitle tracks
    final realTracks = tracks.where((t) => t.id != 'auto' && t.id != 'no').toList();
    return realTracks.isNotEmpty;
  }

  /// Show dialog to select from available video subtitle tracks
  void _showVideoSubtitleTrackDialog(BuildContext context) async {
    if (videoPlayerState == null) return;
    
    // Show loading indicator while getting track information
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Get detailed track information from FFmpeg
      final detailedTracks = await videoPlayerState!.getDetailedSubtitleTracks();
      
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
      
      final textTracks = detailedTracks.where((track) {
        final codec = (track['codec'] as String?)?.toLowerCase() ?? '';
        return textBasedCodecs.contains(codec);
      }).toList();
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (detailedTracks.isEmpty) {
        if (context.mounted) {
          SnackbarHelper.showSnackBar(
            context,
            'No subtitle tracks found in the video file',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }
      
      if (textTracks.isEmpty) {
        if (context.mounted) {
          // Show info about bitmap subtitles not being extractable
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Text-Based Subtitles Found'),
              content: Text(
                'This video contains ${detailedTracks.length} subtitle track(s), but they are in bitmap format (e.g., PGS, HDMV) which cannot be converted to text.\n\n'
                'Only text-based subtitle formats (SRT, ASS, WebVTT, etc.) can be extracted.\n\n'
                'Please load a separate subtitle file instead.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(
              'Select Video Subtitle Track',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: textTracks.length,
                itemBuilder: (context, index) {
                  final track = textTracks[index];
                  return _buildDetailedSubtitleTrackOption(dialogContext, track, index);
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel', style: TextStyle(color: Theme.of( context).colorScheme.onSurface)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorDialog(context, 'Error loading subtitle tracks: $e');
      }
    }
  }

  /// Build a single detailed subtitle track option widget from FFmpeg track info
  Widget _buildDetailedSubtitleTrackOption(BuildContext context, Map<String, dynamic> track, int index) {
    // Extract track information
    final String title = track['title'] ?? 'Subtitle Track ${track['index'] ?? index}';
    final String? language = track['language'];
    final String? codec = track['codec'];
    final String streamIndex = track['index']?.toString() ?? index.toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _selectDetailedSubtitleTrack(context, track),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (language != null) ...[
                        Text(
                          'Language: $language',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      if (codec != null) ...[
                        Text(
                          'Codec: $codec',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      Text(
                        'Stream Index: $streamIndex',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Select a detailed subtitle track and extract its content
  Future<void> _selectDetailedSubtitleTrack(BuildContext dialogContext, Map<String, dynamic> track) async {
    Navigator.pop(dialogContext); // Close the track selection dialog
    
    // Get the root context from the navigator to avoid context conflicts
    final BuildContext? rootContext = Navigator.maybeOf(dialogContext)?.context;
    if (rootContext == null || !rootContext.mounted) return;
    
    bool loadingDialogOpen = false;
    
    try {
      // Show loading dialog for extraction
      loadingDialogOpen = true;
      showDialog(
        context: rootContext,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Extracting subtitle track...'),
              ),
            ],
          ),
        ),
      );
      
      final subtitleIndex = track['subtitle_index'] as int?;
      if (subtitleIndex == null) {
        throw Exception('Invalid subtitle index');
      }
      
      // Extract subtitle content from the video
      final subtitleContent = await videoPlayerState?.extractSubtitleTrackContent(subtitleIndex);
      
      if (subtitleContent == null || subtitleContent.isEmpty) {
        throw Exception('Failed to extract subtitle content from the track.');
      }
      
      // Parse the extracted subtitle content
      List<SimpleSubtitleLine> parsedSubtitles = [];
      String detectedFormat = 'srt'; // Default to SRT
      
      // Determine format and parse accordingly
      // Most extracted subtitles from video tracks are in SRT format
      if (subtitleContent.contains('-->')) {
        // Looks like SRT or WebVTT format
        if (subtitleContent.contains('WEBVTT')) {
          parsedSubtitles = SubtitleParser.parseVtt(subtitleContent);
          detectedFormat = 'vtt';
        } else {
          parsedSubtitles = SubtitleParser.parseSrt(subtitleContent);
          detectedFormat = 'srt';
        }
      } else if (subtitleContent.contains('[Script Info]')) {
        // ASS/SSA format
        parsedSubtitles = SubtitleParser.parseAss(subtitleContent);
        detectedFormat = 'ass';
      } else {
        // Try SRT parser as fallback
        parsedSubtitles = SubtitleParser.parseSrt(subtitleContent);
        detectedFormat = 'srt';
      }
      
      if (parsedSubtitles.isEmpty) {
        throw Exception('Failed to parse the extracted subtitle content.');
      }
      
      // Close loading dialog before proceeding
      if (loadingDialogOpen && rootContext.mounted) {
        Navigator.pop(rootContext);
        loadingDialogOpen = false;
      }
      
      // Delete any existing extracted subtitle file before creating a new one
      try {
        final existingPath = await PreferencesModel.getSecondarySubtitlePath(subtitleCollectionId);
        if (existingPath != null && existingPath.isNotEmpty) {
          final existingFile = File(existingPath);
          if (await existingFile.exists() && existingPath.contains('extracted_subtitle_')) {
            await existingFile.delete();
            print('Deleted previous extracted subtitle file: $existingPath');
          }
        }
      } catch (e) {
        print('Warning: Failed to delete previous extracted subtitle file: $e');
      }
      
      // Save extracted content to a temporary file for future reloading
      try {
        final tempDir = Directory.systemTemp;
        final trackTitle = track['title'] ?? 'Track_${track['index']}';
        final sanitizedTitle = trackTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
        final tempFileName = 'extracted_subtitle_${subtitleCollectionId}_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.$detectedFormat';
        final tempFile = File('${tempDir.path}${Platform.pathSeparator}$tempFileName');
        
        await tempFile.writeAsString(subtitleContent);
        
        // Save the temp file path to SharedPreferences for future reloading
        await PreferencesModel.saveSecondarySubtitlePath(subtitleCollectionId, tempFile.path);
      } catch (e) {
        // If saving to temp file fails, continue anyway but log the error
        print('Warning: Failed to save extracted subtitle to temp file: $e');
      }
      
      // Successfully parsed subtitles
      onSecondarySubtitlesLoaded(parsedSubtitles);
      
      // Persist the track selection
      PreferencesModel.setSecondaryIsOriginal(subtitleCollectionId, false);
      
      if (rootContext.mounted) {
        SnackbarHelper.showSuccess(
          rootContext, 
          'Video subtitle track "${track['title'] ?? 'Track ${track['index']}'}" loaded successfully.'
        );
        Navigator.pop(rootContext); // Close the secondary subtitle sheet
      }
      
    } catch (e) {
      // Ensure loading dialog is closed in case of error
      if (loadingDialogOpen && rootContext.mounted) {
        Navigator.pop(rootContext);
        loadingDialogOpen = false;
      }
      
      // Show error dialog
      if (rootContext.mounted) {
        _showErrorDialog(rootContext, 'Error extracting subtitle track: $e');
      }
    }
  }
}
