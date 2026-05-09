import 'package:flutter/material.dart';

class AppResponsive {
  // Breakpoints
  static const smallPhoneWidth = 360.0;
  static const largePhoneWidth = 600.0;
  static const tabletWidth = 768.0;
  static const desktopWidth = 1100.0;

  // Screen size checks
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < smallPhoneWidth;
  }

  static bool isPhone(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= smallPhoneWidth && width < largePhoneWidth;
  }

  static bool isLargePhone(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= largePhoneWidth && width < tabletWidth;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < tabletWidth;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletWidth && width < desktopWidth;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopWidth;
  }

  // Adaptive horizontal padding for cards, posts, pages
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < smallPhoneWidth) return 12;
    if (width < largePhoneWidth) return 16;
    return 20;
  }

  // Adaptive grid column count
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < largePhoneWidth) return 2;
    if (width < desktopWidth) return 3;
    return 4;
  }

  // Web nav rail width
  static double navRailWidth(BuildContext context) {
    return isDesktop(context) ? 240 : 72;
  }

  // Max content width for centered feeds
  static double maxContentWidth(BuildContext context) {
    return isDesktop(context) ? 680 : double.infinity;
  }

  // Right panel width (desktop only)
  static const rightPanelWidth = 320.0;
}
