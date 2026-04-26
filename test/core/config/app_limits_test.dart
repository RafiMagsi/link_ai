import 'package:flutter_test/flutter_test.dart';
import 'package:link_ai/core/config/app_limits.dart';

void main() {
  test('AppLimits.defaults matches plan limits', () {
    final limits = AppLimits.defaults();
    expect(limits.postMaxChars, 280);
    expect(limits.postMaxMediaItems, 4);
    expect(limits.imageMaxBytes, 5 * 1024 * 1024);
    expect(limits.videoMaxBytes, 200 * 1024 * 1024);
    expect(limits.videoMaxDurationSeconds, 30);
    expect(limits.connectRequestsPerWeek, 50);
  });

  test('AppLimits.fromJson falls back for missing values', () {
    final limits = AppLimits.fromJson(const {});
    expect(limits.postMaxChars, AppLimits.defaults().postMaxChars);
    expect(
      limits.videoMaxDurationSeconds,
      AppLimits.defaults().videoMaxDurationSeconds,
    );
  });

  test('AppLimits.fromJson accepts numeric types', () {
    final limits = AppLimits.fromJson(const {
      'postMaxChars': 140,
      'videoMaxDurationSeconds': 15.0,
    });
    expect(limits.postMaxChars, 140);
    expect(limits.videoMaxDurationSeconds, 15);
  });
}
