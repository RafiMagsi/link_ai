import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../connect/data/models/connection_model.dart';
import '../../../connect/presentation/providers/connect_providers.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/saved_profiles_remote_datasource.dart';

final savedProfilesRemoteDataSourceProvider =
    Provider<SavedProfilesRemoteDataSource>((ref) {
      return SavedProfilesRemoteDataSource(ref.watch(firebaseFirestoreProvider));
    });

final myFollowersProvider = StreamProvider<List<ConnectionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  return ref.watch(connectRemoteDataSourceProvider).watchFollowers(user.uid);
});

final savedProfileIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  return ref
      .watch(savedProfilesRemoteDataSourceProvider)
      .watchSavedProfileIds(user.uid);
});

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

final followerProfilesProvider = Provider<AsyncValue<List<ProfileModel>>>((ref) {
  final profilesState = ref.watch(publicProfilesProvider);
  final followersState = ref.watch(myFollowersProvider);

  final profiles = profilesState.asData?.value;
  final followers = followersState.asData?.value;

  if (profiles == null || followers == null) {
    final error = profilesState.asError?.error ?? followersState.asError?.error;
    final stackTrace =
        profilesState.asError?.stackTrace ?? followersState.asError?.stackTrace;

    if (error != null && stackTrace != null) {
      return AsyncError(error, stackTrace);
    }

    return const AsyncLoading();
  }

  final followerIds = followers
      .map((connection) => connection.userUid)
      .where((uid) => uid.isNotEmpty)
      .toList(growable: false);

  if (followerIds.isEmpty) {
    return const AsyncData(<ProfileModel>[]);
  }

  final profileByUid = {for (final profile in profiles) profile.uid: profile};
  final orderedProfiles = followerIds
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

final suggestedProfilesProvider = Provider<AsyncValue<List<ProfileModel>>>((
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

final savedProfilesControllerProvider =
    StateNotifierProvider<SavedProfilesController, AsyncValue<void>>((ref) {
      return SavedProfilesController(
        ref,
        ref.watch(savedProfilesRemoteDataSourceProvider),
      );
    });

class SavedProfilesController extends StateNotifier<AsyncValue<void>> {
  SavedProfilesController(this._ref, this._dataSource)
    : super(const AsyncData(null));

  final Ref _ref;
  final SavedProfilesRemoteDataSource _dataSource;

  Future<void> toggleSavedProfile(String profileUid, {required bool isSaved}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();

    try {
      if (isSaved) {
        await _dataSource.unsaveProfile(uid: user.uid, profileUid: profileUid);
      } else {
        await _dataSource.saveProfile(uid: user.uid, profileUid: profileUid);
      }
      _ref.invalidate(savedProfileIdsProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

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
