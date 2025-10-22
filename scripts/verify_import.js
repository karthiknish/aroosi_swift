const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK for aroosi-ios
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'aroosi-ios'
});

const db = admin.firestore();

async function verifyProfilesInFirestore() {
  console.log('🔍 Verifying Sample Profiles in Firestore...\n');

  try {
    const profilesSnapshot = await db.collection('profiles').get();
    const profiles = profilesSnapshot.docs;

    console.log(`📊 Found ${profiles.length} profiles in Firestore:`);

    profiles.forEach((doc, index) => {
      const data = doc.data();
      console.log(`${index + 1}. ${data.displayName}`);
      console.log(`   UID: ${data.uid}`);
      console.log(`   Email: ${data.email}`);
      console.log(`   Gender: ${data.gender} | Age: ${data.age}`);
      console.log(`   Location: ${data.location}`);
      console.log(`   Image: ${data.profileImage}`);
      console.log(`   Complete: ${data.isProfileComplete ? '✅' : '❌'}`);
      console.log('');
    });

    if (profiles.length === 0) {
      console.log('⚠️  No profiles found in Firestore.');
      console.log('📋 Please import the sample_profiles.json file first:');
      console.log('   1. Go to Firebase Console → Firestore → Data');
      console.log('   2. Click "Import JSON"');
      console.log('   3. Upload sample_profiles.json');
      console.log('   4. Collection name: profiles');
    } else {
      console.log(`✅ Verification complete! ${profiles.length} profiles are ready for testing.`);
    }

    return profiles.length;

  } catch (error) {
    console.error('❌ Error verifying profiles:', error.message);
    console.log('\n🔧 Possible solutions:');
    console.log('1. Make sure Firebase is configured correctly');
    console.log('2. Check if aroosi-ios project exists');
    console.log('3. Import sample_profiles.json to Firestore first');
    
    return 0;
  }
}

// Run verification
if (require.main === module) {
  verifyProfilesInFirestore()
    .then((count) => {
      process.exit(count > 0 ? 0 : 1);
    })
    .catch((error) => {
      console.error('\n💥 Verification failed');
      process.exit(1);
    });
}

module.exports = { verifyProfilesInFirestore };
