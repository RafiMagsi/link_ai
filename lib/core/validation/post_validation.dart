import '../config/app_limits.dart';

enum MediaType { image, video }

class MediaCandidate {
  const MediaCandidate({
    required this.type,
    required this.sizeBytes,
    this.durationSeconds,
  });

  final MediaType type;
  final int sizeBytes;

  /// Required for videos if you want to enforce `videoMaxDurationSeconds`.
  final int? durationSeconds;
}

sealed class PostValidationError {
  const PostValidationError();
}

class PostTextTooLong extends PostValidationError {
  const PostTextTooLong({required this.maxChars, required this.actualChars});

  final int maxChars;
  final int actualChars;
}

class TooManyMediaItems extends PostValidationError {
  const TooManyMediaItems({required this.maxItems, required this.actualItems});

  final int maxItems;
  final int actualItems;
}

class MediaTooLarge extends PostValidationError {
  const MediaTooLarge({
    required this.type,
    required this.maxBytes,
    required this.actualBytes,
  });

  final MediaType type;
  final int maxBytes;
  final int actualBytes;
}

class VideoTooLong extends PostValidationError {
  const VideoTooLong({required this.maxSeconds, required this.actualSeconds});

  final int maxSeconds;
  final int actualSeconds;
}

class PostValidator {
  const PostValidator(this.limits);

  final AppLimits limits;

  List<PostValidationError> validate({
    required String text,
    required List<MediaCandidate> media,
  }) {
    final errors = <PostValidationError>[];

    final charCount = text.length;
    if (charCount > limits.postMaxChars) {
      errors.add(
        PostTextTooLong(maxChars: limits.postMaxChars, actualChars: charCount),
      );
    }

    if (media.length > limits.postMaxMediaItems) {
      errors.add(
        TooManyMediaItems(
          maxItems: limits.postMaxMediaItems,
          actualItems: media.length,
        ),
      );
    }

    for (final item in media) {
      switch (item.type) {
        case MediaType.image:
          if (item.sizeBytes > limits.imageMaxBytes) {
            errors.add(
              MediaTooLarge(
                type: MediaType.image,
                maxBytes: limits.imageMaxBytes,
                actualBytes: item.sizeBytes,
              ),
            );
          }
        case MediaType.video:
          if (item.sizeBytes > limits.videoMaxBytes) {
            errors.add(
              MediaTooLarge(
                type: MediaType.video,
                maxBytes: limits.videoMaxBytes,
                actualBytes: item.sizeBytes,
              ),
            );
          }

          final duration = item.durationSeconds;
          if (duration != null && duration > limits.videoMaxDurationSeconds) {
            errors.add(
              VideoTooLong(
                maxSeconds: limits.videoMaxDurationSeconds,
                actualSeconds: duration,
              ),
            );
          }
      }
    }

    return errors;
  }
}
