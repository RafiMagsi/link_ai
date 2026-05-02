import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/post_model.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import 'feed_post_card.dart';
import 'modern/modern_post_card.dart';
import 'snow_post/snow_post_card.dart';

class PostDesignSwitcher extends ConsumerWidget {
  const PostDesignSwitcher({
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
    final appConfig = ref.watch(appConfigProvider).asData?.value;
    final designStyle = appConfig?.postDesignStyle ?? 'twitter';

    return switch (designStyle) {
      'snow' => SnowPostCard(
        post: post,
        onCommentTap: onCommentTap,
        onTap: onTap,
      ),
      'modern' => ModernPostCard(
        post: post,
        onCommentTap: onCommentTap,
        onTap: onTap,
      ),
      _ => FeedPostCard(
        post: post,
        onCommentTap: onCommentTap,
        onTap: onTap,
      ),
    };
  }
}
