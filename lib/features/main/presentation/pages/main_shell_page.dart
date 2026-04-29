import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/main_bottom_nav_bar.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key, required this.child});

  final Widget child;

  int _getTabIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case '/feed':
        return 0;
      case '/explore':
        return 1;
      case '/messages':
        return 2;
      case '/products':
        return 3;
      case '/profile':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getTabIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: currentIndex,
        onDestinationSelected: (index) {
          final routes = ['/feed', '/explore', '/messages', '/products', '/profile'];
          if (index < routes.length) {
            context.replace(routes[index]);
          }
        },
      ),
    );
  }
}
