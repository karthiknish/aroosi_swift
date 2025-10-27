#!/usr/bin/env node
/**
 * Setup script for CI/CD configuration
 * Helps configure GitHub secrets and validate setup
 */
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');

function main() {
  console.log('🚀 Setting up CI/CD for Aroosi Flutter App');
  console.log('=' .repeat(50));

  // Check required files exist
  const requiredFiles = [
    '.github/workflows/ci.yml',
    '.github/workflows/test.yml',
    '.github/workflows/release.yml',
    'android/fastlane/Fastfile',
    'ios/fastlane/Fastfile',
    'scripts/bump-version.js',
    'versioning/build-version.json'
  ];

  console.log('📁 Checking required files...');
  for (const file of requiredFiles) {
    const fullPath = path.join(root, file);
    if (fs.existsSync(fullPath)) {
      console.log(`✅ ${file}`);
    } else {
      console.log(`❌ ${file} - Missing!`);
    }
  }

  console.log('\n🔐 Required GitHub Secrets:');
  console.log('=' .repeat(30));

  const androidSecrets = [
    'ANDROID_PACKAGE_NAME',
    'ANDROID_SIGNING_KEYSTORE_BASE64',
    'ANDROID_KEYSTORE_PASSWORD',
    'ANDROID_KEY_ALIAS',
    'ANDROID_KEY_PASSWORD',
    'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON'
  ];

  const iosSecrets = [
    'IOS_APP_IDENTIFIER',
    'APPLE_ID',
    'APPSTORE_TEAM_ID',
    'APPLE_TEAM_ID',
    'APPSTORE_API_KEY_ID',
    'APPSTORE_API_ISSUER_ID',
    'APPSTORE_API_KEY_P8'
  ];

  console.log('\n📱 Android Secrets:');
  androidSecrets.forEach(secret => {
    console.log(`  - ${secret}`);
  });

  console.log('\n🍎 iOS Secrets:');
  iosSecrets.forEach(secret => {
    console.log(`  - ${secret}`);
  });

  console.log('\n📋 Setup Checklist:');
  console.log('=' .repeat(20));

  const checklist = [
    '1. Create keystore for Android signing',
    '2. Create App Store Connect API key for iOS',
    '3. Set up Google Play service account',
    '4. Add all secrets to GitHub repository',
    '5. Test CI workflow with a PR',
    '6. Configure store listings in fastlane/metadata',
    '7. Test release workflow manually',
    '8. Set up branch protection rules'
  ];

  checklist.forEach((item, index) => {
    console.log(` [ ] ${item}`);
  });

  console.log('\n🎯 Next Steps:');
  console.log('=' .repeat(15));

  console.log('1. Go to GitHub repository settings');
  console.log('2. Navigate to Secrets and variables → Actions');
  console.log('3. Add all the secrets listed above');
  console.log('4. Push these changes to trigger CI');
  console.log('5. Test the release workflow');

  console.log('\n✅ Setup complete! Check the docs/ci-cd.md for detailed instructions.');
}

if (require.main === module) {
  main();
}
