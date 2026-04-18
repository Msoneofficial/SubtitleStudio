import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:subtitle_studio/screens/edit_line/edit_line_cubit.dart';
import 'package:subtitle_studio/screens/edit_line/edit_line_state.dart';
import 'package:subtitle_studio/screens/screen_edit_line.dart' as legacy;
import 'package:subtitle_studio/utils/subtitle_parser.dart';

/// BLoC-enabled wrapper for EditSubtitleScreen
/// 
/// This widget provides a gradual migration path from the legacy StatefulWidget
/// to the new BLoC architecture. It wraps the existing EditSubtitleScreen with BLoC
/// providers and state management.
/// 
/// Migration Strategy:
/// 1. This wrapper provides EditLineCubit to the widget tree
/// 2. The legacy _EditSubtitleScreenState can access cubit via context.read<EditLineCubit>()
/// 3. Methods are gradually converted from setState to cubit calls
/// 4. Once all methods migrated, the legacy code can be removed
/// 
/// Usage:
/// ```dart
/// // Instead of:
/// EditSubtitleScreen(subtitleId: id, index: index, sessionId: session)
/// 
/// // Use:
/// EditSubtitleScreenBloc(subtitleId: id, index: index, sessionId: session)
/// ```
class EditSubtitleScreenBloc extends StatelessWidget {
  final Id subtitleId;
  final int index;
  final int sessionId;
  final bool isNewSubtitle;
  final bool editMode;
  final String? videoPath;
  final bool isVideoLoaded;
  final Duration? startVideoPosition;
  final List<SimpleSubtitleLine>? secondarySubtitles;

  const EditSubtitleScreenBloc({
    super.key,
    required this.subtitleId,
    required this.index,
    required this.sessionId,
    this.isNewSubtitle = false,
    this.editMode = false,
    this.videoPath,
    this.isVideoLoaded = false,
    this.startVideoPosition,
    this.secondarySubtitles,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditLineCubit(
        subtitleCollectionId: subtitleId,
        lineIndex: index,
        sessionId: sessionId,
        isNewSubtitle: isNewSubtitle,
        isEditMode: editMode,
        videoPath: videoPath,
        isVideoLoaded: isVideoLoaded,
        secondarySubtitles: secondarySubtitles,
      )..initialize(),
      child: BlocConsumer<EditLineCubit, EditLineState>(
        listener: (context, state) {
          // Handle side effects here
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
            // Clear error after showing
            context.read<EditLineCubit>().clearError();
          }
        },
        builder: (context, state) {
          // Show loading state during initialization
          if (state.isLoading && !state.isInitialized) {
            return Scaffold(
              appBar: AppBar(
                title: Text(isNewSubtitle ? 'New Subtitle' : 'Loading...'),
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading subtitle...'),
                  ],
                ),
              ),
            );
          }

          // Wrap legacy EditSubtitleScreen with BLoC context
          // The legacy screen can now access EditLineCubit via context.read<EditLineCubit>()
          // and gradually migrate features to use the cubit
          return legacy.EditSubtitleScreen(
            subtitleId: subtitleId,
            index: index,
            sessionId: sessionId,
            isNewSubtitle: isNewSubtitle,
            editMode: editMode,
            videoPath: videoPath,
            isVideoLoaded: isVideoLoaded,
            startVideoPosition: startVideoPosition,
            secondarySubtitles: secondarySubtitles,
          );
        },
      ),
    );
  }
}
