import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_theme_colors.dart';

class PostMediaGrid extends StatelessWidget {
  const PostMediaGrid({
    super.key,
    required this.mediaUrls,
    required this.heroTagPrefix,
    required this.onTap,
    this.onDoubleTap,
  });

  final List<String> mediaUrls;
  final String heroTagPrefix;
  final void Function(int index) onTap;
  final VoidCallback? onDoubleTap;

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
        onDoubleTap: onDoubleTap,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSizes.md,
        crossAxisSpacing: AppSizes.md,
      ),
      itemBuilder: (context, index) => _MediaTile(
        url: mediaUrls[index],
        heroTag: '$heroTagPrefix$index',
        onTap: () => onTap(index),
        onDoubleTap: onDoubleTap,
      ),
    );
  }
}

class _MediaTile extends StatefulWidget {
  const _MediaTile({
    required this.url,
    required this.heroTag,
    required this.onTap,
    required this.onDoubleTap,
    this.height,
  });

  final String url;
  final String heroTag;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final double? height;

  @override
  State<_MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<_MediaTile> {
  bool _showLikePulse = false;

  void _pulse() {
    if (!mounted) return;
    setState(() => _showLikePulse = true);
    Future<void>.delayed(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      setState(() => _showLikePulse = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final colors = context.appColors;

      return GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap == null
            ? null
            : () {
                try {
                  widget.onDoubleTap!.call();
                  _pulse();
                } catch (e) {
                 debugPrint('Error handling double tap: $e');
                }
              },
        child: Hero(
          tag: widget.heroTag,
          child: Container(
            height: widget.height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: colors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCachedImage(context, colors),
                IgnorePointer(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _showLikePulse ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: AnimatedScale(
                        scale: _showLikePulse ? 1 : 0.7,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          Icons.favorite,
                          size: 72,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
     debugPrint('Error building media tile: $e');
      return _buildErrorPlaceholder(context);
    }
  }

  Widget _buildCachedImage(BuildContext context, dynamic colors) {
    try {
      // Validate URL before attempting to load
      if (widget.url.isEmpty) {
        return Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: colors.mutedText,
          ),
        );
      }

      return CachedNetworkImage(
        imageUrl: widget.url,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surface,
        ),
        errorWidget: (context, url, error) {
         debugPrint('Error loading image from $url: $error');
          return Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: colors.mutedText,
            ),
          );
        },
      );
    } catch (e) {
     debugPrint('Error building cached image widget: $e');
      return Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colors.mutedText,
        ),
      );
    }
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    try {
      final colors = context.appColors;
      return Container(
        height: widget.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: colors.mutedText,
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
