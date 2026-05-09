import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class FeedVideoPreloadManager {
  FeedVideoPreloadManager._();

  static final FeedVideoPreloadManager instance = FeedVideoPreloadManager._();

  final Map<String, VideoPlayerController> _controllers = {};
  final Set<String> _initializing = {};

  VideoPlayerController? controllerFor(String url) {
    return _controllers[url];
  }

  Future<VideoPlayerController> getOrCreate(String url) async {
    final existing = _controllers[url];
    if (existing != null) return existing;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controllers[url] = controller;

    await _initialize(url, controller);
    return controller;
  }

  Future<void> preload(String url) async {
    if (_controllers.containsKey(url) || _initializing.contains(url)) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controllers[url] = controller;

    await _initialize(url, controller);
  }

  Future<void> _initialize(
    String url,
    VideoPlayerController controller,
  ) async {
    if (_initializing.contains(url)) return;

    _initializing.add(url);

    try {
      // Fast initialization with minimal buffering
      // Don't wait for full initialization, start with timeout
      final initFuture = controller.initialize();

      // Set timeout - start playback even if still loading
      await Future.any([
        initFuture,
        Future.delayed(const Duration(milliseconds: 500)),
      ]).catchError((_) {
        // Ignore timeout, continue anyway
      });

      // Apply fast buffering settings
      await Future.wait([
        controller.setLooping(true),
        controller.setVolume(0),
        if (controller.value.isInitialized)
          controller.play().then((_) => controller.pause()),
      ]).catchError((_) {
        // Ignore errors during initialization
        return [];
      });
    } catch (error, stackTrace) {
      debugPrint('Video preload failed: $url\n$error\n$stackTrace');
      await disposeUrl(url);
    } finally {
      _initializing.remove(url);
    }
  }

  Future<void> play(String url) async {
    final controller = _controllers[url];
    if (controller == null || !controller.value.isInitialized) return;

    await controller.setVolume(0);
    await controller.play();
  }

  Future<void> pause(String url) async {
    final controller = _controllers[url];
    if (controller == null) return;

    await controller.pause();
  }

  Future<void> disposeUrl(String url) async {
    final controller = _controllers.remove(url);
    _initializing.remove(url);

    if (controller == null) return;

    try {
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> keepOnly(Set<String> urlsToKeep) async {
    final urls = _controllers.keys.toList();

    for (final url in urls) {
      if (!urlsToKeep.contains(url)) {
        await disposeUrl(url);
      }
    }
  }

  Future<void> disposeAll() async {
    final urls = _controllers.keys.toList();

    for (final url in urls) {
      await disposeUrl(url);
    }
  }

  int get controllerCount => _controllers.length;
}
