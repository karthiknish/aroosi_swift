#!/usr/bin/env node

/**
 * Focused iOS App Performance Analysis
 * 
 * Targeted analysis of actual performance issues in the Aroosi iOS app
 * focusing on critical problems that impact user experience.
 */

const fs = require('fs');
const path = require('path');

// Configuration
const PROJECT_ROOT = path.join(__dirname, '..');
const SOURCES_DIR = path.join(PROJECT_ROOT, 'Sources');
const CACHED_ASYNC_IMAGE_PATH = path.join(
    SOURCES_DIR,
    'Shared/Components/CachedAsyncImageView.swift'
);

// Performance analysis results
const performanceIssues = {
    critical: [],
    high: [],
    medium: [],
    low: []
};

function analyzeCriticalPerformanceIssues() {
    console.log('🔥 Analyzing Critical Performance Issues...\n');
    
    const criticalFiles = [
        'Sources/Features/Search/SearchView.swift',
        'Sources/Features/Chat/ChatView.swift',
        'Sources/Features/Dashboard/DashboardView.swift',
        'Sources/Shared/Components/AsyncImageView.swift',
        'Sources/Shared/Services/Repositories/ProfileSearchRepository.swift'
    ];
    
    criticalFiles.forEach(relativePath => {
        const fullPath = path.join(PROJECT_ROOT, relativePath);
        if (fs.existsSync(fullPath)) {
            analyzeFileForCriticalIssues(fullPath, relativePath);
        }
    });
}

function analyzeFileForCriticalIssues(filePath, relativePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Check for actual performance problems
    checkForStateObjectIssues(content, relativePath);
    checkForListPerformanceIssues(content, relativePath);
    checkForImageLoadingIssues(content, relativePath);
    checkForDatabaseQueryIssues(content, relativePath);
    checkForMemoryLeakRisks(content, relativePath);
}

function checkForStateObjectIssues(content, filePath) {
    // Check for @State with ObservableObject (actual issue)
    const stateObjectPattern = /@State\s+.*:\s*\w*ViewModel/g;
    const matches = content.match(stateObjectPattern);
    
    if (matches) {
        matches.forEach(match => {
            performanceIssues.critical.push({
                file: filePath,
                type: 'State Management',
                issue: '@State used with ObservableObject instead of @StateObject',
                impact: 'Causes view recreation and memory leaks',
                fix: 'Replace @State with @StateObject for ObservableObject properties'
            });
        });
    }
}

function checkForListPerformanceIssues(content, filePath) {
    // Check for ForEach without lazy loading in large lists
    if (filePath.includes('SearchView.swift') || filePath.includes('DashboardView.swift')) {
        const hasForEach = content.includes('ForEach');
        const usesLazyStack = content.includes('LazyVStack');
        const limitedCardStack =
            filePath.includes('SearchView.swift') &&
            (content.includes('currentIndex + 3') || content.includes('Show up to 3 cards'));

        if (hasForEach && !usesLazyStack && !limitedCardStack) {
            performanceIssues.high.push({
                file: filePath,
                type: 'List Performance',
                issue: 'Large list using ForEach without LazyVStack',
                impact: 'Poor scrolling performance with many items',
                fix: 'Replace VStack with LazyVStack for large lists'
            });
        }
    }
    
    // Check for missing view identification in ForEach
    const forEachPattern = /ForEach\([^)]*\)\s*\{[^}]*\}/g;
    const forEachMatches = content.match(forEachPattern);
    
    if (forEachMatches) {
        forEachMatches.forEach(match => {
            if (!match.includes('.id(') && !match.includes('id: \\')) {
                performanceIssues.high.push({
                    file: filePath,
                    type: 'List Performance',
                    issue: 'ForEach without proper view identification',
                    impact: 'Poor list performance and unnecessary re-renders',
                    fix: 'Add .id() modifier or use id: parameter in ForEach'
                });
            }
        });
    }
}

function checkForImageLoadingIssues(content, filePath) {
    if (filePath.includes('AsyncImageView.swift')) {
        // Check for caching implementation
        const hasDedicatedCacheComponent = fs.existsSync(CACHED_ASYNC_IMAGE_PATH);

        if (!hasDedicatedCacheComponent && !content.includes('cache') && !content.includes('NSCache')) {
            performanceIssues.high.push({
                file: filePath,
                type: 'Image Loading',
                issue: 'Async image loading without caching strategy',
                impact: 'Repeated downloads and poor performance',
                fix: 'Implement image caching with memory limits'
            });
        }
        
        // Check for image resizing
        if (!content.includes('.resizable()') && !content.includes('thumbnail')) {
            performanceIssues.medium.push({
                file: filePath,
                type: 'Image Loading',
                issue: 'Images loaded without proper resizing',
                impact: 'High memory usage and slow loading',
                fix: 'Implement image resizing and compression'
            });
        }
    }
}

function checkForDatabaseQueryIssues(content, filePath) {
    if (filePath.includes('ProfileSearchRepository.swift')) {
        // Check for multiple collection queries
        const collectionQueries = (content.match(/collection\(/g) || []).length;
        if (collectionQueries > 2) {
            performanceIssues.high.push({
                file: filePath,
                type: 'Database Query',
                issue: `Multiple collection queries (${collectionQueries}) in single operation`,
                impact: 'Slow query performance and increased cost',
                fix: 'Optimize queries or implement caching'
            });
        }
        
        // Check for pagination implementation
        if (content.includes('.limit(') && !content.includes('startAfter')) {
            performanceIssues.medium.push({
                file: filePath,
                type: 'Database Query',
                issue: 'Query with limit but no pagination strategy',
                impact: 'Poor performance with large datasets',
                fix: 'Implement proper pagination with startAfter cursor'
            });
        }
    }
}

function checkForMemoryLeakRisks(content, filePath) {
    // Check for closures without weak self
    const closurePattern = /\{[^}]*self\./g;
    const closureMatches = content.match(closurePattern);
    
    if (closureMatches) {
        closureMatches.forEach(match => {
            if (!content.includes('[weak self]') && content.includes('completion:')) {
                performanceIssues.high.push({
                    file: filePath,
                    type: 'Memory Management',
                    issue: 'Closure using self without weak reference',
                    impact: 'Potential retain cycles and memory leaks',
                    fix: 'Use [weak self] in closures that reference self'
                });
            }
        });
    }
    
    // Check for strong delegate references
    if (content.includes('delegate') && !content.includes('weak var')) {
        performanceIssues.critical.push({
            file: filePath,
            type: 'Memory Management',
            issue: 'Strong delegate reference detected',
            impact: 'Memory leaks and retain cycles',
            fix: 'Use weak var for delegate properties'
        });
    }
}

function analyzeViewComplexity() {
    console.log('🎨 Analyzing View Complexity...\n');
    
    const viewFiles = findSwiftFiles();
    
    viewFiles.forEach(filePath => {
        const content = fs.readFileSync(filePath, 'utf8');
        const relativePath = path.relative(PROJECT_ROOT, filePath);
        
        // Check for deeply nested views
        const openBraces = (content.match(/\{/g) || []).length;
        const closeBraces = (content.match(/\}/g) || []).length;
        const nestingLevel = Math.abs(openBraces - closeBraces);
        
        if (nestingLevel > 15) {
            performanceIssues.medium.push({
                file: relativePath,
                type: 'View Complexity',
                issue: `Deeply nested view hierarchy (${nestingLevel} levels)`,
                impact: 'Slow view rendering and difficult maintenance',
                fix: 'Extract complex views into separate components'
            });
        }
        
        // Check for excessive container views
        const vstackCount = (content.match(/VStack/g) || []).length;
        const hstackCount = (content.match(/HStack/g) || []).length;
        const totalContainers = vstackCount + hstackCount;
        
        if (totalContainers > 20) {
            performanceIssues.low.push({
                file: relativePath,
                type: 'View Complexity',
                issue: `Excessive container views (VStack: ${vstackCount}, HStack: ${hstackCount})`,
                impact: 'Unnecessary view overhead',
                fix: 'Simplify view hierarchy and remove redundant containers'
            });
        }
    });
}

function analyzeAnimationPerformance() {
    console.log('🎬 Analyzing Animation Performance...\n');
    
    const viewFiles = findSwiftFiles();
    
    viewFiles.forEach(filePath => {
        const content = fs.readFileSync(filePath, 'utf8');
        const relativePath = path.relative(PROJECT_ROOT, filePath);
        
        // Check for expensive animations
        const animationCount = (content.match(/\.animation\(/g) || []).length;
        
        if (animationCount > 5) {
            performanceIssues.medium.push({
                file: relativePath,
                type: 'Animation Performance',
                issue: `Too many animations (${animationCount}) in single view`,
                impact: 'Performance degradation during complex animations',
                fix: 'Reduce animation count or use simpler animation curves'
            });
        }
        
        // Check for simultaneous animations on state changes
        if (content.includes('@State') && animationCount > 3) {
            performanceIssues.low.push({
                file: relativePath,
                type: 'Animation Performance',
                issue: 'Multiple animations on @State properties',
                impact: 'Unnecessary view re-renders during animations',
                fix: 'Use withAnimation wrapper for specific state changes'
            });
        }
    });
}

function findSwiftFiles() {
    const swiftFiles = [];
    
    function walkDir(dir) {
        try {
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
        } catch (error) {
            // Skip directories that can't be read
        }
    }
    
    walkDir(SOURCES_DIR);
    return swiftFiles;
}

function generateOptimizationRecommendations() {
    console.log('💡 Generating Optimization Recommendations...\n');
    
    const recommendations = {
        immediate: [],
        shortTerm: [],
        longTerm: []
    };
    
    // Immediate fixes (Critical issues)
    if (performanceIssues.critical.length > 0) {
        recommendations.immediate.push('Replace @State with @StateObject for all ObservableObject properties');
        recommendations.immediate.push('Use weak var for all delegate properties to prevent memory leaks');
        recommendations.immediate.push('Add proper view identification (.id()) to all ForEach loops');
    }
    
    // Short-term fixes (High priority issues)
    if (performanceIssues.high.length > 0) {
        recommendations.shortTerm.push('Implement LazyVStack for large lists to improve scrolling performance');
        recommendations.shortTerm.push('Add image caching strategy to AsyncImageView component');
        recommendations.shortTerm.push('Use [weak self] in closures that reference self to prevent retain cycles');
        recommendations.shortTerm.push('Optimize database queries to reduce multiple collection calls');
    }
    
    // Long-term improvements (Medium/Low priority issues)
    if (performanceIssues.medium.length > 0 || performanceIssues.low.length > 0) {
        recommendations.longTerm.push('Implement proper pagination for all database queries');
        recommendations.longTerm.push('Extract complex views into separate reusable components');
        recommendations.longTerm.push('Implement image resizing and compression for better performance');
        recommendations.longTerm.push('Optimize animations to reduce performance impact');
        recommendations.longTerm.push('Add performance monitoring with Firebase Performance Monitoring');
    }
    
    return recommendations;
}

function generateReport() {
    console.log('📊 GENERATING FOCUSED PERFORMANCE REPORT\n');
    console.log('=' .repeat(70));
    
    const totalIssues = performanceIssues.critical.length + 
                       performanceIssues.high.length + 
                       performanceIssues.medium.length + 
                       performanceIssues.low.length;
    
    console.log(`\n📈 PERFORMANCE ISSUES SUMMARY`);
    console.log('-'.repeat(40));
    console.log(`🔥 Critical: ${performanceIssues.critical.length}`);
    console.log(`⚠️  High: ${performanceIssues.high.length}`);
    console.log(`📝 Medium: ${performanceIssues.medium.length}`);
    console.log(`💡 Low: ${performanceIssues.low.length}`);
    console.log(`📊 Total: ${totalIssues}`);
    
    // Calculate performance score
    const criticalWeight = performanceIssues.critical.length * 25;
    const highWeight = performanceIssues.high.length * 15;
    const mediumWeight = performanceIssues.medium.length * 8;
    const lowWeight = performanceIssues.low.length * 3;
    
    const totalWeight = criticalWeight + highWeight + mediumWeight + lowWeight;
    const score = Math.max(0, 100 - totalWeight);
    
    let grade = 'A';
    if (score < 60) grade = 'F';
    else if (score < 70) grade = 'D';
    else if (score < 80) grade = 'C';
    else if (score < 90) grade = 'B';
    
    console.log(`\n🎯 OVERALL PERFORMANCE SCORE: ${score}/100 (${grade})`);
    
    // Show critical issues
    if (performanceIssues.critical.length > 0) {
        console.log('\n🔥 CRITICAL ISSUES (Fix Immediately)');
        console.log('-'.repeat(50));
        performanceIssues.critical.slice(0, 5).forEach(issue => {
            console.log(`\n❌ ${issue.issue}`);
            console.log(`   File: ${issue.file}`);
            console.log(`   Impact: ${issue.impact}`);
            console.log(`   Fix: ${issue.fix}`);
        });
    }
    
    // Show high priority issues
    if (performanceIssues.high.length > 0) {
        console.log('\n⚠️ HIGH PRIORITY ISSUES');
        console.log('-'.repeat(40));
        performanceIssues.high.slice(0, 5).forEach(issue => {
            console.log(`\n⚠️ ${issue.issue}`);
            console.log(`   File: ${issue.file}`);
            console.log(`   Fix: ${issue.fix}`);
        });
    }
    
    // Show recommendations
    const recommendations = generateOptimizationRecommendations();
    
    console.log('\n🚀 OPTIMIZATION RECOMMENDATIONS');
    console.log('=' .repeat(50));
    
    if (recommendations.immediate.length > 0) {
        console.log('\n🔥 IMMEDIATE FIXES (Critical)');
        recommendations.immediate.forEach((rec, index) => {
            console.log(`   ${index + 1}. ${rec}`);
        });
    }
    
    if (recommendations.shortTerm.length > 0) {
        console.log('\n⚡ SHORT-TERM IMPROVEMENTS (High Priority)');
        recommendations.shortTerm.forEach((rec, index) => {
            console.log(`   ${index + 1}. ${rec}`);
        });
    }
    
    if (recommendations.longTerm.length > 0) {
        console.log('\n🎯 LONG-TERM OPTIMIZATIONS');
        recommendations.longTerm.forEach((rec, index) => {
            console.log(`   ${index + 1}. ${rec}`);
        });
    }
    
    // Generate detailed report
    const reportData = {
        timestamp: new Date().toISOString(),
        score,
        grade,
        totalIssues,
        issues: performanceIssues,
        recommendations
    };
    
    const reportPath = path.join(__dirname, 'focused_performance_report.json');
    fs.writeFileSync(reportPath, JSON.stringify(reportData, null, 2));
    
    console.log(`\n📄 Detailed report saved to: ${reportPath}`);
    
    return reportData;
}

// Main execution
async function main() {
    console.log('🚀 STARTING FOCUSED PERFORMANCE ANALYSIS\n');
    console.log('=' .repeat(70));
    
    try {
        analyzeCriticalPerformanceIssues();
        analyzeViewComplexity();
        analyzeAnimationPerformance();
        
        const report = generateReport();
        
        console.log('\n✅ Focused Performance Analysis Complete!');
        console.log(`📊 Overall Score: ${report.score}/100 (${report.grade})`);
        console.log(`🔍 Total Issues: ${report.totalIssues}`);
        
        // Exit with appropriate code based on critical issues
        if (performanceIssues.critical.length > 0) {
            console.log('\n⚠️ Critical performance issues found - immediate attention required');
            process.exit(1);
        } else if (performanceIssues.high.length > 5) {
            console.log('\n⚡ High priority issues found - should be addressed soon');
            process.exit(0);
        } else {
            console.log('\n🎉 Performance is generally good - minor optimizations available');
            process.exit(0);
        }
        
    } catch (error) {
        console.error('❌ Analysis failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { main, performanceIssues };
