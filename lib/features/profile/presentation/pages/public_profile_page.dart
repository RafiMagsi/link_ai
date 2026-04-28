import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../moderation/presentation/providers/moderation_providers.dart';
import '../widgets/profile_options_sidebar.dart';
import '../widgets/profile_view.dart';

class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({super.key, required this.uid});

  final String uid;

  Future<void> _reportUser(BuildContext context, WidgetRef ref) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AppBottomSheet(
          child: _ProfileReasonSheet(
            onSelected: (value) => Navigator.of(context).pop(value),
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
                      title: Text(isBlocked ? 'Unblock user?' : 'Block user?'),
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
                          child: Text(isBlocked ? 'Unblock' : 'Block'),
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

class _ProfileReasonSheet extends StatelessWidget {
  const _ProfileReasonSheet({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    const options = [
      (label: 'Spam', icon: Icons.mail_outlined),
      (label: 'Harassment', icon: Icons.warning_outlined),
      (label: 'Impersonation', icon: Icons.person_off_outlined),
      (label: 'Scam', icon: Icons.block_outlined),
      (label: 'Other', icon: Icons.flag_outlined),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          'Report user',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Choose a reason for this report.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final option in options) ...[
          AppBottomSheetActionTile(
            icon: option.icon,
            title: option.label,
            onTap: () => onSelected(option.label),
          ),
          if (option != options.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
