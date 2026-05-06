import 'package:flutter/material.dart';

import '../../data/models/post_model.dart';

String? postIntentLabel(PostIntent intent) {
  return switch (intent) {
    PostIntent.general => null,
    PostIntent.launch => 'Launch',
    PostIntent.feedback => 'Feedback',
    PostIntent.hiring => 'Hiring',
    PostIntent.cofounder => 'Cofounder',
    PostIntent.question => 'Question',
  };
}

IconData postIntentIcon(PostIntent intent) {
  return switch (intent) {
    PostIntent.general => Icons.auto_awesome_outlined,
    PostIntent.launch => Icons.rocket_launch_outlined,
    PostIntent.feedback => Icons.rate_review_outlined,
    PostIntent.hiring => Icons.badge_outlined,
    PostIntent.cofounder => Icons.group_add_outlined,
    PostIntent.question => Icons.help_outline_rounded,
  };
}

Color postIntentColor(PostIntent intent) {
  return switch (intent) {
    PostIntent.general => const Color(0xFF64748B),
    PostIntent.launch => const Color(0xFF22C55E),
    PostIntent.feedback => const Color(0xFF3B82F6),
    PostIntent.hiring => const Color(0xFFF59E0B),
    PostIntent.cofounder => const Color(0xFFA855F7),
    PostIntent.question => const Color(0xFF0EA5E9),
  };
}
