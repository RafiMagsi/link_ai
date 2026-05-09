import 'package:flutter/foundation.dart';

class VideoModel {
  final String id;
  final String url;
  final String? hlsUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String type;
  final int order;

  const VideoModel({
    required this.id,
    required this.url,
    this.hlsUrl,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    this.type = 'video',
    this.order = 0,
  });

  factory VideoModel.fromPostMedia({
    required String url,
    String? hlsUrl,
    String? thumbnailUrl,
    int order = 0,
  }) {
    return VideoModel(
      id: url.hashCode.toString(),
      url: url,
      hlsUrl: hlsUrl,
      thumbnailUrl: thumbnailUrl,
      type: 'video',
      order: order,
    );
  }

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    try {
      final url = (map['url'] as String?)?.trim() ?? '';
      final hlsUrl = (map['hlsUrl'] as String?)?.trim();
      final thumbnailUrl = (map['thumbnailUrl'] as String?)?.trim();
      final durationSeconds = _safeParseInt(map['durationSeconds']);
      final order = _safeParseInt(map['order']);

      return VideoModel(
        id: url.hashCode.toString(),
        url: url,
        hlsUrl: hlsUrl?.isEmpty == true ? null : hlsUrl,
        thumbnailUrl: thumbnailUrl?.isEmpty == true ? null : thumbnailUrl,
        durationSeconds: durationSeconds,
        type: 'video',
        order: order,
      );
    } catch (e) {
      debugPrint('Error parsing VideoModel from map: $e');
      return VideoModel(
        id: (map['url'] as String? ?? '').hashCode.toString(),
        url: (map['url'] as String?) ?? '',
        type: 'video',
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

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'hlsUrl': hlsUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'type': type,
      'order': order,
    };
  }

  VideoModel copyWith({
    String? id,
    String? url,
    String? hlsUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    String? type,
    int? order,
  }) {
    return VideoModel(
      id: id ?? this.id,
      url: url ?? this.url,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      type: type ?? this.type,
      order: order ?? this.order,
    );
  }
}
