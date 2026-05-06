import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/app_notification_model.dart';
import '../providers/notification_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(myNotificationsProvider);
    final cachedNotifications = notificationsState.error == null
        ? notificationsState.value
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationControllerProvider.notifier).markAllAsRead();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: cachedNotifications != null
          ? _NotificationsList(notifications: cachedNotifications)
          : notificationsState.when(
              data: (notifications) =>
                  _NotificationsList(notifications: notifications),
        loading: () => const Center(child: AppLoader()),
        error: (error, stackTrace) =>
            const Center(child: Text('Unable to load notifications.')),
      ),
    );
  }
}

class _NotificationsList extends ConsumerWidget {
  const _NotificationsList({required this.notifications});

  final List<AppNotificationModel> notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notifications.isEmpty) {
      return const AppEmptyState(
        title: 'No notifications yet',
        subtitle: 'Likes, comments, reposts, follows, and messages show up here.',
        icon: Icons.notifications_none,
      );
    }

    return ListView.separated(
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final currentUid = ref.watch(currentUserProvider)?.uid;
        final onAvatarTap = notification.senderUid.isEmpty
            ? null
            : () async {
                final isSelfProfile = currentUid != null &&
                    notification.senderUid == currentUid;
                await navigateToProfile(
                  context: context,
                  uid: notification.senderUid,
                  isSelfProfile: isSelfProfile,
                );
              };

        return ListTile(
          tileColor: notification.isRead
              ? null
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          leading: AppUserAvatar(
            avatarUrl: notification.senderAvatarUrl,
            onTap: onAvatarTap,
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead
                  ? FontWeight.w600
                  : FontWeight.w900,
            ),
          ),
          subtitle: Text(notification.body),
          trailing: notification.isRead
              ? null
              : Icon(
                  Icons.circle,
                  size: 10,
                  color: Theme.of(context).colorScheme.primary,
                ),
          onTap: () {
            ref
                .read(notificationControllerProvider.notifier)
                .markAsRead(notification.id);

            final postId = notification.postId;
            if (postId != null && postId.isNotEmpty) {
              context.push('/posts/$postId');
              return;
            }

            final productId = notification.productId;
            if (productId != null && productId.isNotEmpty) {
              context.push('/products/$productId');
              return;
            }

            if (notification.senderUid.isNotEmpty) {
              final isSelfProfile = currentUid != null &&
                  notification.senderUid == currentUid;
              navigateToProfile(
                context: context,
                uid: notification.senderUid,
                isSelfProfile: isSelfProfile,
              );
            }
          },
        );
      },
    );
  }
}
