import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/profile_view.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final uid = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push('/connect/requests'),
            icon: const Icon(Icons.group_add_outlined),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : ProfileView(
              uid: uid,
              isSelf: true,
              onEditProfile: () => context.push('/profile/edit'),
            ),
    );
  }
}
