import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
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
    try {
      final callable = _functions.httpsCallable('sendConnectRequest');
      await callable.call({
        'receiverUid': receiverUid,
        'message': message,
      }).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Connect request timed out'),
      );
    } on FirebaseFunctionsException catch (e) {
      _handleCloudFunctionError(e, 'sendConnectRequest');
    } on TimeoutException catch (e) {
      debugPrint('Timeout in sendConnectRequest: $e');
      throw Exception('Request timed out. Please check your connection and try again.');
    } catch (e) {
      debugPrint('Error sending connect request: $e');
      rethrow;
    }
  }

  Future<void> acceptConnectRequest(String requestId) async {
    try {
      final callable = _functions.httpsCallable('respondConnectRequest');
      await callable.call({
        'requestId': requestId,
        'action': 'accept',
      }).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Accept request timed out'),
      );
    } on FirebaseFunctionsException catch (e) {
      _handleCloudFunctionError(e, 'acceptConnectRequest');
    } on TimeoutException catch (e) {
      debugPrint('Timeout in acceptConnectRequest: $e');
      throw Exception('Request timed out. Please check your connection and try again.');
    } catch (e) {
      debugPrint('Error accepting connect request: $e');
      rethrow;
    }
  }

  Future<void> declineConnectRequest(String requestId) async {
    try {
      final callable = _functions.httpsCallable('respondConnectRequest');
      await callable.call({
        'requestId': requestId,
        'action': 'decline',
      }).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Decline request timed out'),
      );
    } on FirebaseFunctionsException catch (e) {
      _handleCloudFunctionError(e, 'declineConnectRequest');
    } on TimeoutException catch (e) {
      debugPrint('Timeout in declineConnectRequest: $e');
      throw Exception('Request timed out. Please check your connection and try again.');
    } catch (e) {
      debugPrint('Error declining connect request: $e');
      rethrow;
    }
  }

  Stream<List<ConnectRequestModel>> watchIncomingRequests(String uid) {
    return _connectRequests
        .where('receiverUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) => sink.close(),
        )
        .map((snapshot) {
          try {
            return snapshot.docs.map(ConnectRequestModel.fromFirestore).toList();
          } catch (error, stackTrace) {
            debugPrint('Error parsing incoming requests for $uid: $error\n$stackTrace');
            return [];
          }
        });
  }

  Stream<List<ConnectRequestModel>> watchOutgoingRequests(String uid) {
    return _connectRequests
        .where('senderUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) => sink.close(),
        )
        .map((snapshot) {
          try {
            return snapshot.docs.map(ConnectRequestModel.fromFirestore).toList();
          } catch (error, stackTrace) {
            debugPrint('Error parsing outgoing requests for $uid: $error\n$stackTrace');
            return [];
          }
        });
  }

  Stream<List<ConnectionModel>> watchConnections(String uid) {
    return _connections
        .where('userUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) => sink.close(),
        )
        .map((snapshot) {
          try {
            return snapshot.docs.map(ConnectionModel.fromFirestore).toList();
          } catch (error, stackTrace) {
            debugPrint('Error parsing connections for $uid: $error\n$stackTrace');
            return [];
          }
        });
  }

  Future<void> sendPing({required String targetUid}) async {
    try {
      final callable = _functions.httpsCallable('sendPing');
      await callable.call({
        'targetUid': targetUid,
      }).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Ping request timed out'),
      );
    } on FirebaseFunctionsException catch (e) {
      _handleCloudFunctionError(e, 'sendPing');
    } on TimeoutException catch (e) {
      debugPrint('Timeout in sendPing: $e');
      throw Exception('Request timed out. Please check your connection and try again.');
    } catch (e) {
      debugPrint('Error sending ping: $e');
      rethrow;
    }
  }

  Future<ConnectRelationshipStatus> getRelationshipStatus({
    required String currentUid,
    required String targetUid,
  }) async {
    final connectionId = '${currentUid}_$targetUid';
    final outgoingRequestId = '${currentUid}_$targetUid';
    final incomingRequestId = '${targetUid}_$currentUid';

    List<DocumentSnapshot<Map<String, dynamic>>> results;
    try {
      results = await Future.wait([
        _connections.doc(connectionId).get(),
        _connectRequests.doc(outgoingRequestId).get(),
        _connectRequests.doc(incomingRequestId).get(),
      ]).timeout(const Duration(seconds: 4));
    } on TimeoutException {
      // Avoid an infinite "Checking..." state on poor networks/offline.
      return ConnectRelationshipStatus.none;
    }

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

  /// Handles FirebaseFunctionsException with proper error mapping
  Never _handleCloudFunctionError(
    FirebaseFunctionsException error,
    String functionName,
  ) {
    debugPrint('Cloud Function error in $functionName: ${error.code} - ${error.message}');

    switch (error.code) {
      case 'unauthenticated':
        throw Exception(
          'Authentication failed. Please log in again.',
        );
      case 'permission-denied':
        throw Exception(
          'You do not have permission to perform this action.',
        );
      case 'resource-exhausted':
        throw Exception(
          'Too many requests. Please wait a moment and try again.',
        );
      case 'not-found':
        throw Exception(
          'The requested resource was not found. The user may have been deleted.',
        );
      case 'invalid-argument':
        throw Exception(
          'Invalid request data. Please check your input and try again.',
        );
      case 'failed-precondition':
        throw Exception(
          'Cannot perform this action at the moment. Please try again.',
        );
      case 'aborted':
        throw Exception(
          'Operation was cancelled. Please try again.',
        );
      case 'internal':
        throw Exception(
          'Server error occurred. Please try again later.',
        );
      case 'deadline-exceeded':
        throw Exception(
          'Request timed out. Please check your connection and try again.',
        );
      case 'unavailable':
        throw Exception(
          'Service is temporarily unavailable. Please try again later.',
        );
      default:
        throw Exception(
          'An error occurred while processing your request. Please try again.',
        );
    }
  }
}

enum ConnectRelationshipStatus {
  none,
  outgoingPending,
  incomingPending,
  connected,
}
