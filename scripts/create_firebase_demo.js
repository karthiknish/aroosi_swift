const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'aroosi-project'
});

const db = admin.firestore();
const auth = admin.auth();

async function createDemoAccount() {
  console.log('🚀 Creating Firebase Demo Account for App Store Review...\n');

  try {
    // Demo user credentials
    const email = 'appreview@aroosi.app';
    const password = 'ReviewDemo2024!';
    const displayName = 'App Reviewer';

    // 1. Create Firebase Auth user
    console.log('📧 Creating Firebase Auth user...');
    const userRecord = await auth.createUser({
      email: email,
      password: password,
      displayName: displayName,
      emailVerified: true,
    });

    console.log(`✅ Firebase Auth user created: ${email}`);
    console.log(`   UID: ${userRecord.uid}`);

    // Set custom claims for premium access
    await auth.setCustomUserClaims(userRecord.uid, {
      isPremium: true,
      role: 'reviewer',
      subscriptionType: 'reviewer_premium'
    });

    console.log('✅ Premium access granted via custom claims');

    // 2. Create Firestore profile document
    console.log('📄 Creating Firestore profile...');
    const profileData = {
      uid: userRecord.uid,
      email: email,
      displayName: displayName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),

      // Basic Profile Information
      age: 28,
      gender: 'prefer_not_to_say',
      location: 'San Francisco, CA',
      coordinates: new admin.firestore.GeoPoint(37.7749, -122.4194),

      // Cultural Information (Aroosi-specific)
      culturalBackground: 'Afghan',
      heritage: 'Central Asian',
      familyOrigin: 'Kabul, Afghanistan',
      languages: ['English', 'Farsi', 'Pashto'],
      culturalValues: 'Traditional with modern outlook',
      religiousBeliefs: 'Moderate',
      familyValues: 'Traditional',
      seeking: 'Long-term relationship',

      // Family Approval Settings
      familyApproval: {
        parentApprovalRequired: true,
        familyInvolvement: 'High - family consulted',
        culturalCompatibilityImportance: 'Very Important',
        religiousAlignment: 'Moderate to conservative',
        traditionalValuesImportance: 'Very Important',
      },

      // Dating Preferences
      datingPreferences: {
        principles: 'Halal dating principles',
        marriageGoals: 'Seeking marriage within 2-3 years',
        familyApproval: 'Required for matches',
        culturalAlignment: 'Important factor',
      },

      // Profile Status
      profileStatus: 'complete',
      isVerified: true,
      isPremium: true,
      subscriptionType: 'reviewer_premium',

      // App Usage
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      loginCount: 1,
      appVersion: '1.0.3',

      // Privacy Settings
      privacy: {
        profileVisibility: 'public',
        showAge: true,
        showLocation: true,
        allowMessages: true,
        familyCanView: true,
      },

      // Cultural Compatibility Scores
      culturalScores: {
        familyValues: 95,
        religiousAlignment: 85,
        traditionalPractices: 90,
        languageCompatibility: 100,
        culturalKnowledge: 88,
        overallCompatibility: 92,
      },

      // Photo Gallery (placeholder URLs - you'll need to upload actual photos)
      photos: [
        {
          url: 'https://firebasestorage.googleapis.com/v0/b/aroosi-project.appspot.com/o/demo%2Fheadshot.jpg?alt=media',
          type: 'headshot',
          approved: true,
          uploadedAt: new Date(),
        },
        {
          url: 'https://firebasestorage.googleapis.com/v0/b/aroosi-project.appspot.com/o/demo%2Fcultural_attire.jpg?alt=media',
          type: 'cultural_attire',
          approved: true,
          uploadedAt: new Date(),
        },
        {
          url: 'https://firebasestorage.googleapis.com/v0/b/aroosi-project.appspot.com/o/demo%2Fcasual.jpg?alt=media',
          type: 'casual',
          approved: true,
          uploadedAt: new Date(),
        },
      ],

      // Preferences for Matching
      preferences: {
        ageRange: [25, 35],
        maxDistance: 50,
        culturalBackground: ['Afghan', 'Afghan-American'],
        religiousAlignment: ['Moderate', 'Conservative'],
        familyValues: ['Traditional', 'Moderate'],
        languages: ['English', 'Farsi', 'Pashto'],
      },
    };

    await db.collection('users').doc(userRecord.uid).set(profileData);
    console.log('✅ Firestore profile created successfully');

    // 3. Create sample matches for testing
    console.log('💕 Creating sample matches...');
    const sampleMatches = [
      {
        name: 'Sarah K.',
        age: 26,
        culturalBackground: 'Afghan',
        profession: 'Software Engineer',
        location: 'San Francisco, CA',
        compatibilityScore: 94,
        status: 'active',
        matchDate: admin.firestore.FieldValue.serverTimestamp(),
        photos: [
          'https://firebasestorage.googleapis.com/v0/b/aroosi-project.appspot.com/o/matches%2Fsarah.jpg?alt=media'
        ],
        interests: ['Technology', 'Afghan Culture', 'Reading', 'Hiking'],
        culturalInfo: {
          familyValues: 'Traditional',
          religiousBeliefs: 'Moderate',
          languages: ['English', 'Farsi'],
        }
      },
      {
        name: 'Ahmed M.',
        age: 30,
        culturalBackground: 'Afghan-American',
        profession: 'Medical Doctor',
        location: 'Stanford, CA',
        compatibilityScore: 91,
        status: 'family_approval_pending',
        matchDate: admin.firestore.FieldValue.serverTimestamp(),
        photos: [
          'https://firebasestorage.googleapis.com/v0/b/aroosi-project.appspot.com/o/matches%2 Fahmed.jpg?alt=media'
        ],
        interests: ['Medicine', 'Community Service', 'Afghan Poetry', 'Sports'],
        culturalInfo: {
          familyValues: 'Traditional',
          religiousBeliefs: 'Moderate',
          languages: ['English', 'Farsi', 'Pashto'],
        }
      },
      {
        name: 'Fatima R.',
        age: 27,
        culturalBackground: 'Afghan',
        profession: 'Teacher',
        location: 'Fremont, CA',
        compatibilityScore: 89,
        status: 'active',
        matchDate: admin.firestore.FieldValue.serverTimestamp(),
        photos: [
          'https://firebasestorage.googleapis.com/v0/b/aroosi-project.appspot.com/o/matches%2Ffatima.jpg?alt=media'
        ],
        interests: ['Education', 'Art', 'Afghan History', 'Cooking'],
        culturalInfo: {
          familyValues: 'Moderate',
          religiousBeliefs: 'Moderate',
          languages: ['English', 'Farsi', 'Pashto'],
        }
      },
    ];

    for (let i = 0; i < sampleMatches.length; i++) {
      await db.collection('users').doc(userRecord.uid).collection('matches').add(sampleMatches[i]);
    }
    console.log('✅ Sample matches created');

    // 4. Create sample conversations
    console.log('💬 Creating sample conversations...');
    const conversations = [
      {
        participantName: 'Sarah K.',
        participantId: 'demo_sarah',
        lastMessage: 'I love how our family values align so well!',
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
        unreadCount: 0,
        isActive: true,
        culturalCompatibility: 94,
        matchId: 'match_1',
      },
      {
        participantName: 'Ahmed M.',
        participantId: 'demo_ahmed',
        lastMessage: 'My family is excited about the possibility of us meeting',
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
        unreadCount: 2,
        isActive: true,
        culturalCompatibility: 91,
        matchId: 'match_2',
      },
    ];

    for (let i = 0; i < conversations.length; i++) {
      const conversationRef = await db.collection('users').doc(userRecord.uid).collection('conversations').add(conversations[i]);

      // Add sample messages to each conversation
      const sampleMessages = [
        {
          text: i === 0
            ? 'Hi! I saw your profile and really appreciate your cultural values.'
            : 'As-salamu alaykum! How are you today?',
          senderId: 'demo_match',
          senderName: i === 0 ? 'Sarah K.' : 'Ahmed M.',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: true,
          messageType: 'text',
        },
        {
          text: i === 0
            ? 'Thank you! I was really impressed by your profile too.'
            : 'Wa alaykumu s-salam! I\'m doing well, thank you for asking.',
          senderId: userRecord.uid,
          senderName: displayName,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: true,
          messageType: 'text',
        },
        {
          text: i === 0
            ? 'I love how our family values align so well!'
            : 'My family is excited about the possibility of us meeting',
          senderId: 'demo_match',
          senderName: i === 0 ? 'Sarah K.' : 'Ahmed M.',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          isRead: i === 0, // Sarah's message is read, Ahmed's is unread
          messageType: 'text',
        },
      ];

      for (const message of sampleMessages) {
        await conversationRef.collection('messages').add(message);
      }
    }
    console.log('✅ Sample conversations created');

    // 5. Create family approval settings
    console.log('👨‍👩‍👧‍👦 Setting up family approval system...');
    const familyData = {
      headOfFamily: 'Demo Family Head',
      approvalRequired: true,
      familyMembers: [
        {
          name: 'Demo Father',
          email: 'father@aroosi.app',
          role: 'parent',
          status: 'active',
          invitationSent: true,
          invitationDate: admin.firestore.FieldValue.serverTimestamp(),
        },
        {
          name: 'Demo Mother',
          email: 'mother@aroosi.app',
          role: 'parent',
          status: 'active',
          invitationSent: true,
          invitationDate: admin.firestore.FieldValue.serverTimestamp(),
        },
      ],
      approvalSettings: {
        requiresParentApproval: true,
        culturalAlignmentRequired: true,
        familyConsentNeeded: true,
        traditionalValuesCheck: true,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('users').doc(userRecord.uid).collection('family').doc('settings').set(familyData);
    console.log('✅ Family approval system configured');

    // 6. Add user activity logs for testing
    console.log('📊 Adding activity logs...');
    const activities = [
      {
        type: 'profile_completed',
        description: 'Profile setup completed with cultural information',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          completionPercentage: 100,
          sectionsCompleted: ['basic', 'cultural', 'family', 'preferences'],
        }
      },
      {
        type: 'matches_viewed',
        description: 'Viewed recommended matches',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          matchesViewed: 3,
          averageCompatibility: 91.3,
        }
      },
      {
        type: 'message_sent',
        description: 'Sent message to Sarah K.',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          recipientName: 'Sarah K.',
          messageType: 'text',
        }
      },
      {
        type: 'family_invited',
        description: 'Invited family members for approval process',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          familyMembersInvited: 2,
          roles: ['father', 'mother'],
        }
      },
    ];

    for (const activity of activities) {
      await db.collection('users').doc(userRecord.uid).collection('activities').add(activity);
    }
    console.log('✅ Activity logs created');

    // 7. Create cultural assessment results
    console.log('🎯 Creating cultural assessment results...');
    const culturalAssessment = {
      assessmentDate: admin.firestore.FieldValue.serverTimestamp(),
      overallScore: 92,
      categories: {
        familyValues: {
          score: 95,
          description: 'Strong commitment to traditional family values',
          importance: 'High',
        },
        religiousAlignment: {
          score: 85,
          description: 'Moderate religious practices with cultural respect',
          importance: 'High',
        },
        traditionalPractices: {
          score: 90,
          description: 'Good understanding of Afghan traditions',
          importance: 'High',
        },
        languageCompatibility: {
          score: 100,
          description: 'Fluent in multiple Afghan languages',
          importance: 'High',
        },
        culturalKnowledge: {
          score: 88,
          description: 'Well-versed in Afghan culture and history',
          importance: 'Medium',
        },
      },
      recommendations: [
        'Excellent match for users seeking traditional Afghan values',
        'Strong candidate for family-centered relationships',
        'Culturally compatible with diverse Afghan backgrounds',
      ],
      compatibilityFactors: [
        'Family approval orientation',
        'Traditional dating preferences',
        'Multi-language capabilities',
        'Cultural knowledge depth',
      ],
    };

    await db.collection('users').doc(userRecord.uid).collection('assessments').doc('cultural').set(culturalAssessment);
    console.log('✅ Cultural assessment created');

    console.log('\n🎉 Demo account creation completed successfully!');
    console.log('📋 Account Summary:');
    console.log(`   Email: ${email}`);
    console.log(`   Password: ${password}`);
    console.log(`   UID: ${userRecord.uid}`);
    console.log('   Profile: Complete with cultural data');
    console.log('   Matches: 3 sample matches');
    console.log('   Conversations: 2 active conversations');
    console.log('   Family: Approval system configured');
    console.log('   Status: Premium account (review access)');
    console.log('   Cultural Assessment: Complete (92% score)');
    console.log('\n✅ Ready for App Store Review!');

  } catch (error) {
    console.error('❌ Error creating demo account:', error);
    if (error.code) {
      console.error('Error Code:', error.code);
    }
    process.exit(1);
  }
}

// Run the script
createDemoAccount().then(() => {
  console.log('\n🚀 Script completed successfully!');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});