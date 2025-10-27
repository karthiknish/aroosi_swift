#!/usr/bin/env node

/**
 * Deployment Readiness Check
 * 
 * This script checks if all prerequisites are met for Firebase deployment
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Checking Firebase deployment readiness...\n');

const checks = [
  {
    name: 'Service Account Key',
    check: () => fs.existsSync('serviceAccountKey.json'),
    required: true,
    fix: 'Download service account key from Firebase Console and save as serviceAccountKey.json'
  },
  {
    name: 'Node.js Dependencies',
    check: () => fs.existsSync('node_modules'),
    required: true,
    fix: 'Run: npm install'
  },
  {
    name: 'Deployment Script',
    check: () => fs.existsSync('deploy_to_firebase.js'),
    required: true,
    fix: 'Ensure deploy_to_firebase.js exists in scripts directory'
  },
  {
    name: 'Security Rules',
    check: () => fs.existsSync('firestore.rules'),
    required: true,
    fix: 'Ensure firestore.rules exists in scripts directory'
  },
  {
    name: 'Index Configuration',
    check: () => fs.existsSync('firestore.indexes.json'),
    required: true,
    fix: 'Ensure firestore.indexes.json exists in scripts directory'
  },
  {
    name: 'Package Configuration',
    check: () => fs.existsSync('package.json'),
    required: true,
    fix: 'Ensure package.json exists in scripts directory'
  },
  {
    name: 'Feature Flag in App.env',
    check: () => {
      const envPath = path.join(__dirname, '../Sources/Resources/App.env');
      if (!fs.existsSync(envPath)) return false;
      const content = fs.readFileSync(envPath, 'utf8');
      return content.includes('ENABLE_ICEBREAKERS=true');
    },
    required: true,
    fix: 'Add ENABLE_ICEBREAKERS=true to Sources/Resources/App.env'
  }
];

let allPassed = true;
let requiredPassed = 0;
let totalRequired = checks.filter(c => c.required).length;

console.log('📋 Running checks:\n');

checks.forEach((check, index) => {
  const passed = check.check();
  const status = passed ? '✅' : '❌';
  const type = check.required ? '[REQUIRED]' : '[OPTIONAL]';
  
  console.log(`${index + 1}. ${status} ${type} ${check.name}`);
  
  if (!passed) {
    console.log(`   💡 Fix: ${check.fix}`);
    if (check.required) {
      allPassed = false;
    }
  } else {
    if (check.required) requiredPassed++;
  }
  console.log('');
});

console.log(`📊 Results: ${requiredPassed}/${totalRequired} required checks passed\n`);

if (allPassed) {
  console.log('🎉 All checks passed! Ready for Firebase deployment.');
  console.log('\n🚀 Next steps:');
  console.log('1. Run: node deploy_to_firebase.js');
  console.log('2. Deploy security rules: firebase deploy --only firestore:rules');
  console.log('3. Deploy indexes: firebase deploy --only firestore:indexes');
  console.log('4. Test in iOS app');
} else {
  console.log('❌ Some required checks failed. Please fix the issues above before deploying.');
  process.exit(1);
}
