import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subtitle_studio/screens/source_view/source_view_cubit.dart';
import 'package:subtitle_studio/screens/source_view/source_view_state.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';
import 'package:subtitle_studio/utils/unicode_text_input_formatter.dart';

/// BLoC-enabled wrapper for SourceViewScreen
/// 
/// This widget provides the BLoC architecture for the source view screen,
/// managing state through SourceViewCubit and handling side effects
/// like error messages and save notifications.
/// 
/// Features:
/// - Automatic state management with BLoC pattern
/// - Error handling with user-friendly messages
/// - Save operation feedback
/// - Performance optimizations with proper widget rebuilding
class SourceViewScreenBloc extends StatelessWidget {
  /// Path to the SRT file to be displayed and edited
  final String filePath;
  
  /// Optional display name for the file (used in app bar title)
  final String? displayName;
  
  /// SAF URI for Android file operations (required for SAF files)
  final String? safUri;
  
  /// Optional pre-loaded file content (used when file is already read via SAF)
  final String? fileContent;

  const SourceViewScreenBloc({
    super.key,
    required this.filePath,
    this.displayName,
    this.safUri,
    this.fileContent,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SourceViewCubit(
        filePath: filePath,
        displayName: displayName,
        safUri: safUri,
        fileContent: fileContent,
      ),
      child: BlocConsumer<SourceViewCubit, SourceViewState>(
        listener: (context, state) {
          // Handle error messages
          if (state.errorMessage != null) {
            SnackbarHelper.showError(context, state.errorMessage!);
            context.read<SourceViewCubit>().clearMessages();
          }
          
          // Handle save messages
          if (state.saveMessage != null) {
            if (state.saveSuccessful) {
              if (state.saveMessage!.contains('cache')) {
                // Enhanced message for cache saves with Save As option
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.saveMessage!),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            context.read<SourceViewCubit>().saveAsFile();
                          },
                          child: const Text(
                            'Tap here to save to a new location ➤',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.orange[700],
                    duration: const Duration(seconds: 8),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                SnackbarHelper.showSuccess(context, state.saveMessage!);
              }
            } else {
              SnackbarHelper.showError(context, state.saveMessage!);
            }
            context.read<SourceViewCubit>().clearMessages();
          }
        },
        builder: (context, state) {
          return _SourceViewWidget(state: state);
        },
      ),
    );
  }
}

/// The actual source view widget implementation
/// 
/// This widget is separated from the BLoC wrapper to optimize rebuilds
/// and provide better performance. It uses const constructors where possible
/// and implements efficient ListView building.
class _SourceViewWidget extends StatelessWidget {
  final SourceViewState state;
  
  const _SourceViewWidget({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop(context);
        if (shouldPop && context.mounted) {
          navigator.pop();
        }
      },
      child: _SourceViewShortcuts(
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          resizeToAvoidBottomInset: true,
          appBar: _buildAppBar(context),
          body: _buildBody(context),
        ),
      ),
    );
  }

  /// Build the app bar with save functionality
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      iconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Source View',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            state.displayFileName,
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.save,
            color: state.hasUnsavedChanges 
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: 'Save Options',
          enabled: !state.isSaving,
          onSelected: (String value) {
            final cubit = context.read<SourceViewCubit>();
            switch (value) {
              case 'save':
                cubit.saveFile();
                break;
              case 'saveAs':
                cubit.saveAsFile();
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'save',
              child: Row(
                children: [
                  Icon(Icons.save),
                  SizedBox(width: 8),
                  Text('Save (Ctrl+S)'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'saveAs',
              child: Row(
                children: [
                  Icon(Icons.save_as),
                  SizedBox(width: 8),
                  Text('Save As...'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build the main body content based on current state
  Widget _buildBody(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading file...'),
          ],
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<SourceViewCubit>().reloadFile(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Main content with optimized ListView
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _OptimizedSubtitleList(
        subtitleEntries: state.subtitleEntries,
      ),
    );
  }

  /// Handle back navigation with unsaved changes check
  Future<bool> _onWillPop(BuildContext context) async {
    if (!state.hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Discard',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              context.read<SourceViewCubit>().saveFile();
              if (context.mounted) {
                navigator.pop(true);
              }
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }
}

/// Keyboard shortcuts widget for save functionality
class _SourceViewShortcuts extends StatelessWidget {
  final Widget child;
  
  const _SourceViewShortcuts({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): const _SaveIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_SaveIntent intent) {
              context.read<SourceViewCubit>().saveFile();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: false,
          child: child,
        ),
      ),
    );
  }
}

/// Intent class for save keyboard shortcut
class _SaveIntent extends Intent {
  const _SaveIntent();
}

/// Optimized subtitle list with performance improvements (matching EditScreen performance)
class _OptimizedSubtitleList extends StatefulWidget {
  final List<SubtitleEntry> subtitleEntries;
  
  const _OptimizedSubtitleList({
    required this.subtitleEntries,
  });

  @override
  State<_OptimizedSubtitleList> createState() => _OptimizedSubtitleListState();
}

class _OptimizedSubtitleListState extends State<_OptimizedSubtitleList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      thickness: 12.0, // Increased thumb width for better usability
      radius: const Radius.circular(6.0), // Rounded scrollbar for modern look
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        itemCount: widget.subtitleEntries.length,
        // Simple ListView.builder like EditScreen - no complex optimizations
        itemBuilder: (context, index) {
          return _SimpleSubtitleTile(
            entry: widget.subtitleEntries[index],
            index: index,
          );
        },
      ),
    );
  }
}

/// Simple subtitle tile widget for editing (matching EditScreen performance)
/// 
/// This widget represents a single subtitle entry with editable fields
/// for index, timecodes, and text. Uses direct object mutation for best performance
/// like EditScreen, avoiding complex BLoC updates on every keystroke.
class _SimpleSubtitleTile extends StatelessWidget {
  final SubtitleEntry entry;
  final int index;
  
  const _SimpleSubtitleTile({
    required this.entry,
    required this.index,
  });

  /// Notify BLoC that content has changed (called only when needed)
  void _onSourceViewContentChanged(BuildContext context) {
    context.read<SourceViewCubit>().markContentChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index number (editable)
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: entry.index,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                entry.index = value;
                _onSourceViewContentChanged(context);
              },
            ),
          ),
          const SizedBox(height: 4),
          // Timecode line (editable)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start time
              IntrinsicWidth(
                child: TextFormField(
                  initialValue: entry.startTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    entry.startTime = value;
                    _onSourceViewContentChanged(context);
                  },
                ),
              ),
              Text(
                ' --> ',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontFamily: 'monospace',
                ),
              ),
              // End time
              IntrinsicWidth(
                child: TextFormField(
                  initialValue: entry.endTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    entry.endTime = value;
                    _onSourceViewContentChanged(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Subtitle text (editable, multiline)
          TextFormField(
            initialValue: entry.text,
            maxLines: null,
            inputFormatters: [
              UnicodeTextInputFormatter(),
            ],
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              entry.text = value;
              _onSourceViewContentChanged(context);
            },
          ),
          const SizedBox(height: 16), // Space between entries like in SRT format
        ],
      ),
    );
  }
}