import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
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

final commentsByAuthorProvider =
    StreamProvider.family<List<PostCommentModel>, String>((ref, uid) {
      return ref.watch(postRemoteDataSourceProvider).watchCommentsByAuthor(uid);
    });

final postByIdProvider = StreamProvider.family<PostModel?, String>((
  ref,
  postId,
) {
  return ref.watch(postRemoteDataSourceProvider).watchPost(postId);
});

final postCommentsProvider =
    StreamProvider.family<List<PostCommentModel>, String>((ref, postId) {
      return ref.watch(postRemoteDataSourceProvider).watchComments(postId);
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
}

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

      await _postRemoteDataSource.createPost(
        profile: profile,
        text: text,
        imageFiles: imageFiles,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException('Post creation timed out'),
      );

      state = const AsyncData(null);
    } on ValidationError catch (error, stackTrace) {
      print('Validation error creating post: $error');
      state = AsyncError(error, stackTrace);
    } on FileSizeError catch (error, stackTrace) {
      print('File size error creating post: $error');
      state = AsyncError(error, stackTrace);
    } on TimeoutException catch (error, stackTrace) {
      print('Timeout creating post: $error');
      state = AsyncError(
        Exception('Post creation took too long. Please check your connection and try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      print('Error creating post: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleLike(String postId) async {
    await _toggleInteraction(
      postId: postId,
      action: (uid) =>
          _postRemoteDataSource.toggleLike(postId: postId, uid: uid),
    );
  }

  Future<void> toggleRepost(String postId) async {
    await _toggleInteraction(
      postId: postId,
      action: (uid) =>
          _postRemoteDataSource.toggleRepost(postId: postId, uid: uid),
    );
  }

  Future<void> toggleSave(String postId) async {
    await _toggleInteraction(
      postId: postId,
      action: (uid) =>
          _postRemoteDataSource.toggleSave(postId: postId, uid: uid),
    );
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

      await _postRemoteDataSource.addComment(
        profile: profile,
        postId: postId,
        text: text,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Adding comment timed out'),
      );

      state = const AsyncData(null);
    } on ValidationError catch (error, stackTrace) {
      print('Validation error adding comment: $error');
      state = AsyncError(error, stackTrace);
    } on TimeoutException catch (error, stackTrace) {
      print('Timeout adding comment: $error');
      state = AsyncError(
        Exception('Comment submission took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      print('Error adding comment: $error\n$stackTrace');
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

      await _postRemoteDataSource.reportPost(
        postId: postId,
        reporterUid: user.uid,
        reason: reason,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Report submission timed out'),
      );
      state = const AsyncData(null);
    } on ValidationError catch (error, stackTrace) {
      print('Validation error reporting post: $error');
      state = AsyncError(error, stackTrace);
    } on TimeoutException catch (error, stackTrace) {
      print('Timeout reporting post: $error');
      state = AsyncError(
        Exception('Report submission took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      print('Error reporting post: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> _toggleInteraction({
    required String postId,
    required Future<void> Function(String uid) action,
  }) async {
    final user = _ref.read(currentUserProvider);

    if (user == null) {
      state = AsyncError(
        Exception('You must be logged in to perform this action.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      await action(user.uid).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Interaction request timed out'),
      );

      _ref.invalidate(postInteractionStateProvider(postId));

      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
      print('Timeout toggling interaction: $error');
      state = AsyncError(
        Exception('Operation took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      print('Error toggling interaction: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }
}
