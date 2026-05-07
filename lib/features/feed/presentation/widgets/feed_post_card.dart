import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/post_colors.dart';
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
import 'post/post_more_menu_button.dart';
import 'repost_header.dart';

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
    final isRepost = post.isPostRepost;

    // For reposts, fetch the original post data
    final originalPost = isRepost && post.quotedPostId != null
        ? ref.watch(postByIdProvider(post.quotedPostId!)).asData?.value
        : null;

    // Use original post data if this is a repost, otherwise use current post
    final displayPost = originalPost ?? post;

    // Get author profile
    final authorProfile = ref
        .watch(profileByUidProvider(displayPost.authorUid))
        .asData
        ?.value;

    final resolvedAvatarUrl =
        authorProfile?.avatarUrl ?? displayPost.authorAvatarUrl;
    final resolvedName = (authorProfile?.name.trim().isNotEmpty ?? false)
        ? authorProfile!.name.trim()
        : displayPost.authorName;
    final resolvedRole = (authorProfile?.role.trim().isNotEmpty ?? false)
        ? authorProfile!.role.trim()
        : displayPost.authorRole;

    // Navigate to the original post author's profile
    final profileUid = displayPost.authorUid.isNotEmpty
        ? displayPost.authorUid
        : null;
    final reposterUid = post.authorUid.isNotEmpty ? post.authorUid : null;

    final onAvatarTap = profileUid != null
        ? () async {
            final isSelfProfile =
                currentUid != null && profileUid == currentUid;
            await navigateToProfile(
              context: context,
              uid: profileUid,
              isSelfProfile: isSelfProfile,
            );
          }
        : null;
    final onReposterTap = reposterUid != null
        ? () async {
            final isSelfProfile =
                currentUid != null && reposterUid == currentUid;
            await navigateToProfile(
              context: context,
              uid: reposterUid,
              isSelfProfile: isSelfProfile,
            );
          }
        : null;

    final colorScheme = Theme.of(context).colorScheme;
    // Use the repost's color (which has its own random color), not the original post's
    final postColor = PostColors.colorFromHex(post.colorCode);
    final complementaryColor = _getComplementaryColor(postColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: postColor.withValues(alpha: 0.05),
          border: Border.all(
            color: postColor.withValues(alpha: 0.90),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: postColor.withValues(alpha: 0.025),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            children: [
              if (isRepost)
                RepostHeader(post: post, onAuthorTap: onReposterTap),
              Stack(
                children: [
                  Positioned(
                    top: -72,
                    right: -60,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            postColor.withValues(alpha: 0.055),
                            postColor.withValues(alpha: 0.00),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -82,
                    left: -66,
                    child: Container(
                      width: 185,
                      height: 185,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            complementaryColor.withValues(alpha: 0.055),
                            complementaryColor.withValues(alpha: 0.00),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          11,
                          isRepost ? 0 : 11,
                          11,
                          7,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PostAvatar(
                              avatarUrl: resolvedAvatarUrl,
                              onTap: onAvatarTap,
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PostHeader(
                                    post: displayPost,
                                    authorNameOverride: resolvedName,
                                    authorRoleOverride: resolvedRole,
                                  ),
                                  const SizedBox(height: 5),
                                  if (displayPost.text.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: HashtagText(
                                        text: displayPost.text,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          height: 1.34,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: -0.05,
                                        ),
                                      ),
                                    ),
                                  if (displayPost.media.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: PostMediaGrid(
                                        mediaUrls: displayPost.media
                                            .map((e) => e.url)
                                            .toList(),
                                        heroTagPrefix:
                                            'post_${displayPost.id}_media_',
                                        onDoubleTap: () => ref
                                            .read(
                                              postControllerProvider.notifier,
                                            )
                                            .toggleLike(displayPost.id),
                                        onTap: (index) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => MediaGalleryPage(
                                                mediaUrls: displayPost.media
                                                    .map((e) => e.url)
                                                    .toList(),
                                                initialIndex: index,
                                                heroTagPrefix:
                                                    'post_${displayPost.id}_media_',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 42),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 62,
                    right: 10,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(
                            0xFFA78BFA,
                          ).withValues(alpha: 0.20),
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
                        child: PostActionRow(
                          post: displayPost,
                          onCommentTap: onCommentTap,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFA78BFA,
                            ).withValues(alpha: 0.0),
                            width: 0.7,
                          ),
                        ),
                        child: Center(child: PostMoreMenuButton(post: post)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getComplementaryColor(Color color) {
    final hslColor = HSLColor.fromColor(color);
    final complementary = hslColor.withHue((hslColor.hue + 180) % 360);
    return complementary.toColor();
  }
}
