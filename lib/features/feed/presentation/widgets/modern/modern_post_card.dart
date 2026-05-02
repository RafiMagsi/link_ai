import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/utils/navigation_utils.dart';
import '../../../../../core/widgets/hashtag_text.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../data/models/post_model.dart';
import '../../design/modern_post_design_system.dart';
import '../../providers/post_providers.dart';
import '../post/post_avatar.dart';
import '../post/post_media_grid.dart';
import '../post/post_more_menu_button.dart';
import 'modern_post_action_row.dart';
import 'modern_post_header.dart';

class ModernPostCard extends ConsumerWidget {
  const ModernPostCard({
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
    final isAuthorGoldSubscriber = post.authorUid.isEmpty
        ? false
        : ref.watch(isGoldSubscriberByUidProvider(post.authorUid));

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

    final accentColor = ModernPostDesignSystem.getAccentColor(post.postType);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 8,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ModernPostDesignSystem.cardBorderRadius),
          color: colorScheme.surface,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.12),
            width: ModernPostDesignSystem.cardBorderWidth,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top accent bar
                Container(
                  height: ModernPostDesignSystem.accentBarWidth,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ModernPostDesignSystem.cardBorderRadius),
                      topRight: Radius.circular(ModernPostDesignSystem.cardBorderRadius),
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.all(ModernPostDesignSystem.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with avatar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PostAvatar(avatarUrl: resolvedAvatarUrl, onTap: onAvatarTap),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: ModernPostHeader(
                              post: post,
                              authorNameOverride: resolvedName,
                              authorRoleOverride: resolvedRole,
                              isGoldSubscriber: isAuthorGoldSubscriber,
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Center(
                              child: PostMoreMenuButton(post: post),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ModernPostDesignSystem.contentGap),
                      // Post text
                      if (post.text.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: HashtagText(
                            text: post.text,
                            style: TextStyle(
                              fontSize: ModernPostDesignSystem.postTextSize,
                              fontWeight: ModernPostDesignSystem.postTextWeight,
                              height: 1.4,
                              letterSpacing: -0.02,
                            ),
                          ),
                        ),
                      // Media
                      if (post.media.isNotEmpty) ...[
                        const SizedBox(height: ModernPostDesignSystem.contentGap),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: PostMediaGrid(
                            mediaUrls: post.media.map((e) => e.url).toList(),
                            heroTagPrefix: 'modern_post_${post.id}_media_',
                            onDoubleTap: () => ref
                                .read(postControllerProvider.notifier)
                                .toggleLike(post.id),
                            onTap: (index) {
                              // Navigate to media gallery
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: ModernPostDesignSystem.contentGap),
                      // Quoted comment (for commentRepost type)
                      if (post.postType == PostType.commentRepost &&
                          post.quotedCommentText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(ModernPostDesignSystem.cardPadding),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                              width: ModernPostDesignSystem.cardBorderWidth,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.quotedCommentAuthorName ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                post.quotedCommentText ?? '',
                                style: const TextStyle(fontSize: 13),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: ModernPostDesignSystem.contentGap),
                      ],
                    ],
                  ),
                ),
                // Divider before action row
                Divider(
                  height: 1,
                  thickness: ModernPostDesignSystem.cardBorderWidth,
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
                // Action row
                ModernPostActionRow(
                  post: post,
                  onCommentTap: onCommentTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
