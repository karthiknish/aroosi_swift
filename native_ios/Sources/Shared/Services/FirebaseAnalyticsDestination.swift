import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics

@available(iOS 17, *)
public final class FirebaseAnalyticsDestination: AnalyticsDestination {
    private let logger = Logger.shared
    
    public init() {
        logger.info("[FirebaseAnalytics] Destination initialized")
    }
    
    public func track(event: AnalyticsEvent) {
        var parameters: [String: Any] = [:]
        
        // Convert string parameters to Any type for Firebase
        for (key, value) in event.parameters {
            parameters[key] = value
        }
        
        // Add app-specific context
        parameters["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        parameters["app_build"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        parameters["platform"] = "iOS"
        parameters["app_name"] = "Aroosi Matrimony"
        
        Analytics.logEvent(event.name, parameters: parameters)
        logger.info("[FirebaseAnalytics] Event tracked: \(event.name) with \(parameters.count) parameters")
    }
    
    public func setUserID(_ userID: String?) {
        Analytics.setUserID(userID)
        logger.info("[FirebaseAnalytics] User ID set: \(userID ?? "nil")")
    }
    
    public func setUserProperty(_ value: String?, for key: String) {
        Analytics.setUserProperty(value, forName: key)
        logger.info("[FirebaseAnalytics] User property set: \(key) = \(value ?? "nil")")
    }
    
    // MARK: - Matrimony-Specific Methods
    
    public func trackMatrimonyEvent(_ eventName: MatrimonyAnalyticsEvent, parameters: [String: String] = [:]) {
        var eventParams = parameters
        eventParams["event_category"] = eventName.category
        eventParams["matrimony_focus"] = "true"
        
        let analyticsEvent = AnalyticsEvent(
            name: eventName.rawValue,
            parameters: eventParams
        )
        
        track(event: analyticsEvent)
    }
    
    public func setUserProfile(_ profile: MatrimonyUserProfile) {
        setUserID(profile.userID)
        setUserProperty(profile.age, for: "user_age")
        setUserProperty(profile.gender, for: "user_gender")
        setUserProperty(profile.religion, for: "user_religion")
        setUserProperty(profile.marriageIntention, for: "marriage_intention")
        setUserProperty(profile.location, for: "user_location")
        setUserProperty(profile.educationLevel, for: "education_level")
        
        logger.info("[FirebaseAnalytics] Matrimony profile set for user: \(profile.userID)")
    }
}

// MARK: - Matrimony-Specific Analytics

public enum MatrimonyAnalyticsEvent: String, CaseIterable {
    // Onboarding Events
    case onboardingStarted = "matrimony_onboarding_started"
    case onboardingStepCompleted = "matrimony_onboarding_step_completed"
    case onboardingCompleted = "matrimony_onboarding_completed"
    
    // Profile Events
    case profileCreated = "matrimony_profile_created"
    case profileUpdated = "matrimony_profile_updated"
    case profileViewed = "matrimony_profile_viewed"
    case photoUploaded = "matrimony_photo_uploaded"
    
    // Search & Matching Events
    case searchPerformed = "matrimony_search_performed"
    case profileLiked = "matrimony_profile_liked"
    case profileShortlisted = "matrimony_profile_shortlisted"
    case matchFound = "matrimony_match_found"
    
    // Communication Events
    case messageSent = "matrimony_message_sent"
    case messageReceived = "matrimony_message_received"
    case conversationStarted = "matrimony_conversation_started"
    
    // Family Approval Events
    case familyApprovalRequested = "matrimony_family_approval_requested"
    case familyApprovalGranted = "matrimony_family_approval_granted"
    case familyApprovalDenied = "matrimony_family_approval_denied"
    
    // Compatibility Events
    case compatibilityTestStarted = "matrimony_compatibility_test_started"
    case compatibilityTestCompleted = "matrimony_compatibility_test_completed"
    case compatibilityScoreViewed = "matrimony_compatibility_score_viewed"
    
    // Religious & Cultural Events
    case religiousPreferenceSet = "matrimony_religious_preference_set"
    case culturalPreferenceSet = "matrimony_cultural_preference_set"
    case familyValuesSet = "matrimony_family_values_set"
    
    // Safety Events
    case profileReported = "matrimony_profile_reported"
    case userBlocked = "matrimony_user_blocked"
    case safetyGuidelinesViewed = "matrimony_safety_guidelines_viewed"
    
    public var category: String {
        switch self {
        case .onboardingStarted, .onboardingStepCompleted, .onboardingCompleted:
            return "onboarding"
        case .profileCreated, .profileUpdated, .profileViewed, .photoUploaded:
            return "profile"
        case .searchPerformed, .profileLiked, .profileShortlisted, .matchFound:
            return "matching"
        case .messageSent, .messageReceived, .conversationStarted:
            return "communication"
        case .familyApprovalRequested, .familyApprovalGranted, .familyApprovalDenied:
            return "family_approval"
        case .compatibilityTestStarted, .compatibilityTestCompleted, .compatibilityScoreViewed:
            return "compatibility"
        case .religiousPreferenceSet, .culturalPreferenceSet, .familyValuesSet:
            return "preferences"
        case .profileReported, .userBlocked, .safetyGuidelinesViewed:
            return "safety"
        }
    }
}

public struct MatrimonyUserProfile {
    let userID: String
    let age: String
    let gender: String
    let religion: String
    let marriageIntention: String
    let location: String
    let educationLevel: String
    
    public init(
        userID: String,
        age: String,
        gender: String,
        religion: String,
        marriageIntention: String,
        location: String,
        educationLevel: String
    ) {
        self.userID = userID
        self.age = age
        self.gender = gender
        self.religion = religion
        self.marriageIntention = marriageIntention
        self.location = location
        self.educationLevel = educationLevel
    }
}

#else
// Fallback for when FirebaseAnalytics is not available
@available(iOS 17, *)
public final class FirebaseAnalyticsDestination: AnalyticsDestination {
    private let logger = Logger.shared
    
    public init() {
        logger.warning("[FirebaseAnalytics] Firebase Analytics not available, using console fallback")
    }
    
    public func track(event: AnalyticsEvent) {
        logger.info("[FirebaseAnalyticsFallback] Event: \(event.name) params: \(event.parameters)")
    }
    
    public func setUserID(_ userID: String?) {
        logger.info("[FirebaseAnalyticsFallback] UserID set: \(userID ?? "nil")")
    }
    
    public func setUserProperty(_ value: String?, for key: String) {
        logger.info("[FirebaseAnalyticsFallback] UserProperty → \(key): \(value ?? "nil")")
    }
}
#endif
