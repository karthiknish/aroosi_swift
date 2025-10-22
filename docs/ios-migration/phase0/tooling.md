# Phase 0 · Tooling & Automation Notes

## Build Scripts
- `build_ios.sh`: wraps `flutter build ios` with a workaround disabling `FLUTTER_NATIVE_ASSETS` for Flutter 3.35.4; supports `debug`, `profile`, `release` (advises profile). Native app will need equivalent shell or Fastlane lane invoking `xcodebuild`.
- `scripts/`: Node scripts (e.g., `upload-icebreaker-questions.js`) for Firebase seeding; keep for admin tasks. Review for any automation to port.

## Fastlane
- Copied project contains `fastlane/metadata/` only—no `Fastfile` present. Original repository likely maintained lanes elsewhere; confirm with product team. New Swift app needs dedicated lanes for build, test, beta deploy, App Store submission.
- `Gemfile` present; bundler expected for Fastlane dependencies (`fastlane`, `cocoapods`). Update once native lanes defined.

## Continuous Integration (GitHub Actions)
- `.github/workflows/ci.yml`: Flutter CI running on pushes/PRs to `main`/`develop`.
  - Installs Flutter 3.35.4, creates `.env`, caches `pub`, Gradle, CocoaPods, Ruby gems.
  - Jobs: `quality` (test, analyze, format check) + `build-ios` (debug IPA artifact). Plan to retire the Flutter workflow once the native iOS app fully replaces it.
  - Uses App Store Connect API keys (ASC_* secrets) for potential signing.
- Additional workflows:
  - `test.yml`: targeted test pipeline (needs review for native alignment).
  - `release.yml`: release automation (likely Flutter builds; inspect when planning migration).
  - `store-listings.yml`: manages store metadata sync.
  - `ios-deployment-secrets.md`: documentation on managing ASC credentials.

## Environment & Secrets
- `.env` file consumed by Flutter to derive `ENVIRONMENT`, API base URLs, Firebase bucket. CI writes staging defaults. Native app should adopt `.xcconfig` + Secrets plist aligned with these variables.
- Firebase config: `GoogleService-Info (1).plist` included; ensure canonical file is stored securely once native project created.

## Next Steps for Native Tooling
1. Define Xcode workspace + scheme naming conventions (`AroosiSwiftDev`, `AroosiSwiftProd`).
2. Add SwiftLint/SwiftFormat configuration; integrate into CI (GitHub Actions or Fastlane). Consider migrating workflows to run both Flutter (legacy) and Swift builds during overlap period.
3. Draft Fastlane lanes for `beta` (TestFlight), `appstore`, `unit_tests`, referencing new targets.
4. Establish dependency management: prefer Swift Package Manager; fall back to CocoaPods for SDK gaps.
5. Plan secrets management (Match or App Store Connect API keys) and update `ios-deployment-secrets.md` accordingly.
