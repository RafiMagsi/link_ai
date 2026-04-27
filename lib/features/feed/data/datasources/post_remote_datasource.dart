import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/hashtag_utils.dart';
import '../../../profile/data/models/profile_model.dart';
import '../models/post_comment_model.dart';
import '../models/post_model.dart';

class PostRemoteDataSource {
  PostRemoteDataSource(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get _posts {
    return _firestore.collection('posts');
  }

  CollectionReference<Map<String, dynamic>> get _postLikes {
    return _firestore.collection('postLikes');
  }

  CollectionReference<Map<String, dynamic>> get _postReposts {
    return _firestore.collection('postReposts');
  }

  CollectionReference<Map<String, dynamic>> get _postSaves {
    return _firestore.collection('postSaves');
  }

  Stream<List<PostModel>> watchLatestPosts({int limit = 50}) {
    return _posts
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
        return PostModel.fromFirestore(snapshot);
      } catch (error, stackTrace) {
        debugPrint('Error parsing post $postId: $error\n$stackTrace');
        return null;
      }
    });
  }

  Stream<List<PostCommentModel>> watchComments(String postId) {
    return _posts.doc(postId).collection('comments').snapshots().distinct().map((
      snapshot,
    ) {
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
    });
  }

  Future<void> createPost({
    required ProfileModel profile,
    required String text,
    required List<File> imageFiles,
  }) async {
    try {
      final postId = _posts.doc().id;

      final uploadedMedia = <PostMediaModel>[];
      final hashtags = HashtagUtils.extractNormalized(text);

      for (var i = 0; i < imageFiles.length; i++) {
        try {
          final file = imageFiles[i];
          final fileName = '${_uuid.v4()}.jpg';

          final ref = _storage.ref().child(
            'postMedia/${profile.uid}/$postId/$fileName',
          );

          await ref
              .putFile(
                file,
                SettableMetadata(
                  contentType: 'image/jpeg',
                  customMetadata: {'uid': profile.uid, 'postId': postId},
                ),
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () =>
                    throw TimeoutException('Image upload timed out'),
              );

          final url = await ref.getDownloadURL().timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Image URL retrieval timed out'),
          );

          uploadedMedia.add(PostMediaModel(url: url, type: 'image', order: i));
        } on FirebaseException catch (e) {
          debugPrint(
            'Firebase error uploading image $i: ${e.code} - ${e.message}',
          );
          if (e.code == 'storage/quota-exceeded') {
            throw StorageQuotaError(
              'Storage quota exceeded. Please delete some posts and try again.',
            );
          } else if (e.code == 'storage/unauthorized') {
            throw Exception('You do not have permission to upload images.');
          }
          rethrow;
        } on TimeoutException catch (e) {
          debugPrint('Timeout uploading image $i: $e');
          throw Exception(
            'Image upload took too long. Please check your connection and try again.',
          );
        } catch (error, stackTrace) {
          debugPrint('Error uploading image $i: $error\n$stackTrace');
          rethrow;
        }
      }

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
    return _posts.where('hashtags', arrayContains: normalized).snapshots().distinct().map((
      snapshot,
    ) {
      final posts = snapshot.docs.map(PostModel.fromFirestore).toList();
      // Client-side sorting as fallback
      posts.sort(
        (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
          a.createdAt ?? DateTime.now(),
        ),
      );
      return posts.take(limit).toList();
    });
  }

  Stream<List<PostModel>> watchPostsByAuthor(String uid, {int limit = 50}) {
    return _posts
        .where('authorUid', isEqualTo: uid)
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

  Stream<List<PostCommentModel>> watchCommentsByAuthor(
    String uid, {
    int limit = 50,
  }) {
    debugPrint('🔴 [INIT] watchCommentsByAuthor for $uid');

    return _firestore
        .collectionGroup('comments')
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .transform(
          StreamTransformer.fromHandlers(
            handleData: (QuerySnapshot<Map<String, dynamic>> snapshot, sink) {
              final docIds =
                  snapshot.docs.map((d) => d.id).take(2).join(',');
              debugPrint(
                '🔴 [SNAPSHOT] ${snapshot.docs.length} docs [$docIds...]',
              );
              sink.add(snapshot);
            },
            handleError: (error, _, sink) {
              debugPrint('🔴 [ERROR] $error');
              // Don't propagate permission errors - let them be handled at UI level
              if (!error.toString().contains('permission-denied')) {
                sink.addError(error);
              } else {
                debugPrint('🔴 [PERMISSION_DENIED] Suppressed - deploy rules');
              }
            },
          ),
        )
        .distinct()
        .map((snapshot) {
          try {
            final snapshotDocs = (snapshot as QuerySnapshot<Map<String, dynamic>>).docs;
            final comments = snapshotDocs
                .map(PostCommentModel.fromFirestore)
                .toList();
            debugPrint('🟢 [MAPPED] ${comments.length} comments');
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
            'reason': reason,
            'reporterUid': reporterUid,
            'createdAt': FieldValue.serverTimestamp(),
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
      final doc = await _postReposts
          .doc('${postId}_$uid')
          .get()
          .timeout(const Duration(seconds: 10));
      return doc.exists;
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
    try {
      final repostId = '${postId}_$uid';
      final repostRef = _postReposts.doc(repostId);
      final postRef = _posts.doc(postId);

      await _firestore
          .runTransaction((transaction) async {
            final repostSnapshot = await transaction.get(repostRef);

            if (repostSnapshot.exists) {
              transaction.delete(repostRef);
              transaction.update(postRef, {
                'repostsCount': FieldValue.increment(-1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              transaction.set(repostRef, {
                'id': repostId,
                'postId': postId,
                'uid': uid,
                'createdAt': FieldValue.serverTimestamp(),
              });
              transaction.update(postRef, {
                'repostsCount': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          })
          .timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      debugPrint(
        'Error toggling repost on post $postId by user $uid: $error\n$stackTrace',
      );
      rethrow;
    }
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

  Future<void> addComment({
    required ProfileModel profile,
    required String postId,
    required String text,
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

  Future<List<PostModel>> searchPosts(String query, {int limit = 20}) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _posts
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
}
