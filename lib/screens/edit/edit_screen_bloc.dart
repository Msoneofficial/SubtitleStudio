import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subtitle_studio/screens/edit/edit_cubit.dart';
import 'package:subtitle_studio/screens/edit/edit_state.dart';
import 'package:subtitle_studio/screens/screen_edit.dart' as legacy;

/// BLoC-enabled wrapper for EditScreen
/// 
/// This widget provides a gradual migration path from the legacy StatefulWidget
/// to the new BLoC architecture. It wraps the existing EditScreen with BLoC
/// providers and state management.
/// 
/// Migration Strategy:
/// 1. This wrapper provides EditCubit to the widget tree
/// 2. The legacy _EditScreenState can access cubit via context.read<EditCubit>()
/// 3. Methods are gradually converted from setState to cubit calls
/// 4. Once all methods migrated, the legacy code can be removed
class EditScreenBloc extends StatelessWidget {
  final int subtitleCollectionId;
  final int? lastEditedIndex;
  final int sessionId;

  const EditScreenBloc({
    super.key,
    required this.subtitleCollectionId,
    this.lastEditedIndex,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditCubit(
        subtitleCollectionId: subtitleCollectionId,
        sessionId: sessionId,
      )..initialize(lastEditedIndex: lastEditedIndex),
      child: BlocConsumer<EditCubit, EditState>(
        listener: (context, state) {
          // Handle side effects here
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
            // Clear error after showing
            context.read<EditCubit>().clearError();
          }
        },
        builder: (context, state) {
          // Show loading state
          if (state.isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Loading...')),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Wrap legacy EditScreen with BLoC context
          // The legacy screen can now access EditCubit via context.read<EditCubit>()
          return legacy.EditScreen(
            subtitleCollectionId: subtitleCollectionId,
            lastEditedIndex: lastEditedIndex,
            sessionId: sessionId,
          );
        },
      ),
    );
  }
}
