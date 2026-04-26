# Firebase Setup (Local Only)

This repo intentionally **does not** commit Firebase project config files (bundle ids, project ids, api keys).

Ignored by `.gitignore`:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `.firebaserc`, `.firebase/`, `firebase-debug.log`

## 1) Create / select Firebase project

- Use Firebase Console to create/select a project (example: `link-ai-0749`).
- Register apps:
  - Android package: `com.nextfiction.linkai`
  - iOS bundle id: `com.nextfiction.linkai`

## 2) Add native config files

- Download `google-services.json` → place at `android/app/google-services.json`
- Download `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`

## 3) Generate FlutterFire options

Generate `lib/firebase_options.dart`:

```bash
flutterfire configure
```

This must match your registered Android/iOS ids.

## 4) (Optional) Admin access

Admin access in Firestore rules uses a custom claim (`request.auth.token.admin == true`).
Use the helper script in `functions/scripts/set-admin.js` to grant admin to a user uid/email (after you deploy Functions / have admin credentials configured).

