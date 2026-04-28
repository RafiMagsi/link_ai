import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/moderation_report_model.dart';

class ModerationRemoteDataSource {
  ModerationRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reports {
    return _firestore.collection('reports');
  }

  CollectionReference<Map<String, dynamic>> get _userBlocks {
    return _firestore.collection('userBlocks');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchBlockDoc(String blockId) {
    return _userBlocks.doc(blockId).snapshots();
  }

  Stream<List<ModerationReportModel>> watchReports({bool openOnly = true}) {
    Query<Map<String, dynamic>> query = _reports.orderBy(
      'createdAt',
      descending: true,
    );

    if (openOnly) {
      query = query.where('status', isEqualTo: 'open');
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(ModerationReportModel.fromFirestore)
          .toList(growable: false);
    });
  }

  Future<void> reportUser({
    required String reporterUid,
    required String targetUid,
    required String reason,
  }) async {
    await _reports
        .add({
          'type': 'user',
          'reporterUid': reporterUid,
          'targetUid': targetUid,
          'reason': reason,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
          'resolvedAt': null,
          'resolvedBy': null,
        })
        .timeout(const Duration(seconds: 15));
  }

  Future<void> blockUser({
    required String blockerUid,
    required String blockedUid,
  }) async {
    final blockId = '${blockerUid}_$blockedUid';
    await _userBlocks
        .doc(blockId)
        .set({
          'id': blockId,
          'blockerUid': blockerUid,
          'blockedUid': blockedUid,
          'createdAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 10));
  }

  Future<void> unblockUser({
    required String blockerUid,
    required String blockedUid,
  }) async {
    final blockId = '${blockerUid}_$blockedUid';
    await _userBlocks
        .doc(blockId)
        .delete()
        .timeout(const Duration(seconds: 10));
  }

  Future<void> resolveReport({
    required String reportId,
    required String adminUid,
    required String status,
  }) async {
    await _reports
        .doc(reportId)
        .update({
          'status': status,
          'resolvedBy': adminUid,
          'resolvedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 10));
  }
}
