import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/widgets/app_loader.dart';
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
                final action = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) {
                    return SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ListTile(title: Text('Profile actions')),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: const Text('Settings'),
                            onTap: () => Navigator.of(context).pop('settings'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.group_add_outlined),
                            title: const Text('Connect requests'),
                            onTap: () =>
                                Navigator.of(context).pop('connect_requests'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Logout'),
                            onTap: () => Navigator.of(context).pop('logout'),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                );

                if (!context.mounted || action == null) return;
                if (action == 'settings') {
                  context.push('/settings');
                  return;
                }
                if (action == 'connect_requests') {
                  context.push('/connect/requests');
                  return;
                }
                if (action == 'logout') {
                  ref.read(authControllerProvider.notifier).logout();
                }
              },
            ),
    );
  }
}
