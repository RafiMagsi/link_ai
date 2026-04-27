import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Custom exception for validation errors.
class ValidationError implements Exception {
  final String message;
  ValidationError(this.message);

  @override
  String toString() => message;
}

/// Custom exception for file/image size errors.
class FileSizeError implements Exception {
  final String message;
  FileSizeError(this.message);

  @override
  String toString() => message;
}

/// Custom exception for rate limiting.
class RateLimitError implements Exception {
  final String message;
  final Duration? retryAfter;
  RateLimitError(this.message, {this.retryAfter});

  @override
  String toString() => message;
}

/// Custom exception for storage quota exceeded.
class StorageQuotaError implements Exception {
  final String message;
  StorageQuotaError(this.message);

  @override
  String toString() => message;
}

/// Maps various error types to user-friendly messages.
class ErrorHandler {
  /// Gets a user-friendly error message from any error type.
  ///
  /// This function handles:
  /// - Firebase Authentication errors
  /// - Firestore errors
  /// - Network errors (Dio)
  /// - Validation errors
  /// - File size errors
  /// - Rate limit errors
  /// - Storage quota errors
  /// - Generic exceptions
  static String getUserFriendlyMessage(dynamic error) {
    try {
      if (error is FirebaseAuthException) {
        return _handleFirebaseAuthError(error);
      }

      if (error is FirebaseException) {
        return _handleFirestoreError(error);
      }

      if (error is DioException) {
        return _handleNetworkError(error);
      }

      if (error is ValidationError) {
        return _handleValidationError(error);
      }

      if (error is FileSizeError) {
        return _handleFileSizeError(error);
      }

      if (error is RateLimitError) {
        return _handleRateLimitError(error);
      }

      if (error is StorageQuotaError) {
        return _handleStorageQuotaError(error);
      }

      if (error is Exception) {
        return _handleGenericException(error);
      }

      return 'An unexpected error occurred. Please try again.';
    } catch (e) {
      // Fallback if error handling itself fails
      debugPrint('Error in getUserFriendlyMessage: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handles Firebase Authentication exceptions.
  static String _handleFirebaseAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'user-not-found' =>
        'This account does not exist. Please check your email or sign up.',
      'wrong-password' =>
        'Incorrect password. Please try again.',
      'invalid-email' =>
        'The email address is invalid. Please check and try again.',
      'user-disabled' =>
        'This account has been disabled. Contact support for help.',
      'email-already-in-use' =>
        'An account with this email already exists. Please log in instead.',
      'weak-password' =>
        'Your password is too weak. Please use at least 8 characters.',
      'operation-not-allowed' =>
        'This operation is not allowed. Please try again later.',
      'too-many-requests' =>
        'Too many login attempts. Please try again in a few minutes.',
      'requires-recent-login' =>
        'Please log out and log in again before performing this action.',
      'network-request-failed' =>
        'Network connection failed. Check your internet and try again.',
      _ => 'Authentication error. Please try again.',
    };
  }

  /// Handles Firestore exceptions.
  static String _handleFirestoreError(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' =>
        'You don\'t have permission to access this resource.',
      'not-found' =>
        'This item no longer exists or has been deleted.',
      'already-exists' =>
        'This item already exists.',
      'resource-exhausted' =>
        'Server is temporarily busy. Please try again in a moment.',
      'invalid-argument' =>
        'Invalid request. Please check your input and try again.',
      'cancelled' =>
        'Request was cancelled. Please try again.',
      'deadline-exceeded' =>
        'Request took too long. Please check your connection and retry.',
      'unavailable' =>
        'Service is temporarily unavailable. Please try again later.',
      'unauthenticated' =>
        'You\'re not authenticated. Please log in again.',
      _ => 'Unable to complete this operation. Please try again.',
    };
  }

  /// Handles network errors (Dio).
  static String _handleNetworkError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout =>
        'Connection timed out. Check your network and try again.',
      DioExceptionType.sendTimeout =>
        'Request took too long. Please retry.',
      DioExceptionType.receiveTimeout =>
        'Response took too long. Please retry.',
      DioExceptionType.badResponse =>
        _handleHttpStatusCode(error.response?.statusCode),
      DioExceptionType.badCertificate =>
        'Security error. Please try again later.',
      DioExceptionType.connectionError =>
        'Connection lost. Check your network and try again.',
      DioExceptionType.unknown =>
        'Network error. Check your connection and try again.',
      _ => 'Network error occurred. Please try again.',
    };
  }

  /// Handles HTTP status codes.
  static String _handleHttpStatusCode(int? statusCode) {
    return switch (statusCode) {
      400 => 'Invalid request. Please check your input and try again.',
      401 => 'You\'re not authenticated. Please log in again.',
      403 => 'You don\'t have permission to perform this action.',
      404 => 'This item no longer exists or has been deleted.',
      409 => 'This item already exists.',
      429 => 'Too many requests. Please wait a moment and try again.',
      500 => 'Server error. Please try again later.',
      503 => 'Service is temporarily unavailable. Please try again later.',
      _ => 'An error occurred. Please try again.',
    };
  }

  /// Handles validation errors.
  static String _handleValidationError(ValidationError error) {
    return error.message;
  }

  /// Handles file/image size errors.
  static String _handleFileSizeError(FileSizeError error) {
    return error.message;
  }

  /// Handles rate limit errors.
  static String _handleRateLimitError(RateLimitError error) {
    if (error.retryAfter != null) {
      final seconds = error.retryAfter!.inSeconds;
      return 'Too many requests. Please wait ${seconds}s and try again.';
    }
    return error.message;
  }

  /// Handles storage quota errors.
  static String _handleStorageQuotaError(StorageQuotaError error) {
    return error.message;
  }

  /// Handles generic exceptions.
  static String _handleGenericException(Exception error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'Connection lost. Check your network and try again.';
    }

    if (message.contains('TimeoutException')) {
      return 'Request took too long. Please retry.';
    }

    if (message.contains('No internet')) {
      return 'No internet connection. Please check your network.';
    }

    if (message.contains('FormatException')) {
      return 'Invalid data format. Please try again or contact support.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}

/// Extension on [AsyncValue] for easier error message handling.
extension AsyncValueErrorExt<T> on AsyncValue<T> {
  /// Gets the user-friendly error message if this value is in error state.
  String? getUserFriendlyErrorMessage() {
    return whenData((_) => null).asError?.error != null
        ? ErrorHandler.getUserFriendlyMessage(asError!.error)
        : null;
  }
}
