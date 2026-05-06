import 'package:flutter/material.dart';

import '../../../data/models/post_model.dart';
import '../../design/modern_post_design_system.dart';
import '../../../../subscription/presentation/widgets/gold_badge_widget.dart';
import '../../utils/post_intent_ui.dart';

class ModernPostHeader extends StatelessWidget {
  const ModernPostHeader({
    super.key,
    required this.post,
    this.authorNameOverride,
    this.authorRoleOverride,
    this.isGoldSubscriber = false,
  });

  final PostModel post;
  final String? authorNameOverride;
  final String? authorRoleOverride;
  final bool isGoldSubscriber;

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
  Widget build(BuildContext context) {
    final displayName = (authorNameOverride?.trim().isNotEmpty ?? false)
        ? authorNameOverride!
        : (post.authorName.isEmpty ? 'AI Builder' : post.authorName);
    final displayRole = (authorRoleOverride?.trim().isNotEmpty ?? false)
        ? authorRoleOverride!
        : (post.authorRole.isEmpty ? 'Builder' : post.authorRole);
    final timeText = _formatTime(post.createdAt);
    final typeLabel = ModernPostDesignSystem.getTypeLabel(post.postType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: ModernPostDesignSystem.authorNameSize,
                        fontWeight: ModernPostDesignSystem.authorNameWeight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isGoldSubscriber)
                    const GoldBadgeWidget(size: 14, padding: EdgeInsets.only(left: 4)),
                ],
              ),
            ),
            if (typeLabel != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ModernPostDesignSystem.getAccentColor(post.postType)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ModernPostDesignSystem.getAccentColor(post.postType),
                  ),
                ),
              ),
            ],
            if (postIntentLabel(post.postIntent) != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: postIntentColor(post.postIntent).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  postIntentLabel(post.postIntent)!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: postIntentColor(post.postIntent),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              displayRole,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Text(
              '· $timeText',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
