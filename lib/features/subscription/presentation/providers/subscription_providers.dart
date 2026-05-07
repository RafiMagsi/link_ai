import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/subscription_remote_datasource.dart';
import '../../data/models/subscription_model.dart';

final subscriptionRemoteDataSourceProvider =
    Provider<SubscriptionRemoteDataSource>((ref) {
      return SubscriptionRemoteDataSource(FirebaseFirestore.instance);
    });

final userSubscriptionProvider = StreamProvider<SubscriptionModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(null);
  }

  return ref
      .watch(subscriptionRemoteDataSourceProvider)
      .watchUserSubscription(user.uid);
});

final userSubscriptionByUidProvider =
    StreamProvider.family<SubscriptionModel?, String>((ref, uid) {
      return ref
          .watch(subscriptionRemoteDataSourceProvider)
          .watchUserSubscription(uid);
    });

final isGoldSubscriberProvider = Provider<bool>((ref) {
  final subscription = ref.watch(userSubscriptionProvider).asData?.value;
  return subscription?.isActive ?? false;
});

final isGoldSubscriberByUidProvider = Provider.family<bool, String>((ref, uid) {
  final subscription = ref
      .watch(userSubscriptionByUidProvider(uid))
      .asData
      ?.value;
  return subscription?.isActive ?? false;
});
