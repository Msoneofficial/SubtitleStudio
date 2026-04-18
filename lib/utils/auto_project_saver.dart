import 'package:flutter/material.dart';
import 'package:subtitle_studio/utils/project_manager.dart';
import 'package:subtitle_studio/database/models/models.dart';

/// Auto Project Saver Mixin
/// 
/// This mixin provides automatic project saving functionality for widgets
/// that create or import subtitle data. It should be used on widgets that
/// handle subtitle import/creation workflows.
mixin AutoProjectSaver<T extends StatefulWidget> on State<T> {
  
  /// Auto-save project after subtitle data is created
  /// This should be called after successfully importing/creating subtitle data
  Future<void> autoSaveProject({
    required Session session,
    required SubtitleCollection subtitleCollection,
    String? suggestedFileName,
    bool showSnackbar = true,
  }) async {
    try {
      final projectPath = await ProjectManager.autoSaveProject(
        context: context,
        session: session,
        subtitleCollection: subtitleCollection,
        suggestedFileName: suggestedFileName,
      );

      if (projectPath != null) {
        // Update the session with the project file path
        await ProjectManager.updateSessionProjectPath(
          sessionId: session.id,
          projectFilePath: projectPath,
        );
        
        if (showSnackbar && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Project saved automatically'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  // Could show project location or open file manager
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Silently fail for auto-save - don't disrupt user workflow
      debugPrint('Auto-save project failed: $e');
    }
  }
  
  /// Prompt user to save project manually
  /// This can be used as a fallback if auto-save fails or is disabled
  Future<void> promptSaveProject({
    required Session session,
    required SubtitleCollection subtitleCollection,
  }) async {
    if (!mounted) return;
    
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Project'),
        content: const Text('Would you like to save this session as a project file (.msone)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (shouldSave == true && mounted) {
      final projectPath = await ProjectManager.saveProject(
        context: context,
        session: session,
        subtitleCollection: subtitleCollection,
        forceNewLocation: true,
      );
      
      if (projectPath != null) {
        await ProjectManager.updateSessionProjectPath(
          sessionId: session.id,
          projectFilePath: projectPath,
        );
      }
    }
  }
}

/// Project Creation Helper
/// 
/// Static helper methods for handling project creation in various workflows
class ProjectCreationHelper {
  
  /// Handle project creation after subtitle import/extraction
  /// This should be called from the UI after successful subtitle operations
  static Future<void> handleNewSubtitleProject({
    required BuildContext context,
    required Map<String, dynamic> subtitleData,
    String? suggestedFileName,
    bool autoSave = true,
  }) async {
    try {
      final session = subtitleData['session'] as Session?;
      final subtitleCollection = subtitleData['subtitleCollection'] as SubtitleCollection?;
      
      if (session == null || subtitleCollection == null) {
        debugPrint('Invalid subtitle data for project creation');
        return;
      }
      
      if (autoSave) {
        final projectPath = await ProjectManager.autoSaveProject(
          context: context,
          session: session,
          subtitleCollection: subtitleCollection,
          suggestedFileName: suggestedFileName,
        );
        
        if (projectPath != null) {
          await ProjectManager.updateSessionProjectPath(
            sessionId: session.id,
            projectFilePath: projectPath,
          );
        }
      }
    } catch (e) {
      debugPrint('Project creation helper error: $e');
      // Don't throw - this is optional functionality
    }
  }
  
  /// Create project data from session and subtitle collection IDs
  /// This is useful when you only have the IDs and need to create a project
  static Future<void> createProjectFromIds({
    required BuildContext context,
    required int sessionId,
    required int subtitleCollectionId,
    String? suggestedFileName,
  }) async {
    try {
      // This would need to fetch the data from database
      // Implementation depends on available database helper methods
      debugPrint('Create project from IDs: $sessionId, $subtitleCollectionId');
      // TODO: Implement when needed
    } catch (e) {
      debugPrint('Create project from IDs error: $e');
    }
  }
}
