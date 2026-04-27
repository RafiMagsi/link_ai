import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/hashtag_utils.dart';
import '../../../feed/presentation/providers/post_providers.dart';

class HashtagTrend {
  final String tag;
  final int count;

  const HashtagTrend({required this.tag, required this.count});
}

final trendingHashtagsProvider = StreamProvider<List<HashtagTrend>>((ref) {
  return ref
      .watch(postRemoteDataSourceProvider)
      .watchLatestPosts(limit: 200)
      .map((posts) {
        final counts = <String, int>{};

        for (final post in posts) {
          final tags = post.hashtags.isNotEmpty
              ? post.hashtags
              : HashtagUtils.extractNormalized(post.text);

          for (final tag in tags) {
            counts[tag] = (counts[tag] ?? 0) + 1;
          }
        }

        final trends =
            counts.entries
                .map((e) => HashtagTrend(tag: e.key, count: e.value))
                .toList()
              ..sort((a, b) => b.count.compareTo(a.count));

        return trends.take(20).toList(growable: false);
      });
});
