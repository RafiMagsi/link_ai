import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../data/models/post_model.dart';
import 'post/post_action_row.dart';
import 'post/post_avatar.dart';
import 'post/post_header.dart';
import 'post/post_media_grid.dart';

class FeedPostCard extends ConsumerWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.onCommentTap,
  });

  final PostModel post;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(AppSizes.lg, 14, AppSizes.lg, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostAvatar(name: post.authorName, avatarUrl: post.authorAvatarUrl),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostHeader(post: post),
                const SizedBox(height: 6),
                if (post.text.trim().isNotEmpty)
                  Text(
                    post.text,
                    style: const TextStyle(fontSize: 15.5, height: 1.35),
                  ),
                if (post.media.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  PostMediaGrid(
                    mediaUrls: post.media.map((e) => e.url).toList(),
                  ),
                ],
                const SizedBox(height: AppSizes.sm),
                PostActionRow(post: post, onCommentTap: onCommentTap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
