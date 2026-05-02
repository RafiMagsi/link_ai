import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../connect/presentation/providers/connect_providers.dart';
import '../../data/datasources/post_remote_datasource.dart';
import '../../data/models/post_comment_model.dart';
import '../../data/models/post_model.dart';

final postRemoteDataSourceProvider = Provider<PostRemoteDataSource>((ref) {
  return PostRemoteDataSource(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

final latestPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(postRemoteDataSourceProvider).watchLatestPosts();
});

final connectedPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(latestPostsProvider).when(
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

final viralPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(latestPostsProvider).when(
    data: (posts) => Stream.value(
      posts.toList()
        ..sort(
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

class _OptimisticPostCountNotifier extends StateNotifier<Map<String, PostModel>> {
  _OptimisticPostCountNotifier() : super({});

  void updateLikeCount(String postId, PostModel post, bool isLiking) {
    final newLikesCount = isLiking ? post.likesCount + 1 : (post.likesCount - 1).clamp(0, double.infinity).toInt();
    final updated = PostModel(
      id: post.id,
      authorUid: post.authorUid,
      authorName: post.authorName,
      authorRole: post.authorRole,
      authorAvatarUrl: post.authorAvatarUrl,
      text: post.text,
      hashtags: post.hashtags,
      media: post.media,
      likesCount: newLikesCount,
      repostsCount: post.repostsCount,
      commentsCount: post.commentsCount,
      savesCount: post.savesCount,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      colorCode: post.colorCode,
    );
    state = {...state, postId: updated};
  }

  void updateRepostCount(String postId, PostModel post, bool isReposting) {
    final newRepostsCount = isReposting ? post.repostsCount + 1 : (post.repostsCount - 1).clamp(0, double.infinity).toInt();
    final updated = PostModel(
      id: post.id,
      authorUid: post.authorUid,
      authorName: post.authorName,
      authorRole: post.authorRole,
      authorAvatarUrl: post.authorAvatarUrl,
      text: post.text,
      hashtags: post.hashtags,
      media: post.media,
      likesCount: post.likesCount,
      repostsCount: newRepostsCount,
      commentsCount: post.commentsCount,
      savesCount: post.savesCount,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      colorCode: post.colorCode,
    );
    state = {...state, postId: updated};
  }

  void updateSaveCount(String postId, PostModel post, bool isSaving) {
    final newSavesCount = isSaving ? post.savesCount + 1 : (post.savesCount - 1).clamp(0, double.infinity).toInt();
    final updated = PostModel(
      id: post.id,
      authorUid: post.authorUid,
      authorName: post.authorName,
      authorRole: post.authorRole,
      authorAvatarUrl: post.authorAvatarUrl,
      text: post.text,
      hashtags: post.hashtags,
      media: post.media,
      likesCount: post.likesCount,
      repostsCount: post.repostsCount,
      commentsCount: post.commentsCount,
      savesCount: newSavesCount,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      colorCode: post.colorCode,
    );
    state = {...state, postId: updated};
  }

  void reset(String postId) {
    final newState = Map<String, PostModel>.from(state);
    newState.remove(postId);
    state = newState;
  }
}

final optimisticPostCountProvider =
    StateNotifierProvider<_OptimisticPostCountNotifier, Map<String, PostModel>>((ref) {
      return _OptimisticPostCountNotifier();
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
      return ref.watch(postRemoteDataSourceProvider).watchComments(postId).map(
            (flatComments) => PostCommentModel.buildCommentTree(flatComments),
          );
    });

class _OptimisticInteractionNotifier extends StateNotifier<PostInteractionState?> {
  _OptimisticInteractionNotifier() : super(null);

  void setOptimistic(PostInteractionState state) {
    this.state = state;
  }

  void resetOptimistic() {
    state = null;
  }
}

final optimisticInteractionProvider =
    StateNotifierProvider.family<_OptimisticInteractionNotifier, PostInteractionState?, String>((ref, postId) {
      return _OptimisticInteractionNotifier();
    });

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

      // Check for optimistic state first (scoped to this post)
      final optimisticState = ref.watch(optimisticInteractionProvider(postId));
      if (optimisticState != null) {
        return optimisticState;
      }

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

  PostInteractionState copyWith({
    bool? liked,
    bool? reposted,
    bool? saved,
  }) {
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

  CommentInteractionState copyWith({
    bool? liked,
    bool? reposted,
    bool? saved,
  }) {
    return CommentInteractionState(
      liked: liked ?? this.liked,
      reposted: reposted ?? this.reposted,
      saved: saved ?? this.saved,
    );
  }
}

class _OptimisticCommentInteractionNotifier extends StateNotifier<CommentInteractionState?> {
  _OptimisticCommentInteractionNotifier() : super(null);

  void setOptimistic(CommentInteractionState state) {
    this.state = state;
  }

  void resetOptimistic() {
    state = null;
  }
}

final optimisticCommentInteractionProvider =
    StateNotifierProvider.family<_OptimisticCommentInteractionNotifier, CommentInteractionState?, String>((ref, commentId) {
      return _OptimisticCommentInteractionNotifier();
    });

final commentInteractionStateProvider =
    FutureProvider.family<CommentInteractionState, String>((ref, commentId) async {
      final user = ref.watch(currentUserProvider);

      if (user == null) {
        return const CommentInteractionState(
          liked: false,
          reposted: false,
          saved: false,
        );
      }

      // Check for optimistic state first (scoped to this comment)
      final optimisticState = ref.watch(optimisticCommentInteractionProvider(commentId));
      if (optimisticState != null) {
        return optimisticState;
      }

      return CommentInteractionState.initial();
    });

class PostController extends StateNotifier<AsyncValue<void>> {
  PostController(this._ref, this._postRemoteDataSource)
    : super(const AsyncData(null));

  final Ref _ref;
  final PostRemoteDataSource _postRemoteDataSource;

  Future<void> createPost({
    required String text,
    required List<File> imageFiles,
  }) async {
    state = const AsyncLoading();

    try {
      // Validate input
      if (text.trim().isEmpty) {
        throw ValidationError('Post text cannot be empty');
      }

      // Validate image files
      const maxImageSize = 5 * 1024 * 1024; // 5MB per image
      const maxTotalSize = 20 * 1024 * 1024; // 20MB total
      int totalSize = 0;

      for (final file in imageFiles) {
        final fileSize = file.lengthSync();
        if (fileSize > maxImageSize) {
          throw FileSizeError('Image size exceeds 5MB limit');
        }
        totalSize += fileSize;
      }

      if (totalSize > maxTotalSize) {
        throw FileSizeError('Total image size exceeds 20MB limit');
      }

      final profile = await _ref.read(myProfileProvider.future);

      if (profile == null) {
        throw Exception('Profile not found. Please log in again.');
      }

      await _postRemoteDataSource
          .createPost(profile: profile, text: text, imageFiles: imageFiles)
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

  Future<void> toggleLike(String postId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to perform this action.'),
        StackTrace.current,
      );
      return;
    }

    try {
      // Get current states to toggle
      final currentInteractionState = await _ref.read(postInteractionStateProvider(postId).future);
      final currentPost = _ref.read(postByIdProvider(postId)).asData?.value;
      final newLiked = !currentInteractionState.liked;

      // Optimistic update - immediately update UI (scoped to this post)
      final optimisticInteractionState = currentInteractionState.copyWith(liked: newLiked);
      _ref.read(optimisticInteractionProvider(postId).notifier).setOptimistic(optimisticInteractionState);

      // Also update post count optimistically
      if (currentPost != null) {
        _ref.read(optimisticPostCountProvider.notifier).updateLikeCount(postId, currentPost, newLiked);
      }

      // Make API call in background
      await _postRemoteDataSource
          .toggleLike(postId: postId, uid: user.uid)
          .timeout(const Duration(seconds: 10));

      // On success, keep optimistic state - let Firestore update naturally
      // This prevents UI flashing/reverting while data syncs
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling like: $error\n$stackTrace');
      // Only revert optimistic updates on error
      _ref.read(optimisticInteractionProvider(postId).notifier).resetOptimistic();
      _ref.read(optimisticPostCountProvider.notifier).reset(postId);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleRepost(String postId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to perform this action.'),
        StackTrace.current,
      );
      return;
    }

    try {
      final currentInteractionState = await _ref.read(postInteractionStateProvider(postId).future);
      final currentPost = _ref.read(postByIdProvider(postId)).asData?.value;
      final newReposted = !currentInteractionState.reposted;

      final optimisticInteractionState = currentInteractionState.copyWith(reposted: newReposted);
      _ref.read(optimisticInteractionProvider(postId).notifier).setOptimistic(optimisticInteractionState);

      if (currentPost != null) {
        _ref.read(optimisticPostCountProvider.notifier).updateRepostCount(postId, currentPost, newReposted);
      }

      await _postRemoteDataSource
          .toggleRepost(postId: postId, uid: user.uid)
          .timeout(const Duration(seconds: 10));

      // Keep optimistic state on success
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling repost: $error\n$stackTrace');
      _ref.read(optimisticInteractionProvider(postId).notifier).resetOptimistic();
      _ref.read(optimisticPostCountProvider.notifier).reset(postId);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleRepostOfPost(String postId) async {
    state = const AsyncLoading();

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('You must be logged in to repost.');
      }

      final myProfile = await _ref.read(myProfileProvider.future);
      if (myProfile == null) {
        throw Exception('Profile not found. Please log in again.');
      }

      final originalPost = _ref.read(postByIdProvider(postId)).asData?.value;
      if (originalPost == null) {
        throw Exception('Post not found.');
      }

      await _postRemoteDataSource
          .toggleRepostOfPost(
            originalPost: originalPost,
            repostingUserUid: user.uid,
            repostingUserName: myProfile.name,
            repostingUserRole: myProfile.role,
            repostingUserAvatarUrl: myProfile.avatarUrl,
          )
          .timeout(const Duration(seconds: 15));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling repost: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleSave(String postId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to perform this action.'),
        StackTrace.current,
      );
      return;
    }

    try {
      final currentInteractionState = await _ref.read(postInteractionStateProvider(postId).future);
      final currentPost = _ref.read(postByIdProvider(postId)).asData?.value;
      final newSaved = !currentInteractionState.saved;

      final optimisticInteractionState = currentInteractionState.copyWith(saved: newSaved);
      _ref.read(optimisticInteractionProvider(postId).notifier).setOptimistic(optimisticInteractionState);

      if (currentPost != null) {
        _ref.read(optimisticPostCountProvider.notifier).updateSaveCount(postId, currentPost, newSaved);
      }

      await _postRemoteDataSource
          .toggleSave(postId: postId, uid: user.uid)
          .timeout(const Duration(seconds: 10));

      // Keep optimistic state on success
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling save: $error\n$stackTrace');
      _ref.read(optimisticInteractionProvider(postId).notifier).resetOptimistic();
      _ref.read(optimisticPostCountProvider.notifier).reset(postId);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> addComment({
    required String postId,
    required String text,
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
          .addComment(profile: profile, postId: postId, text: text)
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
      final currentInteractionState = await _ref.read(commentInteractionStateProvider(commentId).future);
      final newLiked = !currentInteractionState.liked;

      final optimisticInteractionState = currentInteractionState.copyWith(liked: newLiked);
      _ref.read(optimisticCommentInteractionProvider(commentId).notifier).setOptimistic(optimisticInteractionState);

      await _postRemoteDataSource
          .toggleCommentLike(postId: postId, commentId: commentId, uid: user.uid)
          .timeout(const Duration(seconds: 10));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling comment like: $error\n$stackTrace');
      _ref.read(optimisticCommentInteractionProvider(commentId).notifier).resetOptimistic();
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleCommentSave({
    required String postId,
    required String commentId,
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
      final currentInteractionState = await _ref.read(commentInteractionStateProvider(commentId).future);
      final newSaved = !currentInteractionState.saved;

      final optimisticInteractionState = currentInteractionState.copyWith(saved: newSaved);
      _ref.read(optimisticCommentInteractionProvider(commentId).notifier).setOptimistic(optimisticInteractionState);

      await _postRemoteDataSource
          .toggleCommentSave(postId: postId, commentId: commentId, uid: user.uid)
          .timeout(const Duration(seconds: 10));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('Error toggling comment save: $error\n$stackTrace');
      _ref.read(optimisticCommentInteractionProvider(commentId).notifier).resetOptimistic();
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
  }) async {
    state = const AsyncLoading();

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('You must be logged in to perform this action.');
      }

      final profile = await _ref.read(myProfileProvider.future);
      if (profile == null) {
        throw Exception('Profile not found. Please log in again.');
      }

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
      state = AsyncError(error, stackTrace);
    }
  }

}
