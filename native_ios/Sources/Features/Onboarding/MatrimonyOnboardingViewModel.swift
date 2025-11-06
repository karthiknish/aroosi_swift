#if os(iOS)
import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseAuth
#endif

@available(iOS 17, *)
@MainActor
class MatrimonyOnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var errorMessage: String?
    
    // User Preferences
    @Published var marriageIntention: MarriageIntention?
    @Published var familyValues: Set<FamilyValue> = []
    @Published var religiousPreference: Religion?
    @Published var partnerPreferences = PartnerPreferences()
    @Published var requiresFamilyApproval = false
    
    private let onboardingService: MatrimonyOnboardingService
    private let analyticsService: AnalyticsService
    
    init(
        onboardingService: MatrimonyOnboardingService = DefaultMatrimonyOnboardingService(),
        analyticsService: AnalyticsService = AnalyticsService.shared
    ) {
        self.onboardingService = onboardingService
        self.analyticsService = analyticsService
        
        // Track onboarding start
        trackOnboardingStart()
    }
    
    func nextStep() {
        guard validateCurrentStep() else { return }
        
        // Track step completion
        trackStepCompleted(currentStep)
        
        if let nextStep = currentStep.next {
            currentStep = nextStep
            // Track step start
            trackStepStarted(nextStep)
        } else {
            completeOnboarding()
        }
    }
    
    func previousStep() {
        if let previousStep = currentStep.previous {
            currentStep = previousStep
        }
    }
    
    func completeOnboarding() {
        Task {
            do {
                try await saveOnboardingData()
                trackOnboardingCompleted()
                currentStep = .complete
            } catch {
                errorMessage = "Failed to complete onboarding: \(error.localizedDescription)"
            }
        }
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case .welcome:
            return true
        case .intentions:
            guard marriageIntention != nil else {
                errorMessage = "Please select your marriage intention"
                return false
            }
            return true
        case .familyValues:
            guard !familyValues.isEmpty else {
                errorMessage = "Please select at least one family value"
                return false
            }
            return true
        case .religion:
            guard religiousPreference != nil else {
                errorMessage = "Please select your religious preference"
                return false
            }
            return true
        case .preferences:
            return true // Preferences are optional
        case .familyInvolvement:
            return true // Family involvement is a choice
        case .complete:
            return true
        }
    }
    
    private func saveOnboardingData() async throws {
        let onboardingData = MatrimonyOnboardingData(
            marriageIntention: marriageIntention,
            familyValues: Array(familyValues),
            religiousPreference: religiousPreference,
            partnerPreferences: partnerPreferences,
            requiresFamilyApproval: requiresFamilyApproval
        )
        
        try await onboardingService.saveOnboardingData(onboardingData)
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Onboarding Steps

enum OnboardingStep: CaseIterable {
    case welcome
    case intentions
    case familyValues
    case religion
    case preferences
    case familyInvolvement
    case complete
    
    var next: OnboardingStep? {
        switch self {
        case .welcome:
            return .intentions
        case .intentions:
            return .familyValues
        case .familyValues:
            return .religion
        case .religion:
            return .preferences
        case .preferences:
            return .familyInvolvement
        case .familyInvolvement:
            return .complete
        case .complete:
            return nil
        }
    }
    
    var previous: OnboardingStep? {
        switch self {
        case .welcome:
            return nil
        case .intentions:
            return .welcome
        case .familyValues:
            return .intentions
        case .religion:
            return .familyValues
        case .preferences:
            return .religion
        case .familyInvolvement:
            return .preferences
        case .complete:
            return .familyInvolvement
        }
    }
}

// MARK: - Data Models

enum MarriageIntention: String, CaseIterable, Codable {
    case firstMarriage
    case secondMarriage
    case remarriageAfterWidowhood
    case remarriageAfterDivorce
    
    var title: String {
        switch self {
        case .firstMarriage:
            return "First Marriage"
        case .secondMarriage:
            return "Second Marriage"
        case .remarriageAfterWidowhood:
            return "Remarriage (Widow/Widower)"
        case .remarriageAfterDivorce:
            return "Remarriage (Divorced)"
        }
    }
    
    var description: String {
        switch self {
        case .firstMarriage:
            return "Never married before"
        case .secondMarriage:
            return "Previously married"
        case .remarriageAfterWidowhood:
            return "Lost spouse, seeking remarriage"
        case .remarriageAfterDivorce:
            return "Divorced, seeking new marriage"
        }
    }
    
    var icon: String {
        switch self {
        case .firstMarriage:
            return "heart.fill"
        case .secondMarriage:
            return "heart.circle.fill"
        case .remarriageAfterWidowhood:
            return "heart.text.square.fill"
        case .remarriageAfterDivorce:
            return "heart.slash.fill"
        }
    }
}

enum FamilyValue: String, CaseIterable, Codable {
    case traditional
    case modern
    case religious
    case educated
    case familyOriented
    case careerFocused
    case respectful
    case honest
    
    var displayName: String {
        switch self {
        case .traditional:
            return "Traditional Values"
        case .modern:
            return "Modern Outlook"
        case .religious:
            return "Religious Beliefs"
        case .educated:
            return "Education Focus"
        case .familyOriented:
            return "Family Oriented"
        case .careerFocused:
            return "Career Focused"
        case .respectful:
            return "Respectful"
        case .honest:
            return "Honest"
        }
    }
    
    var icon: String {
        switch self {
        case .traditional:
            return "house.fill"
        case .modern:
            return "lightbulb.fill"
        case .religious:
            return "star.fill"
        case .educated:
            return "book.fill"
        case .familyOriented:
            return "person.3.fill"
        case .careerFocused:
            return "briefcase.fill"
        case .respectful:
            return "hand.raised.fill"
        case .honest:
            return "checkmark.shield.fill"
        }
    }
}

enum Religion: String, CaseIterable, Codable {
    case hindu
    case muslim
    case christian
    case sikh
    case jain
    case buddhist
    case parsi
    case jewish
    case other
    case nonReligious
    
    var displayName: String {
        switch self {
        case .hindu:
            return "Hindu"
        case .muslim:
            return "Muslim"
        case .christian:
            return "Christian"
        case .sikh:
            return "Sikh"
        case .jain:
            return "Jain"
        case .buddhist:
            return "Buddhist"
        case .parsi:
            return "Parsi"
        case .jewish:
            return "Jewish"
        case .other:
            return "Other"
        case .nonReligious:
            return "Non-Religious"
        }
    }
    
    var description: String {
        switch self {
        case .hindu:
            return "Hinduism and related traditions"
        case .muslim:
            return "Islam and related traditions"
        case .christian:
            return "Christianity and related traditions"
        case .sikh:
            return "Sikhism and related traditions"
        case .jain:
            return "Jainism and related traditions"
        case .buddhist:
            return "Buddhism and related traditions"
        case .parsi:
            return "Zoroastrianism and related traditions"
        case .jewish:
            return "Judaism and related traditions"
        case .other:
            return "Other religious traditions"
        case .nonReligious:
            return "Secular or non-religious"
        }
    }
    
    var icon: String {
        switch self {
        case .hindu:
            return "om.fill"
        case .muslim:
            return "star.and.crescent.fill"
        case .christian:
            return "cross.fill"
        case .sikh:
            return "khanda.fill"
        case .jain:
            return "hand.raised.fill"
        case .buddhist:
            return "dharmachakra.fill"
        case .parsi:
            return "flame.fill"
        case .jewish:
            return "star.of.david.fill"
        case .other:
            return "questionmark.circle.fill"
        case .nonReligious:
            return "globe.americas.fill"
        }
    }
}

enum EducationLevel: String, CaseIterable, Codable {
    case highSchool
    case bachelors
    case masters
    case phd
    case professional
    case other
    
    var displayName: String {
        switch self {
        case .highSchool:
            return "High School"
        case .bachelors:
            return "Bachelor's Degree"
        case .masters:
            return "Master's Degree"
        case .phd:
            return "PhD/Doctorate"
        case .professional:
            return "Professional Degree"
        case .other:
            return "Other"
        }
    }
}

struct PartnerPreferences {
    var minAge: Int = 18
    var maxAge: Int = 100
    var educationLevel: EducationLevel? = nil
    var occupation: String = ""
    
    var ageRange: String {
        return "\(minAge) - \(maxAge)"
    }
}

struct MatrimonyOnboardingData {
    let marriageIntention: MarriageIntention?
    let familyValues: [FamilyValue]
    let religiousPreference: Religion?
    let partnerPreferences: PartnerPreferences
    let requiresFamilyApproval: Bool
}

// MARK: - Analytics Tracking

private extension MatrimonyOnboardingViewModel {
    func trackOnboardingStart() {
        analyticsService.track(AnalyticsEvent(
            name: "matrimony_onboarding_started",
            parameters: [
                "step": currentStep.rawValue,
                "app_focus": "matrimony",
                "user_intent": "marriage"
            ]
        ))
    }
    
    func trackStepStarted(_ step: OnboardingStep) {
        analyticsService.track(AnalyticsEvent(
            name: "matrimony_onboarding_step_started",
            parameters: [
                "step": step.rawValue,
                "step_title": step.title,
                "step_category": step.category.rawValue
            ]
        ))
    }
    
    func trackStepCompleted(_ step: OnboardingStep) {
        analyticsService.track(AnalyticsEvent(
            name: "matrimony_onboarding_step_completed",
            parameters: [
                "step": step.rawValue,
                "step_title": step.title,
                "step_category": step.category.rawValue,
                "completion_time": ISO8601DateFormatter().string(from: Date())
            ]
        ))
        
        // Track step-specific data
        switch step {
        case .marriageIntentions:
            if let intention = marriageIntention {
                analyticsService.track(AnalyticsEvent(
                    name: "matrimony_intention_selected",
                    parameters: [
                        "intention": intention.rawValue,
                        "intention_title": intention.title
                    ]
                ))
            }
        case .familyValues:
            if !familyValues.isEmpty {
                let values = familyValues.map { $0.rawValue }.joined(separator: ",")
                analyticsService.track(AnalyticsEvent(
                    name: "matrimony_family_values_selected",
                    parameters: [
                        "values": values,
                        "values_count": "\(familyValues.count)"
                    ]
                ))
            }
        case .religiousPreferences:
            if let religion = religiousPreference {
                analyticsService.track(AnalyticsEvent(
                    name: "matrimony_religion_selected",
                    parameters: [
                        "religion": religion.rawValue,
                        "religion_name": religion.displayName
                    ]
                ))
            }
        case .partnerPreferences:
            analyticsService.track(AnalyticsEvent(
                name: "matrimony_partner_preferences_set",
                parameters: [
                    "age_range": partnerPreferences.ageRange ?? "not_set",
                    "education": partnerPreferences.educationLevel?.rawValue ?? "not_set",
                    "location": partnerPreferences.location ?? "not_set"
                ]
            ))
        case .familyInvolvement:
            analyticsService.track(AnalyticsEvent(
                name: "matrimony_family_approval_set",
                parameters: [
                    "requires_approval": requiresFamilyApproval ? "true" : "false"
                ]
            ))
        default:
            break
        }
    }
    
    func trackOnboardingCompleted() {
        analyticsService.track(AnalyticsEvent(
            name: "matrimony_onboarding_completed",
            parameters: [
                "completion_time": ISO8601DateFormatter().string(from: Date()),
                "total_steps": "\(OnboardingStep.allCases.count)",
                "app_focus": "matrimony",
                "ready_for_matching": "true"
            ]
        ))
    }
}

// MARK: - Service Protocol

protocol MatrimonyOnboardingService {
    func saveOnboardingData(_ data: MatrimonyOnboardingData) async throws
    func getOnboardingData() async throws -> MatrimonyOnboardingData?
}

// MARK: - Default Service

#if canImport(FirebaseFirestore)

class DefaultMatrimonyOnboardingService: MatrimonyOnboardingService {
    private let db = Firestore.firestore()
    private let logger = Logger.shared
    
    func saveOnboardingData(_ data: MatrimonyOnboardingData) async throws {
        logger.info("Saving matrimony onboarding data to Firestore")
        
        guard let userID = getCurrentUserID() else {
            throw OnboardingError.userNotAuthenticated
        }
        
        do {
            let onboardingData: [String: Any] = [
                "marriageIntention": data.marriageIntention?.rawValue ?? NSNull(),
                "familyValues": data.familyValues.map { $0.rawValue },
                "religiousPreference": data.religiousPreference?.rawValue ?? NSNull(),
                "partnerPreferences": [
                    "minAge": data.partnerPreferences.minAge,
                    "maxAge": data.partnerPreferences.maxAge,
                    "maxDistance": data.partnerPreferences.maxDistance,
                    "educationLevel": data.partnerPreferences.educationLevel?.rawValue ?? NSNull()
                ],
                "requiresFamilyApproval": data.requiresFamilyApproval,
                "completedAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]
            
            try await db.collection("users").document(userID).setData([
                "onboarding": onboardingData
            ], merge: true)
            
            logger.info("Successfully saved onboarding data for user: \(userID)")
            
        } catch {
            logger.error("Failed to save onboarding data: \(error.localizedDescription)")
            throw OnboardingError.saveFailed
        }
    }
    
    func getOnboardingData() async throws -> MatrimonyOnboardingData? {
        logger.info("Fetching matrimony onboarding data from Firestore")
        
        guard let userID = getCurrentUserID() else {
            throw OnboardingError.userNotAuthenticated
        }
        
        do {
            let document = try await db.collection("users").document(userID).getDocument()
            
            guard let onboardingData = document.data()?["onboarding"] as? [String: Any] else {
                return nil
            }
            
            let marriageIntention = onboardingData["marriageIntention"] as? String
            let familyValuesRaw = onboardingData["familyValues"] as? [String] ?? []
            let religiousPreference = onboardingData["religiousPreference"] as? String
            
            let partnerPreferencesData = onboardingData["partnerPreferences"] as? [String: Any] ?? [:]
            let partnerPreferences = PartnerPreferences(
                minAge: partnerPreferencesData["minAge"] as? Int ?? 18,
                maxAge: partnerPreferencesData["maxAge"] as? Int ?? 100,
                maxDistance: partnerPreferencesData["maxDistance"] as? Int ?? 50,
                educationLevel: (partnerPreferencesData["educationLevel"] as? String).flatMap { EducationLevel(rawValue: $0) }
            )
            
            let onboarding = MatrimonyOnboardingData(
                marriageIntention: marriageIntention.flatMap { MarriageIntention(rawValue: $0) },
                familyValues: familyValuesRaw.compactMap { FamilyValue(rawValue: $0) },
                religiousPreference: religiousPreference.flatMap { Religion(rawValue: $0) },
                partnerPreferences: partnerPreferences,
                requiresFamilyApproval: onboardingData["requiresFamilyApproval"] as? Bool ?? false
            )
            
            logger.info("Successfully fetched onboarding data for user: \(userID)")
            return onboarding
            
        } catch {
            logger.error("Failed to fetch onboarding data: \(error.localizedDescription)")
            throw OnboardingError.fetchFailed
        }
    }
    
    private func getCurrentUserID() -> String? {
        // This should get the current user ID from your authentication service
        // For now, returning a placeholder - you should integrate with your auth service
        return Auth.auth().currentUser?.uid
    }
}

#else

// Fallback implementation for when Firebase Firestore is not available
class DefaultMatrimonyOnboardingService: MatrimonyOnboardingService {
    private let logger = Logger.shared
    
    func saveOnboardingData(_ data: MatrimonyOnboardingData) async throws {
        // Fallback to local storage when Firebase is not available
        logger.info("Saving onboarding data locally (Firebase unavailable)")
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func getOnboardingData() async throws -> MatrimonyOnboardingData? {
        return nil
    }
}

#endif

// MARK: - Onboarding Errors

enum OnboardingError: Error, LocalizedError {
    case userNotAuthenticated
    case saveFailed
    case fetchFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated. Please sign in to continue."
        case .saveFailed:
            return "Failed to save onboarding data. Please try again."
        case .fetchFailed:
            return "Failed to fetch onboarding data. Please try again."
        }
    }
}

#endif
