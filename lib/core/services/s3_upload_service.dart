import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../firebase_options.dart';

class S3UploadService {
  S3UploadService({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(
            app: Firebase.app(),
            region: 'us-central1',
          ),
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Uri _fallbackUrl() {
    final projectId = Firebase.app().options.projectId.isNotEmpty
        ? Firebase.app().options.projectId
        : DefaultFirebaseOptions.currentPlatform.projectId;
    return Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/generateS3UploadUrlHttp',
    );
  }

  Future<Map<String, dynamic>> _requestUploadUrl({
    required String s3Path,
    required String mimeType,
    required String idToken,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateS3UploadUrl');
      final result = await callable.call({
        'path': s3Path,
        'contentType': mimeType,
        'idToken': idToken,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'unauthenticated') rethrow;

      final response = await http
          .post(
            _fallbackUrl(),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'path': s3Path, 'contentType': mimeType}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'S3 upload auth fallback failed: HTTP ${response.statusCode} ${response.body}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'm4v':
        return 'video/x-m4v';
      case '3gp':
        return 'video/3gpp';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }

  /// Upload a file to S3 and return the public URL
  ///
  /// [file] — File to upload
  /// [s3Path] — S3 path (e.g., 'postMedia/userId/postId/uuid.jpg')
  /// [onProgress] — Optional callback for upload progress (bytes sent / total bytes)
  ///
  /// Returns the public S3 URL
  /// Throws exceptions on auth failure, timeout, or network errors
  Future<String> uploadFile({
    required File file,
    required String s3Path,
    void Function(int, int)? onProgress,
  }) async {
    try {
      if (!file.existsSync()) {
        throw Exception('File does not exist: ${file.path}');
      }

      final fileBytes = await file.readAsBytes();
      final mimeType = _getMimeType(file.path);

      debugPrint('S3 Upload: $s3Path (${fileBytes.length} bytes, $mimeType)');

      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'You must be logged in to upload files.',
        );
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'Unable to obtain a valid auth token.',
        );
      }

      // 1. Get presigned URL from Firebase Function
      final result = await _requestUploadUrl(
        s3Path: s3Path,
        mimeType: mimeType,
        idToken: idToken,
      );

      final presignedUrl = result['presignedUrl'] as String;
      final publicUrl = result['publicUrl'] as String;

      // 2. PUT file to S3 via presigned URL
      final response = await http
          .put(
            Uri.parse(presignedUrl),
            headers: {'Content-Type': mimeType},
            body: fileBytes,
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception(
          'S3 upload failed: HTTP ${response.statusCode} '
          'url=${Uri.parse(presignedUrl).host} '
          'body=${response.body}',
        );
      }

      // Report progress
      onProgress?.call(fileBytes.length, fileBytes.length);

      return publicUrl;
    } on SocketException catch (e) {
      debugPrint('Network error uploading file to S3: $e');
      throw Exception(
        'Network error. Please check your connection and try again.',
      );
    } on TimeoutException catch (e) {
      debugPrint('Timeout uploading file to S3: $e');
      throw Exception('Upload took too long. Please try again.');
    } catch (e, stackTrace) {
      debugPrint('Error uploading file to S3: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Delete a file from S3
  /// [s3Path] — S3 path to delete
  Future<void> deleteFile({required String s3Path}) async {
    try {
      // TODO: Implement S3 DELETE operation
      debugPrint('S3 Delete (placeholder): $s3Path');
    } catch (e, stackTrace) {
      debugPrint('Error deleting file from S3: $e\n$stackTrace');
      rethrow;
    }
  }
}
