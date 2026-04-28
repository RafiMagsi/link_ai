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

  CollectionReference<Map<String, dynamic>> get _posts {
    return _firestore.collection('posts');
  }

  CollectionReference<Map<String, dynamic>> get _userModeration {
    return _firestore.collection('userModeration');
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
          'actionType': null,
          'actionBy': null,
          'actionAt': null,
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
    required ModerationReportModel report,
    required String adminUid,
    required String status,
    String? actionType,
  }) async {
    final batch = _firestore.batch();
    final reportRef = _reports.doc(report.id);

    batch.update(reportRef, {
      'status': status,
      'resolvedBy': adminUid,
      'resolvedAt': FieldValue.serverTimestamp(),
      'actionType': actionType,
      'actionBy': actionType == null ? null : adminUid,
      'actionAt': actionType == null ? null : FieldValue.serverTimestamp(),
    });

    if (actionType == 'hide_post' && report.postId != null) {
      batch.update(_posts.doc(report.postId), {
        'visibility': 'hidden',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (actionType == 'restore_post' && report.postId != null) {
      batch.update(_posts.doc(report.postId), {
        'visibility': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (actionType == 'suspend_user' && report.targetUid != null) {
      batch.set(_userModeration.doc(report.targetUid), {
        'uid': report.targetUid,
        'status': 'suspended',
        'updatedBy': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (actionType == 'restore_user' && report.targetUid != null) {
      batch.set(_userModeration.doc(report.targetUid), {
        'uid': report.targetUid,
        'status': 'active',
        'updatedBy': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit().timeout(const Duration(seconds: 10));
  }
}
