import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../feed/data/models/post_model.dart';
import '../../../feed/presentation/providers/post_providers.dart';
import '../../core/managers/feed_video_preload_manager.dart';

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
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _showHud = true;

  @override
  void initState() {
    super.initState();
    // Hide system UI for full screen video
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final videoUrl = widget.videoMedia.hlsUrl ?? widget.videoMedia.url;
      final controller = await FeedVideoPreloadManager.instance.getOrCreate(videoUrl);

      if (!mounted) return;

      // Just add listener and mark as ready - don't change controller state
      controller.addListener(_handleTick);

      setState(() {
        _controller = controller;
        _isReady = true;
      });
    } catch (error) {
      if (mounted) {
        debugPrint('Short video init failed: $error');
      }
    }
  }

  @override
  void didUpdateWidget(covariant _ShortVideoPageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only manage playback if isActive state changed (swiping between videos)
    if (!_isReady || _controller == null) return;
    if (oldWidget.isActive == widget.isActive) return;

    // When becoming active, play the video
    if (widget.isActive && !_controller!.value.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller != null && !_controller!.value.isPlaying) {
          _controller!.play();
        }
      });
    }
    // When becoming inactive, pause the video
    else if (!widget.isActive && _controller!.value.isPlaying) {
      _controller!.pause();
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.removeListener(_handleTick);
    super.dispose();
  }

  void _handleTick() {
    if (!mounted || !_isReady) return;
    // Defer setState to avoid calling it during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _sharePost() async {
    await SharePlus.instance.share(
      ShareParams(text: 'linkai://posts/${widget.post.detailPostId}'),
    );
  }

  void _togglePlayback() {
    if (!_isReady || _controller == null) return;
    HapticFeedback.lightImpact();
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
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
    final progress = _isReady && _controller != null && _controller!.value.duration.inMilliseconds > 0
        ? (_controller!.value.position.inMilliseconds /
                  _controller!.value.duration.inMilliseconds)
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
          child: _isReady && _controller != null
              ? FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              : Container(color: Colors.black),
        ),
        if (_showHud) ...[
          Positioned(
            right: 12,
            bottom: 200,
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
          if (_controller != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: _ShortVideoCaption(
                  post: post,
                  isPlaying: _controller!.value.isPlaying,
                  progress: progress,
                  buffered: _controller!.value.buffered,
                  duration: _controller!.value.duration,
                  onTogglePlayback: _togglePlayback,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ShortVideoCaption extends StatelessWidget {
  const _ShortVideoCaption({
    required this.post,
    required this.isPlaying,
    required this.progress,
    required this.buffered,
    required this.duration,
    required this.onTogglePlayback,
  });

  final PostModel post;
  final bool isPlaying;
  final double progress;
  final List<DurationRange> buffered;
  final Duration duration;
  final VoidCallback onTogglePlayback;

  @override
  Widget build(BuildContext context) {
    final text = post.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.92),
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.65, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  '@${post.authorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (post.authorRole.isNotEmpty)
                Flexible(
                  child: Text(
                    post.authorRole,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white.withValues(alpha: 0.92),
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.createdAt == null
                      ? 'Now playing'
                      : 'Posted ${_relativeTime(post.createdAt!)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTogglePlayback,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background
                  Container(color: Colors.white.withValues(alpha: 0.12)),
                  // Buffered (white)
                  if (buffered.isNotEmpty && duration.inMilliseconds > 0)
                    FractionallySizedBox(
                      widthFactor: (buffered.last.end.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0),
                      child: Container(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  // Playing (blue)
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(color: const Color(0xFF3B82F6)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
    this.avatarUrl,
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
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VideoSideAction(
          icon: liked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(likesCount),
          active: liked,
          activeColor: const Color(0xFFFF2D55),
          onTap: onLike,
        ),
        const SizedBox(height: 12),
        _VideoSideAction(
          icon: Icons.chat_bubble,
          label: _formatCount(commentsCount),
          onTap: onComment,
        ),
        const SizedBox(height: 12),
        _VideoSideAction(
          icon: Icons.repeat_rounded,
          label: _formatCount(repostsCount),
          active: reposted,
          activeColor: const Color(0xFF22C55E),
          onTap: onRepost,
        ),
        const SizedBox(height: 12),
        _VideoSideAction(
          icon: saved ? Icons.bookmark : Icons.bookmark_border,
          label: _formatCount(savesCount),
          active: saved,
          activeColor: const Color(0xFFFFC83D),
          onTap: onSave,
        ),
        const SizedBox(height: 12),
        _VideoSideAction(
          icon: Icons.share,
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
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final accent = active
        ? (activeColor ?? Theme.of(context).colorScheme.primary)
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
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(icon, color: accent, size: 24),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
