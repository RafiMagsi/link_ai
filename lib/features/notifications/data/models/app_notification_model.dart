import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String receiverUid;
  final String senderUid;
  final String senderName;
  final String? senderAvatarUrl;
  final String type;
  final String title;
  final String body;
  final String? postId;
  final String? productId;
  final String? connectRequestId;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotificationModel({
    required this.id,
    required this.receiverUid,
    required this.senderUid,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.type,
    required this.title,
    required this.body,
    required this.postId,
    required this.productId,
    required this.connectRequestId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return AppNotificationModel(
      id: data['id'] as String? ?? doc.id,
      receiverUid: data['receiverUid'] as String? ?? '',
      senderUid: data['senderUid'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderAvatarUrl: data['senderAvatarUrl'] as String?,
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      postId: data['postId'] as String?,
      productId: data['productId'] as String?,
      connectRequestId: data['connectRequestId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}