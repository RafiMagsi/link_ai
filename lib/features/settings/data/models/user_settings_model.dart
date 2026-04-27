import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettingsModel {
  final String uid;

  /// One of: system | light | dark
  final String themeMode;

  final bool notifyLikes;
  final bool notifyReposts;
  final bool notifyComments;
  final bool notifySaves;
  final bool notifyConnectRequests;
  final bool notifyProductActivity;

  final bool videoAutoplay;
  final bool muteVideosByDefault;

  final bool onboardingShown;
  final DateTime? lastOnboardingDismissAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserSettingsModel({
    required this.uid,
    required this.themeMode,
    required this.notifyLikes,
    required this.notifyReposts,
    required this.notifyComments,
    required this.notifySaves,
    required this.notifyConnectRequests,
    required this.notifyProductActivity,
    required this.videoAutoplay,
    required this.muteVideosByDefault,
    required this.onboardingShown,
    required this.lastOnboardingDismissAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettingsModel.defaults(String uid) {
    return UserSettingsModel(
      uid: uid,
      themeMode: 'system',
      notifyLikes: true,
      notifyReposts: true,
      notifyComments: true,
      notifySaves: true,
      notifyConnectRequests: true,
      notifyProductActivity: true,
      videoAutoplay: true,
      muteVideosByDefault: true,
      onboardingShown: false,
      lastOnboardingDismissAt: null,
      createdAt: null,
      updatedAt: null,
    );
  }

  factory UserSettingsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return UserSettingsModel(
      uid: data['uid'] as String? ?? doc.id,
      themeMode: data['themeMode'] as String? ?? 'system',
      notifyLikes: data['notifyLikes'] as bool? ?? true,
      notifyReposts: data['notifyReposts'] as bool? ?? true,
      notifyComments: data['notifyComments'] as bool? ?? true,
      notifySaves: data['notifySaves'] as bool? ?? true,
      notifyConnectRequests: data['notifyConnectRequests'] as bool? ?? true,
      notifyProductActivity: data['notifyProductActivity'] as bool? ?? true,
      videoAutoplay: data['videoAutoplay'] as bool? ?? true,
      muteVideosByDefault: data['muteVideosByDefault'] as bool? ?? true,
      onboardingShown: data['onboardingShown'] as bool? ?? false,
      lastOnboardingDismissAt:
          (data['lastOnboardingDismissAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'themeMode': themeMode,
      'notifyLikes': notifyLikes,
      'notifyReposts': notifyReposts,
      'notifyComments': notifyComments,
      'notifySaves': notifySaves,
      'notifyConnectRequests': notifyConnectRequests,
      'notifyProductActivity': notifyProductActivity,
      'videoAutoplay': videoAutoplay,
      'muteVideosByDefault': muteVideosByDefault,
      'onboardingShown': onboardingShown,
      'lastOnboardingDismissAt': lastOnboardingDismissAt,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'themeMode': themeMode,
      'notifyLikes': notifyLikes,
      'notifyReposts': notifyReposts,
      'notifyComments': notifyComments,
      'notifySaves': notifySaves,
      'notifyConnectRequests': notifyConnectRequests,
      'notifyProductActivity': notifyProductActivity,
      'videoAutoplay': videoAutoplay,
      'muteVideosByDefault': muteVideosByDefault,
      'onboardingShown': onboardingShown,
      'lastOnboardingDismissAt': lastOnboardingDismissAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserSettingsModel copyWith({
    String? themeMode,
    bool? notifyLikes,
    bool? notifyReposts,
    bool? notifyComments,
    bool? notifySaves,
    bool? notifyConnectRequests,
    bool? notifyProductActivity,
    bool? videoAutoplay,
    bool? muteVideosByDefault,
    bool? onboardingShown,
    DateTime? lastOnboardingDismissAt,
  }) {
    return UserSettingsModel(
      uid: uid,
      themeMode: themeMode ?? this.themeMode,
      notifyLikes: notifyLikes ?? this.notifyLikes,
      notifyReposts: notifyReposts ?? this.notifyReposts,
      notifyComments: notifyComments ?? this.notifyComments,
      notifySaves: notifySaves ?? this.notifySaves,
      notifyConnectRequests:
          notifyConnectRequests ?? this.notifyConnectRequests,
      notifyProductActivity:
          notifyProductActivity ?? this.notifyProductActivity,
      videoAutoplay: videoAutoplay ?? this.videoAutoplay,
      muteVideosByDefault: muteVideosByDefault ?? this.muteVideosByDefault,
      onboardingShown: onboardingShown ?? this.onboardingShown,
      lastOnboardingDismissAt:
          lastOnboardingDismissAt ?? this.lastOnboardingDismissAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
