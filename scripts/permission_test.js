const admin = require('firebase-admin');

// Test basic permissions
async function testBasicPermissions() {
  console.log('🔍 Testing Firebase Service Account Permissions...\n');

  try {
    const serviceAccount = require('./service-account.json');
    console.log(`📊 Service Account Info:`);
    console.log(`   Project: ${serviceAccount.project_id}`);
    console.log(`   Email: ${serviceAccount.client_email}`);
    
    // Initialize Admin SDK
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });
    
    const db = admin.firestore();

    // Test 1: Read permissions (basic)
    console.log('\n🧪 Testing READ permissions...');
    try {
      const testCollection = db.collection('profiles').limit(1).get();
      console.log('✅ READ permissions: OK');
    } catch (error) {
      console.log(`❌ READ permissions: FAILED - ${error.message}`);
    }

    // Test 2: Write permissions (create a test doc)
    console.log('\n🧪 Testing WRITE permissions...');
    try {
      const testDoc = {
        test: true,
        timestamp: new Date().toISOString()
      };
      
      await db.collection('_permissions_test').doc('test').set(testDoc);
      console.log('✅ WRITE permissions: OK');
      
      // Clean up
      await db.collection('_permissions_test').doc('test').delete();
      console.log('✅ DELETE permissions: OK');
      
    } catch (error) {
      console.log(`❌ WRITE permissions: FAILED - ${error.message}`);
      console.log(`   Error Code: ${error.code || 'N/A'}`);
    }

    // Test 3: List collections
    console.log('\n🧪 Testing LIST permissions...');
    try {
      const collections = await db.listCollections();
      console.log(`✅ LIST permissions: OK (${collections.length} collections found)`);
    } catch (error) {
      console.log(`❌ LIST permissions: FAILED - ${error.message}`);
    }

    console.log('\n📋 Permission Test Complete.');
    
  } catch (error) {
    console.error('❌ Service Account Test Failed:', error.message);
  }
}

// Additional helper to check current IAM policy
async function checkIAMPolicy() {
  console.log('⚙️  Checking Current IAM Configuration...\n');
  console.log('🔗 To check and modify IAM permissions:');
  console.log('1. Go to: https://console.cloud.google.com/iam-admin/iam');
  console.log('2. Select project: aroosi-ios');
  console.log('3. Find: firebase-adminsdk-fbsvc@aroosi-ios.iam.gserviceaccount.com');
  console.log('4. Edit permissions and ensure these roles are:');
  console.log('   ✅ roles/datastore.editor');
  console.log('   ✅ roles/datastore.user');
  console.log('   ✅ roles/firebase.admin');
  console.log('   ✅ roles/datastore.viewer');
}

// Main execution
if (require.main === module) {
  testBasicPermissions()
    .then(() => checkIAMPolicy())
    .catch((error) => {
      console.error('\n💥 Permission test failed');
      process.exit(1);
    });
}

module.exports = { testBasicPermissions };
