import Foundation
import XCTest
@testable import AroosiKit

@MainActor
final class MatchesViewModelTests: XCTestCase {
    func testObserveMatchesEmitsItems() async {
        let matchRepository = MatchRepositoryStub()
        let profileRepository = ProfileRepositoryStub()
        let chatRepository = ChatThreadRepositoryStub()
        let viewModel = MatchesViewModel(matchRepository: matchRepository,
                                         profileRepository: profileRepository,
                                         chatThreadRepository: chatRepository)

        let otherUser = ProfileSummary(
            id: "user-2",
            displayName: "Nadia",
            age: 28,
            location: "San Francisco",
            bio: "Traveler",
            avatarURL: nil,
            interests: ["Cuisine"],
            lastActiveAt: nil
        )
        profileRepository.setProfile(otherUser)

        viewModel.observeMatches(for: "user-1")
        await Task.yield()
        await Task.yield()

        let match = Match(
            id: "match-1",
            participants: [
                Match.Participant(userID: "user-1", isInitiator: true),
                Match.Participant(userID: "user-2", isInitiator: false)
            ],
            status: .active,
            lastMessagePreview: "Salaam!",
            lastUpdatedAt: Date()
        )

        matchRepository.send([match])

        await waitForState(viewModel) { !$0.isLoading && !$0.items.isEmpty }

        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertEqual(viewModel.state.items.count, 1)
        XCTAssertEqual(viewModel.state.items.first?.counterpartProfile, otherUser)
    }

    func testStreamErrorUpdatesErrorMessage() async {
        let matchRepository = MatchRepositoryStub()
        let profileRepository = ProfileRepositoryStub()
        let chatRepository = ChatThreadRepositoryStub()
        let viewModel = MatchesViewModel(matchRepository: matchRepository,
                                         profileRepository: profileRepository,
                                         chatThreadRepository: chatRepository)

        viewModel.observeMatches(for: "user-1")
        await Task.yield()
        await Task.yield()
        matchRepository.fail(with: TestError.failed)

        await waitForState(viewModel) { !$0.isLoading && $0.errorMessage != nil }

        XCTAssertEqual(viewModel.state.errorMessage, "We couldn't load matches right now. Please try again later.")
    }

    func testUpdateUnreadCountRefreshesItems() async {
        let matchRepository = MatchRepositoryStub()
        let profileRepository = ProfileRepositoryStub()
        let chatRepository = ChatThreadRepositoryStub()
        let viewModel = MatchesViewModel(matchRepository: matchRepository,
                                         profileRepository: profileRepository,
                                         chatThreadRepository: chatRepository)
        profileRepository.setProfile(ProfileSummary(id: "user-2", displayName: "Nadia"))

        viewModel.observeMatches(for: "user-1")
        await Task.yield()
        await Task.yield()

        let match = Match(
            id: "match-1",
            participants: [
                Match.Participant(userID: "user-1", isInitiator: true),
                Match.Participant(userID: "user-2", isInitiator: false)
            ],
            status: .active,
            lastMessagePreview: nil,
            lastUpdatedAt: Date()
        )

        matchRepository.send([match])

        await waitForState(viewModel) { !$0.items.isEmpty }

        viewModel.updateUnreadCount(for: "match-1", count: 4)

        XCTAssertEqual(viewModel.state.items.first?.unreadCount, 4)
    }

    func testChatThreadStreamUpdatesUnreadCount() async {
        let matchRepository = MatchRepositoryStub()
        let profileRepository = ProfileRepositoryStub()
        let chatRepository = ChatThreadRepositoryStub()
        let viewModel = MatchesViewModel(matchRepository: matchRepository,
                                         profileRepository: profileRepository,
                                         chatThreadRepository: chatRepository)

        profileRepository.setProfile(ProfileSummary(id: "user-2", displayName: "Nadia"))

        viewModel.observeMatches(for: "user-1")
        await Task.yield()
        await Task.yield()

        let match = Match(
            id: "match-1",
            participants: [
                Match.Participant(userID: "user-1", isInitiator: true),
                Match.Participant(userID: "user-2", isInitiator: false)
            ],
            status: .active,
            lastMessagePreview: nil,
            lastUpdatedAt: Date(),
            conversationID: "conversation-1"
        )

        matchRepository.send([match])

        await waitForState(viewModel) { !$0.items.isEmpty }

        let thread = ChatThread(
            id: "conversation-1",
            matchID: "match-1",
            participantIDs: ["user-1", "user-2"],
            lastMessage: nil,
            unreadCount: 3,
            unreadCounts: ["user-1": 3, "user-2": 0],
            lastActivityAt: Date()
        )

        chatRepository.send([thread])

        await waitForState(viewModel) { state in
            state.items.first?.unreadCount == 3
        }

        XCTAssertEqual(viewModel.state.items.first?.unreadCount, 3)
    }

    private func waitForState(_ viewModel: MatchesViewModel,
                              timeout: TimeInterval = 1,
                              predicate: @escaping (MatchesViewModel.State) -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if predicate(viewModel.state) { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for view model state to satisfy predicate")
    }
}

private enum TestError: Error {
    case failed
}

@preconcurrency
private final class MatchRepositoryStub: MatchRepository {
    private var continuation: AsyncThrowingStream<[Match], Error>.Continuation?

    func fetchMatch(id: String) async throws -> Match {
        throw RepositoryError.notFound
    }

    func streamMatches(for userID: String) -> AsyncThrowingStream<[Match], Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
        }
    }

    func updateMatch(_ match: Match) async throws {}

    func send(_ matches: [Match]) {
        continuation?.yield(matches)
    }

    func fail(with error: Error) {
        continuation?.finish(throwing: error)
    }
}

@preconcurrency
private final class ProfileRepositoryStub: ProfileRepository {
    var profiles: [String: ProfileSummary] = [:]

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

    func updateProfile(_ profile: ProfileSummary) async throws {
        profiles[profile.id] = profile
    }

    func setProfile(_ profile: ProfileSummary) {
        profiles[profile.id] = profile
    }
}

@preconcurrency
private final class ChatThreadRepositoryStub: ChatThreadRepository {
    private var continuation: AsyncThrowingStream<[ChatThread], Error>.Continuation?

    func fetchThread(id: String) async throws -> ChatThread {
        throw RepositoryError.notFound
    }

    func streamThreads(for userID: String) -> AsyncThrowingStream<[ChatThread], Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
        }
    }

    func upsertThread(_ thread: ChatThread) async throws {}

    func send(_ threads: [ChatThread]) {
        continuation?.yield(threads)
    }

    func fail(with error: Error) {
        continuation?.finish(throwing: error)
    }
}
