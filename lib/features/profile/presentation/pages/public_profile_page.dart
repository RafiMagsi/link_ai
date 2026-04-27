import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/profile_options_sidebar.dart';
import '../widgets/profile_view.dart';

class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ProfileView(
        uid: uid,
        isSelf: false,
        showBackButton: true,
        onEditProfile: () {},
        onOpenMenu: () async {
          await showProfileOptionsSidebar(
            context: context,
            title: 'Profile options',
            actions: [
              ProfileSidebarAction(
                icon: Icons.link,
                label: 'Copy profile link',
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: 'linkai://profiles/$uid'),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Link copied')));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
