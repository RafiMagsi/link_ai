import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderUid;
  final String text;
  final DateTime? createdAt;
  final DateTime? createdAtClient;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.createdAt,
    required this.createdAtClient,
    required this.isRead,
  });

  factory MessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      return MessageModel(
        id: doc.id,
        senderUid: '',
        text: '',
        createdAt: null,
        createdAtClient: null,
        isRead: false,
      );
    }

    return MessageModel(
      id: doc.id,
      senderUid: (data['senderUid'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdAtClient: (data['createdAtClient'] as Timestamp?)?.toDate(),
      isRead: (data['isRead'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toCreateMap({
    required String senderUid,
    required String text,
  }) {
    return {
      'senderUid': senderUid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': Timestamp.now(),
      'isRead': false,
    };
  }
}
