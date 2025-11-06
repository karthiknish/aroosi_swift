#!/usr/bin/env node

/**
 * Manual Firebase Data Verification Script
 * 
 * Manually verifies key screens for proper Firebase data fetching and display
 */

const fs = require('fs');
const path = require('path');

// Configuration
const PROJECT_ROOT = path.join(__dirname, '..');
const SOURCES_DIR = path.join(PROJECT_ROOT, 'Sources');

// Key screens to verify
const keyScreens = [
    {
        name: 'DashboardView',
        path: 'Features/Dashboard/DashboardView.swift',
        viewModel: 'Features/Dashboard/DashboardViewModel.swift',
        expectedData: ['profile', 'matches', 'quickPicks', 'stats']
    },
    {
        name: 'SearchView',
        path: 'Features/Search/SearchView.swift',
        viewModel: 'Features/Search/SearchViewModel.swift',
        expectedData: ['searchResults', 'profiles']
    },
    {
        name: 'MatchesView',
        path: 'Features/Matches/MatchesView.swift',
        viewModel: 'Features/Matches/MatchesViewModel.swift',
        expectedData: ['matches', 'conversations']
    },
    {
        name: 'FavoritesView',
        path: 'Features/Favorites/FavoritesView.swift',
        viewModel: 'Features/Favorites/FavoritesViewModel.swift',
        expectedData: ['favorites']
    },
    {
        name: 'ProfileSummaryDetailView',
        path: 'Features/Profile/ProfileSummaryDetailView.swift',
        viewModel: 'Features/Profile/ProfileDetailViewModel.swift',
        expectedData: ['profileDetail', 'profile']
    },
    {
        name: 'ChatView',
        path: 'Features/Chat/ChatView.swift',
        viewModel: 'Features/Chat/ChatViewModel.swift',
        expectedData: ['messages', 'conversation']
    }
];

function verifyScreen(screen) {
    console.log(`\n🔍 Verifying ${screen.name}...`);
    
    const viewPath = path.join(SOURCES_DIR, screen.path);
    const viewModelPath = path.join(SOURCES_DIR, screen.viewModel);
    
    const verification = {
        name: screen.name,
        viewExists: false,
        viewModelExists: false,
        hasTaskModifier: false,
        hasAsyncOperations: false,
        hasDataDisplay: false,
        hasLoadingStates: false,
        hasErrorHandling: false,
        hasRepositoryIntegration: false,
        issues: [],
        status: 'unknown'
    };
    
    // Check View file
    if (fs.existsSync(viewPath)) {
        verification.viewExists = true;
        const viewContent = fs.readFileSync(viewPath, 'utf8');
        
        // Check for task modifier
        if (viewContent.includes('.task(') || viewContent.includes('.task {')) {
            verification.hasTaskModifier = true;
        }
        
        // Check for data display
        if (viewContent.includes('ForEach(') || viewContent.includes('List(') || viewContent.includes('LazyVStack(')) {
            verification.hasDataDisplay = true;
        }
        
        // Check for loading states
        if (viewContent.includes('ProgressView') || viewContent.includes('isLoading')) {
            verification.hasLoadingStates = true;
        }
        
        // Check for error handling
        if (viewContent.includes('errorMessage') || viewContent.includes('alert')) {
            verification.hasErrorHandling = true;
        }
    } else {
        verification.issues.push('View file does not exist');
    }
    
    // Check ViewModel file
    if (fs.existsSync(viewModelPath)) {
        verification.viewModelExists = true;
        const viewModelContent = fs.readFileSync(viewModelPath, 'utf8');
        
        // Check for async operations
        if (viewModelContent.includes('async ') || viewModelContent.includes('await ')) {
            verification.hasAsyncOperations = true;
        }
        
        // Check for repository integration
        if (viewModelContent.includes('Repository') || viewModelContent.includes('Firestore')) {
            verification.hasRepositoryIntegration = true;
        }
        
        // Check for proper state management
        if (viewModelContent.includes('@Published') && viewModelContent.includes('ObservableObject')) {
            verification.issues.push('Proper state management found');
        }
    } else {
        verification.issues.push('ViewModel file does not exist');
    }
    
    // Determine status
    if (verification.viewExists && verification.viewModelExists && 
        verification.hasTaskModifier && verification.hasAsyncOperations && 
        verification.hasDataDisplay && verification.hasRepositoryIntegration) {
        verification.status = '✅ Complete';
    } else if (verification.viewExists && verification.viewModelExists) {
        verification.status = '⚠️ Partial';
    } else {
        verification.status = '❌ Incomplete';
    }
    
    return verification;
}

function generateVerificationReport(verifications) {
    console.log('\n📊 FIREBASE DATA VERIFICATION REPORT');
    console.log('=' .repeat(60));
    
    let completeCount = 0;
    let partialCount = 0;
    let incompleteCount = 0;
    
    verifications.forEach(verification => {
        console.log(`\n${verification.status} ${verification.name}`);
        console.log(`  View: ${verification.viewExists ? '✅' : '❌'}`);
        console.log(`  ViewModel: ${verification.viewModelExists ? '✅' : '❌'}`);
        console.log(`  Task Modifier: ${verification.hasTaskModifier ? '✅' : '❌'}`);
        console.log(`  Async Operations: ${verification.hasAsyncOperations ? '✅' : '❌'}`);
        console.log(`  Data Display: ${verification.hasDataDisplay ? '✅' : '❌'}`);
        console.log(`  Loading States: ${verification.hasLoadingStates ? '✅' : '❌'}`);
        console.log(`  Error Handling: ${verification.hasErrorHandling ? '✅' : '❌'}`);
        console.log(`  Repository Integration: ${verification.hasRepositoryIntegration ? '✅' : '❌'}`);
        
        if (verification.issues.length > 0) {
            console.log(`  Issues: ${verification.issues.join(', ')}`);
        }
        
        if (verification.status === '✅ Complete') completeCount++;
        else if (verification.status === '⚠️ Partial') partialCount++;
        else incompleteCount++;
    });
    
    console.log('\n📈 SUMMARY');
    console.log('-'.repeat(30));
    console.log(`✅ Complete: ${completeCount}/${verifications.length}`);
    console.log(`⚠️ Partial: ${partialCount}/${verifications.length}`);
    console.log(`❌ Incomplete: ${incompleteCount}/${verifications.length}`);
    
    const completionRate = (completeCount / verifications.length) * 100;
    console.log(`🎯 Completion Rate: ${completionRate.toFixed(1)}%`);
    
    let grade = 'A';
    if (completionRate < 60) grade = 'F';
    else if (completionRate < 70) grade = 'D';
    else if (completionRate < 80) grade = 'C';
    else if (completionRate < 90) grade = 'B';
    
    console.log(`🏆 Grade: ${grade}`);
    
    return {
        completionRate,
        grade,
        completeCount,
        partialCount,
        incompleteCount,
        verifications
    };
}

// Main execution
function main() {
    console.log('🚀 MANUAL FIREBASE DATA VERIFICATION');
    console.log('=' .repeat(60));
    
    const verifications = keyScreens.map(screen => verifyScreen(screen));
    const report = generateVerificationReport(verifications);
    
    // Save detailed report
    const reportPath = path.join(__dirname, 'manual_firebase_verification_report.json');
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
    
    console.log(`\n📄 Detailed report saved to: ${reportPath}`);
    
    if (report.completionRate >= 80) {
        console.log('\n🎉 Firebase data integration is in good shape!');
        process.exit(0);
    } else {
        console.log('\n⚠️ Some screens need attention for proper Firebase integration.');
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { main, verifications: keyScreens };
