import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Navigates to a profile page with route deduplication.
/// If already on the same profile page, provides haptic and visual feedback.
Future<void> navigateToProfile({
  required BuildContext context,
  required String uid,
  required bool isSelfProfile,
}) async {
  if (!context.mounted) return;

  final routerState = GoRouterState.of(context);
  final currentLocation = routerState.uri.toString();

  // Determine target route
  final targetRoute = isSelfProfile ? '/profile' : '/profiles/$uid';

  // Check if already on the target route
  if (currentLocation == targetRoute) {
    // Provide haptic feedback instead of navigating
    await HapticFeedback.lightImpact();
    return;
  }

  // Navigate to the profile page
  if (context.mounted) {
    context.push(targetRoute);
  }
}
