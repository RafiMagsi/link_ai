import 'package:cloud_firestore/cloud_firestore.dart';

class PostMediaModel {
  final String url;
  final String type;
  final int order;

  const PostMediaModel({
    required this.url,
    required this.type,
    required this.order,
  });

  factory PostMediaModel.fromMap(Map<String, dynamic> map) {
    return PostMediaModel(
      url: map['url'] as String? ?? '',
      type: map['type'] as String? ?? 'image',
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type,
      'order': order,
    };
  }
}

class PostModel {
  final String id;
  final String authorUid;
  final String authorName;
  final String authorRole;
  final String? authorAvatarUrl;
  final String text;
  final List<PostMediaModel> media;
  final int likesCount;
  final int repostsCount;
  final int commentsCount;
  final int savesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PostModel({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatarUrl,
    required this.text,
    required this.media,
    required this.likesCount,
    required this.repostsCount,
    required this.commentsCount,
    required this.savesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return PostModel(
      id: data['id'] as String? ?? doc.id,
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? '',
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
      text: data['text'] as String? ?? '',
      media: ((data['media'] as List?) ?? [])
          .map((item) => PostMediaModel.fromMap(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      likesCount: data['likesCount'] as int? ?? 0,
      repostsCount: data['repostsCount'] as int? ?? 0,
      commentsCount: data['commentsCount'] as int? ?? 0,
      savesCount: data['savesCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorRole': authorRole,
      'authorAvatarUrl': authorAvatarUrl,
      'text': text,
      'media': media.map((item) => item.toMap()).toList(),
      'likesCount': likesCount,
      'repostsCount': repostsCount,
      'commentsCount': commentsCount,
      'savesCount': savesCount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}