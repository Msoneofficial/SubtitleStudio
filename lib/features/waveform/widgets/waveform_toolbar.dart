import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subtitle_studio/features/waveform/bloc/waveform_bloc.dart';
import 'package:subtitle_studio/features/waveform/bloc/waveform_state.dart';
import 'package:subtitle_studio/features/waveform/bloc/waveform_event.dart';

/// Toolbar widget for waveform controls
class WaveformToolbar extends StatelessWidget {
  final VoidCallback onLoadAudio;

  const WaveformToolbar({
    Key? key,
    required this.onLoadAudio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaveformBloc, WaveformState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              // Load Audio Button
              _buildLoadButton(context, state),

              const SizedBox(width: 8),

              // Zoom Controls
              if (state is WaveformReady) ...[
                const VerticalDivider(),
                const SizedBox(width: 8),
                _buildZoomControls(context, state),
                const SizedBox(width: 8),
                const VerticalDivider(),
                const SizedBox(width: 8),
                _buildAutoScrollToggle(context, state),
                const Spacer(),
                _buildInfoDisplay(context, state),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadButton(BuildContext context, WaveformState state) {
    final isLoading = state is WaveformLoading;

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onLoadAudio,
      icon: Icon(
        isLoading ? Icons.hourglass_empty : Icons.audio_file,
        size: 18,
      ),
      label: Text(
        isLoading ? 'Loading...' : 'Load Audio',
        style: const TextStyle(fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context, WaveformReady state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom Out (+ button for less detail)
        IconButton(
          onPressed: state.canZoomOut
              ? () => context.read<WaveformBloc>().add(const ZoomOut())
              : null,
          icon: const Icon(Icons.remove),
          tooltip: 'Zoom Out',
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),

        // Zoom Level Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${state.currentZoomIndex + 1}/${state.buffer.zoomLevelCount}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),

        // Zoom In (- button for more detail)
        IconButton(
          onPressed: state.canZoomIn
              ? () => context.read<WaveformBloc>().add(const ZoomIn())
              : null,
          icon: const Icon(Icons.add),
          tooltip: 'Zoom In',
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoScrollToggle(BuildContext context, WaveformReady state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: state.autoScroll,
          onChanged: (_) =>
              context.read<WaveformBloc>().add(const ToggleAutoScroll()),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        Text(
          'Auto-scroll',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildInfoDisplay(BuildContext context, WaveformReady state) {
    final duration = state.buffer.duration;
    final durationText = _formatDuration(duration);
    final samplesPerPixel = state.samplesPerPixel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            '$durationText • ${samplesPerPixel} samp/px',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
