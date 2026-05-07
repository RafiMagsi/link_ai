import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../providers/settings_providers.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_loader.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This permanently deletes your account data, including your profile, settings, posts, comments, follows, saves, notification tokens, and related records. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(accountDeletionControllerProvider.notifier)
          .deleteMyAccount();
      final state = ref.read(accountDeletionControllerProvider);

      if (state.hasError) {
        throw state.error!;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully.')),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          context.go('/login');
        }
      }
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;

      final message = error.code == 'requires-recent-login'
          ? 'Please logout and login again before deleting your account.'
          : ErrorHandler.getUserFriendlyMessage(error);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _deleteAccount(context, ref),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete account: ${ErrorHandler.getUserFriendlyMessage(e)}',
          ),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _deleteAccount(context, ref),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(userSettingsProvider);
    final controllerState = ref.watch(settingsControllerProvider);
    final adminStatus = ref.watch(adminStatusRefreshProvider);
    final isGoldSubscriber = ref.watch(isGoldSubscriberProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsState.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              adminStatus.when(
                data: (isAdminValue) {
                  if (isAdminValue) {
                    return Column(
                      children: [
                        _SettingsSection(
                          title: 'Admin',
                          children: [
                            ListTile(
                              leading: const Icon(Icons.admin_panel_settings),
                              title: const Text('Global Settings'),
                              subtitle: const Text(
                                'Limits, feature flags, throttles',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                try {
                                  if (context.mounted) {
                                    context.push('/admin/settings');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ErrorHandler.getUserFriendlyMessage(
                                            e,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: SizedBox(height: 20, child: AppLoader()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Failed to check admin status',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _SettingsSection(
                title: 'Account & Profile',
                children: [
                  ListTile(
                    leading: const Icon(Icons.smart_toy_outlined),
                    title: const Text('Snow AI'),
                    subtitle: Text(
                      isGoldSubscriber
                          ? 'Open your AI assistant chat'
                          : 'Gold members can chat with Snow AI',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      isGoldSubscriber ? '/snow-chat' : '/subscription',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: Text(isGoldSubscriber ? 'Manage Gold' : 'Get Gold'),
                    subtitle: Text(
                      isGoldSubscriber
                          ? 'Subscription status, restore, manage billing'
                          : 'Unlock @snow and premium AI features',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/subscription'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Edit Profile'),
                    subtitle: const Text('Name, bio, skills, links, avatar'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      try {
                        if (context.mounted) {
                          context.push('/profile/edit');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ErrorHandler.getUserFriendlyMessage(e),
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsSection(
                title: 'Safety & Legal',
                children: [
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: const Text('Support'),
                    subtitle: const Text('Contact, moderation, and help'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/support'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/legal/privacy'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms of Use'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/legal/terms'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: const Text('Community Guidelines'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/legal/guidelines'),
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
                            try {
                              ref
                                  .read(settingsControllerProvider.notifier)
                                  .updateSettings(
                                    settings.copyWith(notifyLikes: value),
                                  );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to update settings: ${ErrorHandler.getUserFriendlyMessage(e)}',
                                    ),
                                  ),
                                );
                              }
                            }
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
                    title: const Text('New followers'),
                    subtitle: const Text('Notify when someone follows you'),
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
                  _ThemeModeTile(
                    themeMode: settings.themeMode,
                    isLoading: controllerState.isLoading,
                    onChanged: (themeMode) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .updateSettings(
                            settings.copyWith(themeMode: themeMode),
                          );
                    },
                  ),
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
                      try {
                        ref.read(authControllerProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Logout failed: ${ErrorHandler.getUserFriendlyMessage(e)}',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    subtitle: const Text('Permanent account deletion'),
                    onTap: () => _deleteAccount(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.alternate_email_rounded),
                    title: const Text('Sign-in method'),
                    subtitle: const Text('Email and password'),
                    trailing: Icon(
                      Icons.verified_user_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: AppLoader()),
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

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.themeMode,
    required this.isLoading,
    required this.onChanged,
  });

  final String themeMode;
  final bool isLoading;
  final ValueChanged<String> onChanged;

  IconData _iconFor(String value) {
    return switch (value) {
      'dark' => Icons.dark_mode,
      'light' => Icons.light_mode,
      _ => Icons.brightness_auto,
    };
  }

  String _labelFor(String value) {
    return switch (value) {
      'dark' => 'Dark',
      'light' => 'Light',
      _ => 'Auto',
    };
  }

  @override
  Widget build(BuildContext context) {
    final selected = switch (themeMode) {
      'light' || 'dark' => themeMode,
      _ => 'system',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(selected)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Theme',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Current: ${_labelFor(selected)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'system',
                icon: Icon(Icons.brightness_auto),
                label: Text('Auto'),
              ),
              ButtonSegment<String>(
                value: 'light',
                icon: Icon(Icons.light_mode),
                label: Text('Light'),
              ),
              ButtonSegment<String>(
                value: 'dark',
                icon: Icon(Icons.dark_mode),
                label: Text('Dark'),
              ),
            ],
            selected: {selected},
            onSelectionChanged: isLoading
                ? null
                : (value) {
                    onChanged(value.first);
                  },
          ),
        ],
      ),
    );
  }
}
