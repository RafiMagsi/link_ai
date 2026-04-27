import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'dart:async';

import '../models/user_settings_model.dart';

class SettingsRemoteDataSource {
  SettingsRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _settings {
    return _firestore.collection('userSettings');
  }

  Future<void> createSettingsIfNotExists(String uid) async {
    try {
      final docRef = _settings.doc(uid);
      final snapshot = await docRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to fetch settings document'),
      );

      if (snapshot.exists) return;

      await docRef.set(UserSettingsModel.defaults(uid).toCreateMap()).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to create settings'),
      );
      developer.log('Settings created successfully for UID: $uid');
    } on TimeoutException catch (e, stackTrace) {
      developer.log(
        'Timeout creating settings for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error creating settings for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Stream<UserSettingsModel> watchSettings(String uid) {
    return _settings.doc(uid).snapshots().asyncMap((snapshot) async {
      try {
        if (!snapshot.exists) {
          await createSettingsIfNotExists(uid);
          return UserSettingsModel.defaults(uid);
        }

        return UserSettingsModel.fromFirestore(snapshot);
      } catch (e, stackTrace) {
        developer.log(
          'Error watching settings for UID: $uid',
          error: e,
          stackTrace: stackTrace,
        );
        // Return default settings on error instead of crashing
        return UserSettingsModel.defaults(uid);
      }
    });
  }

  Future<void> updateSettings(UserSettingsModel settings) async {
    try {
      await _settings
          .doc(settings.uid)
          .set(settings.toUpdateMap(), SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Failed to update settings'),
          );
      developer.log('Settings updated successfully for UID: ${settings.uid}');
    } on TimeoutException catch (e, stackTrace) {
      developer.log(
        'Timeout updating settings for UID: ${settings.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error updating settings for UID: ${settings.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteSettings(String uid) async {
    try {
      await _settings.doc(uid).delete().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to delete settings'),
      );
      developer.log('Settings deleted successfully for UID: $uid');
    } on TimeoutException catch (e, stackTrace) {
      developer.log(
        'Timeout deleting settings for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting settings for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> updateOnboardingShown(String uid, bool shown) async {
    try {
      await _settings.doc(uid).set({
        'onboardingShown': shown,
      }, SetOptions(merge: true)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to update onboarding status'),
      );
      developer.log('Onboarding status updated for UID: $uid (shown: $shown)');
    } on TimeoutException catch (e, stackTrace) {
      developer.log(
        'Timeout updating onboarding status for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error updating onboarding status for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> dismissOnboardingUntilTomorrow(String uid) async {
    try {
      await _settings.doc(uid).set({
        'lastOnboardingDismissAt': DateTime.now(),
      }, SetOptions(merge: true)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Failed to dismiss onboarding'),
      );
      developer.log('Onboarding dismissed until tomorrow for UID: $uid');
    } on TimeoutException catch (e, stackTrace) {
      developer.log(
        'Timeout dismissing onboarding for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Error dismissing onboarding for UID: $uid',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
