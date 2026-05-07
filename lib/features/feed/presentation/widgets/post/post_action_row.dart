import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../data/models/post_model.dart';
import '../../providers/post_providers.dart';
import 'post_action_button.dart';

class PostActionRow extends ConsumerWidget {
  const PostActionRow({
    super.key,
    required this.post,
    required this.onCommentTap,
  });

  final PostModel post;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only individual optimistic providers, not the combined state
    final optimisticLiked = ref.watch(optimisticLikeProvider(post.id));
    final optimisticSaved = ref.watch(optimisticSaveProvider(post.id));
    final optimisticReposted = ref.watch(optimisticRepostProvider(post.id));

    final optimisticCounts = ref.watch(optimisticPostCountProvider);

    // Determine actual state - only read combined provider if all optimistic states are null
    late bool liked;
    late bool saved;
    late bool reposted;

    if (optimisticLiked != null || optimisticSaved != null || optimisticReposted != null) {
      // Use optimistic values where available, read from combined provider for the rest
      final realState = ref.watch(postInteractionStateProvider(post.id)).asData?.value;
      liked = optimisticLiked ?? realState?.liked ?? false;
      saved = optimisticSaved ?? realState?.saved ?? false;
      reposted = optimisticReposted ?? realState?.reposted ?? false;
    } else {
      // No optimistic state, read from combined provider
      final realState = ref.watch(postInteractionStateProvider(post.id)).asData?.value;
      liked = realState?.liked ?? false;
      saved = realState?.saved ?? false;
      reposted = realState?.reposted ?? false;
    }

    // Use optimistic count if available, otherwise use post count
    final displayPost = optimisticCounts[post.id] ?? post;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSizes.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PostActionButton(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            active: false,
            count: displayPost.commentsCount,
            onTap: onCommentTap,
          ),
          PostActionButton(
            icon: Icons.repeat,
            activeIcon: Icons.repeat,
            active: reposted,
            count: displayPost.repostsCount,
            onTap: () =>
                ref.read(postControllerProvider.notifier).toggleRepost(post.id, post: post),
          ),
          PostActionButton(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            active: liked,
            count: displayPost.likesCount,
            onTap: () =>
                ref.read(postControllerProvider.notifier).toggleLike(post.id, post: post),
          ),
          PostActionButton(
            icon: Icons.bookmark_border,
            activeIcon: Icons.bookmark,
            active: saved,
            count: displayPost.savesCount,
            onTap: () =>
                ref.read(postControllerProvider.notifier).toggleSave(post.id, post: post),
          ),
        ],
      ),
    );
  }
}
