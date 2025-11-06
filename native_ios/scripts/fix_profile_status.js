#!/usr/bin/env node

/**
 * Fix Profile Status for Search Testing
 * Activates profiles and ensures they're ready for search rendering
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

async function fixProfileStatus() {
    console.log('🔧 Fixing Profile Status for Search Testing...\n');
    
    try {
        // Get all profiles
        const profilesSnapshot = await db.collection('users').get();
        
        console.log(`📋 Found ${profilesSnapshot.size} profiles`);
        
        for (const doc of profilesSnapshot.docs) {
            const profile = doc.data();
            const profileId = doc.id;
            
            console.log(`\n👤 Processing: ${profile.displayName || profileId}`);
            
            // Check current status
            const isActive = profile.isActive === true;
            const hasDisplayName = !!profile.displayName;
            const hasEmail = !!profile.email;
            
            console.log(`  Current Status: ${isActive ? '✅ Active' : '❌ Inactive'}`);
            console.log(`  Display Name: ${hasDisplayName ? '✅' : '❌'} ${profile.displayName || 'Missing'}`);
            console.log(`  Email: ${hasEmail ? '✅' : '❌'} ${profile.email || 'Missing'}`);
            
            // Prepare updates
            const updates = {};
            
            // Activate profile if it has basic info
            if (hasDisplayName && hasEmail && !isActive) {
                updates.isActive = true;
                console.log(`  🔄 Activating profile...`);
            }
            
            // Add missing fields for better search experience
            if (!profile.age) {
                updates.age = Math.floor(Math.random() * 15) + 25; // Random age 25-40
                console.log(`  ➕ Adding age: ${updates.age}`);
            }
            
            if (!profile.location) {
                const locations = ['Kabul, Afghanistan', 'Herat, Afghanistan', 'Mazar-i-Sharif, Afghanistan', 'Jalalabad, Afghanistan'];
                updates.location = locations[Math.floor(Math.random() * locations.length)];
                console.log(`  ➕ Adding location: ${updates.location}`);
            }
            
            if (!profile.bio) {
                updates.bio = 'Looking for a compatible partner for marriage. Family-oriented and values traditional Islamic principles.';
                console.log(`  ➕ Adding bio`);
            }
            
            if (!profile.avatarURL) {
                // Use a placeholder avatar URL
                updates.avatarURL = `https://ui-avatars.com/api/?name=${encodeURIComponent(profile.displayName || 'User')}&background=4F46E5&color=fff&size=200`;
                console.log(`  ➕ Adding placeholder avatar`);
            }
            
            if (!Array.isArray(profile.photos) || profile.photos.length === 0) {
                updates.photos = [updates.avatarURL];
                console.log(`  ➕ Adding photos array`);
            }
            
            // Update profile if needed
            if (Object.keys(updates).length > 0) {
                updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
                
                await db.collection('users').doc(profileId).update(updates);
                console.log(`  ✅ Profile updated with ${Object.keys(updates).length} changes`);
            } else {
                console.log(`  ℹ️ Profile already complete`);
            }
        }
        
        console.log(`\n🎉 Profile status fix completed!`);
        
        // Run verification
        await verifyProfiles();
        
    } catch (error) {
        console.error('❌ Error fixing profiles:', error.message);
        throw error;
    }
}

async function verifyProfiles() {
    console.log(`\n🔍 Verifying Profile Status...`);
    
    const profilesSnapshot = await db.collection('users').get();
    
    let activeCount = 0;
    let completeCount = 0;
    
    for (const doc of profilesSnapshot.docs) {
        const profile = doc.data();
        
        const isActive = profile.isActive === true;
        const hasRequired = !!profile.displayName && !!profile.email;
        const hasEnhanced = !!profile.age && !!profile.location && !!profile.bio && !!profile.avatarURL;
        
        if (isActive && hasRequired) {
            activeCount++;
        }
        
        if (isActive && hasRequired && hasEnhanced) {
            completeCount++;
        }
        
        const status = isActive && hasRequired && hasEnhanced ? '✅' : 
                      isActive && hasRequired ? '🔄' : '❌';
        console.log(`  ${status} ${profile.displayName || doc.id}`);
    }
    
    console.log(`\n📊 Verification Results:`);
    console.log(`  👥 Total Profiles: ${profilesSnapshot.size}`);
    console.log(`  ✅ Active Profiles: ${activeCount}`);
    console.log(`  🏆 Complete Profiles: ${completeCount}`);
    console.log(`  📱 Ready for Search: ${completeCount}/${profilesSnapshot.size} (${((completeCount/profilesSnapshot.size)*100).toFixed(1)}%)`);
    
    if (completeCount === profilesSnapshot.size) {
        console.log(`\n🎉 All profiles are ready for search rendering!`);
    } else {
        console.log(`\n⚠️ Some profiles may need additional data for optimal search experience`);
    }
}

// Run the fix
async function main() {
    try {
        await fixProfileStatus();
        console.log('\n✅ Profile status fix completed successfully!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Profile fix failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { fixProfileStatus, verifyProfiles };
