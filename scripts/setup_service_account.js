const fs = require('fs');
const path = require('path');

console.log('🔧 Service Account Setup Guide for aroosi-ios\n');

console.log('📋 STEPS TO GET THE CORRECT SERVICE ACCOUNT:\n');

console.log('1️⃣  Open Firebase Console:');
console.log('   https://console.firebase.google.com/project/aroosi-ios/overview\n');

console.log('2️⃣  Navigate to Service Accounts:');
console.log('   Click ⚙️ Project Settings → "Service accounts" tab\n');

console.log('3️⃣  Generate New Key:');
console.log('   Click "Generate new private key" → Select JSON → Click "Generate"\n');

console.log('4️⃣  Download and Move:');
console.log('   Download the JSON file');
console.log('   Move it to: scripts/aroosi-ios-service-account.json\n');

console.log('5️⃣  Run This Script to Replace:');
console.log('   node setup_service_account.js\n');

// Function to backup current service account
function backupCurrentServiceAccount() {
  const currentSAPath = './service-account.json';
  const backupSAPath = './service-account-backup.json';
  
  if (fs.existsSync(currentSAPath)) {
    try {
      fs.copyFileSync(currentSAPath, backupSAPath);
      console.log('✅ Current service account backed up to:', backupSAPath);
      return true;
    } catch (error) {
      console.error('❌ Error backing up service account:', error.message);
      return false;
    }
  } else {
    console.log('ℹ️  No current service account found to backup');
    return true;
  }
}

// Function to replace service account
function replaceServiceAccount() {
  const newSAPath = './aroosi-ios-service-account.json';
  const targetSAPath = './service-account.json';
  
  if (!fs.existsSync(newSAPath)) {
    console.log('\n❌ Service account file not found!');
    console.log('   Please download the aroosi-ios service account as:');
    console.log('   scripts/aroosi-ios-service-account.json');
    console.log('\n📊 Then run this script again.');
    return false;
  }

  try {
    // Backup current
    backupCurrentServiceAccount();
    
    // Verify the new service account format
    const newSA = JSON.parse(fs.readFileSync(newSAPath, 'utf8'));
    
    if (!newSA.project_id) {
      console.log('❌ Invalid service account file format - missing project_id');
      return false;
    }
    
    // Replace the file
    fs.copyFileSync(newSAPath, targetSAPath);
    
    console.log('\n✅ Service account replaced successfully!');
    console.log(`📊 Project ID: ${newSA.project_id}`);
    console.log(`🎯 Service Email: ${newSA.client_email}`);
    
    // Clean up
    fs.unlinkSync(newSAPath);
    console.log('🧹 Removed temporary service account file');
    
    return true;
    
  } catch (error) {
    console.error('\n❌ Error replacing service account:', error.message);
    console.log('   Please check the JSON file is valid and try again.');
    return false;
  }
}

// Function to test the new service account
function testServiceAccount() {
  console.log('\n🧪 Testing Service Account Connection...');
  
  try {
    const admin = require('firebase-admin');
    const serviceAccount = require('./service-account.json');
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });
    
    const db = admin.firestore();
    
    return db.collection('_test').limit(1).get()
      .then(() => {
        console.log('✅ Service account connection successful!');
        console.log(`📊 Connected to project: ${serviceAccount.project_id}`);
        return true;
      })
      .catch((error) => {
        console.log('❌ Service account connection failed:', error.message);
        return false;
      })
      .finally(() => {
        admin.app().delete();
      });
      
  } catch (error) {
    console.log('❌ Service account test failed:', error.message);
    return Promise.resolve(false);
  }
}

// Main execution
async function main() {
  console.log('\n🔄 Looking for new service account file...');
  
  const replacementSuccess = replaceServiceAccount();
  
  if (replacementSuccess) {
    const testSuccess = await testServiceAccount();
    
    if (testSuccess) {
      console.log('\n🎉 Setup Complete!');
      console.log('📋 Your service account is now ready for aroosi-ios');
      console.log('\n🚀 Next steps:');
      console.log('   1. Run: node verify_import.js');
      console.log('   2. Run: node create_profiles_firestore_only.js');
    } else {
      console.log('\n⚠️  Setup completed but connection test failed');
      console.log('   The service account may need additional permissions');
    }
  }
}

// Run if executed directly
if (require.main === module) {
  main().catch((error) => {
    console.error('\n💥 Setup failed:', error.message);
    process.exit(1);
  });
}

module.exports = { backupCurrentServiceAccount, replaceServiceAccount, testServiceAccount };
