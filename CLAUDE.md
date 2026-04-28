# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**LinkAI** is a professional networking app for AI builders (founders, freelancers, learners). Users create profiles, share projects ("builds"), discover connections, send requests, and potentially collaborate. The app emphasizes quality introductions over noisy social feeds.

**Tech Stack:**
- Frontend: Flutter (Clean Architecture, feature-first modules)
- State Management: Riverpod with `@riverpod` annotations
- Backend: Firebase (Auth, Firestore, Storage, Cloud Functions, FCM)
- Models: Freezed + JSON serializable
- Routing: GoRouter
- Notable packages: `cached_network_image`, `shimmer`, `flutter_riverpod`, `riverpod_annotation`, `freezed_annotation`

---

## Architecture & Code Organization

### Folder Structure (Feature-First + Clean Architecture)

```
lib/
├── core/
│   ├── constants/        # App sizes, strings, limits
│   ├── theme/           # AppTheme, ThemeColors, theme providers
│   ├── widgets/         # Reusable: AppLoader, AppUserAvatar, AppEmptyState
│   └── config/          # App configuration (e.g., app_limits)
├── features/            # Feature modules (auth, feed, profile, products, connect, explore, etc.)
│   ├── auth/
│   │   ├── data/        # Auth remote datasource, repositories
│   │   └── presentation/# Auth UI (login, register), auth providers
│   ├── feed/
│   │   ├── data/        # Post models, Firestore queries
│   │   └── presentation/# Feed pages, post cards, widgets
│   ├── profile/
│   ├── products/        # Product showcase (app store-like)
│   ├── connect/         # Follow/unfollow, relationship status, ping notifications
│   ├── explore/         # Discover by hashtags and topics
│   ├── notifications/   # Push + in-app notifications
│   ├── settings/        # User preferences, account management
│   └── admin/           # Admin-only panel (global settings, limits)
├── router/              # GoRouter configuration & routes
├── app/                 # Main app widget (LinkAiApp)
└── main.dart            # Entry point, Firebase init
```

### Clean Architecture Layers

Each feature follows **data → domain → presentation**:

- **data/**: Firestore datasources, repositories, models (Freezed)
- **domain/**: Business logic (not used in current MVP; logic lives in providers)
- **presentation/**: Pages, widgets, providers (Riverpod with `@riverpod`)

### State Management (Riverpod)

- Use `@riverpod` annotation on async functions (auto-generates providers)
- Providers are defined alongside their data (typically in `presentation/providers/`)
- Controllers use `StateNotifier` for mutations (e.g., `authControllerProvider`)
- Always use `.asData?.value` to safely extract data from `AsyncValue`

**Pattern:**
```dart
@riverpod
class MyController extends StateNotifier<AsyncValue<MyState>> {
  // ...
}

final myControllerProvider = StateNotifierProvider<MyController, AsyncValue<MyState>>(
  (ref) => MyController(/* deps */),
);
```

### Models & Serialization

- Models use `@freezed` for immutability
- Implement `.fromJson` / `.toJson` via `@JsonSerializable`
- Example: `PostModel`, `ProfileModel`, `ConnectionModel`

### Firebase Integration

**Auth:**
- `authRemoteDataSourceProvider` watches Firebase Auth state
- `authStateProvider` exposes current `User` or `null`
- `authControllerProvider` handles login/register/logout

**Firestore:**
- Datasources call Firestore collections directly (no ORM layer)
- Queries return streams for real-time updates
- Use security rules to enforce data access

**Storage:**
- Avatars, post media, product screenshots uploaded to `/avatars/{uid}` and `/media/{id}` paths
- URLs stored in Firestore; Flutter displays via `CachedNetworkImage`

**Cloud Functions:**
- Called via `httpsCallable` (e.g., `sendPing`, future AI features)
- Handle server-side logic: notifications, rate limiting, OpenAI calls
- Deployed separately: `firebase deploy --only functions`

---

## Development Workflow

### Setup

1. **Install Flutter & dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure Firebase** (local-only config, see `FIREBASE_SETUP.md`):
   ```bash
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` (not in git).

3. **Build code generation (Riverpod, Freezed, JSON serializable):**
   ```bash
   dart run build_runner build
   # or watch mode:
   dart run build_runner watch
   ```

### Running

- **Debug build:**
  ```bash
  flutter run
  ```

- **Release build (iOS):**
  ```bash
  flutter build ios --release
  ```

- **Release build (Android):**
  ```bash
  flutter build apk --release
  # or app bundle:
  flutter build appbundle --release
  ```

### Testing & Analysis

- **Run all tests:**
  ```bash
  flutter test
  ```

- **Run a specific test file:**
  ```bash
  flutter test test/features/auth/login_test.dart
  ```

- **Lint analysis:**
  ```bash
  flutter analyze
  ```

- **Format code:**
  ```bash
  dart format lib/
  ```

### Cloud Functions (Backend)

- **Located in:** `functions/` directory (Node.js + TypeScript)
- **Build & serve locally:**
  ```bash
  cd functions
  npm run serve
  ```

- **Deploy functions:**
  ```bash
  firebase deploy --only functions
  ```

- **View logs:**
  ```bash
  firebase functions:log
  ```

---

## Key Patterns & Conventions

### Widget States

- **StatelessWidget / ConsumerWidget:** For simple, reactive UI
- **ConsumerStatefulWidget:** When local state + Riverpod deps needed
- Use `ref.watch(provider)` to subscribe to state
- Use `ref.read(controllerProvider.notifier)` to mutate state

### Async Data Handling

Always use `.when()` for `AsyncValue`:
```dart
state.when(
  data: (value) => YourWidget(value),
  loading: () => const AppLoader(),
  error: (error, stack) => ErrorWidget(),
)
```

### Theme & Colors

- Light & dark themes defined in `lib/core/theme/app_theme.dart`
- Custom colors (border, mutedText, surfaceMuted) via `AppThemeColors` extension
- Access via `context.appColors` or `Theme.of(context).colorScheme`
- Text styles from `Theme.of(context).textTheme` (pre-configured in theme)

### Images

- Use `CachedNetworkImage` for all remote images (caching + proper rendering)
- Use `FilterQuality.high` for sharp display
- Provide placeholder & error widgets
- Local assets: none currently; add to `pubspec.yaml` if needed

### Navigation

- Routes defined in `router/app_router.dart`
- Use `context.push(path)` and `context.go(path)` via GoRouter
- Pass data via `extra` parameter: `context.push('/posts/${id}', extra: post)`

---

## Important Implementation Notes

### Profile System

- Users complete profiles in `edit_profile_page.dart` with: name, role, bio, location, skills, tools, links, building, need, wantToMeet
- Public profiles viewable at `/profiles/{uid}` (public_profile_page.dart)
- Self profile at `/profile` (profile_page.dart) shows edit button
- Profile tabs: Posts, Likes, Comments, Hashtags (lazy-loaded via providers)

### Posts & Feed

- Posts stored in Firestore `posts` collection
- Three feed tabs: **Latest** (newest), **Connected** (from users you follow), **Viral** (score-based)
- Comments are flat (no nesting); stored in `postComments` collection
- Media per post uploaded to Storage; URLs stored in post doc

### Follow / Relationship Model

- **Single model:** Simple follow/unfollow system (no request acceptance flow)
- `ConnectRelationshipStatus` enum: `none`, `connected` (pending states removed)
- Follows stored in Firestore `connections` collection with structure: `{id, userUid, connectedUid, createdAt}`
- "Ping" button (active only when `connected`) sends notification via `sendPing` Cloud Function
- Links in profile are tap-to-open (via `url_launcher`), long-press-to-copy (via `Clipboard`)

### Products (App Store-like)

- Products have: name, tagline, description, category, pricing, version, platforms, tags, screenshots, owner info
- Stored in `products` Firestore collection
- Users can save products (similar to posts)
- Product detail page at `/products/{id}`

### Settings & Notifications

- Global app config (limits, feature flags) stored in Firestore `appConfig/global`
- User-specific settings in `userSettings` Firestore doc (notification toggles, preferences)
- Push notifications via Firebase Cloud Messaging (FCM)
- Local notifications via `flutter_local_notifications`

### Admin Panel

- Admin-only features gated by `adminStatusProvider` (checks Firestore custom claims)
- Admins can edit global limits, feature flags, and throttles via `/admin/settings`

---

## Important Files & Their Roles

| File | Purpose |
|------|---------|
| `lib/main.dart` | Firebase init, ProviderScope, app entry |
| `lib/app/link_ai_app.dart` | Root widget, theme/router setup |
| `lib/router/app_router.dart` | All routes & navigation redirects |
| `lib/core/theme/app_theme.dart` | Light & dark theme definitions |
| `lib/core/widgets/app_loader.dart` | Animated gradient loader (used everywhere) |
| `lib/features/auth/presentation/providers/auth_providers.dart` | Auth state + controller |
| `lib/features/feed/data/datasources/post_remote_datasource.dart` | Firestore post queries |
| `lib/features/profile/presentation/widgets/profile_view.dart` | Profile UI (reused by self + public) |
| `lib/features/connect/presentation/widgets/connect_button.dart` | Connect/Ping button logic |
| `functions/src/index.ts` | Cloud Function entry point |
| `firestore.rules` | Firestore security rules |
| `firestore.indexes.json` | Composite index definitions |

---

## Common Tasks

### Adding a New Post-Like Entity

1. Create model in `features/{entity}/data/models/{entity}_model.dart` (Freezed + JSON serializable)
2. Create remote datasource in `features/{entity}/data/datasources/{entity}_remote_datasource.dart`
3. Create providers in `features/{entity}/presentation/providers/{entity}_providers.dart`
4. Create UI pages/widgets
5. Add routes in `router/app_router.dart`

### Adding a Firestore Query

1. Define in datasource (e.g., `watchPostsByAuthorProvider`)
2. Wrap in Riverpod provider (usually `@riverpod` async function)
3. Use `.when()` in UI to handle loading/error/data states

### Adding Admin-Only Settings

1. Add field to Firestore `appConfig/global` doc
2. Create provider to read/write config (e.g., `appConfigProvider`)
3. Add UI in `features/admin/presentation/pages/admin_settings_page.dart`
4. Enforce server-side in Cloud Functions & Firestore Rules

### Handling Images

- Always use `CachedNetworkImage` with `FilterQuality.high`
- For local file selection: use `image_picker`
- Upload to Firebase Storage via datasource
- Store URL in Firestore; fetch via `CachedNetworkImage`

---

## Testing & Code Quality

- **Tests location:** `test/` directory (mirrors `lib/` structure)
- **Test patterns:** Use Riverpod test utilities, mock Firebase via test helpers
- **Linting:** Follows `analysis_options.yaml`; run `flutter analyze` before commit
- **Code generation:** Always run `dart run build_runner build` after editing Freezed/Riverpod code

---

## Deployment

### Firebase Hosting & Functions

- **Deploy everything:**
  ```bash
  firebase deploy
  ```

- **Deploy only functions:**
  ```bash
  firebase deploy --only functions
  ```

- **Deploy only Firestore rules:**
  ```bash
  firebase deploy --only firestore:rules
  ```

### App Store / Play Store

- **iOS:** Build with Xcode or `flutter build ios --release`; submit via App Store Connect
- **Android:** Build AAB (`flutter build appbundle --release`) and submit via Google Play Console
- **Version management:** Update `pubspec.yaml` version and `ios/Runner/GeneratedPluginRegistrant.m` before each release

---

## Known Issues & TODOs

- **Search icons** in Feed and Products are placeholders (`onPressed: () {}`) — need real search implementation
- **Messaging/Chat** is planned but not implemented (only connection requests exist)
- **Onboarding flow** does not enforce profile completion after signup
- **Profile cleanup** on account deletion is incomplete; scheduled for Cloud Functions

---

## Useful References

- **Flutter Docs:** https://docs.flutter.dev
- **Riverpod Docs:** https://riverpod.dev
- **Firebase Docs:** https://firebase.google.com/docs
- **GoRouter Docs:** https://pub.dev/packages/go_router
- **Firestore Rules Guide:** https://firebase.google.com/docs/firestore/security/rules-structure
- **Local setup:** See `FIREBASE_SETUP.md` and `functions/` README for backend config
