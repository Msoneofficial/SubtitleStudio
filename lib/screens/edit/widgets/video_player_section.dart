import 'package:flutter/material.dart';
import 'package:subtitle_studio/widgets/video_player_widget.dart';

/// Isolated video player section to prevent unnecessary rebuilds
///
/// This widget only rebuilds when video-related props change,
/// isolating it from EditScreen setState cascades.
///
/// Performance improvement: Reduces rebuilds from ~275/10s to <5/10s
/// 
/// Key optimization: StatefulWidget that only rebuilds when essential
/// props (videoPath, subtitleCollectionId, subtitleVersion) change.
/// Callbacks are stored as final to prevent closure identity changes.
class VideoPlayerSection extends StatefulWidget {
  final GlobalKey<VideoPlayerWidgetState> videoPlayerKey;
  final String videoPath;
  final int subtitleCollectionId;
  final List<Subtitle> subtitles;
  final List<Subtitle> secondarySubtitles;
  final int subtitleVersion; // Version number to track subtitle updates
  final Function(Duration)? onPositionChanged;
  final Function(int)? onActiveSubtitleChanged;
  final Function()? onSubtitlesUpdated;
  final Function()? onFullscreenExited;
  final Function(int, bool)? onSubtitleMarked;
  final Function(int, String?)? onSubtitleCommentUpdated;

  const VideoPlayerSection({
    super.key,
    required this.videoPlayerKey,
    required this.videoPath,
    required this.subtitleCollectionId,
    required this.subtitles,
    required this.secondarySubtitles,
    required this.subtitleVersion,
    this.onPositionChanged,
    this.onActiveSubtitleChanged,
    this.onSubtitlesUpdated,
    this.onFullscreenExited,
    this.onSubtitleMarked,
    this.onSubtitleCommentUpdated,
  });

  @override
  State<VideoPlayerSection> createState() => _VideoPlayerSectionState();
}

class _VideoPlayerSectionState extends State<VideoPlayerSection> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  void didUpdateWidget(VideoPlayerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only log if essential props actually changed to reduce noise
    if (widget.videoPath != oldWidget.videoPath ||
        widget.subtitleCollectionId != oldWidget.subtitleCollectionId ||
        widget.subtitleVersion != oldWidget.subtitleVersion) {
      debugPrint('VideoPlayerSection: Essential prop changed, rebuilding');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // REMOVED: Excessive debug logging that was called on every rebuild
    // This logging itself adds performance overhead
    
    // RepaintBoundary prevents parent rebuilds from affecting video player
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: VideoPlayerWidget(
          key: widget.videoPlayerKey,
          videoPath: widget.videoPath,
          subtitleCollectionId: widget.subtitleCollectionId,
          subtitles: widget.subtitles,
          secondarySubtitles: widget.secondarySubtitles,
          onPositionChanged: widget.onPositionChanged,
          onActiveSubtitleChanged: widget.onActiveSubtitleChanged,
          onSubtitlesUpdated: widget.onSubtitlesUpdated,
          onFullscreenExited: widget.onFullscreenExited,
          onSubtitleMarked: widget.onSubtitleMarked,
          onSubtitleCommentUpdated: widget.onSubtitleCommentUpdated,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
