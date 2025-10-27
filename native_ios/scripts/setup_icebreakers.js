/**
 * Firebase Icebreaker Questions Setup Script
 * 
 * This script initializes the icebreaker_questions collection with sample questions
 * for the Aroosi Matrimony app. Run this script in Firebase Console or using Firebase CLI.
 * 
 * Usage:
 * 1. Open Firebase Console → Firestore → Database
 * 2. Click "Run query" → "Import" → paste this script
 * 3. Or run: firebase firestore:import --project aroosi-ios icebreaker_data.json
 */

// Sample icebreaker questions for Muslim matrimony
const icebreakerQuestions = [
  {
    text: "What's your favorite family tradition that you'd like to continue?",
    category: "family",
    weight: 1,
    active: true
  },
  {
    text: "How do you balance modern life with traditional Islamic values?",
    category: "values",
    weight: 1,
    active: true
  },
  {
    text: "What qualities do you value most in a life partner?",
    category: "relationships",
    weight: 1,
    active: true
  },
  {
    text: "Describe your ideal weekend with your future spouse.",
    category: "lifestyle",
    weight: 1,
    active: true
  },
  {
    text: "What role does faith play in your daily life?",
    category: "religious",
    weight: 1,
    active: true
  },
  {
    text: "How do you like to spend time with family?",
    category: "family",
    weight: 1,
    active: true
  },
  {
    text: "What's your favorite way to de-stress after a long day?",
    category: "lifestyle",
    weight: 1,
    active: true
  },
  {
    text: "How important is cultural heritage in your life?",
    category: "cultural",
    weight: 1,
    active: true
  },
  {
    text: "What are your thoughts on halal dating and getting to know someone?",
    category: "relationships",
    weight: 1,
    active: true
  },
  {
    text: "Describe your relationship with your extended family.",
    category: "family",
    weight: 1,
    active: true
  },
  {
    text: "What hobbies or activities bring you joy?",
    category: "lifestyle",
    weight: 1,
    active: true
  },
  {
    text: "How do you envision balancing career and family life?",
    category: "values",
    weight: 1,
    active: true
  },
  {
    text: "What's your favorite Islamic quote or verse and why?",
    category: "religious",
    weight: 1,
    active: true
  },
  {
    text: "How do you prefer to celebrate special occasions?",
    category: "cultural",
    weight: 1,
    active: true
  },
  {
    text: "What are your goals for personal growth in the next 5 years?",
    category: "values",
    weight: 1,
    active: true
  }
];

// Firebase Cloud Function to setup icebreaker questions
async function setupIcebreakerQuestions() {
  const admin = require('firebase-admin');
  const serviceAccount = require('./serviceAccountKey.json');
  
  // Initialize Firebase Admin SDK
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  
  const db = admin.firestore();
  
  try {
    console.log('Setting up icebreaker questions...');
    
    // Clear existing questions (optional)
    const existingQuestions = await db.collection('icebreaker_questions').get();
    const batch = db.batch();
    
    existingQuestions.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log('Cleared existing questions');
    
    // Add new questions
    const newBatch = db.batch();
    
    icebreakerQuestions.forEach((question, index) => {
      const docRef = db.collection('icebreaker_questions').doc();
      newBatch.set(docRef, {
        ...question,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        order: index + 1
      });
    });
    
    await newBatch.commit();
    console.log(`Successfully added ${icebreakerQuestions.length} icebreaker questions`);
    
    // Verify setup
    const snapshot = await db.collection('icebreaker_questions').get();
    console.log(`Verification: ${snapshot.size} questions in database`);
    
  } catch (error) {
    console.error('Error setting up icebreaker questions:', error);
  } finally {
    await admin.app().delete();
  }
}

// Export for use in Firebase Functions or local execution
module.exports = { setupIcebreakerQuestions, icebreakerQuestions };

// For direct execution with Node.js
if (require.main === module) {
  setupIcebreakerQuestions();
}

// Instructions for Firebase Console:
/*
1. Go to Firebase Console → Firestore Database
2. Click "Start collection" 
3. Collection ID: icebreaker_questions
4. Add documents with the following fields:
   - text (string): The question text
   - category (string): Question category
   - weight (number): Question weight (default: 1)
   - active (boolean): Whether question is active (default: true)
   - createdAt (timestamp): Auto-generated
   - order (number): Display order

Example document:
Document ID: auto-generated
Fields:
- text: "What's your favorite family tradition?"
- category: "family"
- weight: 1
- active: true
- createdAt: (timestamp)
- order: 1
*/
