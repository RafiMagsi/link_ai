import 'package:flutter/material.dart';

import '../theme/app_theme_colors.dart';

class AppUserAvatar extends StatelessWidget {
  const AppUserAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 20,
    this.onTap,
  });

  final String? avatarUrl;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: colors.border,
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? NetworkImage(avatarUrl!)
          : null,
      child: (avatarUrl == null || avatarUrl!.isEmpty)
          ? Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.onSurface,
            )
          : null,
    );

    if (onTap == null) return avatar;

    return InkResponse(onTap: onTap, radius: radius + 12, child: avatar);
  }
}
