import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFF1E293B)),
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return ListTile(
                tileColor: notification.isRead
                    ? null
                    : const Color(0xFF1D4ED8).withValues(alpha: 0.10),
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
                    : const Icon(
                        Icons.circle,
                        size: 10,
                        color: Color(0xFF2563EB),
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
