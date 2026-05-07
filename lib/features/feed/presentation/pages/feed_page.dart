import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../../../core/widgets/skeleton_post_card.dart';
import '../../../../core/widgets/retry_error_widget.dart';
import '../../../../core/errors/error_handler.dart';
import '../../data/models/post_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../connect/presentation/providers/connect_providers.dart';
import '../providers/post_providers.dart' show latestPostsProvider, connectedPostsProvider, viralPostsProvider, latestFeedProvider, connectedFeedProvider, viralFeedProvider, PaginatedPostsState, activeVideoPostIdProvider;
import '../widgets/feed_post_card.dart';
import 'create_post_page.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    // Header collapse: 0 offset = expanded (50), fully hidden after ~60px scroll
    final headerCollapseFraction = (_scrollOffset / 30).clamp(0.0, 3.0);
    final headerHeight = (50.0 - (20 * headerCollapseFraction)).clamp(0.0, 50.0);
    final titleOpacity = (1 - headerCollapseFraction).clamp(0.0, 1.0);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButton: _CreatePostFabButton(
          onOpen: () async {
            try {
              if (context.mounted) {
                await _showCreatePostSheet(context);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ErrorHandler.getUserFriendlyMessage(e)),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () async {
                        try {
                          if (context.mounted) {
                            await _showCreatePostSheet(context);
                          }
                        } catch (_) {}
                      },
                    ),
                  ),
                );
              }
            }
          },
        ),
        body: Column(
          children: [
            // Animated header
            Container(
              color: bgColor,
              padding: EdgeInsets.only(top: statusBarHeight),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: headerHeight,
                color: bgColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Opacity(
                      opacity: titleOpacity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Feed',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.push('/search'),
                          icon: const Icon(Icons.search),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final unreadState = ref.watch(unreadNotificationsCountProvider);
                            final unreadCount = unreadState.asData?.value ?? 0;

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  onPressed: () => context.push('/notifications'),
                                  icon: const Icon(Icons.notifications_none),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onError,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Pinned TabBar
            Container(
              color: bgColor,
              child: const TabBar(
                tabs: [
                  Tab(text: 'Latest'),
                  Tab(text: 'Connected'),
                  Tab(text: 'Viral'),
                ],
              ),
            ),
            // Feed content
            Expanded(
              child: _FeedTabView(scrollController: _scrollController),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTabView extends ConsumerWidget {
  const _FeedTabView({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestState = ref.watch(latestFeedProvider);
    final connectedPosts = ref.watch(connectedFeedProvider);
    final viralPosts = ref.watch(viralFeedProvider);

    return TabBarView(
      children: [
        _PaginatedFeedList(
          kind: _FeedKind.latest,
          state: latestState,
          scrollController: scrollController,
        ),
        _FeedList(
          kind: _FeedKind.connected,
          posts: AsyncValue.data(connectedPosts),
          emptyStateText: 'Follow people to see their posts here.',
          scrollController: scrollController,
        ),
        _FeedList(
          kind: _FeedKind.viral,
          posts: AsyncValue.data(viralPosts),
          scrollController: scrollController,
        ),
      ],
    );
  }
}

enum _FeedKind { latest, connected, viral }

Future<void> _showCreatePostSheet(BuildContext context) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Create post',
    barrierColor: Colors.black.withValues(alpha: 0.34),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutExpo,
        reverseCurve: Curves.easeInCubic,
      );

      return Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedBuilder(
          animation: curved,
          builder: (context, _) {
            final value = curved.value;
            final slide = 96 * (1 - value);
            final scaleY = 0.90 + (0.10 * value);
            final scaleX = 0.985 + (0.015 * value);
            final opacity = value.clamp(0.0, 1.0);

            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, slide),
                child: Transform.scale(
                  scaleX: scaleX,
                  scaleY: scaleY,
                  alignment: Alignment.bottomCenter,
                  child: _CreatePostBottomSheetShell(animationValue: value),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

class _CreatePostBottomSheetShell extends StatelessWidget {
  const _CreatePostBottomSheetShell({required this.animationValue});

  final double animationValue;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final appBarHeight = 56.0; // Material AppBar default height
    final topInset = statusBarHeight + appBarHeight;
    final sheetHeight = (screenHeight * 0.64).clamp(430.0, 590.0);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(top: topInset, bottom: keyboardHeight),
        child: SizedBox(
          height: sheetHeight,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.18),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 34,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -4 + (animationValue * 18),
                    left: -74,
                    child: _AnimatedSheetGlow(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.18),
                      size: 180,
                    ),
                  ),
                  Positioned(
                    top: -6 + (animationValue * 20),
                    right: -74,
                    child: _AnimatedSheetGlow(
                      color: const Color(0xFFF9A8D4).withValues(alpha: 0.18),
                      size: 10,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 4,
                    child: Transform.scale(
                      scaleX: animationValue.clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF60A5FA),
                              Color(0xFFA78BFA),
                              Color(0xFFF9A8D4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF60A5FA),
                                    Color(0xFFA78BFA),
                                    Color(0xFFF9A8D4),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF312E81),
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create post',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                        ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Thought, ask, or ship something.',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.82),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              tooltip: 'Close',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 34,
                                minHeight: 34,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - animationValue)),
                          child: Opacity(
                            opacity: animationValue.clamp(0.0, 1.0),
                            child: const ClipRect(
                              child: CreatePostPage(
                                showAppBar: true,
                                compact: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Paginated feed list for Latest posts
class _PaginatedFeedList extends ConsumerStatefulWidget {
  const _PaginatedFeedList({
    required this.kind,
    required this.state,
    required this.scrollController,
  });

  final _FeedKind kind;
  final PaginatedPostsState state;
  final ScrollController scrollController;

  @override
  ConsumerState<_PaginatedFeedList> createState() => _PaginatedFeedListState();
}

class _PaginatedFeedListState extends ConsumerState<_PaginatedFeedList> {
  late ScrollController _scrollController;
  DateTime _lastActiveVideoUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _updateActiveVideo() {
    final posts = widget.state.posts;
    if (posts.isEmpty) return;

    final scrollPos = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final centerY = scrollPos + (viewportHeight / 2);

    const estimatedPostHeight = 600.0;
    final estimatedIndex = (centerY / estimatedPostHeight).toInt().clamp(0, posts.length - 1);

    if (estimatedIndex >= 0 && estimatedIndex < posts.length) {
      final centerPost = posts[estimatedIndex];
      ref.read(activeVideoPostIdProvider.notifier).state = centerPost.id;
    }
  }

  void _onScroll() {
    final now = DateTime.now();
    if (now.difference(_lastActiveVideoUpdate).inMilliseconds > 500) {
      _updateActiveVideo();
      _lastActiveVideoUpdate = now;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(latestFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(latestFeedProvider.notifier).refresh();
      },
      child: state.isInitialLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _buildPostsList(context, state),
    );
  }

  Widget _buildPostsList(BuildContext context, PaginatedPostsState state) {
    final posts = state.posts;

    return ListView.separated(
      padding: EdgeInsets.zero,
      controller: _scrollController,
      itemCount: posts.isEmpty ? 2 : posts.length + 2,
      separatorBuilder: (context, index) => const Divider(height: 0.5),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _FeedComposerEntry();
        }

        if (posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Center(
              child: Text(
                'No posts yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appColors.mutedText),
              ),
            ),
          );
        }

        if (index == posts.length + 1) {
          // Load more indicator at bottom
          if (state.isLoadingMore) {
            return Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            );
          }

          if (!state.hasMore) {
            return Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Center(
                child: Text(
                  'No more posts',
                  style: TextStyle(color: context.appColors.mutedText),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        }

        final post = posts[index - 1];
        final detailPostId = post.detailPostId;
        final detailExtra = detailPostId == post.id ? post : null;

        return FeedPostCard(
          post: post,
          onCommentTap: () {
            try {
              if (context.mounted) {
                context.push('/posts/$detailPostId', extra: detailExtra);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ErrorHandler.getUserFriendlyMessage(e)),
                  ),
                );
              }
            }
          },
          onTap: () {
            try {
              if (context.mounted) {
                context.push('/posts/$detailPostId', extra: detailExtra);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ErrorHandler.getUserFriendlyMessage(e)),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}

class _FeedList extends ConsumerWidget {
  const _FeedList({
    required this.kind,
    required this.posts,
    required this.scrollController,
    this.emptyStateText = 'No posts yet.',
  });

  final _FeedKind kind;
  final AsyncValue<List<PostModel>> posts;
  final ScrollController scrollController;
  final String emptyStateText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(latestPostsProvider);
        ref.invalidate(connectedPostsProvider);
        ref.invalidate(viralPostsProvider);
        if (kind == _FeedKind.connected) {
          ref.invalidate(myConnectionsProvider);
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: posts.when(
        data: (visiblePosts) {
          return ListView.separated(
            padding: EdgeInsets.zero,
            controller: scrollController,
            itemCount: visiblePosts.isEmpty ? 2 : visiblePosts.length + 1,
            separatorBuilder: (context, index) {
              return const Divider(height: 0.5);
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _FeedComposerEntry();
              }

              if (visiblePosts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Center(
                    child: Text(
                      emptyStateText,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.appColors.mutedText),
                    ),
                  ),
                );
              }

              final post = visiblePosts[index - 1];
              final detailPostId = post.detailPostId;
              final detailExtra = detailPostId == post.id ? post : null;

              return FeedPostCard(
                post: post,
                onCommentTap: () {
                  try {
                    if (context.mounted) {
                      context.push('/posts/$detailPostId', extra: detailExtra);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ErrorHandler.getUserFriendlyMessage(e)),
                        ),
                      );
                    }
                  }
                },
                onTap: () {
                  try {
                    if (context.mounted) {
                      context.push('/posts/$detailPostId', extra: detailExtra);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ErrorHandler.getUserFriendlyMessage(e)),
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
        loading: () => ListView.separated(
          controller: scrollController,
          itemCount: 6,
          separatorBuilder: (context, index) => const Divider(height: 0.5),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _FeedComposerEntry();
            }
            return const SkeletonPostCard();
          },
        ),
        error: (error, stackTrace) => RetryErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(latestPostsProvider),
        ),
      ),
    );
  }
}

class _CreatePostFabButton extends StatefulWidget {
  const _CreatePostFabButton({required this.onOpen});

  final Future<void> Function() onOpen;

  @override
  State<_CreatePostFabButton> createState() => _CreatePostFabButtonState();
}

class _CreatePostFabButtonState extends State<_CreatePostFabButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_controller.isAnimating) return;

    await _controller.forward(from: 0);

    if (!mounted) return;

    await widget.onOpen();

    if (!mounted) return;
    _controller.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        final pressScale = progress == 0
            ? 1.0
            : 1.0 +
                  (Curves.easeOutBack.transform(progress.clamp(0.0, 1.0)) *
                      0.055);

        return Transform.scale(
          scale: pressScale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF60A5FA), // soft blue
                  Color(0xFFA78BFA), // soft violet
                  Color(0xFFF9A8D4), // soft pink
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA78BFA).withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'feed_fab',
              elevation: 0,
              highlightElevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              onPressed: _handleTap,
              tooltip: 'Create post',
              child: _CreatePostFabIcon(progress: progress),
            ),
          ),
        );
      },
    );
  }
}

class _CreatePostFabIcon extends StatelessWidget {
  const _CreatePostFabIcon({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF312E81);
    final sparkleTurn = progress == 0
        ? 0.0
        : Curves.easeOutCubic.transform(progress) * 6.28318;
    final glowOpacity = progress == 0
        ? 0.0
        : 0.45 + (Curves.easeOut.transform(progress) * 0.35);

    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WaterDropPulsePainter(color: color, progress: progress),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _AiComposeIconPainter(color: color)),
          ),
          Positioned(
            right: -3,
            top: -3,
            child: Transform.rotate(
              angle: sparkleTurn,
              child: Icon(Icons.auto_awesome_rounded, size: 14, color: color),
            ),
          ),
          Positioned(
            left: -3,
            bottom: 3,
            child: Opacity(
              opacity: glowOpacity,
              child: Icon(Icons.blur_on_rounded, size: 9, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterDropPulsePainter extends CustomPainter {
  const _WaterDropPulsePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.72;

    for (var i = 0; i < 3; i++) {
      final localProgress = ((progress * 1.18) - (i * 0.16)).clamp(0.0, 1.0);
      final radius = maxRadius * localProgress;
      final opacity = progress < 0.98
          ? (1 - localProgress).clamp(0.0, 1.0) * 0.72
          : 0.0;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 + (1.8 * (1 - localProgress));

      canvas.drawCircle(center, radius, paint);
    }

    final dropPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              color.withValues(alpha: 0.42),
              color.withValues(alpha: 0.00),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.shortestSide * 0.52),
          );

    canvas.drawCircle(center, size.shortestSide * 0.45, dropPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterDropPulsePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

class _AnimatedSheetGlow extends StatefulWidget {
  const _AnimatedSheetGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_AnimatedSheetGlow> createState() => _AnimatedSheetGlowState();
}

class _AnimatedSheetGlowState extends State<_AnimatedSheetGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.92 + (_controller.value * 0.12);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [widget.color, widget.color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _AiComposeIconPainter extends CustomPainter {
  const _AiComposeIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pageRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.18,
        size.width * 0.58,
        size.height * 0.66,
      ),
      Radius.circular(size.width * 0.13),
    );

    canvas.drawRRect(pageRect, paint);

    final penPath = Path()
      ..moveTo(size.width * 0.45, size.height * 0.70)
      ..lineTo(size.width * 0.83, size.height * 0.32)
      ..lineTo(size.width * 0.92, size.height * 0.41)
      ..lineTo(size.width * 0.54, size.height * 0.79)
      ..lineTo(size.width * 0.39, size.height * 0.84)
      ..close();

    canvas.drawPath(penPath, paint);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.36),
      Offset(size.width * 0.52, size.height * 0.36),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.49),
      Offset(size.width * 0.45, size.height * 0.49),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AiComposeIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _FeedComposerEntry extends ConsumerWidget {
  const _FeedComposerEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final myProfile = ref.watch(myProfileProvider).asData?.value;
    final currentUid = ref.watch(currentUserProvider)?.uid ?? '';
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.md,
        ),
        child: Row(
          children: [
            AppUserAvatar(
              avatarUrl: myProfile?.avatarUrl,
              radius: 20,
              onTap: () async {
                try {
                  await navigateToProfile(
                    context: context,
                    uid: currentUid,
                    isSelfProfile: true,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ErrorHandler.getUserFriendlyMessage(e)),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
                onTap: () async {
                  try {
                    if (context.mounted) {
                      await _showCreatePostSheet(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ErrorHandler.getUserFriendlyMessage(e)),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    'What are you building in AI?',
                    style: TextStyle(color: colors.mutedText, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

