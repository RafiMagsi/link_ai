import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_ai/features/connect/data/datasources/connect_remote_datasource.dart';

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
    final statusState = ref.watch(relationshipStatusStreamProvider(targetUid));

    return statusState.when(
      data: (status) {
        switch (status) {
          case ConnectRelationshipStatus.connected:
            return FilledButton.tonalIcon(
              onPressed: () async {
                await ref
                    .read(connectControllerProvider.notifier)
                    .unfollowUser(targetUid);
              },
              icon: const Icon(Icons.check),
              label: const Text('Following'),
            );

          case ConnectRelationshipStatus.none:
            return FilledButton.icon(
              onPressed: () => ref
                  .read(connectControllerProvider.notifier)
                  .followUser(targetUid),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Follow'),
            );
        }
      },
      loading: () {
        return const FilledButton(onPressed: null, child: Text('Checking...'));
      },
      error: (error, stackTrace) {
        return FilledButton.icon(
          onPressed: () {
            ref.invalidate(relationshipStatusStreamProvider(targetUid));
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        );
      },
    );
  }
}
