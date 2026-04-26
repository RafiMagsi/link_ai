import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

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
        .map((snapshot) => snapshot.docs.map(PostModel.fromFirestore).toList());
  }

  Stream<List<PostCommentModel>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(PostCommentModel.fromFirestore).toList(),
        );
  }

  Future<void> createPost({
    required ProfileModel profile,
    required String text,
    required List<File> imageFiles,
  }) async {
    final postId = _posts.doc().id;

    final uploadedMedia = <PostMediaModel>[];

    for (var i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final fileName = '${_uuid.v4()}.jpg';

      final ref = _storage.ref().child(
        'postMedia/${profile.uid}/$postId/$fileName',
      );

      await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uid': profile.uid, 'postId': postId},
        ),
      );

      final url = await ref.getDownloadURL();

      uploadedMedia.add(PostMediaModel(url: url, type: 'image', order: i));
    }

    final post = PostModel(
      id: postId,
      authorUid: profile.uid,
      authorName: profile.name,
      authorRole: profile.role,
      authorAvatarUrl: profile.avatarUrl,
      text: text,
      media: uploadedMedia,
      likesCount: 0,
      repostsCount: 0,
      commentsCount: 0,
      savesCount: 0,
      createdAt: null,
      updatedAt: null,
    );

    await _posts.doc(postId).set(post.toCreateMap());
  }

  Future<bool> hasLiked({required String postId, required String uid}) async {
    final doc = await _postLikes.doc('${postId}_$uid').get();
    return doc.exists;
  }

  Future<bool> hasReposted({
    required String postId,
    required String uid,
  }) async {
    final doc = await _postReposts.doc('${postId}_$uid').get();
    return doc.exists;
  }

  Future<bool> hasSaved({required String postId, required String uid}) async {
    final doc = await _postSaves.doc('${postId}_$uid').get();
    return doc.exists;
  }

  Future<void> toggleLike({required String postId, required String uid}) async {
    final likeId = '${postId}_$uid';
    final likeRef = _postLikes.doc(likeId);
    final postRef = _posts.doc(postId);

    await _firestore.runTransaction((transaction) async {
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
    });
  }

  Future<void> toggleRepost({
    required String postId,
    required String uid,
  }) async {
    final repostId = '${postId}_$uid';
    final repostRef = _postReposts.doc(repostId);
    final postRef = _posts.doc(postId);

    await _firestore.runTransaction((transaction) async {
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
    });
  }

  Future<void> toggleSave({required String postId, required String uid}) async {
    final saveId = '${postId}_$uid';
    final saveRef = _postSaves.doc(saveId);
    final postRef = _posts.doc(postId);

    await _firestore.runTransaction((transaction) async {
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
    });
  }

  Future<void> addComment({
    required ProfileModel profile,
    required String postId,
    required String text,
  }) async {
    final commentRef = _posts.doc(postId).collection('comments').doc();

    final comment = PostCommentModel(
      id: commentRef.id,
      postId: postId,
      authorUid: profile.uid,
      authorName: profile.name,
      authorAvatarUrl: profile.avatarUrl,
      text: text,
      createdAt: null,
    );

    final postRef = _posts.doc(postId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, comment.toCreateMap());
      transaction.update(postRef, {
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
