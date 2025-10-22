# Phase 0 · Flutter Feature Audit

This note captures the current Flutter implementation at a high level so that each flow can be mapped to an equivalent SwiftUI module.

## High-Level Architecture
- `lib/app.dart` wires Riverpod providers, theming, localization, and the root router (`router.dart`).
- Riverpod (`flutter_riverpod`) is the primary state container; `Notifier` and `AsyncNotifier` types model feature logic.
- Navigation is handled by `go_router` with guards that depend on authentication state (`providers/router_provider.dart`).
- Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `firebase_analytics`) underpins auth, profiles, chat, push notifications, and metrics.
- Networking uses `dio` + cookie persistence to talk to a custom backend for profile management, matchmaking, subscriptions, and cultural content.
- Localization uses `easy_localization` with assets in `assets/translations/` (English, Dari, Pashto currently present).
- Shared UI is concentrated in `widgets/`, theming in `theme/`, and helper utilities in `core/` and `utils/`.

## Feature Modules (`lib/features`)
| Module | Key Responsibilities | Notable Dependencies | Swift Parity Targets |
| --- | --- | --- | --- |
| `auth/` | Email/password, Apple Sign In, OTP flows (phone), session bootstrap, profile fetching, Riverpod auth state machine. | `firebase_auth`, backend REST (`AuthRepository`), `shared_preferences` for tokens. | Swift `AuthFeature` with async/await, FirebaseAuth, Sign in with Apple, Keychain persistence. |
| `chat/` | Conversations list, real-time messaging, media uploads, typing indicators. | Firestore, Firebase Storage, web sockets. | Swift MessageKit-style UI, Firestore listeners, background push handling. |
| `compatibility/` | Questionnaire logic, scoring models, compatibility recommendations. | Custom JSON configs; `vector_math`; local caching. | Swift models + combine-based form flows; offline caching via CoreData. |
| `cultural/` | Articles, cultural tips, religious guidance sections. | Backend REST (`dio`), cached assets. | Swift list/detail views with RemoteConfig-driven content. |
| `engagement/` | Match nudges, notifications, in-app prompts. | Firebase Messaging, analytics, scheduling. | Swift NotificationCenter wrappers, on-device scheduling. |
| `icebreakers/` | Question catalog browsing, responses, randomizer, admin upload script. | Firestore collections, `icebreaker_data.json` seeding. | Swift data models + Firestore repository + snapshot tests. |
| `islamic_education/` | Educational modules, video/audio content, bookmarking. | Backend API, audio player (`just_audio`), downloads. | Swift AVKit integration, offline downloads via `URLSession`. |
| `profiles/` | Profile creation/editing, media management, verification, matching preferences. | Firebase Storage, REST, local validation. | SwiftUI multi-step forms, image picker, Vision for quality checks. |
| `safety/` | Reporting, blocking, account safety tips. | Firestore `reports`, backend endpoints. | Swift service to create reports, integrate with iOS safety guidelines. |
| `support/` | Help center, contact support, FAQ. | REST endpoints, deep links. | SwiftUI forms + Mail compose + web views. |

## Routing & Screens (`lib/screens`)
- `auth/`, `onboarding/`, `startup_screen.dart`, `splash_screen.dart` integrate with the router to direct the initial experience.
- `home/`, `main/` host the tabbed experience (dashboard, chat, discover, profile).
- `settings/` encapsulates account preferences, subscription management, legal docs.

## Shared Layers
- `core/analytics`, `core/config`, `core/errors`: cross-cutting services.
- `providers/`: global Riverpod providers (router, settings, analytics, remote config, environment).
- `utils/`: helpers for date formatting, permissions, device info, logging.
- `widgets/`: shared UI components (buttons, tag chips, cards, match indicators, skeleton loaders).

## Assets & Localization
- Fonts: `assets/fonts/Boldonse-Regular.ttf` (only weight available, used as both regular/bold).
- Images: under `assets/images/`, includes onboarding art, icons, placeholders.
- Translations: `.json` files under `assets/translations/` (English `en.json`, etc.).
- Icebreaker data: `icebreaker_data.json` seeds Firestore via `upload-icebreaker-questions.js`.

## Tooling Hooks
- `build_ios.sh` drives Flutter iOS builds via `fastlane` lanes in `fastlane/`.
- CI/CD uses Fastlane Match for certificates, Crashlytics for crash reporting, and Firebase App Distribution for pre-release.
- Scripts: `scripts/` folder contains migration and maintenance tasks (e.g., seeding users, cleaning caches).

## Open Questions / Follow-ups
1. Verify payment integration (Stripe vs. in-app purchases) – references appear in `features/engagement` and `profiles/subscriptions`, needs confirmation.
2. Determine how push notifications are orchestrated (Firebase Messaging vs. OneSignal) – inspect `providers/notifications_provider.dart` next.
3. Confirm analytics stack (Segment vs Firebase Analytics vs custom) through `core/analytics`.
4. Identify any platform-specific Flutter plugins that lack direct Swift equivalents (e.g., `record`, `emoji_picker_flutter`).

> This audit is a living document. Update it as deeper dives uncover additional modules or cross-cutting concerns.
