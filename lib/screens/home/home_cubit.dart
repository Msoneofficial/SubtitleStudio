import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subtitle_studio/database/models/models.dart';
import 'package:subtitle_studio/database/models/preferences_model.dart';
import 'package:subtitle_studio/screens/home/home_state.dart';
import 'package:subtitle_studio/screens/home/repositories/session_repository.dart';
import 'package:subtitle_studio/utils/logging_helpers.dart';

/// Cubit for managing the Home Screen state
/// 
/// This Cubit encapsulates all business logic for the home screen,
/// following the BLoC pattern for state management. It communicates
/// with the SessionRepository to fetch and manipulate data.
/// 
/// Key Responsibilities:
/// - Load and manage recent sessions
/// - Handle search filtering
/// - Manage FAB expansion state
/// - Delete sessions
/// - Track last edited session
/// - Error handling and logging
/// 
/// State Flow:
/// 1. Initial loading state
/// 2. Emit loaded state with sessions
/// 3. Update state based on user actions (search, delete, FAB toggle)
/// 4. Emit error state on failures
class HomeCubit extends Cubit<HomeState> {
  final SessionRepository _repository;

  HomeCubit({SessionRepository? repository})
      : _repository = repository ?? SessionRepository.instance,
        super(HomeState.initial()) {
    logInfo('HomeCubit: Initialized');
  }

  /// Loads all sessions from the database
  /// 
  /// This method:
  /// 1. Sets loading state
  /// 2. Fetches sessions from repository
  /// 3. Identifies last edited session
  /// 4. Loads sort preference
  /// 5. Emits loaded state with data
  /// 
  /// Logs all operations and handles errors gracefully.
  Future<void> loadSessions() async {
    try {
      await logInfo('HomeCubit: Starting to load sessions');
      
      // Emit loading state
      emit(state.copyWith(isLoading: true, clearError: true));

      // Fetch sessions and last edited session ID
      final sessions = await _repository.fetchAllSessions();
      final lastEditedId = await _repository.getLastEditedSessionId();
      
      // Load sort preference
      final sortOption = await PreferencesModel.getSessionSortOption();

      await logInfo('HomeCubit: Fetched ${sessions.length} sessions, lastEditedId: $lastEditedId, sortOption: $sortOption');

      // Find the last edited session
      final lastEditedSession = _repository.findLastEditedSession(
        sessions,
        lastEditedId,
      );

      if (lastEditedSession != null) {
        await logInfo('HomeCubit: Last edited session: ${lastEditedSession.fileName}');
      } else {
        await logInfo('HomeCubit: No last edited session found');
      }

      // Emit loaded state
      emit(state.copyWith(
        isLoading: false,
        recentSessions: sessions,
        lastEditedSession: lastEditedSession,
        sortOption: sortOption,
        clearError: true,
      ));

      await logInfo('HomeCubit: Successfully loaded sessions');
    } catch (e, stackTrace) {
      await logError(
        'HomeCubit: Error loading sessions',
        context: 'loadSessions',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load sessions: $e',
      ));
    }
  }

  /// Updates the search query and filters sessions
  /// 
  /// Parameters:
  /// - [query]: Search string to filter sessions by filename
  void updateSearchQuery(String query) {
    logInfo('HomeCubit: Updating search query: "$query"');
    
    emit(state.copyWith(searchQuery: query));
  }

  /// Clears the search query
  void clearSearch() {
    logInfo('HomeCubit: Clearing search query');
    
    emit(state.copyWith(searchQuery: ''));
  }

  /// Changes the session sort option
  /// 
  /// Parameters:
  /// - [sortOption]: New sorting option to apply
  Future<void> changeSortOption(SessionSortOption sortOption) async {
    try {
      logInfo('HomeCubit: Changing sort option to: $sortOption');
      
      // Update state immediately for responsive UI
      emit(state.copyWith(sortOption: sortOption));
      
      // Persist the preference
      await PreferencesModel.setSessionSortOption(sortOption);
      
      logInfo('HomeCubit: Successfully changed sort option to: $sortOption');
    } catch (e, stackTrace) {
      await logError(
        'HomeCubit: Error changing sort option',
        context: 'changeSortOption',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't show error to user, preference will be loaded on next app start
    }
  }

  /// Toggles the custom FAB menu expansion state
  void toggleFabExpansion() {
    final newState = !state.isFabExpanded;
    
    logInfo('HomeCubit: Toggling FAB expansion to: $newState');
    
    emit(state.copyWith(isFabExpanded: newState));
  }

  /// Collapses the custom FAB menu
  void collapseFab() {
    if (state.isFabExpanded) {
      logInfo('HomeCubit: Collapsing FAB');
      emit(state.copyWith(isFabExpanded: false));
    }
  }

  /// Deletes a session and reloads the session list
  /// 
  /// Parameters:
  /// - [session]: Session to delete
  /// 
  /// This method:
  /// 1. Deletes the session via repository
  /// 2. Updates state to remove the session
  /// 3. Clears last edited if it was deleted
  /// 4. Logs the operation
  /// 
  /// Throws an exception if deletion fails.
  Future<void> deleteSession(Session session) async {
    try {
      await logInfo('HomeCubit: Deleting session: ${session.fileName}');

      // Delete from database
      await _repository.removeSession(session);

      // Update state
      final updatedSessions = List<Session>.from(state.recentSessions)
        ..removeWhere((s) => s.id == session.id);

      // Clear last edited if it was the deleted session
      final shouldClearLastEdited = state.lastEditedSession?.id == session.id;

      emit(state.copyWith(
        recentSessions: updatedSessions,
        clearLastEditedSession: shouldClearLastEdited,
        clearError: true,
      ));

      await logInfo('HomeCubit: Successfully deleted session: ${session.fileName}');
    } catch (e, stackTrace) {
      await logError(
        'HomeCubit: Error deleting session: ${session.fileName}',
        context: 'deleteSession',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        errorMessage: 'Failed to delete session: $e',
      ));

      rethrow; // Re-throw so UI can show error
    }
  }

  /// Updates the last edited session in database
  /// 
  /// Parameters:
  /// - [sessionId]: ID of the session to mark as last edited
  Future<void> updateLastEditedSession(int sessionId) async {
    try {
      await logInfo('HomeCubit: Updating last edited session to: $sessionId');

      await _repository.setLastEditedSession(sessionId);

      await logInfo('HomeCubit: Successfully updated last edited session');
    } catch (e, stackTrace) {
      await logError(
        'HomeCubit: Error updating last edited session',
        context: 'updateLastEditedSession',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't emit error state for this - it's not critical
    }
  }

  /// Gets comprehensive information about a session
  /// 
  /// Parameters:
  /// - [session]: Session to analyze
  /// 
  /// Returns a map with session statistics and metadata.
  Future<Map<String, dynamic>> getSessionInfo(Session session) async {
    try {
      return await _repository.getSessionInfo(session);
    } catch (e, stackTrace) {
      await logError(
        'HomeCubit: Error getting session info',
        context: 'getSessionInfo',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Return default values on error
      return {
        'totalLines': 0,
        'editedLines': 0,
        'lastEditedIndex': 1,
        'languageCodes': 'EN',
        'languages': ['EN'],
      };
    }
  }

  /// Checks if a session contains MSone subtitles
  /// 
  /// Parameters:
  /// - [session]: Session to check
  Future<bool> isMSoneSubtitle(Session session) async {
    try {
      return await _repository.isMSoneSubtitle(session);
    } catch (e, stackTrace) {
      await logError(
        'HomeCubit: Error checking MSone subtitle',
        context: 'isMSoneSubtitle',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Clears any error message from the state
  void clearError() {
    logInfo('HomeCubit: Clearing error message');
    emit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() {
    logInfo('HomeCubit: Closing');
    return super.close();
  }
}
