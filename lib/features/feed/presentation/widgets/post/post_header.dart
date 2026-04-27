import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../data/models/post_model.dart';
import 'post_more_menu_button.dart';

class PostHeader extends StatelessWidget {
  const PostHeader({
    super.key,
    required this.post,
    this.authorNameOverride,
    this.authorRoleOverride,
  });

  final PostModel post;
  final String? authorNameOverride;
  final String? authorRoleOverride;

  String _timeText() {
    final createdAt = post.createdAt;

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
    final colors = context.appColors;
    final authorName = (authorNameOverride?.trim().isNotEmpty ?? false)
        ? authorNameOverride!.trim()
        : post.authorName;
    final authorRole = (authorRoleOverride?.trim().isNotEmpty ?? false)
        ? authorRoleOverride!.trim()
        : post.authorRole;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            authorName.isEmpty ? 'Unknown Builder' : authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            authorRole.isEmpty ? 'AI Builder' : authorRole,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.mutedText, fontSize: 13),
          ),
        ),
        const SizedBox(width: 6),
        Text('·', style: TextStyle(color: colors.mutedText)),
        const SizedBox(width: 6),
        Text(
          _timeText(),
          style: TextStyle(color: colors.mutedText, fontSize: 13),
        ),
        const Spacer(),
        Align(
          alignment: Alignment.topCenter,
          child: PostMoreMenuButton(post: post)
          ),
      ],
    );
  }
}
