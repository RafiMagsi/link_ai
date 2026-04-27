import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../../../core/widgets/skeleton_post_card.dart';
import '../../../connect/presentation/widgets/connect_button.dart';
import '../../../feed/data/models/post_comment_model.dart';
import '../../../feed/presentation/providers/post_providers.dart';
import '../../../feed/presentation/widgets/feed_post_card.dart';
import '../providers/profile_providers.dart';

class ProfileView extends ConsumerStatefulWidget {
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
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  int _selectedTab = 0;

  Future<void> _refresh() async {
    ref.invalidate(profileByUidProvider(widget.uid));
    ref.invalidate(postsByAuthorProvider(widget.uid));
    ref.invalidate(likedPostIdsByUserProvider(widget.uid));
    ref.invalidate(commentsByAuthorProvider(widget.uid));
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.uid;
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

        return RefreshIndicator.adaptive(
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          notificationPredicate: (notification) {
            return notification.metrics.axis == Axis.vertical;
          },
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _Header(
                      isSelf: widget.isSelf,
                      name: profile.name,
                      role: profile.role,
                      bio: profile.bio,
                      location: profile.location,
                      avatarUrl: profile.avatarUrl,
                      links: profile.links,
                      building: profile.building,
                      need: profile.need,
                      wantToMeet: profile.wantToMeet,
                      skills: profile.skills,
                      tools: profile.tools,
                      targetUid: profile.uid,
                      onEditProfile: widget.onEditProfile,
                    ),
                    _StatsRow(
                      postsState: postsState,
                      likesState: likesState,
                      commentsState: commentsState,
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _ProfileTabsHeaderDelegate(
                  child: _ProfileTabsHeader(
                    selectedIndex: _selectedTab,
                    onChanged: (index) {
                      setState(() {
                        _selectedTab = index;
                      });
                    },
                  ),
                ),
              ),
              _ProfileSelectedTabSliver(
                uid: uid,
                selectedTab: _selectedTab,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: AppLoader()),
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
    required this.bio,
    required this.location,
    required this.avatarUrl,
    required this.links,
    required this.building,
    required this.need,
    required this.wantToMeet,
    required this.skills,
    required this.tools,
    required this.targetUid,
    required this.onEditProfile,
  });

  final bool isSelf;
  final String name;
  final String role;
  final String bio;
  final String location;
  final String? avatarUrl;
  final Map<String, String> links;
  final String building;
  final String need;
  final String wantToMeet;
  final List<String> skills;
  final List<String> tools;
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
        AppSizes.xl,
        AppSizes.lg,
        AppSizes.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _GradientAvatar(avatarUrl: avatarUrl),
              const SizedBox(width: AppSizes.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      displayRole,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: colors.mutedText,
                      ),
                    ),
                    if (location.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSizes.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: colors.mutedText,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          if (bio.trim().isNotEmpty)
            Text(
              bio.trim(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (building.trim().isNotEmpty ||
              need.trim().isNotEmpty ||
              wantToMeet.trim().isNotEmpty) ...[
            const SizedBox(height: AppSizes.md),
            _ProfileInfoPanel(
              building: building,
              need: need,
              wantToMeet: wantToMeet,
            ),
          ],
          if (skills.isNotEmpty || tools.isNotEmpty) ...[
            const SizedBox(height: AppSizes.md),
            _ProfileChipsSection(
              title: 'Skills & tools',
              values: [...skills, ...tools],
            ),
          ],
          if (links.values.any((value) => value.trim().isNotEmpty)) ...[
            const SizedBox(height: AppSizes.md),
            _LinksRow(links: links),
          ],
          const SizedBox(height: AppSizes.lg),
          _ProfileActionButtons(
            isSelf: isSelf,
            targetUid: targetUid,
            displayName: displayName,
            onEditProfile: onEditProfile,
          ),
        ],
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  const _GradientAvatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFFFACC15),
            Color(0xFFEC4899),
            Color(0xFF8B5CF6),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: _ProfileAvatarImage(avatarUrl: avatarUrl),
      ),
    );
  }
}

class _ProfileAvatarImage extends StatelessWidget {
  const _ProfileAvatarImage({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return AppUserAvatar(avatarUrl: avatarUrl, radius: 44);
    }

    return CircleAvatar(
      radius: 44,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person_rounded,
        size: 52,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ProfileActionButtons extends StatelessWidget {
  const _ProfileActionButtons({
    required this.isSelf,
    required this.targetUid,
    required this.displayName,
    required this.onEditProfile,
  });

  final bool isSelf;
  final String targetUid;
  final String displayName;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    if (!isSelf) {
      return Row(
        children: [
          Expanded(
            child: ConnectButton(targetUid: targetUid, targetName: displayName),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('Message'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onEditProfile,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit profile'),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/connect/requests'),
            icon: const Icon(Icons.group_add_outlined, size: 18),
            label: const Text('Requests'),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        IconButton.filledTonal(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(text: 'ai-links://profiles/$targetUid'),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile link copied')),
            );
          },
          icon: const Icon(Icons.share_outlined),
          tooltip: 'Share profile',
        ),
      ],
    );
  }
}

class _ProfileInfoPanel extends StatelessWidget {
  const _ProfileInfoPanel({
    required this.building,
    required this.need,
    required this.wantToMeet,
  });

  final String building;
  final String need;
  final String wantToMeet;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, String value})>[
      (
        icon: Icons.auto_awesome_outlined,
        label: 'Building',
        value: building,
      ),
      (
        icon: Icons.lightbulb_outline,
        label: 'Needs',
        value: need,
      ),
      (
        icon: Icons.people_alt_outlined,
        label: 'Wants to meet',
        value: wantToMeet,
      ),
    ].where((item) => item.value.trim().isNotEmpty).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
            Theme.of(context).colorScheme.surface.withOpacity(0.70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : AppSizes.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon, size: 19, color: colors.mutedText),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: '${item.label}: ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: item.value.trim()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ProfileChipsSection extends StatelessWidget {
  const _ProfileChipsSection({
    required this.title,
    required this.values,
  });

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final uniqueValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (uniqueValues.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: uniqueValues.take(16).map((value) {
            return Chip(
              label: Text(value),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
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
      alignment: WrapAlignment.start,
      children: items.map((e) {
        return GestureDetector(
          onTap: () async {
            final uri = Uri.tryParse(e.value.trim());
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          onLongPress: () => _copy(context, e.value.trim()),
          child: ActionChip(
            avatar: Icon(iconFor(e.key), size: 18, color: colors.mutedText),
            label: Text(e.key),
            onPressed: null,
          ),
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
        AppSizes.sm,
        AppSizes.lg,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E293B)),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.72),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              metric('Posts', posts),
              _VerticalDivider(color: colors.mutedText.withOpacity(0.22)),
              metric('Likes', likes),
              _VerticalDivider(color: colors.mutedText.withOpacity(0.22)),
              metric('Comments', comments),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: color,
    );
  }
}

class _ProfileTabsHeader extends StatelessWidget {
  const _ProfileTabsHeader({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _tabs = [
    (icon: Icons.grid_on_rounded, label: 'Posts'),
    (icon: Icons.favorite_border_rounded, label: 'Likes'),
    (icon: Icons.chat_bubble_outline_rounded, label: 'Comments'),
    (icon: Icons.tag_rounded, label: 'Hashtags'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final selected = selectedIndex == index;

          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: SizedBox(
                height: 52,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      size: 21,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 2,
                      width: selected ? 32 : 0,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ProfileTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ProfileTabsHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(
          top: BorderSide(color: Color(0x141E293B)),
          bottom: BorderSide(color: Color(0x331E293B)),
        ),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileTabsHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _ScrollableEmptyProfileState extends StatelessWidget {
  const _ScrollableEmptyProfileState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.45,
          child: AppEmptyState(
            title: title,
            subtitle: subtitle,
            icon: icon,
          ),
        ),
      ],
    );
  }
}

class _ProfileSelectedTabSliver extends ConsumerWidget {
  const _ProfileSelectedTabSliver({
    required this.uid,
    required this.selectedTab,
  });

  final String uid;
  final int selectedTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (selectedTab) {
      0 => _PostsSliver(uid: uid),
      1 => _LikesSliver(uid: uid),
      2 => _CommentsSliver(uid: uid),
      _ => _HashtagsSliver(uid: uid),
    };
  }
}

class _PostsSliver extends ConsumerWidget {
  const _PostsSliver({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(postsByAuthorProvider(uid));

    return state.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              title: 'No posts yet',
              subtitle: 'No posts to show.',
              icon: Icons.forum_outlined,
            ),
          );
        }

        return SliverList.separated(
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
      loading: () => SliverList.separated(
        itemCount: 4,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => const SkeletonPostCard(),
      ),
      error: (error, stackTrace) => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Unable to load posts.')),
      ),
    );
  }
}

class _LikesSliver extends ConsumerWidget {
  const _LikesSliver({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(likedPostIdsByUserProvider(uid));

    return state.when(
      data: (postIds) {
        if (postIds.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              title: 'No likes yet',
              subtitle: 'Liked posts will show up here.',
              icon: Icons.favorite_border,
            ),
          );
        }

        return SliverList.separated(
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
              loading: () => const SkeletonPostCard(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            );
          },
        );
      },
      loading: () => SliverList.separated(
        itemCount: 4,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => const SkeletonPostCard(),
      ),
      error: (error, stackTrace) => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Unable to load likes.')),
      ),
    );
  }
}

class _CommentsSliver extends ConsumerWidget {
  const _CommentsSliver({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commentsByAuthorProvider(uid));

    return state.when(
      data: (comments) {
        if (comments.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              title: 'No comments yet',
              subtitle: 'Comments made by this user will show up here.',
              icon: Icons.chat_bubble_outline,
            ),
          );
        }

        return SliverList.separated(
          itemCount: comments.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final c = comments[index];
            return ListTile(
              title: Text(
                c.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: const Text('On a post'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/posts/${c.postId}'),
            );
          },
        );
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: AppLoader()),
      ),
      error: (error, stackTrace) => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Unable to load comments.')),
      ),
    );
  }
}

class _HashtagsSliver extends ConsumerWidget {
  const _HashtagsSliver({required this.uid});

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
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              title: 'No hashtags yet',
              subtitle: 'Hashtags used by this user will show up here.',
              icon: Icons.tag,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(AppSizes.lg),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: top.take(40).map((e) {
                return ActionChip(
                  label: Text('#${e.key} · ${e.value}'),
                  onPressed: () => context.push('/hashtags/${e.key}'),
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: AppLoader()),
      ),
      error: (error, stackTrace) => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Unable to load hashtags.')),
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
          return const _ScrollableEmptyProfileState(
            title: 'No posts yet',
            subtitle: 'No posts to show.',
            icon: Icons.forum_outlined,
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
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
      loading: () => ListView.separated(
        itemCount: 4,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => const SkeletonPostCard(),
      ),
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
          return const _ScrollableEmptyProfileState(
            title: 'No likes yet',
            subtitle: 'Liked posts will show up here.',
            icon: Icons.favorite_border,
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
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
              loading: () => const SkeletonPostCard(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            );
          },
        );
      },
      loading: () => ListView.separated(
        itemCount: 4,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => const SkeletonPostCard(),
      ),
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
          return const _ScrollableEmptyProfileState(
            title: 'No comments yet',
            subtitle: 'Comments made by this user will show up here.',
            icon: Icons.chat_bubble_outline,
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
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
      loading: () => const Center(child: AppLoader()),
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
          return const _ScrollableEmptyProfileState(
            title: 'No hashtags yet',
            subtitle: 'Hashtags used by this user will show up here.',
            icon: Icons.tag,
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
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
      loading: () => const Center(child: AppLoader()),
      error: (error, stackTrace) =>
          const Center(child: Text('Unable to load hashtags.')),
    );
  }
}

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _ProfileTabBarDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(
          top: BorderSide(color: Color(0x141E293B)),
          bottom: BorderSide(color: Color(0x331E293B)),
        ),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}