import XCTest
@testable import AroosiKit

@MainActor
@available(iOS 17, macOS 13, *)
final class FavoritesShortlistViewModelTests: XCTestCase {
    func testFavoritesRefreshLoadsProfiles() async {
        let repository = ProfileRepositoryFavoritesStub()
        repository.favoritesResponses = [
            ProfileSearchPage(items: [
                ProfileSummary(id: "u1", displayName: "Layla"),
                ProfileSummary(id: "u2", displayName: "Amina")
            ], nextCursor: "cursor-1"),
        ]

        let viewModel = FavoritesViewModel(profileRepository: repository, pageSize: 10)
        viewModel.refresh()

        await waitUntil(timeout: 1) { !viewModel.state.isLoading }

        XCTAssertEqual(viewModel.state.items.map(\.id), ["u1", "u2"])
        XCTAssertEqual(viewModel.state.nextCursor, "cursor-1")
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testFavoritesLoadMoreAppends() async {
        let repository = ProfileRepositoryFavoritesStub()
        repository.favoritesResponses = [
            ProfileSearchPage(items: [
                ProfileSummary(id: "u1", displayName: "Layla"),
            ], nextCursor: "cursor-1"),
            ProfileSearchPage(items: [
                ProfileSummary(id: "u2", displayName: "Amina"),
            ], nextCursor: nil),
        ]

        let viewModel = FavoritesViewModel(profileRepository: repository, pageSize: 10)
        viewModel.refresh()
        await waitUntil(timeout: 1) { !viewModel.state.isLoading }

        viewModel.loadMore()
        await waitUntil(timeout: 1) { !viewModel.state.isLoadingMore }

        XCTAssertEqual(viewModel.state.items.map(\.id), ["u1", "u2"])
        XCTAssertNil(viewModel.state.nextCursor)
    }

    func testToggleFavoriteRemovesFromState() async {
        let repository = ProfileRepositoryFavoritesStub()
        repository.favoritesResponses = [
            ProfileSearchPage(items: [ProfileSummary(id: "u1", displayName: "Layla")], nextCursor: nil),
        ]

        let viewModel = FavoritesViewModel(profileRepository: repository, pageSize: 10)
        viewModel.refresh()
        await waitUntil(timeout: 1) { !viewModel.state.isLoading }
        XCTAssertEqual(viewModel.state.items.count, 1)

        await viewModel.toggleFavorite(userID: "u1")
        XCTAssertTrue(repository.toggledFavorites.contains("u1"))
        XCTAssertTrue(viewModel.state.items.isEmpty)
    }

    func testShortlistMapsNotes() async {
        let repository = ProfileRepositoryFavoritesStub()
        repository.shortlistResponses = [
            ProfileSearchPage(items: [
                ProfileSummary(id: "u1", displayName: "Layla"),
                ProfileSummary(id: "u2", displayName: "Amina"),
            ],
                                     nextCursor: nil,
                                     metadata: .shortlist(notes: ["u2": "Great conversation"])),
        ]

        let viewModel = ShortlistViewModel(profileRepository: repository, pageSize: 10)
        viewModel.refresh()
        await waitUntil(timeout: 1) { !viewModel.state.isLoading }

        XCTAssertEqual(viewModel.state.entries.count, 2)
        XCTAssertNil(viewModel.state.entries.first { $0.id == "u1" }?.note)
        XCTAssertEqual(viewModel.state.entries.first { $0.id == "u2" }?.note, "Great conversation")
    }

    func testShortlistToggleRemovesEntry() async {
        let repository = ProfileRepositoryFavoritesStub()
        repository.shortlistResponses = [
            ProfileSearchPage(items: [ProfileSummary(id: "u1", displayName: "Layla")], nextCursor: nil,
                                     metadata: .shortlist(notes: [:])),
        ]
        repository.shortlistToggleResults["u1"] = .removed

        let viewModel = ShortlistViewModel(profileRepository: repository, pageSize: 10)
        viewModel.refresh()
        await waitUntil(timeout: 1) { !viewModel.state.isLoading }

        await viewModel.toggleShortlist(userID: "u1")
        XCTAssertTrue(viewModel.state.entries.isEmpty)
        XCTAssertEqual(repository.toggledShortlists, ["u1"])
    }

    func testShortlistUpdateNotePersists() async {
        let repository = ProfileRepositoryFavoritesStub()
        repository.shortlistResponses = [
            ProfileSearchPage(items: [ProfileSummary(id: "u1", displayName: "Layla")], nextCursor: nil,
                                     metadata: .shortlist(notes: [:])),
        ]

        let viewModel = ShortlistViewModel(profileRepository: repository, pageSize: 10)
        viewModel.refresh()
        await waitUntil(timeout: 1) { !viewModel.state.isLoading }

        let result = await viewModel.updateNote(for: "u1", note: "Follow up next week")
        XCTAssertTrue(result)
        XCTAssertEqual(repository.setNotes.first?.userID, "u1")
        XCTAssertEqual(repository.setNotes.first?.note, "Follow up next week")
        XCTAssertEqual(viewModel.state.entries.first?.note, "Follow up next week")
    }

    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            await Task.yield()
        }
        XCTFail("Condition not satisfied within timeout")
    }
}

@preconcurrency
private final class ProfileRepositoryFavoritesStub: ProfileRepository {
    var favoritesResponses: [ProfileSearchPage] = []
    var shortlistResponses: [ProfileSearchPage] = []
    var toggledFavorites: [String] = []
    var toggledShortlists: [String] = []
    var shortlistToggleResults: [String: ShortlistEntry.Action] = [:]
    var setNotes: [(userID: String, note: String)] = []

    func fetchProfile(id: String) async throws -> ProfileSummary {
        ProfileSummary(id: id, displayName: "User")
    }

    func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func updateProfile(_ profile: ProfileSummary) async throws {}

    func fetchShortlist(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        if shortlistResponses.isEmpty {
            return ProfileSearchPage(items: [], nextCursor: nil)
        }
        return shortlistResponses.removeFirst()
    }

    func toggleShortlist(userID: String) async throws -> ShortlistToggleResult {
        toggledShortlists.append(userID)
        let action = shortlistToggleResults[userID] ?? .added
        return ShortlistToggleResult(action: action)
    }

    func setShortlistNote(userID: String, note: String) async throws {
        setNotes.append((userID, note))
    }

    func fetchFavorites(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        if favoritesResponses.isEmpty {
            return ProfileSearchPage(items: [], nextCursor: nil)
        }
        return favoritesResponses.removeFirst()
    }

    func toggleFavorite(userID: String) async throws {
        toggledFavorites.append(userID)
    }
}
