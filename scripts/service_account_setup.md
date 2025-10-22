# Service Account Setup for aroosi-ios

## Step-by-Step Instructions

### 1. Access Firebase Console
**URL:** https://console.firebase.google.com/project/aroosi-ios/overview

### 2. Navigate to Service Accounts
1. Click the ⚙️ **Project Settings** (gear icon) in the left menu
2. Click the **"Service accounts"** tab

### 3. Generate New Private Key
1. Click **"Generate new private key"** button
2. Select **JSON** as the key type
3. Click **"Generate"**

### 4. Download and Configure
1. The JSON file will download automatically
2. **Move the file** to: `scripts/aroosi-ios-service-account.json`
3. **Copy** these exact commands:

```bash
# Navigate to scripts directory
cd "/Users/karthiknishanth/React Projects/aroosi_flutter/scripts"

# Run the setup script
chmod +x setup_service_account.js
node setup_service_account.js
```

## What the Script Does

When you run `node setup_service_account.js`, it will:

✅ **Backup** your current service account to `service-account-backup.json`
✅ **Replace** it with the new `aroosi-ios` service account
✅ **Test** the connection to verify it works
✅ **Clean up** temporary files

## Verification

After running the setup script, verify everything works:

```bash
# Test the connection
node verify_import.js
```

## Expected Output

If successful, you should see:

```
✅ Service account replaced successfully!
📊 Project ID: aroosi-ios
🎯 Service Email: firebase-adminsdk-xxxx@aroosi-ios.iam.gserviceaccount.com
✅ Service account connection successful!
🎉 Setup Complete!
```

## Troubleshooting

### Permission Denied Error
If you get permission errors, the service account needs additional roles:

1. Go to Google Cloud Console: https://console.cloud.google.com/
2. Select the `aroosi-ios` project  
3. Navigate to: ☰ → "IAM & Admin" → "Service Accounts"
4. Find your service account and click it
5. Click "Edit" → "Add Another Role"
6. Add these roles:
   - **Firebase Admin** 
   - **Cloud Firestore Data Editor**

### File Not Found Error
Make sure the downloaded JSON file is named exactly:
```
scripts/aroosi-ios-service-account.json
```

## Alternative Method

If you prefer using Google Cloud Console directly:

1. **Go to:** https://console.cloud.google.com/
2. **Select:** `aroosi-ios` project from top dropdown
3. **Navigate:** ☰ → "IAM & Admin" → "Service Accounts"
4. **Create:** + CREATE SERVICE ACCOUNT
5. **Name:** firebase-admin
6. **Add Role:** Firebase Admin
7. **Continue** → Done
8. **Find** the service account → ⋮ → "Manage keys"
9. **Add Key:** + ADD KEY → Create new key → JSON → Create

## Next Steps After Setup

Once the service account is working:

1. **Import sample profiles:** Follow the guide in `import_profiles_guide.md`
2. **Verify profiles:** Run `node verify_import.js`
3. **Test in app:** Launch the aroosi app to see the sample profiles

The service account is essential for the sample profile creation and verification scripts to work with your `aroosi-ios` Firebase project.
