import 'package:equatable/equatable.dart';
import '../../database/models/models.dart';

/// Represents the state of the Home Screen
/// 
/// This is an immutable state class that uses Equatable for value equality.
/// The state is managed by HomeCubit and drives the UI rendering.
/// 
/// State Properties:
/// - [isLoading]: Whether the screen is in loading state
/// - [recentSessions]: List of all sessions from database
/// - [lastEditedSession]: The most recently edited session
/// - [searchQuery]: Current search filter text
/// - [isFabExpanded]: Whether the custom FAB menu is expanded
/// - [sortOption]: Current sorting option for sessions
/// - [errorMessage]: Error message to display to user (if any)
/// 
/// State Flow:
/// 1. Initial state: loading = true, empty sessions
/// 2. Loaded state: loading = false, sessions populated
/// 3. Error state: loading = false, errorMessage set
class HomeState extends Equatable {
  final bool isLoading;
  final List<Session> recentSessions;
  final Session? lastEditedSession;
  final String searchQuery;
  final bool isFabExpanded;
  final SessionSortOption sortOption;
  final String? errorMessage;

  const HomeState({
    this.isLoading = true,
    this.recentSessions = const [],
    this.lastEditedSession,
    this.searchQuery = '',
    this.isFabExpanded = false,
    this.sortOption = SessionSortOption.lastOpened,
    this.errorMessage,
  });

  /// Initial state when screen is first created
  factory HomeState.initial() => const HomeState(
        isLoading: true,
        recentSessions: [],
        lastEditedSession: null,
        searchQuery: '',
        isFabExpanded: false,
        sortOption: SessionSortOption.lastOpened,
        errorMessage: null,
      );

  /// Creates a copy of this state with optional field overrides
  HomeState copyWith({
    bool? isLoading,
    List<Session>? recentSessions,
    Session? lastEditedSession,
    String? searchQuery,
    bool? isFabExpanded,
    SessionSortOption? sortOption,
    String? errorMessage,
    bool clearLastEditedSession = false,
    bool clearError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      recentSessions: recentSessions ?? this.recentSessions,
      lastEditedSession: clearLastEditedSession
          ? null
          : (lastEditedSession ?? this.lastEditedSession),
      searchQuery: searchQuery ?? this.searchQuery,
      isFabExpanded: isFabExpanded ?? this.isFabExpanded,
      sortOption: sortOption ?? this.sortOption,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// Returns filtered sessions based on search query
  /// 
  /// Filters by case-insensitive substring match on fileName.
  /// Sorts results based on the selected sort option.
  List<Session> get filteredSessions {
    List<Session> sessions;
    
    if (searchQuery.isEmpty) {
      sessions = List.from(recentSessions);
    } else {
      sessions = recentSessions
          .where((session) =>
              session.fileName.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Apply sorting based on selected option
    switch (sortOption) {
      case SessionSortOption.lastOpened:
        // Sort by last edited session, with most recent at the top
        if (lastEditedSession != null) {
          sessions.sort((a, b) {
            if (lastEditedSession!.id == a.id) return -1;
            if (lastEditedSession!.id == b.id) return 1;
            return 0;
          });
        }
        break;
        
      case SessionSortOption.lastCreated:
        // Already in reverse chronological order (newest first) from database
        // No additional sorting needed as database returns in this order
        break;
        
      case SessionSortOption.name:
        // Sort alphabetically by file name (A-Z)
        sessions.sort((a, b) => 
          a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
        break;
        
      case SessionSortOption.nameDesc:
        // Sort reverse alphabetically by file name (Z-A)
        sessions.sort((a, b) => 
          b.fileName.toLowerCase().compareTo(a.fileName.toLowerCase()));
        break;
    }

    return sessions;
  }

  /// Whether the screen has sessions to display
  bool get hasSessions => recentSessions.isNotEmpty;

  /// Whether there's an active search with no results
  bool get hasNoSearchResults =>
      searchQuery.isNotEmpty && filteredSessions.isEmpty;

  @override
  List<Object?> get props => [
        isLoading,
        recentSessions,
        lastEditedSession,
        searchQuery,
        isFabExpanded,
        sortOption,
        errorMessage,
      ];

  @override
  String toString() {
    return 'HomeState(isLoading: $isLoading, '
        'sessionsCount: ${recentSessions.length}, '
        'lastEditedSession: ${lastEditedSession?.fileName}, '
        'searchQuery: "$searchQuery", '
        'isFabExpanded: $isFabExpanded, '
        'sortOption: $sortOption, '
        'hasError: ${errorMessage != null})';
  }
}
