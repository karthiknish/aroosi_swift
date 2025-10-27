#if os(iOS)
import Foundation
import Combine

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseAuth
#endif

@available(iOS 17, *)
@MainActor
class MatrimonyProfileViewModel: ObservableObject {
    @Published var profile: MatrimonyProfile?
    @Published var isLoading = false
    @Published var showingEditProfile = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let user: User
    private let matrimonyService: MatrimonyProfileService
    private var cancellables = Set<AnyCancellable>()
    
    init(user: User, matrimonyService: MatrimonyProfileService = DefaultMatrimonyProfileService()) {
        self.user = user
        self.matrimonyService = matrimonyService
        
        loadProfile()
    }
    
    func loadProfile() {
        Task {
            await refreshProfile()
        }
    }
    
    func refreshProfile() async {
        do {
            isLoading = true
            profile = try await matrimonyService.getMatrimonyProfile(for: user.id)
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            showError = true
        }
        isLoading = false
    }
    
    func showEditProfile() {
        showingEditProfile = true
    }
    
    func shareProfile() {
        // Implement profile sharing
        print("Share profile functionality")
    }
    
    func reportConcern() {
        // Implement concern reporting
        print("Report concern functionality")
    }
}

// MARK: - Matrimony Profile Model

struct MatrimonyProfile: Identifiable, Codable {
    let id: String
    let userID: String
    let displayName: String
    let profilePhotoURL: URL?
    let age: Int
    let height: String?
    let location: String?
    let isVerified: Bool
    
    // Marriage Information
    let marriageIntention: MarriageIntention?
    let preferredMarriageTime: String?
    let requiresFamilyApproval: Bool
    let familyValues: [FamilyValue]?
    
    // Family Details
    let familyType: String?
    let familyStatus: String?
    let financialStatus: String?
    let numberOfSiblings: String?
    
    // Religious & Cultural
    let religion: Religion?
    let motherTongue: String?
    let community: String?
    let religiousPractices: String?
    
    // Education & Career
    let educationLevel: EducationLevel?
    let college: String?
    let occupation: String?
    let company: String?
    let annualIncome: String?
    
    // Partner Preferences
    let partnerAgeRange: String?
    let partnerEducationPreference: String?
    let partnerReligionPreference: String?
    let partnerLocationPreference: String?
    
    // Contact Information
    let phoneNumber: String?
    let email: String?
    
    // Metadata
    let createdAt: Date
    let updatedAt: Date
    let profileCompleteness: Double
    
    init(
        id: String = UUID().uuidString,
        userID: String,
        displayName: String,
        profilePhotoURL: URL? = nil,
        age: Int,
        height: String? = nil,
        location: String? = nil,
        isVerified: Bool = false,
        marriageIntention: MarriageIntention? = nil,
        preferredMarriageTime: String? = nil,
        requiresFamilyApproval: Bool = false,
        familyValues: [FamilyValue]? = nil,
        familyType: String? = nil,
        familyStatus: String? = nil,
        financialStatus: String? = nil,
        numberOfSiblings: String? = nil,
        religion: Religion? = nil,
        motherTongue: String? = nil,
        community: String? = nil,
        religiousPractices: String? = nil,
        educationLevel: EducationLevel? = nil,
        college: String? = nil,
        occupation: String? = nil,
        company: String? = nil,
        annualIncome: String? = nil,
        partnerAgeRange: String? = nil,
        partnerEducationPreference: String? = nil,
        partnerReligionPreference: String? = nil,
        partnerLocationPreference: String? = nil,
        phoneNumber: String? = nil,
        email: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        profileCompleteness: Double = 0.0
    ) {
        self.id = id
        self.userID = userID
        self.displayName = displayName
        self.profilePhotoURL = profilePhotoURL
        self.age = age
        self.height = height
        self.location = location
        self.isVerified = isVerified
        self.marriageIntention = marriageIntention
        self.preferredMarriageTime = preferredMarriageTime
        self.requiresFamilyApproval = requiresFamilyApproval
        self.familyValues = familyValues
        self.familyType = familyType
        self.familyStatus = familyStatus
        self.financialStatus = financialStatus
        self.numberOfSiblings = numberOfSiblings
        self.religion = religion
        self.motherTongue = motherTongue
        self.community = community
        self.religiousPractices = religiousPractices
        self.educationLevel = educationLevel
        self.college = college
        self.occupation = occupation
        self.company = company
        self.annualIncome = annualIncome
        self.partnerAgeRange = partnerAgeRange
        self.partnerEducationPreference = partnerEducationPreference
        self.partnerReligionPreference = partnerReligionPreference
        self.partnerLocationPreference = partnerLocationPreference
        self.phoneNumber = phoneNumber
        self.email = email
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.profileCompleteness = profileCompleteness
    }
}

// MARK: - Service Protocol

protocol MatrimonyProfileService {
    func getMatrimonyProfile(for userID: String) async throws -> MatrimonyProfile
    func updateMatrimonyProfile(_ profile: MatrimonyProfile) async throws
    func deleteMatrimonyProfile(for userID: String) async throws
}

// MARK: - Default Service

#if canImport(FirebaseFirestore)

class DefaultMatrimonyProfileService: MatrimonyProfileService {
    private let db = Firestore.firestore()
    private let logger = Logger.shared
    
    func getMatrimonyProfile(for userID: String) async throws -> MatrimonyProfile {
        logger.info("Fetching matrimony profile for user: \(userID)")
        
        do {
            let document = try await db.collection("matrimony_profiles").document(userID).getDocument()
            
            guard let data = document.data() else {
                throw ProfileError.profileNotFound
            }
            
            let profile = try parseMatrimonyProfile(from: data, userID: userID)
            logger.info("Successfully fetched matrimony profile for user: \(userID)")
            return profile
            
        } catch {
            logger.error("Failed to fetch matrimony profile: \(error.localizedDescription)")
            throw ProfileError.fetchFailed
        }
    }
    
    func updateMatrimonyProfile(_ profile: MatrimonyProfile) async throws {
        logger.info("Updating matrimony profile for user: \(profile.userID)")
        
        do {
            let profileData: [String: Any] = [
                "id": profile.id,
                "displayName": profile.displayName,
                "profilePhotoURL": profile.profilePhotoURL?.absoluteString ?? NSNull(),
                "age": profile.age,
                "height": profile.height ?? NSNull(),
                "location": profile.location ?? NSNull(),
                "isVerified": profile.isVerified,
                "marriageIntention": profile.marriageIntention?.rawValue ?? NSNull(),
                "preferredMarriageTime": profile.preferredMarriageTime ?? NSNull(),
                "requiresFamilyApproval": profile.requiresFamilyApproval,
                "familyValues": profile.familyValues?.map { $0.rawValue } ?? [],
                "familyType": profile.familyType ?? NSNull(),
                "familyStatus": profile.familyStatus ?? NSNull(),
                "financialStatus": profile.financialStatus ?? NSNull(),
                "education": profile.education,
                "occupation": profile.occupation,
                "income": profile.income,
                "religiousPreference": profile.religiousPreference.rawValue,
                "about": profile.about,
                "interests": profile.interests,
                "photos": profile.photos.map { $0.absoluteString },
                "phoneNumber": profile.phoneNumber ?? NSNull(),
                "email": profile.email ?? NSNull(),
                "profileCompleteness": profile.profileCompleteness,
                "updatedAt": Timestamp(date: Date())
            ]
            
            try await db.collection("matrimony_profiles").document(profile.userID).setData(profileData, merge: true)
            
            // Also update the main user profile
            try await db.collection("users").document(profile.userID).setData([
                "matrimonyProfile": profileData,
                "profileUpdatedAt": Timestamp(date: Date())
            ], merge: true)
            
            logger.info("Successfully updated matrimony profile for user: \(profile.userID)")
            
        } catch {
            logger.error("Failed to update matrimony profile: \(error.localizedDescription)")
            throw ProfileError.updateFailed
        }
    }
    
    func deleteMatrimonyProfile(for userID: String) async throws {
        logger.info("Deleting matrimony profile for user: \(userID)")
        
        do {
            try await db.collection("matrimony_profiles").document(userID).delete()
            
            // Remove matrimony profile reference from main user document
            try await db.collection("users").document(userID).setData([
                "matrimonyProfile": FieldValue.delete(),
                "profileDeletedAt": Timestamp(date: Date())
            ], merge: true)
            
            logger.info("Successfully deleted matrimony profile for user: \(userID)")
            
        } catch {
            logger.error("Failed to delete matrimony profile: \(error.localizedDescription)")
            throw ProfileError.deleteFailed
        }
    }
    
    private func parseMatrimonyProfile(from data: [String: Any], userID: String) throws -> MatrimonyProfile {
        guard let displayName = data["displayName"] as? String,
              let age = data["age"] as? Int else {
            throw ProfileError.invalidProfileData
        }
        
        let marriageIntentionRaw = data["marriageIntention"] as? String
        let marriageIntention = MarriageIntention(rawValue: marriageIntentionRaw ?? "firstMarriage") ?? .firstMarriage
        
        let religiousPreferenceRaw = data["religiousPreference"] as? String
        let religiousPreference = Religion(rawValue: religiousPreferenceRaw ?? "islam") ?? .islam
        
        let familyValuesRaw = data["familyValues"] as? [String] ?? []
        let familyValues = familyValuesRaw.compactMap { FamilyValue(rawValue: $0) }
        
        let photoURLsRaw = data["photos"] as? [String] ?? []
        let photos = photoURLsRaw.compactMap { URL(string: $0) }
        
        let profilePhotoURL = data["profilePhotoURL"] as? String.flatMap { URL(string: $0) }
        
        return MatrimonyProfile(
            id: data["id"] as? String ?? UUID().uuidString,
            userID: userID,
            displayName: displayName,
            profilePhotoURL: profilePhotoURL,
            age: age,
            height: data["height"] as? String,
            location: data["location"] as? String,
            isVerified: data["isVerified"] as? Bool ?? false,
            marriageIntention: marriageIntention,
            preferredMarriageTime: data["preferredMarriageTime"] as? String,
            requiresFamilyApproval: data["requiresFamilyApproval"] as? Bool ?? false,
            familyValues: familyValues,
            familyType: data["familyType"] as? String,
            familyStatus: data["familyStatus"] as? String,
            financialStatus: data["financialStatus"] as? String,
            education: data["education"] as? String ?? "",
            occupation: data["occupation"] as? String ?? "",
            income: data["income"] as? String ?? "",
            religiousPreference: religiousPreference,
            about: data["about"] as? String ?? "",
            interests: data["interests"] as? [String] ?? [],
            photos: photos,
            phoneNumber: data["phoneNumber"] as? String,
            email: data["email"] as? String,
            profileCompleteness: data["profileCompleteness"] as? Double ?? 0.0,
            createdAt: (data["createdAt"] as? Timestamp)?.date() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.date() ?? Date()
        )
    }
}

#else

// Fallback implementation for when Firebase Firestore is not available
class DefaultMatrimonyProfileService: MatrimonyProfileService {
    private let logger = Logger.shared
    
    func getMatrimonyProfile(for userID: String) async throws -> MatrimonyProfile {
        logger.info("Firestore not available - using fallback profile data")
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return MatrimonyProfile(
            id: UUID().uuidString,
            userID: userID,
            displayName: "Priya Sharma",
            profilePhotoURL: nil,
            age: 28,
            height: "5'4\"",
            location: "Mumbai, India",
            isVerified: true,
            marriageIntention: .firstMarriage,
            preferredMarriageTime: "Within 1 year",
            requiresFamilyApproval: true,
            familyValues: [.traditional, .familyOriented],
            familyType: "Joint Family",
            familyStatus: "Middle Class",
            financialStatus: "Stable",
            education: "MBA",
            occupation: "Software Engineer",
            income: "15-20 LPA",
            religiousPreference: .islam,
            about: "Looking for a compatible life partner",
            interests: ["Reading", "Traveling", "Cooking"],
            photos: [],
            phoneNumber: "+91 98765 43210",
            email: "priya.sharma@email.com",
            profileCompleteness: 85.0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func updateMatrimonyProfile(_ profile: MatrimonyProfile) async throws {
        logger.info("Firestore not available - using fallback profile update")
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func deleteMatrimonyProfile(for userID: String) async throws {
        logger.info("Firestore not available - using fallback profile deletion")
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}

#endif

// MARK: - Profile Errors

enum ProfileError: Error, LocalizedError {
    case profileNotFound
    case fetchFailed
    case updateFailed
    case deleteFailed
    case invalidProfileData
    
    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return "Profile not found. Please create a profile first."
        case .fetchFailed:
            return "Failed to fetch profile. Please check your connection and try again."
        case .updateFailed:
            return "Failed to update profile. Please try again."
        case .deleteFailed:
            return "Failed to delete profile. Please try again."
        case .invalidProfileData:
            return "Invalid profile data. Please check your information."
        }
    }
}

// MARK: - User Extension

extension User {
    static let preview = User(
        id: "preview-user-123",
        email: "aisha.khan@example.com",
        displayName: "Aisha Khan",
        photoURL: URL(string: "https://storage.googleapis.com/aroosi-app/avatars/preview-user.jpg"),
        isEmailVerified: true,
        createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
        lastLoginAt: Date().addingTimeInterval(-2 * 60 * 60) // 2 hours ago
    )
    
    // Legacy support for existing code
    static let mock = preview
}

#endif
