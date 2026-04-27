import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_user_avatar.dart';

class PostAvatar extends StatelessWidget {
  const PostAvatar({super.key, required this.avatarUrl, this.onTap});

  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppUserAvatar(avatarUrl: avatarUrl, radius: 23, onTap: onTap);
  }
}
