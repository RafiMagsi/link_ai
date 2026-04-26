import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_ai/features/connect/data/datasources/connect_remote_datasource.dart';

import '../pages/send_connect_request_page.dart';
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
            return FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Connected'),
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SendConnectRequestPage(
                      receiverUid: targetUid,
                      receiverName: targetName,
                    ),
                  ),
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
