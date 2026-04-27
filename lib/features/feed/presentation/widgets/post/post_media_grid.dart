import 'package:flutter/material.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_theme_colors.dart';

class PostMediaGrid extends StatelessWidget {
  const PostMediaGrid({
    super.key,
    required this.mediaUrls,
    required this.heroTagPrefix,
    required this.onTap,
  });

  final List<String> mediaUrls;
  final String heroTagPrefix;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final count = mediaUrls.length.clamp(0, 4);

    if (count == 0) return const SizedBox.shrink();

    if (count == 1) {
      return _MediaTile(
        url: mediaUrls.first,
        height: 220,
        heroTag: '${heroTagPrefix}0',
        onTap: () => onTap(0),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSizes.sm,
        crossAxisSpacing: AppSizes.sm,
      ),
      itemBuilder: (context, index) => _MediaTile(
        url: mediaUrls[index],
        heroTag: '$heroTagPrefix$index',
        onTap: () => onTap(index),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.url,
    required this.heroTag,
    required this.onTap,
    this.height,
  });

  final String url;
  final String heroTag;
  final VoidCallback onTap;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Hero(
        tag: heroTag,
        child: Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: colors.border),
          ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: colors.mutedText,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
