import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/notifications/presentation/providers/notification_providers.dart';

import '../router/app_router.dart';

class LinkAiApp extends ConsumerWidget {
  const LinkAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    authState.whenData((user) {
      if (user != null) {
        Future.microtask(() {
          ref
              .read(notificationControllerProvider.notifier)
              .initializeForCurrentUser();
        });
      }
    });

    return MaterialApp.router(
      title: 'LinkAI',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
    );
  }
}
