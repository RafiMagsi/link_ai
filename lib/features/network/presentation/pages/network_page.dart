import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Network')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(followingProfilesProvider);
          ref.invalidate(collaborationMatchesProvider);
          ref.invalidate(openToCollaborateProfilesProvider);
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            _Section(
              title: 'Collaboration matches',
              subtitle: 'Builders whose needs and skills overlap with yours.',
              child: _ProfilesList(asyncProfiles: matchesState),
            ),
            const SizedBox(height: AppSizes.xl),
            _Section(
              title: 'Following',
              subtitle: 'The people you already follow.',
              child: _ProfilesList(
                asyncProfiles: followingState,
                emptyTitle: 'No follows yet',
                emptySubtitle: 'Follow AI builders to grow your network.',
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            _Section(
              title: 'Open to collaborate',
              subtitle:
                  'People actively open to hiring, feedback, or collaboration.',
              child: _ProfilesList(asyncProfiles: openState),
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
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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
        return const Card(
          child: ListTile(
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
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
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
              AppUserAvatar(avatarUrl: profile.avatarUrl, radius: 26),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name.isEmpty ? 'Unnamed Builder' : profile.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (profile.role.trim().isNotEmpty)
                      Text(
                        profile.role,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SmallChip(
                          label: _intentLabel(profile.collaborationIntent),
                        ),
                        _SmallChip(label: _stageLabel(profile.projectStage)),
                        ...profile.lookingFor
                            .where((item) => item.trim().isNotEmpty)
                            .take(2)
                            .map((item) => _SmallChip(label: item)),
                      ],
                    ),
                    if (profile.need.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Needs: ${profile.need}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
