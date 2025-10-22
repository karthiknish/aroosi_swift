const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK with basic Firestore access (no auth)
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'aroosi-project'
});

const db = admin.firestore();

// Sample Afghan names and data
const maleNames = [
  'Ahmad', 'Mohammad', 'Zahoor', 'Abdul', 'Rashid', 'Naim', 'Habib', 'Gul', 
  'Jamal', 'Sultan', ' Omar', 'Aziz', 'Rafi', 'Karim', 'Yusuf', 'Hamid'
];

const femaleNames = [
  'Fatima', 'Maryam', 'Aisha', 'Zahra', 'Khadija', 'Laila', 'Roya', 'Sakina',
  'Nafisa', 'Zarifa', 'Gulnaz', 'Shirin', 'Nadia', 'Sahar', 'Marwa', 'Amina'
];

const afghanProvinces = [
  'Kabul', 'Herat', 'Kandahar', 'Balkh', 'Nangarhar', 'Takhar', 'Badakhshan',
  'Ghazni', 'Paktia', 'Kunduz', 'Baghlan', 'Logar', 'Nangarhar', 'Parwan'
];

const languages = ['Dari', 'Pashto', 'Urdu', 'English', 'Arabic'];
const interests = ['Reading', 'Cooking', 'Travel', 'Photography', 'Music', 'Art', 'Hiking', 'Nature', 'Family', 'Culture'];

// Function to create a comprehensive profile data (without Firebase Auth)
function createProfileData(uid, gender, index) {
  const firstName = gender === 'male' 
    ? maleNames[Math.floor(Math.random() * maleNames.length)]
    : femaleNames[Math.floor(Math.random() * femaleNames.length)];
  
  const lastName = maleNames[Math.floor(Math.random() * maleNames.length)];
  const displayName = `${firstName} ${lastName}`;
  const age = 20 + Math.floor(Math.random() * 15); // Ages 20-35
  const birthYear = 1990 - age + 2024;
  
  const selectedLanguages = [languages[Math.floor(Math.random() * 2)], languages[Math.floor(Math.random() * 2) + 1]];
  const selectedInterests = [];
  for (let i = 0; i < 3 + Math.floor(Math.random() * 3); i++) {
    const interest = interests[Math.floor(Math.random() * interests.length)];
    if (!selectedInterests.includes(interest)) {
      selectedInterests.push(interest);
    }
  }

  const placeholderImage = gender === 'male' 
    ? `https://i.pravatar.cc/300?img=${index + 1}`
    : `https://i.pravatar.cc/300?img=${index + 6}`;

  return {
    uid: uid,
    email: `sample${gender}${index + 1}@aroosi.app`,
    displayName: displayName,
    age: age,
    birthDate: admin.firestore.Timestamp.fromDate(new Date(birthYear, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28))),
    gender: gender,
    location: afghanProvinces[Math.floor(Math.random() * afghanProvinces.length)],
    bio: `I am a ${age}-year-old ${gender === 'male' ? 'man' : 'woman'} from Afghanistan looking for a meaningful relationship. I value family, traditions, and cultural heritage.`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    
    // Profile images
    images: [placeholderImage],
    profileImage: placeholderImage,
    isProfileComplete: true,

    // Languages
    languages: selectedLanguages,
    motherTongue: selectedLanguages[0],

    // Interests
    interests: selectedInterests,

    // Cultural profile
    culturalProfile: {
      religion: 'islam',
      religiousPractice: ['moderately_practicing', 'very_practicing', 'somewhat_practicing'][Math.floor(Math.random() * 3)],
      motherTongue: selectedLanguages[0],
      languages: selectedLanguages,
      familyValues: ['traditional', 'modern', 'mixed'][Math.floor(Math.random() * 3)],
      marriageViews: ['love_marriage', 'arranged_marriage', 'both'][Math.floor(Math.random() * 3)],
      traditionalValues: ['very_important', 'somewhat_important', 'not_important'][Math.floor(Math.random() * 3)],
      familyApprovalImportance: ['very_important', 'somewhat_important', 'not_important'][Math.floor(Math.random() * 3)],
      religionImportance: 7 + Math.floor(Math.random() * 4),
      cultureImportance: 7 + Math.floor(Math.random() * 4),
      familyBackground: 'I come from a respected Afghan family with strong cultural values and traditions.',
      ethnicity: 'afghan',
    },

    // Preferences
    preferences: {
      ageRange: {
        min: 20,
        max: 40
      },
      location: afghanProvinces[Math.floor(Math.random() * afghanProvinces.length)],
      religion: 'islam',
      religiousPractice: 'any',
      familyValues: 'any',
      marriageViews: 'any'
    },

    // Status
    isOnline: true,
    lastSeen: admin.firestore.FieldValue.serverTimestamp(),
    status: 'active'
  };
}

// Function to generate a UUID
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

// Main function to create sample profiles
async function createSampleProfiles() {
  console.log('🚀 Creating Sample Profiles for Firestore...\n');

  try {
    const profilesToCreate = 6; // 3 male, 3 female
    const createdProfiles = [];

    for (let i = 0; i < profilesToCreate; i++) {
      const gender = i < 3 ? 'male' : 'female';
      const uid = generateUUID(); // Generate a random UID instead of using Firebase Auth

      console.log(`\n📸 Creating ${gender} profile ${i + 1}:`);

      // Create comprehensive profile data
      const profileData = createProfileData(uid, gender, i);

      // Save to Firestore directly (no Auth needed)
      await db.collection('profiles').doc(uid).set(profileData);
      console.log(`✅ Firestore profile created for ${profileData.displayName}`);

      createdProfiles.push({
        uid: uid,
        email: profileData.email,
        displayName: profileData.displayName,
        gender: gender,
        imageUrl: profileData.profileImage
      });
    }

    console.log('\n🎉 Profile Creation Summary:');
    console.log(`✅ Successfully created ${createdProfiles.length} Firestore profiles`);
    
    console.log('\n📋 Created Profiles:');
    createdProfiles.forEach((profile, index) => {
      console.log(`${index + 1}. ${profile.displayName} (${profile.gender})`);
      console.log(`   Email: ${profile.email}`);
      console.log(`   UID: ${profile.uid}`);
      console.log(`   Image: ${profile.imageUrl}`);
      console.log('');
    });

    console.log('\n💡 Note: These profiles exist only in Firestore.');
    console.log('   To test in the app, you will need Firebase Auth users or temporary login method.');

  } catch (error) {
    console.error('❌ Error creating sample profiles:', error);
    throw error;
  }
}

// Run the script
if (require.main === module) {
  createSampleProfiles()
    .then(() => {
      console.log('\n🎊 Sample profile creation completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Failed to create sample profiles');
      process.exit(1);
    });
}

module.exports = { createSampleProfiles };
