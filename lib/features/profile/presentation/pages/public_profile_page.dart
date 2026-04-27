import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/profile_view.dart';

class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ProfileView(uid: uid, isSelf: false, onEditProfile: () {}),
    );
  }
}
