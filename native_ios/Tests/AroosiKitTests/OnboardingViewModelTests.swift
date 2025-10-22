import XCTest
@testable import AroosiKit

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func testLoadContentSuccess() async {
        let content = OnboardingContent(title: "Welcome",
                                        tagline: "Find your match",
                                        heroImageURL: URL(string: "https://example.com/hero.png"),
                                        callToActionTitle: "Continue")
        let repository = OnboardingContentRepositoryStub(result: .success(content))
        let viewModel = OnboardingViewModel(repository: repository)

        viewModel.loadContent()
        await waitForIdle()

        XCTAssertEqual(viewModel.state.content, content)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testLoadContentFailureSetsError() async {
        let repository = OnboardingContentRepositoryStub(result: .failure(RepositoryError.networkFailure))
        let viewModel = OnboardingViewModel(repository: repository)

        viewModel.loadContent()
        await waitForIdle()

        XCTAssertNil(viewModel.state.content)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertEqual(viewModel.state.errorMessage, "We couldn't load onboarding content right now.")
    }

    private func waitForIdle() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}

private final class OnboardingContentRepositoryStub: OnboardingContentRepository {
    enum Result {
        case success(OnboardingContent)
        case failure(Error)
    }

    private let result: Result

    init(result: Result) {
        self.result = result
    }

    func fetchContent() async throws -> OnboardingContent {
        switch result {
        case let .success(content):
            return content
        case let .failure(error):
            throw error
        }
    }
}
