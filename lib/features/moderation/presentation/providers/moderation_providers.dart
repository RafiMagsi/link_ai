import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/moderation_remote_datasource.dart';
import '../../data/models/moderation_report_model.dart';

final moderationRemoteDataSourceProvider = Provider<ModerationRemoteDataSource>(
  (ref) {
    return ModerationRemoteDataSource(ref.watch(firebaseFirestoreProvider));
  },
);

final blockStatusProvider = StreamProvider.family<bool, String>((
  ref,
  targetUid,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const Stream<bool>.empty();
  }

  final blockId = '${user.uid}_$targetUid';
  return ref
      .watch(moderationRemoteDataSourceProvider)
      .watchBlockDoc(blockId)
      .map((doc) => doc.exists);
});

final moderationReportsProvider = StreamProvider<List<ModerationReportModel>>((
  ref,
) {
  return ref
      .watch(moderationRemoteDataSourceProvider)
      .watchReports(openOnly: false);
});

final moderationOpenReportsProvider =
    StreamProvider<List<ModerationReportModel>>((ref) {
      return ref
          .watch(moderationRemoteDataSourceProvider)
          .watchReports(openOnly: true);
    });

final moderationControllerProvider =
    StateNotifierProvider<ModerationController, AsyncValue<void>>((ref) {
      return ModerationController(ref);
    });

class ModerationController extends StateNotifier<AsyncValue<void>> {
  ModerationController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  ModerationRemoteDataSource get _remoteDataSource {
    return _ref.read(moderationRemoteDataSourceProvider);
  }

  Future<void> reportUser({
    required String targetUid,
    required String reason,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();

    try {
      await _remoteDataSource.reportUser(
        reporterUid: user.uid,
        targetUid: targetUid,
        reason: reason,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> blockUser(String targetUid) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();

    try {
      await _remoteDataSource.blockUser(
        blockerUid: user.uid,
        blockedUid: targetUid,
      );
      _ref.invalidate(blockStatusProvider(targetUid));
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> unblockUser(String targetUid) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();

    try {
      await _remoteDataSource.unblockUser(
        blockerUid: user.uid,
        blockedUid: targetUid,
      );
      _ref.invalidate(blockStatusProvider(targetUid));
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> resolveReport({
    required ModerationReportModel report,
    required String status,
    String? actionType,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();

    try {
      await _remoteDataSource.resolveReport(
        report: report,
        adminUid: user.uid,
        status: status,
        actionType: actionType,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
