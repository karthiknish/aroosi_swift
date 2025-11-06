#!/usr/bin/env node

/**
 * Firebase Data Validation Script
 * 
 * Analyzes all iOS screens to ensure they properly fetch data from Firebase
 * and display it according to the setup configuration.
 */

const fs = require('fs');
const path = require('path');

// Configuration
const PROJECT_ROOT = path.join(__dirname, '..');
const SOURCES_DIR = path.join(PROJECT_ROOT, 'Sources');

// Validation results
const validationResults = {
    screens: [],
    issues: [],
    recommendations: [],
    summary: {
        totalScreens: 0,
        screensWithFirebase: 0,
        screensWithDataFetching: 0,
        screensWithDataDisplay: 0,
        criticalIssues: 0,
        warnings: 0
    }
};

function analyzeAllScreens() {
    console.log('🔍 Analyzing All Screens for Firebase Data Fetching...\n');
    
    const screenFiles = findScreenFiles();
    validationResults.summary.totalScreens = screenFiles.length;
    
    screenFiles.forEach(filePath => {
        analyzeScreen(filePath);
    });
}

function findScreenFiles() {
    const screenFiles = [];
    
    function walkDir(dir) {
        try {
            const files = fs.readdirSync(dir);
            
            for (const file of files) {
                const filePath = path.join(dir, file);
                const stat = fs.statSync(filePath);
                
                if (stat.isDirectory() && !file.startsWith('.')) {
                    walkDir(filePath);
                } else if (file.endsWith('View.swift') && !file.includes('Preview')) {
                    screenFiles.push(filePath);
                }
            }
        } catch (error) {
            // Skip directories that can't be read
        }
    }
    
    walkDir(SOURCES_DIR);
    return screenFiles;
}

function analyzeScreen(filePath) {
    const relativePath = path.relative(PROJECT_ROOT, filePath);
    const content = fs.readFileSync(filePath, 'utf8');
    const screenName = path.basename(filePath, '.swift');
    
    const screenAnalysis = {
        name: screenName,
        path: relativePath,
        hasFirebase: false,
        hasDataFetching: false,
        hasDataDisplay: false,
        hasViewModel: false,
        hasRepository: false,
        hasTaskModifier: false,
        hasAsyncOperations: false,
        issues: [],
        recommendations: []
    };
    
    // Check for Firebase integration
    checkFirebaseIntegration(content, screenAnalysis);
    
    // Check for data fetching patterns
    checkDataFetching(content, screenAnalysis);
    
    // Check for data display patterns
    checkDataDisplay(content, screenAnalysis);
    
    // Check for proper async/await usage
    checkAsyncOperations(content, screenAnalysis);
    
    // Update summary
    if (screenAnalysis.hasFirebase) validationResults.summary.screensWithFirebase++;
    if (screenAnalysis.hasDataFetching) validationResults.summary.screensWithDataFetching++;
    if (screenAnalysis.hasDataDisplay) validationResults.summary.screensWithDataDisplay++;
    
    validationResults.screens.push(screenAnalysis);
    
    // Add issues to global results
    screenAnalysis.issues.forEach(issue => {
        validationResults.issues.push({
            screen: screenName,
            ...issue
        });
    });
    
    screenAnalysis.recommendations.forEach(rec => {
        validationResults.recommendations.push({
            screen: screenName,
            ...rec
        });
    });
}

function checkFirebaseIntegration(content, analysis) {
    // Check for Firebase imports
    const firebaseImports = [
        'import FirebaseFirestore',
        'import FirebaseAuth',
        'import FirebaseCore',
        'import FirebaseStorage'
    ];
    
    const hasFirebaseImport = firebaseImports.some(imp => content.includes(imp));
    analysis.hasFirebase = hasFirebaseImport;
    
    if (!hasFirebaseImport) {
        // Check if it uses repositories that use Firebase
        const repositoryPatterns = [
            'FirestoreProfileRepository',
            'FirestoreMatchRepository',
            'FirestoreChatMessageRepository',
            'FirestoreInterestRepository',
            'FirestoreSafetyRepository'
        ];
        
        const hasFirebaseRepository = repositoryPatterns.some(repo => content.includes(repo));
        analysis.hasFirebase = hasFirebaseRepository;
    }
    
    // Check for ViewModel usage (indirect Firebase usage)
    if (content.includes('@StateObject') && content.includes('ViewModel')) {
        analysis.hasViewModel = true;
    }
    
    // Check for direct repository usage
    if (content.includes('ProfileRepository') || content.includes('MatchRepository')) {
        analysis.hasRepository = true;
    }
}

function checkDataFetching(content, analysis) {
    // Check for task modifier
    if (content.includes('.task(') || content.includes('.task {')) {
        analysis.hasTaskModifier = true;
    }
    
    // Check for async functions
    if (content.includes('async ') || content.includes('await ')) {
        analysis.hasAsyncOperations = true;
    }
    
    // Check for data fetching patterns
    const fetchingPatterns = [
        'fetchProfile',
        'fetchMatches',
        'fetchFavorites',
        'fetchShortlist',
        'searchProfiles',
        'streamMessages',
        'streamMatches',
        'loadIfNeeded',
        'refresh()',
        'loadMore()',
        'observeMatches',
        'observeMessages'
    ];
    
    const hasFetchingPattern = fetchingPatterns.some(pattern => content.includes(pattern));
    analysis.hasDataFetching = hasFetchingPattern || analysis.hasTaskModifier;
    
    // Check for proper loading states
    if (!content.includes('isLoading') && hasFetchingPattern) {
        analysis.issues.push({
            type: 'warning',
            message: 'Missing loading state management',
            impact: 'Poor user experience during data loading'
        });
    }
    
    // Check for error handling
    if (hasFetchingPattern && !content.includes('errorMessage') && !content.includes('catch')) {
        analysis.issues.push({
            type: 'warning',
            message: 'Missing error handling for data fetching',
            impact: 'Users won\'t see error messages when requests fail'
        });
    }
}

function checkDataDisplay(content, analysis) {
    // Check for data display patterns
    const displayPatterns = [
        'ForEach(',
        'List(',
        'LazyVStack(',
        'LazyVGrid(',
        'NavigationLink(',
        'Text(',
        'Image(',
        'AsyncImage('
    ];
    
    const hasDisplayPattern = displayPatterns.some(pattern => content.includes(pattern));
    analysis.hasDataDisplay = hasDisplayPattern;
    
    // Check for empty state handling
    if (analysis.hasDataFetching && !content.includes('isEmpty') && !content.includes('emptyState')) {
        analysis.recommendations.push({
            type: 'improvement',
            message: 'Add empty state handling for better UX',
            impact: 'Users will see appropriate messages when no data is available'
        });
    }
    
    // Check for conditional rendering based on data
    if (analysis.hasDataFetching && !content.includes('if ') && content.includes('ForEach')) {
        analysis.issues.push({
            type: 'warning',
            message: 'Missing conditional rendering for data states',
            impact: 'UI may show empty lists without proper messaging'
        });
    }
}

function checkAsyncOperations(content, analysis) {
    // Check for proper async/await usage
    if (content.includes('async ') && !content.includes('await ')) {
        analysis.issues.push({
            type: 'error',
            message: 'Async function without await operations',
            impact: 'Async operations may not be properly awaited'
        });
    }
    
    // Check for Task wrapper in SwiftUI
    if (content.includes('await ') && !content.includes('Task {') && !content.includes('.task(')) {
        analysis.issues.push({
            type: 'error',
            message: 'Await operations outside of Task context',
            impact: 'Async operations won\'t work in SwiftUI context'
        });
    }
    
    // Check for MainActor usage
    if (content.includes('@Published') && !content.includes('@MainActor')) {
        analysis.recommendations.push({
            type: 'improvement',
            message: 'Consider using @MainActor for ViewModels with @Published properties',
            impact: 'Ensures UI updates happen on main thread'
        });
    }
}

function analyzeViewModels() {
    console.log('🧠 Analyzing ViewModels for Data Management...\n');
    
    const viewModelFiles = findViewModelFiles();
    
    viewModelFiles.forEach(filePath => {
        analyzeViewModel(filePath);
    });
}

function findViewModelFiles() {
    const viewModelFiles = [];
    
    function walkDir(dir) {
        try {
            const files = fs.readdirSync(dir);
            
            for (const file of files) {
                const filePath = path.join(dir, file);
                const stat = fs.statSync(filePath);
                
                if (stat.isDirectory() && !file.startsWith('.')) {
                    walkDir(filePath);
                } else if (file.endsWith('ViewModel.swift')) {
                    viewModelFiles.push(filePath);
                }
            }
        } catch (error) {
            // Skip directories that can't be read
        }
    }
    
    walkDir(SOURCES_DIR);
    return viewModelFiles;
}

function analyzeViewModel(filePath) {
    const relativePath = path.relative(PROJECT_ROOT, filePath);
    const content = fs.readFileSync(filePath, 'utf8');
    const viewModelName = path.basename(filePath, '.swift');
    
    const viewModelAnalysis = {
        name: viewModelName,
        path: relativePath,
        hasMainActor: false,
        hasObservableObject: false,
        hasPublishedState: false,
        hasRepositoryInjection: false,
        hasAsyncMethods: false,
        hasErrorHandling: false,
        hasLoadingStates: false,
        issues: [],
        recommendations: []
    };
    
    // Check for proper ViewModel setup
    if (content.includes('@MainActor')) {
        viewModelAnalysis.hasMainActor = true;
    } else {
        viewModelAnalysis.issues.push({
            type: 'warning',
            message: 'Missing @MainActor annotation',
            impact: 'UI updates may not happen on main thread'
        });
    }
    
    if (content.includes('ObservableObject')) {
        viewModelAnalysis.hasObservableObject = true;
    } else {
        viewModelAnalysis.issues.push({
            type: 'error',
            message: 'ViewModel doesn\'t conform to ObservableObject',
            impact: 'UI won\' update when data changes'
        });
    }
    
    if (content.includes('@Published')) {
        viewModelAnalysis.hasPublishedState = true;
    }
    
    // Check for repository dependency injection
    if (content.includes('ProfileRepository') || content.includes('MatchRepository')) {
        viewModelAnalysis.hasRepositoryInjection = true;
    }
    
    // Check for async methods
    if (content.includes('func ') && content.includes('async ')) {
        viewModelAnalysis.hasAsyncMethods = true;
    }
    
    // Check for error handling
    if (content.includes('catch') || content.includes('throw') || content.includes('errorMessage')) {
        viewModelAnalysis.hasErrorHandling = true;
    }
    
    // Check for loading states
    if (content.includes('isLoading') || content.includes('isRefreshing')) {
        viewModelAnalysis.hasLoadingStates = true;
    }
    
    // Add to results
    validationResults.screens.push({
        ...viewModelAnalysis,
        type: 'ViewModel'
    });
    
    viewModelAnalysis.issues.forEach(issue => {
        validationResults.issues.push({
            screen: viewModelName,
            type: issue.type,
            message: issue.message,
            impact: issue.impact
        });
    });
}

function generateValidationReport() {
    console.log('📊 GENERATING FIREBASE DATA VALIDATION REPORT\n');
    console.log('=' .repeat(70));
    
    const summary = validationResults.summary;
    
    console.log(`\n📈 VALIDATION SUMMARY`);
    console.log('-'.repeat(40));
    console.log(`📱 Total Screens: ${summary.totalScreens}`);
    console.log(`🔥 With Firebase: ${summary.screensWithFirebase}/${summary.totalScreens}`);
    console.log(`📥 Data Fetching: ${summary.screensWithDataFetching}/${summary.totalScreens}`);
    console.log(`📤 Data Display: ${summary.screensWithDataDisplay}/${summary.totalScreens}`);
    console.log(`❌ Critical Issues: ${summary.criticalIssues}`);
    console.log(`⚠️ Warnings: ${summary.warnings}`);
    
    // Calculate validation score
    const firebaseCoverage = (summary.screensWithFirebase / summary.totalScreens) * 100;
    const dataFetchingCoverage = (summary.screensWithDataFetching / summary.totalScreens) * 100;
    const dataDisplayCoverage = (summary.screensWithDataDisplay / summary.totalScreens) * 100;
    
    const overallScore = (firebaseCoverage + dataFetchingCoverage + dataDisplayCoverage) / 3;
    
    let grade = 'A';
    if (overallScore < 60) grade = 'F';
    else if (overallScore < 70) grade = 'D';
    else if (overallScore < 80) grade = 'C';
    else if (overallScore < 90) grade = 'B';
    
    console.log(`\n🎯 OVERALL VALIDATION SCORE: ${overallScore.toFixed(1)}/100 (${grade})`);
    
    // Show critical issues
    const criticalIssues = validationResults.issues.filter(issue => issue.type === 'error');
    if (criticalIssues.length > 0) {
        console.log('\n🚨 CRITICAL ISSUES');
        console.log('-'.repeat(30));
        criticalIssues.slice(0, 5).forEach(issue => {
            console.log(`\n❌ ${issue.message}`);
            console.log(`   Screen: ${issue.screen}`);
            console.log(`   Impact: ${issue.impact}`);
        });
    }
    
    // Show warnings
    const warnings = validationResults.issues.filter(issue => issue.type === 'warning');
    if (warnings.length > 0) {
        console.log('\n⚠️ WARNINGS');
        console.log('-'.repeat(20));
        warnings.slice(0, 5).forEach(issue => {
            console.log(`\n⚠️ ${issue.message}`);
            console.log(`   Screen: ${issue.screen}`);
        });
    }
    
    // Show recommendations
    if (validationResults.recommendations.length > 0) {
        console.log('\n💡 RECOMMENDATIONS');
        console.log('-'.repeat(25));
        validationResults.recommendations.slice(0, 5).forEach(rec => {
            console.log(`\n💡 ${rec.message}`);
            console.log(`   Screen: ${rec.screen}`);
        });
    }
    
    // Generate detailed report
    const reportData = {
        timestamp: new Date().toISOString(),
        score: overallScore,
        grade,
        summary,
        screens: validationResults.screens,
        issues: validationResults.issues,
        recommendations: validationResults.recommendations
    };
    
    const reportPath = path.join(__dirname, 'firebase_data_validation_report.json');
    fs.writeFileSync(reportPath, JSON.stringify(reportData, null, 2));
    
    console.log(`\n📄 Detailed report saved to: ${reportPath}`);
    
    return reportData;
}

// Main execution
async function main() {
    console.log('🚀 STARTING FIREBASE DATA VALIDATION\n');
    console.log('=' .repeat(70));
    
    try {
        analyzeAllScreens();
        analyzeViewModels();
        
        const report = generateValidationReport();
        
        console.log('\n✅ Firebase Data Validation Complete!');
        console.log(`📊 Overall Score: ${report.score.toFixed(1)}/100 (${report.grade})`);
        console.log(`🔍 Screens Analyzed: ${report.summary.totalScreens}`);
        
        // Exit with appropriate code based on critical issues
        if (validationResults.summary.criticalIssues > 0) {
            console.log('\n⚠️ Critical issues found - immediate attention required');
            process.exit(1);
        } else if (validationResults.summary.warnings > 5) {
            console.log('\n⚡ Warnings found - should be addressed soon');
            process.exit(0);
        } else {
            console.log('\n🎉 Firebase data integration is generally good - minor improvements available');
            process.exit(0);
        }
        
    } catch (error) {
        console.error('❌ Validation failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { main, validationResults };
