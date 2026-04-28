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
import 'post/post_more_menu_button.dart';

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

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 5,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colorScheme.surface,
          border: Border.all(
            color: const Color(0xFFA78BFA).withValues(alpha: 0.10),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFFA78BFA).withValues(alpha: 0.025),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
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
                        const Color(0xFF60A5FA).withValues(alpha: 0.055),
                        const Color(0xFF60A5FA).withValues(alpha: 0.00),
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
                        const Color(0xFFF9A8D4).withValues(alpha: 0.055),
                        const Color(0xFFF9A8D4).withValues(alpha: 0.00),
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
                    padding: const EdgeInsets.fromLTRB(11, 11, 11, 7),
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
                              const SizedBox(height: 5),
                              if (post.text.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: HashtagText(
                                    text: post.text,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      height: 1.34,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.05,
                                    ),
                                  ),
                                ),
                              if (post.media.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: PostMediaGrid(
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
                    color: colorScheme.surface.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.10),
                      width: 0.7,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 42,
                    child: PostActionRow(
                      post: post,
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
                        color: const Color(0xFFA78BFA).withValues(alpha: 0.0),
                        width: 0.7,
                      ),
                    ),
                    child: Center(
                      child: PostMoreMenuButton(post: post),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
