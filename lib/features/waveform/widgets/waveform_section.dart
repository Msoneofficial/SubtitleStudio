import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:subtitle_studio/features/waveform/bloc/waveform_bloc.dart';
import 'package:subtitle_studio/features/waveform/bloc/waveform_event.dart';
import 'package:subtitle_studio/features/waveform/widgets/waveform_widget.dart';
import 'package:subtitle_studio/features/waveform/widgets/waveform_toolbar.dart';
import 'package:subtitle_studio/database/models/models.dart';

/// Waveform section for EditScreen - manages waveform display and controls
class WaveformSection extends StatelessWidget {
  final List<SubtitleLine> subtitles;
  final Duration? playbackPosition;
  final Function(Duration)? onSeek;
  final double height;
  final String? videoPath;

  const WaveformSection({
    Key? key,
    required this.subtitles,
    this.playbackPosition,
    this.onSeek,
    this.height = 180.0,
    this.videoPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WaveformBloc(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toolbar with controls
          WaveformToolbar(
            onLoadAudio: () => _handleLoadAudio(context),
          ),

          // Waveform visualization
          SizedBox(
            height: height,
            child: WaveformWidget(
              subtitles: subtitles,
              playbackPosition: playbackPosition,
              onSeek: onSeek,
              height: height,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLoadAudio(BuildContext context) async {
    try {
      // Pick audio file
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac', 'mp4', 'mkv', 'avi', 'mov'],
        dialogTitle: 'Select audio/video file for waveform',
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      // Load audio into waveform
      if (!context.mounted) return;
      context.read<WaveformBloc>().add(LoadAudioFile(filePath));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
