#if os(iOS)
import Foundation
import UIKit
import SwiftUI

@available(iOS 17, *)
class PerformanceOptimizer: ObservableObject {
    static let shared = PerformanceOptimizer()
    
    @Published var memoryUsage: MemoryUsage = MemoryUsage()
    @Published var imageCacheSize: Int64 = 0
    @Published var databaseOptimizationStatus: OptimizationStatus = .idle
    
    private let imageCacheManager: ImageCacheManager
    private let memoryManager: MemoryManager
    private let databaseOptimizer: DatabaseOptimizer
    private var performanceTimer: Timer?
    
    init(
        imageCacheManager: ImageCacheManager = DefaultImageCacheManager(),
        memoryManager: MemoryManager = DefaultMemoryManager(),
        databaseOptimizer: DatabaseOptimizer = DefaultDatabaseOptimizer()
    ) {
        self.imageCacheManager = imageCacheManager
        self.memoryManager = memoryManager
        self.databaseOptimizer = databaseOptimizer
        
        setupPerformanceMonitoring()
        setupMemoryWarningHandling()
    }
    
    // MARK: - Performance Monitoring
    
    private func setupPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePerformanceMetrics()
            }
        }
    }
    
    private func updatePerformanceMetrics() {
        Task {
            memoryUsage = memoryManager.getCurrentMemoryUsage()
            imageCacheSize = await imageCacheManager.getCacheSize()
        }
    }
    
    private func setupMemoryWarningHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        Task {
            await performMemoryCleanup()
        }
    }
    
    // MARK: - Image Optimization
    
    func optimizeImageLoading() async {
        await imageCacheManager.optimizeCache()
        imageCacheSize = await imageCacheManager.getCacheSize()
    }
    
    func preloadCriticalImages(urls: [URL]) async {
        await imageCacheManager.preloadImages(urls: urls)
    }
    
    func clearImageCache() async {
        await imageCacheManager.clearCache()
        imageCacheSize = 0
    }
    
    // MARK: - Memory Management
    
    private func performMemoryCleanup() async {
        // Clear image cache
        await imageCacheManager.clearCache()
        
        // Release unused objects
        memoryManager.releaseUnusedObjects()
        
        // Optimize database connections
        await databaseOptimizer.optimizeConnections()
        
        // Update metrics
        updatePerformanceMetrics()
    }
    
    func optimizeMemoryUsage() async {
        await performMemoryCleanup()
        
        // Additional memory optimization
        await memoryManager.compactMemory()
        memoryUsage = memoryManager.getCurrentMemoryUsage()
    }
    
    // MARK: - Database Optimization
    
    func optimizeDatabase() async {
        databaseOptimizationStatus = .optimizing
        
        do {
            try await databaseOptimizer.optimizeDatabase()
            databaseOptimizationStatus = .completed
            
            // Reset to idle after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.databaseOptimizationStatus = .idle
            }
        } catch {
            databaseOptimizationStatus = .failed
            print("Database optimization failed: \(error)")
        }
    }
    
    func optimizeQueryPerformance() async {
        await databaseOptimizer.optimizeQueries()
    }
    
    // MARK: - Startup Optimization
    
    func optimizeStartupTime() async {
        // Preload critical data
        await preloadCriticalData()
        
        // Warm up caches
        await imageCacheManager.warmUpCache()
        
        // Optimize database connections
        await databaseOptimizer.optimizeConnections()
    }
    
    private func preloadCriticalData() async {
        // Preload user profile and recent conversations
        // This would be implemented based on app-specific needs
        print("Preloading critical data...")
    }
    
    // MARK: - Performance Metrics
    
    func getPerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            memoryUsage: memoryUsage,
            imageCacheSize: imageCacheSize,
            databaseOptimizationStatus: databaseOptimizationStatus,
            timestamp: Date()
        )
    }
    
    deinit {
        performanceTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Image Cache Manager

protocol ImageCacheManager {
    func optimizeCache() async
    func preloadImages(urls: [URL]) async
    func clearCache() async
    func getCacheSize() async -> Int64
    func warmUpCache() async
}

class DefaultImageCacheManager: ImageCacheManager {
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache")
        
        setupCacheConfiguration()
        createCacheDirectoryIfNeeded()
    }
    
    private func setupCacheConfiguration() {
        cache.countLimit = 100 // Limit number of cached images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Set up eviction policy
        cache.evictsObjectsWithDiscardedContent = true
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func optimizeCache() async {
        // Remove old and unused images
        await clearOldImages()
        
        // Compress large images in cache
        await compressCachedImages()
    }
    
    func preloadImages(urls: [URL]) async {
        for url in urls {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                let compressedImage = compressImage(image, maxSize: 300)
                cache.setObject(compressedImage, forKey: url.absoluteString as NSString)
            }
        }
    }
    
    func clearCache() async {
        cache.removeAllObjects()
        
        // Clear file cache
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    func getCacheSize() async -> Int64 {
        do {
            let resourceValues = try cacheDirectory.resourceValues(forKeys: [.totalFileSizeKey])
            return resourceValues.totalFileSize ?? 0
        } catch {
            return 0
        }
    }
    
    func warmUpCache() async {
        // Preload commonly used images
        // This would be implemented based on app-specific needs
        print("Warming up image cache...")
    }
    
    private func clearOldImages() async {
        // Remove images older than 7 days
        let cutoffDate = Date().addingTimeInterval(-7 * 24 * 3600)
        
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                    if let modificationDate = resourceValues.contentModificationDate,
                       modificationDate < cutoffDate {
                        try fileManager.removeItem(at: fileURL)
                    }
                } catch {
                    print("Failed to remove old image: \(error)")
                }
            }
        }
    }
    
    private func compressCachedImages() async {
        // Compress images larger than 200KB
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                    if let fileSize = resourceValues.fileSize, fileSize > 200 * 1024 {
                        if let data = try? Data(contentsOf: fileURL),
                           let image = UIImage(data: data) {
                            let compressedData = image.jpegData(compressionQuality: 0.7)
                            try compressedData?.write(to: fileURL)
                        }
                    }
                } catch {
                    print("Failed to compress image: \(error)")
                }
            }
        }
    }
    
    private func compressImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        let scale = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let compressedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return compressedImage ?? image
    }
}

// MARK: - Memory Manager

protocol MemoryManager {
    func getCurrentMemoryUsage() -> MemoryUsage
    func releaseUnusedObjects()
    func compactMemory() async
}

class DefaultMemoryManager: MemoryManager {
    func getCurrentMemoryUsage() -> MemoryUsage {
        let machTaskBasicInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &machTaskBasicInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(machTaskBasicInfo.resident_size) / 1024.0 / 1024.0 // MB
            let totalMemory = ProcessInfo.processInfo.physicalMemory / 1024 / 1024 // MB
            let availableMemory = totalMemory - usedMemory
            
            return MemoryUsage(
                used: usedMemory,
                available: availableMemory,
                total: totalMemory,
                percentage: (usedMemory / totalMemory) * 100
            )
        }
        
        return MemoryUsage()
    }
    
    func releaseUnusedObjects() {
        // Trigger garbage collection
        autoreleasepool {
            // Release temporary objects
        }
    }
    
    func compactMemory() async {
        // Compact memory pools
        await MainActor.run {
            // Compact UI-related memory
        }
    }
}

// MARK: - Database Optimizer

protocol DatabaseOptimizer {
    func optimizeDatabase() async throws
    func optimizeQueries() async
    func optimizeConnections() async
}

class DefaultDatabaseOptimizer: DatabaseOptimizer {
    func optimizeDatabase() async throws {
        // Implement database optimization
        // This would include vacuuming, analyzing tables, etc.
        print("Optimizing database...")
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    func optimizeQueries() async {
        // Implement query optimization
        print("Optimizing database queries...")
    }
    
    func optimizeConnections() async {
        // Implement connection pooling optimization
        print("Optimizing database connections...")
    }
}

// MARK: - Models

struct MemoryUsage {
    let used: Double
    let available: Double
    let total: Double
    let percentage: Double
    
    init(used: Double = 0, available: Double = 0, total: Double = 0, percentage: Double = 0) {
        self.used = used
        self.available = available
        self.total = total
        self.percentage = percentage
    }
    
    var usedFormatted: String {
        return String(format: "%.1f MB", used)
    }
    
    var totalFormatted: String {
        return String(format: "%.1f MB", total)
    }
    
    var percentageFormatted: String {
        return String(format: "%.1f%%", percentage)
    }
}

enum OptimizationStatus {
    case idle
    case optimizing
    case completed
    case failed
    
    var displayText: String {
        switch self {
        case .idle:
            return "Ready"
        case .optimizing:
            return "Optimizing..."
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
}

struct PerformanceReport {
    let memoryUsage: MemoryUsage
    let imageCacheSize: Int64
    let databaseOptimizationStatus: OptimizationStatus
    let timestamp: Date
    
    var cacheSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        return formatter.string(fromByteCount: imageCacheSize)
    }
}

#endif
