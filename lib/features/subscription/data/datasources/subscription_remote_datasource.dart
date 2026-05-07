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
          debugPrint(
            'Error watching subscription for $uid: $error\n$stackTrace',
          );
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
}
