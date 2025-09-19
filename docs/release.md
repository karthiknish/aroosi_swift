# Release & Store Publishing

This project mirrors the store configuration that already exists in `aroosi-mobile` so Android and iOS builds share the same identifiers, version numbers, and metadata.

## Versions

- Semantic version lives in `pubspec.yaml`. The build number in that file is used for **iOS**.
- Platform build numbers are tracked in `versioning/build-version.json` (`buildNumber` for iOS, `versionCode` for Android).
- Android `versionCode`/`versionName` are written to `android/app/build.gradle.kts`.
- iOS `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` are in `ios/Runner.xcodeproj/project.pbxproj`.

Run the helper to bump versions consistently:

```bash
node scripts/bump-version.js patch    # or minor | major
```

The script updates all four locations and prints the new values. Pass `--no-ios` or `--no-android` to skip a platform.

After a submission succeeds you can tag the repo with the current numbers:

```bash
node scripts/post-submit-version.js --push
```

## Store credentials

The fastlane lanes expect the same secrets used by `aroosi-mobile`:

| Variable | Purpose |
| --- | --- |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Raw JSON for the Google Play service account (Android publishing via Supply). |
| `ANDROID_PACKAGE_NAME` *(optional)* | Defaults to `com.aroosi.mobile`. Override if you use a different app id. |
| `ASC_API_KEY_ID` | App Store Connect API key ID. |
| `ASC_API_KEY_ISSUER_ID` | App Store Connect API key issuer ID. |
| `ASC_API_KEY_P8_BASE64` | Base64 string of the `.p8` key. Written to `fastlane/asc_api_key.p8` at runtime. |
| `IOS_APP_IDENTIFIER` *(optional)* | Defaults to `com.aroosi.mobile`. |
| `APPLE_ID` | Apple ID email used for App Store Connect (defaults to `contact@aroosi.app`). |
| `APPLE_TEAM_ID` / `APPSTORE_TEAM_ID` *(optional)* | Set if you need to override the default developer team. |

## Publishing

- **Android metadata**: `bundle exec fastlane android upload_metadata`
- **iOS metadata**: `bundle exec fastlane ios upload_metadata`

Both lanes read strings from `fastlane/metadata/**` which were copied from `aroosi-mobile`.

### Tips

- Decode and store the service-account JSON / Apple API key in your CI secrets before running the lanes.
- The Android lane does not upload binaries—use `flutter build appbundle` and `fastlane supply` or your CI to upload bundles when ready.
- The iOS lane only updates metadata. Use Xcode Cloud, EAS, or manual upload for binaries, then run the lane to sync copy updates.
