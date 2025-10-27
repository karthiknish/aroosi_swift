import XCTest
@testable import AroosiKit

@available(iOS 17, macOS 13, *)
@MainActor
final class DashboardViewModelTests: XCTestCase {
    func testLoadPopulatesState() async {
        let profile = ProfileSummary(id: "user-1",
                                     displayName: "Aisha",
                                     age: 30,
                                     location: "Seattle",
                                     bio: nil,
                                     avatarURL: nil,
                                     interests: ["Travel"])

        let match = Match(id: "match-1",
                          participants: [
                              Match.Participant(userID: "user-1", isInitiator: true),
                              Match.Participant(userID: "user-2", isInitiator: false)
                          ],
                          status: .active,
                          lastMessagePreview: "Salaam!",
                          lastUpdatedAt: Date(timeIntervalSince1970: 1_700_000_000),
                          conversationID: "conversation-1")

        let counterpart = ProfileSummary(id: "user-2",
                                         displayName: "Nadia",
                                         age: 29,
                                         location: "Austin",
                                         bio: nil,
                                         avatarURL: nil,
                                         interests: ["Cuisine"])

        let quickPick = ProfileSummary(id: "user-3",
                                       displayName: "Layla",
                                       age: 27,
                                       location: "Chicago",
                                       bio: nil,
                                       avatarURL: nil,
                                       interests: ["Outdoors"])

        let profileRepository = ProfileRepositoryStub(profiles: ["user-1": profile, "user-2": counterpart])
        let matchRepository = MatchRepositoryStub(matches: [match])
        let thread = ChatThread(id: "thread-1",
                                matchID: match.id,
                                participantIDs: ["user-1", "user-2"],
                                lastMessage: nil,
                                unreadCount: 0,
                                unreadCounts: ["user-1": 2],
                                lastActivityAt: Date())
        let chatThreadRepository = ChatThreadRepositoryStub(threads: [thread])
        let searchRepository = ProfileSearchRepositoryStub(page: ProfileSearchPage(items: [quickPick], nextCursor: nil))
        let interestRepository = InterestRepositoryRecorder()

        let viewModel = DashboardViewModel(profileRepository: profileRepository,
                                           matchRepository: matchRepository,
                                           chatThreadRepository: chatThreadRepository,
                                           searchRepository: searchRepository,
                                           interestRepository: interestRepository,
                                           pageSize: 5)

        viewModel.load(for: "user-1")
        await waitForIdle()

        XCTAssertEqual(viewModel.state.profile?.displayName, "Aisha")
        XCTAssertEqual(viewModel.state.activeMatchesCount, 1)
        XCTAssertEqual(viewModel.state.unreadMessagesCount, 2)
        XCTAssertEqual(viewModel.state.recentMatches.count, 1)
        XCTAssertEqual(viewModel.state.recentMatches.first?.counterpartProfile?.displayName, "Nadia")
        XCTAssertEqual(viewModel.state.quickPicks.map { $0.id }, ["user-3"])
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testSendInterestRecordsSuccess() async {
        let profileRepo = ProfileRepositoryStub(profiles: [:])
        let matchRepo = MatchRepositoryStub(matches: [])
        let chatRepo = ChatThreadRepositoryStub(threads: [])
        let quickPick = ProfileSummary(id: "user-2",
                                       displayName: "Zara",
                                       age: nil,
                                       location: nil,
                                       bio: nil,
                                       avatarURL: nil,
                                       interests: [])
        let searchRepo = ProfileSearchRepositoryStub(page: ProfileSearchPage(items: [quickPick], nextCursor: nil))
        let interestRepo = InterestRepositoryRecorder()

        let viewModel = DashboardViewModel(profileRepository: profileRepo,
                                           matchRepository: matchRepo,
                                           chatThreadRepository: chatRepo,
                                           searchRepository: searchRepo,
                                           interestRepository: interestRepo,
                                           pageSize: 5)

        viewModel.load(for: "user-1")
        await waitForIdle()

        guard let recommended = viewModel.state.quickPicks.first else {
            XCTFail("Expected quick pick")
            return
        }

        viewModel.sendInterest(to: recommended)
        await waitForIdle()

        XCTAssertTrue(interestRepo.sentInterests.contains(where: { $0.from == "user-1" && $0.to == recommended.id }))
        XCTAssertTrue(viewModel.state.hasSentInterest(to: recommended.id))
        XCTAssertNil(viewModel.state.sendingInterestIDs.first)
    }

    func testRefreshClearsRefreshingState() async {
        let profileRepo = ProfileRepositoryStub(profiles: [:])
        let matchRepo = MatchRepositoryStub(matches: [])
        let chatRepo = ChatThreadRepositoryStub(threads: [])
        let searchRepo = ProfileSearchRepositoryStub(page: ProfileSearchPage(items: [], nextCursor: nil))
        let interestRepo = InterestRepositoryRecorder()

        let viewModel = DashboardViewModel(profileRepository: profileRepo,
                                           matchRepository: matchRepo,
                                           chatThreadRepository: chatRepo,
                                           searchRepository: searchRepo,
                                           interestRepository: interestRepo,
                                           pageSize: 5)

        viewModel.load(for: "user-1")
        await waitForIdle()

        viewModel.refresh()
        await waitForIdle()

        XCTAssertFalse(viewModel.state.isRefreshing)
    }

    private func waitForIdle() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}

@available(iOS 15.0, macOS 12.0, *)
private final class ProfileRepositoryStub: ProfileRepository {
    private let profiles: [String: ProfileSummary]

    init(profiles: [String: ProfileSummary]) {
        self.profiles = profiles
    }

    func fetchProfile(id: String) async throws -> ProfileSummary {
        if let profile = profiles[id] {
            return profile
        }
        throw RepositoryError.notFound
    }

    func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func updateProfile(_ profile: ProfileSummary) async throws {}

    func fetchShortlist(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        ProfileSearchPage(items: [], nextCursor: nil)
    }

    func toggleShortlist(userID: String) async throws -> ShortlistToggleResult {
        ShortlistToggleResult(action: .added)
    }

    func setShortlistNote(userID: String, note: String) async throws {}

    func fetchFavorites(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        ProfileSearchPage(items: [], nextCursor: nil)
    }

    func toggleFavorite(userID: String) async throws {}
}

@available(iOS 15.0, macOS 12.0, *)
private final class MatchRepositoryStub: MatchRepository {
    private let matches: [Match]

    init(matches: [Match]) {
        self.matches = matches
    }

    func fetchMatch(id: String) async throws -> Match {
        if let match = matches.first(where: { $0.id == id }) {
            return match
        }
        throw RepositoryError.notFound
    }

    func streamMatches(for userID: String) -> AsyncThrowingStream<[Match], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(matches)
            continuation.finish()
        }
    }

    func updateMatch(_ match: Match) async throws {}
}

@available(iOS 15.0, macOS 12.0, *)
private final class ChatThreadRepositoryStub: ChatThreadRepository {
    private let threads: [ChatThread]

    init(threads: [ChatThread]) {
        self.threads = threads
    }

    func fetchThread(id: String) async throws -> ChatThread {
        if let thread = threads.first(where: { $0.id == id }) {
            return thread
        }
        throw RepositoryError.notFound
    }

    func streamThreads(for userID: String) -> AsyncThrowingStream<[ChatThread], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(threads)
            continuation.finish()
        }
    }

    func upsertThread(_ thread: ChatThread) async throws {}
}

@available(iOS 15.0, macOS 12.0, *)
private final class ProfileSearchRepositoryStub: ProfileSearchRepository {
    private let page: ProfileSearchPage

    init(page: ProfileSearchPage) {
        self.page = page
    }

    func searchProfiles(filters: SearchFilters, pageSize: Int, cursor: String?) async throws -> ProfileSearchPage {
        page
    }
}

@available(iOS 15.0, macOS 12.0, *)
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
