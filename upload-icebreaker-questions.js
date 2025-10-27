const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
let app;
try {
  // Try to load from environment variables first (like createDemoAccount.ts)
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  const b64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;

  let serviceAccount;
  if (raw) {
    serviceAccount = JSON.parse(raw);
  } else if (b64) {
    serviceAccount = JSON.parse(Buffer.from(b64, 'base64').toString());
  } else {
    // Fallback to file-based auth
    serviceAccount = require('./firebase-service-account.json');
  }

  app = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}.firebaseio.com`
  });
} catch (error) {
  console.error('Failed to initialize Firebase Admin SDK:', error.message);
  console.error('Make sure you have either:');
  console.error('1. FIREBASE_SERVICE_ACCOUNT environment variable set');
  console.error('2. FIREBASE_SERVICE_ACCOUNT_BASE64 environment variable set');
  console.error('3. firebase-service-account.json file in the project root');
  process.exit(1);
}

const db = admin.firestore();

const icebreakerQuestions = [
  {
    id: '1',
    text: 'What\'s your favorite way to spend a weekend?',
    active: true,
    category: 'lifestyle',
    weight: 1
  },
  {
    id: '2',
    text: 'If you could travel anywhere right now, where would you go and why?',
    active: true,
    category: 'travel',
    weight: 1
  },
  {
    id: '3',
    text: 'What\'s a skill you\'ve always wanted to learn?',
    active: true,
    category: 'personal',
    weight: 1
  },
  {
    id: '4',
    text: 'What\'s your go-to comfort food?',
    active: true,
    category: 'food',
    weight: 1
  },
  {
    id: '5',
    text: 'What\'s the most interesting place you\'ve ever visited?',
    active: true,
    category: 'travel',
    weight: 1
  },
  {
    id: '6',
    text: 'If you could have dinner with any historical figure, who would it be?',
    active: true,
    category: 'personal',
    weight: 1
  },
  {
    id: '7',
    text: 'What\'s your favorite book or movie and why?',
    active: true,
    category: 'entertainment',
    weight: 1
  },
  {
    id: '8',
    text: 'What\'s something that always makes you laugh?',
    active: true,
    category: 'personal',
    weight: 1
  },
  {
    id: '9',
    text: 'What\'s your favorite season and what do you love about it?',
    active: true,
    category: 'lifestyle',
    weight: 1
  },
  {
    id: '10',
    text: 'If you could instantly master any instrument, what would it be?',
    active: true,
    category: 'personal',
    weight: 1
  },
  {
    id: '11',
    text: 'What\'s the best piece of advice you\'ve ever received?',
    active: true,
    category: 'personal',
    weight: 1
  },
  {
    id: '12',
    text: 'What\'s your favorite way to relax after a long day?',
    active: true,
    category: 'lifestyle',
    weight: 1
  },
  {
    id: '13',
    text: 'If you could live in any fictional universe, which one would it be?',
    active: true,
    category: 'entertainment',
    weight: 1
  },
  {
    id: '14',
    text: 'What\'s a hobby you\'d love to pick up?',
    active: true,
    category: 'personal',
    weight: 1
  },
  {
    id: '15',
    text: 'What\'s your favorite type of music and why?',
    active: true,
    category: 'entertainment',
    weight: 1
  },
  {
    id: '16',
    text: 'If you could time travel to any era, when and where would you go?',
    active: true,
    category: 'personal',
    weight: 1
  },
  {
    id: '17',
    text: 'What\'s your dream job?',
    active: true,
    category: 'career',
    weight: 1
  },
  {
    id: '18',
    text: 'What\'s the most spontaneous thing you\'ve ever done?',
    active: true,
    category: 'personal',
    weight: 1
  },
  {
    id: '19',
    text: 'What\'s your favorite local spot in your city?',
    active: true,
    category: 'local',
    weight: 1
  },
  {
    id: '20',
    text: 'If you could have any superpower, what would it be?',
    active: true,
    category: 'fun',
    weight: 1
  }
];

async function uploadIcebreakerQuestions() {
  try {
    console.log('Starting icebreaker questions upload...');

    const batch = db.batch();
    const questionsRef = db.collection('icebreaker_questions');

    icebreakerQuestions.forEach(question => {
      const docRef = questionsRef.doc(question.id);
      batch.set(docRef, {
        ...question,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await batch.commit();
    console.log(`Successfully uploaded ${icebreakerQuestions.length} icebreaker questions to Firebase!`);

  } catch (error) {
    console.error('Error uploading icebreaker questions:', error);
  } finally {
    admin.app().delete();
  }
}

uploadIcebreakerQuestions();