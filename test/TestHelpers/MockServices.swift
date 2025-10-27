import Foundation
import FirebaseFirestore
import FirebaseAuth
@testable import AroosiKit

// MARK: - Mock Authentication Service

class MockAuthService: AuthProviding {
    enum AuthResult {
        case success(UserProfile)
        case failure(Error)
    }
    
    var resultToReturn: AuthResult = .success(UserProfile(id: "default", displayName: "Default", email: nil, avatarURL: nil))
    var currentUserToReturn: UserProfile?
    var shouldFailSignOut = false
    var shouldFailDeleteAccount = false
    var deleteAccountCalled = false
    var signInCallCount = 0
    
    func currentUser() async throws -> UserProfile? {
        return currentUserToReturn
    }
    
    @available(iOS 13, macOS 10.15, *)
    func presentSignIn(from anchor: ASPresentationAnchor) async throws -> UserProfile {
        signInCallCount += 1
        switch resultToReturn {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
    
    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile {
        signInCallCount += 1
        switch resultToReturn {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
    
    func signOut() throws {
        if shouldFailSignOut {
            throw AuthError.signOutFailed
        }
    }
    
    func deleteAccount(password: String?, reason: String?) async throws {
        deleteAccountCalled = true
        if shouldFailDeleteAccount {
            throw AuthError.deleteAccountFailed
        }
    }
}

// MARK: - Mock Profile Repository

class MockProfileRepository: ProfileRepository {
    enum ProfileResult {
        case success(ProfileSummary)
        case notFound
        case failure(Error)
    }
    
    var profileToReturn: ProfileSummary?
    var resultToReturn: ProfileResult = .success(ProfileSummary(id: "default", displayName: "Default"))
    var profilesToReturn: [ProfileSummary] = []
    var shouldFailUpdate = false
    var shouldFailFetch = false
    var updateCallCount = 0
    var fetchCallCount = 0
    
    func fetchProfile(id: String) async throws -> ProfileSummary {
        fetchCallCount += 1
        
        if shouldFailFetch {
            throw RepositoryError.networkError
        }
        
        switch resultToReturn {
        case .success(let profile):
            return profile
        case .notFound:
            throw RepositoryError.notFound
        case .failure(let error):
            throw error
        }
    }
    
    func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(profilesToReturn)
            continuation.finish()
        }
    }
    
    func updateProfile(_ profile: ProfileSummary) async throws {
        updateCallCount += 1
        
        if shouldFailUpdate {
            throw RepositoryError.networkError
        }
    }
    
    func fetchShortlist(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        return ProfileSearchPage(items: profilesToReturn, nextCursor: nil)
    }
    
    func toggleShortlist(userID: String) async throws -> ShortlistToggleResult {
        return ShortlistToggleResult(action: .added)
    }
    
    func setShortlistNote(userID: String, note: String) async throws {
        // Mock implementation
    }
    
    func fetchFavorites(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        return ProfileSearchPage(items: profilesToReturn, nextCursor: nil)
    }
    
    func toggleFavorite(userID: String) async throws {
        // Mock implementation
    }
}

// MARK: - Mock Dashboard Repository

class MockDashboardRepository: DashboardRepository {
    var dashboardInfoToReturn: DashboardInfo?
    var shouldFailLoad = false
    var loadCallCount = 0
    
    func fetchDashboardInfo(userID: String) async throws -> DashboardInfo {
        loadCallCount += 1
        
        if shouldFailLoad {
            throw DashboardError.networkError
        }
        
        return dashboardInfoToReturn ?? DashboardInfo(
            activeMatchesCount: 0,
            unreadMessagesCount: 0,
            recentMatches: [],
            quickPicks: []
        )
    }
}

// MARK: - Mock Chat Message Repository

class MockChatMessageRepository: ChatMessageRepository {
    var messagesToReturn: [ChatMessage] = []
    var shouldFailSendMessage = false
    var shouldFailLoadMessages = false
    var sendMessageCalled = false
    var markAsReadCalled = false
    var stopObservingCalled = false
    var lastSentMessage: ChatMessage?
    
    func sendMessage(_ message: ChatMessage) async throws {
        sendMessageCalled = true
        lastSentMessage = message
        
        if shouldFailSendMessage {
            throw ChatError.networkError
        }
    }
    
    func fetchMessages(conversationID: String, limit: Int) async throws -> [ChatMessage] {
        if shouldFailLoadMessages {
            throw ChatError.networkError
        }
        return Array(messagesToReturn.prefix(limit))
    }
    
    func observeMessages(conversationID: String) -> AsyncThrowingStream<[ChatMessage], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(messagesToReturn)
            continuation.finish()
        }
    }
    
    func markAsRead(conversationID: String, userID: String) async throws {
        markAsReadCalled = true
    }
    
    func stopObserving() {
        stopObservingCalled = true
    }
}

// MARK: - Mock Matches Repository

class MockMatchesRepository: MatchesRepository {
    var matchesToReturn: [MatchListItem] = []
    var shouldFailFetch = false
    var shouldFailSendInterest = false
    var fetchCallCount = 0
    var sendInterestCallCount = 0
    
    func fetchMatches(userID: String, limit: Int) async throws -> [MatchListItem] {
        fetchCallCount += 1
        
        if shouldFailFetch {
            throw MatchesError.networkError
        }
        
        return Array(matchesToReturn.prefix(limit))
    }
    
    func sendInterest(to userID: String, from userID: String) async throws {
        sendInterestCallCount += 1
        
        if shouldFailSendInterest {
            throw MatchesError.networkError
        }
    }
    
    func acceptInterest(interestID: String) async throws {
        // Mock implementation
    }
    
    func rejectInterest(interestID: String) async throws {
        // Mock implementation
    }
}

// MARK: - Mock Quick Picks Repository

class MockQuickPicksRepository: QuickPicksRepository {
    var quickPicksToReturn: [ProfileSummary] = []
    var shouldFailSendInterest = false
    var shouldFailFetch = false
    var sendInterestCalled = false
    var fetchCallCount = 0
    
    func sendInterest(to profile: ProfileSummary) async throws {
        sendInterestCalled = true
        
        if shouldFailSendInterest {
            throw QuickPicksError.networkError
        }
    }
    
    func fetchQuickPicks(userID: String, limit: Int) async throws -> [ProfileSummary] {
        fetchCallCount += 1
        
        if shouldFailFetch {
            throw QuickPicksError.networkError
        }
        
        return Array(quickPicksToReturn.prefix(limit))
    }
}

// MARK: - Mock Settings Repository

class MockSettingsRepository: SettingsRepository {
    var settingsToReturn: UserSettings = UserSettings.default
    var shouldFailUpdate = false
    var shouldFailFetch = false
    var updateCallCount = 0
    var fetchCallCount = 0
    
    func fetchSettings(userID: String) async throws -> UserSettings {
        fetchCallCount += 1
        
        if shouldFailFetch {
            throw SettingsError.networkError
        }
        
        return settingsToReturn
    }
    
    func updateSettings(_ settings: UserSettings, userID: String) async throws {
        updateCallCount += 1
        
        if shouldFailUpdate {
            throw SettingsError.networkError
        }
        
        self.settingsToReturn = settings
    }
}

// MARK: - Mock Family Approval Repository

class MockFamilyApprovalRepository: FamilyApprovalRepository {
    var requestsToReturn: [FamilyApprovalRequest] = []
    var shouldFailCreate = false
    var shouldFailFetch = false
    var createCallCount = 0
    var fetchCallCount = 0
    
    func createRequest(_ request: FamilyApprovalRequest) async throws {
        createCallCount += 1
        
        if shouldFailCreate {
            throw FamilyApprovalError.networkError
        }
    }
    
    func fetchRequests(userID: String) async throws -> [FamilyApprovalRequest] {
        fetchCallCount += 1
        
        if shouldFailFetch {
            throw FamilyApprovalError.networkError
        }
        
        return requestsToReturn
    }
    
    func updateRequest(_ request: FamilyApprovalRequest) async throws {
        // Mock implementation
    }
}

// MARK: - Mock Compatibility Repository

class MockCompatibilityRepository: CompatibilityRepository {
    var responsesToReturn: [CompatibilityResponse] = []
    var reportToReturn: CompatibilityReport?
    var shouldFailSubmit = false
    var shouldFailGenerate = false
    var submitCallCount = 0
    var generateCallCount = 0
    
    func submitResponses(_ responses: [CompatibilityResponse], userID: String) async throws {
        submitCallCount += 1
        
        if shouldFailSubmit {
            throw CompatibilityError.networkError
        }
        
        self.responsesToReturn = responses
    }
    
    func generateReport(userID: String, partnerID: String) async throws -> CompatibilityReport {
        generateCallCount += 1
        
        if shouldFailGenerate {
            throw CompatibilityError.networkError
        }
        
        return reportToReturn ?? CompatibilityReport.mock
    }
}

// MARK: - Mock Error Types

enum AuthError: Error {
    case invalidCredentials
    case signOutFailed
    case deleteAccountFailed
}

enum RepositoryError: Error {
    case networkError
    case notFound
}

enum DashboardError: Error {
    case networkError
}

enum ChatError: Error {
    case networkError
}

enum MatchesError: Error {
    case networkError
}

enum QuickPicksError: Error {
    case networkError
}

enum SettingsError: Error {
    case networkError
}

enum FamilyApprovalError: Error {
    case networkError
}

enum CompatibilityError: Error {
    case networkError
}

// MARK: - Mock Data Extensions

extension UserProfile {
    static let mock = UserProfile(
        id: "mock-user-123",
        displayName: "Mock User",
        email: "mock@example.com",
        avatarURL: nil
    )
}

extension ProfileSummary {
    static let mock = ProfileSummary(
        id: "mock-profile-123",
        displayName: "Mock Profile",
        age: 28,
        location: "San Francisco",
        bio: "Mock bio for testing",
        avatarURL: nil,
        interests: ["Travel", "Cooking", "Music"],
        lastActiveAt: Date()
    )
}

extension DashboardInfo {
    static let mock = DashboardInfo(
        activeMatchesCount: 5,
        unreadMessagesCount: 12,
        recentMatches: [],
        quickPicks: [ProfileSummary.mock]
    )
}

extension ChatMessage {
    static let mock = ChatMessage(
        id: "mock-message-123",
        conversationID: "mock-conversation-123",
        authorID: "mock-user-123",
        text: "Mock message for testing",
        sentAt: Date(),
        deliveredAt: Date(),
        readAt: nil
    )
}

extension UserSettings {
    static let `default` = UserSettings(
        pushNotificationsEnabled: true,
        emailNotificationsEnabled: true,
        profileVisibility: .public,
        discoveryPreferences: DiscoveryPreferences.default
    )
}

extension CompatibilityReport {
    static let mock = CompatibilityReport(
        userID1: "user-1",
        userID2: "user-2",
        overallScore: 85,
        categoryScores: [
            "Values": 90,
            "Lifestyle": 80,
            "Family": 85
        ],
        insights: [
            "Strong alignment in family values",
            "Complementary lifestyle preferences"
        ],
        generatedAt: Date()
    )
}

extension DiscoveryPreferences {
    static let `default` = DiscoveryPreferences(
        ageRange: 18...35,
        maxDistance: 50,
        interests: []
    )
}
