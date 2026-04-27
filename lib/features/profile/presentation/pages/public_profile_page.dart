import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/profile_view.dart';

class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () async {
              final action = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  return SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ListTile(title: Text('Profile actions')),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.link),
                          title: const Text('Copy profile link'),
                          onTap: () => Navigator.of(context).pop('copy'),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              );

              if (!context.mounted || action == null) return;
              if (action == 'copy') {
                await Clipboard.setData(
                  ClipboardData(text: 'linkai://profiles/$uid'),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Link copied')));
              }
            },
          ),
        ],
      ),
      body: ProfileView(uid: uid, isSelf: false, onEditProfile: () {}),
    );
  }
}
