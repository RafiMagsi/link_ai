import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/post_model.dart';
import '../providers/post_providers.dart';
import '../widgets/feed_post_card.dart';

class PostCommentsPage extends ConsumerStatefulWidget {
  const PostCommentsPage({super.key, required this.post});

  final PostModel post;

  @override
  ConsumerState<PostCommentsPage> createState() => _PostCommentsPageState();
}

class _PostCommentsPageState extends ConsumerState<PostCommentsPage> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();

    if (text.isEmpty) return;

    await ref
        .read(postControllerProvider.notifier)
        .addComment(postId: widget.post.id, text: text);

    final state = ref.read(postControllerProvider);

    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to add comment.')));
      return;
    }

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(postCommentsProvider(widget.post.id));

    return Scaffold(
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
                      const Divider(height: 1, color: Color(0xFF1E293B)),
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
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addComment,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
