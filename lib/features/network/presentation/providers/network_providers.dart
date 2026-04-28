import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../connect/presentation/providers/connect_providers.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

final followingProfilesProvider = Provider<AsyncValue<List<ProfileModel>>>((
  ref,
) {
  final profilesState = ref.watch(publicProfilesProvider);
  final followingState = ref.watch(myConnectionsProvider);

  final profiles = profilesState.asData?.value;
  final following = followingState.asData?.value;

  if (profiles == null || following == null) {
    final error = profilesState.asError?.error ?? followingState.asError?.error;
    final stackTrace =
        profilesState.asError?.stackTrace ?? followingState.asError?.stackTrace;

    if (error != null && stackTrace != null) {
      return AsyncError(error, stackTrace);
    }

    return const AsyncLoading();
  }

  final followingIds = following
      .map((connection) => connection.connectedUid)
      .where((uid) => uid.isNotEmpty)
      .toList(growable: false);

  if (followingIds.isEmpty) {
    return const AsyncData(<ProfileModel>[]);
  }

  final profileByUid = {for (final profile in profiles) profile.uid: profile};
  final orderedProfiles = followingIds
      .map((uid) => profileByUid[uid])
      .whereType<ProfileModel>()
      .toList(growable: false);

  return AsyncData(orderedProfiles);
});

final collaborationMatchesProvider = Provider<AsyncValue<List<ProfileModel>>>((
  ref,
) {
  final profilesState = ref.watch(publicProfilesProvider);
  final followingState = ref.watch(myConnectionsProvider);
  final meState = ref.watch(myProfileProvider);

  final profiles = profilesState.asData?.value;
  final following = followingState.asData?.value;
  final me = meState.asData?.value;

  if (profiles == null || following == null) {
    final error =
        profilesState.asError?.error ??
        followingState.asError?.error ??
        meState.asError?.error;
    final stackTrace =
        profilesState.asError?.stackTrace ??
        followingState.asError?.stackTrace ??
        meState.asError?.stackTrace;

    if (error != null && stackTrace != null) {
      return AsyncError(error, stackTrace);
    }

    return const AsyncLoading();
  }

  final currentUid = ref.watch(currentUserProvider)?.uid;
  final followingIds = following.map((item) => item.connectedUid).toSet();

  final candidates = profiles.where((profile) {
    if (profile.uid == currentUid) return false;
    if (followingIds.contains(profile.uid)) return false;
    if (profile.collaborationIntent == 'not_looking') return false;
    return true;
  }).toList();

  candidates.sort(
    (a, b) => _scoreProfile(b, me).compareTo(_scoreProfile(a, me)),
  );
  return AsyncData(candidates.take(20).toList(growable: false));
});

final openToCollaborateProfilesProvider =
    Provider<AsyncValue<List<ProfileModel>>>((ref) {
      final profilesState = ref.watch(publicProfilesProvider);
      final profiles = profilesState.asData?.value;

      if (profiles == null) {
        final error = profilesState.asError?.error;
        final stackTrace = profilesState.asError?.stackTrace;
        if (error != null && stackTrace != null) {
          return AsyncError(error, stackTrace);
        }
        return const AsyncLoading();
      }

      final currentUid = ref.watch(currentUserProvider)?.uid;
      final filtered = profiles.where((profile) {
        if (profile.uid == currentUid) return false;
        return profile.collaborationIntent != 'not_looking';
      }).toList();

      filtered.sort(
        (a, b) =>
            (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)),
      );
      return AsyncData(filtered.take(20).toList(growable: false));
    });

int _scoreProfile(ProfileModel profile, ProfileModel? me) {
  var total = 0;
  final mySkills = <String>{
    ...?me?.skills,
    ...?me?.tools,
  }.map((item) => item.toLowerCase()).toSet();
  final theirSkills = {
    ...profile.skills,
    ...profile.tools,
    ...profile.lookingFor,
  }.map((item) => item.toLowerCase()).toSet();

  total += theirSkills.where(mySkills.contains).length * 3;

  if (me != null && me.need.trim().isNotEmpty) {
    final need = me.need.toLowerCase();
    if (profile.building.toLowerCase().contains(need)) total += 4;
    if (profile.bio.toLowerCase().contains(need)) total += 2;
  }

  if (me != null && me.building.trim().isNotEmpty) {
    final building = me.building.toLowerCase();
    if (profile.need.toLowerCase().contains(building)) total += 4;
  }

  if (profile.collaborationIntent == 'hiring') total += 2;
  if (profile.collaborationIntent == 'looking_for_cofounder') total += 2;
  if (profile.projectStage == 'launched' || profile.projectStage == 'growing') {
    total += 1;
  }

  return total;
}
