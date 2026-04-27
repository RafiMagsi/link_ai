import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'dart:async';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/models/user_settings_model.dart';

final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource>((
  ref,
) {
  return SettingsRemoteDataSource(ref.watch(firebaseFirestoreProvider));
});

final userSettingsProvider = StreamProvider<UserSettingsModel>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const Stream.empty();
  }

  return ref.watch(settingsRemoteDataSourceProvider).watchSettings(user.uid);
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<void>>((ref) {
      return SettingsController(ref.watch(settingsRemoteDataSourceProvider));
    });

class SettingsController extends StateNotifier<AsyncValue<void>> {
  SettingsController(this._settingsRemoteDataSource)
    : super(const AsyncData(null));

  final SettingsRemoteDataSource _settingsRemoteDataSource;

  Future<void> createSettingsIfNotExists(String uid) async {
    state = const AsyncLoading();

    try {
      await _settingsRemoteDataSource.createSettingsIfNotExists(uid);
      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Timeout creating settings for UID: $uid',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'Firebase error creating settings: ${error.code} - ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      developer.log(
        'Error creating settings for UID: $uid',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> updateSettings(UserSettingsModel settings) async {
    state = const AsyncLoading();

    try {
      await _settingsRemoteDataSource.updateSettings(settings);
      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Timeout updating settings for UID: ${settings.uid}',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'Firebase error updating settings: ${error.code} - ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      developer.log(
        'Error updating settings for UID: ${settings.uid}',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    }
  }
}
