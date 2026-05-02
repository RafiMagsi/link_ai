import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String uid;
  final bool isGoldSubscriber;
  final String? purchaseId;
  final DateTime? subscribedAt;
  final DateTime? expiresAt;
  final DateTime? canceledAt;
  final String subscriptionStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionModel({
    required this.uid,
    required this.isGoldSubscriber,
    this.purchaseId,
    this.subscribedAt,
    this.expiresAt,
    this.canceledAt,
    required this.subscriptionStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return SubscriptionModel(
      uid: data['uid'] as String? ?? doc.id,
      isGoldSubscriber: data['isGoldSubscriber'] as bool? ?? false,
      purchaseId: data['purchaseId'] as String?,
      subscribedAt: (data['subscribedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      canceledAt: (data['canceledAt'] as Timestamp?)?.toDate(),
      subscriptionStatus: data['subscriptionStatus'] as String? ?? 'inactive',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'isGoldSubscriber': isGoldSubscriber,
      'purchaseId': purchaseId,
      'subscribedAt': subscribedAt != null ? Timestamp.fromDate(subscribedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'canceledAt': canceledAt != null ? Timestamp.fromDate(canceledAt!) : null,
      'subscriptionStatus': subscriptionStatus,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'isGoldSubscriber': isGoldSubscriber,
      'purchaseId': purchaseId,
      'subscribedAt': subscribedAt != null ? Timestamp.fromDate(subscribedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'canceledAt': canceledAt != null ? Timestamp.fromDate(canceledAt!) : null,
      'subscriptionStatus': subscriptionStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isActive => subscriptionStatus == 'active' && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  SubscriptionModel copyWith({
    String? uid,
    bool? isGoldSubscriber,
    String? purchaseId,
    DateTime? subscribedAt,
    DateTime? expiresAt,
    DateTime? canceledAt,
    String? subscriptionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      uid: uid ?? this.uid,
      isGoldSubscriber: isGoldSubscriber ?? this.isGoldSubscriber,
      purchaseId: purchaseId ?? this.purchaseId,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      canceledAt: canceledAt ?? this.canceledAt,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
