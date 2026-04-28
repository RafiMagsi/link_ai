import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../messaging/presentation/providers/messaging_providers.dart';

class MainBottomNavBar extends ConsumerWidget {
  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadMessageCount =
        ref.watch(unreadMessagesCountProvider).asData?.value ?? 0;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dynamic_feed_outlined),
          selectedIcon: Icon(Icons.dynamic_feed),
          label: 'Feed',
        ),
        const NavigationDestination(
          icon: Icon(Icons.travel_explore_outlined),
          selectedIcon: Icon(Icons.travel_explore),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: unreadMessageCount > 0,
            label: Text(unreadMessageCount > 99 ? '99+' : '$unreadMessageCount'),
            child: const Icon(Icons.mail_outline),
          ),
          selectedIcon: Badge(
            isLabelVisible: unreadMessageCount > 0,
            label: Text(unreadMessageCount > 99 ? '99+' : '$unreadMessageCount'),
            child: const Icon(Icons.mail),
          ),
          label: 'Messages',
        ),
        const NavigationDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps),
          label: 'Products',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
