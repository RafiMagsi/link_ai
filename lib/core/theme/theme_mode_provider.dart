import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';
import '../../features/settings/data/models/user_settings_model.dart';

final appThemeModeProvider = Provider<ThemeMode>((ref) {
  try {
    final user = ref.watch(currentUserProvider);
    if (user == null) return ThemeMode.system;

    final settings = ref.watch(userSettingsProvider);
    return settings.maybeWhen(
      data: (value) {
        try {
          return value.themeModeValue;
        } catch (e) {
         debugPrint('Error reading theme mode: $e');
          return ThemeMode.system;
        }
      },
      orElse: () => ThemeMode.system,
    );
  } catch (e) {
   debugPrint('Error in appThemeModeProvider: $e');
    return ThemeMode.system;
  }
});

extension _UserSettingsThemeMode on UserSettingsModel {
  ThemeMode get themeModeValue {
    try {
      return switch (themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (e) {
     debugPrint('Error converting theme mode: $e');
      return ThemeMode.system;
    }
  }
}
