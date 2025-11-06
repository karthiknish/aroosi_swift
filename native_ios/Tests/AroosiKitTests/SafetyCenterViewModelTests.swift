import XCTest
@testable import AroosiKit

@available(iOS 17, macOS 13, *)
@MainActor
final class SafetyCenterViewModelTests: XCTestCase {
    func testLoadSuccessPopulatesBlockedUsers() async {
        let blocked = BlockedUser(id: "user-1", displayName: "Layla", avatarURL: nil, blockedAt: nil)
        let repository = MockSafetyRepository(blockedUsers: [blocked])
        let viewModel = SafetyCenterViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.state.blockedUsers, [blocked])
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testLoadFailureSetsErrorMessage() async {
        let repository = MockSafetyRepository(blockedUsers: [], shouldThrow: true)
        let viewModel = SafetyCenterViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.blockedUsers.isEmpty)
    }

    func testUnblockRemovesUser() async {
        let blocked = BlockedUser(id: "user-1", displayName: "Layla", avatarURL: nil, blockedAt: nil)
        let repository = MockSafetyRepository(blockedUsers: [blocked])
        let viewModel = SafetyCenterViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.unblock(blocked)

        XCTAssertTrue(viewModel.state.blockedUsers.isEmpty)
        XCTAssertEqual(repository.unblockedUserIDs, ["user-1"])
    }
}

@available(iOS 17, macOS 13, *)
private final class MockSafetyRepository: SafetyRepository {
    var blockedUsers: [BlockedUser]
    var shouldThrow: Bool
    var unblockedUserIDs: [String] = []

    init(blockedUsers: [BlockedUser], shouldThrow: Bool = false) {
        self.blockedUsers = blockedUsers
        self.shouldThrow = shouldThrow
    }

    func fetchBlockedUsers() async throws -> [BlockedUser] {
        if shouldThrow { throw RepositoryError.networkFailure }
        return blockedUsers
    }

    func block(userID: String) async throws {}

    func unblock(userID: String) async throws {
        unblockedUserIDs.append(userID)
        blockedUsers.removeAll { $0.id == userID }
    }

    func report(userID: String, reason: String, details: String?) async throws {}

    func status(for userID: String) async throws -> SafetyStatus { SafetyStatus() }

    func fetchSubmittedReports() async throws -> [SafetyReport] {
        if shouldThrow { throw RepositoryError.networkFailure }
        return []
    }
}
