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
import '../widgets/feed_comment_card.dart';

class CommentDetailPage extends ConsumerStatefulWidget {
  const CommentDetailPage({
    super.key,
    required this.postId,
    required this.commentId,
    this.initialComment,
  });

  final String postId;
  final String commentId;
  final PostCommentModel? initialComment;

  @override
  ConsumerState<CommentDetailPage> createState() => _CommentDetailPageState();
}

class _CommentDetailPageState extends ConsumerState<CommentDetailPage> {
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

  Future<void> _addReply() async {
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

    _captureAutoScrollIntent();
    setState(() => _isSending = true);
    final controller = ref.read(postControllerProvider.notifier);

    try {
      await controller.addComment(
        postId: widget.postId,
        text: text,
        parentCommentId: widget.commentId,
      );
      if (mounted) {
        _commentController.clear();
        if (_shouldAutoScrollAfterSend) {
          _scrollToBottom();
        }
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
                      onSend: () => _addNestedReply(parentCommentId),
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

  Future<void> _addNestedReply(String parentCommentId) async {
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
    final commentsState = ref.watch(postCommentsProvider(widget.postId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comment'),
        centerTitle: true,
      ),
      body: commentsState.when(
        data: (comments) {
          // Find the main comment by ID
          PostCommentModel? mainComment;

          void findComment(PostCommentModel comment) {
            if (comment.id == widget.commentId) {
              mainComment = comment;
            }
            for (final reply in comment.replies) {
              findComment(reply);
            }
          }

          for (final comment in comments) {
            findComment(comment);
          }

          if (mainComment == null) {
            return const AppEmptyState(
              title: 'Comment not found',
              subtitle: 'This comment may have been deleted.',
            );
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Main comment
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.md),
                    child: FeedCommentCard(
                      comment: mainComment!,
                      postId: widget.postId,
                      onReplyTap: () => _showReplyComposer(mainComment!.id),
                      showNestedReplies: false,
                    ),
                  ),
                ),
              ),
              // Divider
              SliverToBoxAdapter(
                child: Divider(
                  height: 1,
                  indent: AppSizes.md,
                  endIndent: AppSizes.md,
                ),
              ),
              // Replies section
              if (mainComment!.replies.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      AppSizes.md,
                      AppSizes.md,
                      AppSizes.sm,
                    ),
                    child: Text(
                      'Replies (${mainComment!.repliesCount})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: AppEmptyState(
                      title: 'No replies yet',
                      subtitle: 'Be the first to reply to this comment',
                    ),
                  ),
                ),
              // Replies list
              if (mainComment!.replies.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  sliver: SliverList.builder(
                    itemBuilder: (context, index) {
                      final reply = mainComment!.replies[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: FeedCommentCard(
                          comment: reply,
                          postId: widget.postId,
                          onReplyTap: () =>
                              _showReplyComposer(reply.id),
                          onCommentTap: () => context.push(
                            '/posts/${widget.postId}/comments/${reply.id}',
                            extra: reply,
                          ),
                          showNestedReplies: false,
                          showNestedIndentation: false,
                        ),
                      );
                    },
                    itemCount: mainComment!.replies.length,
                  ),
                ),
              // Bottom spacing
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.bottom),
              ),
            ],
          );
        },
        loading: () => const Center(child: AppLoader()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      bottomNavigationBar: currentUser == null
          ? null
          : CommentComposerBar(
              controller: _commentController,
              maxChars: _maxCommentChars,
              onSend: _addReply,
              isSending: _isSending,
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
