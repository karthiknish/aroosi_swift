# Store Listings via Version Control

This repo tracks App Store and Play Store listing metadata in `fastlane/metadata`. A GitHub Actions workflow uploads changes to the stores using Fastlane.

## Overview
- iOS (App Store Connect): `ios/fastlane/Fastfile` lane `upload_metadata` uses `deliver` to push metadata from `fastlane/metadata/ios`.
- Android (Google Play Console): `android/fastlane/Fastfile` lane `upload_metadata` uses `supply` to push metadata from `fastlane/metadata/android`.
- CI: `.github/workflows/store-listings.yml` runs on changes to metadata directories (or manual dispatch).

## Directory Structure
```
fastlane/metadata/
  ios/
    en-US/
      name.txt
      subtitle.txt
      description.txt
      keywords.txt
      release_notes.txt
  android/
    en-US/
      title.txt
      short_description.txt
      full_description.txt
```
Add additional locales by creating sibling locale folders (e.g., `en-GB`, `fr-FR`).

## Required Secrets (GitHub Repository Secrets)
- iOS:
  - `IOS_APP_IDENTIFIER` (e.g., `com.company.app`)
  - `APPLE_ID` (Apple login email)
  - `APPSTORE_TEAM_ID` (App Store Connect Team ID)
  - `APPLE_TEAM_ID` (Developer Team ID)
  - `APPSTORE_API_KEY_ID` (App Store Connect API Key ID)
  - `APPSTORE_API_ISSUER_ID` (Issuer ID)
  - `APPSTORE_API_KEY_P8` (Contents of the `.p8` API key)

- Android:
  - `ANDROID_PACKAGE_NAME` (e.g., `com.company.app`)
  - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (contents of the service account JSON)

## Usage
- Edit metadata files in `fastlane/metadata/**` and push to `main`.
- The GitHub Action will upload to the stores.
- You can also trigger manually: Actions → Store Listings → Run workflow.

## Notes
- Screenshots & images are currently skipped. Add screenshot upload later if desired.
- Binary uploads are not part of this workflow; it only syncs metadata.
- Ensure your app is already created in App Store Connect and Google Play Console and package identifiers match.
- For local runs:
  - iOS: `cd ios && fastlane upload_metadata`
  - Android: `cd android && fastlane upload_metadata`
