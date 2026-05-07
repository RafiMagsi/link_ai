import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/post_model.dart';
import '../../providers/post_providers.dart';

class SnowPostActionRow extends ConsumerWidget {
  const SnowPostActionRow({
    super.key,
    required this.post,
    required this.onCommentTap,
  });

  final PostModel post;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactionState = ref.watch(postInteractionStateProvider(post.id));
    final liked = interactionState.asData?.value.liked ?? false;
    final saved = interactionState.asData?.value.saved ?? false;
    final reposted = interactionState.asData?.value.reposted ?? false;
    final mutedColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.86);
    final activeColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 40,
      width: double.infinity,
      child: Row(
        children: [
          _SnowActionButton(
            icon: Icons.mode_comment_outlined,
            label: 'Reply',
            count: post.commentsCount,
            color: mutedColor,
            onTap: onCommentTap,
          ),
          _SnowActionButton(
            icon: reposted ? Icons.repeat_rounded : Icons.repeat_outlined,
            label: 'Repost',
            count: post.repostsCount,
            color: reposted ? activeColor : mutedColor,
            onTap: () =>
                ref.read(postControllerProvider.notifier).toggleRepost(post.id),
          ),
          _SnowActionButton(
            icon: liked ? Icons.favorite : Icons.favorite_outline,
            label: 'Like',
            count: post.likesCount,
            color: liked ? activeColor : mutedColor,
            onTap: () =>
                ref.read(postControllerProvider.notifier).toggleLike(post.id),
          ),
          _SnowActionButton(
            icon: saved ? Icons.bookmark : Icons.bookmark_border_rounded,
            label: 'Save',
            count: post.savesCount,
            color: saved ? activeColor : mutedColor,
            onTap: () =>
                ref.read(postControllerProvider.notifier).toggleSave(post.id),
          ),
        ],
      ),
    );
  }
}

class _SnowActionButton extends StatelessWidget {
  const _SnowActionButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 17, color: color),
                    const SizedBox(width: 6),
                    Text(
                      count > 0 ? '$count' : label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
