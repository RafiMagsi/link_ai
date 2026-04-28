import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/connect_providers.dart';

class ConnectRequestsPage extends ConsumerWidget {
  const ConnectRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingState = ref.watch(incomingConnectRequestsProvider);
    final outgoingState = ref.watch(outgoingConnectRequestsProvider);
    final currentUid = ref.watch(currentUserProvider)?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Connect Requests')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          const Text(
            'Incoming',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          incomingState.when(
            data: (requests) {
              if (requests.isEmpty) {
                return const _EmptyText('No incoming requests.');
              }

              return Column(
                children: requests.map((request) {
                  final onAvatarTap = request.senderUid.isEmpty
                      ? null
                      : () async {
                          final isSelfProfile = currentUid != null &&
                              request.senderUid == currentUid;
                          await navigateToProfile(
                            context: context,
                            uid: request.senderUid,
                            isSelfProfile: isSelfProfile,
                          );
                        };
                  return Card(
                    child: ListTile(
                      leading: AppUserAvatar(
                        avatarUrl: request.senderAvatarUrl,
                        onTap: onAvatarTap,
                      ),
                      title: Text(
                        request.senderName.isEmpty
                            ? 'Unknown Builder'
                            : request.senderName,
                      ),
                      subtitle: Text(
                        [
                          if (request.senderRole.isNotEmpty) request.senderRole,
                          if (request.message.isNotEmpty) request.message,
                        ].join('\n'),
                      ),
                      isThreeLine: request.message.isNotEmpty,
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          IconButton.filledTonal(
                            onPressed: () {
                              ref
                                  .read(connectControllerProvider.notifier)
                                  .declineRequest(
                                    requestId: request.id,
                                    senderUid: request.senderUid,
                                  );
                            },
                            icon: const Icon(Icons.close),
                          ),
                          IconButton.filled(
                            onPressed: () {
                              ref
                                  .read(connectControllerProvider.notifier)
                                  .acceptRequest(
                                    requestId: request.id,
                                    senderUid: request.senderUid,
                                  );
                            },
                            icon: const Icon(Icons.check),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: AppLoader()),
            error: (error, stackTrace) =>
                const Text('Unable to load incoming requests.'),
          ),
          const SizedBox(height: 28),
          const Text(
            'Outgoing',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          outgoingState.when(
            data: (requests) {
              if (requests.isEmpty) {
                return const _EmptyText('No outgoing requests.');
              }

              return Column(
                children: requests.map((request) {
                  final onAvatarTap = request.receiverUid.isEmpty
                      ? null
                      : () async {
                          final isSelfProfile = currentUid != null &&
                              request.receiverUid == currentUid;
                          await navigateToProfile(
                            context: context,
                            uid: request.receiverUid,
                            isSelfProfile: isSelfProfile,
                          );
                        };
                  return Card(
                    child: ListTile(
                      leading: AppUserAvatar(
                        avatarUrl: request.receiverAvatarUrl,
                        onTap: onAvatarTap,
                      ),
                      title: Text(
                        request.receiverName.isEmpty
                            ? 'Unknown Builder'
                            : request.receiverName,
                      ),
                      subtitle: Text(
                        '${request.receiverRole}\nStatus: ${request.statusText}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: AppLoader()),
            error: (error, stackTrace) =>
                const Text('Unable to load outgoing requests.'),
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: TextStyle(color: colors.mutedText)),
    );
  }
}
