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
    final interactionState = ref.watch(postInteractionStateProvider(post.id));

    final liked = interactionState.asData?.value.liked ?? false;
    final saved = interactionState.asData?.value.saved ?? false;
    final reposted = interactionState.asData?.value.reposted ?? false;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSizes.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PostActionButton(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            active: false,
            count: post.commentsCount,
            onTap: onCommentTap,
          ),
          PostActionButton(
            icon: Icons.repeat,
            activeIcon: Icons.repeat,
            active: reposted,
            count: post.repostsCount,
            onTap: () =>
                ref.read(postControllerProvider.notifier).toggleRepostOfPost(post.id),
          ),
          PostActionButton(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            active: liked,
            count: post.likesCount,
            onTap: () =>
                ref.read(postControllerProvider.notifier).toggleLike(post.id),
          ),
          PostActionButton(
            icon: Icons.bookmark_border,
            activeIcon: Icons.bookmark,
            active: saved,
            count: post.savesCount,
            onTap: () =>
                ref.read(postControllerProvider.notifier).toggleSave(post.id),
          ),
        ],
      ),
    );
  }
}
