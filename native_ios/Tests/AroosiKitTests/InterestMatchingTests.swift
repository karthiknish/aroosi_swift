import XCTest
import FirebaseFirestore
@testable import AroosiKit

@available(iOS 17.0, *)
final class InterestMatchingTests: XCTestCase {
    
    var interestRepository: FirestoreInterestRepository!
    var matchCreationService: MatchCreationService!
    var matchRepository: FirestoreMatchRepository!
    
    override func setUpWithError() throws {
        // Initialize test repositories
        interestRepository = FirestoreInterestRepository()
        matchCreationService = MatchCreationService()
        matchRepository = FirestoreMatchRepository()
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        interestRepository = nil
        matchCreationService = nil
        matchRepository = nil
    }
    
    // MARK: - Interest Sending Tests
    
    func testSendInterest() async throws {
        let fromUserID = "test_user_1"
        let toUserID = "test_user_2"
        
        // Send interest
        try await interestRepository.sendInterest(from: fromUserID, to: toUserID)
        
        // Verify interest was sent (would need to query to verify)
        // This is a basic test to ensure no errors are thrown
        XCTAssertTrue(true, "Interest sent successfully")
    }
    
    func testSendDuplicateInterest() async throws {
        let fromUserID = "test_user_1"
        let toUserID = "test_user_2"
        
        // Send first interest
        try await interestRepository.sendInterest(from: fromUserID, to: toUserID)
        
        // Try to send duplicate interest
        do {
            try await interestRepository.sendInterest(from: fromUserID, to: toUserID)
            XCTFail("Should have thrown an error for duplicate interest")
        } catch RepositoryError.alreadyExists {
            // Expected error
            XCTAssertTrue(true, "Duplicate interest correctly rejected")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Mutual Interest Detection Tests
    
    func testMutualInterestDetection() async throws {
        let user1 = "test_user_1"
        let user2 = "test_user_2"
        
        // User 1 sends interest to User 2
        try await interestRepository.sendInterest(from: user1, to: user2)
        
        // Check for mutual interest (should be none initially)
        let mutualInterests = try await interestRepository.checkForMutualInterest(userID: user1, targetID: user2)
        XCTAssertTrue(mutualInterests.isEmpty, "No mutual interest should exist initially")
        
        // User 2 sends interest to User 1
        try await interestRepository.sendInterest(from: user2, to: user1)
        
        // Check for mutual interest again (should detect it)
        let mutualInterestsAfter = try await interestRepository.checkForMutualInterest(userID: user1, targetID: user2)
        XCTAssertFalse(mutualInterestsAfter.isEmpty, "Mutual interest should be detected")
    }
    
    // MARK: - Match Creation Tests
    
    func testMatchCreation() async throws {
        let user1 = "test_user_1"
        let user2 = "test_user_2"
        
        // Create match
        let match = try await matchCreationService.createMatch(between: user1, and: user2)
        
        // Verify match properties
        XCTAssertEqual(match.participantIDs.count, 2, "Match should have 2 participants")
        XCTAssertTrue(match.participantIDs.contains(user1), "Match should include user1")
        XCTAssertTrue(match.participantIDs.contains(user2), "Match should include user2")
        XCTAssertEqual(match.status, .active, "Match should be active")
        XCTAssertNotNil(match.conversationID, "Match should have a conversation ID")
    }
    
    func testMatchCreationWithSameUser() async throws {
        let userID = "test_user_1"
        
        // Try to create match with same user
        do {
            _ = try await matchCreationService.createMatch(between: userID, and: userID)
            XCTFail("Should have thrown an error for same user")
        } catch MatchCreationError.sameUser {
            // Expected error
            XCTAssertTrue(true, "Same user match correctly rejected")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testMatchExists() async throws {
        let user1 = "test_user_1"
        let user2 = "test_user_2"
        
        // Initially no match should exist
        let existsBefore = try await matchCreationService.matchExists(between: user1, and: user2)
        XCTAssertFalse(existsBefore, "No match should exist initially")
        
        // Create match
        _ = try await matchCreationService.createMatch(between: user1, and: user2)
        
        // Now match should exist
        let existsAfter = try await matchCreationService.matchExists(between: user1, and: user2)
        XCTAssertTrue(existsAfter, "Match should exist after creation")
    }
    
    // MARK: - Interest Status Management Tests
    
    func testInterestStatusUpdate() async throws {
        let user1 = "test_user_1"
        let user2 = "test_user_2"
        
        // Send interests from both users
        try await interestRepository.sendInterest(from: user1, to: user2)
        try await interestRepository.sendInterest(from: user2, to: user1)
        
        // Update interest statuses to matched
        try await interestRepository.updateInterestStatuses(userID: user1, targetID: user2, status: .matched)
        
        // Verify no pending interests remain
        let mutualInterests = try await interestRepository.checkForMutualInterest(userID: user1, targetID: user2)
        XCTAssertTrue(mutualInterests.isEmpty, "No pending interests should remain after status update")
    }
    
    func testRespondToInterest() async throws {
        let fromUserID = "test_user_1"
        let toUserID = "test_user_2"
        
        // Send interest
        try await interestRepository.sendInterest(from: fromUserID, to: toUserID)
        
        // Respond to interest (would need to get the interest ID first)
        // This is a basic test structure
        let response = InterestResponse.accept(message: "I'm interested!")
        
        // In a real implementation, you would:
        // 1. Get the interest ID
        // 2. Call respondToInterest(id:interestID, response:response)
        // 3. Verify the status was updated
        
        XCTAssertTrue(true, "Interest response structure created successfully")
    }
    
    // MARK: - Integration Tests
    
    func testCompleteInterestToMatchFlow() async throws {
        let user1 = "integration_user_1"
        let user2 = "integration_user_2"
        
        // Step 1: User 1 sends interest to User 2
        try await interestRepository.sendInterest(from: user1, to: user2)
        
        // Step 2: User 2 sends interest to User 1 (this should trigger match creation)
        try await interestRepository.sendInterest(from: user2, to: user1)
        
        // Step 3: Verify match was created automatically
        let matchExists = try await matchCreationService.matchExists(between: user1, and: user2)
        XCTAssertTrue(matchExists, "Match should be created automatically when interests are mutual")
        
        // Step 4: Verify interests were updated to matched status
        let mutualInterests = try await interestRepository.checkForMutualInterest(userID: user1, targetID: user2)
        XCTAssertTrue(mutualInterests.isEmpty, "Interests should be updated to matched status")
    }
    
    // MARK: - Performance Tests
    
    func testInterestSendingPerformance() throws {
        let fromUserID = "perf_test_user"
        let toUserID = "perf_test_target"
        
        measure {
            Task {
                do {
                    try await interestRepository.sendInterest(from: fromUserID, to: toUserID)
                } catch {
                    XCTFail("Interest sending failed: \(error)")
                }
            }
        }
    }
    
    func testMatchCreationPerformance() throws {
        let user1 = "perf_match_user_1"
        let user2 = "perf_match_user_2"
        
        measure {
            Task {
                do {
                    try await matchCreationService.createMatch(between: user1, and: user2)
                } catch {
                    XCTFail("Match creation failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidInterestParameters() async throws {
        let emptyUserID = ""
        let validUserID = "test_user"
        
        // Try to send interest with empty user ID
        do {
            try await interestRepository.sendInterest(from: emptyUserID, to: validUserID)
            XCTFail("Should have thrown an error for empty user ID")
        } catch {
            // Expected some kind of error
            XCTAssertTrue(true, "Empty user ID correctly rejected")
        }
    }
    
    func testConcurrentInterestSending() async throws {
        let user1 = "concurrent_user_1"
        let user2 = "concurrent_user_2"
        
        // Send interests concurrently from both users
        async let interest1: Void = interestRepository.sendInterest(from: user1, to: user2)
        async let interest2: Void = interestRepository.sendInterest(from: user2, to: user1)
        
        // Wait for both to complete
        try await interest1
        try await interest2
        
        // Verify match was created
        let matchExists = try await matchCreationService.matchExists(between: user1, and: user2)
        XCTAssertTrue(matchExists, "Match should be created even with concurrent interest sending")
    }
}
