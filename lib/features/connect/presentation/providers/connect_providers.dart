import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/connect_remote_datasource.dart';
import '../../data/models/connect_request_model.dart';
import '../../data/models/connection_model.dart';

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(
    app: Firebase.app(),
  );
});

final connectRemoteDataSourceProvider = Provider<ConnectRemoteDataSource>((ref) {
  return ConnectRemoteDataSource(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseFunctionsProvider),
  );
});

final incomingConnectRequestsProvider =
    StreamProvider<List<ConnectRequestModel>>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const Stream.empty();
  }

  return ref
      .watch(connectRemoteDataSourceProvider)
      .watchIncomingRequests(user.uid);
});

final outgoingConnectRequestsProvider =
    StreamProvider<List<ConnectRequestModel>>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const Stream.empty();
  }

  return ref
      .watch(connectRemoteDataSourceProvider)
      .watchOutgoingRequests(user.uid);
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

  return ref.watch(connectRemoteDataSourceProvider).getRelationshipStatus(
        currentUid: user.uid,
        targetUid: targetUid,
      );
});

final connectControllerProvider =
    StateNotifierProvider<ConnectController, AsyncValue<void>>((ref) {
  return ConnectController(
    ref,
    ref.watch(connectRemoteDataSourceProvider),
  );
});

class ConnectController extends StateNotifier<AsyncValue<void>> {
  ConnectController(
    this._ref,
    this._connectRemoteDataSource,
  ) : super(const AsyncData(null));

  final Ref _ref;
  final ConnectRemoteDataSource _connectRemoteDataSource;

  Future<void> sendRequest({
    required String receiverUid,
    required String message,
  }) async {
    state = const AsyncLoading();

    try {
      await _connectRemoteDataSource.sendConnectRequest(
        receiverUid: receiverUid,
        message: message,
      );

      _ref.invalidate(relationshipStatusProvider(receiverUid));
      _ref.invalidate(outgoingConnectRequestsProvider);

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> acceptRequest({
    required String requestId,
    required String senderUid,
  }) async {
    state = const AsyncLoading();

    try {
      await _connectRemoteDataSource.acceptConnectRequest(requestId);

      _ref.invalidate(incomingConnectRequestsProvider);
      _ref.invalidate(myConnectionsProvider);
      _ref.invalidate(relationshipStatusProvider(senderUid));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> declineRequest({
    required String requestId,
    required String senderUid,
  }) async {
    state = const AsyncLoading();

    try {
      await _connectRemoteDataSource.declineConnectRequest(requestId);

      _ref.invalidate(incomingConnectRequestsProvider);
      _ref.invalidate(relationshipStatusProvider(senderUid));

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}