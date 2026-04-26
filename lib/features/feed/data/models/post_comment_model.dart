import 'package:cloud_firestore/cloud_firestore.dart';

class PostCommentModel {
  final String id;
  final String postId;
  final String authorUid;
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  final DateTime? createdAt;

  const PostCommentModel({
    required this.id,
    required this.postId,
    required this.authorUid,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.text,
    required this.createdAt,
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
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}