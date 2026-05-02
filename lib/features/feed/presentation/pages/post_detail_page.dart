import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loader.dart';
import '../providers/post_providers.dart';
import '../widgets/comments/comment_composer_bar.dart';
import '../widgets/feed_post_card.dart';
import '../widgets/modern/modern_comment_card.dart';
import '../../data/models/post_model.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.postId, this.initialPost});

  final String postId;
  final PostModel? initialPost;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  static const int _maxCommentChars = 500;

  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isSending = false;
  bool _shouldAutoScrollAfterSend = true;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _captureAutoScrollIntent() {
    if (!_scrollController.hasClients) {
      _shouldAutoScrollAfterSend = true;
      return;
    }

    final position = _scrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    _shouldAutoScrollAfterSend = distanceToBottom < 120;
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (text.length > _maxCommentChars) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment must be 500 characters or less.'),
        ),
      );
      return;
    }

    _captureAutoScrollIntent();
    setState(() => _isSending = true);
    final controller = ref.read(postControllerProvider.notifier);
    await controller.addComment(postId: widget.postId, text: text);

    if (!mounted) return;
    setState(() => _isSending = false);
    final state = ref.read(postControllerProvider);

    if (state.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to add comment.')));
      return;
    }

    _commentController.clear();
    if (_shouldAutoScrollAfterSend) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postByIdProvider(widget.postId));
    final commentsState = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: postState.when(
              data: (post) {
                final resolvedPost = post ?? widget.initialPost;

                if (resolvedPost == null) {
                  return const AppEmptyState(
                    title: 'Post not found',
                    subtitle: 'It may have been deleted.',
                    icon: Icons.forum_outlined,
                  );
                }

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: FeedPostCard(
                        post: resolvedPost,
                        onTap: null,
                        onCommentTap: _scrollToBottom,
                      ),
                    ),
                    if (resolvedPost.hashtags.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.lg,
                          0,
                          AppSizes.lg,
                          AppSizes.sm,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: resolvedPost.hashtags
                                .map(
                                  (tag) => ActionChip(
                                    label: Text('#$tag'),
                                    onPressed: () =>
                                        context.push('/hashtags/$tag'),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: Divider(height: 1)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                        vertical: AppSizes.sm,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Comments',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    commentsState.when(
                      data: (comments) {
                        if (comments.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(AppSizes.xl),
                              child: Center(child: Text('No comments yet.')),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final comment = comments[index];
                              return ModernCommentCard(
                                comment: comment,
                                postId: widget.postId,
                                onReplyTap: () {
                                  // TODO: Open reply composer for this comment
                                },
                              );
                            },
                            childCount: comments.length,
                          ),
                        );
                      },
                      loading: () => const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppSizes.xl),
                          child: Center(child: AppLoader()),
                        ),
                      ),
                      error: (error, stackTrace) => const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppSizes.xl),
                          child: Center(
                            child: Text('Unable to load comments.'),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  ],
                );
              },
              loading: () => const Center(child: AppLoader()),
              error: (error, stackTrace) =>
                  const Center(child: Text('Unable to load post.')),
            ),
          ),
          CommentComposerBar(
            controller: _commentController,
            maxChars: _maxCommentChars,
            onSend: _addComment,
            isSending: _isSending,
          ),
        ],
      ),
    );
  }
}

