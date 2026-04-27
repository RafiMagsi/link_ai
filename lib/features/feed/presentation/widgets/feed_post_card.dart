import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/hashtag_text.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/post_model.dart';
import '../pages/media_gallery_page.dart';
import 'post/post_action_row.dart';
import 'post/post_avatar.dart';
import 'post/post_header.dart';
import 'post/post_media_grid.dart';

class FeedPostCard extends ConsumerWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.onCommentTap,
    this.onTap,
  });

  final PostModel post;
  final VoidCallback onCommentTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUserProvider)?.uid;
    final onAvatarTap = post.authorUid.isEmpty
        ? null
        : () {
            if (currentUid != null && post.authorUid == currentUid) {
              context.push('/profile');
              return;
            }
            context.push('/profiles/${post.authorUid}');
          };

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.lg, 14, AppSizes.lg, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PostAvatar(avatarUrl: post.authorAvatarUrl, onTap: onAvatarTap),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PostHeader(post: post),
                    const SizedBox(height: 6),
                    if (post.text.trim().isNotEmpty)
                      HashtagText(
                        text: post.text,
                        style: const TextStyle(fontSize: 15.5, height: 1.35),
                      ),
                    if (post.media.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      PostMediaGrid(
                        mediaUrls: post.media.map((e) => e.url).toList(),
                        heroTagPrefix: 'post_${post.id}_media_',
                        onTap: (index) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MediaGalleryPage(
                                mediaUrls: post.media
                                    .map((e) => e.url)
                                    .toList(),
                                initialIndex: index,
                                heroTagPrefix: 'post_${post.id}_media_',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: AppSizes.sm),
                    PostActionRow(post: post, onCommentTap: onCommentTap),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
