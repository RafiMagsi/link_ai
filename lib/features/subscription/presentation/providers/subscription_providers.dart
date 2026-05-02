import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/subscription_remote_datasource.dart';
import '../../data/models/subscription_model.dart';

final subscriptionRemoteDataSourceProvider = Provider<SubscriptionRemoteDataSource>((ref) {
  return SubscriptionRemoteDataSource(FirebaseFirestore.instance);
});

final userSubscriptionProvider = StreamProvider<SubscriptionModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(null);
  }

  return ref.watch(subscriptionRemoteDataSourceProvider).watchUserSubscription(user.uid);
});

final userSubscriptionByUidProvider =
    StreamProvider.family<SubscriptionModel?, String>((ref, uid) {
  return ref.watch(subscriptionRemoteDataSourceProvider).watchUserSubscription(uid);
});

final isGoldSubscriberProvider = Provider<bool>((ref) {
  final subscription = ref.watch(userSubscriptionProvider).asData?.value;
  return subscription?.isActive ?? false;
});

final isGoldSubscriberByUidProvider = Provider.family<bool, String>((ref, uid) {
  final subscription = ref.watch(userSubscriptionByUidProvider(uid)).asData?.value;
  return subscription?.isActive ?? false;
});

class SubscriptionController {
  SubscriptionController(this._dataSource);

  final SubscriptionRemoteDataSource _dataSource;

  Future<void> updateSubscriptionFromWebhook({
    required String uid,
    required String purchaseId,
    required DateTime expiresAt,
    String status = 'active',
  }) async {
    await _dataSource.createSubscription(
      uid: uid,
      purchaseId: purchaseId,
      expiresAt: expiresAt,
    );
  }

  Future<void> cancelSubscription(String uid) async {
    await _dataSource.cancelSubscription(uid);
  }

  Future<void> restorePurchase(String uid) async {
    final subscription = await _dataSource.getSubscriptionStatus(uid);
    if (subscription == null || !subscription.isActive) {
      throw Exception('No active subscription found');
    }
  }
}

final subscriptionControllerProvider = Provider<SubscriptionController>((ref) {
  return SubscriptionController(
    ref.watch(subscriptionRemoteDataSourceProvider),
  );
});
