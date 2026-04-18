import 'package:flutter/material.dart';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:subtitle_studio/database/database_helper.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/utils/project_manager.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/screens/edit/edit_screen_bloc.dart';
import 'package:subtitle_studio/main.dart';
import 'package:subtitle_studio/utils/srt_compiler.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'package:subtitle_studio/services/checkpoint_manager.dart';

/// Session Selection Sheet Widget
/// 
/// This widget provides a bottom modal sheet for selecting an existing session
/// to replace with imported project data. It displays all sessions from the 
/// database and allows the user to choose which one to update.
class SessionSelectionSheet extends StatefulWidget {
  final Map<String, dynamic> projectData;
  final String? originalFileUri;
  final Function(Session)? onSessionReplaced;
  final Function(Session)? onSessionCreated;
  final Function(Session)? onProjectImported; // New callback for home screen refresh

  const SessionSelectionSheet({
    super.key,
    required this.projectData,
    this.originalFileUri,
    this.onSessionReplaced,
    this.onSessionCreated,
    this.onProjectImported,
  });

  @override
  State<SessionSelectionSheet> createState() => _SessionSelectionSheetState();
}

class _SessionSelectionSheetState extends State<SessionSelectionSheet> {
  List<Session> _sessions = [];
  bool _isLoading = true;
  bool _isReplacing = false;
  bool _isCreating = false;
  Session? _selectedSession;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  /// Ask user to select the SRT file location
  /// Since .msone projects are portable but SRT files may be in different locations
  /// Returns a Map with 'filePath', 'fileName', and 'safUri' keys
  Future<Map<String, String?>?> _selectSrtFilePath({Session? existingSession}) async {
    try {
      // Get the original filename and filepath from project data to help user identify the file
      String? originalFileName;
      String? originalFilePath;
      if (widget.projectData['subtitleCollection'] != null) {
        final subtitleData = widget.projectData['subtitleCollection'] as Map<String, dynamic>;
        originalFileName = subtitleData['fileName'];
        originalFilePath = subtitleData['filePath'] ?? subtitleData['originalFileUri'];
      }

      // Get existing session's file path information if available
      String? existingFileName;
      String? existingFilePath;
      if (existingSession != null) {
        final existingSubtitle = await isar.subtitleCollections.get(existingSession.subtitleCollectionId);
        if (existingSubtitle != null) {
          existingFileName = existingSubtitle.fileName;
          existingFilePath = existingSubtitle.filePath ?? existingSubtitle.originalFileUri;
        }
      }
      
      // Show a custom sheet explaining why we need to select the SRT file
      final choice = await showModalBottomSheet<String?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return _LocateSrtSheet(
            originalFileName: originalFileName,
            originalFilePath: originalFilePath,
            existingFileName: existingFileName,
            existingFilePath: existingFilePath,
          );
        },
      );

      if (choice == null || choice == 'cancel') {
        return null;
      } else if (choice == 'use_existing_project') {
        // User chose to use the existing project's path - no need to update file paths in database
        if (existingFilePath != null && existingFileName != null) {
          return {
            'filePath': null, // No file path update needed
            'fileName': existingFileName,
            'safUri': null, // No URI update needed
            'fileUri': null, // No file reference update needed - keep existing
            'useExistingProject': 'true', // Flag to indicate using existing project's paths
          };
        } else {
          if (mounted) {
            SnackbarHelper.showError(context, 'Existing project file path not available');
          }
          return null;
        }
      } else if (choice == 'use_importing_file') {
        // User chose to use the importing file's path - no need to update file paths in database
        if (originalFilePath != null && originalFileName != null) {
          return {
            'filePath': null, // No file path update needed
            'fileName': originalFileName,
            'safUri': null, // No URI update needed
            'fileUri': null, // No file reference update needed - keep existing
            'useImportingFile': 'true', // Flag to indicate using importing file's paths
          };
        } else {
          if (mounted) {
            SnackbarHelper.showError(context, 'Importing file path not available');
          }
          return null;
        }
      } else if (choice == 'select_new') {
        // User chose to create a new SRT file in a selected folder
        return await _createSrtFile();
      }
      
      return null;
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error selecting SRT file: $e');
      }
      return null;
    }
  }

  /// Create a new SRT file in the selected folder
  Future<Map<String, String?>?> _createSrtFile() async {
    try {
      // Get the subtitle lines from project data
      final subtitleCollectionData = widget.projectData['subtitleCollection'] as Map<String, dynamic>;
      final linesData = subtitleCollectionData['lines'] as List<dynamic>;
      
      // Convert to SubtitleLine objects
      List<SubtitleLine> subtitleLines = linesData.map((lineData) {
        final data = Map<String, dynamic>.from(lineData);
        return SubtitleLine()
          ..index = data['index'] ?? 0
          ..startTime = data['startTime'] ?? '00:00:00,000'
          ..endTime = data['endTime'] ?? '00:00:02,000'
          ..original = data['original'] ?? ''
          ..edited = data['edited']
          ..marked = data['marked'] ?? false;
      }).toList();
      
      // Generate SRT content
      final srtContent = SrtCompiler.generateSrtContent(subtitleLines);
      
      // Get original filename for the SRT file
      String originalFileName = subtitleCollectionData['fileName'] ?? '';
      if (originalFileName.isEmpty) {
        // Fallback to session fileName if subtitle fileName is not available
        final sessionData = widget.projectData['session'] as Map<String, dynamic>;
        originalFileName = sessionData['fileName'] ?? 'subtitle';
      }
      
      // Ensure .srt extension
      if (!originalFileName.toLowerCase().endsWith('.srt')) {
        originalFileName = '$originalFileName.srt';
      }
      
      if (Platform.isAndroid) {
        // On Android, use SAF to save the file and get proper URI
        try {
          final fileInfo = await PlatformFileHandler.saveNewFile(
            content: srtContent,
            fileName: originalFileName,
            mimeType: 'application/x-subrip',
          );
          
          if (fileInfo != null) {
            return {
              'filePath': fileInfo.path, // Display path for UI
              'fileName': originalFileName,
              'safUri': fileInfo.safUri, // This is the proper SAF URI
              'fileUri': fileInfo.safUri ?? fileInfo.path, // Prefer SAF URI
            };
          }
        } catch (e) {
          if (mounted) {
            SnackbarHelper.showError(context, 'Error creating SRT file: $e');
          }
          return null;
        }
      } else {
        // On desktop, select a folder and save the file traditionally
        final selectedFolder = await FilePickerConvenience.pickExportFolder(context: context);
        
        if (selectedFolder != null) {
          final filePath = path.join(selectedFolder, originalFileName);
          final file = File(filePath);
          
          // Write the file
          await file.writeAsString(srtContent);
          
          return {
            'filePath': filePath,
            'fileName': originalFileName,
            'safUri': null,
            'fileUri': filePath,
          };
        }
      }
      
      return null;
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error creating SRT file: $e');
      }
      return null;
    }
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await getAllSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to load sessions: $e');
      }
    }
  }

  /// Import checkpoints from project data into the database
  Future<void> _importCheckpoints(int sessionId, int subtitleCollectionId) async {
    try {
      print('[Import] Starting checkpoint import for session $sessionId, collection $subtitleCollectionId');
      print('[Import] Project data keys: ${widget.projectData.keys.toList()}');
      
      // Check if checkpoints exist in project data
      if (!widget.projectData.containsKey('checkpoints')) {
        print('[Import] No checkpoints key found in project data');
        return;
      }

      final checkpointsData = widget.projectData['checkpoints'] as List<dynamic>;
      
      if (checkpointsData.isEmpty) {
        print('[Import] Checkpoints list is empty');
        return;
      }

      print('[Import] Importing ${checkpointsData.length} checkpoints...');

      // Map to store old checkpoint ID to new checkpoint ID
      final Map<int, int> checkpointIdMap = {};
      int importedCount = 0;

      await isar.writeTxn(() async {
        for (final checkpointData in checkpointsData) {
          try {
            final checkpoint = Checkpoint(
              sessionId: sessionId,
              subtitleCollectionId: subtitleCollectionId,
              timestamp: DateTime.parse(checkpointData['timestamp']),
              operationType: checkpointData['operationType'] ?? 'unknown',
              description: checkpointData['description'] ?? '',
              parentCheckpointId: null, // Will be updated in second pass
              isActive: checkpointData['isActive'] ?? false,
              checkpointType: checkpointData['checkpointType'] ?? 'delta',
              metadata: checkpointData['metadata'],
              deltas: (checkpointData['deltas'] as List<dynamic>).map((deltaData) {
                final delta = SubtitleLineDelta();
                delta.changeType = deltaData['changeType'] ?? '';
                delta.lineIndex = deltaData['lineIndex'] ?? 0;
                
                // Restore beforeState
                if (deltaData['beforeState'] != null) {
                  final beforeLine = SubtitleLine();
                  beforeLine.index = deltaData['beforeState']['index'] ?? 0;
                  beforeLine.startTime = deltaData['beforeState']['startTime'] ?? '';
                  beforeLine.endTime = deltaData['beforeState']['endTime'] ?? '';
                  beforeLine.original = deltaData['beforeState']['original'] ?? '';
                  beforeLine.edited = deltaData['beforeState']['edited'];
                  beforeLine.marked = deltaData['beforeState']['marked'] ?? false;
                  beforeLine.comment = deltaData['beforeState']['comment'];
                  beforeLine.resolved = deltaData['beforeState']['resolved'] ?? false;
                  delta.beforeState = beforeLine;
                }
                
                // Restore afterState
                if (deltaData['afterState'] != null) {
                  final afterLine = SubtitleLine();
                  afterLine.index = deltaData['afterState']['index'] ?? 0;
                  afterLine.startTime = deltaData['afterState']['startTime'] ?? '';
                  afterLine.endTime = deltaData['afterState']['endTime'] ?? '';
                  afterLine.original = deltaData['afterState']['original'] ?? '';
                  afterLine.edited = deltaData['afterState']['edited'];
                  afterLine.marked = deltaData['afterState']['marked'] ?? false;
                  afterLine.comment = deltaData['afterState']['comment'];
                  afterLine.resolved = deltaData['afterState']['resolved'] ?? false;
                  delta.afterState = afterLine;
                }
                
                return delta;
              }).toList(),
              snapshot: (checkpointData['snapshot'] as List<dynamic>).map((lineData) {
                final line = SubtitleLine();
                line.index = lineData['index'] ?? 0;
                line.startTime = lineData['startTime'] ?? '';
                line.endTime = lineData['endTime'] ?? '';
                line.original = lineData['original'] ?? '';
                line.edited = lineData['edited'];
                line.marked = lineData['marked'] ?? false;
                line.comment = lineData['comment'];
                line.resolved = lineData['resolved'] ?? false;
                return line;
              }).toList(),
            );

            // Store the checkpoint and map old ID to new ID
            final newId = await isar.checkpoints.put(checkpoint);
            
            // Store the mapping for parent relationships
            // We assume the order of checkpoints is maintained, so we can use index
            final oldId = checkpointsData.indexOf(checkpointData);
            checkpointIdMap[oldId] = newId;
            
            importedCount++;
          } catch (e) {
            print('[Import] Error importing checkpoint: $e');
          }
        }

        // Second pass: Update parent checkpoint IDs
        final allCheckpoints = await CheckpointManager.getCheckpointsForSession(sessionId);
        allCheckpoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        for (int i = 0; i < checkpointsData.length && i < allCheckpoints.length; i++) {
          final checkpointData = checkpointsData[i];
          final oldParentId = checkpointData['parentCheckpointId'];
          
          if (oldParentId != null) {
            // Find the index of the parent in the original data
            int parentIndex = -1;
            for (int j = 0; j < checkpointsData.length; j++) {
              // Since we don't have the original ID, we match by timestamp and description
              final potentialParent = checkpointsData[j];
              if (DateTime.parse(potentialParent['timestamp']).isBefore(
                    DateTime.parse(checkpointData['timestamp']))) {
                parentIndex = j;
              }
            }
            
            if (parentIndex >= 0 && checkpointIdMap.containsKey(parentIndex)) {
              allCheckpoints[i].parentCheckpointId = checkpointIdMap[parentIndex];
              await isar.checkpoints.put(allCheckpoints[i]);
            }
          }
        }
      });

      print('[Import] Successfully imported $importedCount checkpoints');
    } catch (e) {
      print('[Import] Error importing checkpoints: $e');
      // Don't fail the entire import if checkpoints fail
    }
  }

  Future<void> _replaceSession(Session session) async {
    setState(() {
      _isReplacing = true;
      _selectedSession = session;
    });

    try {
      // Ask user to select the SRT file location since it may be different on each device
      final srtFileInfo = await _selectSrtFilePath(existingSession: session);
      if (srtFileInfo == null) {
        // User cancelled the selection
        setState(() {
          _isReplacing = false;
          _selectedSession = null;
        });
        return;
      }

      final sessionData = widget.projectData['session'] as Map<String, dynamic>;
      final subtitleCollectionData = widget.projectData['subtitleCollection'] as Map<String, dynamic>;

      // Prepare subtitle lines
      final linesData = subtitleCollectionData['lines'] as List<dynamic>;
      final subtitleLines = linesData.map((lineData) {
        final line = SubtitleLine();
        line.index = lineData['index'] ?? 0;
        line.startTime = lineData['startTime'] ?? '';
        line.endTime = lineData['endTime'] ?? '';
        line.original = lineData['original'] ?? '';
        line.edited = lineData['edited'];
        line.marked = lineData['marked'] ?? false;
        line.comment = lineData['comment'];  // Include comment field
        return line;
      }).toList();

      // Get the existing subtitle collection
      final existingSubtitle = await isar.subtitleCollections.get(session.subtitleCollectionId);
      if (existingSubtitle != null) {
        // Update the existing subtitle collection with new data
        if (srtFileInfo['useExistingProject'] == 'true') {
          // Keep the existing subtitle collection's file name - no change needed
          // existingSubtitle.fileName remains unchanged
        } else if (srtFileInfo['useImportingFile'] == 'true') {
          // Use the importing file's name
          existingSubtitle.fileName = subtitleCollectionData['fileName'] ?? existingSubtitle.fileName;
        } else {
          // User selected a new file location - use the new file name
          existingSubtitle.fileName = srtFileInfo['fileName'] ?? subtitleCollectionData['fileName'] ?? existingSubtitle.fileName;
        }
        existingSubtitle.encoding = subtitleCollectionData['encoding'] ?? existingSubtitle.encoding;
        existingSubtitle.lines = subtitleLines;
        
        // Update file paths based on user choice
        if (srtFileInfo['useExistingProject'] == 'true') {
          // Keep the existing file references unchanged
          // No updates to originalFileUri or filePath
        } else if (srtFileInfo['useImportingFile'] == 'true') {
          // Use the importing file's path information
          existingSubtitle.originalFileUri = subtitleCollectionData['originalFileUri'] ?? subtitleCollectionData['filePath'];
          existingSubtitle.filePath = subtitleCollectionData['filePath'];
        } else if (srtFileInfo['safUri'] != null || srtFileInfo['filePath'] != null) {
          // User selected a new file location - update with selected SRT file information
          // On Android, prefer SAF URI over file path for originalFileUri
          if (Platform.isAndroid && srtFileInfo['safUri'] != null) {
            existingSubtitle.originalFileUri = srtFileInfo['safUri'];
          } else {
            existingSubtitle.originalFileUri = srtFileInfo['fileUri'] ?? srtFileInfo['filePath'];
          }
          existingSubtitle.filePath = srtFileInfo['filePath'];
        }

        await isar.writeTxn(() async {
          await isar.subtitleCollections.put(existingSubtitle);
        });

        // Update the session with the appropriate file name based on user choice
        if (srtFileInfo['useExistingProject'] == 'true') {
          // Keep the existing session's file name - no change needed
          // session.fileName remains unchanged
        } else if (srtFileInfo['useImportingFile'] == 'true') {
          // Use the importing file's name
          session.fileName = subtitleCollectionData['fileName'] ?? session.fileName;
        } else {
          // User selected a new file location - use the new file name
          session.fileName = srtFileInfo['fileName'] ?? subtitleCollectionData['fileName'] ?? session.fileName;
        }
        if (sessionData['lastEditedIndex'] != null) {
          session.lastEditedIndex = sessionData['lastEditedIndex'];
        }
        if (sessionData['editMode'] != null) {
          session.editMode = sessionData['editMode'];
        }
        // Update project file path - store the .msone file path/URI
        session.projectFilePath = widget.originalFileUri;

        await isar.writeTxn(() async {
          await isar.sessions.put(session);
        });

        // Small delay to ensure database transaction is fully committed
        await Future.delayed(const Duration(milliseconds: 100));

        // Import checkpoints if available in project data
        await _importCheckpoints(session.id, session.subtitleCollectionId);

        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            'Session "${session.fileName}" updated successfully!',
            duration: const Duration(seconds: 3),
          );
          
          // Callback to parent widget first
          if (widget.onSessionReplaced != null) {
            widget.onSessionReplaced!(session);
          }
          
          // Callback to refresh home screen sessions
          if (widget.onProjectImported != null) {
            widget.onProjectImported!(session);
          }
          
          // Navigate to EditScreen with the updated session
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => EditScreenBloc(
                subtitleCollectionId: session.subtitleCollectionId,
                sessionId: session.id,
                lastEditedIndex: session.lastEditedIndex,
              ),
            ),
            (route) => route.isFirst, // Remove all routes except the first one
          );
        }
      } else {
        throw Exception('Session subtitle collection not found');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to replace session: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReplacing = false;
          _selectedSession = null;
        });
      }
    }
  }

  Future<void> _importAsNewSession() async {
    setState(() {
      _isCreating = true;
    });

    try {
      // Ask user to select the SRT file location since it may be different on each device
      final srtFileInfo = await _selectSrtFilePath(); // No existing session when importing as new
      if (srtFileInfo == null) {
        // User cancelled the selection
        setState(() {
          _isCreating = false;
        });
        return;
      }

      final sessionData = widget.projectData['session'] as Map<String, dynamic>;
      final subtitleCollectionData = widget.projectData['subtitleCollection'] as Map<String, dynamic>;

      // Prepare subtitle lines
      final linesData = subtitleCollectionData['lines'] as List<dynamic>;
      final subtitleLines = linesData.map((lineData) {
        final line = SubtitleLine();
        line.index = lineData['index'] ?? 0;
        line.startTime = lineData['startTime'] ?? '';
        line.endTime = lineData['endTime'] ?? '';
        line.original = lineData['original'] ?? '';
        line.edited = lineData['edited'];
        line.marked = lineData['marked'] ?? false;
        line.comment = lineData['comment'];  // Include comment field
        return line;
      }).toList();

      // Use the user-selected SRT file information
      String subtitleFileUri;
      String selectedFileName;
      String selectedFilePath;
      
      if (srtFileInfo['useExistingProject'] == 'true') {
        // This shouldn't happen in import as new, but handle it gracefully
        subtitleFileUri = '';
        selectedFileName = subtitleCollectionData['fileName'] ?? 'Imported Project';
        selectedFilePath = '';
      } else if (srtFileInfo['useImportingFile'] == 'true') {
        // Use the importing file's path information
        if (Platform.isAndroid) {
          // For importing file, we don't have direct SAF URI access, use fallback
          subtitleFileUri = subtitleCollectionData['originalFileUri'] ?? subtitleCollectionData['filePath'] ?? '';
        } else {
          subtitleFileUri = subtitleCollectionData['originalFileUri'] ?? subtitleCollectionData['filePath'] ?? '';
        }
        selectedFileName = subtitleCollectionData['fileName'] ?? 'Imported Project';
        selectedFilePath = subtitleCollectionData['filePath'] ?? '';
      } else {
        // User selected a new location
        // On Android, prefer SAF URI over file path for originalFileUri
        if (Platform.isAndroid && srtFileInfo['safUri'] != null) {
          subtitleFileUri = srtFileInfo['safUri']!;
        } else {
          subtitleFileUri = srtFileInfo['fileUri'] ?? srtFileInfo['filePath'] ?? '';
        }
        selectedFileName = srtFileInfo['fileName'] ?? subtitleCollectionData['fileName'] ?? 'Imported Project';
        selectedFilePath = srtFileInfo['filePath'] ?? '';
      }

      // Store subtitle collection in database
      final subtitleData = await storeSubtitleData(
        subtitleLines,
        selectedFileName, // Use the selected file name
        subtitleCollectionData['encoding'] ?? 'UTF-8',
        selectedFilePath.isNotEmpty ? selectedFilePath : subtitleCollectionData['filePath'], // Use selected file path or fallback
        editMode: sessionData['editMode'] ?? true,
        originalFileUri: subtitleFileUri,
        projectFilePath: null, // No project file path for imports
      );

      // Get the created session from the database using the returned sessionId
      final session = await isar.sessions.get(subtitleData['sessionId']);
      
      if (session == null) {
        throw Exception('Failed to retrieve created session');
      }

      // Update session with imported data and selected file name
      if (sessionData['lastEditedIndex'] != null) {
        session.lastEditedIndex = sessionData['lastEditedIndex'];
      }
      
      // Update the session fileName with the selected file name
      session.fileName = selectedFileName;
      
      // Store the project file path to link session to the .msone file
      session.projectFilePath = widget.originalFileUri;
      
      await isar.writeTxn(() async {
        await isar.sessions.put(session);
      });

      // Small delay to ensure database transaction is fully committed
      await Future.delayed(const Duration(milliseconds: 100));

      // Import checkpoints if available in project data
      await _importCheckpoints(session.id, session.subtitleCollectionId);

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Project imported as new session successfully!',
          duration: const Duration(seconds: 3),
        );
        
        // Callback to parent widget first
        if (widget.onSessionCreated != null) {
          widget.onSessionCreated!(session);
        }
        
        // Callback to refresh home screen sessions
        if (widget.onProjectImported != null) {
          widget.onProjectImported!(session);
        }
        
        // Navigate to EditScreen with the new session
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => EditScreenBloc(
              subtitleCollectionId: session.subtitleCollectionId,
              sessionId: session.id,
              lastEditedIndex: session.lastEditedIndex,
            ),
          ),
          (route) => route.isFirst, // Remove all routes except the first one
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to import as new session: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  /// Build session item widget
  Widget _buildSessionItem(Session session) {
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final isSelected = _selectedSession?.id == session.id;
    final isLoading = _isReplacing && isSelected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => _replaceSession(session),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected && isLoading 
                  ? primaryColor.withValues(alpha: 0.1)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.subtitles,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.fileName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note,
                            size: 14,
                            color: mutedColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            session.editMode ? 'Edit Mode' : 'Translation Mode',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: mutedColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (session.lastEditedIndex != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.bookmark,
                              size: 14,
                              color: mutedColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Line ${session.lastEditedIndex! + 1}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: mutedColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                          if (ProjectManager.hasProjectFile(session)) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.folder,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Project',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: onSurfaceColor.withValues(alpha: 0.3),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
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
                      Icons.file_download,
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
                          'Import Project',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Replace an existing session or import as new',
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

            const SizedBox(height: 16),

            // Sessions List
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              )
            else if (_sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: mutedColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No sessions found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a session first to replace it with imported data',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ..._sessions.map((session) => _buildSessionItem(session)),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: Container(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: (_isReplacing || _isCreating) ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onSurfaceColor,
                        side: BorderSide(
                          color: onSurfaceColor.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.close,
                            size: 20,
                            color: onSurfaceColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: onSurfaceColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Import as New Button
                Expanded(
                  child: Container(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isReplacing || _isCreating) ? null : _importAsNewSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Import as New',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LocateSrtSheet extends StatelessWidget {
  final String? originalFileName;
  final String? originalFilePath;
  final String? existingFileName;
  final String? existingFilePath;

  const _LocateSrtSheet({
    this.originalFileName,
    this.originalFilePath,
    this.existingFileName,
    this.existingFilePath,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurfaceColor.withValues(alpha: 0.6);
    final borderColor = onSurfaceColor.withValues(alpha: 0.12);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
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
                      color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: onSurfaceColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SRT File Options",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Choose subtitle file location",
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
            
            const SizedBox(height: 20),
            
            // Information Container
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "File Location Required",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  originalFileName != null 
                    ? Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'The imported project references a subtitle file named ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                            TextSpan(
                              text: '"$originalFileName"',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                            TextSpan(
                              text: '. You have three options: use the existing project\'s path, use the imported file\'s path, or create a new SRT file.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        'The project contains subtitle data that can be exported as an SRT file. You can use the existing project\'s path or create a new SRT file in a folder of your choice.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                  
                  if (originalFileName != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.subtitles_outlined,
                            color: onSurfaceColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              originalFileName!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: onSurfaceColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Show existing project path if available
            if (existingFilePath != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.folder_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Current Project Path",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The current project uses this file path:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file_outlined,
                            color: onSurfaceColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              existingFilePath!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: onSurfaceColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Show importing file path if available
            if (originalFilePath != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.folder_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Importing File Path",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The imported project references this file path:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? onSurfaceColor.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file_outlined,
                            color: onSurfaceColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              originalFilePath!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: onSurfaceColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 8),
            
            // Action Buttons
            Column(
              children: [
                if (existingFilePath != null) ...[
                  // Use Existing Project Path Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop('use_existing_project'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_tree, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Use Current Project Path",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (originalFilePath != null) ...[
                  // Use Importing File Path Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop('use_importing_file'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.download, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Use Importing File Path",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Select New File Button
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop('select_new'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Create New SRT File",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Cancel Button
                Container(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop('cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Cancel",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}
