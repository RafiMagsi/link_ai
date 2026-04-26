import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profile_model.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _profiles {
    return _firestore.collection('profiles');
  }

  Future<void> createProfileIfNotExists(ProfileModel profile) async {
    final docRef = _profiles.doc(profile.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) return;

    await docRef.set(profile.toCreateMap());
  }

  Future<ProfileModel?> getProfile(String uid) async {
    final snapshot = await _profiles.doc(uid).get();

    if (!snapshot.exists) return null;

    return ProfileModel.fromFirestore(snapshot);
  }

  Stream<ProfileModel?> watchProfile(String uid) {
    return _profiles.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return ProfileModel.fromFirestore(snapshot);
    });
  }

  Future<void> updateProfile(ProfileModel profile) async {
    await _profiles.doc(profile.uid).update(profile.toUpdateMap());
  }

  Future<List<ProfileModel>> getPublicProfiles({
    int limit = 20,
  }) async {
    final snapshot = await _profiles
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map(ProfileModel.fromFirestore).toList();
  }
}