# Fastlane for AroosiSwift

Commands below assume you run them from `aroosi_swift/native_ios` and have Ruby + Bundler installed.

## Setup
```bash
cd "$(git rev-parse --show-toplevel)/aroosi_swift/native_ios"
bundle install
```

## Lanes
- `bundle exec fastlane test` – Runs unit tests on the default simulator.
- `bundle exec fastlane beta` – Builds the app and uploads to TestFlight (requires App Store Connect credentials configured in `fastlane/Appfile` and environment variables).
- `bundle exec fastlane appstore` – Captures screenshots, triggers the beta lane, and uploads to App Store (submission is manual by default).

## Environment
Set the following environment variables (or use `.env.default`) before running distribution lanes:
- `ASC_API_KEY_ID`
- `ASC_API_KEY_ISSUER_ID`
- `ASC_API_KEY_P8`
- `MATCH_PASSWORD` (if using Fastlane Match)

> Remember to rotate API keys regularly and avoid committing secrets to the repository.
