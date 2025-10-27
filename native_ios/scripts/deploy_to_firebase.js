#!/usr/bin/env node

/**
 * Firebase Deployment Script for Icebreaker Feature
 * 
 * This script deploys the icebreaker feature to Firebase including:
 * - Firestore collections setup
 * - Sample questions data
 * - Security rules configuration
 * - Indexes creation
 * 
 * Usage: node deploy_to_firebase.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Configuration
const PROJECT_ID = 'aroosi-ios';
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');

// Sample icebreaker questions
const icebreakerQuestions = [
  {
    text: "What's your favorite family tradition that you'd like to continue?",
    category: "family",
    weight: 1,
    active: true,
    order: 1
  },
  {
    text: "How do you balance modern life with traditional Islamic values?",
    category: "values",
    weight: 1,
    active: true,
    order: 2
  },
  {
    text: "What qualities do you value most in a life partner?",
    category: "relationships",
    weight: 1,
    active: true,
    order: 3
  },
  {
    text: "Describe your ideal weekend with your future spouse.",
    category: "lifestyle",
    weight: 1,
    active: true,
    order: 4
  },
  {
    text: "What role does faith play in your daily life?",
    category: "religious",
    weight: 1,
    active: true,
    order: 5
  },
  {
    text: "How do you like to spend time with family?",
    category: "family",
    weight: 1,
    active: true,
    order: 6
  },
  {
    text: "What's your favorite way to de-stress after a long day?",
    category: "lifestyle",
    weight: 1,
    active: true,
    order: 7
  },
  {
    text: "How important is cultural heritage in your life?",
    category: "cultural",
    weight: 1,
    active: true,
    order: 8
  },
  {
    text: "What are your thoughts on halal dating and getting to know someone?",
    category: "relationships",
    weight: 1,
    active: true,
    order: 9
  },
  {
    text: "Describe your relationship with your extended family.",
    category: "family",
    weight: 1,
    active: true,
    order: 10
  },
  {
    text: "What hobbies or activities bring you joy?",
    category: "lifestyle",
    weight: 1,
    active: true,
    order: 11
  },
  {
    text: "How do you envision balancing career and family life?",
    category: "values",
    weight: 1,
    active: true,
    order: 12
  },
  {
    text: "What's your favorite Islamic quote or verse and why?",
    category: "religious",
    weight: 1,
    active: true,
    order: 13
  },
  {
    text: "How do you prefer to celebrate special occasions?",
    category: "cultural",
    weight: 1,
    active: true,
    order: 14
  },
  {
    text: "What are your goals for personal growth in the next 5 years?",
    category: "values",
    weight: 1,
    active: true,
    order: 15
  }
];

// Security rules for Firestore
const securityRules = {
  rules: {
    icebreaker_questions: {
      allow: {
        read: "request.auth != null",
        write: "request.auth != null && resource.data.active == true"
      }
    },
    icebreaker_answers: {
      allow: {
        read: "request.auth != null && request.auth.uid == resource.data.userId",
        write: "request.auth != null && request.auth.uid == resource.data.userId"
      }
    }
  }
};

// Composite indexes for optimal queries
const indexes = {
  indexes: [
    {
      collectionGroup: "icebreaker_questions",
      queryScope: "COLLECTION",
      fields: [
        {
          fieldPath: "active",
          order: "ASCENDING"
        },
        {
          fieldPath: "order",
          order: "ASCENDING"
        }
      ]
    },
    {
      collectionGroup: "icebreaker_answers",
      queryScope: "COLLECTION",
      fields: [
        {
          fieldPath: "userId",
          order: "ASCENDING"
        },
        {
          fieldPath: "createdAt",
          order: "DESCENDING"
        }
      ]
    }
  ]
};

class FirebaseDeployer {
  constructor() {
    this.db = null;
    this.initialized = false;
  }

  async initialize() {
    try {
      console.log('🔧 Initializing Firebase Admin SDK...');
      
      // Check if service account file exists
      if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
        console.error('❌ Service account key not found at:', SERVICE_ACCOUNT_PATH);
        console.log('💡 Download service account key from Firebase Console:');
        console.log('   1. Go to Firebase Console → Project Settings → Service Accounts');
        console.log('   2. Click "Generate new private key"');
        console.log('   3. Save as serviceAccountKey.json in scripts directory');
        process.exit(1);
      }

      const serviceAccount = require(SERVICE_ACCOUNT_PATH);
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: PROJECT_ID
      });

      this.db = admin.firestore();
      this.initialized = true;
      
      console.log('✅ Firebase Admin SDK initialized successfully');
      console.log(`📊 Connected to project: ${PROJECT_ID}`);
      
    } catch (error) {
      console.error('❌ Failed to initialize Firebase:', error.message);
      process.exit(1);
    }
  }

  async deployQuestions() {
    if (!this.initialized) await this.initialize();
    
    try {
      console.log('\n📝 Deploying icebreaker questions...');
      
      const questionsRef = this.db.collection('icebreaker_questions');
      const batch = this.db.batch();
      
      // Clear existing questions
      console.log('🗑️  Clearing existing questions...');
      const existingQuestions = await questionsRef.get();
      existingQuestions.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      // Add new questions
      console.log('➕ Adding new questions...');
      icebreakerQuestions.forEach((question, index) => {
        const docRef = questionsRef.doc();
        batch.set(docRef, {
          ...question,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });
      
      await batch.commit();
      console.log(`✅ Successfully deployed ${icebreakerQuestions.length} icebreaker questions`);
      
      // Verify deployment
      const snapshot = await questionsRef.get();
      console.log(`📊 Verification: ${snapshot.size} questions in database`);
      
    } catch (error) {
      console.error('❌ Failed to deploy questions:', error.message);
      throw error;
    }
  }

  async deploySecurityRules() {
    if (!this.initialized) await this.initialize();
    
    try {
      console.log('\n🔒 Deploying security rules...');
      
      // For security rules, we need to use Firebase CLI or console
      // This script generates the rules file
      const rulesPath = path.join(__dirname, 'firestore.rules');
      const rulesContent = this.generateRulesFile(securityRules);
      
      fs.writeFileSync(rulesPath, rulesContent);
      console.log(`✅ Security rules generated at: ${rulesPath}`);
      console.log('💡 To deploy rules, run: firebase deploy --only firestore:rules');
      
    } catch (error) {
      console.error('❌ Failed to deploy security rules:', error.message);
      throw error;
    }
  }

  async deployIndexes() {
    if (!this.initialized) await this.initialize();
    
    try {
      console.log('\n📊 Deploying indexes...');
      
      const indexesPath = path.join(__dirname, 'firestore.indexes.json');
      fs.writeFileSync(indexesPath, JSON.stringify(indexes, null, 2));
      
      console.log(`✅ Indexes configuration generated at: ${indexesPath}`);
      console.log('💡 To deploy indexes, run: firebase deploy --only firestore:indexes');
      
    } catch (error) {
      console.error('❌ Failed to deploy indexes:', error.message);
      throw error;
    }
  }

  async verifyDeployment() {
    if (!this.initialized) await this.initialize();
    
    try {
      console.log('\n🔍 Verifying deployment...');
      
      // Check questions collection
      const questionsSnapshot = await this.db.collection('icebreaker_questions').get();
      console.log(`📝 Questions collection: ${questionsSnapshot.size} documents`);
      
      // Check sample question
      if (!questionsSnapshot.empty) {
        const sampleQuestion = questionsSnapshot.docs[0].data();
        console.log('📋 Sample question:', {
          text: sampleQuestion.text?.substring(0, 50) + '...',
          category: sampleQuestion.category,
          active: sampleQuestion.active
        });
      }
      
      // Test collection access
      console.log('🔐 Testing collection access...');
      const testQuery = await this.db.collection('icebreaker_questions')
        .where('active', '==', true)
        .limit(1)
        .get();
      
      console.log(`✅ Active questions query: ${testQuery.size} results`);
      
      console.log('\n🎉 Deployment verification completed successfully!');
      
    } catch (error) {
      console.error('❌ Deployment verification failed:', error.message);
      throw error;
    }
  }

  generateRulesFile(rules) {
    return `rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
${Object.entries(rules.rules).map(([collection, rule]) => {
  return `    match /${collection}/{documentId} {
      allow read: ${rule.allow.read};
      allow write: ${rule.allow.write};
    }`;
}).join('\n')}
  }
}`;
  }

  async deployAll() {
    try {
      console.log('🚀 Starting Firebase deployment for Icebreaker feature...\n');
      
      await this.deployQuestions();
      await this.deploySecurityRules();
      await this.deployIndexes();
      await this.verifyDeployment();
      
      console.log('\n🎊 DEPLOYMENT COMPLETED SUCCESSFULLY!');
      console.log('\n📋 Next steps:');
      console.log('1. Deploy security rules: firebase deploy --only firestore:rules');
      console.log('2. Deploy indexes: firebase deploy --only firestore:indexes');
      console.log('3. Test the feature in your iOS app');
      console.log('4. Monitor Firebase Console for usage');
      
    } catch (error) {
      console.error('\n❌ Deployment failed:', error.message);
      process.exit(1);
    }
  }
}

// Main execution
async function main() {
  const deployer = new FirebaseDeployer();
  
  if (process.argv.includes('--questions-only')) {
    await deployer.deployQuestions();
  } else if (process.argv.includes('--verify-only')) {
    await deployer.verifyDeployment();
  } else {
    await deployer.deployAll();
  }
}

// Handle uncaught errors
process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught exception:', error.message);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Run deployment
if (require.main === module) {
  main();
}

module.exports = FirebaseDeployer;
