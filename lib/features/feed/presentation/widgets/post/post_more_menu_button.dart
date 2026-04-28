import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../data/models/post_model.dart';
import '../../providers/post_providers.dart';

class PostMoreMenuButton extends ConsumerWidget {
  const PostMoreMenuButton({super.key, required this.post});

  final PostModel post;

  String _postLink() {
    // No public web domain yet. Keep a stable in-app style link for copy/share.
    return 'linkai://posts/${post.id}';
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _postLink()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  Future<void> _share(BuildContext context) async {
    // TODO: Replace with share_plus when you’re ready to add it.
    await _copyLink(context);
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AppBottomSheet(
          child: _ReasonSheet(
            title: 'Report post',
            subtitle: 'Choose a reason for this report.',
            options: const [
              (label: 'Spam', icon: Icons.mail_outlined),
              (label: 'Harassment', icon: Icons.warning_outlined),
              (label: 'Misinformation', icon: Icons.info_outlined),
              (label: 'NSFW', icon: Icons.visibility_off_outlined),
              (label: 'Other', icon: Icons.flag_outlined),
            ],
            onSelected: (value) => Navigator.of(context).pop(value),
          ),
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

    // Show confirmation before reporting
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report this post?'),
        content: const Text(
          'Your report helps us keep the community safe. Reports are reviewed by our team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (confirmed != true) return;

    await ref
        .read(postControllerProvider.notifier)
        .reportPost(postId: post.id, reason: reason);

    if (!context.mounted) return;
    final state = ref.read(postControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to report post.')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reported. Thank you.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      iconSize: 10,
      constraints: const BoxConstraints.tightFor(width: 68, height: 68),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      tooltip: 'More',
      onPressed: () async {
        final action = await showModalBottomSheet<_PostMenuAction>(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return _PostActionsSheet(
              post: post,
              onSelected: (value) => Navigator.of(context).pop(value),
            );
          },
        );

        if (!context.mounted) return;
        if (action == null) return;
        switch (action) {
          case _PostMenuAction.copyLink:
            await _copyLink(context);
            break;
          case _PostMenuAction.share:
            await _share(context);
            break;
          case _PostMenuAction.report:
            await _report(context, ref);
            break;
        }
      },
      icon: const Icon(Icons.more_horiz, size: 18),
    );
  }
}

enum _PostMenuAction { share, copyLink, report }

class _PostActionsSheet extends StatelessWidget {
  const _PostActionsSheet({required this.post, required this.onSelected});

  final PostModel post;
  final ValueChanged<_PostMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final authorLabel = post.authorName.trim().isEmpty
        ? 'Post'
        : post.authorName;
    final authorInitial = authorLabel.substring(0, 1).toUpperCase();
    final previewText = post.text.trim().isEmpty
        ? 'No text content'
        : post.text.trim();

    return SafeArea(
      top: false,
      child: AppBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Post actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      authorInitial,
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          previewText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppBottomSheetActionTile(
              icon: Icons.share_outlined,
              title: 'Share post',
              onTap: () => onSelected(_PostMenuAction.share),
            ),
            const SizedBox(height: 8),
            AppBottomSheetActionTile(
              icon: Icons.link_rounded,
              title: 'Copy link',
              onTap: () => onSelected(_PostMenuAction.copyLink),
            ),
            const SizedBox(height: 8),
            AppBottomSheetActionTile(
              icon: Icons.flag_outlined,
              title: 'Report post',
              isDestructive: true,
              onTap: () => onSelected(_PostMenuAction.report),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _ReasonOption = ({String label, IconData icon});

class _ReasonSheet extends StatelessWidget {
  const _ReasonSheet({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final List<_ReasonOption> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
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
