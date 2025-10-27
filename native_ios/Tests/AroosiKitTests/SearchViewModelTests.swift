import XCTest
@testable import AroosiKit

@MainActor
final class SearchViewModelTests: XCTestCase {
    func testInitialSearchSuccess() async {
        let profile = ProfileSummary(id: "2", displayName: "Farah", age: 29, location: "Austin", interests: ["Art"])
        let repository = ProfileSearchRepositoryQueue(pages: [
            ProfileSearchPage(items: [profile], nextCursor: nil)
        ])
        let interestRepository = InterestRepositoryRecorder()
        let viewModel = SearchViewModel(searchRepository: repository,
                                        interestRepository: interestRepository,
                                        pageSize: 10)

        viewModel.configure(userID: "1")
        await waitForIdle()

        XCTAssertEqual(viewModel.state.items, [profile])
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testLoadMoreAppendsResults() async {
        let pageOneProfiles = [
            ProfileSummary(id: "2", displayName: "Farah"),
            ProfileSummary(id: "3", displayName: "Samira")
        ]
        let pageTwoProfiles = [
            ProfileSummary(id: "4", displayName: "Lina")
        ]

        let repository = ProfileSearchRepositoryQueue(pages: [
            ProfileSearchPage(items: pageOneProfiles, nextCursor: "cursor-1"),
            ProfileSearchPage(items: pageTwoProfiles, nextCursor: nil)
        ])
        let viewModel = SearchViewModel(searchRepository: repository,
                                        interestRepository: InterestRepositoryRecorder(),
                                        pageSize: 10)

        viewModel.configure(userID: "current")
        await waitForIdle()

        XCTAssertEqual(viewModel.state.items.map { $0.id }, ["2", "3"])
        XCTAssertTrue(viewModel.state.hasMore)

        viewModel.loadMore()
        await waitForIdle()

        XCTAssertEqual(viewModel.state.items.map { $0.id }, ["2", "3", "4"])
        XCTAssertFalse(viewModel.state.hasMore)
    }

    func testSendInterestMarksProfile() async {
        let repository = ProfileSearchRepositoryQueue(pages: [
            ProfileSearchPage(items: [ProfileSummary(id: "2", displayName: "Farah")], nextCursor: nil)
        ])
        let recorder = InterestRepositoryRecorder()
        let viewModel = SearchViewModel(searchRepository: repository,
                                        interestRepository: recorder,
                                        pageSize: 10)

        viewModel.configure(userID: "current")
        await waitForIdle()

        guard let profile = viewModel.state.items.first else {
            XCTFail("Expected profile in search results")
            return
        }

        viewModel.sendInterest(to: profile)
        await waitForIdle()

        XCTAssertTrue(recorder.sentInterests.contains(where: { $0.to == profile.id }))
        XCTAssertTrue(viewModel.state.hasSentInterest(to: profile.id))
    }

    func testSearchErrorSetsErrorMessage() async {
        let repository = ProfileSearchRepositoryQueue(error: RepositoryError.networkFailure)
        let viewModel = SearchViewModel(searchRepository: repository,
                                        interestRepository: InterestRepositoryRecorder(),
                                        pageSize: 10)

        viewModel.configure(userID: "user-1")
        await waitForIdle()

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.items.isEmpty)
    }

    private func waitForIdle() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}

private final class ProfileSearchRepositoryQueue: ProfileSearchRepository {
    private var pages: [ProfileSearchPage]
    private let error: Error?

    init(pages: [ProfileSearchPage]) {
        self.pages = pages
        self.error = nil
    }

    init(error: Error) {
        self.pages = []
        self.error = error
    }

    func searchProfiles(filters: SearchFilters, pageSize: Int, cursor: String?) async throws -> ProfileSearchPage {
        if let error {
            throw error
        }

        guard !pages.isEmpty else {
            return ProfileSearchPage(items: [], nextCursor: nil)
        }

        return pages.removeFirst()
    }
}

private final class InterestRepositoryRecorder: InterestRepository {
    struct Entry: Equatable {
        let from: String
        let to: String
    }

    private(set) var sentInterests: [Entry] = []

    func sendInterest(from userID: String, to targetUserID: String) async throws {
        sentInterests.append(Entry(from: userID, to: targetUserID))
    }
}
