import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme_colors.dart';

class PostAvatar extends StatelessWidget {
  const PostAvatar({super.key, required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CircleAvatar(
      radius: 23,
      backgroundColor: colors.border,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}
