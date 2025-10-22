# Phase 0 · Data Model Notes · Authentication & Session

## AuthController Highlights (`lib/features/auth/auth_controller.dart`)
- Maintains `AuthState` (Riverpod Notifier) with fields `isAuthenticated`, `loading`, optional `profile`, optional `error`.
- Subscribes to `FirebaseAuth.instance.authStateChanges()` to react to token updates.
- `_bootstrap()` calls `AuthRepository.me()` to restore backend session, verifies Firebase user, then fetches profile JSON.
- Missing profile triggers `_handleMissingProfile()` which keeps the user signed in but surfaces a message.
- Email/password & Apple Sign-In call `AuthRepository` to hit backend, then repeat bootstrap to fetch profile.

## AuthRepository (`lib/features/auth/auth_repository.dart`)
- Uses `ApiClient.dio` for backend calls:
  - `signin(email, password)` → POST `/auth/login`.
  - `signInWithApple()` → POST `/auth/apple` (exchanges identity token).
  - `sendOtp`, `verifyOtp` for phone flows (likely Next.js endpoints).
  - `getProfile()` → GET `/profile/me` returning JSON consumed by `UserProfile.fromJson`.
  - `logout()` → POST `/auth/logout` clearing cookies.
- Stores minimal state; relies on cookies maintained by Dio + `PersistCookieJar`.

## AuthState (in `auth_state.dart`)
```dart
class AuthState {
  final bool isAuthenticated;
  final bool loading;
  final UserProfile? profile;
  final String? error;
}
```
- Swift equivalent should be `struct AuthState` with `enum Status { loading, unauthenticated, authenticated(profile) }` to match SwiftUI patterns.

## UserProfile Model (top of `models.dart`)
- Contains full user record: ids, names, demographics, lifestyle sections, verification flags, subscription status, etc.
- Some fields nested (CulturalProfile, LifestyleProfile, EducationProfile, etc.).
- Swift approach: create `UserProfile` struct with nested structs mirroring Flutter layout. Expose `UserProfile.Basic`, `UserProfile.Cultural`, and so on for readability.

## Session Persistence
- Backend uses cookies for server-side session; Flutter stores them via `PersistCookieJar` in temp directory.
- Future Swift app must adopt either token-based auth or implement `HTTPCookieStorage` bridging to maintain session for REST calls.
- Consider migrating backend to accept Firebase ID token (Bearer) to simplify native integration; `AuthTokenProvider` in `api_client.dart` hints at this plan.

## Error Handling & Messaging
- Flutter surfaces errors via `state.error` strings; display messages for missing profile, slow network, etc.
- Swift UI should map backend/Firestore errors to localized user-facing alerts.

## Follow-ups
1. Extract final `UserProfile` field list (the file extends beyond 900 lines) to ensure Swift Codable covers all sections.
2. Decide whether to consolidate authentication around Firebase-only or maintain cookie-backed backend session.
3. Verify push notification token registration flow in `auth_controller` (look for `registerDeviceToken`).
