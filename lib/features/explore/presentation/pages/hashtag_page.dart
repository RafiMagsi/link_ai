import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../feed/presentation/providers/post_providers.dart';
import '../../../feed/presentation/widgets/feed_post_card.dart';

class HashtagPage extends ConsumerWidget {
  const HashtagPage({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(postsByHashtagProvider(tag));

    return Scaffold(
      appBar: AppBar(title: Text('#$tag')),
      body: state.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const AppEmptyState(
              title: 'No posts yet',
              subtitle: 'Be the first to post with this hashtag.',
              icon: Icons.tag,
            );
          }

          return ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final post = posts[index];
              final detailPostId = post.detailPostId;
              final detailExtra = detailPostId == post.id ? post : null;
              return FeedPostCard(
                post: post,
                onTap: () =>
                    context.push('/posts/$detailPostId', extra: detailExtra),
                onCommentTap: () =>
                    context.push('/posts/$detailPostId', extra: detailExtra),
              );
            },
          );
        },
        loading: () => const Center(child: AppLoader()),
        error: (error, stackTrace) => const Padding(
          padding: EdgeInsets.all(AppSizes.xl),
          child: Center(child: Text('Unable to load hashtag feed.')),
        ),
      ),
    );
  }
}
