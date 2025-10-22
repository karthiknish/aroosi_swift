# Phase 0 · Dependency Inventory

This inventory enumerates key Flutter dependencies and the expected native iOS counterpart or migration notes.

## Runtime Dependencies (pubspec.yaml)
| Package | Purpose | Swift Counterpart / Plan |
| --- | --- | --- |
| `flutter_riverpod` | Global state management via Notifier/Provider. | Adopt SwiftUI + `@Observable` / `ObservableObject`; evaluate The Composable Architecture if additional structure required.
| `go_router` | Declarative routing/navigation. | SwiftUI `NavigationStack` with custom Router abstraction; deep link handling via `UIApplicationDelegate`.
| `dio` + `dio_cookie_manager` | REST client with interceptors, cookie persistence. | Implement async/await `URLSession` client with request interceptors; handle cookies via `HTTPCookieStorage`.
| `shared_preferences` | Local key/value cache for tokens and flags. | Use `UserDefaults` or Keychain (for sensitive data).
| `flutter_dotenv` | Environment variable loading from `.env`. | Ship `Config/Secrets.plist`; parse via `PropertyListSerialization`.
| `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `firebase_analytics` | Firebase services. | Integrate official Firebase iOS SDKs via Swift Package Manager.
| `firebase_localizations` | Flutter localization integration. | Use native `.strings` with `Bundle.main.localizedString` and `SwiftGen`.
| `just_audio`, `record` | Audio playback and recording (voice notes). | Adopt `AVAudioRecorder`/`AVAudioEngine` and `AVPlayer`.
| `image_picker`, `emoji_picker_flutter` | Media selection, emoji selection. | Use `PHPickerViewController`; integrate `EmojiKit` or custom list.
| `app_tracking_transparency` | ATT prompt. | Utilize `ATTrackingManager` on iOS.
| `permission_handler` | Permission flow abstraction. | Create PermissionManager layering over `AVAuthorizationStatus`, `CLAuthorizationStatus`, etc.
| `web_socket_channel` | Real-time updates (chat). | Use `URLSessionWebSocketTask` or Firebase listeners.
| `google_fonts` | Custom font loading. | Ship fonts via asset catalog.
| `intl`, `easy_localization` | Formatting utilities & i18n. | Use `Foundation` formatters, `Locale`, `.stringsdict` for pluralization.
| `uuid` | ID generation. | Use `UUID().uuidString`.
| `url_launcher` | External deep links. | Use `UIApplication.shared.open` APIs.
| `package_info_plus` | App version info. | Use `Bundle.main`.
| `firebase_crashlytics` (implied via Firebase) | Crash reporting. | Add Crashlytics SPM target.
| `sign_in_with_apple` | Apple authorization. | Native `AuthenticationServices`.
| `pallete_generator` | Dominant color extraction. | Use `UIImageColors` or custom CoreImage pipeline.
| `firebase_local_notifications` | Local notification scheduling. | Use `UNUserNotificationCenter`.

## Dev Dependencies
- `flutter_test`, `mockito`: Unit testing/mocking; map to XCTest + XCTestExpectations + Cuckoo or native test doubles.
- `firebase_core_platform_interface`: ensures compatibility in Flutter tests; no native analog needed.

## Scripts & Tooling
- `fastlane/`: Contains lanes for build, test, deploy; reuse by creating native lanes referencing new Xcode workspace.
- `build_ios.sh`: Orchestrates Flutter iOS build; adapt to call `xcodebuild` once native target exists.
- `scripts/`: Node/TS utilities for seeding data (e.g., `upload-icebreaker-questions.js`); keep for server-admin tasks.

## External Services
- **Firebase project** (GoogleService-Info plist copies present).
- **Segment / Analytics**: confirm via `core/analytics` implementation.
- **Push notifications**: APNs via Firebase Cloud Messaging.
- **Payments**: To be validated (search for Stripe/Razorpay references).

## Follow-ups
1. Validate missing native equivalents for smaller packages (`palette_generator`, custom emoji picker) to ensure parity.
2. Confirm backend base URLs and authentication mechanisms (`lib/core/config/environment.dart`).
3. Determine if any platform channels exist that require new Swift bridging logic.
