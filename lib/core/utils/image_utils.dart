import 'dart:io';
import 'package:flutter/foundation.dart';

import '../errors/error_handler.dart';

/// Utilities for image validation, compression, and manipulation.
///
/// Provides safe image operations with comprehensive error handling.
abstract class ImageUtils {
  // Maximum file size constants (in bytes)
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxAvatarSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxThumbnailSizeBytes = 1 * 1024 * 1024; // 1MB

  // Supported image formats
  static const Set<String> supportedFormats = {
    'image/jpeg',
    'image/heic',
    'image/heif',
    'image/png',
    'image/webp',
    'image/gif',
  };

  static const Set<String> supportedExtensions = {
    'jpg',
    'jpeg',
    'heic',
    'heif',
    'png',
    'webp',
    'gif',
  };

  /// Validates image file size and format.
  /// Throws [FileSizeError] or returns error message if validation fails.
  static String? validateImage(
    File imageFile, {
    int maxSizeBytes = maxImageSizeBytes,
  }) {
    try {
      if (!imageFile.existsSync()) {
        return 'Image file does not exist';
      }

      final fileSizeBytes = imageFile.lengthSync();
      if (fileSizeBytes == 0) {
        return 'Image file is empty';
      }

      if (fileSizeBytes > maxSizeBytes) {
        final maxSizeMB = maxSizeBytes ~/ (1024 * 1024);
        return 'Image size exceeds ${maxSizeMB}MB limit';
      }

      final extension = _getFileExtension(imageFile.path).toLowerCase();
      if (!supportedExtensions.contains(extension)) {
        return 'Unsupported image format: $extension';
      }

      return null;
    } catch (e) {
      debugPrint('Error validating image: $e');
      return 'Error validating image';
    }
  }

  /// Validates image from bytes.
  static String? validateImageBytes(
    Uint8List imageBytes, {
    int maxSizeBytes = maxImageSizeBytes,
  }) {
    try {
      if (imageBytes.isEmpty) {
        return 'Image data is empty';
      }

      if (imageBytes.length > maxSizeBytes) {
        final maxSizeMB = maxSizeBytes ~/ (1024 * 1024);
        return 'Image size exceeds ${maxSizeMB}MB limit';
      }

      // Validate magic bytes (file signature)
      if (!_isValidImageMagicBytes(imageBytes)) {
        return 'Invalid image format';
      }

      return null;
    } catch (e) {
      debugPrint('Error validating image bytes: $e');
      return 'Error validating image';
    }
  }

  /// Checks if bytes match known image file signatures.
  static bool _isValidImageMagicBytes(Uint8List bytes) {
    try {
      if (bytes.isEmpty) return false;

      // JPEG: FF D8 FF
      if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return true;
      }

      // PNG: 89 50 4E 47
      if (bytes.length >= 4 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return true;
      }

      // GIF: 47 49 46
      if (bytes.length >= 3 &&
          bytes[0] == 0x47 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46) {
        return true;
      }

      // WebP: RIFF ... WEBP
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking magic bytes: $e');
      return false;
    }
  }

  /// Gets file extension from path.
  static String _getFileExtension(String filePath) {
    try {
      final lastDot = filePath.lastIndexOf('.');
      if (lastDot == -1) return '';
      return filePath.substring(lastDot + 1);
    } catch (e) {
      return '';
    }
  }

  /// Gets MIME type from file extension.
  static String? getMimeType(String filePath) {
    try {
      final extension = _getFileExtension(filePath).toLowerCase();
      return switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'heic' => 'image/heic',
        'heif' => 'image/heif',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => null,
      };
    } catch (e) {
      debugPrint('Error determining MIME type: $e');
      return null;
    }
  }

  /// Validates image URL format.
  /// Returns null if valid, error message if invalid.
  static String? validateImageUrl(String? url) {
    try {
      if (url == null || url.isEmpty) {
        return 'Image URL is required';
      }

      final trimmed = url.trim();
      if (trimmed.isEmpty) {
        return 'Image URL is required';
      }

      // Try to parse as URI
      try {
        final uri = Uri.parse(trimmed);
        if (!uri.isAbsolute) {
          return 'Image URL must be absolute';
        }

        if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
          return 'Image URL must start with http:// or https://';
        }
      } catch (e) {
        return 'Invalid image URL format';
      }

      // Check file extension
      final path = Uri.parse(trimmed).path.toLowerCase();
      final extension = _getFileExtension(path);
      if (extension.isNotEmpty && !supportedExtensions.contains(extension)) {
        return 'Unsupported image format: $extension';
      }

      return null;
    } catch (e) {
      debugPrint('Error validating image URL: $e');
      return 'Error validating image URL';
    }
  }

  /// Safely validates multiple images.
  /// Returns list of error messages for any invalid images.
  static List<String> validateMultipleImages(
    List<File> imageFiles, {
    int maxSizeBytes = maxImageSizeBytes,
  }) {
    try {
      if (imageFiles.isEmpty) {
        return ['No images provided'];
      }

      if (imageFiles.length > 10) {
        return ['Maximum 10 images allowed'];
      }

      final errors = <String>[];
      for (int i = 0; i < imageFiles.length; i++) {
        final error = validateImage(imageFiles[i], maxSizeBytes: maxSizeBytes);
        if (error != null) {
          errors.add('Image ${i + 1}: $error');
        }
      }

      return errors;
    } catch (e) {
      debugPrint('Error validating multiple images: $e');
      return ['Error validating images'];
    }
  }

  /// Validates multiple image URLs.
  /// Returns list of error messages for any invalid URLs.
  static List<String> validateMultipleImageUrls(List<String> urls) {
    try {
      if (urls.isEmpty) {
        return ['No image URLs provided'];
      }

      if (urls.length > 10) {
        return ['Maximum 10 images allowed'];
      }

      final errors = <String>[];
      for (int i = 0; i < urls.length; i++) {
        final error = validateImageUrl(urls[i]);
        if (error != null) {
          errors.add('Image ${i + 1}: $error');
        }
      }

      return errors;
    } catch (e) {
      debugPrint('Error validating multiple image URLs: $e');
      return ['Error validating image URLs'];
    }
  }

  /// Checks if an image is a valid avatar.
  /// Avatars have stricter size limits.
  static String? validateAvatarImage(File imageFile) {
    try {
      final error = validateImage(imageFile, maxSizeBytes: maxAvatarSizeBytes);
      if (error != null) return error;

      // Additional checks for avatars can be added here
      return null;
    } catch (e) {
      debugPrint('Error validating avatar image: $e');
      return 'Error validating avatar';
    }
  }

  /// Gets file size in human-readable format.
  static String getFileSizeString(int bytes) {
    try {
      if (bytes < 0) return 'Invalid size';
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
      if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } catch (e) {
      debugPrint('Error formatting file size: $e');
      return 'Unknown size';
    }
  }

  /// Safely checks if file exists.
  static bool fileExists(String filePath) {
    try {
      if (filePath.isEmpty) return false;
      return File(filePath).existsSync();
    } catch (e) {
      debugPrint('Error checking file existence: $e');
      return false;
    }
  }

  /// Safely gets file size in bytes.
  /// Returns 0 if file doesn't exist or error occurs.
  static int getFileSize(String filePath) {
    try {
      if (filePath.isEmpty) return 0;
      final file = File(filePath);
      if (!file.existsSync()) return 0;
      return file.lengthSync();
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0;
    }
  }

  /// Validates file path is safe (prevents directory traversal).
  static bool isValidFilePath(String filePath) {
    try {
      if (filePath.isEmpty) return false;
      if (filePath.contains('..')) return false;
      if (filePath.startsWith('/') && !_isInAppDirectory(filePath)) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error validating file path: $e');
      return false;
    }
  }

  /// Checks if path is within app's documents directory.
  static bool _isInAppDirectory(String filePath) {
    try {
      // This is a basic check - in production, compare absolute paths
      return !filePath.contains('/etc') &&
          !filePath.contains('/system') &&
          !filePath.contains('/root');
    } catch (e) {
      return false;
    }
  }
}
