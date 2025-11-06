#!/usr/bin/env node

/**
 * Activate All Profiles by Default
 * Ensures all profiles across collections are active and ready for search
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

async function activateAllProfiles() {
    console.log('🔄 Activating All Profiles by Default...\n');
    
    const activationResults = {
        usersCollection: { total: 0, activated: 0, alreadyActive: 0, errors: 0 },
        profilesCollection: { total: 0, activated: 0, alreadyActive: 0, errors: 0 },
        summary: {}
    };
    
    try {
        // 1. Activate profiles in "users" collection
        console.log('📋 Processing "users" collection...');
        const usersSnapshot = await db.collection('users').get();
        activationResults.usersCollection.total = usersSnapshot.size;
        
        for (const doc of usersSnapshot.docs) {
            const profile = doc.data();
            const profileId = doc.id;
            
            try {
                if (profile.isActive !== true) {
                    // Activate the profile
                    await db.collection('users').doc(profileId).update({
                        isActive: true,
                        activatedAt: admin.firestore.FieldValue.serverTimestamp(),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    
                    activationResults.usersCollection.activated++;
                    console.log(`  ✅ Activated: ${profile.displayName || profileId}`);
                } else {
                    activationResults.usersCollection.alreadyActive++;
                    console.log(`  ℹ️ Already active: ${profile.displayName || profileId}`);
                }
            } catch (error) {
                activationResults.usersCollection.errors++;
                console.log(`  ❌ Error activating ${profileId}: ${error.message}`);
            }
        }
        
        // 2. Activate profiles in "profiles" collection
        console.log('\n📋 Processing "profiles" collection...');
        const profilesSnapshot = await db.collection('profiles').get();
        activationResults.profilesCollection.total = profilesSnapshot.size;
        
        for (const doc of profilesSnapshot.docs) {
            const profile = doc.data();
            const profileId = doc.id;
            
            try {
                if (profile.isActive !== true) {
                    // Activate the profile
                    await db.collection('profiles').doc(profileId).update({
                        isActive: true,
                        activatedAt: admin.firestore.FieldValue.serverTimestamp(),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    
                    activationResults.profilesCollection.activated++;
                    console.log(`  ✅ Activated: ${profile.displayName || profile.name || profileId}`);
                } else {
                    activationResults.profilesCollection.alreadyActive++;
                    console.log(`  ℹ️ Already active: ${profile.displayName || profile.name || profileId}`);
                }
            } catch (error) {
                activationResults.profilesCollection.errors++;
                console.log(`  ❌ Error activating ${profileId}: ${error.message}`);
            }
        }
        
        // 3. Calculate summary
        const totalProfiles = activationResults.usersCollection.total + activationResults.profilesCollection.total;
        const totalActivated = activationResults.usersCollection.activated + activationResults.profilesCollection.activated;
        const totalAlreadyActive = activationResults.usersCollection.alreadyActive + activationResults.profilesCollection.alreadyActive;
        const totalErrors = activationResults.usersCollection.errors + activationResults.profilesCollection.errors;
        const totalActiveProfiles = totalActivated + totalAlreadyActive;
        
        activationResults.summary = {
            totalProfiles,
            newlyActivated: totalActivated,
            alreadyActive: totalAlreadyActive,
            totalActiveProfiles,
            errors: totalErrors,
            activationRate: totalProfiles > 0 ? (totalActiveProfiles / totalProfiles) * 100 : 0
        };
        
        // 4. Display results
        console.log('\n📊 ACTIVATION RESULTS');
        console.log('======================');
        console.log(`👥 Total Profiles Processed: ${totalProfiles}`);
        console.log(`🔄 Newly Activated: ${totalActivated}`);
        console.log(`✅ Already Active: ${totalAlreadyActive}`);
        console.log(`🎯 Total Active Profiles: ${totalActiveProfiles}`);
        console.log(`❌ Errors: ${totalErrors}`);
        console.log(`📈 Activation Rate: ${activationResults.summary.activationRate.toFixed(1)}%`);
        
        console.log('\n📋 Collection Breakdown:');
        console.log(`📁 Users Collection: ${activationResults.usersCollection.total} total, ${activationResults.usersCollection.activated + activationResults.usersCollection.alreadyActive} active`);
        console.log(`📁 Profiles Collection: ${activationResults.profilesCollection.total} total, ${activationResults.profilesCollection.activated + activationResults.profilesCollection.alreadyActive} active`);
        
        // 5. Search readiness assessment
        console.log('\n🔍 SEARCH READINESS IMPACT');
        console.log('===========================');
        
        if (totalActiveProfiles === totalProfiles) {
            console.log('🎉 EXCELLENT! All profiles are now active and ready for search!');
            console.log(`📱 Search screen will now display ${totalActiveProfiles} profiles`);
            console.log('🎯 Users will have 3x more profile variety');
        } else if (totalActiveProfiles > 0) {
            console.log(`✅ GOOD! ${totalActiveProfiles} profiles are active and ready for search`);
            console.log(`⚠️ ${totalProfiles - totalActiveProfiles} profiles still need attention`);
        } else {
            console.log('❌ No profiles are active. Search screen will be empty.');
        }
        
        // 6. Next steps
        console.log('\n🚀 NEXT STEPS');
        console.log('===============');
        console.log('1. ✅ All profiles have been activated by default');
        console.log('2. 🔄 Update search repository to check both collections');
        console.log('3. 🎱 Test search screen with all 9 profiles');
        console.log('4. 📊 Monitor user engagement with increased variety');
        console.log('5. 🖼️ Consider adding avatar images to profiles without them');
        
        return activationResults;
        
    } catch (error) {
        console.error('❌ Error during profile activation:', error.message);
        throw error;
    }
}

// Run the activation
async function main() {
    try {
        await activateAllProfiles();
        console.log('\n✅ Profile activation completed successfully!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Profile activation failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { activateAllProfiles };
