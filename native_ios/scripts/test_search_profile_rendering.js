#!/usr/bin/env node

/**
 * Test Search Profile Rendering
 * Verifies Firebase profiles render properly on search screen
 */

const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
try {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: 'aroosi-ios'
    });
} catch (error) {
    console.log('🔧 Using existing Firebase initialization or emulator');
    // Try emulator if service account fails
    if (!admin.apps.length) {
        admin.initializeApp({
            projectId: 'aroosi-ios',
            databaseURL: 'http://localhost:8080'
        });
    }
}

const db = admin.firestore();

class SearchProfileRenderingTester {
    constructor() {
        this.testResults = {
            timestamp: new Date().toISOString(),
            profileData: [],
            renderingTests: [],
            imageTests: [],
            filterTests: [],
            summary: {}
        };
    }

    async runAllTests() {
        console.log('🔍 Testing Search Profile Rendering...\n');
        
        try {
            await this.testProfileDataStructure();
            await this.testProfileImageAvailability();
            await this.testSearchFilterCompatibility();
            await this.testProfileCompleteness();
            await this.generateRenderingReport();
            
            console.log('✅ All search rendering tests completed successfully!');
            return this.testResults;
            
        } catch (error) {
            console.error('❌ Test failed:', error.message);
            throw error;
        }
    }

    async testProfileDataStructure() {
        console.log('📊 Testing Profile Data Structure...');
        
        const profilesSnapshot = await db
            .collection('users')
            .where('isActive', '==', true)
            .limit(10)
            .get();
        
        if (profilesSnapshot.empty) {
            console.log('⚠️ No active profiles found');
            return;
        }
        
        for (const doc of profilesSnapshot.docs) {
            const profile = doc.data();
            const profileId = doc.id;
            
            // Test required fields for search rendering
            const requiredFields = ['displayName', 'isActive'];
            const optionalFields = ['age', 'location', 'bio', 'avatarURL', 'photos', 'interests'];
            
            const structureTest = {
                profileId,
                displayName: profile.displayName || 'MISSING',
                hasRequiredFields: requiredFields.every(field => profile[field] !== undefined),
                missingRequired: requiredFields.filter(field => profile[field] === undefined),
                optionalFieldsPresent: optionalFields.filter(field => profile[field] !== undefined),
                optionalFieldsMissing: optionalFields.filter(field => profile[field] === undefined),
                isSearchable: profile.isActive === true && profile.displayName !== undefined
            };
            
            this.testResults.profileData.push(structureTest);
            
            if (structureTest.isSearchable) {
                console.log(`  ✅ ${profile.displayName} - Searchable profile`);
            } else {
                console.log(`  ❌ ${profile.displayName || profileId} - Not searchable`);
            }
        }
        
        console.log(`📈 Found ${profilesSnapshot.size} profiles, ${this.testResults.profileData.filter(p => p.isSearchable).length} are searchable\n`);
    }

    async testProfileImageAvailability() {
        console.log('🖼️ Testing Profile Image Availability...');
        
        const profilesSnapshot = await db
            .collection('users')
            .where('isActive', '==', true)
            .where('avatarURL', '!=', null)
            .limit(5)
            .get();
        
        for (const doc of profilesSnapshot.docs) {
            const profile = doc.data();
            const profileId = doc.id;
            
            const imageTest = {
                profileId,
                displayName: profile.displayName,
                hasAvatarURL: !!profile.avatarURL,
                avatarURL: profile.avatarURL || null,
                hasPhotos: Array.isArray(profile.photos) && profile.photos.length > 0,
                photoCount: Array.isArray(profile.photos) ? profile.photos.length : 0,
                imageRenderingReady: !!(profile.avatarURL || (profile.photos && profile.photos.length > 0))
            };
            
            this.testResults.imageTests.push(imageTest);
            
            if (imageTest.imageRenderingReady) {
                console.log(`  ✅ ${profile.displayName} - Images ready for rendering`);
            } else {
                console.log(`  ⚠️ ${profile.displayName} - No images available`);
            }
        }
        
        console.log(`📊 Image availability: ${this.testResults.imageTests.filter(t => t.imageRenderingReady).length}/${profilesSnapshot.size} profiles have images\n`);
    }

    async testSearchFilterCompatibility() {
        console.log('🔍 Testing Search Filter Compatibility...');
        
        const profilesSnapshot = await db
            .collection('users')
            .where('isActive', '==', true)
            .limit(10)
            .get();
        
        const filterTests = [];
        
        for (const doc of profilesSnapshot.docs) {
            const profile = doc.data();
            const profileId = doc.id;
            
            const filterTest = {
                profileId,
                displayName: profile.displayName,
                ageFilterable: typeof profile.age === 'number' && profile.age > 0,
                locationFilterable: typeof profile.location === 'string' && profile.location.length > 0,
                interestsFilterable: Array.isArray(profile.interests) && profile.interests.length > 0,
                bioSearchable: typeof profile.bio === 'string' && profile.bio.length > 0,
                overallFilterable: false
            };
            
            filterTest.overallFilterable = filterTest.ageFilterable || 
                                         filterTest.locationFilterable || 
                                         filterTest.interestsFilterable || 
                                         filterTest.bioSearchable;
            
            filterTests.push(filterTest);
            
            if (filterTest.overallFilterable) {
                console.log(`  ✅ ${profile.displayName} - Filter compatible`);
            } else {
                console.log(`  ⚠️ ${profile.displayName} - Limited filter options`);
            }
        }
        
        this.testResults.filterTests = filterTests;
        
        console.log(`📊 Filter compatibility: ${filterTests.filter(t => t.overallFilterable).length}/${profilesSnapshot.size} profiles are filterable\n`);
    }

    async testProfileCompleteness() {
        console.log('📋 Testing Profile Completeness for Search...');
        
        const profilesSnapshot = await db
            .collection('users')
            .where('isActive', '==', true)
            .limit(10)
            .get();
        
        const completenessTests = [];
        
        for (const doc of profilesSnapshot.docs) {
            const profile = doc.data();
            const profileId = doc.id;
            
            let completenessScore = 0;
            const maxScore = 6;
            
            // Check each field that contributes to search experience
            const checks = {
                displayName: !!profile.displayName,
                age: typeof profile.age === 'number' && profile.age > 0,
                location: typeof profile.location === 'string' && profile.location.length > 0,
                bio: typeof profile.bio === 'string' && profile.bio.length > 0,
                avatar: !!profile.avatarURL,
                interests: Array.isArray(profile.interests) && profile.interests.length > 0
            };
            
            completenessScore = Object.values(checks).filter(Boolean).length;
            const completenessPercentage = (completenessScore / maxScore) * 100;
            
            const completenessTest = {
                profileId,
                displayName: profile.displayName,
                completenessScore,
                completenessPercentage,
                fieldChecks: checks,
                searchReady: completenessPercentage >= 50 // At least 50% complete for good search experience
            };
            
            completenessTests.push(completenessTest);
            
            const status = completenessTest.searchReady ? '✅' : '⚠️';
            console.log(`  ${status} ${profile.displayName} - ${completenessPercentage.toFixed(0)}% complete`);
        }
        
        this.testResults.renderingTests = completenessTests;
        
        const avgCompleteness = completenessTests.reduce((sum, test) => sum + test.completenessPercentage, 0) / completenessTests.length;
        console.log(`📊 Average profile completeness: ${avgCompleteness.toFixed(1)}%\n`);
    }

    async generateRenderingReport() {
        console.log('📄 Generating Rendering Report...');
        
        const totalProfiles = this.testResults.profileData.length;
        const searchableProfiles = this.testResults.profileData.filter(p => p.isSearchable).length;
        const profilesReadyForRendering = this.testResults.renderingTests.filter(t => t.searchReady).length;
        const profilesWithImages = this.testResults.imageTests.filter(t => t.imageRenderingReady).length;
        const filterableProfiles = this.testResults.filterTests.filter(t => t.overallFilterable).length;
        
        this.testResults.summary = {
            totalProfiles,
            searchableProfiles,
            profilesReadyForRendering,
            profilesWithImages,
            filterableProfiles,
            searchReadinessPercentage: totalProfiles > 0 ? (profilesReadyForRendering / totalProfiles) * 100 : 0,
            imageAvailabilityPercentage: totalProfiles > 0 ? (profilesWithImages / totalProfiles) * 100 : 0,
            filterCompatibilityPercentage: totalProfiles > 0 ? (filterableProfiles / totalProfiles) * 100 : 0,
            overallGrade: this.calculateOverallGrade()
        };
        
        // Save report
        const reportPath = './search_profile_rendering_report.json';
        fs.writeFileSync(reportPath, JSON.stringify(this.testResults, null, 2));
        
        console.log(`📊 RENDERING TEST SUMMARY`);
        console.log(`========================`);
        console.log(`👥 Total Profiles: ${totalProfiles}`);
        console.log(`🔍 Searchable: ${searchableProfiles} (${((searchableProfiles/totalProfiles)*100).toFixed(1)}%)`);
        console.log(`📱 Ready for Rendering: ${profilesReadyForRendering} (${this.testResults.summary.searchReadinessPercentage.toFixed(1)}%)`);
        console.log(`🖼️ With Images: ${profilesWithImages} (${this.testResults.summary.imageAvailabilityPercentage.toFixed(1)}%)`);
        console.log(`🔧 Filterable: ${filterableProfiles} (${this.testResults.summary.filterCompatibilityPercentage.toFixed(1)}%)`);
        console.log(`🏆 Overall Grade: ${this.testResults.summary.overallGrade}`);
        console.log(`📄 Report saved to: ${reportPath}\n`);
        
        this.printRecommendations();
    }

    calculateOverallGrade() {
        const { searchReadinessPercentage, imageAvailabilityPercentage, filterCompatibilityPercentage } = this.testResults.summary;
        const averageScore = (searchReadinessPercentage + imageAvailabilityPercentage + filterCompatibilityPercentage) / 3;
        
        if (averageScore >= 90) return 'A+ (Excellent)';
        if (averageScore >= 80) return 'A (Very Good)';
        if (averageScore >= 70) return 'B+ (Good)';
        if (averageScore >= 60) return 'B (Fair)';
        if (averageScore >= 50) return 'C (Needs Improvement)';
        return 'D (Poor)';
    }

    printRecommendations() {
        console.log(`💡 RECOMMENDATIONS`);
        console.log(`==================`);
        
        const { searchReadinessPercentage, imageAvailabilityPercentage, filterCompatibilityPercentage } = this.testResults.summary;
        
        if (searchReadinessPercentage < 80) {
            console.log(`📝 Profile Completeness: Improve profile data quality to enhance search experience`);
        }
        
        if (imageAvailabilityPercentage < 70) {
            console.log(`📸 Image Upload: Encourage users to add profile photos for better engagement`);
        }
        
        if (filterCompatibilityPercentage < 80) {
            console.log(`🔍 Filter Data: Add more structured data (age, location, interests) to improve filtering`);
        }
        
        if (searchReadinessPercentage >= 80 && imageAvailabilityPercentage >= 70 && filterCompatibilityPercentage >= 80) {
            console.log(`🎉 Excellent! Profiles are well-optimized for search rendering`);
        }
        
        console.log(`\n🚀 NEXT STEPS`);
        console.log(`=============`);
        console.log(`1. Test search screen with actual iOS app`);
        console.log(`2. Verify profile card rendering with different data scenarios`);
        console.log(`3. Test image loading performance`);
        console.log(`4. Validate search filter functionality`);
        console.log(`5. Monitor user engagement with search results`);
    }
}

// Run tests
async function main() {
    const tester = new SearchProfileRenderingTester();
    
    try {
        await tester.runAllTests();
        console.log('🎉 Search profile rendering testing completed successfully!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Testing failed:', error.message);
        process.exit(1);
    }
}

// Run if called directly
if (require.main === module) {
    main();
}

module.exports = SearchProfileRenderingTester;
