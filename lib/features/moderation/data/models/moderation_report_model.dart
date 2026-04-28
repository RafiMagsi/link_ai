import 'package:cloud_firestore/cloud_firestore.dart';

class ModerationReportModel {
  const ModerationReportModel({
    required this.id,
    required this.type,
    required this.reporterUid,
    required this.reason,
    required this.status,
    required this.postId,
    required this.targetUid,
    required this.resolvedBy,
    required this.createdAt,
    required this.resolvedAt,
  });

  final String id;
  final String type;
  final String reporterUid;
  final String reason;
  final String status;
  final String? postId;
  final String? targetUid;
  final String? resolvedBy;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  bool get isResolved => status != 'open';

  factory ModerationReportModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return ModerationReportModel(
      id: (data['id'] as String?) ?? doc.id,
      type: (data['type'] as String?) ?? 'post',
      reporterUid: (data['reporterUid'] as String?) ?? '',
      reason: (data['reason'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'open',
      postId: data['postId'] as String?,
      targetUid: data['targetUid'] as String?,
      resolvedBy: data['resolvedBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}
