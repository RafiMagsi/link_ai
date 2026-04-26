import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/post_model.dart';
import '../providers/post_providers.dart';
import 'post_comments_page.dart';
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
        backgroundColor: const Color(0xFF0F172A),
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
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
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
        await Future<void>.delayed(const Duration(milliseconds: 250));
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
              return const Divider(
                height: 1,
                thickness: 0.7,
                color: Color(0xFF1E293B),
              );
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _FeedComposerEntry();
              }

              if (visiblePosts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      emptyStateText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                );
              }

              final post = visiblePosts[index - 1];

              return FeedPostCard(
                post: post,
                onCommentTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostCommentsPage(post: post),
                    ),
                  );
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

class _FeedComposerEntry extends StatelessWidget {
  const _FeedComposerEntry();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/posts/create'),
      child: Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF1E293B),
              child: Icon(Icons.person),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Text(
                  'What are you building in AI?',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
