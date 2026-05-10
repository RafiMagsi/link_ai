import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoProgressBar extends StatelessWidget {
  const VideoProgressBar({
    super.key,
    required this.controller,
    required this.onSeek,
  });

  final VideoPlayerController controller;
  final Function(Duration) onSeek;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _handleSeek(context, details.globalPosition);
      },
      onTapDown: (details) {
        _handleSeek(context, details.globalPosition);
      },
      child: _ProgressBarPainter(
        controller: controller,
      ),
    );
  }

  void _handleSeek(BuildContext context, Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);
    final percentage = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final duration = controller.value.duration;
    final seekPosition = duration * percentage;
    controller.seekTo(seekPosition);
  }
}

class _ProgressBarPainter extends StatelessWidget {
  const _ProgressBarPainter({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dark background for total duration
            Container(color: Colors.white.withValues(alpha: 0.1)),
            // Buffered content (light gray)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.buffered.isEmpty || value.duration.inMilliseconds == 0) {
                  return const SizedBox.shrink();
                }
                final bufferedEnd = value.buffered.last.end;
                final bufferedPercent = (bufferedEnd.inMilliseconds / value.duration.inMilliseconds)
                    .clamp(0.0, 1.0);
                return FractionallySizedBox(
                  widthFactor: bufferedPercent,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                );
              },
            ),
            // Playing progress (bright blue)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.duration.inMilliseconds == 0) {
                  return const SizedBox.shrink();
                }
                final playedPercent =
                    (value.position.inMilliseconds / value.duration.inMilliseconds)
                        .clamp(0.0, 1.0);
                return FractionallySizedBox(
                  widthFactor: playedPercent,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    color: const Color(0xFF3B82F6),
                  ),
                );
              },
            ),
            // Playhead thumb
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.duration.inMilliseconds == 0) {
                  return const SizedBox.shrink();
                }
                final playedPercent =
                    (value.position.inMilliseconds / value.duration.inMilliseconds)
                        .clamp(0.0, 1.0);
                return Align(
                  alignment: Alignment(playedPercent * 2 - 1, 0),
                  child: Transform.translate(
                    offset: const Offset(0, 0),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
