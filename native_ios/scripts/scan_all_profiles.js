#!/usr/bin/env node

/**
 * Scan All Firebase Profiles
 * Comprehensive scan of all profiles in the database
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

async function scanAllProfiles() {
    console.log('🔍 Scanning All Firebase Profiles...\n');
    
    try {
        // Get ALL profiles without any filters
        const allProfilesSnapshot = await db.collection('users').get();
        
        console.log(`📊 Total Profiles Found: ${allProfilesSnapshot.size}\n`);
        
        const profileAnalysis = {
            total: allProfilesSnapshot.size,
            active: 0,
            inactive: 0,
            incomplete: 0,
            complete: 0,
            withImages: 0,
            withInterests: 0,
            profiles: []
        };
        
        for (const doc of allProfilesSnapshot.docs) {
            const profile = doc.data();
            const profileId = doc.id;
            
            // Analyze each profile
            const analysis = {
                id: profileId,
                displayName: profile.displayName || 'No Name',
                email: profile.email || 'No Email',
                isActive: profile.isActive === true,
                hasDisplayName: !!profile.displayName,
                hasEmail: !!profile.email,
                hasAge: typeof profile.age === 'number' && profile.age > 0,
                hasLocation: typeof profile.location === 'string' && profile.location.length > 0,
                hasBio: typeof profile.bio === 'string' && profile.bio.length > 0,
                hasAvatar: !!profile.avatarURL,
                hasPhotos: Array.isArray(profile.photos) && profile.photos.length > 0,
                hasInterests: Array.isArray(profile.interests) && profile.interests.length > 0,
                createdAt: profile.createdAt?.toDate?.() || null,
                lastActiveAt: profile.lastActiveAt?.toDate?.() || null,
                updatedAt: profile.updatedAt?.toDate?.() || null
            };
            
            // Calculate completeness
            const requiredFields = [analysis.hasDisplayName, analysis.hasEmail];
            const enhancedFields = [analysis.hasAge, analysis.hasLocation, analysis.hasBio, analysis.hasAvatar, analysis.hasInterests];
            
            analysis.isComplete = requiredFields.every(Boolean) && enhancedFields.filter(Boolean).length >= 3;
            analysis.isSearchable = analysis.isActive && analysis.hasDisplayName;
            
            // Update counters
            if (analysis.isActive) profileAnalysis.active++;
            else profileAnalysis.inactive++;
            
            if (analysis.isComplete) profileAnalysis.complete++;
            else profileAnalysis.incomplete++;
            
            if (analysis.hasAvatar || analysis.hasPhotos) profileAnalysis.withImages++;
            if (analysis.hasInterests) profileAnalysis.withInterests++;
            
            profileAnalysis.profiles.push(analysis);
            
            // Display profile info
            const status = analysis.isActive ? '✅' : '❌';
            const completeness = analysis.isComplete ? '🏆' : '🔄';
            const searchability = analysis.isSearchable ? '🔍' : '🚫';
            
            console.log(`${status} ${completeness} ${searchability} ${analysis.displayName}`);
            console.log(`   📧 ${analysis.email}`);
            console.log(`   🆔 ${profileId}`);
            
            if (analysis.hasAge) console.log(`   🎂 Age: ${profile.age}`);
            if (analysis.hasLocation) console.log(`   📍 Location: ${profile.location}`);
            if (analysis.hasBio) console.log(`   📝 Bio: ${profile.bio.substring(0, 50)}...`);
            if (analysis.hasAvatar) console.log(`   🖼️ Avatar: ✅`);
            if (analysis.hasInterests) console.log(`   🏷️ Interests: ${profile.interests.join(', ')}`);
            if (analysis.createdAt) console.log(`   📅 Created: ${analysis.createdAt.toLocaleDateString()}`);
            
            console.log('');
        }
        
        // Print summary
        console.log('📊 COMPREHENSIVE PROFILE ANALYSIS');
        console.log('==================================');
        console.log(`👥 Total Profiles: ${profileAnalysis.total}`);
        console.log(`✅ Active Profiles: ${profileAnalysis.active} (${((profileAnalysis.active/profileAnalysis.total)*100).toFixed(1)}%)`);
        console.log(`❌ Inactive Profiles: ${profileAnalysis.inactive} (${((profileAnalysis.inactive/profileAnalysis.total)*100).toFixed(1)}%)`);
        console.log(`🏆 Complete Profiles: ${profileAnalysis.complete} (${((profileAnalysis.complete/profileAnalysis.total)*100).toFixed(1)}%)`);
        console.log(`🔄 Incomplete Profiles: ${profileAnalysis.incomplete} (${((profileAnalysis.incomplete/profileAnalysis.total)*100).toFixed(1)}%)`);
        console.log(`🖼️ With Images: ${profileAnalysis.withImages} (${((profileAnalysis.withImages/profileAnalysis.total)*100).toFixed(1)}%)`);
        console.log(`🏷️ With Interests: ${profileAnalysis.withInterests} (${((profileAnalysis.withInterests/profileAnalysis.total)*100).toFixed(1)}%)`);
        
        // Search readiness
        const searchableProfiles = profileAnalysis.profiles.filter(p => p.isSearchable).length;
        console.log(`🔍 Searchable Profiles: ${searchableProfiles} (${((searchableProfiles/profileAnalysis.total)*100).toFixed(1)}%)`);
        
        console.log('\n💡 RECOMMENDATIONS');
        console.log('==================');
        
        if (profileAnalysis.inactive > 0) {
            console.log(`🔄 Activate ${profileAnalysis.inactive} inactive profiles for better search results`);
        }
        
        if (profileAnalysis.incomplete > 0) {
            console.log(`📝 Complete ${profileAnalysis.incomplete} profiles with more information`);
        }
        
        if (profileAnalysis.withImages < profileAnalysis.total) {
            console.log(`📸 Add images to ${profileAnalysis.total - profileAnalysis.withImages} profiles`);
        }
        
        if (searchableProfiles === profileAnalysis.total) {
            console.log('🎉 Excellent! All profiles are ready for search rendering');
        }
        
        return profileAnalysis;
        
    } catch (error) {
        console.error('❌ Error scanning profiles:', error.message);
        throw error;
    }
}

// Run the scan
async function main() {
    try {
        await scanAllProfiles();
        console.log('\n✅ Profile scan completed successfully!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Profile scan failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { scanAllProfiles };
