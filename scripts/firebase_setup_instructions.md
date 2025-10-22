# 🔥 Firebase Demo Account Setup Instructions

## 📋 Quick Setup Guide

Since the Flutter script needs to run within the app context, here are the easiest ways to create the demo account:

## Option 1: Firebase Console (Recommended) ⭐

### Step 1: Go to Firebase Console
1. Visit: https://console.firebase.google.com/
2. Select project: `aroosi-project`
3. Go to **Authentication** → **Users** tab

### Step 2: Create Demo User
1. Click **Add user**
2. **Email**: `appreview@aroosi.app`
3. **Password**: `ReviewDemo2024!`
4. **Display Name**: `App Reviewer`
5. Click **Add user**

### Step 3: Create Profile Document
1. Go to **Firestore Database**
2. Click **Start collection** → **Collection ID**: `users`
3. Click **Add document** → **Document ID**: (Use the UID from step 2)
4. Copy and paste the profile data from `demo_profile_data.json` below

## Option 2: Using the Aroosi App (Alternative)

1. Open the Aroosi Flutter app
2. Go to Sign Up screen
3. Use credentials:
   - **Email**: `appreview@aroosi.app`
   - **Password**: `ReviewDemo2024!`
4. Complete the profile setup manually using the demo data below

## 📄 Demo Profile Data (JSON)

Copy this data into the Firestore document for the demo user:

```json
{
  "uid": "[USER_UID_FROM_AUTH]",
  "email": "appreview@aroosi.app",
  "displayName": "App Reviewer",
  "createdAt": "[CURRENT_TIMESTAMP]",
  "updatedAt": "[CURRENT_TIMESTAMP]",
  "age": 28,
  "gender": "prefer_not_to_say",
  "location": "San Francisco, CA",
  "culturalBackground": "Afghan",
  "heritage": "Central Asian",
  "familyOrigin": "Kabul, Afghanistan",
  "languages": ["English", "Farsi", "Pashto"],
  "culturalValues": "Traditional with modern outlook",
  "religiousBeliefs": "Moderate",
  "familyValues": "Traditional",
  "seeking": "Long-term relationship",
  "familyApproval": {
    "parentApprovalRequired": true,
    "familyInvolvement": "High - family consulted",
    "culturalCompatibilityImportance": "Very Important",
    "religiousAlignment": "Moderate to conservative",
    "traditionalValuesImportance": "Very Important"
  },
  "datingPreferences": {
    "principles": "Halal dating principles",
    "marriageGoals": "Seeking marriage within 2-3 years",
    "familyApproval": "Required for matches",
    "culturalAlignment": "Important factor"
  },
  "profileStatus": "complete",
  "isVerified": true,
  "isPremium": true,
  "subscriptionType": "reviewer_premium",
  "lastLogin": "[CURRENT_TIMESTAMP]",
  "loginCount": 1,
  "appVersion": "1.0.3",
  "privacy": {
    "profileVisibility": "public",
    "showAge": true,
    "showLocation": true,
    "allowMessages": true,
    "familyCanView": true
  },
  "culturalScores": {
    "familyValues": 95,
    "religiousAlignment": 85,
    "traditionalPractices": 90,
    "languageCompatibility": 100,
    "culturalKnowledge": 88,
    "overallCompatibility": 92
  },
  "photos": [
    {
      "url": "https://firebasestorage.googleapis.com/v0/b/aroosi-project.appspot.com/o/demo%2Fheadshot.jpg?alt=media",
      "type": "headshot",
      "approved": true,
      "uploadedAt": "[CURRENT_TIMESTAMP]"
    }
  ],
  "preferences": {
    "ageRange": [25, 35],
    "maxDistance": 50,
    "culturalBackground": ["Afghan", "Afghan-American"],
    "religiousAlignment": ["Moderate", "Conservative"],
    "familyValues": ["Traditional", "Moderate"],
    "languages": ["English", "Farsi", "Pashto"]
  }
}
```

## 🔥 Firebase CLI Setup (Advanced)

If you prefer using Firebase CLI:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Go to project directory
cd /Users/karthiknishanth/React\ Projects/aroosi_flutter

# Use Firebase project
firebase use aroosi-project

# Deploy Firestore rules (if needed)
firebase deploy --only firestore:rules
```

## ✅ Verification Checklist

After setting up the demo account, verify:

- [ ] User can log in with `appreview@aroosi.app` / `ReviewDemo2024!`
- [ ] Profile displays all cultural information
- [ ] Family approval settings are configured
- [ ] Premium features are accessible
- [ ] Sample matches appear in Discover tab
- [ ] Messaging system works
- [ ] Multi-language support functions

## 🎯 Test Data Summary

The demo account includes:
- ✅ Complete cultural profile with Afghan heritage
- ✅ Family approval system configured
- ✅ Premium access for all features
- ✅ Cultural compatibility scores
- ✅ Multi-language support (English, Farsi, Pashto)
- ✅ Traditional dating preferences
- ✅ Privacy settings optimized for testing

## 📞 Support

If you encounter issues during setup:
1. Check Firebase project ID: `aroosi-project`
2. Verify Firestore rules allow read/write
3. Confirm Firebase Auth is enabled
4. Email: support@aroosi.app