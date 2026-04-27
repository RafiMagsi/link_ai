import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/hashtag_utils.dart';
import '../../../feed/data/models/post_model.dart';
import '../../../feed/presentation/providers/post_providers.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

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

// Search state providers
final searchQueryProvider = StateProvider<String>((ref) => '');

final userSearchResultsProvider =
    FutureProvider<List<ProfileModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return [];
  }

  try {
    final dataSource = ref.watch(profileRemoteDataSourceProvider);
    return await dataSource.searchProfiles(query, limit: 20).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
       debugPrint('Timeout searching profiles for query: $query');
        return [];
      },
    );
  } catch (error, stackTrace) {
   debugPrint('Error searching profiles for query: $query\n$error\n$stackTrace');
    return [];
  }
});

final postSearchResultsProvider = FutureProvider<List<PostModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return [];
  }

  try {
    final dataSource = ref.watch(postRemoteDataSourceProvider);
    return await dataSource.searchPosts(query, limit: 20).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
       debugPrint('Timeout searching posts for query: $query');
        return [];
      },
    );
  } catch (error, stackTrace) {
   debugPrint('Error searching posts for query: $query\n$error\n$stackTrace');
    return [];
  }
});

final hashtagSearchResultsProvider =
    FutureProvider<List<String>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final trending = ref.watch(trendingHashtagsProvider);

  if (query.isEmpty) {
    return trending.when(
      data: (trends) => trends.map((t) => t.tag).toList(),
      loading: () => [],
      error: (_, _) => [],
    );
  }

  return trending.when(
    data: (trends) {
      final queryLower = query.toLowerCase();
      return trends
          .where((trend) => trend.tag.toLowerCase().contains(queryLower))
          .map((t) => t.tag)
          .toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

final productSearchResultsProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return [];
  }

  try {
    final dataSource = ref.watch(productRemoteDataSourceProvider);
    return await dataSource.searchProducts(query, limit: 20).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
       debugPrint('Timeout searching products for query: $query');
        return [];
      },
    );
  } catch (error, stackTrace) {
   debugPrint('Error searching products for query: $query\n$error\n$stackTrace');
    return [];
  }
});

// Recent searches provider - FutureProvider with async initialization
final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    return searches.take(10).toList();
  } catch (error, stackTrace) {
   debugPrint('Error fetching recent searches: $error\n$stackTrace');
    return [];
  }
});

Future<void> addRecentSearch(String query) async {
  if (query.isEmpty) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];

    searches.remove(query);
    searches.insert(0, query);

    await prefs.setStringList('recent_searches', searches.take(20).toList());
  } catch (error, stackTrace) {
   debugPrint('Error adding recent search: $error\n$stackTrace');
  }
}

Future<void> clearRecentSearches() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
  } catch (error, stackTrace) {
   debugPrint('Error clearing recent searches: $error\n$stackTrace');
  }
}
