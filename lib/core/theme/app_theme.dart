import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'app_theme_colors.dart';

abstract class AppTheme {
  // "Claude-like" soothing palette:
  // - Light: warm paper background + coral accent
  // - Dark: deep graphite + soft coral accent

  static ThemeData light() {
    const scaffold = Color(0xFFF7F6F2); // warm paper
    const surface = Color(0xFFFFFFFF);
    const primary = Color(0xFFDC6A4D); // soft coral
    const secondary = Color(0xFF1E887A); // calming teal
    const onSurface = Color(0xFF0F172A);
    const border = Color(0xFFE7E2D9);
    const mutedText = Color(0xFF6B7280);
    const surfaceMuted = Color(0xFFF2F0EA);

    final scheme = const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: Color(0xFFDC2626),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: onSurface,
      onError: Colors.white,
    );

    return _baseTheme(
      scheme: scheme,
      scaffoldBackground: scaffold,
      appBarBackground: scaffold,
      border: border,
      mutedText: mutedText,
      surfaceMuted: surfaceMuted,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark() {
    const scaffold = Color(0xFF0E1116); // graphite
    const surface = Color(0xFF121826);
    const primary = Color(0xFFFF8A65); // soft coral
    const secondary = Color(0xFF2DD4BF); // teal
    const onSurface = Color(0xFFEAF0FF);
    const border = Color(0xFF253049);
    const mutedText = Color(0xFF9AA7C2);
    const surfaceMuted = Color(0xFF0B1020);

    final scheme = const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: Color(0xFFEF4444),
      onPrimary: Color(0xFF1B100A),
      onSecondary: Color(0xFF05201B),
      onSurface: onSurface,
      onError: Colors.white,
    );

    return _baseTheme(
      scheme: scheme,
      scaffoldBackground: scaffold,
      appBarBackground: scaffold,
      border: border,
      mutedText: mutedText,
      surfaceMuted: surfaceMuted,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _baseTheme({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required Color appBarBackground,
    required Color border,
    required Color mutedText,
    required Color surfaceMuted,
    required Brightness brightness,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      extensions: <ThemeExtension<dynamic>>[
        AppThemeColors(
          border: border,
          mutedText: mutedText,
          surfaceMuted: surfaceMuted,
        ),
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: appBarBackground,
        foregroundColor: scheme.onSurface,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.7, space: 1),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: appBarBackground,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMuted,
        selectedColor: scheme.primary.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: border),
        ),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surface,
        contentTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide(color: scheme.primary),
        ),
        hintStyle: TextStyle(color: mutedText),
      ),
    );
  }
}
