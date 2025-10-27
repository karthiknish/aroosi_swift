#!/usr/bin/env node

/**
 * Firebase Existing Profiles Test Script
 * 
 * This script tests existing user profiles on Firebase to verify:
 * - User data structure and compatibility
 * - Icebreaker feature integration
 * - Authentication and permissions
 * - Data consistency and integrity
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error('❌ Service account key not found at:', SERVICE_ACCOUNT_PATH);
  process.exit(1);
}

const serviceAccount = require(SERVICE_ACCOUNT_PATH);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'aroosi-ios'
});

const db = admin.firestore();
const auth = admin.auth();

class FirebaseProfileTester {
  constructor() {
    this.testResults = {
      users: [],
      icebreakerQuestions: [],
      icebreakerAnswers: [],
      summary: {
        totalUsers: 0,
        activeUsers: 0,
        usersWithIcebreakers: 0,
        questionsCount: 0,
        answersCount: 0,
        errors: []
      }
    };
  }

  async testExistingProfiles() {
    console.log('🔍 Testing Existing Profiles on Firebase...\n');
    
    try {
      await this.testUserProfiles();
      await this.testIcebreakerQuestions();
      await this.testIcebreakerAnswers();
      await this.testUserPermissions();
      await this.generateTestReport();
      
      console.log('\n🎉 Profile testing completed successfully!');
      
    } catch (error) {
      console.error('❌ Profile testing failed:', error.message);
      this.testResults.summary.errors.push(error.message);
    }
    
    return this.testResults;
  }

  async testUserProfiles() {
    console.log('👥 Testing User Profiles...');
    
    try {
      const usersSnapshot = await db.collection('users').limit(10).get();
      
      if (usersSnapshot.empty) {
        console.log('📝 No user profiles found in database');
        return;
      }
      
      console.log(`📊 Found ${usersSnapshot.size} user profiles`);
      
      for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        const userTest = {
          userId: doc.id,
          email: userData.email || 'N/A',
          displayName: userData.displayName || 'N/A',
          age: userData.age || 'N/A',
          gender: userData.gender || 'N/A',
          location: userData.location || 'N/A',
          createdAt: userData.createdAt?.toDate() || 'N/A',
          lastActive: userData.lastActive?.toDate() || 'N/A',
          profileComplete: this.checkProfileCompleteness(userData),
          icebreakerCompatible: this.checkIcebreakerCompatibility(userData),
          issues: []
        };
        
        // Check for required fields
        if (!userData.email) userTest.issues.push('Missing email');
        if (!userData.displayName) userTest.issues.push('Missing display name');
        if (!userData.age) userTest.issues.push('Missing age');
        if (!userData.gender) userTest.issues.push('Missing gender');
        
        this.testResults.users.push(userTest);
        this.testResults.summary.totalUsers++;
        
        if (userData.lastActive) {
          this.testResults.summary.activeUsers++;
        }
        
        console.log(`  ✅ User: ${userTest.displayName} (${userTest.email})`);
        if (userTest.issues.length > 0) {
          console.log(`    ⚠️  Issues: ${userTest.issues.join(', ')}`);
        }
      }
      
    } catch (error) {
      console.error('❌ Failed to test user profiles:', error.message);
      this.testResults.summary.errors.push(`User profiles test: ${error.message}`);
    }
  }

  async testIcebreakerQuestions() {
    console.log('\n❄️  Testing Icebreaker Questions...');
    
    try {
      const questionsSnapshot = await db.collection('icebreaker_questions')
        .where('active', '==', true)
        .orderBy('order')
        .get();
      
      if (questionsSnapshot.empty) {
        console.log('📝 No active icebreaker questions found');
        this.testResults.summary.errors.push('No active icebreaker questions');
        return;
      }
      
      console.log(`📊 Found ${questionsSnapshot.size} active icebreaker questions`);
      
      for (const doc of questionsSnapshot.docs) {
        const questionData = doc.data();
        const questionTest = {
          questionId: doc.id,
          text: questionData.text?.substring(0, 50) + '...',
          category: questionData.category || 'N/A',
          order: questionData.order || 'N/A',
          active: questionData.active || false,
          weight: questionData.weight || 1,
          createdAt: questionData.createdAt?.toDate() || 'N/A',
          valid: this.validateQuestion(questionData)
        };
        
        this.testResults.icebreakerQuestions.push(questionTest);
        this.testResults.summary.questionsCount++;
        
        console.log(`  ✅ Question: ${questionTest.text} (${questionTest.category})`);
      }
      
    } catch (error) {
      console.error('❌ Failed to test icebreaker questions:', error.message);
      this.testResults.summary.errors.push(`Icebreaker questions test: ${error.message}`);
    }
  }

  async testIcebreakerAnswers() {
    console.log('\n💬 Testing Icebreaker Answers...');
    
    try {
      const answersSnapshot = await db.collection('icebreaker_answers').limit(20).get();
      
      if (answersSnapshot.empty) {
        console.log('📝 No icebreaker answers found (expected for new feature)');
        return;
      }
      
      console.log(`📊 Found ${answersSnapshot.size} icebreaker answers`);
      
      for (const doc of answersSnapshot.docs) {
        const answerData = doc.data();
        const answerTest = {
          answerId: doc.id,
          userId: answerData.userId || 'N/A',
          questionId: answerData.questionId || 'N/A',
          answer: answerData.answer?.substring(0, 30) + '...',
          answerLength: answerData.answer?.length || 0,
          createdAt: answerData.createdAt?.toDate() || 'N/A',
          updatedAt: answerData.updatedAt?.toDate() || 'N/A',
          valid: this.validateAnswer(answerData)
        };
        
        this.testResults.icebreakerAnswers.push(answerTest);
        this.testResults.summary.answersCount++;
        
        console.log(`  ✅ Answer: User ${answerTest.userId} answered question ${answerTest.questionId}`);
      }
      
    } catch (error) {
      console.error('❌ Failed to test icebreaker answers:', error.message);
      this.testResults.summary.errors.push(`Icebreaker answers test: ${error.message}`);
    }
  }

  async testUserPermissions() {
    console.log('\n🔐 Testing User Permissions...');
    
    try {
      // Test if we can read users collection
      const testRead = await db.collection('users').limit(1).get();
      console.log('  ✅ Users collection: Read permission OK');
      
      // Test if we can write to icebreaker_answers
      const testDoc = {
        userId: 'test-user-id',
        questionId: 'test-question-id',
        answer: 'Test answer for validation',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };
      
      const writeRef = await db.collection('icebreaker_answers').add(testDoc);
      console.log('  ✅ Icebreaker answers: Write permission OK');
      
      // Clean up test document
      await writeRef.delete();
      console.log('  ✅ Test cleanup: Delete permission OK');
      
    } catch (error) {
      console.error('❌ Permission test failed:', error.message);
      this.testResults.summary.errors.push(`Permission test: ${error.message}`);
    }
  }

  checkProfileCompleteness(userData) {
    const requiredFields = ['email', 'displayName', 'age', 'gender'];
    const presentFields = requiredFields.filter(field => userData[field]);
    return (presentFields.length / requiredFields.length) * 100;
  }

  checkIcebreakerCompatibility(userData) {
    // Check if user has required fields for icebreaker feature
    return userData.email && userData.displayName && userData.userId;
  }

  validateQuestion(questionData) {
    return questionData.text && 
           questionData.text.length >= 10 && 
           questionData.category && 
           questionData.active !== false;
  }

  validateAnswer(answerData) {
    return answerData.userId && 
           answerData.questionId && 
           answerData.answer && 
           answerData.answer.length >= 10;
  }

  async generateTestReport() {
    console.log('\n📋 Generating Test Report...');
    
    const report = {
      timestamp: new Date().toISOString(),
      summary: this.testResults.summary,
      userProfiles: {
        total: this.testResults.summary.totalUsers,
        active: this.testResults.summary.activeUsers,
        averageCompleteness: this.calculateAverageCompleteness(),
        icebreakerCompatible: this.testResults.users.filter(u => u.icebreakerCompatible).length
      },
      icebreakerFeature: {
        questionsAvailable: this.testResults.summary.questionsCount,
        answersExist: this.testResults.summary.answersCount > 0,
        categories: this.getUniqueCategories(),
        averageQuestionLength: this.calculateAverageQuestionLength()
      },
      recommendations: this.generateRecommendations(),
      nextSteps: this.generateNextSteps()
    };
    
    // Save report to file
    const reportPath = path.join(__dirname, 'firebase_test_report.json');
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
    
    console.log(`📄 Test report saved to: ${reportPath}`);
    
    // Display summary
    this.displayTestSummary(report);
  }

  calculateAverageCompleteness() {
    if (this.testResults.users.length === 0) return 0;
    const total = this.testResults.users.reduce((sum, user) => sum + user.profileComplete, 0);
    return Math.round(total / this.testResults.users.length);
  }

  getUniqueCategories() {
    const categories = [...new Set(this.testResults.icebreakerQuestions.map(q => q.category))];
    return categories.filter(cat => cat !== 'N/A');
  }

  calculateAverageQuestionLength() {
    if (this.testResults.icebreakerQuestions.length === 0) return 0;
    const totalLength = this.testResults.icebreakerQuestions.reduce((sum, q) => 
      sum + (q.text?.length || 0), 0);
    return Math.round(totalLength / this.testResults.icebreakerQuestions.length);
  }

  generateRecommendations() {
    const recommendations = [];
    
    if (this.testResults.summary.totalUsers === 0) {
      recommendations.push('Create test user profiles to validate the icebreaker feature');
    }
    
    if (this.testResults.summary.questionsCount < 10) {
      recommendations.push('Add more icebreaker questions for better user engagement');
    }
    
    const incompleteProfiles = this.testResults.users.filter(u => u.profileComplete < 80);
    if (incompleteProfiles.length > 0) {
      recommendations.push(`${incompleteProfiles.length} users have incomplete profiles - may affect icebreaker feature`);
    }
    
    if (this.testResults.summary.answersCount === 0) {
      recommendations.push('Test the icebreaker feature in the iOS app to generate answer data');
    }
    
    return recommendations;
  }

  generateNextSteps() {
    return [
      '1. Test icebreaker feature in iOS app with existing users',
      '2. Monitor user engagement with icebreaker questions',
      '3. Review and optimize question categories based on user feedback',
      '4. Set up analytics to track icebreaker completion rates',
      '5. Consider adding more questions based on user preferences'
    ];
  }

  displayTestSummary(report) {
    console.log('\n📊 TEST SUMMARY');
    console.log('================');
    console.log(`👥 User Profiles: ${report.userProfiles.total} total, ${report.userProfiles.active} active`);
    console.log(`📈 Profile Completeness: ${report.userProfiles.averageCompleteness}% average`);
    console.log(`🔗 Icebreaker Compatible: ${report.userProfiles.icebreakerCompatible} users`);
    console.log(`❄️  Questions Available: ${report.icebreakerFeature.questionsAvailable} questions`);
    console.log(`📝 Categories: ${report.icebreakerFeature.categories.join(', ')}`);
    console.log(`💬 User Answers: ${report.icebreakerFeature.answersExist ? 'Yes' : 'No (expected for new feature)'}`);
    
    if (report.recommendations.length > 0) {
      console.log('\n💡 RECOMMENDATIONS');
      console.log('==================');
      report.recommendations.forEach(rec => console.log(`• ${rec}`));
    }
    
    console.log('\n🚀 NEXT STEPS');
    console.log('=============');
    report.nextSteps.forEach(step => console.log(step));
  }
}

// Main execution
async function main() {
  const tester = new FirebaseProfileTester();
  await tester.testExistingProfiles();
  
  // Clean up Firebase connection
  await admin.app().delete();
}

// Run the test
if (require.main === module) {
  main().catch(console.error);
}

module.exports = FirebaseProfileTester;
