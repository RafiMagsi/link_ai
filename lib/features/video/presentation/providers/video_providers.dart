import 'package:flutter_riverpod/legacy.dart';

/// Holds the postId of the currently auto-playing video in the feed.
final activeVideoPostIdProvider = StateProvider<String?>((ref) => null);
