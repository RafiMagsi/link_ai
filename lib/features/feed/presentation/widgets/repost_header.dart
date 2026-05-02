import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../data/models/post_model.dart';

class RepostHeader extends StatelessWidget {
  const RepostHeader({
    super.key,
    required this.post,
    required this.onAuthorTap,
  });

  final PostModel post;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.md,
        AppSizes.lg,
        AppSizes.sm,
      ),
      child: InkWell(
        onTap: onAuthorTap,
        child: Row(
          children: [
            Icon(
              Icons.repeat,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${post.authorName} reposted',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
