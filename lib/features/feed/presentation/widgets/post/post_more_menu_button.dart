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
      builder: (context) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Report post'),
                subtitle: Text('Pick the best reason'),
              ),
              const Divider(height: 1),
              ...['Spam', 'Harassment', 'Misinformation', 'NSFW', 'Other'].map(
                (label) => ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(label),
                  onTap: () => Navigator.of(context).pop(label),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

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
