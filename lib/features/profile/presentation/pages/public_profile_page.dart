import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../providers/profile_providers.dart';
import '../../../connect/presentation/widgets/connect_button.dart';

final publicProfileProvider = FutureProvider.family.autoDispose((
  ref,
  String uid,
) {
  return ref.watch(profileRemoteDataSourceProvider).getProfile(uid);
});

class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(publicProfileProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Public Profile')),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: AppUserAvatar(avatarUrl: profile.avatarUrl, radius: 42),
              ),
              const SizedBox(height: 16),
              Text(
                profile.name.isEmpty ? 'Unnamed Builder' : profile.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.role.isEmpty ? 'AI Builder' : profile.role,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appColors.mutedText),
              ),
              const SizedBox(height: 24),
              _Section(title: 'Bio', value: profile.bio),
              _Section(title: 'Building', value: profile.building),
              _Section(title: 'Need', value: profile.need),
              _Section(title: 'Want to meet', value: profile.wantToMeet),
              const SizedBox(height: 20),
              ConnectButton(
                targetUid: profile.uid,
                targetName: profile.name.isEmpty ? 'AI Builder' : profile.name,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Unable to load profile.')),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
    );
  }
}
