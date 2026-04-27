import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

enum ProfileCompletionStatus {
  complete,
  incomplete,
}

/// Determines if a user's profile is complete
/// A profile is complete if it has: name, role, and bio
final profileCompletionStatusProvider =
    Provider<ProfileCompletionStatus>((ref) {
  final profile = ref.watch(myProfileProvider);

  return profile.when(
    data: (data) {
      if (data == null) return ProfileCompletionStatus.incomplete;

      final hasName = data.name.isNotEmpty;
      final hasRole = data.role.isNotEmpty;
      final hasBio = data.bio.isNotEmpty;

      if (hasName && hasRole && hasBio) {
        return ProfileCompletionStatus.complete;
      }

      return ProfileCompletionStatus.incomplete;
    },
    loading: () => ProfileCompletionStatus.incomplete,
    error: (_, _) => ProfileCompletionStatus.incomplete,
  );
});

/// Determines if onboarding should be shown
/// Shows if:
/// - Profile is incomplete
/// - User hasn't dismissed it in the last 24 hours
/// - Onboarding hasn't been shown before
final shouldShowOnboardingProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  final settings = ref.watch(userSettingsProvider);
  final profileStatus = ref.watch(profileCompletionStatusProvider);

  if (user == null) return false;
  if (profileStatus == ProfileCompletionStatus.complete) return false;

  return settings.when(
    data: (data) {
      // If onboarding was already shown, check if 24 hours have passed
      if (data.lastOnboardingDismissAt != null) {
        final now = DateTime.now();
        final timeSinceDismissal = now.difference(data.lastOnboardingDismissAt!);

        // Only show again after 24 hours
        if (timeSinceDismissal.inHours < 24) {
          return false;
        }
      }

      return true;
    },
    loading: () => false,
    error: (_, _) => false,
  );
});
