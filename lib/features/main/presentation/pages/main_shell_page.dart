import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_responsive.dart';
import '../widgets/main_bottom_nav_bar.dart';
import '../widgets/web_nav_rail.dart';
import '../widgets/web_right_panel.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key, required this.child});

  final Widget child;

  static const _routes = ['/feed', '/explore', '/messages', '/products', '/profile'];

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

  void _navigateTo(BuildContext context, int index) {
    if (index < _routes.length) {
      context.replace(_routes[index]);
    }
  }

  void _openCreatePost(BuildContext context) {
    context.push('/posts/create');
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getTabIndex(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isDesktop = constraints.maxWidth >= 1100;

        if (isMobile) {
          // Mobile layout with bottom navigation
          return Scaffold(
            body: child,
            bottomNavigationBar: MainBottomNavBar(
              currentIndex: currentIndex,
              onDestinationSelected: (index) => _navigateTo(context, index),
            ),
          );
        }

        // Web/Tablet layout with side navigation (3 equal columns)
        return Scaffold(
          body: Row(
            children: [
              // Left navigation rail (1/3 width)
              Expanded(
                flex: 1,
                child: ClipRect(
                  child: WebNavRail(
                    currentIndex: currentIndex,
                    onTap: (index) => _navigateTo(context, index),
                    onCreatePost: () => _openCreatePost(context),
                  ),
                ),
              ),
              // Center content area (1/3 width)
              Expanded(
                flex: 1,
                child: ClipRect(
                  child: child,
                ),
              ),
              // Right sidebar (1/3 width, desktop only)
              if (isDesktop)
                Expanded(
                  flex: 1,
                  child: ClipRect(
                    child: const WebRightPanel(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
