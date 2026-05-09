import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../data/models/post_model.dart';
import '../../providers/post_providers.dart';

class PostMediaWidget extends ConsumerWidget {
  const PostMediaWidget({
    super.key,
    required this.mediaList,
    required this.postId,
    this.onDoubleTap,
    this.onTap,
  });

  final List<PostMediaModel> mediaList;
  final String postId;
  final VoidCallback? onDoubleTap;
  final Function(int)? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mediaList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Single media item
    if (mediaList.length == 1) {
      final media = mediaList.first;
      if (media.type == 'video') {
        return _VideoPlayerWidget(
          media: media,
          postId: postId,
          onDoubleTap: onDoubleTap,
          onTap: onTap == null ? null : () => onTap!.call(0),
        );
      }
      return GestureDetector(
        onDoubleTap: onDoubleTap,
        child: _ImageWidget(url: media.url),
      );
    }

    // Multiple media items - grid layout
    return _MediaGrid(mediaList: mediaList, postId: postId, onTap: onTap);
  }
}

class _ImageWidget extends StatelessWidget {
  const _ImageWidget({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator.adaptive()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );
  }
}

class _VideoPlayerWidget extends ConsumerStatefulWidget {
  const _VideoPlayerWidget({
    required this.media,
    required this.postId,
    this.onDoubleTap,
    this.onTap,
  });

  final PostMediaModel media;
  final String postId;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTap;

  @override
  ConsumerState<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _wasAutoPlaying = false;

  static const double _fallbackAspectRatio = 4 / 5;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.media.url))
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
            _VideoPlaceholder(thumbnailUrl: widget.media.thumbnailUrl),
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
        : _fallbackAspectRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: AspectRatio(aspectRatio: aspectRatio, child: child),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.mediaList, required this.postId, this.onTap});

  final List<PostMediaModel> mediaList;
  final String postId;
  final Function(int)? onTap;

  @override
  Widget build(BuildContext context) {
    final cols = mediaList.length <= 2 ? 2 : 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.0,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: List.generate(mediaList.length, (index) {
          final media = mediaList[index];
          return GestureDetector(
            onTap: () => onTap?.call(index),
            child: media.type == 'video'
                ? _VideoThumbnail(media: media)
                : _ImageGridItem(url: media.url),
          );
        }),
      ),
    );
  }
}

class _ImageGridItem extends StatelessWidget {
  const _ImageGridItem({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      errorWidget: (context, url, error) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.media});

  final PostMediaModel media;

  @override
  Widget build(BuildContext context) {
    if (media.thumbnailUrl != null && media.thumbnailUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: media.thumbnailUrl!,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            errorWidget: (context, url, error) => _buildFallback(context),
          ),
          _buildBadge(),
        ],
      );
    }

    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.videocam,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          _buildBadge(),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Positioned(
      bottom: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Text(
          'VIDEO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.thumbnailUrl});

  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
