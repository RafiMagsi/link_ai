import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/managers/feed_video_preload_manager.dart';
import '../../../feed/data/models/post_model.dart';

class FeedVideoController {
  final FeedVideoPreloadManager _manager = FeedVideoPreloadManager.instance;

  Future<void> updateActiveIndex(
    int newIndex,
    List<PostModel> posts,
  ) async {
    await _preloadAroundIndex(videos: posts, index: newIndex);
  }

  Future<void> _preloadAroundIndex({
    required List<PostModel> videos,
    required int index,
  }) async {
    final urlsToKeep = <String>{};

    for (final i in [index - 1, index, index + 1]) {
      if (i < 0 || i >= videos.length) continue;

      final post = videos[i];
      final videoMedia = post.media.firstWhere(
        (m) => m.type == 'video',
        orElse: () => post.media.first,
      );

      if (videoMedia.status != 'ready') continue;

      final videoUrl = videoMedia.hlsUrl ?? videoMedia.url;
      urlsToKeep.add(videoUrl);

      if (i == index || i == index + 1) {
        await _manager.preload(videoUrl);
      }
    }

    await _manager.keepOnly(urlsToKeep);
  }

  Future<void> disposeAll() async {
    await _manager.disposeAll();
  }
}

final feedVideoControllerProvider = Provider<FeedVideoController>((ref) {
  return FeedVideoController();
});
