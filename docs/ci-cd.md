# CI/CD Setup Guide

This document explains the comprehensive CI/CD pipeline setup for the Aroosi Flutter app, including automated building, testing, and deployment to both App Store and Play Store.

## Overview

The CI/CD pipeline consists of several GitHub Actions workflows:

- **CI Workflow** (`ci.yml`): Runs on every push and PR for basic validation
- **Test Workflow** (`test.yml`): Comprehensive testing suite
- **Release Workflow** (`release.yml`): Version bumping and store deployment
- **Store Listings Workflow** (`store-listings.yml`): Metadata synchronization

## Workflows

### 1. CI Workflow

**Trigger**: Push/PR to main/develop branches
**Purpose**: Basic validation and artifact generation

**Jobs**:
- `test`: Runs Flutter tests and analysis
- `build-android`: Builds Android APK
- `build-ios`: Builds iOS app

**Artifacts**:
- Android APK: `android-apk/app-debug.apk`
- iOS Build: `ios-build/Runner.xcarchive`

### 2. Test Workflow

**Trigger**: Push/PR to main/develop branches
**Purpose**: Comprehensive testing

**Jobs**:
- `unit-tests`: Run all unit tests
- `lint`: Code analysis and formatting checks
- `widget-tests`: Widget-specific tests

### 3. Release Workflow

**Trigger**: Manual dispatch only
**Purpose**: Version bumping and store deployment

**Features**:
- Automatic version bumping (patch/minor/major)
- Platform-specific build number tracking
- Optional Android/Play Store deployment
- Optional iOS/App Store deployment
- Automatic git tagging

**Parameters**:
- `version_type`: patch, minor, or major
- `deploy_android`: Deploy to Play Store (boolean)
- `deploy_ios`: Deploy to App Store (boolean)

### 4. Store Listings Workflow

**Trigger**: Changes to metadata files or manual dispatch
**Purpose**: Synchronize store metadata

**Features**:
- Automatic metadata upload to both stores
- Triggered by changes in `fastlane/metadata/**`

## Version Management

The project uses a sophisticated version management system:

### Version Files
- `pubspec.yaml`: Main Flutter version
- `versioning/build-version.json`: Platform build numbers
- `android/app/build.gradle.kts`: Android version codes
- `ios/Runner.xcodeproj/project.pbxproj`: iOS versions

### Version Scripts
- `scripts/bump-version.js`: Bump semantic version and build numbers
- `scripts/post-submit-version.js`: Tag releases

### Usage
```bash
# Bump patch version
node scripts/bump-version.js patch

# Bump minor version
node scripts/bump-version.js minor

# Tag current version
node scripts/post-submit-version.js --push
```

## Fastlane Configuration

### Android Fastlane (`android/fastlane/Fastfile`)

**Available Lanes**:
- `build`: Build release AAB
- `upload_metadata`: Upload metadata only
- `deploy`: Build and deploy to Play Store
- `promote`: Promote from beta to production
- `release`: Build and deploy (alias for deploy)

### iOS Fastlane (`ios/fastlane/Fastfile`)

**Available Lanes**:
- `build`: Build release IPA
- `upload_metadata`: Upload metadata only
- `deploy_testflight`: Build and deploy to TestFlight
- `deploy`: Build and deploy to App Store
- `release`: Build and deploy to App Store (alias for deploy)
- `release_testflight`: Build and deploy to TestFlight (alias)

## Required Secrets

### GitHub Repository Secrets

#### Android Secrets
- `ANDROID_PACKAGE_NAME`: App package name (default: `com.aroosi.mobile`)
- `ANDROID_SIGNING_KEYSTORE_BASE64`: Base64 encoded keystore file
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password
- `ANDROID_KEY_ALIAS`: Key alias
- `ANDROID_KEY_PASSWORD`: Key password
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: Google Play service account JSON

#### iOS Secrets
- `IOS_APP_IDENTIFIER`: App bundle identifier (default: `com.aroosi.mobile`)
- `APPLE_ID`: Apple ID email
- `APPSTORE_TEAM_ID`: App Store Connect Team ID
- `APPLE_TEAM_ID`: Developer Team ID
- `APPSTORE_API_KEY_ID`: App Store Connect API Key ID
- `APPSTORE_API_ISSUER_ID`: API Key Issuer ID
- `APPSTORE_API_KEY_P8`: Contents of the `.p8` API key file

## Deployment Process

### Manual Deployment

1. **Version Bump** (if needed):
   ```bash
   node scripts/bump-version.js patch
   git add .
   git commit -m "Bump version"
   git push
   ```

2. **Trigger Release**:
   - Go to GitHub Actions
   - Select "Release to Stores" workflow
   - Click "Run workflow"
   - Choose version type and deployment options

3. **Alternative**: Use Fastlane directly:
   ```bash
   # Android
   cd android && bundle exec fastlane deploy

   # iOS
   cd ios && bundle exec fastlane deploy
   ```

### Automated Deployment

The release workflow handles everything automatically:
1. Version bumping
2. Code signing
3. Building
4. Store deployment
5. Git tagging

## Store Metadata

Store metadata is managed in `fastlane/metadata/`:

```
fastlane/metadata/
├── android/
│   └── en-US/
│       ├── title.txt
│       ├── short_description.txt
│       └── full_description.txt
└── ios/
    └── en-US/
        ├── name.txt
        ├── subtitle.txt
        └── description.txt
```

### Updating Metadata

1. Edit files in `fastlane/metadata/**`
2. Commit and push changes
3. Store Listings workflow will automatically sync to stores
4. Or run manually: Actions → Store Listings → Run workflow

## Code Signing Setup

### Android Signing

1. **Create Upload Key**:
   ```bash
   keytool -genkeypair \
     -alias upload \
     -keyalg RSA \
     -keysize 2048 \
     -validity 10000 \
     -dname "CN=Aroosi,O=Aroosi,C=US" \
     -keystore upload-keystore.jks
   ```

2. **Base64 Encode Keystore**:
   ```bash
   base64 -i upload-keystore.jks -o encoded-keystore.txt
   ```

3. **Add to GitHub Secrets**:
   - `ANDROID_SIGNING_KEYSTORE_BASE64`: Contents of encoded-keystore.txt
   - `ANDROID_KEYSTORE_PASSWORD`: Keystore password
   - `ANDROID_KEY_ALIAS`: Key alias (usually "upload")
   - `ANDROID_KEY_PASSWORD`: Key password

### iOS Signing

1. **Create App Store Connect API Key**:
   - Go to App Store Connect → Users and Access → Keys
   - Create new key with App Manager role
   - Download the `.p8` file

2. **Add to GitHub Secrets**:
   - `APPSTORE_API_KEY_ID`: Key ID from App Store Connect
   - `APPSTORE_API_ISSUER_ID`: Issuer ID from App Store Connect
   - `APPSTORE_API_KEY_P8`: Contents of the `.p8` file

## Local Development

### Setup

1. **Install Dependencies**:
   ```bash
   # Flutter dependencies
   flutter pub get

   # Fastlane
   gem install fastlane
   cd android && bundle install
   cd ../ios && bundle install
   ```

2. **Configure Environment**:
   ```bash
   # Create .env file with required secrets
   cp .env.example .env
   # Edit .env with your actual credentials
   ```

3. **Build Locally**:
   ```bash
   # Android
   cd android && fastlane build

   # iOS
   cd ios && fastlane build
   ```

## Troubleshooting

### Common Issues

1. **Build Failures**:
   - Check Flutter doctor: `flutter doctor`
   - Clean build cache: `flutter clean`
   - Update dependencies: `flutter pub upgrade`

2. **Store Upload Failures**:
   - Verify API credentials are correct
   - Check app identifiers match
   - Ensure app exists in stores

3. **Version Conflicts**:
   - Check `versioning/build-version.json`
   - Verify pubspec.yaml version format
   - Ensure build numbers are sequential

### Getting Help

- Check GitHub Actions logs for detailed error messages
- Review the documentation in `docs/`
- Check existing issues in the repository

## Security Notes

- Never commit signing keys to version control
- Use GitHub Secrets for all sensitive information
- Rotate API keys regularly
- Limit repository access to trusted contributors

## Best Practices

1. **Version Management**:
   - Use semantic versioning consistently
   - Tag releases after successful deployment
   - Keep build numbers sequential

2. **Testing**:
   - Run full test suite before deployment
   - Use different environments (dev/staging/production)
   - Monitor app performance after releases

3. **Deployment**:
   - Use TestFlight for iOS beta testing
   - Use Play Store internal testing for Android
   - Deploy metadata changes before binary changes
   - Test on real devices before production release

4. **Monitoring**:
   - Monitor GitHub Actions for failures
   - Set up notifications for deployment status
   - Track app store reviews and ratings
   - Monitor crash reports and user feedback
