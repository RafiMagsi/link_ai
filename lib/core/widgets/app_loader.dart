import 'package:flutter/material.dart';

class AppLoader extends StatefulWidget {
  const AppLoader({
    super.key,
    this.size = 48,
    this.strokeWidth = 4,
  });

  final double size;
  final double strokeWidth;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    try {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      )..repeat();

      _rotation = Tween<double>(begin: 0, end: 6.28).animate(
        CurvedAnimation(parent: _controller, curve: Curves.linear),
      );

      _opacity = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.0), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.4), weight: 50),
      ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    } catch (e) {
     debugPrint('Error initializing AppLoader animations: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    try {
      _controller.dispose();
    } catch (e) {
     debugPrint('Error disposing AppLoader animation controller: $e');
    } finally {
      super.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _GradientCirclePainter(
                progress: _controller.value,
                opacity: _opacity.value,
                primaryColor: scheme.primary,
                secondaryColor: scheme.secondary,
                strokeWidth: widget.strokeWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GradientCirclePainter extends CustomPainter {
  _GradientCirclePainter({
    required this.progress,
    required this.opacity,
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
  });

  final double progress;
  final double opacity;
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = (size.width / 2) - (strokeWidth / 2);

      // Validate dimensions
      if (radius <= 0 || !center.isFinite) {
        return;
      }

      // Create gradient
      final gradient = SweepGradient(
        colors: [
          primaryColor.withValues(alpha: opacity),
          secondaryColor.withValues(alpha: opacity),
          primaryColor.withValues(alpha: opacity * 0.4),
        ],
        stops: const [0.0, 0.5, 1.0],
        startAngle: 0,
        endAngle: 6.28,
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      // Draw arc with animation
      final sweepAngle = 2.5 + (progress * 0.5);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        0,
        sweepAngle,
        false,
        paint,
      );

      // Draw secondary arc (trailing)
      final secondaryPaint = Paint()
        ..color = secondaryColor.withValues(alpha: opacity * 0.2)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        sweepAngle + 0.3,
        1.5,
        false,
        secondaryPaint,
      );
    } catch (e) {
     debugPrint('Error painting AppLoader: $e');
    }
  }

  @override
  bool shouldRepaint(_GradientCirclePainter oldDelegate) =>
      progress != oldDelegate.progress || opacity != oldDelegate.opacity;
}
