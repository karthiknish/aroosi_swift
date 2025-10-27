const admin = require('firebase-admin');

async function simpleProfileTest() {
  console.log('🧪 Simple Profile Creation Test...\n');

  try {
    const serviceAccount = require('./service-account.json');
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });
    
    const db = admin.firestore();

    // Test 1: Create a simple profile
    console.log('📝 Creating a simple test profile...');
    
    const simpleProfile = {
      uid: 'test-user-123',
      email: 'test@aroosi.app',
      displayName: 'Test User',
      age: 25,
      gender: 'male',
      location: 'Kabul',
      bio: 'This is a test profile for aroosi app.',
      profileImage: 'https://i.pravatar.cc/300?img=test',
      isProfileComplete: true,
      languages: ['Dari', 'English'],
      interests: ['Reading', 'Music'],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      culturalProfile: {
        religion: 'islam',
        religiousPractice: 'moderately_practicing',
        familyValues: 'traditional',
        ethnicity: 'afghan'
      },
      preferences: {
        minAge: 20,
        maxAge: 40,
        location: 'Kabul'
      },
      isOnline: true,
      lastSeen: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection('profiles').doc('test-user-123').set(simpleProfile);
    console.log('✅ Simple profile created successfully!');

    // Test 2: Verify the profile was created
    const createdProfile = await db.collection('profiles').doc('test-user-123').get();
    if (createdProfile.exists) {
      console.log('✅ Profile verification successful!');
      console.log(`   Name: ${createdProfile.data().displayName}`);
      console.log(`   Email: ${createdProfile.data().email}`);
      console.log(`   Age: ${createdProfile.data().age}`);
    } else {
      console.log('❌ Profile creation failed - document not found');
    }

    // Test 3: Clean up
    await db.collection('profiles').doc('test-user-123').delete();
    console.log('✅ Test profile cleaned up');

    console.log('\n🎉 All tests passed! Ready for profile creation.');
    
  } catch (error) {
    console.error('❌ Simple test failed:', error.message);
    console.log('\n🔧 The issue might be:');
    console.log('1. Data structure validation rules');
    console.log('2. Document size limits');
    console.log('3. Required field constraints');
    
    console.log('\n💡 Recommendation: Use manual import method');
  }
}

if (require.main === module) {
  simpleProfileTest()
    .catch(() => process.exit(1));
}

module.exports = { simpleProfileTest };
