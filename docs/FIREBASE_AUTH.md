# Firebase Authentication Integration

This document describes how Firebase Auth was integrated into the Upfunda app, replacing the previous hardcoded user ID approach with proper token-based authentication.

## Overview

| Aspect | Detail |
|---|---|
| **Firebase Project** | `upfuna-academy` |
| **Auth Method** | Email + Password (phone OTP planned for Phase 2) |
| **Token Flow** | App → Firebase Auth → ID Token → Backend as Bearer token |
| **Env Management** | `.env` file loaded via `flutter_dotenv` |
| **Platforms** | Android, iOS, Web |

## Architecture

```
User enters credentials
        ↓
LoginScreen → AuthNotifier.login()
        ↓
FirebaseAuthService.signInWithEmailAndPassword()
        ↓
Firebase Auth SDK ←→ Firebase servers
        ↓
User object + ID token returned
        ↓
AuthNotifier updates AuthState (isLoggedIn, user)
        ↓
GoRouter redirect sends user to /student-home
        ↓
DioApiService attaches Bearer token to all API requests
```

## Files Changed / Created

### New Files

| File | Purpose |
|---|---|
| `.env` | Stores Firebase keys, API URL, Razorpay key (gitignored) |
| `.env.example` | Template with placeholder values for new developers |
| `lib/core/utils/env_config.dart` | Static getters for all env variables |
| `lib/data/services/firebase_auth_service.dart` | Wraps `FirebaseAuth` instance |
| `lib/firebase_options.dart` | Platform-specific `FirebaseOptions` from env |

### Modified Files

| File | What Changed |
|---|---|
| `pubspec.yaml` | Added `firebase_core`, `firebase_auth`, `flutter_dotenv`; `.env` as asset |
| `.gitignore` | Added `.env`, `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart` |
| `lib/main.dart` | Added `dotenv.load()` and `Firebase.initializeApp()` |
| `lib/providers/auth_provider.dart` | Full rewrite — Firebase sign-in, auth state stream, error mapping |
| `lib/data/services/dio_api_service.dart` | Dynamic base URL from env; Bearer token interceptor |
| `lib/data/services/api_service.dart` | Removed `loginWithPhone` method |
| `lib/data/services/mock_api_service.dart` | Removed `loginWithPhone` override |
| `lib/features/auth/login_screen.dart` | Calls Firebase email/password auth |
| `web/index.html` | Added Firebase JS SDK script tags |

## How Auth Works

### Login Flow

1. User enters email + password on `LoginScreen`
2. `AuthNotifier.login()` calls `FirebaseAuthService.signInWithEmailAndPassword()`
3. Firebase returns a `UserCredential` on success
4. `AuthNotifier` updates state: `isLoggedIn = true`, `user = credential.user`
5. GoRouter detects the auth state change and redirects to `/student-home`

### Session Persistence

Firebase Auth SDK automatically persists the auth session. On app restart:

1. `AuthNotifier` constructor subscribes to `FirebaseAuth.authStateChanges()` stream
2. If a previously signed-in user exists, Firebase emits the `User` object
3. The listener updates `AuthState` → user is logged in automatically

### API Calls

`DioApiService` has a Dio interceptor that:

1. Before each request, calls `FirebaseAuthService.getIdToken()`
2. Attaches the token as `Authorization: Bearer <token>` header
3. The backend validates the token and identifies the user

### Logout

1. `AuthNotifier.logout()` calls `FirebaseAuthService.signOut()`
2. Firebase clears the session and emits `null` on `authStateChanges()`
3. `AuthState` resets to default → GoRouter redirects to `/login`

## Environment Variables

All secrets are stored in `.env` at the project root:

```env
FIREBASE_API_KEY=...
FIREBASE_AUTH_DOMAIN=...
FIREBASE_PROJECT_ID=...
FIREBASE_STORAGE_BUCKET=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_APP_ID=...
FIREBASE_MEASUREMENT_ID=...
API_BASE_URL=...
RAZORPAY_KEY_ID=...
```

The `.env` file is:
- Loaded in `main.dart` before `Firebase.initializeApp()`
- Read by `EnvConfig` static getters (e.g., `EnvConfig.firebaseApiKey`)
- Listed as an asset in `pubspec.yaml`
- **Gitignored** — never committed to the repository

## Android / iOS Native Setup

### Current State (Web Only)

Firebase is fully configured for **Web** using environment variables. Android and iOS are configured with the same web values as a placeholder.

### To Enable Android / iOS

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Run FlutterFire configure:
   ```bash
   flutterfire configure --project=upfuna-academy
   ```

3. This generates:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - Updates `lib/firebase_options.dart` with native platform options

4. The generated files are gitignored. Each developer must run `flutterfire configure` or obtain copies from a team lead.

## Phone OTP Auth (Phase 2 — Not Yet Implemented)

Firebase Auth does not support a combined phone + password flow. The current phone login mode creates a synthetic email (`{phone}@phone.upfunda.com`). A proper phone OTP flow would require:

1. Enable "Phone" provider in Firebase Console → Authentication → Sign-in method
2. Add SHA-1/SHA-256 fingerprint for Android
3. Call `FirebaseAuth.instance.verifyPhoneNumber()` which sends an OTP
4. Verify the OTP with `PhoneAuthProvider.credential()`
5. Sign in with the credential

## Adding a New Auth Provider (e.g., Google Sign-In)

1. Enable the provider in Firebase Console → Authentication → Sign-in method
2. Add the Flutter package (e.g., `google_sign_in`)
3. Add a method to `FirebaseAuthService`:
   ```dart
   Future<UserCredential> signInWithGoogle() async {
     final googleUser = await GoogleSignIn().signIn();
     final googleAuth = await googleUser!.authentication;
     final credential = GoogleAuthProvider.credential(
       accessToken: googleAuth.accessToken,
       idToken: googleAuth.idToken,
     );
     return _auth.signInWithCredential(credential);
   }
   ```
4. Call it from `AuthNotifier` the same way `signInWithEmailAndPassword` is called
5. The Dio interceptor will automatically attach the ID token — no backend changes needed

## Error Handling

`AuthNotifier._mapFirebaseError()` maps Firebase error codes to user-friendly messages:

| Firebase Code | User Message |
|---|---|
| `user-not-found` | No account found with this email |
| `wrong-password` / `invalid-credential` | Incorrect email or password |
| `invalid-email` | Please enter a valid email address |
| `user-disabled` | This account has been disabled |
| `too-many-requests` | Too many attempts. Please try again later |
| `network-request-failed` | Network error. Check your connection |
| (other) | Sign in failed. Please try again |
