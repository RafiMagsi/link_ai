import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/app_notification_model.dart';

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseMessagingProvider),
  );
});

final myNotificationsProvider =
    StreamProvider<List<AppNotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const Stream.empty();
  }

  return ref
      .watch(notificationRemoteDataSourceProvider)
      .watchMyNotifications(user.uid);
});

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const Stream.empty();
  }

  return ref
      .watch(notificationRemoteDataSourceProvider)
      .watchUnreadCount(user.uid);
});

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
  return NotificationController(
    ref,
    ref.watch(notificationRemoteDataSourceProvider),
  );
});

class NotificationController extends StateNotifier<AsyncValue<void>> {
  NotificationController(
    this._ref,
    this._notificationRemoteDataSource,
  ) : super(const AsyncData(null));

  final Ref _ref;
  final NotificationRemoteDataSource _notificationRemoteDataSource;

  Future<void> initializeForCurrentUser() async {
    final user = _ref.read(currentUserProvider);

    if (user == null) return;

    state = const AsyncLoading();

    try {
      await _notificationRemoteDataSource.requestPermission();

      final token = await _notificationRemoteDataSource.getToken();

      if (token != null) {
        await _notificationRemoteDataSource.saveToken(
          uid: user.uid,
          token: token,
        );
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _notificationRemoteDataSource.saveToken(
          uid: user.uid,
          token: newToken,
        );
      });

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationRemoteDataSource.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    final user = _ref.read(currentUserProvider);

    if (user == null) return;

    await _notificationRemoteDataSource.markAllAsRead(user.uid);
  }
}