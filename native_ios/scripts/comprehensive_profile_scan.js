#!/usr/bin/env node

/**
 * Comprehensive Profile Scan
 * Checks all possible profile locations and structures
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
try {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: 'aroosi-ios'
    });
} catch (error) {
    console.log('🔧 Using existing Firebase initialization');
    if (!admin.apps.length) {
        admin.initializeApp({
            projectId: 'aroosi-ios',
            databaseURL: 'http://localhost:8080'
        });
    }
}

const db = admin.firestore();

async function comprehensiveProfileScan() {
    console.log('🔍 COMPREHENSIVE FIREBASE PROFILE SCAN\n');
    
    const results = {
        usersCollection: { count: 0, profiles: [] },
        profilesCollection: { count: 0, profiles: [] },
        otherCollections: {},
        totalProfiles: 0
    };
    
    try {
        // 1. Check 'users' collection
        console.log('📋 Checking "users" collection...');
        const usersSnapshot = await db.collection('users').get();
        results.usersCollection.count = usersSnapshot.size;
        
        for (const doc of usersSnapshot.docs) {
            const profile = doc.data();
            results.usersCollection.profiles.push({
                id: doc.id,
                displayName: profile.displayName || 'No Name',
                email: profile.email || 'No Email',
                isActive: profile.isActive || false,
                hasAvatar: !!profile.avatarURL,
                hasInterests: Array.isArray(profile.interests) && profile.interests.length > 0
            });
        }
        
        console.log(`   Found ${usersSnapshot.size} profiles in "users" collection`);
        
        // 2. Check 'profiles' collection (if it exists)
        console.log('\n📋 Checking "profiles" collection...');
        try {
            const profilesSnapshot = await db.collection('profiles').get();
            results.profilesCollection.count = profilesSnapshot.size;
            
            for (const doc of profilesSnapshot.docs) {
                const profile = doc.data();
                results.profilesCollection.profiles.push({
                    id: doc.id,
                    displayName: profile.displayName || 'No Name',
                    email: profile.email || 'No Email',
                    isActive: profile.isActive !== false, // Default to active
                    hasAvatar: !!profile.avatarURL,
                    hasInterests: Array.isArray(profile.interests) && profile.interests.length > 0
                });
            }
            
            console.log(`   Found ${profilesSnapshot.size} profiles in "profiles" collection`);
        } catch (error) {
            console.log('   No "profiles" collection found or access denied');
        }
        
        // 3. Check for other potential profile collections
        console.log('\n📋 Checking other potential collections...');
        const collections = await db.listCollections();
        const profileRelatedCollections = ['userProfiles', 'members', 'accounts', 'customers'];
        
        for (const collection of collections) {
            const collectionName = collection.id;
            
            if (profileRelatedCollections.includes(collectionName)) {
                try {
                    const snapshot = await db.collection(collectionName).limit(5).get();
                    results.otherCollections[collectionName] = {
                        count: snapshot.size,
                        sampleProfiles: []
                    };
                    
                    for (const doc of snapshot.docs) {
                        const data = doc.data();
                        if (data.displayName || data.name || data.email) {
                            results.otherCollections[collectionName].sampleProfiles.push({
                                id: doc.id,
                                displayName: data.displayName || data.name || 'No Name',
                                email: data.email || 'No Email'
                            });
                        }
                    }
                    
                    console.log(`   Found ${snapshot.size} documents in "${collectionName}" collection`);
                } catch (error) {
                    console.log(`   Could not access "${collectionName}" collection`);
                }
            }
        }
        
        // 4. Calculate totals
        results.totalProfiles = results.usersCollection.count + results.profilesCollection.count;
        
        // Add other collection counts
        Object.values(results.otherCollections).forEach(collection => {
            results.totalProfiles += collection.count;
        });
        
        // 5. Display comprehensive results
        console.log('\n📊 COMPREHENSIVE SCAN RESULTS');
        console.log('=============================');
        console.log(`👥 Total Profiles Across All Collections: ${results.totalProfiles}`);
        console.log(`📋 "users" Collection: ${results.usersCollection.count} profiles`);
        console.log(`📋 "profiles" Collection: ${results.profilesCollection.count} profiles`);
        
        Object.entries(results.otherCollections).forEach(([name, data]) => {
            console.log(`📋 "${name}" Collection: ${data.count} profiles`);
        });
        
        // 6. Detailed profile listing
        console.log('\n👤 DETAILED PROFILE LISTING');
        console.log('===========================');
        
        if (results.usersCollection.profiles.length > 0) {
            console.log('\n📋 Users Collection:');
            results.usersCollection.profiles.forEach((profile, index) => {
                const status = profile.isActive ? '✅' : '❌';
                const avatar = profile.hasAvatar ? '🖼️' : '📝';
                const interests = profile.hasInterests ? '🏷️' : '📋';
                console.log(`   ${index + 1}. ${status} ${avatar} ${interests} ${profile.displayName} (${profile.email})`);
            });
        }
        
        if (results.profilesCollection.profiles.length > 0) {
            console.log('\n📋 Profiles Collection:');
            results.profilesCollection.profiles.forEach((profile, index) => {
                const status = profile.isActive ? '✅' : '❌';
                const avatar = profile.hasAvatar ? '🖼️' : '📝';
                const interests = profile.hasInterests ? '🏷️' : '📋';
                console.log(`   ${index + 1}. ${status} ${avatar} ${interests} ${profile.displayName} (${profile.email})`);
            });
        }
        
        Object.entries(results.otherCollections).forEach(([collectionName, data]) => {
            if (data.sampleProfiles.length > 0) {
                console.log(`\n📋 ${collectionName} Collection (Sample):`);
                data.sampleProfiles.forEach((profile, index) => {
                    console.log(`   ${index + 1}. ${profile.displayName} (${profile.email})`);
                });
            }
        });
        
        // 7. Search readiness assessment
        console.log('\n🔍 SEARCH READINESS ASSESSMENT');
        console.log('===============================');
        
        const activeUsers = results.usersCollection.profiles.filter(p => p.isActive).length;
        const usersWithImages = results.usersCollection.profiles.filter(p => p.hasAvatar).length;
        const usersWithInterests = results.usersCollection.profiles.filter(p => p.hasInterests).length;
        
        console.log(`📱 Search Screen Ready Profiles: ${activeUsers}/${results.usersCollection.count}`);
        console.log(`🖼️ Profiles with Images: ${usersWithImages}/${results.usersCollection.count}`);
        console.log(`🏷️ Profiles with Interests: ${usersWithInterests}/${results.usersCollection.count}`);
        
        if (activeUsers === results.usersCollection.count && usersWithImages === results.usersCollection.count) {
            console.log('\n🎉 EXCELLENT! All profiles are ready for search rendering!');
        } else {
            console.log('\n⚠️ Some profiles may need additional data for optimal search experience');
        }
        
        return results;
        
    } catch (error) {
        console.error('❌ Error during comprehensive scan:', error.message);
        throw error;
    }
}

// Run the comprehensive scan
async function main() {
    try {
        await comprehensiveProfileScan();
        console.log('\n✅ Comprehensive profile scan completed successfully!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Comprehensive scan failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { comprehensiveProfileScan };
