import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      developer.log('User registered successfully: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e, stackTrace) {
      developer.log(
        'Firebase Auth Error during registration: ${e.code} - ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during registration',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      developer.log('User logged in successfully: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e, stackTrace) {
      developer.log(
        'Firebase Auth Error during login: ${e.code} - ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during login',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      developer.log('User logged out successfully');
    } on FirebaseAuthException catch (e, stackTrace) {
      developer.log(
        'Firebase Auth Error during logout: ${e.code} - ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during logout',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
