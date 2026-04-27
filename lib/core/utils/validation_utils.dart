import 'package:flutter/foundation.dart';

/// Comprehensive validation utilities for user input and data.
///
/// All validation functions return error messages (or null if valid).
/// This allows for clear, specific error feedback without exceptions.
abstract class ValidationUtils {
  // Email validation regex
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  /// Validates an email address.
  /// Returns null if valid, error message if invalid.
  static String? validateEmail(String? email) {
    try {
      if (email == null || email.isEmpty) {
        return 'Email is required';
      }

      final trimmed = email.trim().toLowerCase();
      if (trimmed.isEmpty) {
        return 'Email is required';
      }

      if (trimmed.length > 254) {
        return 'Email is too long (max 254 characters)';
      }

      if (!_emailRegex.hasMatch(trimmed)) {
        return 'Invalid email format';
      }

      return null;
    } catch (e) {
     debugPrint('Error validating email: $e');
      return 'Error validating email';
    }
  }

  /// Validates a URL.
  /// Returns null if valid, error message if invalid.
  static String? validateUrl(String? url) {
    try {
      if (url == null || url.isEmpty) {
        return 'URL is required';
      }

      final trimmed = url.trim();
      if (trimmed.isEmpty) {
        return 'URL is required';
      }

      if (trimmed.length > 2048) {
        return 'URL is too long (max 2048 characters)';
      }

      // Try to parse as URI
      try {
        Uri.parse(trimmed);
      } catch (e) {
        return 'Invalid URL format';
      }

      if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
        return 'URL must start with http:// or https://';
      }

      return null;
    } catch (e) {
     debugPrint('Error validating URL: $e');
      return 'Error validating URL';
    }
  }

  /// Validates text length.
  /// Returns null if valid, error message if invalid.
  static String? validateLength(
    String? text, {
    int minLength = 0,
    int maxLength = 5000,
    String fieldName = 'Text',
  }) {
    try {
      if (text == null) {
        if (minLength > 0) {
          return '$fieldName is required';
        }
        return null;
      }

      final trimmed = text.trim();
      if (trimmed.isEmpty && minLength > 0) {
        return '$fieldName is required';
      }

      if (trimmed.length < minLength) {
        return '$fieldName must be at least $minLength characters';
      }

      if (trimmed.length > maxLength) {
        return '$fieldName must be no more than $maxLength characters';
      }

      return null;
    } catch (e) {
     debugPrint('Error validating length for $fieldName: $e');
      return 'Error validating $fieldName';
    }
  }

  /// Validates a password.
  /// Returns null if valid, error message if invalid.
  static String? validatePassword(String? password) {
    try {
      if (password == null || password.isEmpty) {
        return 'Password is required';
      }

      if (password.length < 8) {
        return 'Password must be at least 8 characters';
      }

      if (password.length > 128) {
        return 'Password is too long';
      }

      // Check for at least one uppercase letter
      if (!password.contains(RegExp(r'[A-Z]'))) {
        return 'Password must contain at least one uppercase letter';
      }

      // Check for at least one lowercase letter
      if (!password.contains(RegExp(r'[a-z]'))) {
        return 'Password must contain at least one lowercase letter';
      }

      // Check for at least one digit
      if (!password.contains(RegExp(r'[0-9]'))) {
        return 'Password must contain at least one digit';
      }

      return null;
    } catch (e) {
     debugPrint('Error validating password: $e');
      return 'Error validating password';
    }
  }

  /// Validates username/handle format.
  /// Returns null if valid, error message if invalid.
  static String? validateUsername(String? username) {
    try {
      if (username == null || username.isEmpty) {
        return 'Username is required';
      }

      final trimmed = username.trim();
      if (trimmed.isEmpty) {
        return 'Username is required';
      }

      if (trimmed.length < 3) {
        return 'Username must be at least 3 characters';
      }

      if (trimmed.length > 30) {
        return 'Username must be no more than 30 characters';
      }

      // Allow alphanumeric, underscore, and hyphen
      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
        return 'Username can only contain letters, numbers, underscores, and hyphens';
      }

      // Cannot start or end with hyphen or underscore
      if (trimmed.startsWith('-') ||
          trimmed.startsWith('_') ||
          trimmed.endsWith('-') ||
          trimmed.endsWith('_')) {
        return 'Username cannot start or end with hyphen or underscore';
      }

      return null;
    } catch (e) {
     debugPrint('Error validating username: $e');
      return 'Error validating username';
    }
  }

  /// Validates a name (first/last name).
  /// Returns null if valid, error message if invalid.
  static String? validateName(String? name, {String fieldName = 'Name'}) {
    try {
      if (name == null || name.isEmpty) {
        return '$fieldName is required';
      }

      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        return '$fieldName is required';
      }

      if (trimmed.length < 2) {
        return '$fieldName must be at least 2 characters';
      }

      if (trimmed.length > 50) {
        return '$fieldName must be no more than 50 characters';
      }

      // Allow letters, spaces, hyphens, and apostrophes
      if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(trimmed)) {
        return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
      }

      return null;
    } catch (e) {
     debugPrint('Error validating $fieldName: $e');
      return 'Error validating $fieldName';
    }
  }

  /// Validates that two values match (e.g., password confirmation).
  /// Returns null if valid, error message if invalid.
  static String? validateMatch(
    String? value1,
    String? value2, {
    String fieldName = 'Password',
  }) {
    try {
      if (value1 == null || value2 == null) {
        return '$fieldName does not match';
      }

      if (value1 != value2) {
        return '$fieldName does not match';
      }

      return null;
    } catch (e) {
     debugPrint('Error validating match for $fieldName: $e');
      return 'Error validating $fieldName';
    }
  }

  /// Validates a phone number (basic format).
  /// Returns null if valid, error message if invalid.
  static String? validatePhoneNumber(String? phone) {
    try {
      if (phone == null || phone.isEmpty) {
        return 'Phone number is required';
      }

      final trimmed = phone.replaceAll(RegExp(r'\D'), '');
      if (trimmed.isEmpty) {
        return 'Invalid phone number format';
      }

      if (trimmed.length < 10) {
        return 'Phone number must be at least 10 digits';
      }

      if (trimmed.length > 15) {
        return 'Phone number is too long';
      }

      return null;
    } catch (e) {
     debugPrint('Error validating phone number: $e');
      return 'Error validating phone number';
    }
  }

  /// Safely parses a string value with validation.
  /// Returns the value if valid, null if invalid.
  static String? safeParse(String? value) {
    try {
      if (value == null) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (e) {
     debugPrint('Error parsing string value: $e');
      return null;
    }
  }

  /// Safely parses an integer value.
  /// Returns the value if valid, null if invalid.
  static int? safeParseInt(dynamic value) {
    try {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value.trim());
      return null;
    } catch (e) {
     debugPrint('Error parsing int value: $e');
      return null;
    }
  }

  /// Safely parses a double value.
  /// Returns the value if valid, null if invalid.
  static double? safeParseDouble(dynamic value) {
    try {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value.trim());
      return null;
    } catch (e) {
     debugPrint('Error parsing double value: $e');
      return null;
    }
  }

  /// Safely parses a boolean value.
  /// Returns the value if valid, null if invalid.
  static bool? safeParseBool(dynamic value) {
    try {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase().trim();
        if (lower == 'true' || lower == '1' || lower == 'yes') return true;
        if (lower == 'false' || lower == '0' || lower == 'no') return false;
      }
      return null;
    } catch (e) {
     debugPrint('Error parsing bool value: $e');
      return null;
    }
  }

  /// Validates that a value is not empty/null.
  /// Returns null if valid, error message if invalid.
  static String? validateRequired(
    dynamic value, {
    String fieldName = 'This field',
  }) {
    try {
      if (value == null) {
        return '$fieldName is required';
      }

      if (value is String && value.trim().isEmpty) {
        return '$fieldName is required';
      }

      if (value is List && value.isEmpty) {
        return '$fieldName is required';
      }

      if (value is Map && value.isEmpty) {
        return '$fieldName is required';
      }

      return null;
    } catch (e) {
     debugPrint('Error validating required field $fieldName: $e');
      return '$fieldName is required';
    }
  }
}
