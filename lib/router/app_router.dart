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
import '../features/profile/presentation/pages/saved_items_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/pages/app_store_pages.dart';
import '../features/admin/presentation/pages/admin_settings_page.dart';
import '../features/admin/presentation/pages/admin_reports_page.dart';
import '../features/admin/presentation/providers/admin_providers.dart';
import '../features/feed/presentation/pages/create_post_page.dart';
import '../features/feed/presentation/pages/post_detail_page.dart';
import '../features/main/presentation/pages/main_shell_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/messaging/presentation/pages/inbox_page.dart';
import '../features/messaging/presentation/pages/conversation_page.dart';
import '../features/messaging/data/models/conversation_model.dart';
import '../features/feed/data/models/post_model.dart';
import '../features/explore/presentation/pages/hashtag_page.dart';
import '../features/explore/presentation/pages/search_page.dart';
import '../features/network/presentation/pages/network_page.dart';
import '../features/products/data/models/product_model.dart';
import '../features/products/presentation/pages/create_product_page.dart';
import '../features/products/presentation/pages/edit_product_page.dart';
import '../features/products/presentation/pages/product_detail_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/onboarding/presentation/providers/onboarding_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final adminStatus = ref.watch(adminStatusProvider);
  final shouldShowOnboarding = ref.watch(shouldShowOnboardingProvider);

  return GoRouter(
    initialLocation: '/feed',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRemoteDataSourceProvider).authStateChanges(),
    ),
    redirect: (context, state) {
      try {
        final user = authState.asData?.value;
        final isLoggedIn = user != null;

        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        final isAdminRoute = state.matchedLocation.startsWith('/admin');
        final isOnboardingRoute = state.matchedLocation == '/onboarding';
        final isEditProfileRoute = state.matchedLocation == '/profile/edit';

        // Handle auth state loading
        if (authState.isLoading) {
          return null;
        }

        // Handle auth state errors
        if (authState.hasError) {
          return '/login';
        }

        // Redirect unauthenticated users to login
        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }

        // Redirect authenticated users away from auth routes
        if (isLoggedIn && isAuthRoute) {
          return '/feed';
        }

        // Handle onboarding
        if (isLoggedIn && !isOnboardingRoute && !isEditProfileRoute) {
          try {
            if (shouldShowOnboarding) {
              return '/onboarding';
            }
          } catch (e) {
            // Silently fail onboarding check and continue
            debugPrint('Onboarding check error: $e');
          }
        }

        // Handle admin access control
        if (isAdminRoute) {
          if (adminStatus.isLoading) {
            return null;
          }

          if (adminStatus.hasError) {
            return '/feed';
          }

          final isAdmin = adminStatus.asData?.value == true;
          if (!isAdmin) {
            return '/feed';
          }
        }

        return null;
      } catch (e) {
        // On any redirect error, default to login for safety
        debugPrint('Router redirect error: $e');
        return '/login';
      }
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
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const MainShellPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(showBackButton: true),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/profile/saved',
        name: 'saved-items',
        builder: (context, state) => const SavedItemsPage(),
      ),
      GoRoute(
        path: '/profiles/:uid',
        name: 'public-profile',
        builder: (context, state) {
          try {
            final uid = state.pathParameters['uid'];
            if (uid == null || uid.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Invalid user ID.')),
              );
            }
            return PublicProfilePage(uid: uid);
          } catch (e) {
            return Scaffold(
              body: Center(child: Text('Error loading profile: $e')),
            );
          }
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportPage(),
      ),
      GoRoute(
        path: '/legal/privacy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/legal/terms',
        name: 'terms-of-use',
        builder: (context, state) => const TermsOfUsePage(),
      ),
      GoRoute(
        path: '/legal/guidelines',
        name: 'community-guidelines',
        builder: (context, state) => const CommunityGuidelinesPage(),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'admin-settings',
        builder: (context, state) => const AdminSettingsPage(),
      ),
      GoRoute(
        path: '/admin/reports',
        name: 'admin-reports',
        builder: (context, state) => const AdminReportsPage(),
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
          try {
            final postId = state.pathParameters['postId'];
            if (postId == null || postId.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Invalid post ID.')),
              );
            }
            final initialPost = state.extra is PostModel
                ? state.extra as PostModel
                : null;
            return PostDetailPage(postId: postId, initialPost: initialPost);
          } catch (e) {
            return Scaffold(
              body: Center(child: Text('Error loading post: $e')),
            );
          }
        },
      ),
      GoRoute(
        path: '/hashtags/:tag',
        name: 'hashtag',
        builder: (context, state) {
          try {
            final tag = state.pathParameters['tag'];
            if (tag == null || tag.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Invalid hashtag.')),
              );
            }
            return HashtagPage(tag: tag);
          } catch (e) {
            return Scaffold(
              body: Center(child: Text('Error loading hashtag: $e')),
            );
          }
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return SearchPage(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/network',
        name: 'network',
        builder: (context, state) => const NetworkPage(),
      ),
      GoRoute(
        path: '/products/create',
        name: 'create-product',
        builder: (context, state) => const CreateProductPage(),
      ),
      GoRoute(
        path: '/products/:productId',
        name: 'product-detail',
        builder: (context, state) {
          try {
            final productId = state.pathParameters['productId'];
            if (productId == null || productId.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Invalid product ID.')),
              );
            }
            return ProductDetailPage(productId: productId);
          } catch (e) {
            return Scaffold(
              body: Center(child: Text('Error loading product: $e')),
            );
          }
        },
      ),
      GoRoute(
        path: '/products/:productId/edit',
        name: 'edit-product',
        builder: (context, state) {
          try {
            final productId = state.pathParameters['productId'];
            if (productId == null || productId.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Invalid product ID.')),
              );
            }
            final extra = state.extra;
            if (extra is! ProductModel) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'Missing product data. Please go back and try again.',
                  ),
                ),
              );
            }
            return EditProductPage(product: extra);
          } catch (e) {
            return Scaffold(
              body: Center(child: Text('Error loading product: $e')),
            );
          }
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/messages',
        name: 'messages',
        builder: (context, state) => const InboxPage(),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        name: 'conversation',
        builder: (context, state) {
          final convId = state.pathParameters['conversationId']!;
          final extra = state.extra as ConversationModel?;
          return ConversationPage(
            conversationId: convId,
            initialConversation: extra,
          );
        },
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
