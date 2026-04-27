import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/connect_request_model.dart';
import '../models/connection_model.dart';

class ConnectRemoteDataSource {
  ConnectRemoteDataSource(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _connectRequests {
    return _firestore.collection('connectRequests');
  }

  CollectionReference<Map<String, dynamic>> get _connections {
    return _firestore.collection('connections');
  }

  Future<void> sendConnectRequest({
    required String receiverUid,
    required String message,
  }) async {
    final callable = _functions.httpsCallable('sendConnectRequest');

    await callable.call({'receiverUid': receiverUid, 'message': message});
  }

  Future<void> acceptConnectRequest(String requestId) async {
    final callable = _functions.httpsCallable('respondConnectRequest');

    await callable.call({'requestId': requestId, 'action': 'accept'});
  }

  Future<void> declineConnectRequest(String requestId) async {
    final callable = _functions.httpsCallable('respondConnectRequest');

    await callable.call({'requestId': requestId, 'action': 'decline'});
  }

  Stream<List<ConnectRequestModel>> watchIncomingRequests(String uid) {
    return _connectRequests
        .where('receiverUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ConnectRequestModel.fromFirestore).toList(),
        );
  }

  Stream<List<ConnectRequestModel>> watchOutgoingRequests(String uid) {
    return _connectRequests
        .where('senderUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ConnectRequestModel.fromFirestore).toList(),
        );
  }

  Stream<List<ConnectionModel>> watchConnections(String uid) {
    return _connections
        .where('userUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ConnectionModel.fromFirestore).toList(),
        );
  }

  Future<ConnectRelationshipStatus> getRelationshipStatus({
    required String currentUid,
    required String targetUid,
  }) async {
    final connectionId = '${currentUid}_$targetUid';
    final outgoingRequestId = '${currentUid}_$targetUid';
    final incomingRequestId = '${targetUid}_$currentUid';

    final results = await Future.wait([
      _connections.doc(connectionId).get(),
      _connectRequests.doc(outgoingRequestId).get(),
      _connectRequests.doc(incomingRequestId).get(),
    ]);

    final connection = results[0];
    final outgoing = results[1];
    final incoming = results[2];

    if (connection.exists) {
      return ConnectRelationshipStatus.connected;
    }

    if (outgoing.exists) {
      final status = outgoing.data()?['status'] as String?;

      if (status == 'pending') {
        return ConnectRelationshipStatus.outgoingPending;
      }

      if (status == 'accepted') {
        return ConnectRelationshipStatus.connected;
      }
    }

    if (incoming.exists) {
      final status = incoming.data()?['status'] as String?;

      if (status == 'pending') {
        return ConnectRelationshipStatus.incomingPending;
      }

      if (status == 'accepted') {
        return ConnectRelationshipStatus.connected;
      }
    }

    return ConnectRelationshipStatus.none;
  }
}

enum ConnectRelationshipStatus {
  none,
  outgoingPending,
  incomingPending,
  connected,
}
