import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../subscription/presentation/widgets/gold_badge_widget.dart';
import '../../data/models/post_comment_model.dart';
import 'comments/comment_action_row.dart';

class FeedCommentCard extends ConsumerWidget {
  const FeedCommentCard({
    super.key,
    required this.comment,
    required this.postId,
    required this.onReplyTap,
    this.onCommentTap,
    this.isBestAnswer = false,
    this.showBestAnswerAction = false,
    this.onBestAnswerToggle,
    this.isBestAnswerUpdating = false,
    this.showNestedReplies = true,
    this.showNestedIndentation = true,
  });

  final PostCommentModel comment;
  final String postId;
  final VoidCallback onReplyTap;
  final VoidCallback? onCommentTap;
  final bool isBestAnswer;
  final bool showBestAnswerAction;
  final VoidCallback? onBestAnswerToggle;
  final bool isBestAnswerUpdating;
  final bool showNestedReplies;
  final bool showNestedIndentation;

  String _formatTime(DateTime? createdAt) {
    if (createdAt == null) return 'now';

    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  Color _accentColor({required bool isSnowComment}) {
    if (isBestAnswer) return const Color(0xFF22C55E);
    if (isSnowComment) return const Color(0xFF60A5FA);
    return const Color(0xFFA78BFA);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSnowComment = comment.authorUid == 'snow_ai';
    final accentColor = _accentColor(isSnowComment: isSnowComment);
    final isAuthorGoldSubscriber = comment.authorUid.isEmpty
        ? false
        : ref.watch(isGoldSubscriberByUidProvider(comment.authorUid));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        isBestAnswer ? AppSizes.sm : (isSnowComment ? AppSizes.xs : 5),
        AppSizes.md,
        isSnowComment ? AppSizes.xs : 5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accentColor.withValues(alpha: isBestAnswer ? 0.10 : 0.08),
              border: Border.all(
                color: accentColor.withValues(alpha: isBestAnswer ? 0.22 : 0.15),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onCommentTap,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(11, 11, 11, 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppUserAvatar(
                              avatarUrl: comment.authorAvatarUrl,
                              radius: 18,
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _CommentHeader(
                                    comment: comment,
                                    timeText: _formatTime(comment.createdAt),
                                    isSnowComment: isSnowComment,
                                    isBestAnswer: isBestAnswer,
                                    isAuthorGoldSubscriber: isAuthorGoldSubscriber,
                                  ),
                                  const SizedBox(height: 5),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      comment.text,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.34,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.04,
                                      ),
                                    ),
                                  ),
                                  if (!isSnowComment) const SizedBox(height: 46),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isSnowComment)
                    Positioned(
                      left: 62,
                      right: 10,
                      bottom: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFA78BFA).withValues(alpha: 0.20),
                            width: 0.7,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.045),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: 42,
                          child: Row(
                            children: [
                              Expanded(
                                child: CommentActionRow(
                                  postId: postId,
                                  commentId: comment.id,
                                  commentText: comment.text,
                                  commentAuthorUid: comment.authorUid,
                                  commentAuthorName: comment.authorName,
                                  commentAuthorAvatarUrl: comment.authorAvatarUrl,
                                  likesCount: comment.likesCount,
                                  savesCount: comment.savesCount,
                                  repostsCount: comment.repostsCount,
                                  repliesCount: comment.repliesCount,
                                  onReplyTap: onReplyTap,
                                  onCommentTap: onCommentTap,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (showBestAnswerAction)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: isBestAnswerUpdating ? null : onBestAnswerToggle,
                            icon: isBestAnswerUpdating
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        accentColor,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    isBestAnswer
                                        ? Icons.check_circle_rounded
                                        : Icons.workspace_premium_outlined,
                                    size: 20,
                                    color: accentColor,
                                  ),
                            tooltip: isBestAnswer
                                ? 'Unmark best answer'
                                : 'Mark best answer',
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showNestedReplies && comment.replies.isNotEmpty)
            ...comment.replies.map(
              (reply) => FeedCommentCard(
                comment: reply,
                postId: postId,
                isBestAnswer: reply.isBestAnswer,
                showBestAnswerAction: showBestAnswerAction,
                isBestAnswerUpdating: isBestAnswerUpdating,
                onBestAnswerToggle: onBestAnswerToggle,
                onReplyTap: onReplyTap,
                onCommentTap: onCommentTap,
                showNestedReplies: showNestedReplies,
                showNestedIndentation: showNestedIndentation,
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentHeader extends StatelessWidget {
  const _CommentHeader({
    required this.comment,
    required this.timeText,
    required this.isSnowComment,
    required this.isBestAnswer,
    required this.isAuthorGoldSubscriber,
  });

  final PostCommentModel comment;
  final String timeText;
  final bool isSnowComment;
  final bool isBestAnswer;
  final bool isAuthorGoldSubscriber;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  comment.authorName.isEmpty ? 'Unknown Builder' : comment.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.06,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isAuthorGoldSubscriber) ...[
                const SizedBox(width: 4),
                const GoldBadgeWidget(
                  size: 12,
                  padding: EdgeInsets.zero,
                ),
              ],
              if (isSnowComment) ...[
                const SizedBox(width: 6),
                _CommentBadge(
                  label: 'AI',
                  color: const Color(0xFF0284C7),
                ),
              ],
              if (isBestAnswer) ...[
                const SizedBox(width: 6),
                _CommentBadge(
                  label: 'Best',
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.64),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBadge extends StatelessWidget {
  const _CommentBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
