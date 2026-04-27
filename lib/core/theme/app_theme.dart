import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'app_theme_colors.dart';

abstract class AppTheme {
  // Twitter/Instagram modern aesthetic:
  // - Light: clean white with vibrant Twitter blue + Instagram accent
  // - Dark: deep black with bright accent colors for contrast

  static ThemeData light() {
    const scaffold = Color(0xFFFFFFFF); // pure white
    const surface = Color(0xFFFFFFFF); // pure white surfaces
    const primary = Color(0xFF1DA1F2); // Twitter blue
    const secondary = Color(0xFFE1306C); // Instagram pink
    const onSurface = Color(0xFF0F1419);
    const border = Color(0xFFEFF3F4);
    const mutedText = Color(0xFF657786);
    const surfaceMuted = Color(0xFFF7F9FA);

    final scheme = const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: Color(0xFFE74C3C),
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
    const scaffold = Color(0xFF000000); // pure black
    const surface = Color(0xFF161B22); // dark surface
    const primary = Color(0xFF1DA1F2); // Twitter blue (bright on dark)
    const secondary = Color(0xFFE1306C); // Instagram pink
    const onSurface = Color(0xFFE7EDF4);
    const border = Color(0xFF2D3748);
    const mutedText = Color(0xFF828997);
    const surfaceMuted = Color(0xFF0A0E27);

    final scheme = const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: Color(0xFFEF5350),
      onPrimary: Color(0xFF000000),
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
    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    final textTheme = baseTextTheme.copyWith(
      // Display / page title: 28–32sp, bold
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      // Section title: 20–22sp, bold
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      // Body: 16–17sp, medium weight, better readability
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.1,
        color: scheme.onSurface,
      ),
      // Meta: 13–14sp, medium, muted
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: mutedText,
        height: 1.4,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
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
        elevation: 0.5,
        backgroundColor: appBarBackground,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontSize: 20,
        ),
        scrolledUnderElevation: 0.5,
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: appBarBackground,
        indicatorColor: scheme.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: mutedText,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: scheme.primary,
            );
          }
          return IconThemeData(
            color: mutedText,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMuted,
        selectedColor: scheme.primary.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
          side: BorderSide(color: border, width: 1),
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
        fillColor: surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: TextStyle(
          color: mutedText,
          fontSize: 15,
        ),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          textStyle: textTheme.labelMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: scheme.onPrimary,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          side: BorderSide(color: scheme.primary, width: 1.5),
          textStyle: textTheme.labelMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          textStyle: textTheme.labelMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}
