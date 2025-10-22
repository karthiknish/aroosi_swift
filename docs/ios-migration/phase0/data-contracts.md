# Phase 0 · Data Contract Notes

## Firestore Collections (from `firebase/firestore.rules`)
| Collection | Purpose | Key Fields | Notes for Swift |
| --- | --- | --- | --- |
| `users` | Private user profile & preferences. | `isPublic`, `role`, onboarding state. | Guard reads by UID; create `UserPrivate` model. |
| `profiles` | Public facing profile cards shown to matches. | `name`, `age`, `gender`, cultural attributes, media references. | Build `ProfilePublic` struct; ensure validation mirrors `isValidProfileData`. |
| `conversations` | Chat thread metadata. | `participants` array (2), `lastMessage`, `updatedAt`. | Repository should enforce 2 participants; combine with subcollection `messages`. |
| `conversations/{conversationId}/messages` | Individual messages. | `text`, `fromUserId`, attachments, timestamps. | Use listener with structured models; enforce length <= 1000. |
| `matches` | Match statuses between users. | `userId`, `matchedUserId`, status timestamps. | Determine if derived from `interests`; add dedup logic. |
| `interests` | Expressions of interest (likes). | `fromUserId`, `toUserId`, `status`. | Align with `isValidInterestCreate`. |
| `reports` | Safety reports. | `reporterId`, `reportedUserId`, `reason`. | Admin-only read; ensure Swift app only creates. |
| `blocks` | Blocked user list. | `blockerId`, `blockedUserId`. | Provide local cache for quick lookups. |
| `users/{userId}/shortlist` | Bookmarked matches. | `shortlistedUserId` documents. | Nest under user-specific repository. |
| `icebreaker_questions` | Question catalog. | `text`, `category`, `weight`, `active`. | Read-only for clients; seed updates via admin script. |
| `icebreaker_answers` | User-submitted answers. | `userId`, `questionId`, `answer`. | Restrict to owner for reads/writes. |

## Seed Data (`icebreaker_data.json`)
- Contains 20 starter questions with `id`, `text`, `category`, `weight`, `createdAt/updatedAt` timestamps.
- Swift migration should provide Codable structs and a seeding utility for offline preview/testing.

## Backend REST Endpoints
- `core/api_client.dart` uses `Env.apiBaseUrl` with endpoints such as `/auth/login`, `/profile/me`, `/matches`, `/compatibility/scores` (confirm by scanning repository).
- Cookies are currently used for session persistence. Swift client must migrate to token-based or maintain cookie jar using `HTTPCookieStorage`.
- `.env` toggles `API_BASE_URL` and `SUBSCRIPTIONS_ENABLED` – replicate through `Config/*.xcconfig` and runtime plist.

## Authentication Flow
1. Email/password or Apple Sign In obtains Firebase ID token.
2. Backend `/auth/session` validated via `AuthRepository` (`lib/features/auth/auth_repository.dart`).
3. User profile fetched via `/profile/me` returning JSON consumed by `UserProfile.fromJson`.
4. Missing profile triggers forced onboarding (Flutter surfaces `_missingProfileError`).

## Push & Messaging
- `push_notification_service.dart` registers device tokens with backend, handles topic subscriptions.
- `firebase_messaging` is used for FCM token refresh; Swift counterpart must bridge APNs token to FCM.

## Analytics
- `core/analytics_service.dart` wraps Firebase Analytics and conditionally Segment (needs confirmation). Events include onboarding completion, interest sent, match created, message sent.

## Follow-ups
1. Export JSON schemas for REST responses (look into `lib/features/*/models/` for existing Dart models).
2. Decide how to map Firestore timestamps (`Timestamp`) to Swift `Date` using `FirebaseFirestoreSwift`.
3. Confirm any custom cloud functions or triggers that impact client assumptions.
