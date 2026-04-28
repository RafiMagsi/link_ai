import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_ai/features/explore/presentation/widgets/shadow_style.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../../profile/data/models/profile_model.dart';
import '../providers/network_providers.dart';

class NetworkPage extends ConsumerWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingState = ref.watch(followingProfilesProvider);
    final matchesState = ref.watch(collaborationMatchesProvider);
    final openState = ref.watch(openToCollaborateProfilesProvider);

    Future<void> refreshNetwork() async {
      ref.invalidate(followingProfilesProvider);
      ref.invalidate(collaborationMatchesProvider);
      ref.invalidate(openToCollaborateProfilesProvider);

      await Future<void>.delayed(const Duration(milliseconds: 350));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Network')),
      body: RefreshIndicator.adaptive(
        onRefresh: refreshNetwork,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.md,
            AppSizes.lg,
            AppSizes.xxxl,
          ),
          children: [
            const _NetworkHero(),
            const SizedBox(height: AppSizes.xxl),
            _Section(
              title: 'Collaboration matches',
              subtitle: 'Builders whose needs and skills overlap with yours.',
              icon: Icons.hub_outlined,
              accentColor: const Color(0xFF60A5FA),
              child: _ProfilesList(asyncProfiles: matchesState),
            ),
            const SizedBox(height: AppSizes.xxl),
            _Section(
              title: 'Following',
              subtitle: 'People you already follow and want to keep close.',
              icon: Icons.people_alt_outlined,
              accentColor: const Color(0xFFA78BFA),
              child: _ProfilesList(
                asyncProfiles: followingState,
                emptyTitle: 'No follows yet',
                emptySubtitle: 'Follow AI builders to grow your network.',
              ),
            ),
            const SizedBox(height: AppSizes.xxl),
            _Section(
              title: 'Open to collaborate',
              subtitle: 'People open to hiring, feedback, consulting, or building together.',
              icon: Icons.handshake_outlined,
              accentColor: const Color(0xFFF9A8D4),
              child: _ProfilesList(asyncProfiles: openState),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkHero extends StatelessWidget {
  const _NetworkHero();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.10),
          width: 0.7,
        ),
        boxShadow: ShadowStyle.lightShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -76,
              right: -64,
              child: _SoftGlow(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.06),
                size: 190,
              ),
            ),
            Positioned(
              bottom: -88,
              left: -72,
              child: _SoftGlow(
                color: const Color(0xFFF9A8D4).withValues(alpha: 0.06),
                size: 198,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFBFDBFE),
                          Color(0xFFD8B4FE),
                          Color(0xFFFBCFE8),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.hub_outlined,
                      color: Color(0xFF312E81),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Find AI people worth building with',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Discover collaborators, people you follow, and builders open to opportunities.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStat(
                          label: 'Matches',
                          icon: Icons.auto_awesome_rounded,
                          color: const Color(0xFF60A5FA),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: _HeroStat(
                          label: 'Following',
                          icon: Icons.people_alt_outlined,
                          color: const Color(0xFFA78BFA),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: _HeroStat(
                          label: 'Open',
                          icon: Icons.handshake_outlined,
                          color: const Color(0xFFF9A8D4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
          width: 0.7,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.md,
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accentColor.withValues(alpha: 0.10),
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        child,
      ],
    );
  }
}

class _ProfilesList extends StatefulWidget {
  const _ProfilesList({
    required this.asyncProfiles,
    this.emptyTitle = 'Nothing here yet',
    this.emptySubtitle = 'Profiles will appear here once your network grows.',
  });

  final AsyncValue<List<ProfileModel>> asyncProfiles;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  State<_ProfilesList> createState() => _ProfilesListState();
}

class _ProfilesListState extends State<_ProfilesList> {
  List<ProfileModel>? _cachedProfiles;

  @override
  void didUpdateWidget(covariant _ProfilesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final latest = widget.asyncProfiles.asData?.value;
    if (latest != null) {
      _cachedProfiles = latest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.asyncProfiles.asData?.value;
    if (latest != null) {
      _cachedProfiles = latest;
    }

    final cachedProfiles = _cachedProfiles;
    if (cachedProfiles != null) {
      if (cachedProfiles.isEmpty) {
        return AppEmptyState(
          title: widget.emptyTitle,
          subtitle: widget.emptySubtitle,
          icon: Icons.people_outline,
        );
      }

      return Column(
        children: cachedProfiles
            .take(8)
            .map((profile) => _ProfileTile(profile: profile))
            .toList(growable: false),
      );
    }

    return widget.asyncProfiles.when(
      data: (_) => const SizedBox.shrink(),
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSizes.lg),
        child: Center(child: AppLoader()),
      ),
      error: (error, stackTrace) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFA78BFA).withValues(alpha: 0.075),
              width: 0.7,
            ),
            boxShadow: ShadowStyle.lightShadow(),
          ),
          child: const ListTile(
            leading: Icon(Icons.error_outline),
            title: Text('Unable to load profiles'),
          ),
        );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile});

  final ProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final intent = _intentLabel(profile.collaborationIntent);
    final stage = _stageLabel(profile.projectStage);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFA78BFA).withValues(alpha: 0.075),
            width: 0.7,
          ),
          boxShadow: ShadowStyle.lightShadow(),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => navigateToProfile(
                context: context,
                uid: profile.uid,
                isSelfProfile: false,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AppUserAvatar(avatarUrl: profile.avatarUrl, radius: 26),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: _intentColor(profile.collaborationIntent),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profile.name.isEmpty ? 'Unnamed Builder' : profile.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              _TinyStatusBadge(label: intent),
                            ],
                          ),
                          if (profile.role.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              profile.role,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                          const SizedBox(height: AppSizes.sm),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              _SmallChip(label: stage),
                              ...profile.lookingFor
                                  .where((item) => item.trim().isNotEmpty)
                                  .take(2)
                                  .map((item) => _SmallChip(label: item)),
                            ],
                          ),
                          if (profile.need.trim().isNotEmpty) ...[
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              'Needs: ${profile.need}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.25,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _intentColor(String value) {
    switch (value) {
      case 'hiring':
        return const Color(0xFF60A5FA);
      case 'looking_for_cofounder':
        return const Color(0xFFA78BFA);
      case 'open_to_consulting':
        return const Color(0xFFF59E0B);
      case 'not_looking':
        return const Color(0xFF94A3B8);
      case 'open_to_collaborate':
      default:
        return const Color(0xFF22C55E);
    }
  }

  String _intentLabel(String value) {
    switch (value) {
      case 'hiring':
        return 'Hiring';
      case 'looking_for_cofounder':
        return 'Cofounder';
      case 'open_to_consulting':
        return 'Consulting';
      case 'not_looking':
        return 'Not looking';
      case 'open_to_collaborate':
      default:
        return 'Collaborate';
    }
  }

  String _stageLabel(String value) {
    switch (value) {
      case 'idea':
        return 'Idea';
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

class _TinyStatusBadge extends StatelessWidget {
  const _TinyStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.08),
          width: 0.7,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6D28D9),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.55,
            ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.06),
          width: 0.7,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
