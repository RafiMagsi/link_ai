class AppLimits {
  const AppLimits({
    required this.postMaxChars,
    required this.postMaxMediaItems,
    required this.imageMaxBytes,
    required this.videoMaxBytes,
    required this.videoMaxDurationSeconds,
    required this.connectRequestsPerWeek,
  });

  factory AppLimits.defaults() => const AppLimits(
    postMaxChars: 280,
    postMaxMediaItems: 4,
    imageMaxBytes: 5 * 1024 * 1024,
    videoMaxBytes: 200 * 1024 * 1024,
    videoMaxDurationSeconds: 30,
    connectRequestsPerWeek: 50,
  );

  factory AppLimits.fromJson(Map<String, Object?> json) {
    return AppLimits(
      postMaxChars: _readInt(
        json,
        'postMaxChars',
        AppLimits.defaults().postMaxChars,
      ),
      postMaxMediaItems: _readInt(
        json,
        'postMaxMediaItems',
        AppLimits.defaults().postMaxMediaItems,
      ),
      imageMaxBytes: _readInt(
        json,
        'imageMaxBytes',
        AppLimits.defaults().imageMaxBytes,
      ),
      videoMaxBytes: _readInt(
        json,
        'videoMaxBytes',
        AppLimits.defaults().videoMaxBytes,
      ),
      videoMaxDurationSeconds: _readInt(
        json,
        'videoMaxDurationSeconds',
        AppLimits.defaults().videoMaxDurationSeconds,
      ),
      connectRequestsPerWeek: _readInt(
        json,
        'connectRequestsPerWeek',
        AppLimits.defaults().connectRequestsPerWeek,
      ),
    );
  }

  final int postMaxChars;
  final int postMaxMediaItems;
  final int imageMaxBytes;
  final int videoMaxBytes;
  final int videoMaxDurationSeconds;
  final int connectRequestsPerWeek;

  Map<String, Object?> toJson() => {
    'postMaxChars': postMaxChars,
    'postMaxMediaItems': postMaxMediaItems,
    'imageMaxBytes': imageMaxBytes,
    'videoMaxBytes': videoMaxBytes,
    'videoMaxDurationSeconds': videoMaxDurationSeconds,
    'connectRequestsPerWeek': connectRequestsPerWeek,
  };

  static int _readInt(Map<String, Object?> json, String key, int fallback) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
