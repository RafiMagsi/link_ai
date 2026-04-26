import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/app_config_remote_datasource.dart';
import '../../data/models/app_config_model.dart';

final appConfigRemoteDataSourceProvider =
    Provider<AppConfigRemoteDataSource>((ref) {
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
  AdminController(
    this._appConfigRemoteDataSource,
    this._firebaseAuth,
  ) : super(const AsyncData(null));

  final AppConfigRemoteDataSource _appConfigRemoteDataSource;
  final FirebaseAuth _firebaseAuth;

  Future<void> createDefaultConfigIfMissing() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) return;

    state = const AsyncLoading();

    try {
      await _appConfigRemoteDataSource.createDefaultIfMissing(
        updatedBy: user.uid,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
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

    state = const AsyncLoading();

    try {
      await _appConfigRemoteDataSource.updateGlobalConfig(
        config: config,
        updatedBy: user.uid,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refreshAdminClaim() async {
    state = const AsyncLoading();

    try {
      await _firebaseAuth.currentUser?.getIdTokenResult(true);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}