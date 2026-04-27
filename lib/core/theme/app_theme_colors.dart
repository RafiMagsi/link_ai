import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.border,
    required this.mutedText,
    required this.surfaceMuted,
  });

  final Color border;
  final Color mutedText;
  final Color surfaceMuted;

  @override
  AppThemeColors copyWith({
    Color? border,
    Color? mutedText,
    Color? surfaceMuted,
  }) {
    return AppThemeColors(
      border: border ?? this.border,
      mutedText: mutedText ?? this.mutedText,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;

    return AppThemeColors(
      border: Color.lerp(border, other.border, t) ?? border,
      mutedText: Color.lerp(mutedText, other.mutedText, t) ?? mutedText,
      surfaceMuted:
          Color.lerp(surfaceMuted, other.surfaceMuted, t) ?? surfaceMuted,
    );
  }
}

extension AppThemeColorsX on BuildContext {
  AppThemeColors get appColors {
    final ext = Theme.of(this).extension<AppThemeColors>();
    assert(ext != null, 'AppThemeColors extension is missing from ThemeData.');
    return ext!;
  }
}
