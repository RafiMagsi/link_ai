import 'package:flutter/material.dart';

class ShadowStyle {
  const ShadowStyle._();

  static const Color borderColor = Color(0xFFA78BFA);
  static const Color blueGlow = Color(0xFF60A5FA);
  static const Color violetGlow = Color(0xFFA78BFA);
  static const Color pinkGlow = Color(0xFFF9A8D4);

  static List<BoxShadow> lightShadow({Color? color}) {
    final glowColor = color ?? violetGlow;

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.020),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
      BoxShadow(
        color: glowColor.withValues(alpha: 0.026),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static Border subtleBorder({Color? color}) {
    return Border.all(
      color: (color ?? borderColor).withValues(alpha: 0.075),
      width: 0.7,
    );
  }
}