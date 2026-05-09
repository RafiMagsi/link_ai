# Video Module

Centralized video playback and management module for LinkAI. Handles all video-related functionality including HLS streaming, player state management, and memory-efficient preloading.

## Architecture

```
lib/features/video/
├── core/
│   └── managers/
│       └── feed_video_preload_manager.dart    # Intelligent preloading & memory management
├── data/
│   └── models/
│       └── video_model.dart                   # Core video data model
├── presentation/
│   ├── pages/
│   │   └── short_video_viewer_page.dart       # Full-screen short video viewer
│   ├── widgets/
│   │   ├── feed_hls_video_player.dart         # HLS-optimized feed player
│   │   └── video_player_widget.dart           # Generic post video player
│   └── providers/
│       └── video_providers.dart               # Riverpod state management
├── video.dart                                 # Barrel exports
└── README.md                                  # This file
```

## Core Components

### VideoModel
Video data representation with support for HLS URLs, thumbnails, and metadata.

```dart
final video = VideoModel(
  id: 'video-123',
  url: 'https://s3.amazonaws.com/videos/abc.mp4',
  hlsUrl: 'https://s3.amazonaws.com/videos/abc/master.m3u8',
  thumbnailUrl: 'https://...',
  durationSeconds: 30,
);
```

### FeedVideoPreloadManager
Singleton that manages video controller lifecycle for efficient memory usage. Keeps controllers for current, next, and previous videos only.

**Key methods:**
- `getOrCreate(url)` - Get or create controller for a URL
- `preload(url)` - Preload video silently
- `play(url)` - Start playback
- `pause(url)` - Pause playback
- `keepOnly(Set<String> urls)` - Dispose all except specified URLs
- `disposeAll()` - Clean up all controllers

```dart
final manager = FeedVideoPreloadManager.instance;

// Preload next video
await manager.preload(nextVideoUrl);

// Keep only current ±1 videos in memory
await manager.keepOnly({prevUrl, currentUrl, nextUrl}.toSet());

// Clean up on page exit
await manager.disposeAll();
```

### FeedHlsVideoPlayer
Instagram-style video player widget for feed items with:
- Visibility-based autoplay/pause
- HLS adaptive bitrate support
- Smooth controller reuse via preload manager
- Muted by default
- Looping playback

```dart
FeedHlsVideoPlayer(
  video: videoModel,
  isActive: index == currentIndex,
  isVisible: visibilityFraction > 0.65,
)
```

### VideoPlayerWidget
Generic video player for posts with:
- Play/pause controls
- Thumbnail placeholder
- Tap to play UI
- Auto-play based on visibility

```dart
VideoPlayerWidget(
  video: videoModel,
  postId: post.id,
  onTap: () { /* handle tap */ },
)
```

### ShortVideoViewerPage
Full-screen short video viewer with:
- Vertical swipe navigation
- Like, comment, repost, save actions
- Real-time progress indicator
- Share functionality

```dart
context.push('/videos/${post.id}', extra: post);
```

## State Management

### activeVideoPostIdProvider
Tracks which post's video is currently playing in the feed.

```dart
// Get current active video post ID
final activePostId = ref.watch(activeVideoPostIdProvider);

// Set active video
ref.read(activeVideoPostIdProvider.notifier).state = postId;
```

## Usage Patterns

### In Feed (Multiple Videos)

```dart
class FeedPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedPostsProvider);
    
    return PageView.builder(
      onPageChanged: (index) {
        ref.read(activeVideoPostIdProvider.notifier).state = posts[index].id;
        _preloadAroundIndex(index, posts);
      },
      itemBuilder: (context, index) {
        final post = posts[index];
        return FeedHlsVideoPlayer(
          video: VideoModel.fromPostMedia(
            url: post.media.first.url,
            hlsUrl: post.media.first.hlsUrl,
            thumbnailUrl: post.media.first.thumbnailUrl,
          ),
          isActive: index == _currentIndex,
          isVisible: _isVisible,
        );
      },
    );
  }

  Future<void> _preloadAroundIndex(int index, List<PostModel> posts) async {
    final manager = FeedVideoPreloadManager.instance;
    final urlsToKeep = <String>{};

    for (final i in [index - 1, index, index + 1]) {
      if (i < 0 || i >= posts.length) continue;
      final url = posts[i].media.first.hlsUrl ?? posts[i].media.first.url;
      urlsToKeep.add(url);
      
      if (i == index || i == index + 1) {
        await manager.preload(url);
      }
    }

    await manager.keepOnly(urlsToKeep);
  }
}
```

### In Post Detail (Single Video)

```dart
class PostDetailPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VideoPlayerWidget(
      video: VideoModel.fromPostMedia(
        url: post.media.first.url,
        hlsUrl: post.media.first.hlsUrl,
        thumbnailUrl: post.media.first.thumbnailUrl,
      ),
      postId: post.id,
    );
  }
}
```

## Memory Management Best Practices

1. **Dispose on page exit:**
   ```dart
   @override
   void dispose() {
     FeedVideoPreloadManager.instance.disposeAll();
     super.dispose();
   }
   ```

2. **Aggressive cleanup (feed only):**
   ```dart
   // Keep only current ±1, dispose rest
   await manager.keepOnly({prevUrl, currentUrl, nextUrl}.toSet());
   ```

3. **Monitor controller count:**
   ```dart
   final count = FeedVideoPreloadManager.instance.controllerCount;
   debugPrint('Active video controllers: $count');
   ```

## HLS Configuration

For optimal Instagram-style experience:

- **Master playlist:** `https://s3.amazonaws.com/videos/{id}/master.m3u8`
- **Renditions:** 360p (800k), 480p (1400k), 720p (2800k)
- **Segment length:** 2-3 seconds
- **Autoplay:** Muted only
- **Looping:** Enabled

Backend must generate HLS playlists on video upload via Cloud Functions.

## Implementation Checklist for New Features

- [ ] Use `VideoModel` for video data
- [ ] Use `FeedVideoPreloadManager` for feed video preloading
- [ ] Use `FeedHlsVideoPlayer` for feed items
- [ ] Use `VideoPlayerWidget` for single video contexts
- [ ] Call `disposeAll()` on page/widget exit
- [ ] Track active video with `activeVideoPostIdProvider`
- [ ] Support HLS URLs where possible

## See Also

- [Instagram-Style S3 HLS Flutter Buffering Plan](../../../docs/Video%20implementation/instagram_style_s3_hls_flutter_buffering_plan.md)
- Feed module (`lib/features/feed/`)
- Video module core utilities (`lib/features/video/core/`)
