import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/widgets/app_loader.dart';
import '../widgets/profile_options_sidebar.dart';
import '../widgets/profile_view.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, this.showBackButton = false});
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final uid = user?.uid;

    return Scaffold(
      body: uid == null
          ? const Center(child: AppLoader())
          : ProfileView(
              uid: uid,
              isSelf: true,
              showBackButton: showBackButton,
              onEditProfile: () => context.push('/profile/edit'),
              onOpenMenu: () async {
                await showProfileOptionsSidebar(
                  context: context,
                  title: 'Profile options',
                  actions: [
                    ProfileSidebarAction(
                      icon: Icons.bookmark_border,
                      label: 'View saved',
                      onTap: () {
                        if (context.mounted) context.push('/profile/saved');
                      },
                    ),
                    ProfileSidebarAction(
                      icon: Icons.people_outline,
                      label: 'My network',
                      onTap: () {
                        if (context.mounted) context.push('/network');
                      },
                    ),
                    ProfileSidebarAction(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () {
                        if (context.mounted) context.push('/notifications');
                      },
                    ),
                    ProfileSidebarAction(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {
                        if (context.mounted) context.push('/settings');
                      },
                    ),
                    ProfileSidebarAction(
                      icon: Icons.support_agent_outlined,
                      label: 'Support',
                      onTap: () {
                        if (context.mounted) context.push('/support');
                      },
                    ),
                    ProfileSidebarAction(
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: () {
                        ref.read(authControllerProvider.notifier).logout();
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
