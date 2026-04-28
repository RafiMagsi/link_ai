import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../moderation/presentation/providers/moderation_providers.dart';
import '../widgets/profile_options_sidebar.dart';
import '../widgets/profile_view.dart';

class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({super.key, required this.uid});

  final String uid;

  Future<void> _reportUser(BuildContext context, WidgetRef ref) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Report User',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Help us understand why you're reporting this user",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...[
                    MapEntry('Spam', Icons.mail_outlined),
                    MapEntry('Harassment', Icons.warning_outlined),
                    MapEntry('Impersonation', Icons.person_off_outlined),
                    MapEntry('Scam', Icons.block_outlined),
                    MapEntry('Other', Icons.flag_outlined),
                  ].map((entry) {
                    final label = entry.key;
                    final icon = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(label),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  icon,
                                  size: 20,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

    await ref
        .read(moderationControllerProvider.notifier)
        .reportUser(targetUid: uid, reason: reason);

    if (!context.mounted) return;
    final state = ref.read(moderationControllerProvider);
    final message = state.hasError
        ? 'Unable to report user right now.'
        : 'User reported. Thank you.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBlocked =
        ref.watch(blockStatusProvider(uid)).asData?.value ?? false;

    return Scaffold(
      body: ProfileView(
        uid: uid,
        isSelf: false,
        showBackButton: true,
        onEditProfile: () {},
        onOpenMenu: () async {
          await showProfileOptionsSidebar(
            context: context,
            title: 'Profile options',
            actions: [
              ProfileSidebarAction(
                icon: Icons.link,
                label: 'Copy profile link',
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: 'linkai://profiles/$uid'),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Link copied')));
                },
              ),
              ProfileSidebarAction(
                icon: Icons.flag_outlined,
                label: 'Report user',
                onTap: () => _reportUser(context, ref),
              ),
              ProfileSidebarAction(
                icon: isBlocked
                    ? Icons.lock_open_outlined
                    : Icons.block_outlined,
                label: isBlocked ? 'Unblock user' : 'Block user',
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        isBlocked ? 'Unblock user?' : 'Block user?',
                      ),
                      content: Text(
                        isBlocked
                            ? 'You will be able to see this user\'s content again.'
                            : 'You won\'t see this user\'s posts and they won\'t be able to message you.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            isBlocked ? 'Unblock' : 'Block',
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  if (isBlocked) {
                    await ref
                        .read(moderationControllerProvider.notifier)
                        .unblockUser(uid);
                  } else {
                    await ref
                        .read(moderationControllerProvider.notifier)
                        .blockUser(uid);
                  }

                  if (!context.mounted) return;
                  final state = ref.read(moderationControllerProvider);
                  final message = state.hasError
                      ? 'Unable to update block status.'
                      : isBlocked
                      ? 'User unblocked.'
                      : 'User blocked.';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
