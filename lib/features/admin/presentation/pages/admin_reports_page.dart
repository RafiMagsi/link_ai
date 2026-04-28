import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../moderation/data/models/moderation_report_model.dart';
import '../../../moderation/presentation/providers/moderation_providers.dart';

class AdminReportsPage extends ConsumerWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(moderationReportsProvider);
    final moderationState = ref.watch(moderationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moderation Queue')),
      body: reportsState.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const AppEmptyState(
              icon: Icons.verified_user_outlined,
              title: 'No reports',
              subtitle: 'Nothing is waiting in the moderation queue.',
            );
          }

          return ListView.separated(
            itemCount: reports.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportTile(
                report: report,
                isBusy: moderationState.isLoading,
                onResolve: (status, actionType) async {
                  await ref
                      .read(moderationControllerProvider.notifier)
                      .resolveReport(
                        report: report,
                        status: status,
                        actionType: actionType,
                      );
                },
              );
            },
          );
        },
        loading: () => const Center(child: AppLoader()),
        error: (error, stackTrace) {
          return const Center(child: Text('Unable to load reports.'));
        },
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.report,
    required this.isBusy,
    required this.onResolve,
  });

  final ModerationReportModel report;
  final bool isBusy;
  final void Function(String status, String? actionType) onResolve;

  @override
  Widget build(BuildContext context) {
    final typeLabel = report.type == 'user' ? 'User report' : 'Post report';
    final targetLabel = report.type == 'user'
        ? (report.targetUid ?? 'Unknown user')
        : (report.postId ?? 'Unknown post');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        child: Icon(
          report.type == 'user'
              ? Icons.person_off_outlined
              : Icons.flag_outlined,
        ),
      ),
      title: Text(typeLabel),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.reason, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Reporter: ${report.reporterUid}'),
          Text('Target: $targetLabel'),
          Text('Status: ${report.status}'),
          if (report.actionType != null) Text('Action: ${report.actionType}'),
        ],
      ),
      trailing: PopupMenuButton<String>(
        enabled: !isBusy,
        onSelected: (value) {
          switch (value) {
            case 'resolved':
              onResolve('resolved', null);
              break;
            case 'dismissed':
              onResolve('dismissed', null);
              break;
            case 'hide_post':
              onResolve('actioned', 'hide_post');
              break;
            case 'restore_post':
              onResolve('resolved', 'restore_post');
              break;
            case 'suspend_user':
              onResolve('actioned', 'suspend_user');
              break;
            case 'restore_user':
              onResolve('resolved', 'restore_user');
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'resolved', child: Text('Mark resolved')),
          const PopupMenuItem(value: 'dismissed', child: Text('Dismiss')),
          if (report.type == 'post' && report.postId != null) ...const [
            PopupMenuDivider(),
            PopupMenuItem(value: 'hide_post', child: Text('Hide post')),
            PopupMenuItem(value: 'restore_post', child: Text('Restore post')),
          ],
          if (report.type == 'user' && report.targetUid != null) ...const [
            PopupMenuDivider(),
            PopupMenuItem(value: 'suspend_user', child: Text('Suspend user')),
            PopupMenuItem(value: 'restore_user', child: Text('Restore user')),
          ],
        ],
      ),
      isThreeLine: true,
    );
  }
}
