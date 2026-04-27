import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_config_model.dart';

class AppConfigRemoteDataSource {
  AppConfigRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _globalConfig {
    return _firestore.collection('appConfig').doc('global');
  }

  Stream<AppConfigModel> watchGlobalConfig() {
    return _globalConfig.snapshots()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) => sink.close(),
        )
        .map((snapshot) {
          try {
            return AppConfigModel.fromFirestore(snapshot);
          } catch (error, stackTrace) {
            print('Error parsing global config: $error\n$stackTrace');
            rethrow;
          }
        });
  }

  Future<AppConfigModel> getGlobalConfig() async {
    try {
      final snapshot = await _globalConfig.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Config fetch timed out'),
      );
      return AppConfigModel.fromFirestore(snapshot);
    } on TimeoutException catch (e) {
      print('Timeout fetching global config: $e');
      // Return default config on timeout to prevent app crash
      return AppConfigModel.defaults();
    } catch (e) {
      print('Error fetching global config: $e');
      // Return default config on error to prevent app crash
      return AppConfigModel.defaults();
    }
  }

  Future<void> updateGlobalConfig({
    required AppConfigModel config,
    required String updatedBy,
  }) async {
    try {
      await _globalConfig.set(
        config.toUpdateMap(updatedBy: updatedBy),
        SetOptions(merge: true),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Config update timed out'),
      );
    } on TimeoutException catch (e) {
      print('Timeout updating global config: $e');
      throw Exception(
        'Config update took too long. Please check your connection and try again.',
      );
    } on FirebaseException catch (e) {
      print('Firebase error updating config: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('You do not have permission to update the app configuration.');
      } else if (e.code == 'invalid-argument') {
        throw Exception('Invalid configuration data. Please check your input.');
      } else if (e.code == 'unauthenticated') {
        throw Exception('You must be authenticated to update configuration.');
      }
      rethrow;
    } catch (e) {
      print('Error updating global config: $e');
      rethrow;
    }
  }

  Future<void> createDefaultIfMissing({required String updatedBy}) async {
    try {
      final snapshot = await _globalConfig.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Config check timed out'),
      );

      if (snapshot.exists) return;

      await _globalConfig.set(
        AppConfigModel.defaults().toUpdateMap(updatedBy: updatedBy),
        SetOptions(merge: true),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Default config creation timed out'),
      );
    } on TimeoutException catch (e) {
      print('Timeout creating default config: $e');
      throw Exception(
        'Default config creation took too long. Please try again.',
      );
    } on FirebaseException catch (e) {
      print('Firebase error creating default config: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('You do not have permission to create the app configuration.');
      } else if (e.code == 'unauthenticated') {
        throw Exception('You must be authenticated to create configuration.');
      }
      rethrow;
    } catch (e) {
      print('Error creating default config: $e');
      rethrow;
    }
  }
}
