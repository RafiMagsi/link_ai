import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;
import 'dart:async';
import '../models/profile_model.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _profiles {
    return _firestore.collection('profiles');
  }

  Future<void> createProfileIfNotExists(ProfileModel profile) async {
    try {
      final docRef = _profiles.doc(profile.uid);
      final snapshot = await docRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to fetch profile document'),
      );

      if (snapshot.exists) return;

      await docRef.set(profile.toCreateMap()).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to create profile'),
      );
      developer.log('Profile created successfully for UID: ${profile.uid}');
    } on TimeoutException catch (e, stackTrace) {
      developer.log(
        'Timeout creating profile: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error creating profile',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ProfileModel?> getProfile(String uid) async {
    try {
      final snapshot = await _profiles.doc(uid).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to fetch profile'),
      );

      if (!snapshot.exists) return null;

      return ProfileModel.fromFirestore(snapshot);
    } on TimeoutException catch (e, stackTrace) {
      developer.log(
        'Timeout fetching profile for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching profile for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Stream<ProfileModel?> watchProfile(String uid) {
    return _profiles.doc(uid).snapshots().map((snapshot) {
      try {
        if (!snapshot.exists) return null;
        return ProfileModel.fromFirestore(snapshot);
      } catch (e, stackTrace) {
        developer.log(
          'Error parsing profile snapshot for UID: $uid',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    });
  }

  Future<void> updateProfile(ProfileModel profile) async {
    try {
      await _profiles.doc(profile.uid).update(profile.toUpdateMap()).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to update profile'),
      );
      developer.log('Profile updated successfully for UID: ${profile.uid}');
    } on TimeoutException catch (e, stackTrace) {
      developer.log(
        'Timeout updating profile for UID: ${profile.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error updating profile for UID: ${profile.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<ProfileModel>> getPublicProfiles({int limit = 20}) async {
    try {
      final snapshot = await _profiles
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Failed to fetch public profiles'),
          );

      return snapshot.docs.map(ProfileModel.fromFirestore).toList();
    } on TimeoutException catch (e, stackTrace) {
      developer.log(
        'Timeout fetching public profiles',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching public profiles',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<String> uploadAvatar({required String uid, required File file}) async {
    try {
      final ref = _storage.ref().child('avatars/$uid/profile.jpg');

      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg', customMetadata: {'uid': uid}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Failed to upload avatar'),
      );

      final downloadUrl = await ref.getDownloadURL().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to get avatar download URL'),
      );

      developer.log('Avatar uploaded successfully for UID: $uid');
      return downloadUrl;
    } on FirebaseException catch (e, stackTrace) {
      developer.log(
        'Firebase Storage error uploading avatar: ${e.code} - ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } on TimeoutException catch (e, stackTrace) {
      developer.log(
        'Timeout uploading avatar for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error uploading avatar for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<ProfileModel>> searchProfiles(String query, {int limit = 20}) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final queryLower = query.toLowerCase();
      final snapshot = await _profiles.limit(limit + 50).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to search profiles'),
      );

      final results = snapshot.docs
          .map(ProfileModel.fromFirestore)
          .where((profile) {
            final nameMatch = profile.name.toLowerCase().contains(queryLower);
            final roleMatch = profile.role.toLowerCase().contains(queryLower);
            final skillsMatch = profile.skills.any(
              (skill) => skill.toLowerCase().contains(queryLower),
            );

            return nameMatch || roleMatch || skillsMatch;
          })
          .take(limit)
          .toList();

      return results;
    } on TimeoutException catch (e, stackTrace) {
      developer.log(
        'Timeout searching profiles for query: $query',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error searching profiles for query: $query',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
