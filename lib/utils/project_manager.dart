import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/utils/platform_file_handler.dart';
import 'package:subtitle_studio/utils/file_picker_utils_saf.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/widgets/session_selection_sheet.dart';
import 'package:subtitle_studio/main.dart';
import 'package:subtitle_studio/services/checkpoint_manager.dart';

/// Project Manager for .msone files
/// 
/// This class handles all operations related to .msone project files:
/// - Auto-saving projects when importing/creating subtitles
/// - Manual project saving with user-selected locations
/// - Loading and updating existing projects
/// - Managing project metadata and versioning
class ProjectManager {
  static const String projectVersion = '2.0';
  
  /// Auto-save project file after importing/creating subtitles
  /// This is called automatically when new content is imported
  static Future<String?> autoSaveProject({
    required BuildContext context,
    required Session session,
    required SubtitleCollection subtitleCollection,
    String? suggestedFileName,
  }) async {
    try {
      final projectData = await _createProjectData(session, subtitleCollection);
      final fileName = (suggestedFileName ?? session.fileName)
          .replaceAll(RegExp(r'\.[^.]*$'), '') + '.msone';
      
      if (Platform.isAndroid) {
        return await _saveProjectWithSAF(
          context: context,
          projectData: projectData,
          fileName: fileName,
        );
      } else if (Platform.isIOS) {
        return await _saveProjectWithFilePicker(
          context: context,
          projectData: projectData,
          fileName: fileName,
        );
      } else {
        return await _saveProjectWithPicker(
          context: context,
          projectData: projectData,
          fileName: fileName,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Auto-save project error: $e');
      }
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Failed to save project: $e');
      }
      return null;
    }
  }
  
  /// Save project to existing location or prompt for new location
  static Future<String?> saveProject({
    required BuildContext context,
    required Session session,
    required SubtitleCollection subtitleCollection,
    bool forceNewLocation = false,
  }) async {
    try {
      final projectData = await _createProjectData(session, subtitleCollection);
      
      // If we have an existing project file path and not forcing new location
      if (!forceNewLocation && session.projectFilePath != null) {
        final success = await _updateExistingProject(
          projectFilePath: session.projectFilePath!,
          projectData: projectData,
        );
        
        if (success) {
          if (context.mounted) {
            SnackbarHelper.showSuccess(context, 'Project saved successfully!');
          }
          return session.projectFilePath;
        }
      }
      
      // Save to new location
      final fileName = session.fileName
          .replaceAll(RegExp(r'\.[^.]*$'), '') + '.msone';
      
      if (Platform.isAndroid) {
        return await _saveProjectWithSAF(
          context: context,
          projectData: projectData,
          fileName: fileName,
        );
      } else if (Platform.isIOS) {
        return await _saveProjectWithFilePicker(
          context: context,
          projectData: projectData,
          fileName: fileName,
        );
      } else {
        return await _saveProjectWithPicker(
          context: context,
          projectData: projectData,
          fileName: fileName,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Save project error: $e');
      }
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Failed to save project: $e');
      }
      return null;
    }
  }
  
  /// Create project data structure for .msone file
  static Future<Map<String, dynamic>> _createProjectData(
    Session session,
    SubtitleCollection subtitleCollection,
  ) async {
    // Fetch checkpoints for this session
    final checkpointsData = await _fetchCheckpoints(session.id);
    
    return {
      'version': projectVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'appVersion': '3.0.0', // You can get this from package_info
      'session': {
        'fileName': session.fileName,
        'lastEditedIndex': session.lastEditedIndex,
        'editMode': session.editMode,
        'projectFilePath': session.projectFilePath,
      },
      'subtitleCollection': {
        'fileName': subtitleCollection.fileName,
        'filePath': subtitleCollection.filePath,
        'originalFileUri': subtitleCollection.originalFileUri,
        'encoding': subtitleCollection.encoding,
        'lines': subtitleCollection.lines.map((line) => {
          'index': line.index,
          'startTime': line.startTime,
          'endTime': line.endTime,
          'original': line.original,
          'edited': line.edited,
          'marked': line.marked,
          'comment': line.comment,  // Include comment field
          'resolved': line.resolved, // Include resolved field
        }).toList(),
      },
      'checkpoints': checkpointsData,
      'metadata': {
        'totalLines': subtitleCollection.lines.length,
        'editedLines': subtitleCollection.lines.where((l) => 
          l.edited != null && l.edited!.isNotEmpty).length,
        'markedLines': subtitleCollection.lines.where((l) => l.marked).length,
        'lastSaved': DateTime.now().toIso8601String(),
      },
    };
  }
  
  /// Fetch checkpoints for a session
  static Future<List<Map<String, dynamic>>> _fetchCheckpoints(int sessionId) async {
    try {
      print('[ProjectManager] Fetching checkpoints for session $sessionId...');
      final checkpoints = await CheckpointManager.getCheckpointsForSession(sessionId);
      print('[ProjectManager] Found ${checkpoints.length} checkpoints for session $sessionId');
      
      if (checkpoints.isEmpty) {
        print('[ProjectManager] WARNING: No checkpoints found! Saving without checkpoint data.');
      }

      // Convert checkpoints to JSON-serializable format
      return checkpoints.map((checkpoint) {
        return {
          'sessionId': checkpoint.sessionId,
          'subtitleCollectionId': checkpoint.subtitleCollectionId,
          'timestamp': checkpoint.timestamp.toIso8601String(),
          'operationType': checkpoint.operationType,
          'description': checkpoint.description,
          'parentCheckpointId': checkpoint.parentCheckpointId,
          'isActive': checkpoint.isActive,
          'checkpointType': checkpoint.checkpointType,
          'metadata': checkpoint.metadata,
          'deltas': checkpoint.deltas.map((delta) => {
            'changeType': delta.changeType,
            'lineIndex': delta.lineIndex,
            'beforeState': delta.beforeState != null ? {
              'index': delta.beforeState!.index,
              'startTime': delta.beforeState!.startTime,
              'endTime': delta.beforeState!.endTime,
              'original': delta.beforeState!.original,
              'edited': delta.beforeState!.edited,
              'marked': delta.beforeState!.marked,
              'comment': delta.beforeState!.comment,
              'resolved': delta.beforeState!.resolved,
            } : null,
            'afterState': delta.afterState != null ? {
              'index': delta.afterState!.index,
              'startTime': delta.afterState!.startTime,
              'endTime': delta.afterState!.endTime,
              'original': delta.afterState!.original,
              'edited': delta.afterState!.edited,
              'marked': delta.afterState!.marked,
              'comment': delta.afterState!.comment,
              'resolved': delta.afterState!.resolved,
            } : null,
          }).toList(),
          'snapshot': checkpoint.snapshot.map((line) => {
            'index': line.index,
            'startTime': line.startTime,
            'endTime': line.endTime,
            'original': line.original,
            'edited': line.edited,
            'marked': line.marked,
            'comment': line.comment,
            'resolved': line.resolved,
          }).toList(),
        };
      }).toList();
    } catch (e) {
      print('[ProjectManager] Error fetching checkpoints: $e');
      return [];
    }
  }
  
  /// Save project using SAF (Android)
  static Future<String?> _saveProjectWithSAF({
    required BuildContext context,
    required Map<String, dynamic> projectData,
    required String fileName,
  }) async {
    try {
      final jsonString = jsonEncode(projectData);
      
      final fileInfo = await PlatformFileHandler.saveNewFile(
        content: jsonString,
        fileName: fileName,
        mimeType: 'application/octet-stream', // Use generic binary type for .msone files
      );
      
      if (fileInfo != null) {
        if (context.mounted) {
          SnackbarHelper.showSuccess(
            context, 
            'Project saved successfully!',
            duration: const Duration(seconds: 2),
          );
        }
        return fileInfo.safUri ?? fileInfo.path;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('SAF save error: $e');
      }
      rethrow;
    }
  }
  
  /// Save project using file picker (iOS)
  static Future<String?> _saveProjectWithFilePicker({
    required BuildContext context,
    required Map<String, dynamic> projectData,
    required String fileName,
  }) async {
    try {
      final jsonString = jsonEncode(projectData);
      final contentBytes = Uint8List.fromList(utf8.encode(jsonString));
      
      // Use file picker to save the file on iOS
      final result = await fp.FilePicker.platform.saveFile(
        dialogTitle: 'Save Project File',
        fileName: fileName,
        type: fp.FileType.custom,
        allowedExtensions: ['msone'],
        bytes: contentBytes,
      );
      
      if (result != null) {
        if (context.mounted) {
          SnackbarHelper.showSuccess(
            context, 
            'Project saved successfully!',
            duration: const Duration(seconds: 2),
          );
        }
        return result;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('iOS file picker save error: $e');
      }
      rethrow;
    }
  }
  
  /// Save project using file picker (Desktop)
  static Future<String?> _saveProjectWithPicker({
    required BuildContext context,
    required Map<String, dynamic> projectData,
    required String fileName,
  }) async {
    try {
      final selectedPath = await FilePickerConvenience.pickExportFolder(
        context: context,
      );
      
      if (selectedPath != null) {
        final filePath = '$selectedPath${Platform.pathSeparator}$fileName';
        final file = File(filePath);
        
        final jsonString = jsonEncode(projectData);
        await file.writeAsString(jsonString);
        
        if (context.mounted) {
          SnackbarHelper.showSuccess(
            context, 
            'Project saved to: $filePath',
            duration: const Duration(seconds: 3),
          );
        }
        return filePath;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('File picker save error: $e');
      }
      rethrow;
    }
  }
  
  /// Update existing project file
  static Future<bool> _updateExistingProject({
    required String projectFilePath,
    required Map<String, dynamic> projectData,
  }) async {
    try {
      final jsonString = jsonEncode(projectData);
      
      if (Platform.isAndroid && projectFilePath.startsWith('content://')) {
        // Use SAF to update existing file
        final success = await PlatformFileHandler.writeFile(
          content: jsonString,
          filePath: projectFilePath,
        );
        return success;
      } else if (Platform.isIOS) {
        // On iOS, we cannot write to arbitrary file paths due to sandbox restrictions
        // The file picker returns a path, but we don't have write access to it
        // Return false to trigger save to new location instead
        if (kDebugMode) {
          print('iOS: Cannot update existing project file directly. Will prompt for new location.');
        }
        return false;
      } else {
        // Direct file update for desktop
        final file = File(projectFilePath);
        await file.writeAsString(jsonString);
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update existing project error: $e');
      }
      return false;
    }
  }
  
  /// Update session with project file path
  static Future<void> updateSessionProjectPath({
    required int sessionId,
    required String projectFilePath,
  }) async {
    try {
      final session = await isar.sessions.get(sessionId);
      if (session != null) {
        session.projectFilePath = projectFilePath;
        await isar.writeTxn(() async {
          await isar.sessions.put(session);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update session project path error: $e');
      }
    }
  }
  
  /// Check if session has an associated project file
  static bool hasProjectFile(Session session) {
    return session.projectFilePath != null && 
           session.projectFilePath!.isNotEmpty;
  }
  
  /// Get user-friendly project file name
  static String getProjectFileName(Session session) {
    if (!hasProjectFile(session)) return 'Untitled Project';
    
    final path = session.projectFilePath!;
    if (Platform.isAndroid && path.startsWith('content://')) {
      // Extract filename from SAF URI (this might need refinement)
      return '${session.fileName.replaceAll(RegExp(r'\.[^.]*$'), '')}.msone';
    } else {
      return path.split(Platform.pathSeparator).last;
    }
  }
  
  /// Show session selection sheet for replacing import data or importing as new
  static Future<Session?> showSessionSelectionSheet({
    required BuildContext context,
    required Map<String, dynamic> projectData,
    String? originalFileUri,
    Function(Session)? onProjectImported,
  }) async {
    Session? resultSession;
    
    await showModalBottomSheet<Session>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SessionSelectionSheet(
          projectData: projectData,
          originalFileUri: originalFileUri,
          onSessionReplaced: (session) {
            resultSession = session;
          },
          onSessionCreated: (session) {
            resultSession = session;
          },
          onProjectImported: onProjectImported,
        );
      },
    );
    
    return resultSession;
  }
}

/// Actions for importing project files
enum ImportAction {
  importAsNew,
  cancel,
}
