import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigModel {
  final int postTextMaxLength;
  final int maxMediaPerPost;
  final int maxImageSizeMb;
  final int maxVideoSizeMb;
  final int maxVideoDurationSeconds;
  final int connectRequestsPerWeek;

  final bool enableReposts;
  final bool enableComments;
  final bool enableProducts;
  final bool enableViralFeed;

  final int postRateLimitPerHour;
  final int connectCooldownMinutes;

  final String? updatedBy;
  final DateTime? updatedAt;

  const AppConfigModel({
    required this.postTextMaxLength,
    required this.maxMediaPerPost,
    required this.maxImageSizeMb,
    required this.maxVideoSizeMb,
    required this.maxVideoDurationSeconds,
    required this.connectRequestsPerWeek,
    required this.enableReposts,
    required this.enableComments,
    required this.enableProducts,
    required this.enableViralFeed,
    required this.postRateLimitPerHour,
    required this.connectCooldownMinutes,
    required this.updatedBy,
    required this.updatedAt,
  });

  factory AppConfigModel.defaults() {
    return const AppConfigModel(
      postTextMaxLength: 280,
      maxMediaPerPost: 4,
      maxImageSizeMb: 5,
      maxVideoSizeMb: 200,
      maxVideoDurationSeconds: 30,
      connectRequestsPerWeek: 50,
      enableReposts: true,
      enableComments: true,
      enableProducts: true,
      enableViralFeed: true,
      postRateLimitPerHour: 10,
      connectCooldownMinutes: 5,
      updatedBy: null,
      updatedAt: null,
    );
  }

  factory AppConfigModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      return AppConfigModel.defaults();
    }

    return AppConfigModel(
      postTextMaxLength: data['postTextMaxLength'] as int? ?? 280,
      maxMediaPerPost: data['maxMediaPerPost'] as int? ?? 4,
      maxImageSizeMb: data['maxImageSizeMb'] as int? ?? 5,
      maxVideoSizeMb: data['maxVideoSizeMb'] as int? ?? 200,
      maxVideoDurationSeconds:
          data['maxVideoDurationSeconds'] as int? ?? 30,
      connectRequestsPerWeek:
          data['connectRequestsPerWeek'] as int? ?? 50,
      enableReposts: data['enableReposts'] as bool? ?? true,
      enableComments: data['enableComments'] as bool? ?? true,
      enableProducts: data['enableProducts'] as bool? ?? true,
      enableViralFeed: data['enableViralFeed'] as bool? ?? true,
      postRateLimitPerHour:
          data['postRateLimitPerHour'] as int? ?? 10,
      connectCooldownMinutes:
          data['connectCooldownMinutes'] as int? ?? 5,
      updatedBy: data['updatedBy'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toUpdateMap({
    required String updatedBy,
  }) {
    return {
      'postTextMaxLength': postTextMaxLength,
      'maxMediaPerPost': maxMediaPerPost,
      'maxImageSizeMb': maxImageSizeMb,
      'maxVideoSizeMb': maxVideoSizeMb,
      'maxVideoDurationSeconds': maxVideoDurationSeconds,
      'connectRequestsPerWeek': connectRequestsPerWeek,
      'enableReposts': enableReposts,
      'enableComments': enableComments,
      'enableProducts': enableProducts,
      'enableViralFeed': enableViralFeed,
      'postRateLimitPerHour': postRateLimitPerHour,
      'connectCooldownMinutes': connectCooldownMinutes,
      'updatedBy': updatedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppConfigModel copyWith({
    int? postTextMaxLength,
    int? maxMediaPerPost,
    int? maxImageSizeMb,
    int? maxVideoSizeMb,
    int? maxVideoDurationSeconds,
    int? connectRequestsPerWeek,
    bool? enableReposts,
    bool? enableComments,
    bool? enableProducts,
    bool? enableViralFeed,
    int? postRateLimitPerHour,
    int? connectCooldownMinutes,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return AppConfigModel(
      postTextMaxLength:
          postTextMaxLength ?? this.postTextMaxLength,
      maxMediaPerPost: maxMediaPerPost ?? this.maxMediaPerPost,
      maxImageSizeMb: maxImageSizeMb ?? this.maxImageSizeMb,
      maxVideoSizeMb: maxVideoSizeMb ?? this.maxVideoSizeMb,
      maxVideoDurationSeconds:
          maxVideoDurationSeconds ?? this.maxVideoDurationSeconds,
      connectRequestsPerWeek:
          connectRequestsPerWeek ?? this.connectRequestsPerWeek,
      enableReposts: enableReposts ?? this.enableReposts,
      enableComments: enableComments ?? this.enableComments,
      enableProducts: enableProducts ?? this.enableProducts,
      enableViralFeed: enableViralFeed ?? this.enableViralFeed,
      postRateLimitPerHour:
          postRateLimitPerHour ?? this.postRateLimitPerHour,
      connectCooldownMinutes:
          connectCooldownMinutes ?? this.connectCooldownMinutes,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}