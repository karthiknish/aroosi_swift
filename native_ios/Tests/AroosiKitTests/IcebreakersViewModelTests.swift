@testable import AroosiKit
import XCTest

@available(iOS 17, macOS 13, *)
@MainActor
final class IcebreakersViewModelTests: XCTestCase {
    func testLoadSuccessPopulatesItems() async {
        let repository = IcebreakerRepositoryStub()
        repository.items = [
            IcebreakerItem(id: "q1", text: "Question 1"),
            IcebreakerItem(id: "q2", text: "Question 2", currentAnswer: "Hello", isAnswered: true)
        ]

        let viewModel = IcebreakersViewModel(repository: repository)
        viewModel.load(for: "user")
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.state.items.count, 2)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testLoadFailureSetsErrorMessage() async {
        let repository = IcebreakerRepositoryStub()
        repository.error = RepositoryError.networkFailure

        let viewModel = IcebreakersViewModel(repository: repository)
        viewModel.load(for: "user")
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.items.isEmpty)
    }

    func testSubmitAnswerUpdatesItem() async {
        let repository = IcebreakerRepositoryStub()
        repository.items = [IcebreakerItem(id: "q1", text: "Question 1")]

        let viewModel = IcebreakersViewModel(repository: repository)
        viewModel.load(for: "user")
        try? await Task.sleep(nanoseconds: 100_000_000)

        await viewModel.submit(answer: "This is my answer", for: "q1")

        XCTAssertEqual(repository.submitCalls.count, 1)
        XCTAssertTrue(viewModel.state.items.first?.isAnswered ?? false)
        XCTAssertEqual(viewModel.state.items.first?.currentAnswer, "This is my answer")
    }
}

private final class IcebreakerRepositoryStub: IcebreakerRepository {
    var items: [IcebreakerItem] = []
    var error: Error?
    var submitCalls: [(questionID: String, answer: String, userID: String)] = []

    func fetchDailyIcebreakers(for userID: String) async throws -> [IcebreakerItem] {
        if let error { throw error }
        return items.isEmpty ? [IcebreakerItem(id: "placeholder", text: "Placeholder question")] : items
    }

    func submitAnswer(_ answer: String, to questionID: String, userID: String) async throws {
        submitCalls.append((questionID, answer, userID))
    }

    func fetchAnswers(for userID: String) async throws -> [IcebreakerAnswer] { [] }
}
