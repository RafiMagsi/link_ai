import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
  return PostController(
    ref,
    ref.watch(postRemoteDataSourceProvider),
  );
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
  PostController(
    this._ref,
    this._postRemoteDataSource,
  ) : super(const AsyncData(null));

  final Ref _ref;
  final PostRemoteDataSource _postRemoteDataSource;

  Future<void> createPost({
    required String text,
    required List<File> imageFiles,
  }) async {
    state = const AsyncLoading();

    try {
      final profile = await _ref.read(myProfileProvider.future);

      if (profile == null) {
        throw Exception('Profile not found.');
      }

      await _postRemoteDataSource.createPost(
        profile: profile,
        text: text,
        imageFiles: imageFiles,
      );

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleLike(String postId) async {
    await _toggleInteraction(
      postId: postId,
      action: (uid) => _postRemoteDataSource.toggleLike(
        postId: postId,
        uid: uid,
      ),
    );
  }

  Future<void> toggleRepost(String postId) async {
    await _toggleInteraction(
      postId: postId,
      action: (uid) => _postRemoteDataSource.toggleRepost(
        postId: postId,
        uid: uid,
      ),
    );
  }

  Future<void> toggleSave(String postId) async {
    await _toggleInteraction(
      postId: postId,
      action: (uid) => _postRemoteDataSource.toggleSave(
        postId: postId,
        uid: uid,
      ),
    );
  }

  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    state = const AsyncLoading();

    try {
      final profile = await _ref.read(myProfileProvider.future);

      if (profile == null) {
        throw Exception('Profile not found.');
      }

      await _postRemoteDataSource.addComment(
        profile: profile,
        postId: postId,
        text: text,
      );

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> _toggleInteraction({
    required String postId,
    required Future<void> Function(String uid) action,
  }) async {
    final user = _ref.read(currentUserProvider);

    if (user == null) return;

    state = const AsyncLoading();

    try {
      await action(user.uid);

      _ref.invalidate(postInteractionStateProvider(postId));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}