# Aroosi Native iOS

Native iOS client for the Aroosi cultural matchmaking platform, built with SwiftUI and Firebase.

## Development

```bash
cd native_ios
swift package update
swift run
```

Open `native_ios/AroosiApp.xcodeproj` in Xcode 15+ for full development experience.

## Project Structure

- `native_ios/` - Swift package with SwiftUI implementation
- `ios/` - iOS-specific configuration and fastlane setup
- `firebase/` - Backend configuration and security rules
- `docs/` - Comprehensive documentation

## Releases

- iOS bundle id: `com.aroosi.mobile`
- Versioning and build numbers managed in `versioning/`
- Fastlane configuration in `fastlane/`
