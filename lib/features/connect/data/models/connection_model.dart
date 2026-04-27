import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionModel {
  final String id;
  final String userUid;
  final String connectedUid;
  final DateTime? createdAt;

  const ConnectionModel({
    required this.id,
    required this.userUid,
    required this.connectedUid,
    required this.createdAt,
  });

  factory ConnectionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return ConnectionModel(
      id: data['id'] as String? ?? doc.id,
      userUid: data['userUid'] as String? ?? '',
      connectedUid: data['connectedUid'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
