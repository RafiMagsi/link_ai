import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/managers/feed_video_preload_manager.dart';
import '../../data/models/video_model.dart';

class FeedHlsVideoPlayer extends StatefulWidget {
  const FeedHlsVideoPlayer({
    super.key,
    required this.video,
    required this.isActive,
    required this.isVisible,
    this.onVisibilityChanged,
  });

  final VideoModel video;
  final bool isActive;
  final bool isVisible;
  final ValueChanged<bool>? onVisibilityChanged;

  @override
  State<FeedHlsVideoPlayer> createState() => _FeedHlsVideoPlayerState();
}

class _FeedHlsVideoPlayerState extends State<FeedHlsVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  FeedVideoPreloadManager get _manager => FeedVideoPreloadManager.instance;

  String get _videoUrl => widget.video.hlsUrl ?? widget.video.url;

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  @override
  void didUpdateWidget(covariant FeedHlsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.video.url != widget.video.url) {
      _controller = null;
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

      setState(() {
        _controller = controller;
        _isLoading = false;
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

  void _syncPlayback() {
    final shouldPlay = widget.isActive && widget.isVisible;
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) return;

    if (shouldPlay) {
      _manager.play(_videoUrl);
    } else {
      _manager.pause(_videoUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildContent(),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            const Positioned(
              right: 10,
              bottom: 10,
              child: _MuteBadge(),
            ),
          ],
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
      return _buildThumbnail();
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildThumbnail() {
    final thumbnailUrl = widget.video.thumbnailUrl;

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: Colors.black12),
      );
    }

    return Container(color: Colors.black12);
  }

  @override
  void dispose() {
    // Controllers are managed by FeedVideoPreloadManager, not disposed here
    super.dispose();
  }
}

class _MuteBadge extends StatelessWidget {
  const _MuteBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.all(7),
        child: Icon(
          Icons.volume_off_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
