import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../data/models/post_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
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
              Tab(text: 'Connected'),
              Tab(text: 'Viral'),
            ],
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
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
                            style: const TextStyle(
                              color: Colors.white,
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
          onPressed: () => context.push('/posts/create'),
          icon: const Icon(Icons.add),
          label: const Text('Post'),
        ),
        body: TabBarView(
          children: [
            _FeedList(kind: _FeedKind.latest, posts: latestPosts),
            _FeedList(
              kind: _FeedKind.connected,
              posts: latestPosts,
              emptyStateText:
                  'Connected feed is coming next.\nFor now it shows the latest posts.',
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
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(latestPostsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: posts.when(
        data: (items) {
          final visiblePosts = switch (kind) {
            _FeedKind.latest => items,
            _FeedKind.connected => items,
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
                  context.push('/posts/${post.id}', extra: post);
                },
                onTap: () {
                  context.push('/posts/${post.id}', extra: post);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Unable to load feed.')),
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
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSizes.lg, 14, AppSizes.lg, 14),
        child: Row(
          children: [
            AppUserAvatar(
              avatarUrl: myProfile?.avatarUrl,
              radius: 22,
              onTap: () => context.push('/profile'),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => context.push('/posts/create'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.md,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
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
