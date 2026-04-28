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
import '../../../../core/utils/hashtag_utils.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../connect/data/datasources/connect_remote_datasource.dart';
import '../../../connect/presentation/providers/connect_providers.dart';
import '../../../feed/presentation/providers/post_providers.dart';
import '../../../feed/presentation/widgets/feed_post_card.dart';
import '../../../messaging/data/models/conversation_model.dart';
import '../providers/profile_providers.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({
    super.key,
    required this.uid,
    required this.isSelf,
    required this.onEditProfile,
    this.showBackButton = false,
    this.onOpenMenu,
  });

  final String uid;
  final bool isSelf;
  final VoidCallback onEditProfile;
  final bool showBackButton;
  final VoidCallback? onOpenMenu;

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  int _selectedTab = 0;
  int? _cachedPostsCount;
  int? _cachedLikesCount;
  int? _cachedCommentsCount;

  Future<void> _refresh() async {
    ref.invalidate(profileByUidProvider(widget.uid));
    ref.invalidate(postsByAuthorProvider(widget.uid));
    ref.invalidate(likedPostIdsByUserProvider(widget.uid));
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.uid;
    final profileState = ref.watch(profileByUidProvider(uid));
    final postsState = ref.watch(postsByAuthorProvider(uid));
    final likesState = ref.watch(likedPostIdsByUserProvider(uid));

    final latestPostsCount = postsState.asData?.value.length;
    if (latestPostsCount != null) _cachedPostsCount = latestPostsCount;
    final latestLikesCount = likesState.asData?.value.length;
    if (latestLikesCount != null) _cachedLikesCount = latestLikesCount;

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
                      currentUid: ref.watch(currentUserProvider)?.uid ?? '',
                      name: profile.name,
                      role: profile.role,
                      bio: profile.bio,
                      location: profile.location,
                      avatarUrl: profile.avatarUrl,
                      links: profile.links,
                      building: profile.building,
                      need: profile.need,
                      wantToMeet: profile.wantToMeet,
                      collaborationIntent: profile.collaborationIntent,
                      projectStage: profile.projectStage,
                      lookingFor: profile.lookingFor,
                      skills: profile.skills,
                      tools: profile.tools,
                      targetUid: profile.uid,
                      onEditProfile: widget.onEditProfile,
                      showBackButton: widget.showBackButton,
                      onOpenMenu: widget.onOpenMenu,
                    ),
                    _StatsRow(
                      posts: _cachedPostsCount,
                      likes: _cachedLikesCount,
                      comments: _cachedCommentsCount,
                    ),
                    const SizedBox(height: AppSizes.xs),
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
              _ProfileSelectedTabSliver(uid: uid, selectedTab: _selectedTab),
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
    required this.currentUid,
    required this.name,
    required this.role,
    required this.bio,
    required this.location,
    required this.avatarUrl,
    required this.links,
    required this.building,
    required this.need,
    required this.wantToMeet,
    required this.collaborationIntent,
    required this.projectStage,
    required this.lookingFor,
    required this.skills,
    required this.tools,
    required this.targetUid,
    required this.onEditProfile,
    required this.showBackButton,
    required this.onOpenMenu,
  });

  final bool isSelf;
  final String currentUid;
  final String name;
  final String role;
  final String bio;
  final String location;
  final String? avatarUrl;
  final Map<String, String> links;
  final String building;
  final String need;
  final String wantToMeet;
  final String collaborationIntent;
  final String projectStage;
  final List<String> lookingFor;
  final List<String> skills;
  final List<String> tools;
  final String targetUid;
  final VoidCallback onEditProfile;
  final bool showBackButton;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final displayName = name.isEmpty ? 'Unnamed Builder' : name;
    final displayRole = role.isEmpty ? 'AI Builder' : role;
    final scheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: topInset + 82,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.45),
                    scheme.secondary.withValues(alpha: 0.35),
                    scheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(height: 1, color: colors.border),
                  ),
                  Positioned(
                    left: AppSizes.sm,
                    right: AppSizes.sm,
                    top: topInset - 10,
                    child: Row(
                      children: [
                        if (showBackButton)
                          IconButton(
                            constraints: const BoxConstraints.tightFor(
                              width: 40,
                              height: 36,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: 'Back',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: scheme.onPrimary,
                              overlayColor: scheme.onPrimary.withValues(
                                alpha: 0.10,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back),
                          )
                        else
                          const SizedBox(width: 40, height: 36),
                        const Spacer(),
                        // Keep the top row minimal: just navigation affordance(s).
                        const SizedBox(width: 40, height: 36),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -34,
              left: AppSizes.lg,
              right: AppSizes.lg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side of avatar: message + share
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                              child: _ProfilePrimaryAction(
                                isSelf: isSelf,
                                targetUid: targetUid,
                                targetName: displayName,
                                onEditProfile: onEditProfile,
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            _HeaderIconChip(
                              icon: Icons.share_outlined,
                              tooltip: 'Share profile',
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: 'linkai://profiles/$targetUid',
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile link copied'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Center(
                    child: _GradientAvatar(avatarUrl: avatarUrl, radius: 44),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  // Right side of avatar: primary action + menu
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isSelf)
                              _HeaderIconChip(
                                icon: Icons.chat_bubble_outline,
                                tooltip: 'Message',
                                onPressed: () {
                                  final convId = ConversationModel.buildId(
                                    currentUid,
                                    targetUid,
                                  );
                                  context.push('/messages/$convId');
                                },
                              )
                            else
                              const SizedBox(width: 40, height: 36),
                            const SizedBox(width: AppSizes.sm),
                            if (onOpenMenu != null)
                              _HeaderIconChip(
                                icon: Icons.more_horiz,
                                tooltip: 'More',
                                onPressed: onOpenMenu!,
                              )
                            else
                              const SizedBox(width: 40, height: 36),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            0,
            AppSizes.lg,
            AppSizes.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                displayRole,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.mutedText),
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
                        style: TextStyle(color: colors.mutedText, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              if (links.values.any((value) => value.trim().isNotEmpty)) ...[
                const SizedBox(height: AppSizes.sm),
                _LinksRow(links: links),
              ],
              const SizedBox(height: AppSizes.sm),
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
                  wantToMeet.trim().isNotEmpty ||
                  lookingFor.isNotEmpty ||
                  collaborationIntent.trim().isNotEmpty ||
                  projectStage.trim().isNotEmpty) ...[
                const SizedBox(height: AppSizes.sm),
                _ProfileInfoPanel(
                  building: building,
                  need: need,
                  wantToMeet: wantToMeet,
                  collaborationIntent: collaborationIntent,
                  projectStage: projectStage,
                  lookingFor: lookingFor,
                ),
              ],
              if (skills.isNotEmpty || tools.isNotEmpty) ...[
                const SizedBox(height: AppSizes.sm),
                _ProfileChipsSection(
                  title: 'Skills & tools',
                  values: [...skills, ...tools],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  const _GradientAvatar({required this.avatarUrl, this.radius = 44});

  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: _ProfileAvatarImage(avatarUrl: avatarUrl, radius: radius),
      ),
    );
  }
}

class _ProfileAvatarImage extends StatelessWidget {
  const _ProfileAvatarImage({required this.avatarUrl, required this.radius});

  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return AppUserAvatar(avatarUrl: avatarUrl, radius: radius);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person_rounded,
        size: radius * 1.15,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ProfilePrimaryAction extends ConsumerWidget {
  const _ProfilePrimaryAction({
    required this.isSelf,
    required this.targetUid,
    required this.targetName,
    required this.onEditProfile,
  });

  final bool isSelf;
  final String targetUid;
  final String targetName;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      backgroundColor: scheme.onPrimary.withValues(alpha: 0.14),
      foregroundColor: scheme.onPrimary,
      side: BorderSide(color: scheme.onPrimary.withValues(alpha: 0.22)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth.isFinite &&
            constraints.maxWidth <= 104; // fits beside another icon chip

        Widget iconAction({
          required IconData icon,
          required String tooltip,
          required VoidCallback onPressed,
        }) {
          return _HeaderIconChip(
            icon: icon,
            tooltip: tooltip,
            onPressed: onPressed,
          );
        }

        if (isSelf) {
          if (isCompact) {
            return iconAction(
              icon: Icons.edit_outlined,
              tooltip: 'Edit profile',
              onPressed: onEditProfile,
            );
          }

          return FilledButton(
            style: buttonStyle,
            onPressed: onEditProfile,
            child: const Text(
              'Edit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }

        final statusState = ref.watch(
          relationshipStatusStreamProvider(targetUid),
        );

        return statusState.when(
          data: (status) {
            switch (status) {
              case ConnectRelationshipStatus.connected:
                if (isCompact) {
                  return iconAction(
                    icon: Icons.check,
                    tooltip: 'Following',
                    onPressed: () async {
                      await ref
                          .read(connectControllerProvider.notifier)
                          .unfollowUser(targetUid);
                    },
                  );
                }
                return FilledButton.icon(
                  style: buttonStyle,
                  onPressed: () async {
                    await ref
                        .read(connectControllerProvider.notifier)
                        .unfollowUser(targetUid);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text(
                    'Following',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              case ConnectRelationshipStatus.none:
                if (isCompact) {
                  return iconAction(
                    icon: Icons.person_add_alt_1,
                    tooltip: 'Follow',
                    onPressed: () => ref
                        .read(connectControllerProvider.notifier)
                        .followUser(targetUid),
                  );
                }
                return FilledButton(
                  style: buttonStyle,
                  onPressed: () => ref
                      .read(connectControllerProvider.notifier)
                      .followUser(targetUid),
                  child: const Text(
                    'Follow',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
            }
          },
          loading: () {
            if (isCompact) return const _HeaderBusyChip();
            return FilledButton(
              style: buttonStyle,
              onPressed: null,
              child: const Text(
                'Checking…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
          error: (error, stackTrace) {
            if (isCompact) {
              return iconAction(
                icon: Icons.refresh,
                tooltip: 'Retry',
                onPressed: () =>
                    ref.invalidate(relationshipStatusStreamProvider(targetUid)),
              );
            }
            return FilledButton(
              style: buttonStyle,
              onPressed: () =>
                  ref.invalidate(relationshipStatusStreamProvider(targetUid)),
              child: const Text(
                'Retry',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        );
      },
    );
  }
}

class _HeaderBusyChip extends StatelessWidget {
  const _HeaderBusyChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 40,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.onPrimary.withValues(alpha: 0.12),
              border: Border.all(
                color: scheme.onPrimary.withValues(alpha: 0.18),
              ),
            ),
          ),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                scheme.onPrimary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconChip extends StatelessWidget {
  const _HeaderIconChip({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 40,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.onPrimary.withValues(alpha: 0.12),
              border: Border.all(
                color: scheme.onPrimary.withValues(alpha: 0.18),
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints.tightFor(width: 40, height: 36),
            padding: EdgeInsets.zero,
            tooltip: tooltip,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: scheme.onPrimary,
              overlayColor: scheme.onPrimary.withValues(alpha: 0.10),
            ),
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoPanel extends StatelessWidget {
  const _ProfileInfoPanel({
    required this.building,
    required this.need,
    required this.wantToMeet,
    required this.collaborationIntent,
    required this.projectStage,
    required this.lookingFor,
  });

  final String building;
  final String need;
  final String wantToMeet;
  final String collaborationIntent;
  final String projectStage;
  final List<String> lookingFor;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, String value})>[
      (icon: Icons.auto_awesome_outlined, label: 'Building', value: building),
      (icon: Icons.lightbulb_outline, label: 'Needs', value: need),
      (
        icon: Icons.people_alt_outlined,
        label: 'Wants to meet',
        value: wantToMeet,
      ),
    ].where((item) => item.value.trim().isNotEmpty).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;
    final intentLabel = _collaborationIntentLabel(collaborationIntent);
    final stageLabel = _projectStageLabel(projectStage);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ...items.asMap().entries.map((entry) {
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
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(height: 1.35),
                          children: [
                            TextSpan(
                              text: '${item.label}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: item.value.trim()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(icon: Icons.handshake_outlined, label: intentLabel),
                _MetaChip(
                  icon: Icons.rocket_launch_outlined,
                  label: stageLabel,
                ),
                ...lookingFor
                    .where((value) => value.trim().isNotEmpty)
                    .take(4)
                    .map(
                      (value) => _MetaChip(
                        icon: Icons.person_search_outlined,
                        label: value,
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _collaborationIntentLabel(String value) {
    switch (value) {
      case 'hiring':
        return 'Hiring';
      case 'looking_for_cofounder':
        return 'Looking for cofounder';
      case 'open_to_consulting':
        return 'Open to consulting';
      case 'not_looking':
        return 'Not looking now';
      case 'open_to_collaborate':
      default:
        return 'Open to collaborate';
    }
  }

  String _projectStageLabel(String value) {
    switch (value) {
      case 'idea':
        return 'Idea stage';
      case 'launched':
        return 'Launched';
      case 'growing':
        return 'Growing';
      case 'mvp':
      default:
        return 'MVP';
    }
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.mutedText),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ProfileChipsSection extends StatelessWidget {
  const _ProfileChipsSection({required this.title, required this.values});

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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: 2,
          runSpacing: 0,
          children: uniqueValues.take(16).map((value) {
            return GradientChip(label: value);
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
          onLongPress: () => _copy(context, e.value.trim()),
          child: ActionChip(
            avatar: Icon(iconFor(e.key), size: 18, color: colors.mutedText),
            label: Text(e.key),
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              final uri = Uri.tryParse(e.value.trim());
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.posts,
    required this.likes,
    required this.comments,
  });

  final int? posts;
  final int? likes;
  final int? comments;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
        AppSizes.xs,
        AppSizes.lg,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          metric('Posts', posts),
          _VerticalDivider(color: colors.border),
          metric('Likes', likes),
          _VerticalDivider(color: colors.border),
          metric('Comments', comments),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: color);
  }
}

class _ProfileTabsHeader extends StatelessWidget {
  const _ProfileTabsHeader({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _tabs = ['Posts', 'Likes', 'Comments', 'Hashtags'];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: SizedBox(
                height: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _tabs[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : colors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
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
        border: Border(
          top: BorderSide(
            color: context.appColors.border.withValues(alpha: 0.35),
          ),
          bottom: BorderSide(
            color: context.appColors.border.withValues(alpha: 0.75),
          ),
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
    final cached = state.error == null ? state.value : null;

    if (cached != null) {
      if (cached.isEmpty) {
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
        itemCount: cached.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final post = cached[index];
          return FeedPostCard(
            post: post,
            onTap: () => context.push('/posts/${post.id}', extra: post),
            onCommentTap: () => context.push('/posts/${post.id}', extra: post),
          );
        },
      );
    }

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
    final cached = state.error == null ? state.value : null;

    if (cached != null) {
      if (cached.isEmpty) {
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
        itemCount: cached.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final postId = cached[index];
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
    }

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
    final cached = state.error == null ? state.value : null;

    if (cached != null) {
      if (cached.isEmpty) {
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
        itemCount: cached.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final comment = cached[index];
          return ListTile(
            title: Text(
              comment.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text('On a post'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/posts/${comment.postId}'),
          );
        },
      );
    }

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
              title: Text(c.text, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: const Text('On a post'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/posts/${c.postId}'),
            );
          },
        );
      },
      loading: () => SliverList.separated(
        itemCount: 4,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => ListTile(
          title: Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
        ),
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
          final tags = post.hashtags.isNotEmpty
              ? post.hashtags
              : HashtagUtils.extractNormalized(post.text);
          for (final t in tags) {
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

class GradientChip extends StatelessWidget {
  const GradientChip({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2563EB).withValues(alpha: 0.14),
                const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                const Color(0xFFEC4899).withValues(alpha: 0.10),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
