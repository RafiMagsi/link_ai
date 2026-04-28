import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;
import 'dart:async';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/models/profile_model.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  return ProfileRemoteDataSource(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

final myProfileProvider = StreamProvider<ProfileModel?>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const Stream.empty();
  }

  return ref.watch(profileRemoteDataSourceProvider).watchProfile(user.uid);
});

final profileByUidProvider = StreamProvider.family<ProfileModel?, String>((
  ref,
  uid,
) {
  return ref.watch(profileRemoteDataSourceProvider).watchProfile(uid);
});

final publicProfilesProvider = FutureProvider<List<ProfileModel>>((ref) {
  return ref.watch(profileRemoteDataSourceProvider).getPublicProfiles();
});

final profilesByIdsProvider =
    FutureProvider.family<List<ProfileModel>, List<String>>((ref, uids) {
      return ref.watch(profileRemoteDataSourceProvider).getProfilesByIds(uids);
    });

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
      return ProfileController(ref.watch(profileRemoteDataSourceProvider));
    });

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController(this._profileRemoteDataSource)
    : super(const AsyncData(null));

  final ProfileRemoteDataSource _profileRemoteDataSource;

  Future<void> updateProfile(ProfileModel profile) async {
    state = const AsyncLoading();

    try {
      await _profileRemoteDataSource.updateProfile(profile);
      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Timeout updating profile for UID: ${profile.uid}',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'Firebase error updating profile: ${error.code} - ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      developer.log(
        'Error updating profile for UID: ${profile.uid}',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    }
  }

  Future<String?> uploadAvatar({
    required String uid,
    required File file,
  }) async {
    state = const AsyncLoading();

    try {
      final avatarUrl = await _profileRemoteDataSource.uploadAvatar(
        uid: uid,
        file: file,
      );

      state = const AsyncData(null);
      return avatarUrl;
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Timeout uploading avatar for UID: $uid',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      return null;
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'Firebase Storage error uploading avatar: ${error.code} - ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      return null;
    } catch (error, stackTrace) {
      developer.log(
        'Error uploading avatar for UID: $uid',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}
