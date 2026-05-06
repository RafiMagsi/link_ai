import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/connection_model.dart';

class ConnectRemoteDataSource {
  ConnectRemoteDataSource(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _connections {
    return _firestore.collection('connections');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchConnectionDoc(
    String connectionId,
  ) {
    return _connections.doc(connectionId).snapshots();
  }

  Stream<List<ConnectionModel>> watchConnections(String uid) {
    return _connections
        .where('userUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs.map(ConnectionModel.fromFirestore).toList();
          } catch (error, stackTrace) {
            debugPrint(
              'Error parsing connections for $uid: $error\n$stackTrace',
            );
            return [];
          }
        });
  }

  Stream<List<ConnectionModel>> watchFollowers(String uid) {
    return _connections.where('connectedUid', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      try {
        final items = snapshot.docs.map(ConnectionModel.fromFirestore).toList();
        items.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(0);
          final bTime = b.createdAt ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
        return items;
      } catch (error, stackTrace) {
        debugPrint('Error parsing followers for $uid: $error\n$stackTrace');
        return [];
      }
    });
  }

  Future<void> followUser({
    required String currentUid,
    required String targetUid,
  }) async {
    final connectionId = '${currentUid}_$targetUid';
    await _connections.doc(connectionId).set({
      'id': connectionId,
      'userUid': currentUid,
      'connectedUid': targetUid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unfollowUser({
    required String currentUid,
    required String targetUid,
  }) async {
    final connectionId = '${currentUid}_$targetUid';
    await _connections.doc(connectionId).delete();
  }

  Future<void> sendPing({required String targetUid}) async {
    try {
      final callable = _functions.httpsCallable('sendPing');
      await callable
          .call({'targetUid': targetUid})
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw TimeoutException('Ping request timed out'),
          );
    } on FirebaseFunctionsException catch (e) {
      _handleCloudFunctionError(e, 'sendPing');
    } on TimeoutException catch (e) {
      debugPrint('Timeout in sendPing: $e');
      throw Exception(
        'Request timed out. Please check your connection and try again.',
      );
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
    try {
      final connection = await _connections
          .doc(connectionId)
          .get()
          .timeout(const Duration(seconds: 4));

      return connection.exists
          ? ConnectRelationshipStatus.connected
          : ConnectRelationshipStatus.none;
    } on TimeoutException {
      // Avoid an infinite "Checking..." state on poor networks/offline.
      return ConnectRelationshipStatus.none;
    }
  }

  /// Handles FirebaseFunctionsException with proper error mapping
  Never _handleCloudFunctionError(
    FirebaseFunctionsException error,
    String functionName,
  ) {
    debugPrint(
      'Cloud Function error in $functionName: ${error.code} - ${error.message}',
    );

    switch (error.code) {
      case 'unauthenticated':
        throw Exception('Authentication failed. Please log in again.');
      case 'permission-denied':
        throw Exception('You do not have permission to perform this action.');
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
        throw Exception('Operation was cancelled. Please try again.');
      case 'internal':
        throw Exception('Server error occurred. Please try again later.');
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
  connected,
}
