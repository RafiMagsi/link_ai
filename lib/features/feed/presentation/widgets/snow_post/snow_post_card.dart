import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/utils/navigation_utils.dart';
import '../../../data/models/post_model.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import 'snow_post_header.dart';
import 'snow_post_thought_body.dart';
import 'snow_post_ship_body.dart';
import 'snow_post_ask_body.dart';
import 'snow_post_action_row.dart';

class SnowPostCard extends ConsumerWidget {
  const SnowPostCard({
    super.key,
    required this.post,
    required this.onCommentTap,
    this.onTap,
  });

  final PostModel post;
  final VoidCallback onCommentTap;
  final VoidCallback? onTap;

  Color _getAccentColor(PostType type) {
    return switch (type) {
      PostType.thought => const Color(0xFF8B877E),
      PostType.ship => const Color(0xFF5FA51F),
      PostType.ask => const Color(0xFF2B8FE8),
      PostType.commentRepost => const Color(0xFF8B877E),
    };
  }

  Color _getSoftAccentColor(PostType type) {
    return switch (type) {
      PostType.thought => const Color(0xFFF1EFE8),
      PostType.ship => const Color(0xFFEAF6DD),
      PostType.ask => const Color(0xFFE7F2FF),
      PostType.commentRepost => const Color(0xFFF1EFE8),
    };
  }

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

    final accentColor = _getAccentColor(post.postType);
    final softAccentColor = _getSoftAccentColor(post.postType);
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 5,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              Color.alphaBlend(
                softAccentColor.withValues(alpha: 0.18),
                colorScheme.surface,
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: dividerColor.withValues(alpha: 0.14),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor,
                            accentColor.withValues(alpha: 0.58),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const SizedBox(width: 3.5),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 11, 12, 9),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SnowPostHeader(
                              post: post,
                              avatarUrl: resolvedAvatarUrl,
                              authorName: resolvedName,
                              authorRole: resolvedRole,
                              onAvatarTap: onAvatarTap,
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: KeyedSubtree(
                                key: ValueKey(post.postType),
                                child: switch (post.postType) {
                                  PostType.thought => SnowPostThoughtBody(
                                      post: post,
                                    ),
                                  PostType.ship => SnowPostShipBody(
                                      post: post,
                                    ),
                                  PostType.ask => SnowPostAskBody(
                                      post: post,
                                    ),
                                  PostType.commentRepost => SnowPostThoughtBody(
                                      post: post,
                                    ),
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Divider(
                              height: 1,
                              thickness: 0.7,
                              color: dividerColor.withValues(alpha: 0.18),
                            ),
                            const SizedBox(height: 4),
                            SnowPostActionRow(
                              post: post,
                              onCommentTap: onCommentTap,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
