import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../video/data/models/video_model.dart';
import '../providers/video_providers.dart';

class VideoPlayerWidget extends ConsumerStatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.video,
    required this.postId,
    this.onDoubleTap,
    this.onTap,
    this.borderRadius = 12.0,
    this.aspectRatio = 4 / 5,
  });

  final VideoModel video;
  final String postId;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTap;
  final double borderRadius;
  final double aspectRatio;

  @override
  ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _wasAutoPlaying = false;

  String get _videoUrl => widget.video.hlsUrl ?? widget.video.url;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(_videoUrl))
      ..addListener(_handleTick)
      ..initialize()
          .then((_) {
            setState(() {
              _isInitialized = true;
            });
          })
          .catchError((error) {
            debugPrint('Error initializing video: $error');
          });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTick);
    _controller.dispose();
    super.dispose();
  }

  void _handleTick() {
    if (!mounted || !_isInitialized) return;
    setState(() {});
  }

  void _setAutoPlayState(bool shouldAutoPlay) {
    if (shouldAutoPlay && !_isPlaying) {
      _controller.setVolume(0);
      _controller.play();
      setState(() {
        _isPlaying = true;
        _wasAutoPlaying = true;
      });
    } else if (!shouldAutoPlay && _wasAutoPlaying) {
      _controller.pause();
      _controller.seekTo(Duration.zero);
      setState(() {
        _isPlaying = false;
        _wasAutoPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVideoPostId = ref.watch(activeVideoPostIdProvider);
    final shouldAutoPlay = activeVideoPostId == widget.postId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setAutoPlayState(shouldAutoPlay);
    });

    if (!_isInitialized) {
      return _buildFramedVideo(
        context,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _VideoPlaceholder(thumbnailUrl: widget.video.thumbnailUrl),
            const Center(child: CircularProgressIndicator.adaptive()),
          ],
        ),
      );
    }

    return _buildFramedVideo(
      context,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
            if (!_isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            if (_isPlaying)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPlaying = false;
                      _wasAutoPlaying = false;
                      _controller.pause();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.pause,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFramedVideo(BuildContext context, {required Widget child}) {
    final aspectRatio = _isInitialized && _controller.value.aspectRatio > 0
        ? _controller.value.aspectRatio
        : widget.aspectRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AspectRatio(aspectRatio: aspectRatio, child: child),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.thumbnailUrl});

  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return Image.network(
        thumbnailUrl!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
