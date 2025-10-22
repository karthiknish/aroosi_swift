const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'aroosi-ios'
});

const db = admin.firestore();
const storage = admin.storage();

// Additional Afghan names for more variety
const maleNames = [
  'Hamid', 'Omar', 'Aziz', 'Rafi', 'Karim', 'Yusuf', 'Bashir', 'Wali',
  'Nader', 'Farid', 'Shah', 'Faisal', 'Musa', 'Gulzar', 'Saeed',
  'Zaman', 'Anwar', 'Jamaal', 'Ismail', 'Qasim', 'Shir', 'Talib'
];

const femaleNames = [
  'Laila', 'Roya', 'Sakina', 'Mariam', 'Zeenat', 'Nilo', 'Yasmeen', 'Homa',
  'Shirin', 'Parwana', 'Roshan', 'Banu', 'Ameena', 'Soraya', 'Leila',
  'Gulnar', 'Fahima', 'Zarifa', 'Shabnam', 'Nadia', 'Sahar'
];

const afghanProvinces = [
  'Kabul', 'Herat', 'Kandahar', 'Balkh', 'Nangarhar', 'Takhar', 'Badakhshan',
  'Ghazni', 'Paktia', 'Kunduz', 'Baghlan', 'Logar', 'Parwan'
];

const languages = ['Dari', 'Pashto', 'Urdu', 'English', 'Arabic', 'Persian'];
const interests = [
  'Reading', 'Cooking', 'Travel', 'Photography', 'Music', 'Art', 'Hiking', 'Nature',
  'Family', 'Culture', 'Poetry', 'Education', 'Sports', 'Gardening', 'Technology',
  'History', 'Writing', 'Dance', 'Crafts', 'Volunteering', 'Business', 'Teaching'
];

// Seed images for additional profiles
const maleImages = [
  '../seed_images/male/7d47cd7939b7040c529e87e30939f828.jpg',
  '../seed_images/male/7dced5b45e8869ca68492a74eab8eae0.jpg',
  '../seed_images/male/8be2e47fc3e7d1373967e10c341a817c.jpg',
  '../seed_images/male/94cbe1e49d1871c5d2b35fb5f8dbde5f.jpg',
  '../seed_images/male/122234_oct_8be2e47fc3e7d1373967e10c341a817c.jpg',
  '../seed_images/male/cf53da9d906cda72ae8f9cb1921ac052.jpg'
];

const femaleImages = [
  '../seed_images/female/6d6132211e670b5edfbbd514e2dbe655.jpg',
  '../seed_images/female/8baeedf9b017a22cb1ff87756faf3947.jpg',
  '../seed_images/female/d23f49e0ab8eb3d72a823ee4896c7635.jpg',
  '../seed_images/female/dcfba52c35b75889e0e709b07c219109.jpg',
  '../seed_images/female/e7d66fdbc7135c353b8566d51f5c2222.jpg',
  '../seed_images/female/143540_oct_8baeedf9b017a22cb1ff87756faf3947.jpg'
];

// Function to create profile data
function createProfileData(uid, gender, index) {
  const firstName = gender === 'male' 
    ? maleNames[Math.floor(Math.random() * maleNames.length)]
    : femaleNames[Math.floor(Math.random() * femaleNames.length)];
  
  const lastName = maleNames[Math.floor(Math.random() * maleNames.length)];
  const displayName = `${firstName} ${lastName}`;
  const age = 18 + Math.floor(Math.random() * 17); // Ages 18-35
  
  // Create multiple interest combinations for variety
  const selectedLanguages = [];
  for (let i = 0; i < 2 + Math.floor(Math.random() * 2); i++) {
    const lang = languages[Math.floor(Math.random() * languages.length)];
    if (!selectedLanguages.includes(lang)) {
      selectedLanguages.push(lang);
    }
  }

  const selectedInterests = [];
  const numInterests = 2 + Math.floor(Math.random() * 4);
  for (let i = 0; i < numInterests; i++) {
    const interest = interests[Math.floor(Math.random() * interests.length)];
    if (!selectedInterests.includes(interest)) {
      selectedInterests.push(interest);
    }
  }

  const placeholderImage = gender === 'male' 
    ? `https://i.pravatar.cc/300?img=${index + 7}` // Start from 7 for new profiles
    : `https://i.pravatar.cc/300?img=${index + 13}`;

  // Religious practice variation for more realistic profiles
  const religiousPractices = ['very_practicing', 'moderately_practicing', 'somewhat_practicing', 'not_practicing'];
  const familyValues = ['traditional', 'modern', 'mixed', 'liberal'];
  const marriageViews = ['love_marriage', 'arranged_marriage', 'both', 'family_approval'];
  const traditionalValues = ['very_important', 'somewhat_important', 'not_important'];

  return {
    uid: uid,
    email: `sample${gender}${index + 7}@aroosi.app`, // Start from 7
    displayName: displayName,
    age: age,
    gender: gender,
    location: afghanProvinces[Math.floor(Math.random() * afghanProvinces.length)],
    bio: `I am a ${age}-year-old ${gender === 'male' ? 'man' : 'woman'} from Afghanistan, bringing traditional values while embracing modern opportunities. I believe in building meaningful connections based on respect, understanding, and shared cultural heritage.`,
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

    // Cultural profile with more variations
    culturalProfile: {
      religion: 'islam',
      religiousPractice: religiousPractices[Math.floor(Math.random() * religiousPractices.length)],
      motherTongue: selectedLanguages[0],
      languages: selectedLanguages,
      familyValues: familyValues[Math.floor(Math.random() * familyValues.length)],
      marriageViews: marriageViews[Math.floor(Math.random() * marriageViews.length)],
      traditionalValues: traditionalValues[Math.floor(Math.random() * traditionalValues.length)],
      ethnicity: 'afghan',
      religionImportance: 5 + Math.floor(Math.random() * 5),
      cultureImportance: 5 + Math.floor(Math.random() + 5),
      familyBackground: `Growing up in Afghanistan has shaped my worldview and values. I come from a family that values both tradition and education, and I hope to find someone who understands this balance.`,
      familyApprovalImportance: ['very_important', 'somewhat_important', 'not_important'][Math.floor(Math.random() * 3)],
      
      // Cultural compatibility metrics
      languagePreference: 'matches',
      dietaryRestrictions: 'halal_compliant',
      culturalPractices: ['prayer_times', 'family_gatherings', 'cultural_events'],
    },

    // Enhanced preferences
    preferences: {
      minAge: 18,
      maxAge: 40,
      location: '阿富汗', // Using Afghan text for variation
      religion: 'islam',
      religiousPractice: 'varies',
      educationLevel: ['high_school', 'bachelor', 'master', 'phd'][Math.floor(Math.random() * 4)],
      occupation: ['student', 'professional', 'entrepreneur', 'teacher', 'government', 'healthcare'][Math.floor(Math.random() * 6)],
    },

    // Status and activity
    isOnline: Math.random() > 0.3,
    lastSeen: new Date().toISOString(),
    status: 'active',
    
    // Additional profile features
    height: 160 + Math.floor(Math.random() * 30), // 160-190cm
    education: ['high_school', 'bachelor', 'master', 'phd'][Math.floor(Math.random() * 4)],
    occupation: ['student', 'professional', 'entrepreneur', 'teacher', 'healthcare'][Math.floor(Math.random() * 5)],
    relationshipStatus: 'single',
    
    // Social features
    socialProfiles: ['moderate', 'private', 'public'][Math.floor(Math.random() * 3)],
    smokingStatus: 'non_smoker',
    alcoholUse: 'occasional',
    interestsDetail: {
      professional: selectedInterests.filter(i => ['Technology', 'Business', 'Teaching'].includes(i)),
      recreational: selectedInterests.filter(i => ['Travel', 'Photography', 'Music', 'Art'].includes(i)),
      social: selectedInterests.filter(i => ['Family', 'Culture', 'Community'].includes(i)),
    },
    
    // Personality traits
    personalityTraits: {
      openness: 3 + Math.floor(Math.random() * 5), // 3-8 scale
      conscientiousness: 2 + Math.floor(Math.random() + 6), // 2-8 scale
      agreeableness: 2 + Math.floor(Math.random() + 6), // 2-8 scale
      extraversion: 2 + Math.floor(Math.random() + 6), // 2-8 scale
    },
    
    // Communication preferences
    communicationStyle: ['formal', 'casual', 'warm'][Math.floor(Math.random() + 3)],
    preferredContact: ['message_first', 'video_chat', 'in_person'][Math.floor(Math.random() + 3)],
  };
}

// Function to generate UUID
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

async function uploadImageToStorage(localPath, storageName) {
  try {
    console.log(`📤 Uploading ${storageName}...`);
    
    const bucket = storage.bucket();
    const file = bucket.file(`profile-images/${storageName}`);
    
    // Upload image
    await bucket.upload(localPath, {
      destination: `profile-images/${storageName}`,
      metadata: {
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      }
    });

    // Make file publicly readable
    await file.makePublic();
    
    const publicUrl = `https://storage.googleapis.com/aroosi-ios.firebasestorage.app/profile-images/${storageName}`;
    console.log(`✅ Uploaded: ${storageName}`);
    
    return publicUrl;
  } catch (error) {
    console.error(`❌ Failed to upload ${storageName}:`, error.message);
    return null;
  }
}

// Main function to create additional profiles
async function createAdditionalProfiles() {
  console.log('🚀 Creating Additional Sample Profiles (Total: 12 profiles)...\n');

  try {
    const profilesToCreate = 6; // 3 male, 3 female (additional)
    const createdProfiles = [];
    let imageIndex = 0;

    for (let i = 0; i < profilesToCreate; i++) {
      const gender = i < 3 ? 'male' : 'female';
      const uid = generateUUID();

      console.log(`\n📸 Creating ${gender} profile ${i + 7}:`);

      // Create comprehensive profile data
      const profileData = createProfileData(uid, gender, i + 7); // +7 to continue numbering
      
      // Upload the corresponding seed image
      const imagePath = gender === 'male' ? maleImages[imageIndex] : femaleImages[imageIndex];
      const storageName = `${gender}_profile_${i + 7}.jpg`;
      
      let imageUrl = placeholderImage; // fallback
      
      try {
        imageUrl = await uploadImageToStorage(imagePath, storageName);
        imageIndex++;
      } catch (error) {
        console.log(`⚠️  Using placeholder for ${profileData.displayName} - upload failed`);
        console.log(`   Error: ${error.message}`);
      }

      // Update profile data with correct image URL
      profileData.profileImage = imageUrl;
      profileData.images = [imageUrl];
      profileData.hasCustomImage = imageUrl !== placeholderImage;

      // Update profile data with actual image URL
      profileData.updatedAt = new Date().toISOString();

      // Save to Firestore
      await db.collection('profiles').doc(uid).set(profileData);
      console.log(`✅ Profile created: ${profileData.displayName}`);
      console.log(`   👤 Age: ${profileData.age} | Location: ${profileData.location}`);
      console.log(`   ❤️  Religion: ${profileData.culturalProfile.religiousPractice?.replace('_', ' ')}`);
      console.log(`   🖼️  Image: ${imageUrl}`);

      createdProfiles.push({
        uid: uid,
        email: profileData.email,
        displayName: profileData.displayName,
        gender: gender,
        age: profileData.age,
        location: profileData.location,
        imageUrl: profileData.profileImage,
        education: profileData.education,
        occupation: profileData.occupation,
        interests: profileData.interests,
        religiousPractice: profileData.culturalProfile.religiousPractice,
        familyValues: profileData.culturalProfile.familyValues,
        marriageViews: profileData.culturalProfile.marriageViews,
        imageUrl: profileData.profileImage
      });
    }

    console.log('\n🎉 Additional Profiles Created Successfully!');
    console.log(`✅ Total profiles now: ${createdProfiles.length + 6}`)
    
    console.log('\n📋 New Profiles Created:');
    createdProfiles.forEach((profile, index) => {
      console.log(`${index + 7}. ${profile.displayName} (${profile.gender})`);
      console.log(`   👤 Age: ${profile.age} | Education: ${profile.education}`);
      console.log(`   💼 Occupation: ${profile.occupation}`);
      console.log(`   ❤️  Religious: ${profile.religiousPractice}`);
      console.log(`   💬️  Family Values: ${profile.familyValues}`);
      console.log(`   🖼️  Image: ${profile.imageUrl}`);
      console.log('');
    });

    console.log('📊 Database Statistics:');
    console.log(`   Male Profiles: ${createdProfiles.filter(p => p.gender === 'male').length}/9`);
    console.log(`   Female Profiles: ${createdProfiles.filter(p => p.gender === 'female').length}/12`);
    console.log(`   Age Range: 18-35`);

  } catch (error) {
    console.error('❌ Error creating additional profiles:', error);
    throw error;
  }
}

// Function to get total profile count
async function getTotalProfileCount() {
  try {
    const snapshot = await db.collection('profiles').get();
    return snapshot.size;
  } catch (error) {
    console.error('❌ Error counting profiles:', error.message);
    return 0;
  }
}

// Run the script
if (require.main === module) {
  createAdditionalProfiles()
    .then(() => {
      getTotalProfileCount()
        .then(count => {
          console.log(`\n🎊 Total profiles in database: ${count}`);
          console.log('💡 Your aroosi app now has a robust dataset for testing!');
          process.exit(0);
        });
    })
    .catch((error) => {
      console.error('\n💥 Failed to create additional profiles');
      process.exit(1);
    });
}

module.exports = { createAdditionalProfiles, getTotalProfileCount };
