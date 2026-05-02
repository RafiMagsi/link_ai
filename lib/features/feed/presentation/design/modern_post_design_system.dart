import 'package:flutter/material.dart';

import '../../data/models/post_model.dart';

class ModernPostDesignSystem {
  // Spacing & Layout
  static const double accentBarWidth = 4.0;
  static const double cardBorderRadius = 8.0;
  static const double cardBorderWidth = 0.7;
  static const double cardPadding = 12.0;
  static const double contentGap = 8.0;
  static const double actionRowGap = 16.0;

  // Typography
  static const FontWeight authorNameWeight = FontWeight.w700;
  static const double authorNameSize = 14.0;
  static const FontWeight postTextWeight = FontWeight.w400;
  static const double postTextSize = 15.0;
  static const double timeTextSize = 12.0;

  // Get accent color by post type
  static Color getAccentColor(PostType type) {
    return switch (type) {
      PostType.thought => const Color(0xFF64748B), // slate
      PostType.ship => const Color(0xFF22C55E), // emerald
      PostType.ask => const Color(0xFF3B82F6), // blue
      PostType.commentRepost => const Color(0xFF64748B), // slate (like thought)
    };
  }

  // Get soft background color by post type
  static Color getSoftBackgroundColor(PostType type) {
    return switch (type) {
      PostType.thought => const Color(0xFFF1F5F9), // slate-100
      PostType.ship => const Color(0xFFDCFCE7), // emerald-100
      PostType.ask => const Color(0xFFDBEAFE), // blue-100
      PostType.commentRepost => const Color(0xFFF1F5F9),
    };
  }

  // Get type label
  static String? getTypeLabel(PostType type) {
    return switch (type) {
      PostType.thought => null,
      PostType.ship => 'Shipped',
      PostType.ask => 'Asking',
      PostType.commentRepost => null,
    };
  }

  // Get type icon
  static IconData getTypeIcon(PostType type) {
    return switch (type) {
      PostType.thought => Icons.auto_awesome_outlined,
      PostType.ship => Icons.rocket_launch_outlined,
      PostType.ask => Icons.help_outline_rounded,
      PostType.commentRepost => Icons.repeat_outlined,
    };
  }
}
