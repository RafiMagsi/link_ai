import 'package:cached_network_image/cached_network_image.dart';
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

    Widget buildAvatar() {
      if (avatarUrl == null || avatarUrl!.isEmpty) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: colors.border,
          child: Icon(
            Icons.person_outline,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        );
      }

      return CircleAvatar(
        radius: radius,
        backgroundColor: colors.border,
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
      );
    }

    final avatar = buildAvatar();

    if (onTap == null) return avatar;

    return InkResponse(onTap: onTap, radius: radius + 12, child: avatar);
  }
}
