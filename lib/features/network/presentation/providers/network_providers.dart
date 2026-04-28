import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../connect/presentation/providers/connect_providers.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

final followingProfilesProvider = FutureProvider<List<ProfileModel>>((
  ref,
) async {
  final connections = await ref.watch(myConnectionsProvider.future);
  final uids = connections
      .map((connection) => connection.connectedUid)
      .where((uid) => uid.isNotEmpty)
      .toList(growable: false);

  return ref.watch(profileRemoteDataSourceProvider).getProfilesByIds(uids);
});

final collaborationMatchesProvider = FutureProvider<List<ProfileModel>>((
  ref,
) async {
  final me = await ref.watch(myProfileProvider.future);
  final allProfiles = await ref.watch(publicProfilesProvider.future);
  final currentUid = ref.watch(currentUserProvider)?.uid;
  final following = await ref.watch(myConnectionsProvider.future);
  final followingIds = following.map((item) => item.connectedUid).toSet();

  final candidates = allProfiles.where((profile) {
    if (profile.uid == currentUid) return false;
    if (followingIds.contains(profile.uid)) return false;
    if (profile.collaborationIntent == 'not_looking') return false;
    return true;
  }).toList();

  int score(ProfileModel profile) {
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
    if (profile.projectStage == 'launched' ||
        profile.projectStage == 'growing') {
      total += 1;
    }

    return total;
  }

  candidates.sort((a, b) => score(b).compareTo(score(a)));
  return candidates.take(20).toList(growable: false);
});

final openToCollaborateProfilesProvider = FutureProvider<List<ProfileModel>>((
  ref,
) async {
  final currentUid = ref.watch(currentUserProvider)?.uid;
  final profiles = await ref.watch(publicProfilesProvider.future);

  final filtered = profiles.where((profile) {
    if (profile.uid == currentUid) return false;
    return profile.collaborationIntent != 'not_looking';
  }).toList();

  filtered.sort(
    (a, b) =>
        (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)),
  );
  return filtered.take(20).toList(growable: false);
});
