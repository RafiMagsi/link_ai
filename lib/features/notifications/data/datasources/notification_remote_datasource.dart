import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
      debugPrint('Error requesting notification permission: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        final apnsToken = await _waitForApnsToken();

        if (apnsToken == null) {
          debugPrint('APNS token is not ready yet. FCM token will be retried later.');
          return null;
        }
      }

      return await _messaging.getToken().timeout(
            const Duration(seconds: 10),
          );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Error getting FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('Timeout getting FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } catch (error, stackTrace) {
      debugPrint('Unexpected error getting FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<String?> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        final apnsToken = await _messaging.getAPNSToken();

        if (apnsToken != null) {
          return apnsToken;
        }
      } on FirebaseException catch (error) {
        debugPrint('APNS token attempt ${attempt + 1} failed: $error');
      }

      await Future<void>.delayed(const Duration(milliseconds: 700));
    }

    return null;
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
      debugPrint('Error saving FCM token for user $uid: $error\n$stackTrace');
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
            debugPrint('Error parsing notifications for user $uid: $error\n$stackTrace');
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
            debugPrint('Error counting unread notifications for user $uid: $error\n$stackTrace');
            return 0;
          }
        });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({'isRead': true}).timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('Error marking notification $notificationId as read: $error\n$stackTrace');
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
      debugPrint('Error marking all notifications as read for user $uid: $error\n$stackTrace');
      rethrow;
    }
  }
}
