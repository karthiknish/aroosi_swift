# iOS Deployment - Required GitHub Secrets

## 📋 **GitHub Repository Secrets Required**

Add these secrets to your GitHub repository: **Settings → Secrets and variables → Actions**

### **App Store Connect Secrets** (Required for iOS deployment)
- `IOS_APP_IDENTIFIER` = `com.aroosi.mobile`
- `APPLE_ID` = `contact@aroosi.app`
- `APPSTORE_TEAM_ID` = Your Apple Team ID (10 characters)
- `APPLE_TEAM_ID` = Your Apple Team ID (10 characters)
- `APPSTORE_API_KEY_ID` = Your App Store Connect API Key ID (e.g., `2X9R4HXF34`)
- `APPSTORE_API_ISSUER_ID` = Your App Store Connect Issuer ID (e.g., `69a6de79-ceda-47e3-e053-5b8c7c11a4d1`)
- `APPSTORE_API_KEY_P8` = Base64 encoded contents of your `.p8` file

### **iOS Signing Secrets** (Required for iOS deployment)
- `CERTIFICATE_P12_BASE64` = Base64 encoded iOS distribution certificate (.p12 file)
- `CERTIFICATE_PASSWORD` = Password for the .p12 certificate
- `MOBILEPROVISION_BASE64` = Base64 encoded mobile provisioning profile
- `PROVISIONING_PROFILE_UUID` = UUID of your provisioning profile

### **Play Store Secrets** (Required for Android deployment)
- `ANDROID_PACKAGE_NAME` = `com.aroosi.mobile`
- `ANDROID_SIGNING_KEYSTORE_BASE64` = Base64 encoded Android keystore
- `ANDROID_KEYSTORE_PASSWORD` = Keystore password
- `ANDROID_KEY_ALIAS` = Key alias
- `ANDROID_KEY_PASSWORD` = Key password
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` = Service account JSON for Play Store API

## 🔧 **How to Get Each Secret**

### **App Store Connect API Keys**
1. Go to https://appstoreconnect.apple.com/
2. Navigate to "Users and Access" → "Keys"
3. Create new API key with permissions: Apps, In-App Purchases, TestFlight
4. Download .p8 file and base64 encode it: `base64 -i AuthKey_2X9R4HXF34.p8`

### **Apple Team ID**
1. Go to https://developer.apple.com/account/
2. View Account → Membership
3. Copy the Team ID (10 characters)

### **iOS Certificate & Provisioning Profile**
1. Use `fastlane match` to generate certificates
2. Or manually create in Apple Developer Console
3. Download .p12 certificate and mobileprovision file
4. Base64 encode them: `base64 -i certificate.p12`

### **Base64 Encoding Commands**
```bash
# For .p8 API key
base64 -i AuthKey_2X9R4HXF34.p8

# For .p12 certificate
base64 -i distribution.p12

# For mobile provisioning profile
base64 -i AppStore_com.aroosi.mobile.mobileprovision
```

## 🚀 **Testing the Setup**

**Run these commands locally** to test:
```bash
cd "/Users/karthiknishanth/React Projects/aroosi_flutter/ios"
source .env
fastlane upload_metadata
```

**Run in GitHub Actions**:
1. Go to Actions tab in GitHub
2. Run "Store Listings" workflow manually
3. Check if it completes successfully

## 📱 **iOS Deployment Workflow**

The GitHub Actions will automatically:
1. ✅ Build iOS app with correct Flutter version (3.24.0)
2. ✅ Archive and export IPA
3. ✅ Upload metadata to App Store Connect
4. ✅ Deploy to TestFlight or App Store

## 🔍 **Troubleshooting**

**If deployment fails**:
1. Check that all secrets are set in GitHub repository settings
2. Verify API key permissions in App Store Connect
3. Ensure provisioning profile matches bundle ID
4. Check certificate validity dates

**Common errors**:
- "ASC_API_KEY_ID and ASC_API_KEY_ISSUER_ID environment variables are required" → Missing secrets
- "Code signing failed" → Missing or invalid certificate/provisioning profile
- "App Store Connect API key not valid" → Wrong key ID or issuer ID

## 🎯 **Next Steps**

1. ✅ **Update Flutter version** in workflows (3.16.0 → 3.24.0)
2. ✅ **Add all required secrets** to GitHub repository
3. ✅ **Test store listings workflow** manually
4. ✅ **Run full release workflow** for iOS deployment

**You should now be ready to deploy to the App Store!** 🎉
