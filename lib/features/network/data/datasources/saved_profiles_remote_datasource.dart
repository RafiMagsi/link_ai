import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SavedProfilesRemoteDataSource {
  SavedProfilesRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _savedProfiles {
    return _firestore.collection('savedProfiles');
  }

  Stream<List<String>> watchSavedProfileIds(String uid, {int limit = 50}) {
    return _savedProfiles
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => (doc.data()['profileUid'] as String?) ?? '')
                .where((value) => value.isNotEmpty)
                .toList(growable: false);
          } catch (error, stackTrace) {
            debugPrint(
              'Error parsing saved profile IDs for $uid: $error\n$stackTrace',
            );
            return <String>[];
          }
        });
  }

  Future<void> saveProfile({
    required String uid,
    required String profileUid,
  }) async {
    final saveId = '${profileUid}_$uid';
    await _savedProfiles.doc(saveId).set({
      'id': saveId,
      'uid': uid,
      'profileUid': profileUid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unsaveProfile({
    required String uid,
    required String profileUid,
  }) async {
    final saveId = '${profileUid}_$uid';
    await _savedProfiles.doc(saveId).delete();
  }
}
