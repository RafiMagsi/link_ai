import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/post_comment_model.dart';
import '../../providers/post_providers.dart';
import '../post/post_action_button.dart';

class CommentActionRow extends ConsumerWidget {
  const CommentActionRow({
    super.key,
    required this.postId,
    required this.commentId,
    required this.commentText,
    required this.commentAuthorUid,
    required this.commentAuthorName,
    required this.commentAuthorAvatarUrl,
    required this.likesCount,
    required this.savesCount,
    required this.repostsCount,
    required this.repliesCount,
    this.onReplyTap,
    this.onCommentTap,
  });

  final String postId;
  final String commentId;
  final String commentText;
  final String commentAuthorUid;
  final String commentAuthorName;
  final String? commentAuthorAvatarUrl;
  final int likesCount;
  final int savesCount;
  final int repostsCount;
  final int repliesCount;
  final VoidCallback? onReplyTap;
  final VoidCallback? onCommentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only individual optimistic providers, not the combined state
    final optimisticLiked = ref.watch(optimisticCommentLikeProvider(commentId));
    final optimisticSaved = ref.watch(optimisticCommentSaveProvider(commentId));
    final optimisticReposted = ref.watch(optimisticCommentRepostProvider(commentId));

    final optimisticCounts = ref.watch(optimisticCommentCountProvider);

    late bool isLiked;
    late bool isSaved;
    late bool isReposted;

    // Determine actual state - only read combined provider if all optimistic states are null
    if (optimisticLiked != null || optimisticSaved != null || optimisticReposted != null) {
      // Use optimistic values where available, read from combined provider for the rest
      final realState = ref.watch(
        commentInteractionStateProvider((postId: postId, commentId: commentId)),
      ).asData?.value;
      isLiked = optimisticLiked ?? realState?.liked ?? false;
      isSaved = optimisticSaved ?? realState?.saved ?? false;
      isReposted = optimisticReposted ?? realState?.reposted ?? false;
    } else {
      // No optimistic state, read from combined provider
      final realState = ref.watch(
        commentInteractionStateProvider((postId: postId, commentId: commentId)),
      ).asData?.value;
      isLiked = realState?.liked ?? false;
      isSaved = realState?.saved ?? false;
      isReposted = realState?.reposted ?? false;
    }

    // Build comment model for optimistic updates
    final comment = PostCommentModel(
      id: commentId,
      postId: postId,
      authorUid: commentAuthorUid,
      authorName: commentAuthorName,
      authorAvatarUrl: commentAuthorAvatarUrl,
      text: commentText,
      createdAt: null,
      createdAtClient: null,
      likesCount: likesCount,
      repostsCount: repostsCount,
      savesCount: savesCount,
      repliesCount: repliesCount,
    );

    // Use optimistic counts if available
    final displayComment = optimisticCounts[commentId] ?? comment;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
          PostActionButton(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            active: false,
            count: displayComment.repliesCount,
            onTap: onCommentTap ?? onReplyTap ?? () {},
          ),
          PostActionButton(
            icon: Icons.repeat,
            activeIcon: Icons.repeat,
            active: isReposted,
            count: displayComment.repostsCount,
            onTap: () {
              ref
                  .read(postControllerProvider.notifier)
                  .toggleCommentRepost(
                    postId: postId,
                    commentId: commentId,
                    commentText: commentText,
                    commentAuthorUid: commentAuthorUid,
                    commentAuthorName: commentAuthorName,
                    commentAuthorAvatarUrl: commentAuthorAvatarUrl,
                    comment: comment,
                  );
            },
          ),
          PostActionButton(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            active: isLiked,
            count: displayComment.likesCount,
            onTap: () {
              ref
                  .read(postControllerProvider.notifier)
                  .toggleCommentLike(
                    postId: postId,
                    commentId: commentId,
                    comment: comment,
                  );
            },
          ),
          PostActionButton(
            icon: Icons.bookmark_border,
            activeIcon: Icons.bookmark,
            active: isSaved,
            count: displayComment.savesCount,
            onTap: () {
              ref
                  .read(postControllerProvider.notifier)
                  .toggleCommentSave(
                    postId: postId,
                    commentId: commentId,
                    comment: comment,
                  );
            },
          ),
        ],
      );
  }
}
