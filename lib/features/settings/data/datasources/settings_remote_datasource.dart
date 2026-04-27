import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_settings_model.dart';

class SettingsRemoteDataSource {
  SettingsRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _settings {
    return _firestore.collection('userSettings');
  }

  Future<void> createSettingsIfNotExists(String uid) async {
    final docRef = _settings.doc(uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) return;

    await docRef.set(UserSettingsModel.defaults(uid).toCreateMap());
  }

  Stream<UserSettingsModel> watchSettings(String uid) {
    return _settings.doc(uid).snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists) {
        await createSettingsIfNotExists(uid);
        return UserSettingsModel.defaults(uid);
      }

      return UserSettingsModel.fromFirestore(snapshot);
    });
  }

  Future<void> updateSettings(UserSettingsModel settings) async {
    await _settings
        .doc(settings.uid)
        .set(settings.toUpdateMap(), SetOptions(merge: true));
  }

  Future<void> deleteSettings(String uid) async {
    await _settings.doc(uid).delete();
  }
}
