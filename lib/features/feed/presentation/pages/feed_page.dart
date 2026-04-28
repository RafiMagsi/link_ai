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
import '../providers/post_providers.dart';
import '../widgets/feed_post_card.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestPosts = ref.watch(latestPostsProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Feed',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Latest'),
              Tab(text: 'Following'),
              Tab(text: 'Viral'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.search),
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
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
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
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'feed_fab',
          onPressed: () async {
            try {
              if (context.mounted) {
                context.push('/posts/create');
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
                            context.push('/posts/create');
                          }
                        } catch (_) {}
                      },
                    ),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Post'),
        ),
        body: TabBarView(
          children: [
            _FeedList(kind: _FeedKind.latest, posts: latestPosts),
            _FeedList(
              kind: _FeedKind.connected,
              posts: latestPosts,
              emptyStateText: 'Follow people to see their posts here.',
            ),
            _FeedList(kind: _FeedKind.viral, posts: latestPosts),
          ],
        ),
      ),
    );
  }

  static int _viralScore(PostModel post) {
    return (post.likesCount * 2) +
        (post.repostsCount * 3) +
        post.commentsCount +
        post.savesCount;
  }
}

enum _FeedKind { latest, connected, viral }

class _FeedList extends ConsumerWidget {
  const _FeedList({
    required this.kind,
    required this.posts,
    this.emptyStateText = 'No posts yet.',
  });

  final _FeedKind kind;
  final AsyncValue<List<PostModel>> posts;
  final String emptyStateText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingState = kind == _FeedKind.connected
        ? ref.watch(myConnectionsProvider)
        : null;
    final followingUids = followingState?.asData?.value
        .map((c) => c.connectedUid)
        .where((uid) => uid.isNotEmpty)
        .toSet();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(latestPostsProvider);
        if (kind == _FeedKind.connected) {
          ref.invalidate(myConnectionsProvider);
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: posts.when(
        data: (items) {
          final visiblePosts = switch (kind) {
            _FeedKind.latest => items,
            _FeedKind.connected =>
              followingUids == null
                  ? items
                  : items
                        .where((p) => followingUids.contains(p.authorUid))
                        .toList(),
            _FeedKind.viral =>
              (items.toList()..sort(
                (a, b) =>
                    FeedPage._viralScore(b).compareTo(FeedPage._viralScore(a)),
              )),
          };

          return ListView.separated(
            itemCount: visiblePosts.isEmpty ? 2 : visiblePosts.length + 1,
            separatorBuilder: (context, index) {
              return const Divider(height: 1);
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

              return FeedPostCard(
                post: post,
                onCommentTap: () {
                  try {
                    if (context.mounted) {
                      context.push('/posts/${post.id}', extra: post);
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
                      context.push('/posts/${post.id}', extra: post);
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
          itemCount: 6,
          separatorBuilder: (context, index) => const Divider(height: 1),
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
          vertical: AppSizes.lg,
        ),
        child: Row(
          children: [
            AppUserAvatar(
              avatarUrl: myProfile?.avatarUrl,
              radius: 24,
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
            const SizedBox(width: AppSizes.lg),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
                onTap: () {
                  try {
                    if (context.mounted) {
                      context.push('/posts/create');
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
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.md,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    'What are you building in AI?',
                    style: TextStyle(color: colors.mutedText, fontSize: 15),
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
