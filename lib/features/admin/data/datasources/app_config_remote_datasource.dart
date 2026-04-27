import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_config_model.dart';

class AppConfigRemoteDataSource {
  AppConfigRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _globalConfig {
    return _firestore.collection('appConfig').doc('global');
  }

  Stream<AppConfigModel> watchGlobalConfig() {
    return _globalConfig.snapshots().map(AppConfigModel.fromFirestore);
  }

  Future<AppConfigModel> getGlobalConfig() async {
    final snapshot = await _globalConfig.get();
    return AppConfigModel.fromFirestore(snapshot);
  }

  Future<void> updateGlobalConfig({
    required AppConfigModel config,
    required String updatedBy,
  }) async {
    await _globalConfig.set(
      config.toUpdateMap(updatedBy: updatedBy),
      SetOptions(merge: true),
    );
  }

  Future<void> createDefaultIfMissing({required String updatedBy}) async {
    final snapshot = await _globalConfig.get();

    if (snapshot.exists) return;

    await _globalConfig.set(
      AppConfigModel.defaults().toUpdateMap(updatedBy: updatedBy),
      SetOptions(merge: true),
    );
  }
}
