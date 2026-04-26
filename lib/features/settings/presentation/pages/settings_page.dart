import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/settings_providers.dart';
import '../../../admin/presentation/providers/admin_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This will delete your Firebase account. Profile cleanup will be improved with Cloud Functions later. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.currentUser?.delete();

      if (context.mounted) {
        context.go('/login');
      }
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;

      final message = error.code == 'requires-recent-login'
          ? 'Please logout and login again before deleting your account.'
          : 'Unable to delete account.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(userSettingsProvider);
    final controllerState = ref.watch(settingsControllerProvider);
    final adminStatus = ref.watch(adminStatusProvider);
    final isAdmin = adminStatus.asData?.value == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsState.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isAdmin)
                _SettingsSection(
                  title: 'Admin',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings),
                      title: const Text('Global Settings'),
                      subtitle: const Text('Limits, feature flags, throttles'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/admin/settings'),
                    ),
                  ],
                ),
              if (isAdmin) const SizedBox(height: 18),
              _SettingsSection(
                title: 'Account & Profile',
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Edit Profile'),
                    subtitle: const Text('Name, bio, skills, links, avatar'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/edit'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsSection(
                title: 'Notifications',
                children: [
                  SwitchListTile(
                    value: settings.notifyLikes,
                    title: const Text('Likes'),
                    subtitle: const Text('Notify when someone likes your post'),
                    onChanged: controllerState.isLoading
                        ? null
                        : (value) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(notifyLikes: value),
                                );
                          },
                  ),
                  SwitchListTile(
                    value: settings.notifyReposts,
                    title: const Text('Reposts'),
                    subtitle: const Text(
                      'Notify when someone reposts your post',
                    ),
                    onChanged: controllerState.isLoading
                        ? null
                        : (value) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(notifyReposts: value),
                                );
                          },
                  ),
                  SwitchListTile(
                    value: settings.notifyComments,
                    title: const Text('Comments'),
                    subtitle: const Text(
                      'Notify when someone comments on your post',
                    ),
                    onChanged: controllerState.isLoading
                        ? null
                        : (value) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(notifyComments: value),
                                );
                          },
                  ),
                  SwitchListTile(
                    value: settings.notifySaves,
                    title: const Text('Saves'),
                    subtitle: const Text('Notify when someone saves your post'),
                    onChanged: controllerState.isLoading
                        ? null
                        : (value) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(notifySaves: value),
                                );
                          },
                  ),
                  SwitchListTile(
                    value: settings.notifyConnectRequests,
                    title: const Text('Connect Requests'),
                    subtitle: const Text(
                      'Notify when someone wants to connect',
                    ),
                    onChanged: controllerState.isLoading
                        ? null
                        : (value) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(
                                    notifyConnectRequests: value,
                                  ),
                                );
                          },
                  ),
                  SwitchListTile(
                    value: settings.notifyProductActivity,
                    title: const Text('Product Activity'),
                    subtitle: const Text(
                      'Notify for product saves, comments, and updates',
                    ),
                    onChanged: controllerState.isLoading
                        ? null
                        : (value) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(
                                    notifyProductActivity: value,
                                  ),
                                );
                          },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsSection(
                title: 'App Preferences',
                children: [
                  SwitchListTile(
                    value: settings.videoAutoplay,
                    title: const Text('Video Autoplay'),
                    subtitle: const Text(
                      'Automatically play videos in the feed',
                    ),
                    onChanged: controllerState.isLoading
                        ? null
                        : (value) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(videoAutoplay: value),
                                );
                          },
                  ),
                  SwitchListTile(
                    value: settings.muteVideosByDefault,
                    title: const Text('Mute Videos by Default'),
                    subtitle: const Text(
                      'Videos start muted unless you unmute them',
                    ),
                    onChanged: controllerState.isLoading
                        ? null
                        : (value) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(muteVideosByDefault: value),
                                );
                          },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsSection(
                title: 'Account',
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () {
                      ref.read(authControllerProvider.notifier).logout();
                      context.go('/login');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Permanent account deletion'),
                    onTap: () => _deleteAccount(context, ref),
                  ),
                  const ListTile(
                    leading: Icon(Icons.link),
                    title: Text('Manage Login Providers'),
                    subtitle: Text('Coming later'),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Unable to load settings.')),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
