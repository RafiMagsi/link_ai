import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/managers/feed_video_preload_manager.dart';
import '../../../feed/data/models/post_model.dart';

class FeedHlsVideoPlayer extends StatefulWidget {
  const FeedHlsVideoPlayer({
    super.key,
    required this.media,
    required this.isActive,
    this.onVisibilityChanged,
    this.isFeedView = true,
    this.maxHeight,
  });

  final PostMediaModel media;
  final bool isActive;
  final ValueChanged<bool>? onVisibilityChanged;
  final bool isFeedView; // true = feed view (constrained), false = full view (no constraint)
  final double? maxHeight; // custom max height, only used if isFeedView=true

  @override
  State<FeedHlsVideoPlayer> createState() => _FeedHlsVideoPlayerState();
}

class _FeedHlsVideoPlayerState extends State<FeedHlsVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isVisible = false;
  bool _isMuted = true;

  FeedVideoPreloadManager get _manager => FeedVideoPreloadManager.instance;

  String get _videoUrl => widget.media.hlsUrl ?? widget.media.url;

  // Cache aspect ratio to prevent blinking
  double? _cachedAspectRatio;

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  @override
  void didUpdateWidget(covariant FeedHlsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.media.url != widget.media.url) {
      _controller = null;
      _cachedAspectRatio = null;
      _isLoading = true;
      _hasError = false;
      _attachController();
      return;
    }

    _syncPlayback();
  }

  Future<void> _attachController() async {
    try {
      final controller = await _manager.getOrCreate(_videoUrl);

      if (!mounted) return;

      // Calculate aspect ratio immediately when controller is ready
      double? aspectRatio;
      if (controller.value.isInitialized && _cachedAspectRatio == null) {
        aspectRatio = _calculateAspectRatio(controller);
      }

      setState(() {
        _controller = controller;
        _isLoading = false;
        // Set cached aspect ratio if calculated
        if (aspectRatio != null) {
          _cachedAspectRatio = aspectRatio;
        }
      });

      _syncPlayback();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  double _calculateAspectRatio(VideoPlayerController controller) {
    final aspectRatio = controller.value.aspectRatio;
    // Vertical video (< 1.0): keep original aspect ratio, max height 600
    // Landscape (>= 1.0): use 16:9 = 1.78
    if (aspectRatio < 1.0) {
      // Vertical video - keep original aspect ratio (will be constrained to 600px height)
      return aspectRatio;
    } else {
      // Landscape video - use 16:9
      return 16 / 9;
    }
  }

  void _syncPlayback() {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) return;

    // For feed view: keep playing when active (visibility changes don't stop playback)
    // For full view: respect visibility for active state
    final shouldPlay = widget.isFeedView ? widget.isActive : (widget.isActive && _isVisible);

    if (shouldPlay) {
      _manager.play(_videoUrl);
    }
    // Don't pause when invisible - controller might be used by ShortVideoViewerPage
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use cached aspect ratio or default to 9:16 for vertical videos
    final aspectRatio = _cachedAspectRatio ?? 9 / 16;

    return VisibilityDetector(
      key: ValueKey('feed-video-${widget.media.url}'),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction > 0.65;
        if (_isVisible == visible) return;

        _isVisible = visible;
        widget.onVisibilityChanged?.call(visible);

        // For feed videos: only report visibility, don't sync playback
        // (playback continues when navigating to nested pages)
        if (!widget.isFeedView) {
          _syncPlayback();
        }
      },
      child: widget.isFeedView
          ? SizedBox(
  height: widget.maxHeight ?? 600,
  width: double.infinity,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      fit: StackFit.expand,
      children: [
        _buildContent(),
        if (_isLoading)
          Container(
            color: Colors.black12,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        Positioned(
          right: 10,
          bottom: 10,
          child: _MuteBadge(
            isMuted: _isMuted,
            onToggle: _toggleMute,
          ),
        ),
      ],
    ),
  ),
)
          : AspectRatio(
              // In full view: full size, no constraint
              aspectRatio: aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildContent(),
                    if (_isLoading)
                      Container(
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: _MuteBadge(
                        isMuted: _isMuted,
                        onToggle: _toggleMute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildContent() {
    final controller = _controller;

    if (_hasError) {
      return Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.error_outline_rounded),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return Container(color: Colors.black);
    }

    final videoSize = controller.value.size;

    if (videoSize.width <= 0 || videoSize.height <= 0) {
      return Container(
        color: Colors.black,
        child: VideoPlayer(controller),
      );
    }

    return Container(
      color: Colors.black,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: videoSize.width,
            height: videoSize.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Controllers are managed by FeedVideoPreloadManager, not disposed here
    super.dispose();
  }
}

class _MuteBadge extends StatelessWidget {
  const _MuteBadge({
    required this.isMuted,
    required this.onToggle,
  });

  final bool isMuted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(999),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
