import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/post_providers.dart';
import '../post/post_action_button.dart';

class CommentActionRow extends ConsumerWidget {
  const CommentActionRow({
    super.key,
    required this.postId,
    required this.commentId,
    required this.commentText,
    required this.commentAuthorName,
    required this.commentAuthorAvatarUrl,
    required this.likesCount,
    required this.savesCount,
    required this.repostsCount,
  });

  final String postId;
  final String commentId;
  final String commentText;
  final String commentAuthorName;
  final String? commentAuthorAvatarUrl;
  final int likesCount;
  final int savesCount;
  final int repostsCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactionState = ref.watch(commentInteractionStateProvider(commentId));
    final optimisticState = ref.watch(optimisticCommentInteractionProvider(commentId));

    late bool isLiked;
    late bool isSaved;
    late bool isReposted;

    if (optimisticState != null) {
      isLiked = optimisticState.liked;
      isSaved = optimisticState.saved;
      isReposted = optimisticState.reposted;
    } else if (interactionState.asData case final asyncData?) {
      isLiked = asyncData.value.liked;
      isSaved = asyncData.value.saved;
      isReposted = asyncData.value.reposted;
    } else {
      isLiked = false;
      isSaved = false;
      isReposted = false;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PostActionButton(
            icon: Icons.favorite_outline,
            activeIcon: Icons.favorite,
            active: isLiked,
            count: likesCount,
            onTap: () {
              ref.read(postControllerProvider.notifier).toggleCommentLike(
                postId: postId,
                commentId: commentId,
              );
            },
          ),
          PostActionButton(
            icon: Icons.repeat_outlined,
            activeIcon: Icons.repeat,
            active: isReposted,
            count: repostsCount,
            onTap: () {
              ref.read(postControllerProvider.notifier).toggleCommentRepost(
                postId: postId,
                commentId: commentId,
                commentText: commentText,
                commentAuthorName: commentAuthorName,
                commentAuthorAvatarUrl: commentAuthorAvatarUrl,
              );
            },
          ),
          PostActionButton(
            icon: Icons.bookmark_outline,
            activeIcon: Icons.bookmark,
            active: isSaved,
            count: savesCount,
            onTap: () {
              ref.read(postControllerProvider.notifier).toggleCommentSave(
                postId: postId,
                commentId: commentId,
              );
            },
          ),
        ],
      ),
    );
  }
}
