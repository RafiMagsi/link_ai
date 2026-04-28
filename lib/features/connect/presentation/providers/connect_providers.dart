import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/connect_remote_datasource.dart';
import '../../data/models/connection_model.dart';

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(app: Firebase.app());
});

final connectRemoteDataSourceProvider = Provider<ConnectRemoteDataSource>((
  ref,
) {
  return ConnectRemoteDataSource(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseFunctionsProvider),
  );
});

final myConnectionsProvider = StreamProvider<List<ConnectionModel>>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const Stream.empty();
  }

  return ref.watch(connectRemoteDataSourceProvider).watchConnections(user.uid);
});

final relationshipStatusProvider =
    FutureProvider.family<ConnectRelationshipStatus, String>((ref, targetUid) {
      final user = ref.watch(currentUserProvider);

      if (user == null) {
        return Future.value(ConnectRelationshipStatus.none);
      }

      return ref
          .watch(connectRemoteDataSourceProvider)
          .getRelationshipStatus(currentUid: user.uid, targetUid: targetUid);
    });

/// Instant follow status: watch the single connection doc instead of doing
/// multiple reads + showing a prolonged "Checking..." state.
final relationshipStatusStreamProvider =
    StreamProvider.family<ConnectRelationshipStatus, String>((ref, targetUid) {
      final user = ref.watch(currentUserProvider);
      if (user == null) return const Stream.empty();

      final connectionId = '${user.uid}_$targetUid';

      return ref
          .watch(connectRemoteDataSourceProvider)
          .watchConnectionDoc(connectionId)
          .map(
            (doc) => doc.exists
                ? ConnectRelationshipStatus.connected
                : ConnectRelationshipStatus.none,
          );
    });

final connectControllerProvider =
    StateNotifierProvider<ConnectController, AsyncValue<void>>((ref) {
      return ConnectController(ref, ref.watch(connectRemoteDataSourceProvider));
    });

class ConnectController extends StateNotifier<AsyncValue<void>> {
  ConnectController(this._ref, this._connectRemoteDataSource)
    : super(const AsyncData(null));

  final Ref _ref;
  final ConnectRemoteDataSource _connectRemoteDataSource;

  Future<void> pingUser(String targetUid) async {
    state = const AsyncLoading();

    try {
      await _connectRemoteDataSource.sendPing(targetUid: targetUid);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> followUser(String targetUid) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();

    try {
      await _connectRemoteDataSource.followUser(
        currentUid: user.uid,
        targetUid: targetUid,
      );

      _ref.invalidate(myConnectionsProvider);
      _ref.invalidate(relationshipStatusProvider(targetUid));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> unfollowUser(String targetUid) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();

    try {
      await _connectRemoteDataSource.unfollowUser(
        currentUid: user.uid,
        targetUid: targetUid,
      );

      _ref.invalidate(myConnectionsProvider);
      _ref.invalidate(relationshipStatusProvider(targetUid));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
