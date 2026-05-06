import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/widgets/app_user_avatar.dart';
import '../../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../../subscription/presentation/widgets/gold_badge_widget.dart';
import '../../../data/models/post_comment_model.dart';
import '../comments/comment_action_row.dart';

class ModernCommentCard extends ConsumerWidget {
  const ModernCommentCard({
    super.key,
    required this.comment,
    required this.postId,
    required this.onReplyTap,
    this.isBestAnswer = false,
    this.showBestAnswerAction = false,
    this.onBestAnswerToggle,
    this.isBestAnswerUpdating = false,
  });

  final PostCommentModel comment;
  final String postId;
  final VoidCallback onReplyTap;
  final bool isBestAnswer;
  final bool showBestAnswerAction;
  final VoidCallback? onBestAnswerToggle;
  final bool isBestAnswerUpdating;

  String _formatTime(DateTime? createdAt) {
    if (createdAt == null) return 'now';

    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNested = comment.parentCommentId != null;
    final leftPadding = isNested ? 40.0 : 0.0;
    final isAuthorGoldSubscriber = comment.authorUid.isEmpty
        ? false
        : ref.watch(isGoldSubscriberByUidProvider(comment.authorUid));

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isBestAnswer
                  ? colorScheme.primaryContainer.withValues(alpha: 0.28)
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                  color: isBestAnswer
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comment header with avatar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppUserAvatar(
                        avatarUrl: comment.authorAvatarUrl,
                        radius: 16,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    comment.authorName.isEmpty
                                        ? 'Unknown Builder'
                                        : comment.authorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAuthorGoldSubscriber)
                                  const GoldBadgeWidget(
                                    size: 12,
                                    padding: EdgeInsets.only(left: 4),
                                  ),
                                if (isBestAnswer) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Best answer',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(comment.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  // Comment text
                  Text(
                    comment.text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  // Action row
                  CommentActionRow(
                    postId: postId,
                    commentId: comment.id,
                    commentText: comment.text,
                    commentAuthorUid: comment.authorUid,
                    commentAuthorName: comment.authorName,
                    commentAuthorAvatarUrl: comment.authorAvatarUrl,
                    likesCount: comment.likesCount,
                    savesCount: comment.savesCount,
                    repostsCount: comment.repostsCount,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (showBestAnswerAction)
                        TextButton.icon(
                          onPressed: isBestAnswerUpdating
                              ? null
                              : onBestAnswerToggle,
                          icon: isBestAnswerUpdating
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.primary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  isBestAnswer
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.workspace_premium_outlined,
                                  size: 14,
                                ),
                          label: Text(
                            isBestAnswer
                                ? 'Remove best answer'
                                : 'Mark best answer',
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      TextButton.icon(
                        onPressed: onReplyTap,
                        icon: const Icon(Icons.reply_outlined, size: 14),
                        label: const Text('Reply'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Nested replies
          if (comment.replies.isNotEmpty)
            ...comment.replies.map(
              (reply) => ModernCommentCard(
                comment: reply,
                postId: postId,
                isBestAnswer: reply.isBestAnswer,
                onReplyTap: () {
                  // TODO: Handle reply to nested comment
                },
              ),
            ),
        ],
      ),
    );
  }
}
