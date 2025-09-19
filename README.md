# Aroosi Flutter

Flutter client that mirrors the production bundle identifiers and store
configuration used by `aroosi-mobile`.

## Development

```bash
flutter pub get
flutter run
```

Environment variables are loaded from `.env` (see `lib/core/env.dart`).

## Releases

- Android package id: `com.aroosi.mobile`
- iOS bundle id: `com.aroosi.mobile`
- Versioning, build numbers, and fastlane metadata live alongside the Flutter
  project. See [docs/release.md](docs/release.md) for the full workflow, required
  secrets, and helper scripts (`scripts/bump-version.js`).
