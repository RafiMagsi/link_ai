import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../providers/notification_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(myNotificationsProvider);

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
      body: notificationsState.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const AppEmptyState(
              title: 'No notifications yet',
              subtitle: 'Likes, comments, reposts, and connects show up here.',
              icon: Icons.notifications_none,
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return ListTile(
                tileColor: notification.isRead
                    ? null
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
                leading: CircleAvatar(
                  backgroundImage: notification.senderAvatarUrl != null
                      ? NetworkImage(notification.senderAvatarUrl!)
                      : null,
                  child: notification.senderAvatarUrl == null
                      ? Text(
                          notification.senderName.isNotEmpty
                              ? notification.senderName[0].toUpperCase()
                              : '?',
                        )
                      : null,
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

                  // Later: navigate based on type/postId/productId.
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Unable to load notifications.')),
      ),
    );
  }
}
