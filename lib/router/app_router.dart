import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/public_profile_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/admin/presentation/pages/admin_settings_page.dart';
import '../features/admin/presentation/providers/admin_providers.dart';
import '../features/feed/presentation/pages/create_post_page.dart';
import '../features/feed/presentation/pages/post_detail_page.dart';
import '../features/main/presentation/pages/main_shell_page.dart';
import '../features/connect/presentation/pages/connect_requests_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/feed/data/models/post_model.dart';
import '../features/explore/presentation/pages/hashtag_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final adminStatus = ref.watch(adminStatusProvider);

  return GoRouter(
    initialLocation: '/feed',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRemoteDataSourceProvider).authStateChanges(),
    ),
    redirect: (context, state) {
      final user = authState.asData?.value;
      final isLoggedIn = user != null;

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      if (authState.isLoading) {
        return null;
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/feed';
      }

      if (isAdminRoute) {
        final isAdmin = adminStatus.asData?.value == true;

        if (adminStatus.isLoading) {
          return null;
        }

        if (!isAdmin) {
          return '/feed';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const MainShellPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/profiles/:uid',
        name: 'public-profile',
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return PublicProfilePage(uid: uid);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'admin-settings',
        builder: (context, state) => const AdminSettingsPage(),
      ),
      GoRoute(
        path: '/posts/create',
        name: 'create-post',
        builder: (context, state) => const CreatePostPage(),
      ),
      GoRoute(
        path: '/posts/:postId',
        name: 'post-detail',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          final initialPost = state.extra is PostModel
              ? state.extra as PostModel
              : null;
          return PostDetailPage(postId: postId, initialPost: initialPost);
        },
      ),
      GoRoute(
        path: '/hashtags/:tag',
        name: 'hashtag',
        builder: (context, state) {
          final tag = state.pathParameters['tag']!;
          return HashtagPage(tag: tag);
        },
      ),
      GoRoute(
        path: '/connect/requests',
        name: 'connect-requests',
        builder: (context, state) => const ConnectRequestsPage(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
