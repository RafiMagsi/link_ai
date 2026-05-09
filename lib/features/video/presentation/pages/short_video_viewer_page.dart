import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../feed/data/models/post_model.dart';
import '../../../feed/presentation/providers/post_providers.dart';

class ShortVideoViewerPage extends ConsumerStatefulWidget {
  const ShortVideoViewerPage({super.key, required this.initialPost});

  final PostModel initialPost;

  @override
  ConsumerState<ShortVideoViewerPage> createState() =>
      _ShortVideoViewerPageState();
}

class _ShortVideoViewerPageState extends ConsumerState<ShortVideoViewerPage> {
  PageController? _pageController;
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(shortVideoFeedProvider(widget.initialPost));
    if (posts.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final desiredIndex = posts.indexWhere(
      (post) => post.id == widget.initialPost.id,
    );
    final safeInitialIndex = desiredIndex >= 0 ? desiredIndex : 0;

    if (_pageController == null) {
      _currentIndex = safeInitialIndex;
      _pageController = PageController(initialPage: safeInitialIndex);
    }

    final currentPost = posts[_currentIndex.clamp(0, posts.length - 1)];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            allowImplicitScrolling: true,
            itemCount: posts.length,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final post = posts[index];
              final selectedVideo = post.media.firstWhere(
                (media) => media.type == 'video',
                orElse: () => post.media.first,
              );

              return _ShortVideoPageItem(
                key: ValueKey(post.id),
                post: post,
                videoMedia: selectedVideo,
                isActive: index == _currentIndex,
                onCommentTap: () {
                  context.pop();
                  context.push('/posts/${post.detailPostId}', extra: post);
                },
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.26),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Spacer(),
                _VideoFeedPill(
                  icon: Icons.video_collection_outlined,
                  label: '${_currentIndex + 1}/${posts.length}',
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 68,
            right: 68,
            child: Center(
              child: _VideoFeedPill(
                icon: Icons.bolt,
                label: currentPost.postIntent.name.toUpperCase(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortVideoPageItem extends ConsumerStatefulWidget {
  const _ShortVideoPageItem({
    super.key,
    required this.post,
    required this.videoMedia,
    required this.isActive,
    required this.onCommentTap,
  });

  final PostModel post;
  final PostMediaModel videoMedia;
  final bool isActive;
  final VoidCallback onCommentTap;

  @override
  ConsumerState<_ShortVideoPageItem> createState() =>
      _ShortVideoPageItemState();
}

class _ShortVideoPageItemState extends ConsumerState<_ShortVideoPageItem> {
  late final VideoPlayerController _controller;
  bool _isReady = false;
  bool _showHud = true;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoMedia.url))
          ..setLooping(true)
          ..setVolume(1)
          ..addListener(_handleTick)
          ..initialize()
              .then((_) {
                if (!mounted) return;
                setState(() => _isReady = true);
                if (widget.isActive) {
                  _controller.play();
                }
              })
              .catchError((Object error) {
                debugPrint('Short video init failed: $error');
              });
  }

  @override
  void didUpdateWidget(covariant _ShortVideoPageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isReady) return;

    if (widget.isActive && !_controller.value.isPlaying) {
      _controller.play();
    } else if (!widget.isActive && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTick)
      ..dispose();
    super.dispose();
  }

  void _handleTick() {
    if (!mounted || !_isReady) return;
    setState(() {});
  }

  Future<void> _sharePost() async {
    await SharePlus.instance.share(
      ShareParams(text: 'linkai://posts/${widget.post.detailPostId}'),
    );
  }

  void _togglePlayback() {
    if (!_isReady) return;
    HapticFeedback.lightImpact();
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() => _showHud = true);
  }

  @override
  Widget build(BuildContext context) {
    final optimisticLiked = ref.watch(optimisticLikeProvider(widget.post.id));
    final optimisticSaved = ref.watch(optimisticSaveProvider(widget.post.id));
    final optimisticReposted = ref.watch(
      optimisticRepostProvider(widget.post.id),
    );
    final realState = ref
        .watch(postInteractionStateProvider(widget.post.id))
        .asData
        ?.value;
    final counts = ref.watch(optimisticPostCountProvider);
    final post = counts[widget.post.id] ?? widget.post;

    final liked = optimisticLiked ?? realState?.liked ?? false;
    final saved = optimisticSaved ?? realState?.saved ?? false;
    final reposted = optimisticReposted ?? realState?.reposted ?? false;
    final progress = _isReady && _controller.value.duration.inMilliseconds > 0
        ? (_controller.value.position.inMilliseconds /
                  _controller.value.duration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _showHud = !_showHud),
          onDoubleTap: () => ref
              .read(postControllerProvider.notifier)
              .toggleLike(post.id, post: post),
          child: _isReady
              ? FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : _ShortVideoThumbnail(
                  thumbnailUrl: widget.videoMedia.thumbnailUrl,
                ),
        ),
        if (_showHud) ...[
          Positioned(
            right: 12,
            bottom: 116,
            child: _ShortVideoActions(
              liked: liked,
              saved: saved,
              reposted: reposted,
              commentsCount: post.commentsCount,
              likesCount: post.likesCount,
              repostsCount: post.repostsCount,
              savesCount: post.savesCount,
              onLike: () => ref
                  .read(postControllerProvider.notifier)
                  .toggleLike(post.id, post: post),
              onComment: widget.onCommentTap,
              onRepost: () => ref
                  .read(postControllerProvider.notifier)
                  .toggleRepost(post.id, post: post),
              onSave: () => ref
                  .read(postControllerProvider.notifier)
                  .toggleSave(post.id, post: post),
              onShare: _sharePost,
            ),
          ),
          Positioned(
            left: 16,
            right: 90,
            bottom: 28,
            child: _ShortVideoCaption(
              post: post,
              isPlaying: _controller.value.isPlaying,
              progress: progress,
              onTogglePlayback: _togglePlayback,
            ),
          ),
        ],
      ],
    );
  }
}

class _ShortVideoThumbnail extends StatelessWidget {
  const _ShortVideoThumbnail({required this.thumbnailUrl});

  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator.adaptive()),
        ),
        errorWidget: (context, url, error) => _FallbackVideoSurface(),
      );
    }
    return const _FallbackVideoSurface();
  }
}

class _FallbackVideoSurface extends StatelessWidget {
  const _FallbackVideoSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 72, color: Colors.white70),
      ),
    );
  }
}

class _ShortVideoCaption extends StatelessWidget {
  const _ShortVideoCaption({
    required this.post,
    required this.isPlaying,
    required this.progress,
    required this.onTogglePlayback,
  });

  final PostModel post;
  final bool isPlaying;
  final double progress;
  final VoidCallback onTogglePlayback;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.72),
            Colors.black.withValues(alpha: 0.38),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _VideoFeedPill(
                  icon: Icons.schedule,
                  label: post.createdAt == null
                      ? 'Now'
                      : _relativeTime(post.createdAt!),
                ),
              ],
            ),
            if (post.authorRole.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                post.authorRole,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (post.text.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                post.text.trim(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.34,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: onTogglePlayback,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _ShortVideoActions extends StatelessWidget {
  const _ShortVideoActions({
    required this.liked,
    required this.saved,
    required this.reposted,
    required this.commentsCount,
    required this.likesCount,
    required this.repostsCount,
    required this.savesCount,
    required this.onLike,
    required this.onComment,
    required this.onRepost,
    required this.onSave,
    required this.onShare,
  });

  final bool liked;
  final bool saved;
  final bool reposted;
  final int commentsCount;
  final int likesCount;
  final int repostsCount;
  final int savesCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onRepost;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VideoSideAction(
          icon: liked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(likesCount),
          active: liked,
          onTap: onLike,
        ),
        const SizedBox(height: 14),
        _VideoSideAction(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(commentsCount),
          onTap: onComment,
        ),
        const SizedBox(height: 14),
        _VideoSideAction(
          icon: Icons.repeat,
          label: _formatCount(repostsCount),
          active: reposted,
          onTap: onRepost,
        ),
        const SizedBox(height: 14),
        _VideoSideAction(
          icon: saved ? Icons.bookmark : Icons.bookmark_border,
          label: _formatCount(savesCount),
          active: saved,
          onTap: onSave,
        ),
        const SizedBox(height: 14),
        _VideoSideAction(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: onShare,
        ),
      ],
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return value.toString();
  }
}

class _VideoSideAction extends StatelessWidget {
  const _VideoSideAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final accent = active
        ? Theme.of(context).colorScheme.primary
        : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoFeedPill extends StatelessWidget {
  const _VideoFeedPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
