import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  bool _isFullScreenRoute(BuildContext context) {
    try {
      final router = GoRouter.of(context);
      final uri = router.routeInformationProvider.value.uri;
      final path = uri.path;
      debugPrint('=== DEBUG: Router path = $path');
      final isFullScreen = path.startsWith('/videos/short/');
      debugPrint('=== DEBUG: isFullScreen = $isFullScreen');
      return isFullScreen;
    } catch (e) {
      debugPrint('=== DEBUG: Error getting router path - $e');
      return false;
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
          debugPrint('=== MOBILE BUILD: About to check full screen route');
          final showBottomNav = !_isFullScreenRoute(context);
          debugPrint('=== MOBILE BUILD: showBottomNav = $showBottomNav, maxWidth: ${constraints.maxWidth}');
          return Scaffold(
            body: child,
            bottomNavigationBar: showBottomNav
                ? MainBottomNavBar(
                    currentIndex: currentIndex,
                    onDestinationSelected: (index) => _navigateTo(context, index),
                  )
                : null,
          );
        }

        // Web/Tablet layout with side navigation (Twitter-like proportions)
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                // Left navigation rail (~240px)
                if (isDesktop)
                Expanded(flex: 1, child: SizedBox()), // Spacer
                Expanded(
                  flex: 2,
                  child: ClipRect(
                    child: WebNavRail(
                      currentIndex: currentIndex,
                      onTap: (index) => _navigateTo(context, index),
                      onCreatePost: () => _openCreatePost(context),
                    ),
                  ),
                ),
                // Center content area (~600px, wider)
                Expanded(
                  flex: 3,
                  child: ClipRect(
                    child: child,
                  ),
                ),
                // Right sidebar (~320px, desktop only)
                if (isDesktop)
                  Expanded(
                    flex: 2,
                    child: ClipRect(
                      child: const WebRightPanel(),
                    ),
                  ),
                  if (isDesktop)
                  Expanded(flex: 1, child: SizedBox()), // Spacer
              ],
            ),
          ),
        );
      },
    );
  }
}
