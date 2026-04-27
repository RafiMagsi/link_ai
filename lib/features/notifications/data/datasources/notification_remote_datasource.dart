import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/app_notification_model.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._firestore, this._messaging);

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  CollectionReference<Map<String, dynamic>> get _notifications {
    return _firestore.collection('notifications');
  }

  Future<NotificationSettings> requestPermission() {
    try {
      return _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      ).timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      print('Error requesting notification permission: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken().timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      print('Error getting FCM token: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> saveToken({required String uid, required String token}) async {
    try {
      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
          ? 'android'
          : 'unknown';

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'platform': platform,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      print('Error saving FCM token for user $uid: $error\n$stackTrace');
      rethrow;
    }
  }

  Stream<List<AppNotificationModel>> watchMyNotifications(String uid) {
    return _notifications
        .where('receiverUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) => sink.close(),
        )
        .map((snapshot) {
          try {
            return snapshot.docs.map(AppNotificationModel.fromFirestore).toList();
          } catch (error, stackTrace) {
            print('Error parsing notifications for user $uid: $error\n$stackTrace');
            return [];
          }
        });
  }

  Stream<int> watchUnreadCount(String uid) {
    return _notifications
        .where('receiverUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) => sink.close(),
        )
        .map((snapshot) {
          try {
            return snapshot.docs.length;
          } catch (error, stackTrace) {
            print('Error counting unread notifications for user $uid: $error\n$stackTrace');
            return 0;
          }
        });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({'isRead': true}).timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      print('Error marking notification $notificationId as read: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<void> markAllAsRead(String uid) async {
    try {
      final snapshot = await _notifications
          .where('receiverUid', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 10));

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit().timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      print('Error marking all notifications as read for user $uid: $error\n$stackTrace');
      rethrow;
    }
  }
}
