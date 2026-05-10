import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum PostType { thought, ship, ask, commentRepost, repost }

enum PostIntent { general, launch, feedback, hiring, cofounder, question }

class ShipMeta {
  final String projectName;
  final String tagline;
  final String? ctaUrl;
  final String? demoUrl;

  const ShipMeta({
    required this.projectName,
    required this.tagline,
    this.ctaUrl,
    this.demoUrl,
  });

  factory ShipMeta.fromMap(Map<String, dynamic> map) {
    return ShipMeta(
      projectName: (map['projectName'] as String?)?.trim() ?? '',
      tagline: (map['tagline'] as String?)?.trim() ?? '',
      ctaUrl: (map['ctaUrl'] as String?)?.trim(),
      demoUrl: (map['demoUrl'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectName': projectName,
      'tagline': tagline,
      'ctaUrl': ctaUrl,
      'demoUrl': demoUrl,
    };
  }
}

class AskMeta {
  final String question;
  final List<String> topics;
  final int answerCount;

  const AskMeta({
    required this.question,
    required this.topics,
    required this.answerCount,
  });

  factory AskMeta.fromMap(Map<String, dynamic> map) {
    final topicsList =
        (map['topics'] as List?)
            ?.whereType<String>()
            .map((t) => t.trim())
            .toList() ??
        [];
    return AskMeta(
      question: (map['question'] as String?)?.trim() ?? '',
      topics: topicsList,
      answerCount: (map['answerCount'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'question': question, 'topics': topics, 'answerCount': answerCount};
  }
}

class PostMediaModel {
  final String url;
  final String type;
  final int order;
  final String? thumbnailUrl;
  final String? hlsUrl;
  final String status;

  const PostMediaModel({
    required this.url,
    required this.type,
    required this.order,
    this.thumbnailUrl,
    this.hlsUrl,
    this.status = 'ready',
  });

  factory PostMediaModel.fromMap(Map<String, dynamic> map) {
    try {
      // Safely extract and validate fields
      final url = (map['url'] as String?)?.trim() ?? '';
      final type = (map['type'] as String?)?.trim() ?? 'image';
      final order = _safeParseInt(map['order']);
      final thumbnailUrl = (map['thumbnailUrl'] as String?)?.trim();
      final hlsUrl = (map['hlsUrl'] as String?)?.trim();
      final status = (map['status'] as String?)?.trim() ?? 'ready';

      // Validate URL format
      if (url.isNotEmpty && !_isValidUrl(url)) {
        debugPrint('Invalid URL in PostMediaModel: $url');
      }

      return PostMediaModel(
        url: url,
        type: type,
        order: order,
        thumbnailUrl: thumbnailUrl?.isEmpty == true ? null : thumbnailUrl,
        hlsUrl: hlsUrl?.isEmpty == true ? null : hlsUrl,
        status: status,
      );
    } catch (e) {
      debugPrint('Error parsing PostMediaModel from map: $e');
      return PostMediaModel(
        url: (map['url'] as String?) ?? '',
        type: (map['type'] as String?) ?? 'image',
        order: 0,
      );
    }
  }

  static int _safeParseInt(dynamic value) {
    try {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    } catch (e) {
      debugPrint('Error parsing int value: $e');
      return 0;
    }
  }

  static bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'url': url,
        'type': type,
        'order': order,
        'thumbnailUrl': thumbnailUrl,
        'hlsUrl': hlsUrl,
        'status': status,
      };
    } catch (e) {
      debugPrint('Error converting PostMediaModel to map: $e');
      return {'url': '', 'type': 'image', 'order': 0};
    }
  }
}

class PostModel {
  final String id;
  final String authorUid;
  final String authorName;
  final String authorRole;
  final String? authorAvatarUrl;
  final String text;
  final List<String> hashtags;
  final List<PostMediaModel> media;
  final int likesCount;
  final int repostsCount;
  final int commentsCount;
  final int savesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PostType postType;
  final ShipMeta? shipMeta;
  final AskMeta? askMeta;
  final String? quotedCommentId;
  final String? quotedCommentText;
  final String? quotedCommentAuthorName;
  final String? quotedCommentAuthorAvatarUrl;
  final String? quotedCommentAuthorUid;
  final String? quotedPostId;
  final String? bestAnswerCommentId;
  final String colorCode;
  final PostIntent postIntent;

  const PostModel({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatarUrl,
    required this.text,
    required this.hashtags,
    required this.media,
    required this.likesCount,
    required this.repostsCount,
    required this.commentsCount,
    required this.savesCount,
    required this.createdAt,
    required this.updatedAt,
    required this.colorCode,
    this.postIntent = PostIntent.general,
    this.postType = PostType.thought,
    this.shipMeta,
    this.askMeta,
    this.quotedCommentId,
    this.quotedCommentText,
    this.quotedCommentAuthorName,
    this.quotedCommentAuthorAvatarUrl,
    this.quotedCommentAuthorUid,
    this.quotedPostId,
    this.bestAnswerCommentId,
  });

  bool get isPostRepost {
    return postType == PostType.repost ||
        (postType == PostType.commentRepost &&
            quotedPostId != null &&
            quotedCommentId == null &&
            text.trim().isEmpty);
  }

  String get detailPostId {
    return isPostRepost && quotedPostId != null ? quotedPostId! : id;
  }

  factory PostModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data() ?? {};

      PostType postType = PostType.thought;
      final typeStr = data['postType'] as String?;
      if (typeStr != null) {
        postType = PostType.values.firstWhere(
          (e) => e.toString() == 'PostType.$typeStr',
          orElse: () => PostType.thought,
        );
      }

      ShipMeta? shipMeta;
      if (postType == PostType.ship && data['shipMeta'] != null) {
        shipMeta = ShipMeta.fromMap(
          Map<String, dynamic>.from(data['shipMeta'] as Map),
        );
      }

      AskMeta? askMeta;
      if (postType == PostType.ask && data['askMeta'] != null) {
        askMeta = AskMeta.fromMap(
          Map<String, dynamic>.from(data['askMeta'] as Map),
        );
      }

      PostIntent postIntent = PostIntent.general;
      final intentStr = data['postIntent'] as String?;
      if (intentStr != null) {
        postIntent = PostIntent.values.firstWhere(
          (e) => e.toString() == 'PostIntent.$intentStr',
          orElse: () => PostIntent.general,
        );
      }

      return PostModel(
        id: _safeString(data['id'], fallback: doc.id),
        authorUid: _safeString(data['authorUid']),
        authorName: _safeString(data['authorName']),
        authorRole: _safeString(data['authorRole']),
        authorAvatarUrl: data['authorAvatarUrl'] as String?,
        text: _safeString(data['text']),
        hashtags: _safeStringList(data['hashtags']),
        media: _safeMediaList(data['media']),
        likesCount: _safeInt(data['likesCount']),
        repostsCount: _safeInt(data['repostsCount']),
        commentsCount: _safeInt(data['commentsCount']),
        savesCount: _safeInt(data['savesCount']),
        createdAt: _safeTimestamp(data['createdAt']),
        updatedAt: _safeTimestamp(data['updatedAt']),
        postType: postType,
        shipMeta: shipMeta,
        askMeta: askMeta,
        postIntent: postIntent,
        quotedCommentId: data['quotedCommentId'] as String?,
        quotedCommentText: data['quotedCommentText'] as String?,
        quotedCommentAuthorName: data['quotedCommentAuthorName'] as String?,
        quotedCommentAuthorAvatarUrl:
            data['quotedCommentAuthorAvatarUrl'] as String?,
        quotedCommentAuthorUid: data['quotedCommentAuthorUid'] as String?,
        quotedPostId: data['quotedPostId'] as String?,
        bestAnswerCommentId: data['bestAnswerCommentId'] as String?,
        colorCode: _safeString(data['colorCode'], fallback: '0xFF60A5FA'),
      );
    } catch (e) {
      debugPrint('Error parsing PostModel from Firestore: $e');
      return PostModel(
        id: doc.id,
        authorUid: '',
        authorName: '',
        authorRole: '',
        authorAvatarUrl: null,
        text: '',
        hashtags: const [],
        media: const [],
        likesCount: 0,
        repostsCount: 0,
        commentsCount: 0,
        savesCount: 0,
        createdAt: null,
        updatedAt: null,
        postIntent: PostIntent.general,
        postType: PostType.thought,
        bestAnswerCommentId: null,
        colorCode: '0xFF60A5FA',
      );
    }
  }

  static String _safeString(dynamic value, {String fallback = ''}) {
    try {
      if (value == null) return fallback;
      if (value is String) return value.trim();
      return value.toString().trim();
    } catch (e) {
      return fallback;
    }
  }

  static int _safeInt(dynamic value) {
    try {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static List<String> _safeStringList(dynamic value) {
    try {
      if (value == null) return [];
      if (value is List) {
        return value
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error parsing string list: $e');
      return [];
    }
  }

  static List<PostMediaModel> _safeMediaList(dynamic value) {
    try {
      if (value == null) return [];
      if (value is List) {
        return value
            .map((item) {
              try {
                return PostMediaModel.fromMap(
                  Map<String, dynamic>.from(item as Map),
                );
              } catch (e) {
                debugPrint('Error parsing media item: $e');
                return null;
              }
            })
            .whereType<PostMediaModel>()
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error parsing media list: $e');
      return [];
    }
  }

  static DateTime? _safeTimestamp(dynamic value) {
    try {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    } catch (e) {
      debugPrint('Error parsing timestamp: $e');
      return null;
    }
  }

  Map<String, dynamic> toCreateMap() {
    final map = {
      'id': id,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorRole': authorRole,
      'authorAvatarUrl': authorAvatarUrl,
      'text': text,
      'hashtags': hashtags,
      'media': media.map((item) => item.toMap()).toList(),
      'likesCount': likesCount,
      'repostsCount': repostsCount,
      'commentsCount': commentsCount,
      'savesCount': savesCount,
      'postType': postType.toString().split('.').last,
      'postIntent': postIntent.toString().split('.').last,
      'colorCode': colorCode,
      'deleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'bestAnswerCommentId': bestAnswerCommentId,
    };

    if (shipMeta != null) {
      map['shipMeta'] = shipMeta!.toMap();
    }
    if (askMeta != null) {
      map['askMeta'] = askMeta!.toMap();
    }

    return map;
  }

  PostModel copyWith({
    String? id,
    String? authorUid,
    String? authorName,
    String? authorRole,
    String? authorAvatarUrl,
    String? text,
    List<String>? hashtags,
    List<PostMediaModel>? media,
    int? likesCount,
    int? repostsCount,
    int? commentsCount,
    int? savesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    PostType? postType,
    ShipMeta? shipMeta,
    AskMeta? askMeta,
    String? quotedCommentId,
    String? quotedCommentText,
    String? quotedCommentAuthorName,
    String? quotedCommentAuthorAvatarUrl,
    String? quotedCommentAuthorUid,
    String? quotedPostId,
    String? bestAnswerCommentId,
    String? colorCode,
    PostIntent? postIntent,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      text: text ?? this.text,
      hashtags: hashtags ?? this.hashtags,
      media: media ?? this.media,
      likesCount: likesCount ?? this.likesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      savesCount: savesCount ?? this.savesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      postType: postType ?? this.postType,
      shipMeta: shipMeta ?? this.shipMeta,
      askMeta: askMeta ?? this.askMeta,
      quotedCommentId: quotedCommentId ?? this.quotedCommentId,
      quotedCommentText: quotedCommentText ?? this.quotedCommentText,
      quotedCommentAuthorName:
          quotedCommentAuthorName ?? this.quotedCommentAuthorName,
      quotedCommentAuthorAvatarUrl:
          quotedCommentAuthorAvatarUrl ?? this.quotedCommentAuthorAvatarUrl,
      quotedCommentAuthorUid:
          quotedCommentAuthorUid ?? this.quotedCommentAuthorUid,
      quotedPostId: quotedPostId ?? this.quotedPostId,
      bestAnswerCommentId: bestAnswerCommentId ?? this.bestAnswerCommentId,
      colorCode: colorCode ?? this.colorCode,
      postIntent: postIntent ?? this.postIntent,
    );
  }
}
