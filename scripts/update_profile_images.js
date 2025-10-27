const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'aroosi-ios',
  storageBucket: 'aroosi-ios.firebasestorage.app'
});

const db = admin.firestore();
const storage = admin.storage();

// Seed images file paths
const maleImages = [
  '../seed_images/male/14773b6e6edddbebb7807e2bed6d27b9.jpg',
  '../seed_images/male/15c4e6ca89f3cb25795c9b9df1413193.jpg',
  '../seed_images/male/1d0c6bb4818de0c1daa2d120f71c877d.jpg'
];

const femaleImages = [
  '../seed_images/female/4d81d1c8ce537b1f798d7c4c86ada984.jpg',
  '../seed_images/female/589bb56f3d572be57cc6150f88f658f3.jpg',
  '../seed_images/female/5b7b20ee78cc2826dd2d514015f741f1.jpg'
];

// Current profile UIDs (from verification)
const profileData = [
  { uid: 'b5636bf7-3f59-4328-9279-068afa27e831', gender: 'male', name: 'Yusuf Mohammad' },
  { uid: '6883d9f7-10e6-4822-98a5-a1fe68492851', gender: 'male', name: 'Abdul Yusuf' },
  { uid: 'ead2e258-eb0b-4c44-a2ec-609156bf5c7d', gender: 'male', name: 'Karim Rashid' },
  { uid: '4ae608a3-745d-4e96-bb78-cd3eee313cbf', gender: 'female', name: 'Nafisa Aziz' },
  { uid: 'b50bf53e-3fa9-4f98-8b99-0d5a44b38bc2', gender: 'female', name: 'Marwa Rashid' },
  { uid: 'a1d1527d-1713-4a2f-86cc-d5bf3621ac0d', gender: 'female', name: 'Zahra Zahoor' }
];

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
    console.log(`✅ Uploaded: ${storageName} -> ${publicUrl}`);
    
    return publicUrl;
  } catch (error) {
    console.error(`❌ Failed to upload ${storageName}:`, error.message);
    return null;
  }
}

async function updateProfileImageUrls() {
  console.log('🔄 Updating Profile Images with Seed Images...\n');

  try {
    for (let i = 0; i < profileData.length; i++) {
      const profile = profileData[i];
      const imageIndex = i < 3 ? i : i - 3; // 0,1,2 for males, 0,1,2 for females
      const imagePath = profile.gender === 'male' ? maleImages[imageIndex] : femaleImages[imageIndex];
      const storageName = `${profile.gender}_profile_${i + 1}.jpg`;
      
      console.log(`\n📸 Processing Profile ${i + 1}: ${profile.name}`);
      console.log(`   Gender: ${profile.gender}`);
      console.log(`   Image: ${path.basename(imagePath)}`);

      // Upload image to storage
      const imageUrl = await uploadImageToStorage(imagePath, storageName);
      
      if (imageUrl) {
        // Update Firestore profile with new image URL
        await db.collection('profiles').doc(profile.uid).update({
          profileImage: imageUrl,
          images: [imageUrl],
          updatedAt: new Date().toISOString()
        });
        
        console.log(`✅ Updated ${profile.name} with seed image`);
        console.log(`   New URL: ${imageUrl}`);
      } else {
        console.log(`⚠️  Skipped ${profile.name} - upload failed`);
      }
    }

    console.log('\n🎉 Profile Image Updates Complete!');
    
    // Verify the updates
    console.log('\n🔍 Verifying updates...');
    
    for (const profile of profileData) {
      const doc = await db.collection('profiles').doc(profile.uid).get();
      const data = doc.data();
      
      console.log(`✅ ${profile.name}: ${data.profileImage}`);
    }

  } catch (error) {
    console.error('❌ Error updating profile images:', error.message);
    throw error;
  }
}

// Main execution
if (require.main === module) {
  updateProfileImageUrls()
    .then(() => {
      console.log('\n🎊 All profile images updated successfully!');
      console.log('💡 Test your aroosi app to see the new seed images!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Failed to update profile images');
      process.exit(1);
    });
}

module.exports = { updateProfileImageUrls };
