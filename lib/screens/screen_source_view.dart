// Source View Screen for Subtitle Studio v3
//
// This screen provides a classic text editor interface for directly editing SRT files
// without database operations. It allows users to:
// - Edit the complete file content as plain text
// - Modify index numbers, time codes, and text content freely
// - Save changes directly to the original file location with proper encoding detection
// - Use standard text editor functionality
//
// Key Features:
// - Full text editing capabilities like a standard text editor
// - Automatic encoding detection and preservation
// - Direct file saving without database operations
// - Material Design interface with proper theming
// - Save button in app bar menu
// - BLoC pattern for state management and performance optimization
// - Enhanced scrollbar with increased thumb width (12px)
//
// Architecture:
// - BLoC pattern with SourceViewCubit for state management
// - Optimized widget rebuilding and performance
// - Separation of concerns between UI and business logic
// - Clean architecture with immutable state objects

// Re-export the BLoC implementation as the main SourceViewScreen
export 'package:subtitle_studio/screens/source_view/source_view_screen_bloc.dart' show SourceViewScreenBloc;

// Maintain backward compatibility by aliasing the BLoC implementation
import 'package:subtitle_studio/screens/source_view/source_view_screen_bloc.dart' as bloc;

/// Legacy SourceViewScreen that redirects to the BLoC implementation
/// 
/// This ensures backward compatibility while using the new BLoC architecture.
/// All existing code that imports SourceViewScreen will now get the BLoC version.
/// 
/// Performance improvements implemented:
/// - BLoC pattern for efficient state management
/// - Optimized ListView.builder with proper item keys
/// - Enhanced scrollbar with 12px thumb width and rounded corners
/// - Const constructors throughout the widget tree
/// - Separation of concerns for better maintainability
class SourceViewScreen extends bloc.SourceViewScreenBloc {
  const SourceViewScreen({
    super.key,
    required super.filePath,
    super.displayName,
    super.safUri,
    super.fileContent,
  });
}