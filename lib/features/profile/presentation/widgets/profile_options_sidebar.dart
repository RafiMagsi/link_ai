import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';

class ProfileSidebarAction {
  const ProfileSidebarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

Future<void> showProfileOptionsSidebar({
  required BuildContext context,
  required String title,
  required List<ProfileSidebarAction> actions,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close profile options',
    barrierColor: Colors.black54,
    pageBuilder: (context, animation, secondaryAnimation) {
      final theme = Theme.of(context);
      final width = MediaQuery.sizeOf(context).width.clamp(280.0, 360.0);

      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: theme.colorScheme.surface,
          elevation: 24,
          child: SafeArea(
            left: false,
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg,
                      AppSizes.lg,
                      AppSizes.md,
                      AppSizes.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: actions.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final action = actions[index];
                        return ListTile(
                          leading: Icon(action.icon),
                          title: Text(action.label),
                          onTap: () {
                            Navigator.of(context).pop();
                            action.onTap();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
