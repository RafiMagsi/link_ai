import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../../profile/data/datasources/profile_remote_datasource.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

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
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(
    this._authRemoteDataSource,
    this._profileRemoteDataSource,
  ) : super(const AsyncData(null));

  final AuthRemoteDataSource _authRemoteDataSource;
  final ProfileRemoteDataSource _profileRemoteDataSource;

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

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
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

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();

    try {
      await _authRemoteDataSource.logout();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}