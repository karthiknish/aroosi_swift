# Phase 0 · Data Model Notes · Safety & Support

## Safety Flows (Reporting & Blocking)
Source: `lib/features/safety/safety_repository.dart`, `lib/core/firebase_service.dart`
- SafetyRepository wraps `FirebaseService` helpers to report, block, unblock users and list blocked accounts.
- Methods:
  - `reportUser(userId, reason, details?)` → writes to Firestore `reports` collection (via `FirebaseService.reportUser`). Returns map with `success` flag and message/error string.
  - `blockUser(userId)` / `unblockUser(userId)` → manipulates Firestore `blocks` collection.
  - `getBlockedUsers()` → returns array of maps from Firestore.
  - `isBlocked(userId)` → helper to check block status (currently only checks self-blocked; `isBlockedBy` placeholder false).
- **Swift Migration**:
  - Create `SafetyRepository` using Firebase iOS SDK; define async methods returning typed structs (`SafetyActionResult` with `status`, `message`).
  - Use `Firestore` access via `CollectionReference` wrappers. Provide concurrency-safe operations using `async/await`.
  - Implement symmetric check to determine if current user is blocked by another user (requires rule/back-end support).

## Support Requests
Source: `lib/features/support/support_repository.dart`
- Submits support/contact forms to multiple possible endpoints (`/support/contact`, `/support`, `/help/contact`, `/contact`).
- Tries multiple payload shapes to maintain compatibility with legacy backend variations.
- Returns true on first 2xx response; otherwise false.
- **Swift Migration**:
  - Provide `SupportRepository` with `submitContact(message, email?, subject?, category?, metadata?)`.
  - Attempt prioritized endpoint list; consider centralizing request building with typed `SupportPayload` struct.
  - Add logging for failure cases through shared Logger; surface user-friendly error message to UI.
  - Evaluate backend consolidation—if native app can rely on a single endpoint, simplify logic and coordinate with backend team.

## FirebaseService Responsibilities (partial)
- Auth: email/password, Apple sign-in, password reset, sign-out, delete.
- Firestore accessors for `users`, `profiles`, `conversations`, `matches`, `interests`, `reports`, `blocks`, etc.
- Profile CRUD, search, match retrieval, chat operations, storage uploads (images/audio), device token registration.
- **Swift Plan**: break into scoped services (AuthService, ProfileService, MessagingService) to avoid monolithic class. Use dependency injection to keep testable.

## Follow-ups
1. Review remaining portions of `firebase_service.dart` to map chat, storage, and notification methods into Swift modules.
2. Confirm Firestore security rules support the expected client operations (see `data-contracts.md`).
3. Define error handling strategy for Firestore operations (map to typed errors vs generic strings).
