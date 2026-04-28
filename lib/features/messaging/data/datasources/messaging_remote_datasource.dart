import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessagingRemoteDataSource {
  MessagingRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversations {
    return _firestore.collection('conversations');
  }

  Stream<List<ConversationModel>> watchInbox(String uid) {
    return _conversations
        .where('participantUids', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map(ConversationModel.fromFirestore)
                .toList();
          } catch (error, stackTrace) {
            debugPrint(
              'Error parsing inbox for $uid: $error\n$stackTrace',
            );
            return [];
          }
        });
  }

  Stream<int> watchUnreadCount(String uid) {
    return _conversations
        .where('participantUids', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          try {
            int total = 0;
            for (final doc in snapshot.docs) {
              final conv = ConversationModel.fromFirestore(doc);
              total += conv.unreadCountFor(uid);
            }
            return total;
          } catch (error, stackTrace) {
            debugPrint(
              'Error calculating unread count for $uid: $error\n$stackTrace',
            );
            return 0;
          }
        });
  }

  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAtClient', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map(MessageModel.fromFirestore)
                .toList();
          } catch (error, stackTrace) {
            debugPrint(
              'Error parsing messages for $conversationId: $error\n$stackTrace',
            );
            return [];
          }
        });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderUid,
    required String text,
    required String otherUid,
    required String otherName,
    required String? otherAvatarUrl,
    required String myName,
    required String? myAvatarUrl,
  }) async {
    final batch = _firestore.batch();

    final conversationRef = _conversations.doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();

    batch.set(
      conversationRef,
      {
        'id': conversationId,
        'participantUids': [senderUid, otherUid],
        'participantNames': {
          senderUid: myName,
          otherUid: otherName,
        },
        'participantAvatarUrls': {
          senderUid: myAvatarUrl,
          otherUid: otherAvatarUrl,
        },
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderUid': senderUid,
        'unreadCounts': {
          senderUid: 0,
          otherUid: FieldValue.increment(1),
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      messageRef,
      MessageModel(
        id: messageRef.id,
        senderUid: senderUid,
        text: text,
        createdAt: null,
        createdAtClient: null,
        isRead: false,
      ).toCreateMap(senderUid: senderUid, text: text),
    );

    await batch.commit();
  }

  Future<void> markRead({
    required String conversationId,
    required String uid,
  }) async {
    await _conversations.doc(conversationId).update({
      'unreadCounts.$uid': 0,
    });
  }
}
