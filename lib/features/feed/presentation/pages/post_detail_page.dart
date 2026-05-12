import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/post_comment_model.dart';
import '../providers/post_providers.dart';
import '../widgets/comments/comment_composer_bar.dart';
import '../widgets/feed_post_card.dart';
import '../widgets/feed_comment_card.dart';
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
  String? _updatingBestAnswerCommentId;

  @override
  void initState() {
    super.initState();
    debugPrint('═══════════ POST DETAIL PAGE ═══════════');
    debugPrint('Post ID: ${widget.postId}');
    debugPrint('Has initial post: ${widget.initialPost != null}');
    debugPrint('═════════════════════════════════════════');
  }

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

  bool _supportsBestAnswer(PostIntent intent) {
    return intent == PostIntent.question || intent == PostIntent.feedback;
  }

  List<PostCommentModel> _applyBestAnswerFlag(
    List<PostCommentModel> comments,
    String? bestAnswerCommentId,
  ) {
    PostCommentModel mapComment(PostCommentModel comment) {
      final replies = comment.replies.map(mapComment).toList();
      return comment.copyWith(
        replies: replies,
        isBestAnswer: comment.id == bestAnswerCommentId,
      );
    }

    final mapped = comments.map(mapComment).toList();
    if (bestAnswerCommentId == null) return mapped;

    mapped.sort((a, b) {
      if (a.isBestAnswer == b.isBestAnswer) return 0;
      return a.isBestAnswer ? -1 : 1;
    });
    return mapped;
  }

  Future<void> _setBestAnswer({
    required PostModel post,
    required String? commentId,
  }) async {
    setState(() => _updatingBestAnswerCommentId = commentId ?? '__clear__');

    final controller = ref.read(postControllerProvider.notifier);
    await controller.setBestAnswer(
      postId: widget.postId,
      postIntent: post.postIntent,
      commentId: commentId,
    );

    if (!mounted) return;
    setState(() => _updatingBestAnswerCommentId = null);

    final state = ref.read(postControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update best answer.')),
      );
    }
  }

  Future<void> _showReplyComposer(String parentCommentId) async {
    _commentController.clear();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reply to comment',
      barrierColor: Colors.black.withValues(alpha: 0.34),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutExpo,
          reverseCurve: Curves.easeInCubic,
        );

        return Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: curved,
            builder: (context, _) {
              final value = curved.value;
              final slide = 96 * (1 - value);
              final scaleY = 0.90 + (0.10 * value);
              final scaleX = 0.985 + (0.015 * value);
              final opacity = value.clamp(0.0, 1.0);

              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, slide),
                  child: Transform.scale(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    alignment: Alignment.bottomCenter,
                    child: _ReplyComposerSheet(
                      animationValue: value,
                      controller: _commentController,
                      isSending: _isSending,
                      onSend: () => _addReply(parentCommentId),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      _commentController.clear();
    });
  }

  Future<void> _addReply(String parentCommentId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (text.length > _maxCommentChars) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply must be 500 characters or less.'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    final controller = ref.read(postControllerProvider.notifier);

    try {
      await controller.addComment(
        postId: widget.postId,
        text: text,
        parentCommentId: parentCommentId,
      );
      if (mounted) {
        Navigator.of(context).pop();
        _commentController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: $e')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 POST DETAIL BUILD: ${widget.postId}');
    final postState = ref.watch(postByIdProvider(widget.postId));
    final commentsState = ref.watch(postCommentsProvider(widget.postId));
    final currentUser = ref.watch(currentUserProvider);

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

                final supportsBestAnswer = _supportsBestAnswer(
                  resolvedPost.postIntent,
                );
                final canManageBestAnswer =
                    supportsBestAnswer &&
                    currentUser?.uid == resolvedPost.authorUid;

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
                    if (supportsBestAnswer)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.lg,
                          0,
                          AppSizes.lg,
                          AppSizes.sm,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Icon(
                                Icons.workspace_premium_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  resolvedPost.bestAnswerCommentId == null
                                      ? 'Mark one helpful comment as the best answer.'
                                      : 'Best answer selected for this discussion.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              if (canManageBestAnswer &&
                                  resolvedPost.bestAnswerCommentId != null)
                                TextButton(
                                  onPressed:
                                      _updatingBestAnswerCommentId != null
                                      ? null
                                      : () => _setBestAnswer(
                                          post: resolvedPost,
                                          commentId: null,
                                        ),
                                  child: const Text('Clear'),
                                ),
                            ],
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
                        final decoratedComments = _applyBestAnswerFlag(
                          comments,
                          resolvedPost.bestAnswerCommentId,
                        );

                        // Show only top-level comments (no parent)
                        final topLevelComments = decoratedComments
                            .where((c) => c.parentCommentId == null)
                            .toList();

                        if (topLevelComments.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(AppSizes.xl),
                              child: Center(child: Text('No comments yet.')),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final comment = topLevelComments[index];
                            return FeedCommentCard(
                              comment: comment,
                              postId: widget.postId,
                              isBestAnswer: comment.isBestAnswer,
                              showBestAnswerAction: canManageBestAnswer,
                              isBestAnswerUpdating:
                                  _updatingBestAnswerCommentId ==
                                  (comment.isBestAnswer
                                      ? '__clear__'
                                      : comment.id),
                              onBestAnswerToggle: () => _setBestAnswer(
                                post: resolvedPost,
                                commentId: comment.isBestAnswer
                                    ? null
                                    : comment.id,
                              ),
                              onReplyTap: () => _showReplyComposer(comment.id),
                              onCommentTap: () =>
                                  context.push('/posts/${widget.postId}/comments/${comment.id}', extra: comment),
                              showNestedReplies: false,
                            );
                          }, childCount: topLevelComments.length),
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

class _ReplyComposerSheet extends StatelessWidget {
  const _ReplyComposerSheet({
    required this.animationValue,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final double animationValue;
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final appBarHeight = 56.0;
    final topInset = statusBarHeight + appBarHeight;
    final sheetHeight = (screenHeight * 0.64).clamp(430.0, 590.0);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(top: topInset, bottom: keyboardHeight),
        child: SizedBox(
          height: sheetHeight,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          'Reply to comment',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(40, 40),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CommentComposerBar(
                        controller: controller,
                        maxChars: 500,
                        onSend: onSend,
                        isSending: isSending,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
