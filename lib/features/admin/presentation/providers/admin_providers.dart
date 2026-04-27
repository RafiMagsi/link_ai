import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/app_config_remote_datasource.dart';
import '../../data/models/app_config_model.dart';

final appConfigRemoteDataSourceProvider = Provider<AppConfigRemoteDataSource>((
  ref,
) {
  return AppConfigRemoteDataSource(ref.watch(firebaseFirestoreProvider));
});

final appConfigProvider = StreamProvider<AppConfigModel>((ref) {
  return ref.watch(appConfigRemoteDataSourceProvider).watchGlobalConfig();
});

final adminStatusProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) return false;

  final idTokenResult = await user.getIdTokenResult();

  return idTokenResult.claims?['admin'] == true;
});

final adminControllerProvider =
    StateNotifierProvider<AdminController, AsyncValue<void>>((ref) {
      return AdminController(
        ref.watch(appConfigRemoteDataSourceProvider),
        ref.watch(firebaseAuthProvider),
      );
    });

class AdminController extends StateNotifier<AsyncValue<void>> {
  AdminController(this._appConfigRemoteDataSource, this._firebaseAuth)
    : super(const AsyncData(null));

  final AppConfigRemoteDataSource _appConfigRemoteDataSource;
  final FirebaseAuth _firebaseAuth;

  Future<void> createDefaultConfigIfMissing() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      state = AsyncError(
        Exception('User is not logged in.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      await _appConfigRemoteDataSource.createDefaultIfMissing(
        updatedBy: user.uid,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Config initialization timed out'),
      );
      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
     debugPrint('Timeout creating default config: $error');
      state = AsyncError(
        Exception('Configuration initialization took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
     debugPrint('Error creating default config: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> updateConfig(AppConfigModel config) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      state = AsyncError(
        Exception('User is not logged in.'),
        StackTrace.current,
      );
      return;
    }

    // Check admin status
    try {
      final idTokenResult = await user.getIdTokenResult();
      final isAdmin = idTokenResult.claims?['admin'] == true;

      if (!isAdmin) {
        state = AsyncError(
          Exception('Only administrators can update app configuration.'),
          StackTrace.current,
        );
        return;
      }
    } catch (e) {
     debugPrint('Error checking admin status: $e');
      state = AsyncError(
        Exception('Unable to verify admin privileges. Please try again.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      await _appConfigRemoteDataSource.updateGlobalConfig(
        config: config,
        updatedBy: user.uid,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Config update timed out'),
      );
      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
     debugPrint('Timeout updating config: $error');
      state = AsyncError(
        Exception('Configuration update took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
     debugPrint('Error updating config: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refreshAdminClaim() async {
    state = const AsyncLoading();

    try {
      await _firebaseAuth.currentUser
          ?.getIdTokenResult(true)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Token refresh timed out'),
          );
      state = const AsyncData(null);
    } on TimeoutException catch (error, stackTrace) {
     debugPrint('Timeout refreshing admin claim: $error');
      state = AsyncError(
        Exception('Token refresh took too long. Please try again.'),
        stackTrace,
      );
    } catch (error, stackTrace) {
     debugPrint('Error refreshing admin claim: $error\n$stackTrace');
      state = AsyncError(error, stackTrace);
    }
  }
}
