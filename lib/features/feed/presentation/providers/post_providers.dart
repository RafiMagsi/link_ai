import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/config/app_limits_provider.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../connect/presentation/providers/connect_providers.dart';
import '../../data/datasources/post_remote_datasource.dart';
import '../../data/models/post_comment_model.dart';
import '../../data/models/post_model.dart';
import '../../../../core/services/s3_upload_service.dart';

// Re-export from video_providers for convenience
export '../../../video/presentation/providers/video_providers.dart' show activeVideoPostIdProvider;

// Pagination state class
class PaginatedPostsState {
  final List<PostModel> posts;
  final DocumentSnapshot? cursor;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isInitialLoading;
  final Object? error;

  const PaginatedPostsState({
    required this.posts,
    this.cursor,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.isInitialLoading = false,
    this.error,
  });

  PaginatedPostsState copyWith({
    List<PostModel>? posts,
    DocumentSnapshot? cursor,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isInitialLoading,
    Object? error,
  }) {
    return PaginatedPostsState(
      posts: posts ?? this.posts,
      cursor: cursor ?? this.cursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      error: error ?? this.error,
    );
  }
}

final s3UploadServiceProvider = Provider<S3UploadService>((ref) {
  return S3UploadService();
});

final postRemoteDataSourceProvider = Provider<PostRemoteDataSource>((ref) {
  return PostRemoteDataSource(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(s3UploadServiceProvider),
  );
});

final latestPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(postRemoteDataSourceProvider).watchLatestPosts();
});

final shortVideoFeedProvider = Provider.family<List<PostModel>, PostModel>((
  ref,
  initialPost,
) {
  final latestPosts = ref.watch(latestPostsProvider).asData?.value ?? const [];
  final videoPosts = latestPosts
      .where((post) => post.media.any((media) => media.type == 'video'))
      .toList();

  final containsInitial = videoPosts.any((post) => post.id == initialPost.id);
  final merged = containsInitial ? videoPosts : [initialPost, ...videoPosts];

  merged.sort((a, b) {
    final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });

  final unique = <String>{};
  return merged.where((post) => unique.add(post.id)).toList();
});

// Pagination notifier for Latest posts
class LatestFeedNotifier extends StateNotifier<PaginatedPostsState> {
  LatestFeedNotifier(this._ds)
    : super(const PaginatedPostsState(posts: [], isInitialLoading: true)) {
    loadInitial();
  }

  final PostRemoteDataSource _ds;

  Future<void> loadInitial() async {
    try {
      state = state.copyWith(isInitialLoading: true, error: null);
      final (posts, cursor) = await _ds.fetchLatestPostsPage();
      state = PaginatedPostsState(
        posts: posts,
        cursor: cursor,
        hasMore: posts.length >= 20,
        isInitialLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e, isInitialLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    try {
      state = state.copyWith(isLoadingMore: true, error: null);
      final (newPosts, cursor) = await _ds.fetchLatestPostsPage(
        after: state.cursor,
      );
      if (newPosts.isEmpty) {
        state = state.copyWith(hasMore: false, isLoadingMore: false);
      } else {
        state = PaginatedPostsState(
          posts: [...state.posts, ...newPosts],
          cursor: cursor,
          hasMore: newPosts.length >= 20,
          isLoadingMore: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e, isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

final latestFeedProvider =
    StateNotifierProvider<LatestFeedNotifier, PaginatedPostsState>((ref) {
      final ds = ref.watch(postRemoteDataSourceProvider);
      return LatestFeedNotifier(ds);
    });

// Connected posts derive from latest paginated posts
final connectedFeedProvider = Provider<List<PostModel>>((ref) {
  final latestState = ref.watch(latestFeedProvider);
  final connectionsAsync = ref.watch(myConnectionsProvider);

  return connectionsAsync.when(
    data: (connections) {
      final followingUids = connections
          .map((c) => c.connectedUid)
          .where((uid) => uid.isNotEmpty)
          .toSet();

      return latestState.posts
          .where((p) => followingUids.contains(p.authorUid))
          .toList();
    },
    loading: () => <PostModel>[],
    error: (_, _) => <PostModel>[],
  );
});

// Keep old provider for backward compatibility
final connectedPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref
      .watch(latestPostsProvider)
      .when(
        data: (posts) {
          final connectionsAsync = ref.watch(myConnectionsProvider);
          return connectionsAsync.when(
            data: (connections) {
              final followingUids = connections
                  .map((c) => c.connectedUid)
                  .where((uid) => uid.isNotEmpty)
                  .toSet();

              final connectedPosts = posts
                  .where((p) => followingUids.contains(p.authorUid))
                  .toList();

              return Stream.value(connectedPosts);
            },
            loading: () => Stream.value(<PostModel>[]),
            error: (e, _) => Stream.error(e),
          );
        },
        loading: () => Stream.value(<PostModel>[]),
        error: (e, _) => Stream.error(e),
      );
});

// Viral posts derive from latest paginated posts
final viralFeedProvider = Provider<List<PostModel>>((ref) {
  final latestState = ref.watch(latestFeedProvider);
  final sorted = latestState.posts.toList()
    ..sort(
      (a, b) => _calculateViralScore(b).compareTo(_calculateViralScore(a)),
    );
  return sorted;
});

// Keep old provider for backward compatibility
final viralPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref
      .watch(latestPostsProvider)
      .when(
        data: (posts) => Stream.value(
          posts.toList()..sort(
            (a, b) =>
                _calculateViralScore(b).compareTo(_calculateViralScore(a)),
          ),
        ),
        loading: () => Stream.error(StateError('Loading posts')),
        error: (e, _) => Stream.error(e),
      );
});

int _calculateViralScore(PostModel post) {
  return (post.likesCount * 2) +
      (post.repostsCount * 3) +
      post.commentsCount +
      post.savesCount;
}

final postsByHashtagProvider = StreamProvider.family<List<PostModel>, String>((
  ref,
  tag,
) {
  return ref.watch(postRemoteDataSourceProvider).watchPostsByHashtag(tag);
});

final postsByAuthorProvider = StreamProvider.family<List<PostModel>, String>((
  ref,
  uid,
) {
  return ref.watch(postRemoteDataSourceProvider).watchPostsByAuthor(uid);
});

final likedPostIdsByUserProvider = StreamProvider.family<List<String>, String>((
  ref,
  uid,
) {
  return ref.watch(postRemoteDataSourceProvider).watchLikedPostIdsByUser(uid);
});

final savedPostIdsByUserProvider = StreamProvider.family<List<String>, String>((
  ref,
  uid,
) {
  return ref.watch(postRemoteDataSourceProvider).watchSavedPostIdsByUser(uid);
});

final commentsByAuthorProvider =
    StreamProvider.family<List<PostCommentModel>, String>((ref, uid) {
      return ref.watch(postRemoteDataSourceProvider).watchCommentsByAuthor(uid);
    });

class _OptimisticPostCountNotifier
    extends StateNotifier<Map<String, PostModel>> {
  _OptimisticPostCountNotifier() : super({});

  void updateLikeCount(String postId, PostModel post, bool isLiking) {
    // Use existing optimistic post if available to preserve other count changes
    final basePost = state[postId] ?? post;
    final newLikesCount = isLiking
        ? basePost.likesCount + 1
        : (basePost.likesCount - 1).clamp(0, double.infinity).toInt();
    final updated = basePost.copyWith(likesCount: newLikesCount);
    state = {...state, postId: updated};
  }

  void updateRepostCount(String postId, PostModel post, bool isReposting) {
    // Use existing optimistic post if available to preserve other count changes
    final basePost = state[postId] ?? post;
    final newRepostsCount = isReposting
        ? basePost.repostsCount + 1
        : (basePost.repostsCount - 1).clamp(0, double.infinity).toInt();
    final updated = basePost.copyWith(repostsCount: newRepostsCount);
    state = {...state, postId: updated};
  }

  void updateSaveCount(String postId, PostModel post, bool isSaving) {
    // Use existing optimistic post if available to preserve other count changes
    final basePost = state[postId] ?? post;
    final newSavesCount = isSaving
        ? basePost.savesCount + 1
        : (basePost.savesCount - 1).clamp(0, double.infinity).toInt();
    final updated = basePost.copyWith(savesCount: newSavesCount);
    state = {...state, postId: updated};
  }

  void reset(String postId) {
    final newState = Map<String, PostModel>.from(state);
    newState.remove(postId);
    state = newState;
  }
}

final optimisticPostCountProvider =
    StateNotifierProvider<_OptimisticPostCountNotifier, Map<String, PostModel>>(
      (ref) {
        return _OptimisticPostCountNotifier();
      },
    );

class _OptimisticCommentCountNotifier
    extends StateNotifier<Map<String, PostCommentModel>> {
  _OptimisticCommentCountNotifier() : super({});

  void updateLikeCount(
    String commentId,
    PostCommentModel comment,
    bool isLiking,
  ) {
    // Use existing optimistic comment if available to preserve other count changes
    final baseComment = state[commentId] ?? comment;
    final newLikesCount = isLiking
        ? baseComment.likesCount + 1
        : (baseComment.likesCount - 1).clamp(0, double.infinity).toInt();
    final updated = baseComment.copyWith(likesCount: newLikesCount);
    state = {...state, commentId: updated};
  }

  void updateRepostCount(
    String commentId,
    PostCommentModel comment,
    bool isReposting,
  ) {
    // Use existing optimistic comment if available to preserve other count changes
    final baseComment = state[commentId] ?? comment;
    final newRepostsCount = isReposting
        ? baseComment.repostsCount + 1
        : (baseComment.repostsCount - 1).clamp(0, double.infinity).toInt();
    final updated = baseComment.copyWith(repostsCount: newRepostsCount);
    state = {...state, commentId: updated};
  }

  void updateSaveCount(
    String commentId,
    PostCommentModel comment,
    bool isSaving,
  ) {
    // Use existing optimistic comment if available to preserve other count changes
    final baseComment = state[commentId] ?? comment;
    final newSavesCount = isSaving
        ? baseComment.savesCount + 1
        : (baseComment.savesCount - 1).clamp(0, double.infinity).toInt();
    final updated = baseComment.copyWith(savesCount: newSavesCount);
    state = {...state, commentId: updated};
  }

  void reset(String commentId) {
    final newState = Map<String, PostCommentModel>.from(state);
    newState.remove(commentId);
    state = newState;
  }
}

final optimisticCommentCountProvider =
    StateNotifierProvider<
      _OptimisticCommentCountNotifier,
      Map<String, PostCommentModel>
    >((ref) {
      return _OptimisticCommentCountNotifier();
    });

final postByIdProvider = StreamProvider.family<PostModel?, String>((
  ref,
  postId,
) {
  final realPost = ref.watch(postRemoteDataSourceProvider).watchPost(postId);
  final optimisticPosts = ref.watch(optimisticPostCountProvider);

  return realPost.map((post) {
    if (post == null) return null;
    // If there's an optimistic count update, use it
    if (optimisticPosts.containsKey(postId)) {
      return optimisticPosts[postId];
    }
    return post;
  });
});

final postCommentsProvider =
    StreamProvider.family<List<PostCommentModel>, String>((ref, postId) {
      return ref
          .watch(postRemoteDataSourceProvider)
          .watchComments(postId)
          .map(
            (flatComments) => PostCommentModel.buildCommentTree(flatComments),
          );
    });

class _OptimisticBoolNotifier extends StateNotifier<bool?> {
  _OptimisticBoolNotifier() : super(null);

  void set(bool value) {
    state = value;
  }

  void reset() {
    state = null;
  }
}

// Separate optimistic providers for each action to prevent state conflicts
final optimisticLikeProvider =
    StateNotifierProvider.family<_OptimisticBoolNotifier, bool?, String>(
      (ref, postId) => _OptimisticBoolNotifier(),
    );

final optimisticSaveProvider =
    StateNotifierProvider.family<_OptimisticBoolNotifier, bool?, String>(
      (ref, postId) => _OptimisticBoolNotifier(),
    );

final optimisticRepostProvider =
    StateNotifierProvider.family<_OptimisticBoolNotifier, bool?, String>(
      (ref, postId) => _OptimisticBoolNotifier(),
    );

final postInteractionStateProvider =
    FutureProvider.family<PostInteractionState, String>((ref, postId) async {
      final user = ref.watch(currentUserProvider);

      if (user == null) {
        return const PostInteractionState(
          liked: false,
          reposted: false,
          saved: false,
        );
      }

      // Check for optimistic state first for each action independently
      final optimisticLiked = ref.watch(optimisticLikeProvider(postId));
      final optimisticSaved = ref.watch(optimisticSaveProvider(postId));
      final optimisticReposted = ref.watch(optimisticRepostProvider(postId));

      // If all are null, fetch from backend
      if (optimisticLiked == null &&
          optimisticSaved == null &&
          optimisticReposted == null) {
        final dataSource = ref.watch(postRemoteDataSourceProvider);

        final results = await Future.wait([
          dataSource.hasLiked(postId: postId, uid: user.uid),
          dataSource.hasReposted(postId: postId, uid: user.uid),
          dataSource.hasSaved(postId: postId, uid: user.uid),
        ]);

        return PostInteractionState(
          liked: results[0],
          reposted: results[1],
          saved: results[2],
        );
      }

      // Fetch all from backend to get baseline
      final dataSource = ref.watch(postRemoteDataSourceProvider);
      final results = await Future.wait([
        dataSource.hasLiked(postId: postId, uid: user.uid),
        dataSource.hasReposted(postId: postId, uid: user.uid),
        dataSource.hasSaved(postId: postId, uid: user.uid),
      ]);

      return PostInteractionState(
        liked: optimisticLiked ?? results[0],
        reposted: optimisticReposted ?? results[1],
        saved: optimisticSaved ?? results[2],
      );
    });

final postControllerProvider =
    StateNotifierProvider<PostController, AsyncValue<void>>((ref) {
      return PostController(ref, ref.watch(postRemoteDataSourceProvider));
    });

class PostInteractionState {
  final bool liked;
  final bool reposted;
  final bool saved;

  const PostInteractionState({
    required this.liked,
    required this.reposted,
    required this.saved,
  });

  factory PostInteractionState.initial() {
    return const PostInteractionState(
      liked: false,
      reposted: false,
      saved: false,
    );
  }

  PostInteractionState copyWith({bool? liked, bool? reposted, bool? saved}) {
    return PostInteractionState(
      liked: liked ?? this.liked,
      reposted: reposted ?? this.reposted,
      saved: saved ?? this.saved,
    );
  }
}

class CommentInteractionState {
  final bool liked;
  final bool reposted;
  final bool saved;

  const CommentInteractionState({
    required this.liked,
    required this.reposted,
    required this.saved,
  });

  factory CommentInteractionState.initial() {
    return const CommentInteractionState(
      liked: false,
      reposted: false,
      saved: false,
    );
  }

  CommentInteractionState copyWith({bool? liked, bool? reposted, bool? saved}) {
    return CommentInteractionState(
      liked: liked ?? this.liked,
      reposted: reposted ?? this.reposted,
      saved: saved ?? this.saved,
    );
  }
}

// Separate optimistic providers for comments
final optimisticCommentLikeProvider =
    StateNotifierProvider.family<_OptimisticBoolNotifier, bool?, String>(
      (ref, commentId) => _OptimisticBoolNotifier(),
    );

final optimisticCommentSaveProvider =
    StateNotifierProvider.family<_OptimisticBoolNotifier, bool?, String>(
      (ref, commentId) => _OptimisticBoolNotifier(),
    );

final optimisticCommentRepostProvider =
    StateNotifierProvider.family<_OptimisticBoolNotifier, bool?, String>(
      (ref, commentId) => _OptimisticBoolNotifier(),
    );

final commentInteractionStateProvider =
    FutureProvider.family<
      CommentInteractionState,
      ({String postId, String commentId})
    >((ref, params) async {
      final user = ref.watch(currentUserProvider);

      if (user == null) {
        return const CommentInteractionState(
          liked: false,
          reposted: false,
          saved: false,
        );
      }

      final postId = params.postId;
      final commentId = params.commentId;

      // Check for optimistic state first for each action independently
      final optimisticLiked = ref.watch(
        optimisticCommentLikeProvider(commentId),
      );
      final optimisticSaved = ref.watch(
        optimisticCommentSaveProvider(commentId),
      );
      final optimisticReposted = ref.watch(
        optimisticCommentRepostProvider(commentId),
      );

      // If all are null, fetch from backend
      if (optimisticLiked == null &&
          optimisticSaved == null &&
          optimisticReposted == null) {
        final dataSource = ref.watch(postRemoteDataSourceProvider);

        final results = await Future.wait<bool>([
          dataSource.hasLikedComment(
            postId: postId,
            commentId: commentId,
            uid: user.uid,
          ),
          dataSource.hasRepostedComment(
            postId: postId,
            commentId: commentId,
            uid: user.uid,
          ),
          dataSource.hasSavedComment(
            postId: postId,
            commentId: commentId,
            uid: user.uid,
          ),
        ]);

        return CommentInteractionState(
          liked: results[0],
          reposted: results[1],
          saved: results[2],
        );
      }

      // Fetch all from backend to get baseline
      final dataSource = ref.watch(postRemoteDataSourceProvider);
      final results = await Future.wait<bool>([
        dataSource.hasLikedComment(
          postId: postId,
          commentId: commentId,
          uid: user.uid,
        ),
        dataSource.hasRepostedComment(
          postId: postId,
          commentId: commentId,
          uid: user.uid,
        ),
        dataSource.hasSavedComment(
          postId: postId,
          commentId: commentId,
          uid: user.uid,
        ),
      ]);

      return CommentInteractionState(
        liked: optimisticLiked ?? results[0],
        reposted: optimisticReposted ?? results[1],
        saved: optimisticSaved ?? results[2],
      );
    });

class PostController extends StateNotifier<AsyncValue<void>> {
  PostController(this._ref, this._postRemoteDataSource)
    : super(const AsyncData(null));

  final Ref _ref;
  final PostRemoteDataSource _postRemoteDataSource;

  Future<void> createPost({
    required String text,
    required List<File> mediaFiles,
    required PostIntent postIntent,
  }) async {
    state = const AsyncLoading();

    try {
      final limits = _ref.read(appLimitsProvider);

      // Validate input
      if (text.trim().isEmpty) {
        throw ValidationError('Post text cannot be empty');
      }

      // Validate media files
      final maxImageSize = limits.imageMaxBytes;
      final maxVideoSize = limits.videoMaxBytes;
      final maxTotalSize =
          (limits.imageMaxBytes * limits.postMaxMediaItems) +
          limits.videoMaxBytes;
      int totalSize = 0;

      for (final file in mediaFiles) {
        final fileSize = file.lengthSync();
        final isVideo = _isVideoFile(file.path);
        if (isVideo && fileSize > maxVideoSize) {
          throw FileSizeError(
            'Video size exceeds ${(maxVideoSize / (1024 * 1024)).round()}MB limit',
          );
        }
        if (!isVideo && fileSize > maxImageSize) {
          throw FileSizeError(
            'Image size exceeds ${(maxImageSize / (1024 * 1024)).round()}MB limit',
          );
        }
        totalSize += fileSize;
      }

      if (totalSize > maxTotalSize) {
        throw FileSizeError('Total media size exceeds allowed limit');
      }

      final profile = await _ref.read(myProfileProvider.future);

      if (profile == null) {
        throw Exception('Profile not found. Please log in again.');
      }

      await _postRemoteDataSource
          .createPost(
            profile: profile,
            text: text,
            mediaFiles: mediaFiles,
            postIntent: postIntent,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException('Post creation timed out'),
          );

      state = const AsyncData(null);
    } on ValidationError catch (error, stackTrace) {
      debugPrint('Validation error creating post: $error');
      state = AsyncError(error, stackTrace);
    } on FileSizeError catch (error, stackTrace) {
      debugPrint('File size error creating post: $error');
      state = AsyncError(error, stackTrace);
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('Timeout creating post: $error');
      state = AsyncError(
        Exception(
          'Post creation took too long. Please check your connection and try again.',
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint('Error creating post: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.3gp');
  }

  Future<void> toggleLike(String postId, {PostModel? post}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to perform this action.'),
        StackTrace.current,
      );
      return;
    }

    try {
      // Read current state synchronously (from cache)
      final currentInteractionState = _ref
          .read(postInteractionStateProvider(postId))
          .asData
          ?.value;

      if (currentInteractionState == null) {
        throw Exception('Interaction state not found.');
      }

      final newLiked = !currentInteractionState.liked;

      // ✅ OPTIMISTIC UPDATE - immediately update UI (before any async operations)
      // Update only the like state, leaving save/repost independent
      _ref.read(optimisticLikeProvider(postId).notifier).set(newLiked);

      // Use provided post or try to get from cache
      var currentPost =
          post ?? _ref.read(postByIdProvider(postId)).asData?.value;
      currentPost ??= await _ref.read(postByIdProvider(postId).future);

      // Update count optimistically if post data is available
      if (currentPost != null) {
        _ref
            .read(optimisticPostCountProvider.notifier)
            .updateLikeCount(postId, currentPost, newLiked);
      }

      // Make API call in background (doesn't block UI)
      await _postRemoteDataSource
          .toggleLike(postId: postId, uid: user.uid)
          .timeout(const Duration(seconds: 10));

      // On success, keep optimistic state - let Firestore update naturally
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling like: $error\n$stackTrace');
      // Only revert like state on error, leaving save/repost untouched
      _ref.read(optimisticLikeProvider(postId).notifier).reset();
      _ref.read(optimisticPostCountProvider.notifier).reset(postId);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleRepost(String postId, {PostModel? post}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to perform this action.'),
        StackTrace.current,
      );
      return;
    }

    try {
      // Read current state synchronously (from cache)
      final currentInteractionState = _ref
          .read(postInteractionStateProvider(postId))
          .asData
          ?.value;

      if (currentInteractionState == null) {
        throw Exception('Interaction state not found.');
      }

      final newReposted = !currentInteractionState.reposted;

      // ✅ OPTIMISTIC UPDATE - immediately update UI (before any async operations)
      // Update only the repost state, leaving like/save independent
      _ref.read(optimisticRepostProvider(postId).notifier).set(newReposted);

      // Use provided post or try to get from cache
      var currentPost =
          post ?? _ref.read(postByIdProvider(postId)).asData?.value;
      currentPost ??= await _ref.read(postByIdProvider(postId).future);

      // Update count optimistically if post data is available
      if (currentPost != null) {
        _ref
            .read(optimisticPostCountProvider.notifier)
            .updateRepostCount(postId, currentPost, newReposted);
      }

      // Fetch profile data asynchronously in background
      final myProfile = await _ref.read(myProfileProvider.future);

      if (myProfile == null) {
        throw Exception('Profile not found. Please log in again.');
      }

      if (currentPost == null) {
        throw Exception('Post not found.');
      }

      // Make API call in background (doesn't block UI)
      await _postRemoteDataSource
          .toggleRepostOfPost(
            originalPost: currentPost,
            repostingUserUid: user.uid,
            repostingUserName: myProfile.name,
            repostingUserRole: myProfile.role,
            repostingUserAvatarUrl: myProfile.avatarUrl,
          )
          .timeout(const Duration(seconds: 10));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling repost: $error\n$stackTrace');
      // Only revert repost state on error, leaving like/save untouched
      _ref.read(optimisticRepostProvider(postId).notifier).reset();
      _ref.read(optimisticPostCountProvider.notifier).reset(postId);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleRepostOfPost(String postId) async {
    await toggleRepost(postId);
  }

  Future<void> toggleSave(String postId, {PostModel? post}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to perform this action.'),
        StackTrace.current,
      );
      return;
    }

    try {
      // Read current state synchronously (from cache)
      final currentInteractionState = _ref
          .read(postInteractionStateProvider(postId))
          .asData
          ?.value;

      if (currentInteractionState == null) {
        throw Exception('Interaction state not found.');
      }

      final newSaved = !currentInteractionState.saved;

      // ✅ OPTIMISTIC UPDATE - immediately update UI (before any async operations)
      // Update only the save state, leaving like/repost independent
      _ref.read(optimisticSaveProvider(postId).notifier).set(newSaved);

      // Use provided post or try to get from cache
      var currentPost =
          post ?? _ref.read(postByIdProvider(postId)).asData?.value;
      currentPost ??= await _ref.read(postByIdProvider(postId).future);

      // Update count optimistically if post data is available
      if (currentPost != null) {
        _ref
            .read(optimisticPostCountProvider.notifier)
            .updateSaveCount(postId, currentPost, newSaved);
      }

      // Make API call in background (doesn't block UI)
      await _postRemoteDataSource
          .toggleSave(postId: postId, uid: user.uid)
          .timeout(const Duration(seconds: 10));

      // Keep optimistic state on success
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling save: $error\n$stackTrace');
      // Only revert save state on error, leaving like/repost untouched
      _ref.read(optimisticSaveProvider(postId).notifier).reset();
      _ref.read(optimisticPostCountProvider.notifier).reset(postId);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) async {
    state = const AsyncLoading();

    try {
      // Validate input
      if (text.trim().isEmpty) {
        throw ValidationError('Comment text cannot be empty');
      }

      if (text.length > 500) {
        throw ValidationError('Comment text cannot exceed 500 characters');
      }

      final profile = await _ref.read(myProfileProvider.future);

      if (profile == null) {
        throw Exception('Profile not found. Please log in again.');
      }

      await _postRemoteDataSource
          .addComment(
            profile: profile,
            postId: postId,
            text: text,
            parentCommentId: parentCommentId,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Adding comment timed out'),
          );

      state = const AsyncData(null);
    } on ValidationError catch (error, stackTrace) {
      debugPrint('Validation error adding comment: $error');
      state = AsyncError(error, stackTrace);
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('Timeout adding comment: $error');
      state = AsyncError(
        Exception('Comment submission took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint('Error adding comment: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setBestAnswer({
    required String postId,
    required PostIntent postIntent,
    required String? commentId,
  }) async {
    state = const AsyncLoading();

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('You must be logged in to update best answer.');
      }

      await _postRemoteDataSource
          .setBestAnswer(
            postId: postId,
            authorUid: user.uid,
            postIntent: postIntent,
            commentId: commentId,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('Updating best answer timed out'),
          );

      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('Timeout updating best answer: $error');
      state = AsyncError(
        Exception('Best answer update took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint('Error updating best answer: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to report a post.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      // Validate input
      if (reason.trim().isEmpty) {
        throw ValidationError('Please provide a reason for reporting');
      }

      if (reason.length > 1000) {
        throw ValidationError('Reason cannot exceed 1000 characters');
      }

      await _postRemoteDataSource
          .reportPost(postId: postId, reporterUid: user.uid, reason: reason)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('Report submission timed out'),
          );
      state = const AsyncData(null);
    } on ValidationError catch (error, stackTrace) {
      debugPrint('Validation error reporting post: $error');
      state = AsyncError(error, stackTrace);
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('Timeout reporting post: $error');
      state = AsyncError(
        Exception('Report submission took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      debugPrint('Error reporting post: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    PostCommentModel? comment,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to perform this action.'),
        StackTrace.current,
      );
      return;
    }

    try {
      // Read current state synchronously (from cache)
      final currentInteractionState = _ref
          .read(
            commentInteractionStateProvider((
              postId: postId,
              commentId: commentId,
            )),
          )
          .asData
          ?.value;

      if (currentInteractionState == null) {
        throw Exception('Interaction state not found.');
      }

      final newLiked = !currentInteractionState.liked;

      // ✅ OPTIMISTIC UPDATE - immediately update UI (before any async operations)
      // Update only the like state, leaving save/repost independent
      _ref
          .read(optimisticCommentLikeProvider(commentId).notifier)
          .set(newLiked);

      // Update count optimistically if comment data is available
      if (comment != null) {
        _ref
            .read(optimisticCommentCountProvider.notifier)
            .updateLikeCount(commentId, comment, newLiked);
      }

      // Make API call in background (doesn't block UI)
      await _postRemoteDataSource
          .toggleCommentLike(
            postId: postId,
            commentId: commentId,
            uid: user.uid,
          )
          .timeout(const Duration(seconds: 10));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling comment like: $error\n$stackTrace');
      // Only revert like state on error, leaving save/repost untouched
      _ref.read(optimisticCommentLikeProvider(commentId).notifier).reset();
      _ref.read(optimisticCommentCountProvider.notifier).reset(commentId);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleCommentSave({
    required String postId,
    required String commentId,
    PostCommentModel? comment,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to perform this action.'),
        StackTrace.current,
      );
      return;
    }

    try {
      // Read current state synchronously (from cache)
      final currentInteractionState = _ref
          .read(
            commentInteractionStateProvider((
              postId: postId,
              commentId: commentId,
            )),
          )
          .asData
          ?.value;

      if (currentInteractionState == null) {
        throw Exception('Interaction state not found.');
      }

      final newSaved = !currentInteractionState.saved;

      // ✅ OPTIMISTIC UPDATE - immediately update UI (before any async operations)
      // Update only the save state, leaving like/repost independent
      _ref
          .read(optimisticCommentSaveProvider(commentId).notifier)
          .set(newSaved);

      // Update count optimistically if comment data is available
      if (comment != null) {
        _ref
            .read(optimisticCommentCountProvider.notifier)
            .updateSaveCount(commentId, comment, newSaved);
      }

      // Make API call in background (doesn't block UI)
      await _postRemoteDataSource
          .toggleCommentSave(
            postId: postId,
            commentId: commentId,
            uid: user.uid,
          )
          .timeout(const Duration(seconds: 10));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling comment save: $error\n$stackTrace');
      // Only revert save state on error, leaving like/repost untouched
      _ref.read(optimisticCommentSaveProvider(commentId).notifier).reset();
      _ref.read(optimisticCommentCountProvider.notifier).reset(commentId);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleCommentRepost({
    required String postId,
    required String commentId,
    required String commentText,
    required String commentAuthorUid,
    required String commentAuthorName,
    required String? commentAuthorAvatarUrl,
    PostCommentModel? comment,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to perform this action.'),
        StackTrace.current,
      );
      return;
    }

    try {
      // Read current state synchronously (from cache)
      final currentInteractionState = _ref
          .read(
            commentInteractionStateProvider((
              postId: postId,
              commentId: commentId,
            )),
          )
          .asData
          ?.value;

      if (currentInteractionState == null) {
        throw Exception('Interaction state not found.');
      }

      final newReposted = !currentInteractionState.reposted;

      // ✅ OPTIMISTIC UPDATE - immediately update UI (before any async operations)
      // Update only the repost state, leaving like/save independent
      _ref
          .read(optimisticCommentRepostProvider(commentId).notifier)
          .set(newReposted);

      // Update count optimistically if comment data is available
      if (comment != null) {
        _ref
            .read(optimisticCommentCountProvider.notifier)
            .updateRepostCount(commentId, comment, newReposted);
      }

      // Fetch profile data asynchronously in background
      final profile = await _ref.read(myProfileProvider.future);
      if (profile == null) {
        throw Exception('Profile not found. Please log in again.');
      }

      // Make API call in background (doesn't block UI)
      await _postRemoteDataSource
          .toggleCommentRepost(
            postId: postId,
            commentId: commentId,
            uid: user.uid,
            senderName: profile.name,
            senderAvatarUrl: profile.avatarUrl,
            commentText: commentText,
            commentAuthorUid: commentAuthorUid,
            commentAuthorName: commentAuthorName,
            commentAuthorAvatarUrl: commentAuthorAvatarUrl,
          )
          .timeout(const Duration(seconds: 10));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling comment repost: $error\n$stackTrace');
      // Only revert repost state on error, leaving like/save untouched
      _ref.read(optimisticCommentRepostProvider(commentId).notifier).reset();
      _ref.read(optimisticCommentCountProvider.notifier).reset(commentId);
      state = AsyncError(error, stackTrace);
    }
  }
}

/// Provides all media items from a user's posts, sorted by creation date (newest first).
final userMediaProvider =
    FutureProvider.family<List<(PostModel post, int mediaIndex)>, String>((
      ref,
      uid,
    ) async {
      final postsState = ref.watch(postsByAuthorProvider(uid));
      final posts = postsState.asData?.value ?? [];

      final mediaItems = <(PostModel post, int mediaIndex)>[];
      for (final post in posts) {
        if (post.media.isNotEmpty) {
          for (int i = 0; i < post.media.length; i++) {
            mediaItems.add((post, i));
          }
        }
      }

      return mediaItems;
    });
