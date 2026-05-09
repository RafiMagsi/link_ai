import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../data/models/post_model.dart';
import '../../../../video/presentation/widgets/feed_hls_video_player.dart';

class PostMediaWidget extends StatelessWidget {
  const PostMediaWidget({
    super.key,
    required this.mediaList,
    required this.postId,
    this.onVideoTap,
  });

  final List<PostMediaModel> mediaList;
  final String postId;
  final VoidCallback? onVideoTap;

  @override
  Widget build(BuildContext context) {
    if (mediaList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Single media item
    if (mediaList.length == 1) {
      final media = mediaList.first;
      if (media.type == 'video') {
        return GestureDetector(
          onTap: onVideoTap,
          behavior: HitTestBehavior.opaque,
          child: FeedHlsVideoPlayer(
            media: media,
            isActive: true,
            isFeedView: true,
            maxHeight: 350,
          ),
        );
      }
      return _ImageWidget(url: media.url);
    }

    // Multiple media items - grid layout
    return _MediaGrid(mediaList: mediaList, postId: postId);
  }
}

class _ImageWidget extends StatelessWidget {
  const _ImageWidget({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator.adaptive()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.mediaList, required this.postId});

  final List<PostMediaModel> mediaList;
  final String postId;

  @override
  Widget build(BuildContext context) {
    final cols = mediaList.length <= 2 ? 2 : 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.0,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: List.generate(mediaList.length, (index) {
          final media = mediaList[index];
          return media.type == 'video'
              ? _VideoThumbnail(media: media)
              : _ImageGridItem(url: media.url);
        }),
      ),
    );
  }
}

class _ImageGridItem extends StatelessWidget {
  const _ImageGridItem({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      errorWidget: (context, url, error) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.media});

  final PostMediaModel media;

  @override
  Widget build(BuildContext context) {
    if (media.thumbnailUrl != null && media.thumbnailUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: media.thumbnailUrl!,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            errorWidget: (context, url, error) => _buildFallback(context),
          ),
          _buildBadge(),
        ],
      );
    }

    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.videocam,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          _buildBadge(),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Positioned(
      bottom: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Text(
          'VIDEO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
