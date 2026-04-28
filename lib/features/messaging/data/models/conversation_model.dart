import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participantUids;
  final Map<String, dynamic> participantNames;
  final Map<String, dynamic> participantAvatarUrls;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastMessageSenderUid;
  final Map<String, dynamic> unreadCounts;
  final DateTime? createdAt;

  const ConversationModel({
    required this.id,
    required this.participantUids,
    required this.participantNames,
    required this.participantAvatarUrls,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageSenderUid,
    required this.unreadCounts,
    required this.createdAt,
  });

  factory ConversationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      return ConversationModel(
        id: doc.id,
        participantUids: [],
        participantNames: {},
        participantAvatarUrls: {},
        lastMessage: '',
        lastMessageAt: null,
        lastMessageSenderUid: '',
        unreadCounts: {},
        createdAt: null,
      );
    }

    return ConversationModel(
      id: doc.id,
      participantUids: List<String>.from(data['participantUids'] as List? ?? []),
      participantNames: Map<String, dynamic>.from(
        (data['participantNames'] as Map?) ?? {},
      ),
      participantAvatarUrls: Map<String, dynamic>.from(
        (data['participantAvatarUrls'] as Map?) ?? {},
      ),
      lastMessage: (data['lastMessage'] as String?) ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderUid: (data['lastMessageSenderUid'] as String?) ?? '',
      unreadCounts: Map<String, dynamic>.from(
        (data['unreadCounts'] as Map?) ?? {},
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  int unreadCountFor(String uid) {
    return (unreadCounts[uid] as int?) ?? 0;
  }

  String getOtherUid(String currentUid) {
    return participantUids.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => '',
    );
  }

  String getOtherName(String currentUid) {
    final otherUid = getOtherUid(currentUid);
    return (participantNames[otherUid] as String?) ?? 'Unknown';
  }

  String? getOtherAvatarUrl(String currentUid) {
    final otherUid = getOtherUid(currentUid);
    return (participantAvatarUrls[otherUid] as String?);
  }

  static String buildId(String uid1, String uid2) {
    final uids = [uid1, uid2];
    uids.sort();
    return uids.join('_');
  }
}
