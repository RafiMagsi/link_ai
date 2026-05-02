import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/subscription_model.dart';

class SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection('users');
  }

  Stream<SubscriptionModel?> watchUserSubscription(String uid) {
    return _users
        .doc(uid)
        .collection('subscription')
        .doc('data')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }
          return SubscriptionModel.fromFirestore(snapshot);
        })
        .handleError((error, stackTrace) {
          debugPrint('Error watching subscription for $uid: $error\n$stackTrace');
          return null;
        });
  }

  Future<SubscriptionModel?> getSubscriptionStatus(String uid) async {
    try {
      final doc = await _users
          .doc(uid)
          .collection('subscription')
          .doc('data')
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        return null;
      }

      return SubscriptionModel.fromFirestore(doc);
    } catch (error, stackTrace) {
      debugPrint('Error getting subscription for $uid: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> createSubscription({
    required String uid,
    required String purchaseId,
    required DateTime expiresAt,
  }) async {
    try {
      final subscription = SubscriptionModel(
        uid: uid,
        isGoldSubscriber: true,
        purchaseId: purchaseId,
        subscribedAt: DateTime.now(),
        expiresAt: expiresAt,
        subscriptionStatus: 'active',
      );

      await _users
          .doc(uid)
          .collection('subscription')
          .doc('data')
          .set(subscription.toCreateMap())
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('Error creating subscription for $uid: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<void> updateSubscriptionStatus({
    required String uid,
    required String status,
    DateTime? expiresAt,
  }) async {
    try {
      final updateData = {
        'subscriptionStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (expiresAt != null) {
        updateData['expiresAt'] = Timestamp.fromDate(expiresAt);
      }

      if (status == 'canceled') {
        updateData['canceledAt'] = FieldValue.serverTimestamp();
        updateData['isGoldSubscriber'] = false;
      }

      await _users
          .doc(uid)
          .collection('subscription')
          .doc('data')
          .update(updateData)
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('Error updating subscription for $uid: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<void> cancelSubscription(String uid) async {
    try {
      await _users
          .doc(uid)
          .collection('subscription')
          .doc('data')
          .update({
            'subscriptionStatus': 'canceled',
            'isGoldSubscriber': false,
            'canceledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('Error canceling subscription for $uid: $error\n$stackTrace');
      rethrow;
    }
  }
}
