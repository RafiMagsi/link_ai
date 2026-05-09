import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_responsive.dart';
import '../../../messaging/presentation/providers/messaging_providers.dart';

class WebNavRail extends ConsumerWidget {
  const WebNavRail({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCreatePost,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCreatePost;

  static const _navItems = [
    (icon: Icons.dynamic_feed_outlined, selectedIcon: Icons.dynamic_feed, label: 'Feed'),
    (icon: Icons.travel_explore_outlined, selectedIcon: Icons.travel_explore, label: 'Explore'),
    (icon: Icons.mail_outline, selectedIcon: Icons.mail, label: 'Messages'),
    (icon: Icons.apps_outlined, selectedIcon: Icons.apps, label: 'Products'),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = AppResponsive.isDesktop(context);
    final unreadMessageCount =
        ref.watch(unreadMessagesCountProvider).asData?.value ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.8,
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: double.infinity,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'AI',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_navItems.length, (index) {
                    final item = _navItems[index];
                    final isSelected = index == currentIndex;

                    // Special handling for Messages badge
                    Widget icon = Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      size: 24,
                    );
                    if (index == 2 && unreadMessageCount > 0) {
                      icon = Badge(
                        isLabelVisible: true,
                        label: Text(unreadMessageCount > 99 ? '99+' : '$unreadMessageCount'),
                        child: icon,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        onTap: () => onTap(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                          child: isDesktop
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.label,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight:
                                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                                              letterSpacing: 0.3,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    icon,
                                  ],
                                )
                              : Center(child: icon),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: ElevatedButton(
                  onPressed: onCreatePost,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 20 : 12,
                      vertical: 14,
                    ),
                  ),
                  child: isDesktop
                      ? const Text('Create Post')
                      : const Icon(Icons.edit),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
