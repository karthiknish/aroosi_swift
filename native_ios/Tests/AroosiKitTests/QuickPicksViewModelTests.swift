@testable import AroosiKit
import XCTest

@MainActor
final class QuickPicksViewModelTests: XCTestCase {
    func test_load_success_populatesRecommendationsAndCompatibility() async {
        let repository = MockQuickPicksRepository()
        let recommendation = QuickPickRecommendation(id: "user-1", profile: .fixture(id: "user-1"))
        repository.fetchQuickPicksResult = .success([recommendation])
        repository.compatibilityScores = ["user-1": 72]

        let viewModel = QuickPicksViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.state.recommendations, [recommendation])
        XCTAssertEqual(viewModel.state.currentRecommendation?.id, "user-1")
        XCTAssertEqual(viewModel.state.compatibility(for: "user-1"), 72)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func test_load_error_setsErrorMessage() async {
        let repository = MockQuickPicksRepository()
        repository.fetchQuickPicksResult = .failure(TestError.sample)

        let viewModel = QuickPicksViewModel(repository: repository)

        await viewModel.load()

        XCTAssertTrue(viewModel.state.recommendations.isEmpty)
        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func test_likeCurrent_invokesRepositoryAndAdvances() async {
        let repository = MockQuickPicksRepository()
        repository.fetchQuickPicksResult = .success([
            QuickPickRecommendation(id: "one", profile: .fixture(id: "one"))
        ])

        let viewModel = QuickPicksViewModel(repository: repository)
        await viewModel.load()

        await viewModel.likeCurrent()

        XCTAssertEqual(repository.acted.count, 1)
        XCTAssertEqual(repository.acted.first?.0, "one")
        XCTAssertEqual(repository.acted.first?.1, .like)
        XCTAssertEqual(viewModel.state.likesUsed, 1)
        XCTAssertNil(viewModel.state.currentRecommendation)
        XCTAssertNotNil(viewModel.state.infoMessage)
    }

    func test_skipCurrent_invokesRepositoryWithoutConsumingLike() async {
        let repository = MockQuickPicksRepository()
        repository.fetchQuickPicksResult = .success([
            QuickPickRecommendation(id: "skip-me", profile: .fixture(id: "skip-me")),
            QuickPickRecommendation(id: "next", profile: .fixture(id: "next"))
        ])

        let viewModel = QuickPicksViewModel(repository: repository)
        await viewModel.load()

        await viewModel.skipCurrent()

        XCTAssertEqual(repository.acted.count, 1)
        XCTAssertEqual(repository.acted.first?.1, .skip)
        XCTAssertEqual(viewModel.state.likesUsed, 0)
        XCTAssertEqual(viewModel.state.currentRecommendation?.id, "next")
    }
}

// MARK: - Helpers

@MainActor
private final class MockQuickPicksRepository: QuickPicksRepository {
    var fetchQuickPicksResult: Result<[QuickPickRecommendation], Error> = .success([])
    var compatibilityScores: [String: Int] = [:]
    var acted: [(String, QuickPickAction)] = []

    func fetchQuickPicks(dayKey: String?) async throws -> [QuickPickRecommendation] {
        switch fetchQuickPicksResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func act(on userID: String, action: QuickPickAction) async throws {
        acted.append((userID, action))
        if let error = actionError { throw error }
    }

    func fetchCompatibilityScore(for userID: String) async throws -> Int {
        if let error = compatibilityError {
            throw error
        }
        return compatibilityScores[userID] ?? 0
    }

    var actionError: Error?
    var compatibilityError: Error?
}

private extension ProfileSummary {
    static func fixture(id: String) -> ProfileSummary {
        ProfileSummary(id: id,
                       displayName: "Test User",
                       age: 30,
                       location: "Seattle",
                       bio: nil,
                       avatarURL: nil,
                       interests: [])
    }
}

private enum TestError: Error {
    case sample
}
