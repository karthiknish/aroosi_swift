# Native iOS Project Setup

This guide walks through bootstrapping the `AroosiSwift` Xcode workspace and wiring it to the Swift package in this directory.

## Prerequisites
- Xcode 15.4+
- CocoaPods (only if additional pods beyond SPM are required)
- SwiftLint (`brew install swiftlint`) and SwiftFormat (`brew install swiftformat`)
- Fastlane (`bundle install` from repo root once Gemfile is updated)

## 1. Create the Xcode Workspace & App Target
1. Open Terminal and run:
   ```bash
   cd "$(git rev-parse --show-toplevel)/aroosi_swift/native_ios"
   mkdir -p Workspace
   open .
   ```
2. In Xcode, create a new **App** project:
   - Product Name: `AroosiSwift`
   - Team: (select Apple developer team)
   - Organization Identifier: `com.aroosi`
   - Interface: SwiftUI
   - Language: Swift
   - Include Tests: checked
   - Save inside `native_ios/Workspace/AroosiSwift`
3. Delete the auto-generated `ContentView.swift`/`AroosiSwiftApp.swift` as the Swift package already provides `RootView`.
4. Add the Swift package:
   - File → Add Packages… → `Add Local…` and choose `native_ios/Package.swift`.
   - Add product `AroosiKit` to the app target.
5. Link host files:
   - Drag `native_ios/AppHost/AroosiApp.swift` and `AppHost/AppDelegate.swift` into the app target (ensure “Copy items if needed” is **unchecked**).
6. Update the app target’s info plist to reference configuration files:
   - Set `INFOPLIST_FILE` to `AppHost/Supporting/Info.plist` once created.
   - Assign `Debug.xcconfig`, `Staging.xcconfig`, `Release.xcconfig` in the Build Settings → `Per-Configuration Build Settings`.

## 2. Configure Firebase
1. Add the correct `GoogleService-Info.plist` under `AppHost/Supporting/` for each environment (Debug/Release variants).
2. Enable required capabilities: Sign in with Apple, Push Notifications, Background Modes (remote notifications), Keychain sharing if needed.
3. Confirm `FirebaseApp.configure()` in `AppDelegate` executes before other services.

## 3. Linting & Formatting
- Add build phases:
  1. **SwiftLint**: `if which swiftlint >/dev/null; then swiftlint --config .swiftlint.yml; else echo "warning: SwiftLint not installed"; fi`
  2. **SwiftFormat** (optional as pre-commit): `if which swiftformat >/dev/null; then swiftformat --config .swiftformat Sources AppHost; fi`

## 4. Fastlane Integration
1. Run `bundle init` (if not already) and add `gem 'fastlane'`.
2. From `native_ios/fastlane`, execute `bundle exec fastlane test` to verify lane (once workspace exists).
3. Populate `fastlane/Appfile` with real Apple IDs and team identifiers.
4. Add environment variables for App Store Connect API keys in CI (see `.github/workflows/` in Flutter project as reference).

## 5. Continuous Integration
- Extend existing GitHub Actions or create `native_ios.yml` to:
  - Check out repo → install SwiftLint/SwiftFormat.
  - Run `xcodebuild test -workspace AroosiSwift.xcworkspace -scheme AroosiSwift -destination "platform=iOS Simulator,name=iPhone 15"`.
  - Archive for TestFlight on demand using Fastlane lanes.

## 6. Next Steps After Bootstrap
- Wire Sign in with Apple end-to-end (validate both the SwiftUI sheet and `FirebaseAuthService.presentSignIn(from:)` paths) before layering phone OTP or other factors.
- Port feature slices (e.g., Onboarding, Profiles) incrementally, using the documented data models in `docs/ios-migration/phase0`.
- Mirror analytics/events and push notification handling from the Flutter app.

> Keep this document updated as the native project evolves (e.g., when adding new targets like Widget extensions or watchOS companions).
