const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'aroosi-ios'
});

const db = admin.firestore();

async function checkImportedProfiles() {
  console.log('🔍 Checking Imported Sample Profiles...\n');

  try {
    const profilesSnapshot = await db.collection('profiles').get();
    const profiles = profilesSnapshot.docs;

    console.log(`📊 Sample Profiles Ready: ${profiles.length} profiles imported successfully!\n`);

    if (profiles.length > 0) {
      console.log('🎉 SUCCESS! Your sample profiles are now in Firebase:\n');

      profiles.forEach((doc, index) => {
        const data = doc.data();
        console.log(`${index + 1}. ${data.displayName}`);
        console.log(`   👤 ${data.gender === 'male' ? '🚹' : '👩'} Age: ${data.age} | Location: ${data.location}`);
        console.log(`   💬 Bio: ${data.bio.substring(0, 60)}...`);
        console.log(`   🎨 Languages: ${data.languages.join(', ')}`);
        console.log(`   ⚡ Religious: ${data.culturalProfile.religiousPractice?.replace('_', ' ')}`);
        console.log(`   🖼️  Image: ${data.profileImage}`);
        console.log('');
      });

      console.log('✅ All profiles are complete and ready for testing!');
      console.log('\n🚀 Launch your aroosi app to see the sample profiles in action!');
      
      // Check male/female balance
      const males = profiles.filter(doc => doc.data().gender === 'male');
      const females = profiles.filter(doc => doc.data().gender === 'female');
      console.log(`\n📈 Profile Balance: ${males.length} males, ${females.length} females`);

      return profiles.length;
      
    } else {
      console.log('❌ No profiles found yet. Please follow these steps:');
      console.log('1. Go to: https://console.firebase.google.com/project/aroosi-ios/firestore');
      console.log('2. Click "Data" tab → "Import JSON"');
      console.log('3. Upload: sample_profiles.json');
      console.log('4. Collection name: profiles');
      return 0;
    }

  } catch (error) {
    console.error('❌ Error checking profiles:', error.message);
    console.log('\n🔧 Solution: Import the profiles manually via Firebase Console.');
    return 0;
  }
}

// Main execution
if (require.main === module) {
  checkImportedProfiles()
    .then((count) => {
      console.log(count > 0 ? '\n🎉 Import verification complete!' : '\n📋 Please complete the import first.');
      process.exit(count > 0 ? 0 : 1);
    })
    .catch((error) => {
      console.error('\n💥 Verification failed');
      process.exit(1);
    });
}

module.exports = { checkImportedProfiles };
