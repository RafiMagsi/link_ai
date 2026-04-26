import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connect_providers.dart';

class ConnectRequestsPage extends ConsumerWidget {
  const ConnectRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingState = ref.watch(incomingConnectRequestsProvider);
    final outgoingState = ref.watch(outgoingConnectRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Requests'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: request.senderAvatarUrl != null
                            ? NetworkImage(request.senderAvatarUrl!)
                            : null,
                        child: request.senderAvatarUrl == null
                            ? Text(
                                request.senderName.isNotEmpty
                                    ? request.senderName[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(
                        request.senderName.isEmpty
                            ? 'Unknown Builder'
                            : request.senderName,
                      ),
                      subtitle: Text(
                        [
                          if (request.senderRole.isNotEmpty)
                            request.senderRole,
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Unable to load incoming requests.'),
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
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: request.receiverAvatarUrl != null
                            ? NetworkImage(request.receiverAvatarUrl!)
                            : null,
                        child: request.receiverAvatarUrl == null
                            ? Text(
                                request.receiverName.isNotEmpty
                                    ? request.receiverName[0].toUpperCase()
                                    : '?',
                              )
                            : null,
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Unable to load outgoing requests.'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}