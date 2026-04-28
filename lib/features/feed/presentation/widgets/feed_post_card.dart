import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/hashtag_text.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/models/post_model.dart';
import '../providers/post_providers.dart';
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
    final authorProfile = post.authorUid.isEmpty
        ? null
        : ref.watch(profileByUidProvider(post.authorUid)).asData?.value;

    final resolvedAvatarUrl = authorProfile?.avatarUrl ?? post.authorAvatarUrl;
    final resolvedName = (authorProfile?.name.trim().isNotEmpty ?? false)
        ? authorProfile!.name.trim()
        : post.authorName;
    final resolvedRole = (authorProfile?.role.trim().isNotEmpty ?? false)
        ? authorProfile!.role.trim()
        : post.authorRole;

    final onAvatarTap = post.authorUid.isEmpty
        ? null
        : () async {
            final isSelfProfile = currentUid != null && post.authorUid == currentUid;
            await navigateToProfile(
              context: context,
              uid: post.authorUid,
              isSelfProfile: isSelfProfile,
            );
          };

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.lg, 6, 0, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PostAvatar(avatarUrl: resolvedAvatarUrl, onTap: onAvatarTap),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PostHeader(
                      post: post,
                      authorNameOverride: resolvedName,
                      authorRoleOverride: resolvedRole,
                    ),
                    const SizedBox(height: 2),
                    if (post.text.trim().isNotEmpty)
                      HashtagText(
                        text: post.text,
                        style: const TextStyle(fontSize: 15.5, height: 1.32),
                      ),
                    if (post.media.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      PostMediaGrid(
                        mediaUrls: post.media.map((e) => e.url).toList(),
                        heroTagPrefix: 'post_${post.id}_media_',
                        onDoubleTap: () => ref
                            .read(postControllerProvider.notifier)
                            .toggleLike(post.id),
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
