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

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _isNavigating = false;
  List<AppNotificationModel>? _cachedNotifications;

  @override
  Widget build(BuildContext context) {
    // Don't watch provider while navigating - use cached data only
    if (!_isNavigating) {
      final notificationsState = ref.watch(myNotificationsProvider);
      final cachedNotifications = notificationsState.error == null
          ? notificationsState.value
          : null;
      if (cachedNotifications != null) {
        _cachedNotifications = cachedNotifications;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _isNavigating ? null : () {
              ref.read(notificationControllerProvider.notifier).markAllAsRead();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _cachedNotifications != null
          ? _NotificationsList(
              notifications: _cachedNotifications!,
              onNavigationStart: () => setState(() => _isNavigating = true),
              onNavigationEnd: () => setState(() => _isNavigating = false),
            )
          : !_isNavigating
              ? ref.watch(myNotificationsProvider).when(
                    data: (notifications) => _NotificationsList(
                      notifications: notifications,
                      onNavigationStart: () => setState(() => _isNavigating = true),
                      onNavigationEnd: () => setState(() => _isNavigating = false),
                    ),
                    loading: () => const Center(child: AppLoader()),
                    error: (error, stackTrace) =>
                        const Center(child: Text('Unable to load notifications.')),
                  )
              : const SizedBox.shrink(), // Don't rebuild while navigating
    );
  }
}

class _NotificationsList extends ConsumerStatefulWidget {
  const _NotificationsList({
    required this.notifications,
    required this.onNavigationStart,
    required this.onNavigationEnd,
  });

  final List<AppNotificationModel> notifications;
  final VoidCallback onNavigationStart;
  final VoidCallback onNavigationEnd;

  @override
  ConsumerState<_NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends ConsumerState<_NotificationsList> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const AppEmptyState(
        title: 'No notifications yet',
        subtitle: 'Likes, comments, reposts, follows, and messages show up here.',
        icon: Icons.notifications_none,
      );
    }

    return ListView.separated(
      itemCount: widget.notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = widget.notifications[index];
        final currentUid = ref.watch(currentUserProvider)?.uid;
        final onAvatarTap = notification.senderUid.isEmpty || _isNavigating
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
          enabled: !_isNavigating,
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
          onTap: _isNavigating
              ? null
              : () {
                  if (_isNavigating) return;

                  try {
                    final postId = notification.postId;
                    if (postId != null && postId.isNotEmpty) {
                      debugPrint('📲 Tapping notification: navigating to post $postId');
                      setState(() => _isNavigating = true);
                      widget.onNavigationStart();

                      if (context.mounted) {
                        context.push('/posts/$postId').then((_) {
                          if (mounted) {
                            setState(() => _isNavigating = false);
                            widget.onNavigationEnd();
                          }
                        });
                      }
                      return;
                    }

                    final productId = notification.productId;
                    if (productId != null && productId.isNotEmpty) {
                      debugPrint('📲 Tapping notification: navigating to product $productId');
                      setState(() => _isNavigating = true);
                      widget.onNavigationStart();

                      if (context.mounted) {
                        context.push('/products/$productId').then((_) {
                          if (mounted) {
                            setState(() => _isNavigating = false);
                            widget.onNavigationEnd();
                          }
                        });
                      }
                      return;
                    }

                    if (notification.senderUid.isNotEmpty) {
                      final isSelfProfile = currentUid != null &&
                          notification.senderUid == currentUid;
                      debugPrint('📲 Tapping notification: navigating to profile ${notification.senderUid}');
                      setState(() => _isNavigating = true);
                      widget.onNavigationStart();

                      navigateToProfile(
                        context: context,
                        uid: notification.senderUid,
                        isSelfProfile: isSelfProfile,
                      ).then((_) {
                        if (mounted) {
                          setState(() => _isNavigating = false);
                          widget.onNavigationEnd();
                        }
                      });
                    }
                  } catch (e, stackTrace) {
                    debugPrint('Notification tap error: $e');
                    debugPrintStack(stackTrace: stackTrace);
                    if (mounted) {
                      setState(() => _isNavigating = false);
                      widget.onNavigationEnd();
                    }
                  }
                },
        );
      },
    );
  }
}
