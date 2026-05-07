import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/post_model.dart';
import '../../design/modern_post_design_system.dart';
import '../../providers/post_providers.dart';

class ModernPostActionRow extends ConsumerWidget {
  const ModernPostActionRow({
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ModernPostDesignSystem.cardPadding,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionButton(
            icon: Icons.mode_comment_outlined,
            activeIcon: Icons.mode_comment_outlined,
            active: false,
            label: 'Reply',
            count: post.commentsCount,
            onTap: onCommentTap,
          ),
          _ActionButton(
            icon: Icons.repeat_outlined,
            activeIcon: Icons.repeat_rounded,
            active: reposted,
            label: 'Repost',
            count: post.repostsCount,
            onTap: () {
              ref.read(postControllerProvider.notifier).toggleRepost(post.id);
            },
          ),
          _ActionButton(
            icon: Icons.favorite_outline,
            activeIcon: Icons.favorite,
            active: liked,
            label: 'Like',
            count: post.likesCount,
            onTap: () {
              ref.read(postControllerProvider.notifier).toggleLike(post.id);
            },
          ),
          _ActionButton(
            icon: Icons.bookmark_outline,
            activeIcon: Icons.bookmark,
            active: saved,
            label: 'Save',
            count: post.savesCount,
            onTap: () {
              ref.read(postControllerProvider.notifier).toggleSave(post.id);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 18,
              color: active
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              count > 0 ? '$count' : '',
              style: TextStyle(
                fontSize: 11,
                color: active
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
