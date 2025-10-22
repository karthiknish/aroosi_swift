const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK for the aroosi-ios project
// Note: We'll connect to Firestore directly using the project ID
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'aroosi-ios',
  databaseURL: 'https://aroosi-ios-default-rtdb.firebaseio.com',
  storageBucket: 'aroosi-ios.firebasestorage.app'
});

const db = admin.firestore();
const auth = admin.auth();
const storage = admin.storage();

// Sample Afghan names and data
const maleNames = [
  'Ahmad', 'Mohammad', 'Zahoor', 'Abdul', 'Rashid', 'Naim', 'Habib', 'Gul', 
  'Jamal', 'Sultan', ' Omar', 'Aziz', 'Rafi', 'Karim', 'Yusuf', 'Hamid',
  'Zaman', 'Saeed', 'Wali', 'Nader', 'Farid', 'Shah', 'Faisal', 'Musa'
];

const femaleNames = [
  'Fatima', 'Maryam', 'Aisha', 'Zahra', 'Khadija', 'Laila', 'Roya', 'Sakina',
  'Nafisa', 'Zarifa', 'Gulnaz', 'Shirin', 'Nadia', 'Sahar', 'Marwa', 'Amina',
  'Homa', 'Parwana', 'Roshan', 'Banu', 'Zeenat', 'Nilo', 'Yasmeen', 'Mina'
];

const afghanProvinces = [
  'Kabul', 'Herat', 'Kandahar', 'Balkh', 'Nangarhar', 'Takhar', 'Badakhshan',
  'Ghazni', 'Paktia', 'Kunduz', 'Baghlan', 'Logar', 'Nangarhar', 'Parwan'
];

const languages = ['Dari', 'Pashto', 'Urdu', 'English', 'Arabic'];
const interests = ['Reading', 'Cooking', 'Travel', 'Photography', 'Music', 'Art', 'Hiking', 'Nature', 'Family', 'Culture'];

// Function to create placeholder image URL
function createPlaceholderImageUrl(gender, index) {
  // Use placeholder images that can be replaced later with actual storage uploads
  const placeholderImages = {
    male: [
      'https://i.pravatar.cc/300?img=1',
      'https://i.pravatar.cc/300?img=2', 
      'https://i.pravatar.cc/300?img=3',
      'https://i.pravatar.cc/300?img=4',
      'https://i.pravatar.cc/300?img=5'
    ],
    female: [
      'https://i.pravatar.cc/300?img=6',
      'https://i.pravatar.cc/300?img=7',
      'https://i.pravatar.cc/300?img=8', 
      'https://i.pravatar.cc/300?img=9',
      'https://i.pravatar.cc/300?img=10'
    ]
  };
  
  const imageUrl = placeholderImages[gender][index % placeholderImages[gender].length];
  console.log(`🖼️  Using placeholder image for ${gender} ${index + 1}: ${imageUrl}`);
  return imageUrl;
}

// Function to upload image to Firebase Storage (disabled for now)
async function uploadImageToStorage(filePath, fileName) {
  console.log(`⚠️  Storage upload currently disabled, using placeholder images`);
  console.log(`📁 Original image: ${fileName}`);
  return null;
}

// Function to create a comprehensive profile
function createProfileData(user, imageUrl, gender) {
  const firstName = gender === 'male' 
    ? maleNames[Math.floor(Math.random() * maleNames.length)]
    : femaleNames[Math.floor(Math.random() * femaleNames.length)];
  
  const lastName = maleNames[Math.floor(Math.random() * maleNames.length)]; // Using male names as last names
  const displayName = `${firstName} ${lastName}`;
  const age = 20 + Math.floor(Math.random() * 15); // Ages 20-35
  const birthYear = 1990 - age + 2024; // Current year 2024
  
  const selectedLanguages = [languages[Math.floor(Math.random() * 2)], languages[Math.floor(Math.random() * 2) + 1]];
  const selectedInterests = [];
  for (let i = 0; i < 3 + Math.floor(Math.random() * 3); i++) {
    const interest = interests[Math.floor(Math.random() * interests.length)];
    if (!selectedInterests.includes(interest)) {
      selectedInterests.push(interest);
    }
  }

  return {
    uid: user.uid,
    email: user.email,
    displayName: displayName,
    age: age,
    birthDate: admin.firestore.Timestamp.fromDate(new Date(birthYear, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28))),
    gender: gender,
    location: afghanProvinces[Math.floor(Math.random() * afghanProvinces.length)],
    bio: `I am a ${age}-year-old ${gender === 'male' ? 'man' : 'woman'} from Afghanistan looking for a meaningful relationship. I value family, traditions, and cultural heritage.`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    
    // Profile images
    images: [imageUrl],
    profileImage: imageUrl,
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

// Main function to create sample profiles
async function createSampleProfiles() {
  console.log('🚀 Creating Sample Profiles with Seed Images...\n');

  try {
    // Get male image files
    const maleImagesDir = '../seed_images/male';
    const femaleImagesDir = '../seed_images/female';
    
    const maleImageFiles = fs.readdirSync(maleImagesDir);
    const femaleImageFiles = fs.readdirSync(femaleImagesDir);

    console.log(`📁 Found ${maleImageFiles.length} male images and ${femaleImageFiles.length} female images`);

    // Create profiles
    const profilesToCreate = 6; // 3 male, 3 female
    const createdProfiles = [];

    for (let i = 0; i < profilesToCreate; i++) {
      const gender = i < 3 ? 'male' : 'female';
      const imageFiles = gender === 'male' ? maleImageFiles : femaleImageFiles;
      const imagesDir = gender === 'male' ? maleImagesDir : femaleImagesDir;
      
      // Use a different image for each profile
      const imageFile = imageFiles[i % imageFiles.length];
      const imagePath = path.join(imagesDir, imageFile);
      const firebaseImageName = `${gender}_profile_${i + 1}_${Date.now()}.jpg`;

      console.log(`\n📸 Processing ${gender} profile ${i + 1}:`);
      console.log(`   Image: ${imageFile}`);

      // Use placeholder image URL for now
      const imageUrl = createPlaceholderImageUrl(gender, i);
      
      if (!imageUrl) {
        console.log(`⚠️  Skipping profile due to image failure`);
        continue;
      }

      // Create Firebase Auth user
      const email = `sample${gender}${i + 1}@aroosi.app`;
      const password = 'Sample123!';
      const displayName = `Sample ${gender} ${i + 1}`;

      const userRecord = await auth.createUser({
        email: email,
        password: password,
        displayName: displayName,
        emailVerified: true,
      });

      console.log(`✅ Firebase Auth user created: ${email}`);
      console.log(`   UID: ${userRecord.uid}`);

      // Create comprehensive profile data
      const profileData = createProfileData(userRecord, imageUrl, gender);

      // Save to Firestore
      await db.collection('profiles').doc(userRecord.uid).set(profileData);
      console.log(`✅ Firestore profile created for ${displayName}`);

      createdProfiles.push({
        uid: userRecord.uid,
        email: email,
        displayName: displayName,
        gender: gender,
        imageUrl: imageUrl
      });
    }

    console.log('\n🎉 Profile Creation Summary:');
    console.log(`✅ Successfully created ${createdProfiles.length} sample profiles`);
    
    console.log('\n📋 Created Profiles:');
    createdProfiles.forEach((profile, index) => {
      console.log(`${index + 1}. ${profile.displayName} (${profile.gender})`);
      console.log(`   Email: ${profile.email}`);
      console.log(`   UID: ${profile.uid}`);
      console.log(`   Image: ${profile.imageUrl}`);
      console.log('');
    });

    console.log('💡 To test these profiles in the app:');
    console.log('1. Use the email addresses above to login');
    console.log('2. Default password: Sample123!');
    console.log('3. All profiles have complete cultural profiles and images');

  } catch (error) {
    console.error('❌ Error creating sample profiles:', error);
    if (error.code) {
      console.error('Error code:', error.code);
      console.error('Error message:', error.message);
    }
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

module.exports = { createSampleProfiles, uploadImageToStorage };
