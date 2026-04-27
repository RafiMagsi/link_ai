import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../../connect/presentation/widgets/connect_button.dart';
import '../../../feed/data/models/post_comment_model.dart';
import '../../../feed/presentation/providers/post_providers.dart';
import '../../../feed/presentation/widgets/feed_post_card.dart';
import '../providers/profile_providers.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({
    super.key,
    required this.uid,
    required this.isSelf,
    required this.onEditProfile,
  });

  final String uid;
  final bool isSelf;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileByUidProvider(uid));
    final postsState = ref.watch(postsByAuthorProvider(uid));
    final likesState = ref.watch(likedPostIdsByUserProvider(uid));
    final commentsState = ref.watch(commentsByAuthorProvider(uid));

    return profileState.when(
      data: (profile) {
        if (profile == null) {
          return const AppEmptyState(
            title: 'Profile not found',
            subtitle: 'This user may have deleted their profile.',
            icon: Icons.person_off_outlined,
          );
        }

        return DefaultTabController(
          length: 4,
          child: Column(
            children: [
              _Header(
                isSelf: isSelf,
                name: profile.name,
                role: profile.role,
                location: profile.location,
                avatarUrl: profile.avatarUrl,
                links: profile.links,
                targetUid: profile.uid,
                onEditProfile: onEditProfile,
              ),
              _StatsRow(
                postsState: postsState,
                likesState: likesState,
                commentsState: commentsState,
              ),
              const SizedBox(height: AppSizes.md),
              const TabBar(
                tabs: [
                  Tab(text: 'Posts'),
                  Tab(text: 'Likes'),
                  Tab(text: 'Comments'),
                  Tab(text: 'Hashtags'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _PostsTab(uid: uid),
                    _LikesTab(uid: uid),
                    _CommentsTab(uid: uid),
                    _HashtagsTab(uid: uid),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          const Center(child: Text('Unable to load profile.')),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isSelf,
    required this.name,
    required this.role,
    required this.location,
    required this.avatarUrl,
    required this.links,
    required this.targetUid,
    required this.onEditProfile,
  });

  final bool isSelf;
  final String name;
  final String role;
  final String location;
  final String? avatarUrl;
  final Map<String, String> links;
  final String targetUid;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final displayName = name.isEmpty ? 'Unnamed Builder' : name;
    final displayRole = role.isEmpty ? 'AI Builder' : role;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.lg,
        AppSizes.lg,
        0,
      ),
      child: Column(
        children: [
          AppUserAvatar(avatarUrl: avatarUrl, radius: 44),
          const SizedBox(height: AppSizes.md),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            displayRole,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.mutedText),
          ),
          if (location.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: colors.mutedText,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.mutedText),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.lg),
          if (isSelf)
            FilledButton.icon(
              onPressed: onEditProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Edit profile'),
            )
          else
            ConnectButton(targetUid: targetUid, targetName: displayName),
          const SizedBox(height: AppSizes.md),
          _LinksRow(links: links),
        ],
      ),
    );
  }
}

class _LinksRow extends StatelessWidget {
  const _LinksRow({required this.links});

  final Map<String, String> links;

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = links.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    IconData iconFor(String key) {
      return switch (key.toLowerCase()) {
        'website' => Icons.public,
        'linkedin' => Icons.work_outline,
        'github' => Icons.code,
        'x' => Icons.alternate_email,
        _ => Icons.link,
      };
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((e) {
        return ActionChip(
          avatar: Icon(iconFor(e.key), size: 18, color: colors.mutedText),
          label: Text(e.key),
          onPressed: () => _copy(context, e.value.trim()),
        );
      }).toList(),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.postsState,
    required this.likesState,
    required this.commentsState,
  });

  final AsyncValue<List<dynamic>> postsState;
  final AsyncValue<List<String>> likesState;
  final AsyncValue<List<PostCommentModel>> commentsState;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final posts = postsState.asData?.value.length;
    final likes = likesState.asData?.value.length;
    final comments = commentsState.asData?.value.length;

    Widget metric(String label, int? value) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value?.toString() ?? '—',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: colors.mutedText)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.md,
        AppSizes.lg,
        0,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              metric('Posts', posts),
              metric('Likes', likes),
              metric('Comments', comments),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostsTab extends ConsumerWidget {
  const _PostsTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(postsByAuthorProvider(uid));
    return state.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const AppEmptyState(
            title: 'No posts yet',
            subtitle: 'No posts to show.',
            icon: Icons.forum_outlined,
          );
        }

        return ListView.separated(
          itemCount: posts.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final post = posts[index];
            return FeedPostCard(
              post: post,
              onTap: () => context.push('/posts/${post.id}', extra: post),
              onCommentTap: () =>
                  context.push('/posts/${post.id}', extra: post),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          const Center(child: Text('Unable to load posts.')),
    );
  }
}

class _LikesTab extends ConsumerWidget {
  const _LikesTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(likedPostIdsByUserProvider(uid));

    return state.when(
      data: (postIds) {
        if (postIds.isEmpty) {
          return const AppEmptyState(
            title: 'No likes yet',
            subtitle: 'Liked posts will show up here.',
            icon: Icons.favorite_border,
          );
        }

        return ListView.separated(
          itemCount: postIds.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final postId = postIds[index];
            final postState = ref.watch(postByIdProvider(postId));

            return postState.when(
              data: (post) {
                if (post == null) return const SizedBox.shrink();
                return FeedPostCard(
                  post: post,
                  onTap: () => context.push('/posts/${post.id}', extra: post),
                  onCommentTap: () =>
                      context.push('/posts/${post.id}', extra: post),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSizes.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => const SizedBox.shrink(),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          const Center(child: Text('Unable to load likes.')),
    );
  }
}

class _CommentsTab extends ConsumerWidget {
  const _CommentsTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commentsByAuthorProvider(uid));

    return state.when(
      data: (comments) {
        if (comments.isEmpty) {
          return const AppEmptyState(
            title: 'No comments yet',
            subtitle: 'Comments made by this user will show up here.',
            icon: Icons.chat_bubble_outline,
          );
        }

        return ListView.separated(
          itemCount: comments.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final c = comments[index];
            return ListTile(
              title: Text(c.text, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: const Text('On a post'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/posts/${c.postId}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          const Center(child: Text('Unable to load comments.')),
    );
  }
}

class _HashtagsTab extends ConsumerWidget {
  const _HashtagsTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsState = ref.watch(postsByAuthorProvider(uid));

    return postsState.when(
      data: (posts) {
        final counts = <String, int>{};
        for (final post in posts) {
          for (final t in post.hashtags) {
            counts[t] = (counts[t] ?? 0) + 1;
          }
        }

        final top = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (top.isEmpty) {
          return const AppEmptyState(
            title: 'No hashtags yet',
            subtitle: 'Hashtags used by this user will show up here.',
            icon: Icons.tag,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: top.take(40).map((e) {
                return ActionChip(
                  label: Text('#${e.key} · ${e.value}'),
                  onPressed: () => context.push('/hashtags/${e.key}'),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          const Center(child: Text('Unable to load hashtags.')),
    );
  }
}
