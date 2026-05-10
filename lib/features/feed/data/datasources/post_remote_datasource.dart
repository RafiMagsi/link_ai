import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../core/constants/post_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/services/s3_upload_service.dart';
import '../../../../core/utils/hashtag_utils.dart';
import '../../../profile/data/models/profile_model.dart';
import '../models/post_comment_model.dart';
import '../models/post_model.dart';

class PostRemoteDataSource {
  PostRemoteDataSource(this._firestore, this._s3);

  final FirebaseFirestore _firestore;
  final S3UploadService _s3;

  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get _posts {
    return _firestore.collection('posts');
  }

  CollectionReference<Map<String, dynamic>> get _postLikes {
    return _firestore.collection('postLikes');
  }

  CollectionReference<Map<String, dynamic>> get _postSaves {
    return _firestore.collection('postSaves');
  }

  CollectionReference<Map<String, dynamic>> get _postReposts {
    return _firestore.collection('postReposts');
  }

  CollectionReference<Map<String, dynamic>> get _commentLikes {
    return _firestore.collection('commentLikes');
  }

  CollectionReference<Map<String, dynamic>> get _commentReposts {
    return _firestore.collection('commentReposts');
  }

  CollectionReference<Map<String, dynamic>> get _commentSaves {
    return _firestore.collection('commentSaves');
  }

  Stream<List<PostModel>> watchLatestPosts({int limit = 50}) {
    return _posts
        .where('deleted', isNotEqualTo: true)
        .orderBy('deleted')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .distinct()
        .map((snapshot) {
          try {
            return snapshot.docs.map(PostModel.fromFirestore).toList();
          } catch (error, stackTrace) {
            debugPrint('Error parsing posts: $error\n$stackTrace');
            return [];
          }
        });
  }

  Stream<PostModel?> watchPost(String postId) {
    return _posts.doc(postId).snapshots().distinct().map((snapshot) {
      try {
        if (!snapshot.exists) return null;
        final data = snapshot.data();
        if (data != null && data['deleted'] == true) return null;
        return PostModel.fromFirestore(snapshot);
      } catch (error, stackTrace) {
        debugPrint('Error parsing post $postId: $error\n$stackTrace');
        return null;
      }
    });
  }

  Stream<List<PostCommentModel>> watchComments(String postId) {
    return _posts.doc(postId).collection('comments').snapshots().distinct().map(
      (snapshot) {
        try {
          final comments = snapshot.docs
              .map(PostCommentModel.fromFirestore)
              .toList();
          comments.sort((a, b) {
            final aTime = a.createdAt ?? a.createdAtClient;
            final bTime = b.createdAt ?? b.createdAtClient;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return -1;
            if (bTime == null) return 1;
            return aTime.compareTo(bTime);
          });
          return comments;
        } catch (error, stackTrace) {
          debugPrint(
            'Error parsing comments for post $postId: $error\n$stackTrace',
          );
          return [];
        }
      },
    );
  }

  Future<void> createPost({
    required ProfileModel profile,
    required String text,
    required List<File> mediaFiles,
    required PostIntent postIntent,
  }) async {
    try {
      final postId = _posts.doc().id;

      final uploadedMedia = <PostMediaModel>[];
      final hashtags = HashtagUtils.extractNormalized(text);

      // Upload files in parallel using Future.wait()
      final uploadTasks = <Future<void>>[];

      for (var i = 0; i < mediaFiles.length; i++) {
        final task = _uploadMediaFile(
          file: mediaFiles[i],
          s3Path: 'postMedia/${profile.uid}/$postId/${_uuid.v4()}',
          index: i,
          uploadedMedia: uploadedMedia,
        );
        uploadTasks.add(task);
      }

      await Future.wait(uploadTasks);

      final post = PostModel(
        id: postId,
        authorUid: profile.uid,
        authorName: profile.name,
        authorRole: profile.role,
        authorAvatarUrl: profile.avatarUrl,
        text: text,
        hashtags: hashtags,
        media: uploadedMedia,
        likesCount: 0,
        repostsCount: 0,
        commentsCount: 0,
        savesCount: 0,
        createdAt: null,
        updatedAt: null,
        postIntent: postIntent,
        colorCode: PostColors.getRandomColor(),
      );

      await _posts
          .doc(postId)
          .set(post.toCreateMap())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Post creation timed out'),
          );
    } on FirebaseException catch (e) {
      debugPrint('Firebase error creating post: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('You do not have permission to create posts.');
      } else if (e.code == 'resource-exhausted') {
        throw RateLimitError(
          'Too many posts created recently. Please try again later.',
        );
      }
      rethrow;
    } on TimeoutException catch (e) {
      debugPrint('Timeout creating post: $e');
      throw Exception(
        'Post creation took too long. Please check your connection and try again.',
      );
    } catch (error, stackTrace) {
      debugPrint('Error creating post: $error\n$stackTrace');
      rethrow;
    }
  }

  Stream<List<PostModel>> watchPostsByHashtag(String tag, {int limit = 50}) {
    final normalized = tag.toLowerCase();
    return _posts
        .where('hashtags', arrayContains: normalized)
        .where('deleted', isNotEqualTo: true)
        .orderBy('deleted')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .distinct()
        .map((snapshot) {
          return snapshot.docs.map(PostModel.fromFirestore).toList();
        });
  }

  Stream<List<PostModel>> watchPostsByAuthor(String uid, {int limit = 50}) {
    return _posts
        .where('authorUid', isEqualTo: uid)
        .where('deleted', isNotEqualTo: true)
        .orderBy('deleted')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .distinct()
        .map((snapshot) {
          try {
            return snapshot.docs.map(PostModel.fromFirestore).toList();
          } catch (error, stackTrace) {
            debugPrint(
              'Error parsing posts by author $uid: $error\n$stackTrace',
            );
            return [];
          }
        });
  }

  Stream<List<String>> watchLikedPostIdsByUser(String uid, {int limit = 50}) {
    return _postLikes
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .distinct()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => (doc.data()['postId'] as String?) ?? '')
                .where((id) => id.isNotEmpty)
                .toList();
          } catch (error, stackTrace) {
            debugPrint(
              'Error parsing liked post IDs for user $uid: $error\n$stackTrace',
            );
            return [];
          }
        });
  }

  Stream<List<String>> watchSavedPostIdsByUser(String uid, {int limit = 50}) {
    return _postSaves
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => (doc.data()['postId'] as String?) ?? '')
                .where((id) => id.isNotEmpty)
                .toList();
          } catch (error, stackTrace) {
            debugPrint(
              'Error parsing saved post IDs for user $uid: $error\n$stackTrace',
            );
            return [];
          }
        });
  }

  Stream<List<PostCommentModel>> watchCommentsByAuthor(
    String uid, {
    int limit = 50,
  }) {
    return _firestore
        .collectionGroup('comments')
        .where('authorUid', isEqualTo: uid)
        .limit(limit)
        .snapshots()
        .distinct()
        .map((snapshot) {
          try {
            final comments = snapshot.docs
                .map(PostCommentModel.fromFirestore)
                .toList();
            comments.sort((a, b) {
              final aTime = a.createdAt ?? a.createdAtClient;
              final bTime = b.createdAt ?? b.createdAtClient;

              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              return bTime.compareTo(aTime);
            });

            if (comments.length > limit) {
              return comments.take(limit).toList();
            }

            return comments;
          } catch (error, stackTrace) {
            debugPrint(
              'Error parsing comments by author $uid: $error\n$stackTrace',
            );
            return [];
          }
        });
  }

  Future<void> reportPost({
    required String postId,
    required String reporterUid,
    required String reason,
  }) async {
    try {
      await _firestore
          .collection('reports')
          .add({
            'type': 'post',
            'postId': postId,
            'targetUid': null,
            'reason': reason,
            'reporterUid': reporterUid,
            'status': 'open',
            'actionType': null,
            'actionBy': null,
            'actionAt': null,
            'createdAt': FieldValue.serverTimestamp(),
            'resolvedAt': null,
            'resolvedBy': null,
          })
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('Report submission timed out'),
          );
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase error reporting post $postId: ${e.code} - ${e.message}',
      );
      if (e.code == 'permission-denied') {
        throw Exception('You do not have permission to report posts.');
      } else if (e.code == 'resource-exhausted') {
        throw RateLimitError(
          'Too many reports submitted. Please try again later.',
        );
      }
      rethrow;
    } on TimeoutException catch (e) {
      debugPrint('Timeout reporting post $postId: $e');
      throw Exception('Report submission took too long. Please try again.');
    } catch (error, stackTrace) {
      debugPrint('Error reporting post $postId: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<void> deletePost({required String postId}) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .update({
            'deleted': true,
            'deletedAt': FieldValue.serverTimestamp(),
          })
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('Delete submission timed out'),
          );
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase error deleting post $postId: ${e.code} - ${e.message}',
      );
      if (e.code == 'permission-denied') {
        throw Exception('You do not have permission to delete this post.');
      } else if (e.code == 'not-found') {
        throw Exception('Post not found.');
      }
      rethrow;
    } on TimeoutException catch (e) {
      debugPrint('Timeout deleting post $postId: $e');
      throw Exception('Delete operation took too long. Please try again.');
    } catch (error, stackTrace) {
      debugPrint('Error deleting post $postId: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<bool> hasLiked({required String postId, required String uid}) async {
    try {
      final doc = await _postLikes
          .doc('${postId}_$uid')
          .get()
          .timeout(const Duration(seconds: 10));
      return doc.exists;
    } catch (error, stackTrace) {
      debugPrint(
        'Error checking if post $postId liked by $uid: $error\n$stackTrace',
      );
      return false;
    }
  }

  Future<bool> hasReposted({
    required String postId,
    required String uid,
  }) async {
    try {
      final result = await _postReposts
          .doc(_postRepostId(postId, uid))
          .get()
          .timeout(const Duration(seconds: 10));
      return result.exists;
    } catch (error, stackTrace) {
      debugPrint(
        'Error checking if post $postId reposted by $uid: $error\n$stackTrace',
      );
      return false;
    }
  }

  Future<bool> hasSaved({required String postId, required String uid}) async {
    try {
      final doc = await _postSaves
          .doc('${postId}_$uid')
          .get()
          .timeout(const Duration(seconds: 10));
      return doc.exists;
    } catch (error, stackTrace) {
      debugPrint(
        'Error checking if post $postId saved by $uid: $error\n$stackTrace',
      );
      return false;
    }
  }

  Future<void> toggleLike({required String postId, required String uid}) async {
    try {
      final likeId = '${postId}_$uid';
      final likeRef = _postLikes.doc(likeId);
      final postRef = _posts.doc(postId);

      await _firestore
          .runTransaction((transaction) async {
            final likeSnapshot = await transaction.get(likeRef);

            if (likeSnapshot.exists) {
              transaction.delete(likeRef);
              transaction.update(postRef, {
                'likesCount': FieldValue.increment(-1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              transaction.set(likeRef, {
                'id': likeId,
                'postId': postId,
                'uid': uid,
                'createdAt': FieldValue.serverTimestamp(),
              });
              transaction.update(postRef, {
                'likesCount': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint(
        'Error toggling like on post $postId by user $uid: $error\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<void> toggleRepost({
    required String postId,
    required String uid,
  }) async {
    throw UnimplementedError(
      'Use toggleRepostOfPost with full repost context.',
    );
  }

  Future<void> toggleSave({required String postId, required String uid}) async {
    try {
      final saveId = '${postId}_$uid';
      final saveRef = _postSaves.doc(saveId);
      final postRef = _posts.doc(postId);

      await _firestore
          .runTransaction((transaction) async {
            final saveSnapshot = await transaction.get(saveRef);

            if (saveSnapshot.exists) {
              transaction.delete(saveRef);
              transaction.update(postRef, {
                'savesCount': FieldValue.increment(-1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              transaction.set(saveRef, {
                'id': saveId,
                'postId': postId,
                'uid': uid,
                'createdAt': FieldValue.serverTimestamp(),
              });
              transaction.update(postRef, {
                'savesCount': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint(
        'Error toggling save on post $postId by user $uid: $error\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<void> toggleRepostOfPost({
    required PostModel originalPost,
    required String repostingUserUid,
    required String repostingUserName,
    required String repostingUserRole,
    required String? repostingUserAvatarUrl,
  }) async {
    try {
      final originalPostRef = _posts.doc(originalPost.id);
      final repostDocId = _repostPostId(originalPost.id, repostingUserUid);
      final repostPostRef = _posts.doc(repostDocId);
      final repostEdgeId = _postRepostId(originalPost.id, repostingUserUid);
      final repostEdgeRef = _postReposts.doc(repostEdgeId);

      await _firestore
          .runTransaction((transaction) async {
            final repostEdgeSnapshot = await transaction.get(repostEdgeRef);
            final repostSnapshot = await transaction.get(repostPostRef);
            final originalSnapshot = await transaction.get(originalPostRef);
            final currentCount =
                (originalSnapshot.data()?['repostsCount'] as int?) ?? 0;

            if (repostEdgeSnapshot.exists || repostSnapshot.exists) {
              transaction.delete(repostEdgeRef);
              transaction.delete(repostPostRef);
              transaction.update(originalPostRef, {
                'repostsCount': currentCount > 0 ? currentCount - 1 : 0,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              transaction.set(repostEdgeRef, {
                'id': repostEdgeId,
                'postId': originalPost.id,
                'uid': repostingUserUid,
                'repostPostId': repostDocId,
                'createdAt': FieldValue.serverTimestamp(),
              });
              transaction.set(repostPostRef, {
                'id': repostDocId,
                'postType': 'repost',
                'authorUid': repostingUserUid,
                'authorName': repostingUserName,
                'authorRole': repostingUserRole,
                'authorAvatarUrl': repostingUserAvatarUrl,
                'text': '',
                'hashtags': [],
                'media': [],
                'likesCount': 0,
                'repostsCount': 0,
                'commentsCount': 0,
                'savesCount': 0,
                'deleted': false,
                'quotedPostId': originalPost.id,
                'colorCode': PostColors.getRandomColor(),
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });

              transaction.update(originalPostRef, {
                'repostsCount': currentCount + 1,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('Error toggling repost: $error\n$stackTrace');
      rethrow;
    }
  }

  String _repostPostId(String postId, String uid) => 'repost_${postId}_$uid';

  String _postRepostId(String postId, String uid) => '${postId}_$uid';

  Future<void> addComment({
    required ProfileModel profile,
    required String postId,
    required String text,
    String? parentCommentId,
  }) async {
    try {
      final commentRef = _posts.doc(postId).collection('comments').doc();

      final comment = PostCommentModel(
        id: commentRef.id,
        postId: postId,
        authorUid: profile.uid,
        authorName: profile.name,
        authorAvatarUrl: profile.avatarUrl,
        text: text,
        createdAt: null,
        createdAtClient: null,
        parentCommentId: parentCommentId,
      );

      final postRef = _posts.doc(postId);

      await _firestore
          .runTransaction((transaction) async {
            transaction.set(commentRef, comment.toCreateMap());
            transaction.update(postRef, {
              'commentsCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint('Error adding comment to post $postId: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<void> setBestAnswer({
    required String postId,
    required String authorUid,
    required PostIntent postIntent,
    required String? commentId,
  }) async {
    if (postIntent != PostIntent.question &&
        postIntent != PostIntent.feedback) {
      throw Exception(
        'Best answer is only available for question or feedback posts.',
      );
    }

    try {
      final postRef = _posts.doc(postId);

      await _firestore
          .runTransaction((transaction) async {
            final postSnapshot = await transaction.get(postRef);
            if (!postSnapshot.exists) {
              throw Exception('Post not found.');
            }

            final postData = postSnapshot.data() ?? <String, dynamic>{};
            if (postData['authorUid'] != authorUid) {
              throw Exception('Only the post author can mark a best answer.');
            }

            if (commentId != null) {
              final commentRef = postRef.collection('comments').doc(commentId);
              final commentSnapshot = await transaction.get(commentRef);
              if (!commentSnapshot.exists) {
                throw Exception('Comment not found.');
              }
            }

            transaction.update(postRef, {
              'bestAnswerCommentId': commentId,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint(
        'Error setting best answer for post $postId: $error\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<List<PostModel>> searchPosts(String query, {int limit = 20}) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _posts
          .where('deleted', isNotEqualTo: true)
          .limit(limit + 50)
          .get()
          .timeout(const Duration(seconds: 10));

      final results = snapshot.docs
          .map((doc) {
            try {
              return PostModel.fromFirestore(doc);
            } catch (error, stackTrace) {
              debugPrint('Error parsing post in search: $error\n$stackTrace');
              return null;
            }
          })
          .whereType<PostModel>()
          .where((post) {
            final textMatch = post.text.toLowerCase().contains(queryLower);
            final hashtagMatch = post.hashtags.any(
              (tag) => tag.toLowerCase().contains(queryLower),
            );

            return textMatch || hashtagMatch;
          })
          .take(limit)
          .toList();

      results.sort(
        (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
          a.createdAt ?? DateTime.now(),
        ),
      );

      return results;
    } catch (error, stackTrace) {
      debugPrint('Error searching posts: $error\n$stackTrace');
      return [];
    }
  }

  // Comment Engagement Methods

  Future<bool> hasLikedComment({
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    try {
      final doc = await _commentLikes
          .doc('${commentId}_$uid')
          .get()
          .timeout(const Duration(seconds: 10));
      return doc.exists;
    } catch (error, stackTrace) {
      debugPrint(
        'Error checking if comment $commentId liked by $uid: $error\n$stackTrace',
      );
      return false;
    }
  }

  Future<bool> hasSavedComment({
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    try {
      final doc = await _commentSaves
          .doc('${commentId}_$uid')
          .get()
          .timeout(const Duration(seconds: 10));
      return doc.exists;
    } catch (error, stackTrace) {
      debugPrint(
        'Error checking if comment $commentId saved by $uid: $error\n$stackTrace',
      );
      return false;
    }
  }

  Future<bool> hasRepostedComment({
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    try {
      final doc = await _commentReposts
          .doc('${commentId}_$uid')
          .get()
          .timeout(const Duration(seconds: 10));
      return doc.exists;
    } catch (error, stackTrace) {
      debugPrint(
        'Error checking if comment $commentId reposted by $uid: $error\n$stackTrace',
      );
      return false;
    }
  }

  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    try {
      final likeId = '${commentId}_$uid';
      final likeRef = _commentLikes.doc(likeId);
      final commentRef = _posts
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      await _firestore
          .runTransaction((transaction) async {
            final likeSnapshot = await transaction.get(likeRef);

            if (likeSnapshot.exists) {
              transaction.delete(likeRef);
              transaction.update(commentRef, {
                'likesCount': FieldValue.increment(-1),
              });
            } else {
              transaction.set(likeRef, {
                'id': likeId,
                'commentId': commentId,
                'postId': postId,
                'uid': uid,
                'createdAt': FieldValue.serverTimestamp(),
              });
              transaction.update(commentRef, {
                'likesCount': FieldValue.increment(1),
              });
            }
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint(
        'Error toggling like on comment $commentId by user $uid: $error\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<void> toggleCommentSave({
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    try {
      final saveId = '${commentId}_$uid';
      final saveRef = _commentSaves.doc(saveId);
      final commentRef = _posts
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      await _firestore
          .runTransaction((transaction) async {
            final saveSnapshot = await transaction.get(saveRef);

            if (saveSnapshot.exists) {
              transaction.delete(saveRef);
              transaction.update(commentRef, {
                'savesCount': FieldValue.increment(-1),
              });
            } else {
              transaction.set(saveRef, {
                'id': saveId,
                'commentId': commentId,
                'postId': postId,
                'uid': uid,
                'createdAt': FieldValue.serverTimestamp(),
              });
              transaction.update(commentRef, {
                'savesCount': FieldValue.increment(1),
              });
            }
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint(
        'Error toggling save on comment $commentId by user $uid: $error\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<void> toggleCommentRepost({
    required String postId,
    required String commentId,
    required String uid,
    required String senderName,
    required String? senderAvatarUrl,
    required String commentText,
    required String commentAuthorUid,
    required String commentAuthorName,
    required String? commentAuthorAvatarUrl,
  }) async {
    try {
      final repostId = '${commentId}_$uid';
      final repostRef = _commentReposts.doc(repostId);
      final commentRef = _posts
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      await _firestore
          .runTransaction((transaction) async {
            final repostSnapshot = await transaction.get(repostRef);
            final commentSnapshot = await transaction.get(commentRef);
            final currentCount =
                (commentSnapshot.data()?['repostsCount'] as int?) ?? 0;

            if (repostSnapshot.exists) {
              transaction.delete(repostRef);
              transaction.update(commentRef, {
                'repostsCount': currentCount > 0 ? currentCount - 1 : 0,
              });
            } else {
              transaction.set(repostRef, {
                'id': repostId,
                'commentId': commentId,
                'postId': postId,
                'uid': uid,
                'createdAt': FieldValue.serverTimestamp(),
              });
              transaction.update(commentRef, {
                'repostsCount': currentCount + 1,
              });

              final newPostId = _uuid.v4();
              transaction.set(_posts.doc(newPostId), {
                'id': newPostId,
                'postType': 'commentRepost',
                'authorUid': uid,
                'authorName': senderName,
                'authorRole': '',
                'authorAvatarUrl': senderAvatarUrl,
                'text': commentText,
                'hashtags': [],
                'media': [],
                'likesCount': 0,
                'repostsCount': 0,
                'commentsCount': 0,
                'savesCount': 0,
                'deleted': false,
                'quotedCommentId': commentId,
                'quotedCommentText': commentText,
                'quotedCommentAuthorName': commentAuthorName,
                'quotedCommentAuthorAvatarUrl': commentAuthorAvatarUrl,
                'quotedCommentAuthorUid': commentAuthorUid,
                'quotedPostId': postId,
                'colorCode': PostColors.getRandomColor(),
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint(
        'Error toggling repost on comment $commentId by user $uid: $error\n$stackTrace',
      );
      rethrow;
    }
  }

  // Helper method to upload media file to S3
  Future<void> _uploadMediaFile({
    required File file,
    required String s3Path,
    required int index,
    required List<PostMediaModel> uploadedMedia,
  }) async {
    try {
      // Determine media type from file extension
      final extension = file.path.split('.').last.toLowerCase();
      final isVideo = [
        'mp4',
        'mov',
        'm4v',
        'webm',
        'mkv',
        'avi',
        '3gp',
      ].contains(extension);
      final mediaType = isVideo ? 'video' : 'image';
      String? thumbnailUrl;

      if (isVideo) {
        thumbnailUrl = await _generateAndUploadVideoThumbnail(
          videoFile: file,
          s3Path: s3Path,
        );
      }

      final url = await _s3.uploadFile(
        file: file,
        s3Path:
            '$s3Path.${extension.isNotEmpty ? extension : (isVideo ? 'mp4' : 'jpg')}',
      );

      uploadedMedia.add(
        PostMediaModel(
          url: url,
          type: mediaType,
          order: index,
          thumbnailUrl: thumbnailUrl,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Error uploading media file $index: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<String?> _generateAndUploadVideoThumbnail({
    required File videoFile,
    required String s3Path,
  }) async {
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 70,
        timeMs: 500,
      );

      if (bytes == null || bytes.isEmpty) return null;

      final tempFile = await _writeTempThumbnail(bytes);
      return await _s3.uploadFile(
        file: tempFile,
        s3Path: '${s3Path}_thumb.jpg',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Error generating video thumbnail for $s3Path: $error\n$stackTrace',
      );
      return null;
    }
  }

  Future<File> _writeTempThumbnail(Uint8List bytes) async {
    final file = File('${Directory.systemTemp.path}/${_uuid.v4()}_thumb.jpg');
    return file.writeAsBytes(bytes, flush: true);
  }

  // Pagination methods
  Future<(List<PostModel>, DocumentSnapshot?)> fetchLatestPostsPage({
    DocumentSnapshot? after,
    int limit = 20,
  }) async {
    try {
      var query = _posts
          .where('deleted', isNotEqualTo: true)
          .orderBy('deleted')
          .orderBy('createdAt', descending: true)
          .limit(limit + 1); // Fetch one extra to detect if there are more

      if (after != null) {
        query = query.startAfterDocument(after);
      }

      final snapshot = await query.get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;

      final posts = docs.map(PostModel.fromFirestore).toList();
      final cursor = docs.isNotEmpty ? docs.last : null;

      return (posts, cursor);
    } catch (error, stackTrace) {
      debugPrint('Error fetching latest posts page: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<(List<PostModel>, DocumentSnapshot?)> fetchPostsByAuthorPage({
    required String uid,
    DocumentSnapshot? after,
    int limit = 20,
  }) async {
    try {
      var query = _posts
          .where('authorUid', isEqualTo: uid)
          .where('deleted', isNotEqualTo: true)
          .orderBy('deleted')
          .orderBy('createdAt', descending: true)
          .limit(limit + 1);

      if (after != null) {
        query = query.startAfterDocument(after);
      }

      final snapshot = await query.get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;

      final posts = docs.map(PostModel.fromFirestore).toList();
      final cursor = docs.isNotEmpty ? docs.last : null;

      return (posts, cursor);
    } catch (error, stackTrace) {
      debugPrint('Error fetching posts by author page: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<(List<PostModel>, DocumentSnapshot?)> fetchPostsByHashtagPage({
    required String tag,
    DocumentSnapshot? after,
    int limit = 20,
  }) async {
    try {
      final normalized = tag.toLowerCase();
      var query = _posts
          .where('hashtags', arrayContains: normalized)
          .where('deleted', isNotEqualTo: true)
          .orderBy('deleted')
          .orderBy('createdAt', descending: true)
          .limit(limit + 1);

      if (after != null) {
        query = query.startAfterDocument(after);
      }

      final snapshot = await query.get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;
      final posts = docs.map(PostModel.fromFirestore).toList();
      final cursor = docs.isNotEmpty ? docs.last : null;

      return (posts, cursor);
    } catch (error, stackTrace) {
      debugPrint('Error fetching posts by hashtag page: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<(List<PostModel>, DocumentSnapshot?)> fetchSavedPostsPage({
    required String uid,
    DocumentSnapshot? after,
    int limit = 20,
  }) async {
    try {
      var query = _postSaves
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit + 1);

      if (after != null) {
        query = query.startAfterDocument(after);
      }

      final snapshot = await query.get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;

      // Fetch the actual post documents
      final postIds = docs
          .map((doc) => (doc.data()['postId'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      final posts = <PostModel>[];
      for (final postId in postIds) {
        final postDoc = await _posts.doc(postId).get();
        if (postDoc.exists) {
          try {
            posts.add(PostModel.fromFirestore(postDoc));
          } catch (e) {
            debugPrint('Error parsing saved post $postId: $e');
          }
        }
      }

      final cursor = docs.isNotEmpty ? docs.last : null;
      return (posts, cursor);
    } catch (error, stackTrace) {
      debugPrint('Error fetching saved posts page: $error\n$stackTrace');
      rethrow;
    }
  }
}
