import XCTest
@testable import AroosiKit

@available(iOS 17, *)
@MainActor
final class DashboardTests: XCTestCase {
    
    // MARK: - Dashboard Loading Tests
    
    func testDashboardLoadSuccess() async throws {
        // Given
        let mockDashboardRepo = MockDashboardRepository()
        let mockProfileRepo = MockProfileRepository()
        let mockMatchesRepo = MockMatchesRepository()
        let mockQuickPicksRepo = MockQuickPicksRepository()
        
        let dashboardViewModel = DashboardViewModel(
            dashboardRepository: mockDashboardRepo,
            profileRepository: mockProfileRepo,
            matchesRepository: mockMatchesRepo,
            quickPicksRepository: mockQuickPicksRepo
        )
        
        let expectedProfile = ProfileSummary(
            id: "user-123",
            displayName: "Test User",
            age: 28,
            location: "San Francisco",
            bio: "Test bio",
            avatarURL: nil,
            interests: ["Travel", "Cooking"],
            lastActiveAt: Date()
        )
        
        mockDashboardRepo.dashboardInfoToReturn = DashboardInfo(
            activeMatchesCount: 5,
            unreadMessagesCount: 12,
            recentMatches: [],
            quickPicks: []
        )
        mockProfileRepo.profileToReturn = expectedProfile
        
        // When
        await dashboardViewModel.load(for: "user-123")
        
        // Then
        XCTAssertFalse(dashboardViewModel.state.isLoading)
        XCTAssertEqual(dashboardViewModel.state.activeMatchesCount, 5)
        XCTAssertEqual(dashboardViewModel.state.unreadMessagesCount, 12)
        XCTAssertEqual(dashboardViewModel.state.profile?.displayName, expectedProfile.displayName)
        XCTAssertNil(dashboardViewModel.state.errorMessage)
    }
    
    func testDashboardLoadFailure() async throws {
        // Given
        let mockDashboardRepo = MockDashboardRepository()
        mockDashboardRepo.shouldFailLoad = true
        
        let dashboardViewModel = DashboardViewModel(
            dashboardRepository: mockDashboardRepo
        )
        
        // When
        await dashboardViewModel.load(for: "user-123")
        
        // Then
        XCTAssertFalse(dashboardViewModel.state.isLoading)
        XCTAssertNotNil(dashboardViewModel.state.errorMessage)
        XCTAssertEqual(dashboardViewModel.state.activeMatchesCount, 0)
        XCTAssertEqual(dashboardViewModel.state.unreadMessagesCount, 0)
    }
    
    func testDashboardRefreshSuccess() async throws {
        // Given
        let mockDashboardRepo = MockDashboardRepository()
        let dashboardViewModel = DashboardViewModel(
            dashboardRepository: mockDashboardRepo
        )
        
        let initialInfo = DashboardInfo(
            activeMatchesCount: 3,
            unreadMessagesCount: 7,
            recentMatches: [],
            quickPicks: []
        )
        
        let refreshedInfo = DashboardInfo(
            activeMatchesCount: 4,
            unreadMessagesCount: 8,
            recentMatches: [],
            quickPicks: []
        )
        
        mockDashboardRepo.dashboardInfoToReturn = initialInfo
        
        // Load initial data
        await dashboardViewModel.load(for: "user-123")
        XCTAssertEqual(dashboardViewModel.state.activeMatchesCount, 3)
        
        // Setup refresh data
        mockDashboardRepo.dashboardInfoToReturn = refreshedInfo
        
        // When
        await dashboardViewModel.refresh()
        
        // Then
        XCTAssertEqual(dashboardViewModel.state.activeMatchesCount, 4)
        XCTAssertEqual(dashboardViewModel.state.unreadMessagesCount, 8)
        XCTAssertFalse(dashboardViewModel.state.isLoading)
    }
    
    // MARK: - Stats Tests
    
    func testActiveMatchesCount() async throws {
        // Given
        let mockDashboardRepo = MockDashboardRepository()
        let dashboardViewModel = DashboardViewModel(
            dashboardRepository: mockDashboardRepo
        )
        
        mockDashboardRepo.dashboardInfoToReturn = DashboardInfo(
            activeMatchesCount: 10,
            unreadMessagesCount: 25,
            recentMatches: [],
            quickPicks: []
        )
        
        // When
        await dashboardViewModel.load(for: "user-123")
        
        // Then
        XCTAssertEqual(dashboardViewModel.state.activeMatchesCount, 10)
    }
    
    func testUnreadMessagesCount() async throws {
        // Given
        let mockDashboardRepo = MockDashboardRepository()
        let dashboardViewModel = DashboardViewModel(
            dashboardRepository: mockDashboardRepo
        )
        
        mockDashboardRepo.dashboardInfoToReturn = DashboardInfo(
            activeMatchesCount: 5,
            unreadMessagesCount: 0,
            recentMatches: [],
            quickPicks: []
        )
        
        // When
        await dashboardViewModel.load(for: "user-123")
        
        // Then
        XCTAssertEqual(dashboardViewModel.state.unreadMessagesCount, 0)
    }
    
    // MARK: - Recent Matches Tests
    
    func testRecentMatchesLoaded() async throws {
        // Given
        let mockDashboardRepo = MockDashboardRepository()
        let dashboardViewModel = DashboardViewModel(
            dashboardRepository: mockDashboardRepo
        )
        
        let recentMatch = MatchListItem(
            id: "match-1",
            match: Match(
                id: "match-1",
                participants: [
                    Match.Participant(userID: "user-1", isInitiator: true),
                    Match.Participant(userID: "user-2", isInitiator: false)
                ],
                status: .active,
                lastMessagePreview: "Hello!",
                lastUpdatedAt: Date(),
                conversationID: "conv-1"
            ),
            counterpartProfile: ProfileSummary(
                id: "user-2",
                displayName: "Match User",
                age: 26,
                location: "New York",
                bio: "Nice person",
                avatarURL: nil,
                interests: ["Music"],
                lastActiveAt: Date().addingTimeInterval(-3600)
            ),
            unreadCount: 2
        )
        
        mockDashboardRepo.dashboardInfoToReturn = DashboardInfo(
            activeMatchesCount: 1,
            unreadMessagesCount: 2,
            recentMatches: [recentMatch],
            quickPicks: []
        )
        
        // When
        await dashboardViewModel.load(for: "user-123")
        
        // Then
        XCTAssertEqual(dashboardViewModel.state.recentMatches.count, 1)
        XCTAssertEqual(dashboardViewModel.state.recentMatches.first?.counterpartProfile?.displayName, "Match User")
        XCTAssertEqual(dashboardViewModel.state.recentMatches.first?.unreadCount, 2)
    }
    
    // MARK: - Quick Picks Tests
    
    func testQuickPicksLoaded() async throws {
        // Given
        let mockDashboardRepo = MockDashboardRepository()
        let dashboardViewModel = DashboardViewModel(
            dashboardRepository: mockDashboardRepo
        )
        
        let quickPick = ProfileSummary(
            id: "quickpick-1",
            displayName: "Quick Pick User",
            age: 30,
            location: "Los Angeles",
            bio: "Interesting person",
            avatarURL: nil,
            interests: ["Sports", "Movies"],
            lastActiveAt: Date().addingTimeInterval(-1800)
        )
        
        mockDashboardRepo.dashboardInfoToReturn = DashboardInfo(
            activeMatchesCount: 0,
            unreadMessagesCount: 0,
            recentMatches: [],
            quickPicks: [quickPick]
        )
        
        // When
        await dashboardViewModel.load(for: "user-123")
        
        // Then
        XCTAssertEqual(dashboardViewModel.state.quickPicks.count, 1)
        XCTAssertEqual(dashboardViewModel.state.quickPicks.first?.displayName, "Quick Pick User")
        XCTAssertTrue(dashboardViewModel.state.quickPicks.first?.interests.contains("Sports") == true)
    }
    
    // MARK: - Interest Sending Tests
    
    func testSendInterestSuccess() async throws {
        // Given
        let mockQuickPicksRepo = MockQuickPicksRepository()
        let dashboardViewModel = DashboardViewModel(
            quickPicksRepository: mockQuickPicksRepo
        )
        
        let profile = ProfileSummary(
            id: "target-user",
            displayName: "Target User",
            age: 28,
            location: "Boston",
            bio: "Great match",
            avatarURL: nil,
            interests: ["Reading"],
            lastActiveAt: Date()
        )
        
        mockQuickPicksRepo.shouldFailSendInterest = false
        
        // When
        await dashboardViewModel.sendInterest(to: profile)
        
        // Then
        XCTAssertTrue(mockQuickPicksRepo.sendInterestCalled)
        XCTAssertFalse(dashboardViewModel.state.isSendingInterest(for: profile.id))
        XCTAssertTrue(dashboardViewModel.state.hasSentInterest(to: profile.id))
    }
    
    func testSendInterestFailure() async throws {
        // Given
        let mockQuickPicksRepo = MockQuickPicksRepository()
        mockQuickPicksRepo.shouldFailSendInterest = true
        
        let dashboardViewModel = DashboardViewModel(
            quickPicksRepository: mockQuickPicksRepo
        )
        
        let profile = ProfileSummary(
            id: "target-user",
            displayName: "Target User",
            age: 28,
            location: "Boston",
            bio: "Great match",
            avatarURL: nil,
            interests: ["Reading"],
            lastActiveAt: Date()
        )
        
        // When
        await dashboardViewModel.sendInterest(to: profile)
        
        // Then
        XCTAssertFalse(dashboardViewModel.state.isSendingInterest(for: profile.id))
        XCTAssertFalse(dashboardViewModel.state.hasSentInterest(to: profile.id))
        XCTAssertNotNil(dashboardViewModel.state.errorMessage)
    }
    
    // MARK: - Error Handling Tests
    
    func testLoadIfNeededNotCalledTwice() async throws {
        // Given
        let mockDashboardRepo = MockDashboardRepository()
        let dashboardViewModel = DashboardViewModel(
            dashboardRepository: mockDashboardRepo
        )
        
        mockDashboardRepo.dashboardInfoToReturn = DashboardInfo(
            activeMatchesCount: 1,
            unreadMessagesCount: 1,
            recentMatches: [],
            quickPicks: []
        )
        
        // When
        await dashboardViewModel.loadIfNeeded(for: "user-123")
        await dashboardViewModel.loadIfNeeded(for: "user-123") // Should not call again
        
        // Then
        XCTAssertEqual(mockDashboardRepo.loadCallCount, 1)
    }
    
    func testInfoMessageDismissal() async throws {
        // Given
        let dashboardViewModel = DashboardViewModel()
        
        // Set an info message
        dashboardViewModel.showInfoMessage("Test message")
        
        // When
        dashboardViewModel.dismissInfoMessage()
        
        // Then
        XCTAssertNil(dashboardViewModel.state.infoMessage)
    }
}

// MARK: - Mock Classes

private class MockDashboardRepository: DashboardRepository {
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

private class MockQuickPicksRepository: QuickPicksRepository {
    var shouldFailSendInterest = false
    var sendInterestCalled = false
    
    func sendInterest(to profile: ProfileSummary) async throws {
        sendInterestCalled = true
        
        if shouldFailSendInterest {
            throw QuickPicksError.networkError
        }
    }
    
    func fetchQuickPicks(userID: String, limit: Int) async throws -> [ProfileSummary] {
        return []
    }
}

private enum DashboardError: Error {
    case networkError
}

private enum QuickPicksError: Error {
    case networkError
}
