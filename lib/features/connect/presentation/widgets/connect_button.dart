import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_ai/features/connect/data/datasources/connect_remote_datasource.dart';
import 'package:go_router/go_router.dart';

import '../providers/connect_providers.dart';

class ConnectButton extends ConsumerWidget {
  const ConnectButton({
    super.key,
    required this.targetUid,
    required this.targetName,
  });

  final String targetUid;
  final String targetName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(relationshipStatusProvider(targetUid));

    return statusState.when(
      data: (status) {
        switch (status) {
          case ConnectRelationshipStatus.connected:
            return FilledButton.tonal(
              onPressed: () async {
                await ref.read(connectControllerProvider.notifier).pingUser(targetUid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ping sent!')),
                  );
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.notifications_active_outlined),
                  SizedBox(width: 8),
                  Text('Ping'),
                ],
              ),
            );

          case ConnectRelationshipStatus.outgoingPending:
            return FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.schedule),
              label: const Text('Request Sent'),
            );

          case ConnectRelationshipStatus.incomingPending:
            return FilledButton.icon(
              onPressed: () {
                // User should respond from Requests page.
              },
              icon: const Icon(Icons.mark_email_unread_outlined),
              label: const Text('Respond in Requests'),
            );

          case ConnectRelationshipStatus.none:
            return FilledButton.icon(
              onPressed: () {
                context.push(
                  '/connect/request/$targetUid',
                  extra: {'receiverName': targetName},
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Connect'),
            );
        }
      },
      loading: () {
        return const FilledButton(onPressed: null, child: Text('Checking...'));
      },
      error: (error, stackTrace) {
        return FilledButton.icon(
          onPressed: () {
            ref.invalidate(relationshipStatusProvider(targetUid));
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        );
      },
    );
  }
}
