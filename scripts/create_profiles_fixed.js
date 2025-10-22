const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK for aroosi-ios
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'aroosi-ios'
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
  'Ghazni', 'Paktia', 'Kunduz', 'Baghlan', 'Logar', 'Parwan'
];

const languages = ['Dari', 'Pashto', 'Urdu', 'English', 'Arabic'];
const interests = ['Reading', 'Cooking', 'Travel', 'Photography', 'Music', 'Art', 'Hiking', 'Nature', 'Family', 'Culture'];

// Function to create a profile data
function createProfileData(uid, gender, index) {
  const firstName = gender === 'male' 
    ? maleNames[Math.floor(Math.random() * maleNames.length)]
    : femaleNames[Math.floor(Math.random() * femaleNames.length)];
  
  const lastName = maleNames[Math.floor(Math.random() * maleNames.length)];
  const displayName = `${firstName} ${lastName}`;
  const age = 20 + Math.floor(Math.random() * 15);
  
  const selectedLanguages = [languages[Math.floor(Math.random() * 4)], languages[Math.floor(Math.random() * 3) + 1]];
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
    gender: gender,
    location: afghanProvinces[Math.floor(Math.random() * afghanProvinces.length)],
    bio: `I am a ${age}-year-old ${gender === 'male' ? 'man' : 'woman'} from Afghanistan looking for a meaningful relationship. I value family, traditions, and cultural heritage.`,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    
    // Profile images
    images: [placeholderImage],
    profileImage: placeholderImage,
    isProfileComplete: true,

    // Languages
    languages: selectedLanguages,
    motherTongue: selectedLanguages[0],

    // Interests
    interests: selectedInterests,

    // Simplified cultural profile
    culturalProfile: {
      religion: 'islam',
      religiousPractice: 'moderately_practicing',
      motherTongue: selectedLanguages[0],
      languages: selectedLanguages,
      familyValues: 'traditional',
      marriageViews: 'love_marriage',
      ethnicity: 'afghan',
      religionImportance: 8,
      cultureImportance: 8
    },

    // Simplified preferences
    preferences: {
      minAge: 20,
      maxAge: 40,
      location: afghanProvinces[Math.floor(Math.random() * afghanProvinces.length)],
      religion: 'islam'
    },

    // Status
    isOnline: true,
    lastSeen: new Date().toISOString(),
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
  console.log('🚀 Creating Sample Profiles (Fixed Version)...\n');

  try {
    const profilesToCreate = 6; // 3 male, 3 female
    const createdProfiles = [];

    for (let i = 0; i < profilesToCreate; i++) {
      const gender = i < 3 ? 'male' : 'female';
      const uid = generateUUID();

      console.log(`\n📸 Creating ${gender} profile ${i + 1}:`);

      // Create simplified profile data
      const profileData = createProfileData(uid, gender, i);
      console.log(`   Name: ${profileData.displayName}`);
      console.log(`   Email: ${profileData.email}`);
      console.log(`   Age: ${profileData.age} | Location: ${profileData.location}`);

      // Save to Firestore
      await db.collection('profiles').doc(uid).set(profileData);
      console.log(`✅ Firestore profile created`);

      createdProfiles.push({
        uid: uid,
        email: profileData.email,
        displayName: profileData.displayName,
        gender: gender,
        age: profileData.age,
        location: profileData.location,
        imageUrl: profileData.profileImage
      });
    }

    console.log('\n🎉 Profile Creation Summary:');
    console.log(`✅ Successfully created ${createdProfiles.length} Firestore profiles`);
    
    console.log('\n📋 Created Profiles:');
    createdProfiles.forEach((profile, index) => {
      console.log(`${index + 1}. ${profile.displayName} (${profile.gender})`);
      console.log(`   👤 Age: ${profile.age} | Location: ${profile.location}`);
      console.log(`   📧 Email: ${profile.email}`);
      console.log(`   🖼️  Image: ${profile.imageUrl}`);
      console.log('');
    });

    console.log('🎊 Sample profiles are now ready for testing in the aroosi app!');

  } catch (error) {
    console.error('❌ Error creating sample profiles:', error);
    
    // Create backup if script fails
    console.log('\n📄 Creating local profiles backup file...');
    const profilesData = [];
    for (let i = 0; i < 6; i++) {
      const gender = i < 3 ? 'male' : 'female';
      const uid = generateUUID();
      const profileData = createProfileData(uid, gender, i);
      profilesData.push(profileData);
    }
    
    fs.writeFileSync('./sample_profiles_fixed.json', JSON.stringify(profilesData, null, 2));
    console.log('💾 Saved profiles to sample_profiles_fixed.json');
    throw error;
  }
}

// Run the script
if (require.main === module) {
  createSampleProfiles()
    .then(() => {
      console.log('\n🎉 Sample profile creation completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Failed to create sample profiles');
      process.exit(1);
    });
}

module.exports = { createSampleProfiles };
