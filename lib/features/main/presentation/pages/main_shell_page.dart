import 'package:flutter/material.dart';

import '../../../explore/presentation/pages/explore_page.dart';
import '../../../feed/presentation/pages/feed_page.dart';
import '../../../messaging/presentation/pages/inbox_page.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../widgets/main_bottom_nav_bar.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  late final PageController _pageController;

  final _pages = const [
    FeedPage(),
    ExplorePage(),
    InboxPage(),
    ProductsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _pages,
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }
}
