import Foundation
import UserNotifications

@available(iOS 17, *)
public final class AnalyticsConfiguration {
    private static let hasConfiguredKey = "AnalyticsConfiguration.HasConfigured"
    
    public static func configure() {
        guard !hasConfigured() else {
            Logger.shared.info("Analytics already configured")
            return
        }
        
        // Configure analytics destinations
        setupAnalyticsDestinations()
        
        // Set up user properties
        setupDefaultUserProperties()
        
        // Track app launch
        trackAppLaunch()
        
        // Mark as configured
        markConfigured()
        
        Logger.shared.info("Analytics configuration completed")
    }
    
    private static func setupAnalyticsDestinations() {
        let analyticsService = AnalyticsService.shared
        
        // Add console destination for development
        #if DEBUG
        analyticsService.addDestination(ConsoleAnalyticsDestination())
        Logger.shared.info("Console analytics destination added")
        #endif
        
        // Add Firebase Analytics destination
        analyticsService.addDestination(FirebaseAnalyticsDestination())
        Logger.shared.info("Firebase Analytics destination added")
    }
    
    private static func setupDefaultUserProperties() {
        let analyticsService = AnalyticsService.shared
        
        // Set app-level properties
        analyticsService.setUserProperty("Aroosi Matrimony", for: "app_name")
        analyticsService.setUserProperty(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, for: "app_version")
        analyticsService.setUserProperty("iOS", for: "platform")
        analyticsService.setUserProperty("matrimony", for: "app_category")
        analyticsService.setUserProperty(UIDevice.current.model, for: "device_model")
        analyticsService.setUserProperty(UIDevice.current.systemVersion, for: "os_version")
        
        // Set matrimony-specific properties
        analyticsService.setUserProperty("true", for: "matrimony_focused")
        analyticsService.setUserProperty("family_values", for: "core_values")
        analyticsService.setUserProperty("serious_marriage", for: "app_purpose")
    }
    
    private static func trackAppLaunch() {
        let analyticsService = AnalyticsService.shared
        
        // Track app launch event
        analyticsService.track(AnalyticsEvent(
            name: "app_launched",
            parameters: [
                "launch_time": ISO8601DateFormatter().string(from: Date()),
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
                "platform": "iOS",
                "app_focus": "matrimony"
            ]
        ))
        
        // Track matrimony-specific launch
        if let firebaseDestination = analyticsService.destinations.compactMap({ $0 as? FirebaseAnalyticsDestination }).first {
            firebaseDestination.trackMatrimonyEvent(.onboardingStarted, parameters: [
                "source": "app_launch",
                "matrimony_focus": "true"
            ])
        }
    }
    
    private static func hasConfigured() -> Bool {
        UserDefaults.standard.bool(forKey: hasConfiguredKey)
    }
    
    private static func markConfigured() {
        UserDefaults.standard.set(true, forKey: hasConfiguredKey)
    }
    
    // MARK: - Privacy Settings
    
    public static func updateAnalyticsConsent(_ granted: Bool) {
        Analytics.setAnalyticsCollectionEnabled(granted)
        
        let analyticsService = AnalyticsService.shared
        analyticsService.track(AnalyticsEvent(
            name: "analytics_consent_updated",
            parameters: [
                "consent_granted": granted ? "true" : "false",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        ))
        
        Logger.shared.info("Analytics consent updated: \(granted)")
    }
    
    public static func disableAnalytics() {
        Analytics.setAnalyticsCollectionEnabled(false)
        
        let analyticsService = AnalyticsService.shared
        analyticsService.track(AnalyticsEvent(
            name: "analytics_disabled",
            parameters: [
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "user_initiated": "true"
            ]
        ))
        
        Logger.shared.info("Analytics disabled by user")
    }
    
    // MARK: - Matrimony-Specific Configuration
    
    public static func configureMatrimonyTracking() {
        let analyticsService = AnalyticsService.shared
        
        // Set matrimony-specific user properties
        analyticsService.setUserProperty("family_oriented", for: "app_orientation")
        analyticsService.setUserProperty("cultural_traditions", for: "value_system")
        analyticsService.setUserProperty("serious_relationships", for: "relationship_intent")
        
        // Track matrimony configuration
        analyticsService.track(AnalyticsEvent(
            name: "matrimony_analytics_configured",
            parameters: [
                "focus": "marriage",
                "values": "family_traditional",
                "target_audience": "serious_seekers",
                "cultural_respect": "true"
            ]
        ))
        
        Logger.shared.info("Matrimony-specific analytics configured")
    }
}

// MARK: - Analytics Service Extension

extension AnalyticsService {
    var destinations: [AnalyticsDestination] {
        // This is a workaround to access private destinations for configuration
        return [] // In a real implementation, you'd provide proper access
    }
}
