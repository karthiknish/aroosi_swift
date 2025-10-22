# iOS App Store Setup Guide

## Environment Configuration

### 1. Xcode Build Configuration Setup

1. **Open Xcode Project:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Add Configuration Files:**
   - Add `Config.xcconfig` (Production)
   - Add `Config-Staging.xcconfig` (Staging)

3. **Configure Build Settings:**
   - Select `Runner` target
   - Go to "Build Settings" tab
   - Under "Configurations", add new configurations:
     - **Release**: Set to `Config.xcconfig`
     - **Debug**: Set to `Config-Staging.xcconfig`

### 2. Bundle Identifier Setup

1. **Set Bundle ID:**
   - Target: `Runner` → "General" tab
   - Bundle Identifier: `com.aroosi.mobile`
   - Ensure this matches your Apple Developer account

2. **Version Info:**
   - Version: `1.0` (Marketing Version)
   - Build: `1` (Current Project Version)

### 3. Signing & Capabilities

1. **Team Selection:**
   - Select your Apple Developer team
   - Ensure automatic signing is enabled for development

2. **Capabilities:**
   - **Push Notifications**: Enable
   - **Background Modes**: Enable (Audio, Background fetch)
   - **In-App Purchase**: Enable (if needed later)

### 4. Firebase Configuration

1. **Download `GoogleService-Info.plist`:**
   - Go to Firebase Console
   - Select your production project
   - Download `GoogleService-Info.plist`
   - Add to `ios/Runner` folder in Xcode

2. **Configure Firebase:**
   - Add Firebase SDK to `ios/Podfile`:
   ```ruby
   target 'Runner' do
     pod 'Firebase/Auth'
     pod 'Firebase/Core'
   end
   ```

### 5. Info.plist Configuration

Add these entries to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone for voice messages in chat.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library for profile pictures.</string>

<key>NSCameraUsageDescription</key>
<string>This app uses the camera for taking profile photos.</string>

<key>CFBundleDisplayName</key>
<string>Aroosi</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>background-fetch</string>
</array>
```

### 6. App Store Connect Setup

1. **Create App in App Store Connect:**
   - Go to https://appstoreconnect.apple.com
   - Create new app with Bundle ID: `com.aroosi.mobile`
   - Set app name: `Aroosi`

2. **App Information:**
   - Category: `Social Networking`
   - Age Rating: Configure based on content
   - Add app description and keywords

3. **Build and Upload:**
   ```bash
   flutter build ios --release --no-codesign
   ```
   - Open Xcode and archive the build
   - Upload to App Store Connect

### 7. Environment Variables

Create `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig`:

**Release.xcconfig:**
```
#include "../Config.xcconfig"
```

**Debug.xcconfig:**
```
#include "../Config-Staging.xcconfig"
```

### 8. Security Settings

1. **App Transport Security:**
   - Add to `Info.plist` if needed for development:
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
     <key>NSAllowsArbitraryLoads</key>
     <true/>
   </dict>
   ```

2. **Bitcode:**
   - Enable in Build Settings: `ENABLE_BITCODE = YES`

### 9. Testing

1. **Test Flight:**
   - Create internal testing group
   - Add testers via email
   - Upload beta build

2. **Device Testing:**
   - Test on multiple iOS devices
   - Test push notifications
   - Test all app features

### 10. Release Checklist

- [ ] Bundle ID matches Apple Developer account
- [ ] App Store Connect app created
- [ ] Screenshots prepared (Required sizes)
- [ ] App icon prepared (All sizes)
- [ ] Privacy Policy URL ready
- - [ ] Support URL ready
- [ ] Marketing materials ready
- [ ] TestFlight testing completed
- [ ] App reviewed and approved