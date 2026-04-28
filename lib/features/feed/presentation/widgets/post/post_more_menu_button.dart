import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                          'Report Post',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Help us understand why you\'re reporting this post',
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
                    MapEntry('Misinformation', Icons.info_outlined),
                    MapEntry('NSFW', Icons.visibility_off_outlined),
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
      constraints: const BoxConstraints.tightFor(width: 68, height: 16),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      tooltip: 'More',
      onPressed: () async {
        final action = await showModalBottomSheet<_PostMenuAction>(
          context: context,
          showDragHandle: true,
          builder: (context) {
            return SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Post actions'),
                    subtitle: Text(
                      post.authorName.isEmpty ? 'Post' : post.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Share'),
                    onTap: () =>
                        Navigator.of(context).pop(_PostMenuAction.share),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link),
                    title: const Text('Copy link'),
                    onTap: () =>
                        Navigator.of(context).pop(_PostMenuAction.copyLink),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Report'),
                    onTap: () =>
                        Navigator.of(context).pop(_PostMenuAction.report),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
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
