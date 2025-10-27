#if os(iOS)
import Foundation
import UIKit

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

@available(iOS 17, *)
class CrashReportingService: ObservableObject {
    static let shared = CrashReportingService()
    
    @Published var isReportingEnabled = true
    @Published var crashCount: Int = 0
    @Published var lastCrashDate: Date?
    
    private let crashReporter: CrashReporter
    private let analyticsService: AnalyticsService
    
    init(
        crashReporter: CrashReporter = DefaultCrashReporter(),
        analyticsService: AnalyticsService = DefaultAnalyticsService()
    ) {
        self.crashReporter = crashReporter
        self.analyticsService = analyticsService
        
        setupCrashReporting()
        loadCrashStatistics()
    }
    
    // MARK: - Setup
    
    private func setupCrashReporting() {
        crashReporter.setup { [weak self] crashReport in
            Task { @MainActor in
                await self?.handleCrashReport(crashReport)
            }
        }
    }
    
    private func loadCrashStatistics() {
        crashCount = crashReporter.getCrashCount()
        lastCrashDate = crashReporter.getLastCrashDate()
    }
    
    // MARK: - Crash Handling
    
    private func handleCrashReport(_ crashReport: CrashReport) async {
        do {
            // Send crash report to server
            try await sendCrashReport(crashReport)
            
            // Update local statistics
            crashCount += 1
            lastCrashDate = Date()
            saveCrashStatistics()
            
            // Track crash in analytics
            await analyticsService.trackCrash(crashReport)
            
        } catch {
            print("Failed to send crash report: \(error)")
        }
    }
    
    private func sendCrashReport(_ crashReport: CrashReport) async throws {
        #if canImport(FirebaseCrashlytics)
        let crashlytics = Crashlytics.crashlytics()
        
        // Set custom keys for additional context
        crashlytics.setCustomValue(crashReport.errorType, forKey: "error_type")
        crashlytics.setCustomValue(crashReport.stackTrace, forKey: "stack_trace")
        crashlytics.setCustomValue(crashReport.deviceInfo.model, forKey: "device_model")
        crashlytics.setCustomValue(crashReport.deviceInfo.osVersion, forKey: "os_version")
        crashlytics.setCustomValue(crashReport.appVersion, forKey: "app_version")
        crashlytics.setCustomValue(crashReport.timestamp.timeIntervalSince1970, forKey: "crash_timestamp")
        
        // Log the crash with Crashlytics
        crashlytics.log("Crash reported: \(crashReport.errorType)")
        
        // Record error with Crashlytics
        let error = NSError(
            domain: "AroosiMatrimony",
            code: crashReport.errorCode,
            userInfo: [
                NSLocalizedDescriptionKey: crashReport.errorType,
                "stackTrace": crashReport.stackTrace,
                "deviceInfo": crashReport.deviceInfo.description,
                "appVersion": crashReport.appVersion,
                "timestamp": crashReport.timestamp
            ]
        )
        
        crashlytics.record(error: error)
        
        Logger.shared.info("Crash report sent to Firebase Crashlytics")
        
        #else
        // Fallback implementation when Crashlytics is not available
        Logger.shared.info("Crashlytics not available - using fallback logging")
        print("Sending crash report: \(crashReport.description)")
        
        // Simulate network request
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        #endif
    }
    
    private func saveCrashStatistics() {
        UserDefaults.standard.set(crashCount, forKey: "CrashCount")
        UserDefaults.standard.set(lastCrashDate, forKey: "LastCrashDate")
    }
    
    // MARK: - Manual Reporting
    
    func reportError(_ error: Error, context: [String: Any] = [:]) async {
        let errorReport = ErrorReport(
            error: error,
            context: context,
            timestamp: Date(),
            appVersion: getAppVersion(),
            deviceInfo: getDeviceInfo()
        )
        
        do {
            try await sendErrorReport(errorReport)
            await analyticsService.trackError(errorReport)
        } catch {
            print("Failed to send error report: \(error)")
        }
    }
    
    func reportCustomEvent(_ event: String, properties: [String: Any] = [:]) async {
        let customReport = CustomReport(
            event: event,
            properties: properties,
            timestamp: Date(),
            appVersion: getAppVersion(),
            deviceInfo: getDeviceInfo()
        )
        
        do {
            try await sendCustomReport(customReport)
            await analyticsService.trackCustomEvent(customReport)
        } catch {
            print("Failed to send custom report: \(error)")
        }
    }
    
    private func sendErrorReport(_ errorReport: ErrorReport) async throws {
        #if canImport(FirebaseCrashlytics)
        let crashlytics = Crashlytics.crashlytics()
        
        // Set custom keys for additional context
        for (key, value) in errorReport.context {
            crashlytics.setCustomValue("\(value)", forKey: key)
        }
        
        crashlytics.setCustomValue(errorReport.timestamp.timeIntervalSince1970, forKey: "error_timestamp")
        crashlytics.setCustomValue(errorReport.appVersion, forKey: "app_version")
        crashlytics.setCustomValue(errorReport.deviceInfo.model, forKey: "device_model")
        crashlytics.setCustomValue(errorReport.deviceInfo.osVersion, forKey: "os_version")
        
        // Log the error with Crashlytics
        crashlytics.log("Error reported: \(errorReport.error.localizedDescription)")
        
        // Record error with Crashlytics
        let nsError = NSError(
            domain: "AroosiMatrimony.Error",
            code: -1,
            userInfo: [
                NSLocalizedDescriptionKey: errorReport.error.localizedDescription,
                "context": errorReport.context,
                "timestamp": errorReport.timestamp,
                "appVersion": errorReport.appVersion,
                "deviceInfo": errorReport.deviceInfo.description
            ]
        )
        
        crashlytics.record(error: nsError)
        
        Logger.shared.info("Error report sent to Firebase Crashlytics")
        
        #else
        // Fallback implementation when Crashlytics is not available
        Logger.shared.info("Crashlytics not available - using fallback error logging")
        print("Sending error report: \(errorReport.error.localizedDescription)")
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        #endif
    }
    
    private func sendCustomReport(_ customReport: CustomReport) async throws {
        #if canImport(FirebaseCrashlytics)
        let crashlytics = Crashlytics.crashlytics()
        
        // Set custom keys for additional context
        for (key, value) in customReport.properties {
            crashlytics.setCustomValue("\(value)", forKey: key)
        }
        
        crashlytics.setCustomValue(customReport.timestamp.timeIntervalSince1970, forKey: "custom_event_timestamp")
        crashlytics.setCustomValue(customReport.appVersion, forKey: "app_version")
        
        // Log the custom event with Crashlytics
        crashlytics.log("Custom event: \(customReport.event)")
        
        // Record as non-fatal error for tracking
        let customError = NSError(
            domain: "AroosiMatrimony.CustomEvent",
            code: -2,
            userInfo: [
                NSLocalizedDescriptionKey: "Custom Event: \(customReport.event)",
                "properties": customReport.properties,
                "timestamp": customReport.timestamp,
                "appVersion": customReport.appVersion
            ]
        )
        
        crashlytics.record(error: customError)
        
        Logger.shared.info("Custom event sent to Firebase Crashlytics: \(customReport.event)")
        
        #else
        // Fallback implementation when Crashlytics is not available
        Logger.shared.info("Crashlytics not available - using fallback custom event logging")
        print("Sending custom report: \(customReport.event)")
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second
        #endif
    }
    
    // MARK: - User Feedback
    
    func reportUserFeedback(_ feedback: UserFeedback) async {
        do {
            try await sendUserFeedback(feedback)
            await analyticsService.trackUserFeedback(feedback)
        } catch {
            print("Failed to send user feedback: \(error)")
        }
    }
    
    private func sendUserFeedback(_ feedback: UserFeedback) async throws {
        // Mock implementation
        print("Sending user feedback: \(feedback.type)")
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
    }
    
    // MARK: - Settings
    
    func setReportingEnabled(_ enabled: Bool) {
        isReportingEnabled = enabled
        crashReporter.setEnabled(enabled)
        UserDefaults.standard.set(enabled, forKey: "CrashReportingEnabled")
    }
    
    func clearCrashData() {
        crashReporter.clearCrashData()
        crashCount = 0
        lastCrashDate = nil
        saveCrashStatistics()
    }
    
    // MARK: - Utilities
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func getDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        return DeviceInfo(
            model: device.model,
            systemVersion: device.systemVersion,
            name: device.name,
            identifierForVendor: device.identifierForVendor?.uuidString
        )
    }
    
    // MARK: - Performance Monitoring
    
    func startPerformanceMonitoring() {
        crashReporter.startPerformanceMonitoring { [weak self] metrics in
            Task { @MainActor in
                await self?.handlePerformanceMetrics(metrics)
            }
        }
    }
    
    private func handlePerformanceMetrics(_ metrics: PerformanceMetrics) async {
        // Report performance issues
        if metrics.memoryUsage > 80 {
            await reportError(
                CrashReportingError.highMemoryUsage,
                context: ["memoryUsage": metrics.memoryUsage]
            )
        }
        
        if metrics.cpuUsage > 90 {
            await reportError(
                CrashReportingError.highCPUUsage,
                context: ["cpuUsage": metrics.cpuUsage]
            )
        }
        
        await analyticsService.trackPerformance(metrics)
    }
}

// MARK: - Crash Reporter Protocol

protocol CrashReporter {
    func setup(onCrash: @escaping (CrashReport) -> Void)
    func getCrashCount() -> Int
    func getLastCrashDate() -> Date?
    func setEnabled(_ enabled: Bool)
    func clearCrashData()
    func startPerformanceMonitoring(onMetrics: @escaping (PerformanceMetrics) -> Void)
}

// MARK: - Default Crash Reporter

class DefaultCrashReporter: CrashReporter {
    private var onCrashCallback: ((CrashReport) -> Void)?
    private var onMetricsCallback: ((PerformanceMetrics) -> Void)?
    private var performanceTimer: Timer?
    
    func setup(onCrash: @escaping (CrashReport) -> Void) {
        onCrashCallback = onCrash
        
        // Set up crash handler
        NSSetUncaughtExceptionHandler { exception in
            let crashReport = CrashReport(
                exception: exception,
                timestamp: Date(),
                stackTrace: Thread.callStackSymbols
            )
            
            onCrash(crashReport)
        }
        
        // Set up signal handlers for fatal signals
        setupSignalHandlers()
    }
    
    private func setupSignalHandlers() {
        let signals: [Int32] = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE]
        
        for signal in signals {
            signal(signal) { _ in
                let crashReport = CrashReport(
                    exception: nil,
                    timestamp: Date(),
                    stackTrace: Thread.callStackSymbols,
                    signal: signal
                )
                
                self.onCrashCallback?(crashReport)
            }
        }
    }
    
    func getCrashCount() -> Int {
        return UserDefaults.standard.integer(forKey: "CrashCount")
    }
    
    func getLastCrashDate() -> Date? {
        return UserDefaults.standard.object(forKey: "LastCrashDate") as? Date
    }
    
    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "CrashReportingEnabled")
    }
    
    func clearCrashData() {
        UserDefaults.standard.removeObject(forKey: "CrashCount")
        UserDefaults.standard.removeObject(forKey: "LastCrashDate")
    }
    
    func startPerformanceMonitoring(onMetrics: @escaping (PerformanceMetrics) -> Void) {
        onMetricsCallback = onMetrics
        
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            let metrics = self.collectPerformanceMetrics()
            onMetrics(metrics)
        }
    }
    
    private func collectPerformanceMetrics() -> PerformanceMetrics {
        let memoryUsage = getCurrentMemoryUsage()
        let cpuUsage = getCurrentCPUUsage()
        
        return PerformanceMetrics(
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            timestamp: Date()
        )
    }
    
    private func getCurrentMemoryUsage() -> Double {
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
            let usedMemory = Double(machTaskBasicInfo.resident_size)
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            return (usedMemory / totalMemory) * 100
        }
        
        return 0
    }
    
    private func getCurrentCPUUsage() -> Double {
        var info = processor_info_array_t(bitPattern: 0)
        var numCpuInfo = mach_msg_type_number_t(0)
        var numCpus = natural_t(0)
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &info, &numCpuInfo)
        
        if result == KERN_SUCCESS {
            let cpuLoadInfo = info!.bindMemory(to: processor_cpu_load_info.self, capacity: Int(numCpus))
            
            var totalTicks: UInt32 = 0
            var idleTicks: UInt32 = 0
            
            for i in 0..<Int(numCpus) {
                totalTicks += cpuLoadInfo[i].cpu_ticks.0 + cpuLoadInfo[i].cpu_ticks.1 + cpuLoadInfo[i].cpu_ticks.2 + cpuLoadInfo[i].cpu_ticks.3
                idleTicks += cpuLoadInfo[i].cpu_ticks.2
            }
            
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(numCpuInfo))
            
            return Double(totalTicks - idleTicks) / Double(totalTicks) * 100
        }
        
        return 0
    }
}

// MARK: - Analytics Service Protocol

protocol AnalyticsService {
    func trackCrash(_ crashReport: CrashReport) async
    func trackError(_ errorReport: ErrorReport) async
    func trackCustomEvent(_ customReport: CustomReport) async
    func trackUserFeedback(_ feedback: UserFeedback) async
    func trackPerformance(_ metrics: PerformanceMetrics) async
}

// MARK: - Default Analytics Service

class DefaultAnalyticsService: AnalyticsService {
    func trackCrash(_ crashReport: CrashReport) async {
        print("Tracking crash in analytics: \(crashReport.description)")
    }
    
    func trackError(_ errorReport: ErrorReport) async {
        print("Tracking error in analytics: \(errorReport.error.localizedDescription)")
    }
    
    func trackCustomEvent(_ customReport: CustomReport) async {
        print("Tracking custom event in analytics: \(customReport.event)")
    }
    
    func trackUserFeedback(_ feedback: UserFeedback) async {
        print("Tracking user feedback in analytics: \(feedback.type)")
    }
    
    func trackPerformance(_ metrics: PerformanceMetrics) async {
        print("Tracking performance metrics: Memory: \(metrics.memoryUsage)%, CPU: \(metrics.cpuUsage)%")
    }
}

// MARK: - Models

struct CrashReport {
    let exception: NSException?
    let timestamp: Date
    let stackTrace: [String]
    let signal: Int32?
    
    var description: String {
        if let exception = exception {
            return "Exception: \(exception.name) - \(exception.reason ?? "Unknown reason")"
        } else if let signal = signal {
            return "Signal: \(signal)"
        } else {
            return "Unknown crash"
        }
    }
}

struct ErrorReport {
    let error: Error
    let context: [String: Any]
    let timestamp: Date
    let appVersion: String
    let deviceInfo: DeviceInfo
}

struct CustomReport {
    let event: String
    let properties: [String: Any]
    let timestamp: Date
    let appVersion: String
    let deviceInfo: DeviceInfo
}

struct UserFeedback {
    let type: FeedbackType
    let rating: Int?
    let comment: String?
    let timestamp: Date
    let appVersion: String
    let deviceInfo: DeviceInfo
}

enum FeedbackType {
    case bugReport
    case featureRequest
    case generalFeedback
    case crashReport
}

struct PerformanceMetrics {
    let memoryUsage: Double
    let cpuUsage: Double
    let timestamp: Date
}

struct DeviceInfo {
    let model: String
    let systemVersion: String
    let name: String
    let identifierForVendor: String?
}

enum CrashReportingError: Error {
    case highMemoryUsage
    case highCPUUsage
    case reportingDisabled
    
    var localizedDescription: String {
        switch self {
        case .highMemoryUsage:
            return "High memory usage detected"
        case .highCPUUsage:
            return "High CPU usage detected"
        case .reportingDisabled:
            return "Crash reporting is disabled"
        }
    }
}

#endif
