import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:developer' as developer;

import '../../data/datasources/auth_remote_datasource.dart';
import '../../../profile/data/datasources/profile_remote_datasource.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../settings/data/datasources/settings_remote_datasource.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(firebaseAuthProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRemoteDataSourceProvider).authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).currentUser;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(
        ref.watch(authRemoteDataSourceProvider),
        ref.watch(profileRemoteDataSourceProvider),
        ref.watch(settingsRemoteDataSourceProvider),
      );
    });

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(
    this._authRemoteDataSource,
    this._profileRemoteDataSource,
    this._settingsRemoteDataSource,
  ) : super(const AsyncData(null));

  final AuthRemoteDataSource _authRemoteDataSource;
  final ProfileRemoteDataSource _profileRemoteDataSource;
  final SettingsRemoteDataSource _settingsRemoteDataSource;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final credential = await _authRemoteDataSource.registerWithEmail(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Unable to create user.');
      }

      await user.updateDisplayName(name.trim());

      await _profileRemoteDataSource.createProfileIfNotExists(
        ProfileModel.empty(
          uid: user.uid,
          email: user.email ?? email,
          name: name.trim(),
        ),
      );

      await _settingsRemoteDataSource.createSettingsIfNotExists(user.uid);

      // Mark onboarding as not yet shown (will trigger onboarding flow)
      await _settingsRemoteDataSource.updateOnboardingShown(
        user.uid,
        false,
      );

      state = const AsyncData(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      developer.log(
        'FirebaseAuthException during register: ${error.code} - ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      developer.log(
        'Error during register',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();

    try {
      final credential = await _authRemoteDataSource.loginWithEmail(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await _profileRemoteDataSource.createProfileIfNotExists(
          ProfileModel.empty(
            uid: user.uid,
            email: user.email ?? email,
            name: user.displayName ?? '',
          ),
        );
      }

      await _settingsRemoteDataSource.createSettingsIfNotExists(
        user?.uid ?? '0',
      );
      state = const AsyncData(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      developer.log(
        'FirebaseAuthException during login: ${error.code} - ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      developer.log(
        'Error during login',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();

    try {
      await _authRemoteDataSource.logout();
      state = const AsyncData(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      developer.log(
        'FirebaseAuthException during logout: ${error.code} - ${error.message}',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      developer.log(
        'Error during logout',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    }
  }
}
