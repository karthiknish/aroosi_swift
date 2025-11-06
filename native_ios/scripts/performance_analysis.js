#!/usr/bin/env node

/**
 * iOS App Performance Analysis
 * 
 * Comprehensive analysis of potential performance issues in the Aroosi iOS app
 * including SwiftUI rendering, memory usage, database queries, and network requests.
 */

const fs = require('fs');
const path = require('path');

// Configuration
const PROJECT_ROOT = path.join(__dirname, '..');
const SOURCES_DIR = path.join(PROJECT_ROOT, 'Sources');

// Performance analysis results
const analysisResults = {
    swiftuiPerformance: { issues: [], recommendations: [], score: 0 },
    memoryManagement: { issues: [], recommendations: [], score: 0 },
    databaseQueries: { issues: [], recommendations: [], score: 0 },
    imageLoading: { issues: [], recommendations: [], score: 0 },
    networkRequests: { issues: [], recommendations: [], score: 0 },
    componentRendering: { issues: [], recommendations: [], score: 0 }
};

function analyzeSwiftUIPerformance() {
    console.log('🔍 Analyzing SwiftUI Performance Issues...\n');
    
    const swiftFiles = findSwiftFiles();
    let issues = [];
    let recommendations = [];
    
    swiftFiles.forEach(filePath => {
        const content = fs.readFileSync(filePath, 'utf8');
        
        // Check for potential performance issues
        checkForPerformanceAntiPatterns(content, filePath, issues);
        checkForAnimationIssues(content, filePath, issues);
        checkForStateManagementIssues(content, filePath, issues);
        checkForListPerformance(content, filePath, issues);
    });
    
    // Generate recommendations
    if (issues.length > 0) {
        recommendations.push('Use @StateObject instead of @State for ObservableObjects');
        recommendations.push('Implement lazy loading for large lists with LazyVStack');
        recommendations.push('Avoid unnecessary view re-renders with proper view identification');
        recommendations.push('Use onAppear and onDisappear for resource management');
        recommendations.push('Implement view recycling for complex list items');
    }
    
    const score = Math.max(0, 100 - (issues.length * 10));
    
    analysisResults.swiftuiPerformance = {
        issues,
        recommendations,
        score
    };
    
    console.log(`✅ SwiftUI Performance Analysis Complete - Score: ${score}/100`);
    console.log(`   Issues Found: ${issues.length}`);
    console.log(`   Recommendations: ${recommendations.length}\n`);
}

function checkForPerformanceAntiPatterns(content, filePath, issues) {
    // Check for @State with ObservableObject
    if (content.match(/@State.*:.*ViewModel/)) {
        issues.push({
            file: filePath,
            type: 'State Management',
            severity: 'High',
            description: '@State used with ObservableObject - should use @StateObject',
            impact: 'Memory leaks and unexpected view recreations'
        });
    }
    
    // Check for missing lazy loading in large lists
    if (content.includes('ForEach') && !content.includes('LazyVStack') && !content.includes('LazyHStack')) {
        const forEachCount = (content.match(/ForEach/g) || []).length;
        if (forEachCount > 2) {
            issues.push({
                file: filePath,
                type: 'List Performance',
                severity: 'Medium',
                description: 'Multiple ForEach without lazy loading',
                impact: 'Poor performance with large datasets'
            });
        }
    }
    
    // Check for unnecessary re-renders
    if (content.includes('.animation(') && content.includes('@State')) {
        issues.push({
            file: filePath,
            type: 'Animation Performance',
            severity: 'Low',
            description: 'Animation on @State may cause unnecessary re-renders',
            impact: 'Minor performance degradation'
        });
    }
}

function checkForAnimationIssues(content, filePath, issues) {
    // Check for expensive animations
    if (content.includes('.animation(.spring') || content.includes('.animation(.easeInOut')) {
        issues.push({
            file: filePath,
            type: 'Animation Performance',
            severity: 'Low',
            description: 'Expensive animation curves detected',
            impact: 'Potential frame drops during animations'
        });
    }
    
    // Check for simultaneous animations
    const animationCount = (content.match(/\.animation\(/g) || []).length;
    if (animationCount > 5) {
        issues.push({
            file: filePath,
            type: 'Animation Performance',
            severity: 'Medium',
            description: `Too many animations (${animationCount}) in single view`,
            impact: 'Performance degradation during complex animations'
        });
    }
}

function checkForStateManagementIssues(content, filePath, issues) {
    // Check for excessive @State variables
    const stateCount = (content.match(/@State\s+private\s+/g) || []).length;
    if (stateCount > 10) {
        issues.push({
            file: filePath,
            type: 'State Management',
            severity: 'Medium',
            description: `Too many @State variables (${stateCount})`,
            impact: 'Unnecessary view re-renders and memory usage'
        });
    }
    
    // Check for @Published without proper optimization
    if (content.includes('@Published') && !content.includes('@Published private(set)')) {
        issues.push({
            file: filePath,
            type: 'State Management',
            severity: 'Low',
            description: '@Published properties should be private(set) when possible',
            impact: 'Unnecessary view updates'
        });
    }
}

function checkForListPerformance(content, filePath, issues) {
    // Check for List without id parameter
    if (content.match(/List\s*\{[^}]*ForEach[^)]*}/s) && !content.includes('ForEach(')) {
        issues.push({
            file: filePath,
            type: 'List Performance',
            severity: 'High',
            description: 'List without proper ForEach identification',
            impact: 'Poor list performance and memory usage'
        });
    }
    
    // Check for complex views in ForEach
    if (content.includes('ForEach') && content.includes('VStack') && content.includes('HStack')) {
        const forEachMatches = content.match(/ForEach[^{]*\{[^}]*VStack[^}]*HStack[^}]*}/gs);
        if (forEachMatches && forEachMatches.length > 0) {
            issues.push({
                file: filePath,
                type: 'List Performance',
                severity: 'Medium',
                description: 'Complex nested layouts in ForEach',
                impact: 'Slow list rendering and scrolling'
            });
        }
    }
}

function analyzeMemoryManagement() {
    console.log('🧠 Analyzing Memory Management Issues...\n');
    
    const swiftFiles = findSwiftFiles();
    let issues = [];
    let recommendations = [];
    
    swiftFiles.forEach(filePath => {
        const content = fs.readFileSync(filePath, 'utf8');
        
        checkForMemoryLeaks(content, filePath, issues);
        checkForStrongReferenceCycles(content, filePath, issues);
        checkForImageMemoryIssues(content, filePath, issues);
        checkForCacheManagement(content, filePath, issues);
    });
    
    // Generate recommendations
    if (issues.length > 0) {
        recommendations.push('Use weak references for delegates and closures');
        recommendations.push('Implement proper image caching with memory limits');
        recommendations.push('Use @StateObject for ObservableObject lifecycle management');
        recommendations.push('Implement cache cleanup policies');
        recommendations.push('Use Instruments to monitor memory usage');
    }
    
    const score = Math.max(0, 100 - (issues.length * 15));
    
    analysisResults.memoryManagement = {
        issues,
        recommendations,
        score
    };
    
    console.log(`✅ Memory Management Analysis Complete - Score: ${score}/100`);
    console.log(`   Issues Found: ${issues.length}`);
    console.log(`   Recommendations: ${recommendations.length}\n`);
}

function checkForMemoryLeaks(content, filePath, issues) {
    // Check for potential retain cycles in closures
    if (content.match(/\[weak self\]/) === null && content.includes('completion:')) {
        issues.push({
            file: filePath,
            type: 'Memory Leak',
            severity: 'High',
            description: 'Completion handlers without weak self references',
            impact: 'Potential memory leaks and retain cycles'
        });
    }
    
    // Check for strong delegate references
    if (content.includes('delegate') && !content.includes('weak')) {
        issues.push({
            file: filePath,
            type: 'Memory Leak',
            severity: 'High',
            description: 'Strong delegate references detected',
            impact: 'Memory leaks and retain cycles'
        });
    }
}

function checkForStrongReferenceCycles(content, filePath, issues) {
    // Check for closure patterns that might cause retain cycles
    if (content.includes('{') && content.includes('self.') && !content.includes('[weak self]')) {
        issues.push({
            file: filePath,
            type: 'Retain Cycle',
            severity: 'Medium',
            description: 'Closure using self without weak reference',
            impact: 'Potential retain cycles'
        });
    }
}

function checkForImageMemoryIssues(content, filePath, issues) {
    // Check for image loading without memory management
    if (content.includes('AsyncImage') && !content.includes('cache')) {
        issues.push({
            file: filePath,
            type: 'Image Memory',
            severity: 'Medium',
            description: 'AsyncImage without caching strategy',
            impact: 'High memory usage from repeated image loading'
        });
    }
    
    // Check for large image handling
    if (content.includes('Image') && !content.includes('.resizable()')) {
        issues.push({
            file: filePath,
            type: 'Image Memory',
            severity: 'Low',
            description: 'Image without proper resizing',
            impact: 'Unnecessary memory usage'
        });
    }
}

function checkForCacheManagement(content, filePath, issues) {
    // Check for cache implementation
    if (content.includes('cache') && !content.includes('NSCache')) {
        issues.push({
            file: filePath,
            type: 'Cache Management',
            severity: 'Low',
            description: 'Custom cache without NSCache',
            impact: 'Suboptimal cache performance'
        });
    }
}

function analyzeDatabaseQueries() {
    console.log('🗄️ Analyzing Database Query Performance...\n');
    
    const swiftFiles = findSwiftFiles();
    let issues = [];
    let recommendations = [];
    
    swiftFiles.forEach(filePath => {
        const content = fs.readFileSync(filePath, 'utf8');
        
        checkForQueryEfficiency(content, filePath, issues);
        checkForIndexingIssues(content, filePath, issues);
        checkForPaginationIssues(content, filePath, issues);
        checkForQueryOptimization(content, filePath, issues);
    });
    
    // Generate recommendations
    if (issues.length > 0) {
        recommendations.push('Implement proper database indexing for frequently queried fields');
        recommendations.push('Use pagination for large datasets');
        recommendations.push('Implement query result caching');
        recommendations.push('Use batch operations for multiple updates');
        recommendations.push('Monitor query performance with Firebase Performance Monitoring');
    }
    
    const score = Math.max(0, 100 - (issues.length * 12));
    
    analysisResults.databaseQueries = {
        issues,
        recommendations,
        score
    };
    
    console.log(`✅ Database Query Analysis Complete - Score: ${score}/100`);
    console.log(`   Issues Found: ${issues.length}`);
    console.log(`   Recommendations: ${recommendations.length}\n`);
}

function checkForQueryEfficiency(content, filePath, issues) {
    // Check for multiple collection queries
    const collectionQueries = (content.match(/collection\(/g) || []).length;
    if (collectionQueries > 3) {
        issues.push({
            file: filePath,
            type: 'Query Efficiency',
            severity: 'Medium',
            description: `Multiple collection queries (${collectionQueries}) in single operation`,
            impact: 'Slow query performance and increased cost'
        });
    }
    
    // Check for where clause complexity
    const whereClauses = (content.match(/\.where\(/g) || []).length;
    if (whereClauses > 5) {
        issues.push({
            file: filePath,
            type: 'Query Efficiency',
            severity: 'Medium',
            description: `Complex query with many where clauses (${whereClauses})`,
            impact: 'Slow query performance'
        });
    }
}

function checkForIndexingIssues(content, filePath, issues) {
    // Check for queries on non-indexed fields
    if (content.includes('.where(') && !content.includes('orderBy:')) {
        issues.push({
            file: filePath,
            type: 'Indexing',
            severity: 'High',
            description: 'Query without proper indexing',
            impact: 'Very slow query performance with large datasets'
        });
    }
}

function checkForPaginationIssues(content, filePath, issues) {
    // Check for limit usage without pagination
    if (content.includes('.limit(') && !content.includes('startAfter') && !content.includes('cursor')) {
        issues.push({
            file: filePath,
            type: 'Pagination',
            severity: 'Medium',
            description: 'Query with limit but no pagination strategy',
            impact: 'Poor performance with large datasets'
        });
    }
}

function checkForQueryOptimization(content, filePath, issues) {
    // Check for N+1 query problems
    if (content.includes('forEach') && content.includes('getDocument')) {
        issues.push({
            file: filePath,
            type: 'Query Optimization',
            severity: 'High',
            description: 'Potential N+1 query pattern detected',
            impact: 'Very poor performance with multiple document fetches'
        });
    }
}

function analyzeImageLoading() {
    console.log('🖼️ Analyzing Image Loading Performance...\n');
    
    const swiftFiles = findSwiftFiles();
    let issues = [];
    let recommendations = [];
    
    swiftFiles.forEach(filePath => {
        const content = fs.readFileSync(filePath, 'utf8');
        
        checkForImageOptimization(content, filePath, issues);
        checkForCachingStrategy(content, filePath, issues);
        checkForImageSize(content, filePath, issues);
        checkForLoadingStrategy(content, filePath, issues);
    });
    
    // Generate recommendations
    if (issues.length > 0) {
        recommendations.push('Implement image resizing and compression');
        recommendations.push('Use proper caching strategies with memory limits');
        recommendations.push('Implement progressive image loading');
        recommendations.push('Use WebP format for better compression');
        recommendations.push('Implement image preloading for critical images');
    }
    
    const score = Math.max(0, 100 - (issues.length * 10));
    
    analysisResults.imageLoading = {
        issues,
        recommendations,
        score
    };
    
    console.log(`✅ Image Loading Analysis Complete - Score: ${score}/100`);
    console.log(`   Issues Found: ${issues.length}`);
    console.log(`   Recommendations: ${recommendations.length}\n`);
}

function checkForImageOptimization(content, filePath, issues) {
    // Check for image optimization
    if (content.includes('AsyncImage') && !content.includes('.resizable()')) {
        issues.push({
            file: filePath,
            type: 'Image Optimization',
            severity: 'Medium',
            description: 'AsyncImage without proper resizing',
            impact: 'Unnecessary bandwidth and memory usage'
        });
    }
}

function checkForCachingStrategy(content, filePath, issues) {
    // Check for caching implementation
    if (content.includes('AsyncImage') && !content.includes('cache')) {
        issues.push({
            file: filePath,
            type: 'Caching Strategy',
            severity: 'High',
            description: 'Image loading without caching strategy',
            impact: 'Repeated downloads and poor performance'
        });
    }
}

function checkForImageSize(content, filePath, issues) {
    // Check for large image handling
    if (content.includes('URL(string:') && !content.includes('thumbnail') && !content.includes('resized')) {
        issues.push({
            file: filePath,
            type: 'Image Size',
            severity: 'Medium',
            description: 'Loading full-size images without optimization',
            impact: 'High memory and bandwidth usage'
        });
    }
}

function checkForLoadingStrategy(content, filePath, issues) {
    // Check for loading strategy
    if (content.includes('AsyncImage') && !content.includes('placeholder')) {
        issues.push({
            file: filePath,
            type: 'Loading Strategy',
            severity: 'Low',
            description: 'AsyncImage without loading placeholder',
            impact: 'Poor user experience during loading'
        });
    }
}

function analyzeNetworkRequests() {
    console.log('🌐 Analyzing Network Request Performance...\n');
    
    const swiftFiles = findSwiftFiles();
    let issues = [];
    let recommendations = [];
    
    swiftFiles.forEach(filePath => {
        const content = fs.readFileSync(filePath, 'utf8');
        
        checkForRequestOptimization(content, filePath, issues);
        checkForErrorHandling(content, filePath, issues);
        checkForRequestBatching(content, filePath, issues);
        checkForOfflineSupport(content, filePath, issues);
    });
    
    // Generate recommendations
    if (issues.length > 0) {
        recommendations.push('Implement request batching for multiple operations');
        recommendations.push('Add proper error handling and retry mechanisms');
        recommendations.push('Implement offline data synchronization');
        recommendations.push('Use request caching for frequently accessed data');
        recommendations.push('Monitor network performance with analytics');
    }
    
    const score = Math.max(0, 100 - (issues.length * 8));
    
    analysisResults.networkRequests = {
        issues,
        recommendations,
        score
    };
    
    console.log(`✅ Network Request Analysis Complete - Score: ${score}/100`);
    console.log(`   Issues Found: ${issues.length}`);
    console.log(`   Recommendations: ${recommendations.length}\n`);
}

function checkForRequestOptimization(content, filePath, issues) {
    // Check for multiple simultaneous requests
    const asyncCalls = (content.match(/await /g) || []).length;
    if (asyncCalls > 5) {
        issues.push({
            file: filePath,
            type: 'Request Optimization',
            severity: 'Medium',
            description: `Multiple async calls (${asyncCalls}) without batching`,
            impact: 'Increased network usage and latency'
        });
    }
}

function checkForErrorHandling(content, filePath, issues) {
    // Check for proper error handling
    if (content.includes('await ') && !content.includes('try')) {
        issues.push({
            file: filePath,
            type: 'Error Handling',
            severity: 'High',
            description: 'Async calls without proper error handling',
            impact: 'Poor user experience and potential crashes'
        });
    }
}

function checkForRequestBatching(content, filePath, issues) {
    // Check for request batching opportunities
    if (content.includes('await ') && !content.includes('Task.whenAll') && !content.includes('TaskGroup')) {
        issues.push({
            file: filePath,
            type: 'Request Batching',
            severity: 'Medium',
            description: 'Multiple async calls without batching',
            impact: 'Increased network latency'
        });
    }
}

function checkForOfflineSupport(content, filePath, issues) {
    // Check for offline support
    if (content.includes('await ') && !content.includes('offline') && !content.includes('cache')) {
        issues.push({
            file: filePath,
            type: 'Offline Support',
            severity: 'Low',
            description: 'Network requests without offline support',
            impact: 'Poor offline user experience'
        });
    }
}

function analyzeComponentRendering() {
    console.log('🎨 Analyzing Component Rendering Performance...\n');
    
    const swiftFiles = findSwiftFiles();
    let issues = [];
    let recommendations = [];
    
    swiftFiles.forEach(filePath => {
        const content = fs.readFileSync(filePath, 'utf8');
        
        checkForViewComplexity(content, filePath, issues);
        checkForRedundantViews(content, filePath, issues);
        checkForViewIdentification(content, filePath, issues);
        checkForConditionalRendering(content, filePath, issues);
    });
    
    // Generate recommendations
    if (issues.length > 0) {
        recommendations.push('Simplify complex view hierarchies');
        recommendations.push('Use proper view identification for lists');
        recommendations.push('Implement view recycling for repeated components');
        recommendations.push('Use conditional rendering efficiently');
        recommendations.push('Profile view performance with Instruments');
    }
    
    const score = Math.max(0, 100 - (issues.length * 10));
    
    analysisResults.componentRendering = {
        issues,
        recommendations,
        score
    };
    
    console.log(`✅ Component Rendering Analysis Complete - Score: ${score}/100`);
    console.log(`   Issues Found: ${issues.length}`);
    console.log(`   Recommendations: ${recommendations.length}\n`);
}

function checkForViewComplexity(content, filePath, issues) {
    // Check for deeply nested view hierarchies
    const nestingLevel = content.split('{').length - content.split('}').length;
    if (Math.abs(nestingLevel) > 10) {
        issues.push({
            file: filePath,
            type: 'View Complexity',
            severity: 'Medium',
            description: `Deeply nested view hierarchy (${Math.abs(nestingLevel)} levels)`,
            impact: 'Slow view rendering and updates'
        });
    }
}

function checkForRedundantViews(content, filePath, issues) {
    // Check for redundant container views
    const vstackCount = (content.match(/VStack/g) || []).length;
    const hstackCount = (content.match(/HStack/g) || []).length;
    if (vstackCount > 10 || hstackCount > 10) {
        issues.push({
            file: filePath,
            type: 'Redundant Views',
            severity: 'Low',
            description: `Many container views (VStack: ${vstackCount}, HStack: ${hstackCount})`,
            impact: 'Unnecessary view overhead'
        });
    }
}

function checkForViewIdentification(content, filePath, issues) {
    // Check for proper view identification
    if (content.includes('ForEach') && !content.includes('.id(')) {
        issues.push({
            file: filePath,
            type: 'View Identification',
            severity: 'High',
            description: 'ForEach without proper view identification',
            impact: 'Poor list performance and memory usage'
        });
    }
}

function checkForConditionalRendering(content, filePath, issues) {
    // Check for inefficient conditional rendering
    if (content.includes('if ') && content.includes('else ') && content.includes('View')) {
        issues.push({
            file: filePath,
            type: 'Conditional Rendering',
            severity: 'Low',
            description: 'Complex conditional rendering patterns',
            impact: 'Potential view rendering inefficiencies'
        });
    }
}

function findSwiftFiles() {
    const swiftFiles = [];
    
    function walkDir(dir) {
        const files = fs.readdirSync(dir);
        
        for (const file of files) {
            const filePath = path.join(dir, file);
            const stat = fs.statSync(filePath);
            
            if (stat.isDirectory() && !file.startsWith('.')) {
                walkDir(filePath);
            } else if (file.endsWith('.swift')) {
                swiftFiles.push(filePath);
            }
        }
    }
    
    walkDir(SOURCES_DIR);
    return swiftFiles;
}

function generateReport() {
    console.log('📊 GENERATING PERFORMANCE ANALYSIS REPORT\n');
    console.log('=' .repeat(60));
    
    const categories = Object.keys(analysisResults);
    let totalScore = 0;
    let totalIssues = 0;
    
    categories.forEach(category => {
        const result = analysisResults[category];
        totalScore += result.score;
        totalIssues += result.issues.length;
        
        console.log(`\n🔍 ${category.toUpperCase()}`);
        console.log('-'.repeat(40));
        console.log(`Score: ${result.score}/100`);
        console.log(`Issues: ${result.issues.length}`);
        console.log(`Recommendations: ${result.recommendations.length}`);
        
        if (result.issues.length > 0) {
            console.log('\n🚨 Critical Issues:');
            result.issues.slice(0, 3).forEach(issue => {
                console.log(`   • ${issue.description} (${issue.severity})`);
            });
        }
        
        if (result.recommendations.length > 0) {
            console.log('\n💡 Top Recommendations:');
            result.recommendations.slice(0, 3).forEach(rec => {
                console.log(`   • ${rec}`);
            });
        }
    });
    
    const overallScore = Math.round(totalScore / categories.length);
    
    console.log('\n' + '='.repeat(60));
    console.log('📈 OVERALL PERFORMANCE SCORE');
    console.log('=' .repeat(60));
    console.log(`Total Score: ${overallScore}/100`);
    console.log(`Total Issues: ${totalIssues}`);
    
    // Performance grade
    let grade = 'A';
    if (overallScore < 60) grade = 'F';
    else if (overallScore < 70) grade = 'D';
    else if (overallScore < 80) grade = 'C';
    else if (overallScore < 90) grade = 'B';
    
    console.log(`Performance Grade: ${grade}`);
    
    // Priority recommendations
    console.log('\n🎯 PRIORITY OPTIMIZATIONS');
    console.log('=' .repeat(60));
    
    const allIssues = [];
    categories.forEach(category => {
        analysisResults[category].issues.forEach(issue => {
            allIssues.push({ ...issue, category });
        });
    });
    
    // Sort by severity
    allIssues.sort((a, b) => {
        const severityOrder = { 'High': 3, 'Medium': 2, 'Low': 1 };
        return severityOrder[b.severity] - severityOrder[a.severity];
    });
    
    console.log('\n🔥 High Priority Issues:');
    allIssues.filter(issue => issue.severity === 'High').slice(0, 5).forEach(issue => {
        console.log(`   • ${issue.description} - ${issue.category}`);
    });
    
    console.log('\n⚠️ Medium Priority Issues:');
    allIssues.filter(issue => issue.severity === 'Medium').slice(0, 5).forEach(issue => {
        console.log(`   • ${issue.description} - ${issue.category}`);
    });
    
    // Generate detailed report file
    const reportData = {
        timestamp: new Date().toISOString(),
        overallScore,
        grade,
        totalIssues,
        categories: analysisResults,
        priorityIssues: allIssues.filter(issue => issue.severity === 'High').slice(0, 10)
    };
    
    const reportPath = path.join(__dirname, 'performance_analysis_report.json');
    fs.writeFileSync(reportPath, JSON.stringify(reportData, null, 2));
    
    console.log(`\n📄 Detailed report saved to: ${reportPath}`);
    
    return reportData;
}

// Main execution
async function main() {
    console.log('🚀 STARTING IOS APP PERFORMANCE ANALYSIS\n');
    console.log('=' .repeat(60));
    
    try {
        analyzeSwiftUIPerformance();
        analyzeMemoryManagement();
        analyzeDatabaseQueries();
        analyzeImageLoading();
        analyzeNetworkRequests();
        analyzeComponentRendering();
        
        const report = generateReport();
        
        console.log('\n✅ Performance Analysis Complete!');
        console.log(`📊 Overall Score: ${report.overallScore}/100 (${report.grade})`);
        console.log(`🔍 Total Issues Found: ${report.totalIssues}`);
        
        process.exit(report.totalIssues > 20 ? 1 : 0);
        
    } catch (error) {
        console.error('❌ Analysis failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { main, analysisResults };
