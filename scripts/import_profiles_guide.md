# Import Sample Profiles to aroosi-ios Firebase

The script has successfully created sample profile data in `sample_profiles.json`. Here's how to import them into your `aroosi-ios` Firebase project:

## Option 1: Firebase Console Import (Recommended)

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/project/aroosi-ios/firestore
   - Make sure you're on the `aroosi-ios` project

2. **Navigate to Firestore**
   - Click on "Firestore Database" in the left menu
   - Select the "Data" tab

3. **Import the Data**
   - Click the three dots (⋮) next to your project name
   - Select "Import JSON"
   - Upload the `sample_profiles.json` file
   - For the collection name, enter: `profiles`

4. **Configure Import Settings**
   - Document ID: Leave it set to "Auto ID" (the script already has UIDs)
   - Click "Import"

## Option 2: Use Firebase CLI (More Technical)

If you want to use the Firebase CLI for importing:

```bash
# Switch to aroosi-ios project
firebase use aroosi-ios

# Import the JSON file to Firestore
firebase firestore:import sample_profiles.json --collection profiles
```

## Available Profiles

The JSON file contains **6 sample profiles**:

### Male Profiles (3)
1. **Yusuf Jamal** - Age 20, from Herat
2. **Ahmad Guls** - Age 32, from Kabul  
3. **Karim Zahur** - Age 23, from Kandahar

### Female Profiles (3)
4. **Fatima Abdul** - Age 28, from Nangarhar
5. **Roya Rashid** - Age 22, from Balkh
6. **Aisha Naim** - Age 30, from Takhar

## Profile Features

Each profile includes:

✅ **Complete Cultural Profile**
- Religion: Islam
- Religious Practice (varied levels)
- Language preferences
- Family values and marriage views
- Traditional values importance

✅ **Personal Information**
- Age, location, bio
- Profile image (placeholder)
- Languages and interests
- Preferences for matching

✅ **Realistic Afghan Context**
- Afghan provinces as locations
- Traditional Afghan names
- Culturally appropriate bio text

## Testing in the App

After importing:

1. **Login Test**: The profiles will appear in search results and matching
2. **Display Test**: Profile images will show (using placeholder images)
3. **Compatibility Test**: Cultural matching will work properly

## Next Steps (Optional)

### Replace Placeholder Images
To replace placeholder images with your seed images:

1. **Upload to Firebase Storage**
   ```bash
   firebase storage:upload ../seed_images/male/14773b6e6edddbebb7807e2bed6d27b9.jpg profile-images/
   ```

2. **Update Profile URLs**
   - Go to Firebase Console
   - Navigate to Firestore → Data → profiles
   - Edit each profile's `profileImage` and `images` fields with the new Storage URLs

### Create Firebase Auth Users (Optional)
If you want actual login functionality, you can create Firebase Auth users matching the email addresses:
- `samplemale1@aroosi.app` → Password: `Sample123!`
- `samplemale2@aroosi.app` → Password: `Sample123!`
- etc.

## Verification

After importing, verify the data:
- Check Firebase Console → Data → profiles
- Look for the 6 documents with proper UIDs
- Verify field structure matches your app's expectations

The profiles are now ready for testing in your aroosi-ios app!
