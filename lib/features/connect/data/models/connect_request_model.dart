import 'package:cloud_firestore/cloud_firestore.dart';

enum ConnectRequestStatus {
  pending,
  accepted,
  declined,
}

class ConnectRequestModel {
  final String id;
  final String senderUid;
  final String receiverUid;
  final String senderName;
  final String senderRole;
  final String? senderAvatarUrl;
  final String receiverName;
  final String receiverRole;
  final String? receiverAvatarUrl;
  final String message;
  final ConnectRequestStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ConnectRequestModel({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.senderName,
    required this.senderRole,
    required this.senderAvatarUrl,
    required this.receiverName,
    required this.receiverRole,
    required this.receiverAvatarUrl,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConnectRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return ConnectRequestModel(
      id: data['id'] as String? ?? doc.id,
      senderUid: data['senderUid'] as String? ?? '',
      receiverUid: data['receiverUid'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? '',
      senderAvatarUrl: data['senderAvatarUrl'] as String?,
      receiverName: data['receiverName'] as String? ?? '',
      receiverRole: data['receiverRole'] as String? ?? '',
      receiverAvatarUrl: data['receiverAvatarUrl'] as String?,
      message: data['message'] as String? ?? '',
      status: _parseStatus(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static ConnectRequestStatus _parseStatus(String? value) {
    switch (value) {
      case 'accepted':
        return ConnectRequestStatus.accepted;
      case 'declined':
        return ConnectRequestStatus.declined;
      case 'pending':
      default:
        return ConnectRequestStatus.pending;
    }
  }

  String get statusText {
    switch (status) {
      case ConnectRequestStatus.pending:
        return 'Pending';
      case ConnectRequestStatus.accepted:
        return 'Accepted';
      case ConnectRequestStatus.declined:
        return 'Declined';
    }
  }
}