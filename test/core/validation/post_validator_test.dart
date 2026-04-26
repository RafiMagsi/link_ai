import 'package:flutter_test/flutter_test.dart';
import 'package:link_ai/core/config/app_limits.dart';
import 'package:link_ai/core/validation/post_validation.dart';

void main() {
  test('validates post text length', () {
    final limits = AppLimits.defaults();
    final validator = PostValidator(limits);

    final text = List.filled(limits.postMaxChars + 1, 'a').join();
    final errors = validator.validate(text: text, media: const []);

    expect(errors.whereType<PostTextTooLong>().length, 1);
  });

  test('validates media count', () {
    final limits = AppLimits.defaults();
    final validator = PostValidator(limits);

    final media = List.generate(
      limits.postMaxMediaItems + 1,
      (_) => const MediaCandidate(type: MediaType.image, sizeBytes: 1024),
    );
    final errors = validator.validate(text: 'ok', media: media);

    expect(errors.whereType<TooManyMediaItems>().length, 1);
  });

  test('validates image size', () {
    final limits = AppLimits.defaults();
    final validator = PostValidator(limits);

    final errors = validator.validate(
      text: 'ok',
      media: [
        MediaCandidate(
          type: MediaType.image,
          sizeBytes: limits.imageMaxBytes + 1,
        ),
      ],
    );

    final tooLarge = errors.whereType<MediaTooLarge>().toList();
    expect(tooLarge.length, 1);
    expect(tooLarge.single.type, MediaType.image);
  });

  test('validates video size and duration when provided', () {
    final limits = AppLimits.defaults();
    final validator = PostValidator(limits);

    final errors = validator.validate(
      text: 'ok',
      media: [
        MediaCandidate(
          type: MediaType.video,
          sizeBytes: limits.videoMaxBytes + 1,
          durationSeconds: limits.videoMaxDurationSeconds + 1,
        ),
      ],
    );

    expect(errors.whereType<MediaTooLarge>().length, 1);
    expect(errors.whereType<VideoTooLong>().length, 1);
  });
}
