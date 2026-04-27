import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../data/models/post_model.dart';
import '../providers/post_providers.dart';
import '../widgets/feed_post_card.dart';
import '../widgets/comments/comment_composer_bar.dart';

class PostCommentsPage extends ConsumerStatefulWidget {
  const PostCommentsPage({super.key, required this.post});

  final PostModel post;

  @override
  ConsumerState<PostCommentsPage> createState() => _PostCommentsPageState();
}

class _PostCommentsPageState extends ConsumerState<PostCommentsPage> {
  static const int _maxCommentChars = 500;

  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();

    if (text.isEmpty) return;

    if (text.length > _maxCommentChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment must be 500 characters or less.'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    final controller = ref.read(postControllerProvider.notifier);
    await controller.addComment(postId: widget.post.id, text: text);

    if (!mounted) return;
    setState(() => _isSending = false);
    final state = ref.read(postControllerProvider);

    if (state.hasError) {
      final error = state.asError?.error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to add comment.')));
      if (error != null) {
        debugPrint('Add comment failed: $error');
      }
      return;
    }

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(postCommentsProvider(widget.post.id));

    return AppScaffold(
      safeArea: false,
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: commentsState.when(
              data: (comments) {
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: comments.length + 1,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return FeedPostCard(
                        post: widget.post,
                        onCommentTap: () {},
                      );
                    }

                    final comment = comments[index - 1];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment.authorAvatarUrl != null
                            ? NetworkImage(comment.authorAvatarUrl!)
                            : null,
                        child: comment.authorAvatarUrl == null
                            ? Text(
                                comment.authorName.isNotEmpty
                                    ? comment.authorName[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(
                        comment.authorName.isEmpty
                            ? 'Unknown Builder'
                            : comment.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(comment.text),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  const Center(child: Text('Unable to load comments.')),
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
