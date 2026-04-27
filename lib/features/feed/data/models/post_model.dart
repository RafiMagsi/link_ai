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
    try {
      // Safely extract and validate fields
      final url = (map['url'] as String?)?.trim() ?? '';
      final type = (map['type'] as String?)?.trim() ?? 'image';
      final order = _safeParseInt(map['order']);

      // Validate URL format
      if (url.isNotEmpty && !_isValidUrl(url)) {
        print('Invalid URL in PostMediaModel: $url');
      }

      return PostMediaModel(
        url: url,
        type: type,
        order: order,
      );
    } catch (e) {
      print('Error parsing PostMediaModel from map: $e');
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
      print('Error parsing int value: $e');
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
      return {'url': url, 'type': type, 'order': order};
    } catch (e) {
      print('Error converting PostMediaModel to map: $e');
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
  });

  factory PostModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data() ?? {};

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
      );
    } catch (e) {
      print('Error parsing PostModel from Firestore: $e');
      // Return a minimal valid post on error
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
      print('Error parsing string list: $e');
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
                print('Error parsing media item: $e');
                return null;
              }
            })
            .whereType<PostMediaModel>()
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing media list: $e');
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
      print('Error parsing timestamp: $e');
      return null;
    }
  }

  Map<String, dynamic> toCreateMap() {
    return {
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
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
