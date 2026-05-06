import 'package:cloud_firestore/cloud_firestore.dart';

class PostCommentModel {
  final String id;
  final String postId;
  final String authorUid;
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  final DateTime? createdAt;
  final DateTime? createdAtClient;
  final String? parentCommentId;
  final List<PostCommentModel> replies;
  final int likesCount;
  final int repostsCount;
  final int savesCount;
  final bool isBestAnswer;

  const PostCommentModel({
    required this.id,
    required this.postId,
    required this.authorUid,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.text,
    required this.createdAt,
    required this.createdAtClient,
    this.parentCommentId,
    this.replies = const [],
    this.likesCount = 0,
    this.repostsCount = 0,
    this.savesCount = 0,
    this.isBestAnswer = false,
  });

  factory PostCommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return PostCommentModel(
      id: data['id'] as String? ?? doc.id,
      postId: data['postId'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdAtClient: (data['createdAtClient'] as Timestamp?)?.toDate(),
      parentCommentId: data['parentCommentId'] as String?,
      likesCount: data['likesCount'] as int? ?? 0,
      repostsCount: data['repostsCount'] as int? ?? 0,
      savesCount: data['savesCount'] as int? ?? 0,
      isBestAnswer: data['isBestAnswer'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'postId': postId,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'text': text,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
      // Used for immediate ordering on clients (serverTimestamp can be null locally).
      'createdAtClient': Timestamp.now(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static List<PostCommentModel> buildCommentTree(
    List<PostCommentModel> flatComments,
  ) {
    final rootComments = <PostCommentModel>[];
    final commentReplies = <String, List<PostCommentModel>>{};

    // Separate root comments and build replies map
    for (final comment in flatComments) {
      if (comment.parentCommentId == null) {
        rootComments.add(comment);
      } else {
        final parentId = comment.parentCommentId!;
        if (commentReplies[parentId] == null) {
          commentReplies[parentId] = [];
        }
        commentReplies[parentId]!.add(comment);
      }
    }

    // Build the tree recursively
    PostCommentModel buildNode(PostCommentModel comment) {
      final replies = commentReplies[comment.id] ?? [];
      return PostCommentModel(
        id: comment.id,
        postId: comment.postId,
        authorUid: comment.authorUid,
        authorName: comment.authorName,
        authorAvatarUrl: comment.authorAvatarUrl,
        text: comment.text,
        createdAt: comment.createdAt,
        createdAtClient: comment.createdAtClient,
        parentCommentId: comment.parentCommentId,
        replies: replies.map(buildNode).toList(),
        likesCount: comment.likesCount,
        repostsCount: comment.repostsCount,
        savesCount: comment.savesCount,
        isBestAnswer: comment.isBestAnswer,
      );
    }

    return rootComments.map(buildNode).toList();
  }

  PostCommentModel copyWith({
    List<PostCommentModel>? replies,
    bool? isBestAnswer,
  }) {
    return PostCommentModel(
      id: id,
      postId: postId,
      authorUid: authorUid,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      text: text,
      createdAt: createdAt,
      createdAtClient: createdAtClient,
      parentCommentId: parentCommentId,
      replies: replies ?? this.replies,
      likesCount: likesCount,
      repostsCount: repostsCount,
      savesCount: savesCount,
      isBestAnswer: isBestAnswer ?? this.isBestAnswer,
    );
  }
}
