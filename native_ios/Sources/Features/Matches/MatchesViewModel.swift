import Combine
import Foundation

@available(iOS 17, *)
@MainActor
final class MatchesViewModel: ObservableObject {
    struct State: Equatable {
        var items: [MatchListItem] = []
        var isLoading: Bool = false
        var errorMessage: String?

        var isEmpty: Bool {
            !isLoading && errorMessage == nil && items.isEmpty
        }
    }

    struct MatchListItem: Identifiable, Equatable, Hashable {
        let id: String
        let match: Match
        let counterpartProfile: ProfileSummary?
        let unreadCount: Int

        var lastMessagePreview: String? { match.lastMessagePreview }
        var lastUpdatedAt: Date { match.lastUpdatedAt }

        static func == (lhs: MatchListItem, rhs: MatchListItem) -> Bool { lhs.id == rhs.id }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    @Published private(set) var state = State()

    private let matchRepository: MatchRepository
    private let profileRepository: ProfileRepository
    private let chatThreadRepository: ChatThreadRepository?
    private let logger = Logger.shared

    private var matchStreamTask: Task<Void, Never>?
    private var chatStreamTask: Task<Void, Never>?
    private var currentUserID: String?
    private var profileCache: [String: ProfileSummary] = [:]
    private var unreadCounts: [String: Int] = [:]
    private var latestMatches: [Match] = []

    init(matchRepository: MatchRepository = FirestoreMatchRepository(),
         profileRepository: ProfileRepository = FirestoreProfileRepository(),
         chatThreadRepository: ChatThreadRepository? = FirestoreChatThreadRepository()) {
        self.matchRepository = matchRepository
        self.profileRepository = profileRepository
        self.chatThreadRepository = chatThreadRepository
    }

    deinit {
        matchStreamTask?.cancel()
        chatStreamTask?.cancel()
    }

    func observeMatches(for userID: String) {
        currentUserID = userID
        profileCache.removeAll()
        unreadCounts.removeAll()
        latestMatches.removeAll()

        state.isLoading = true
        state.errorMessage = nil
        state.items = []

        matchStreamTask?.cancel()
        matchStreamTask = Task { [weak self] in
            guard let self else { return }
            defer { self.state.isLoading = false }

            do {
                for try await matches in self.matchRepository.streamMatches(for: userID) {
                    try Task.checkCancellation()
                    await self.ensureProfiles(for: matches, currentUserID: userID)

                    self.latestMatches = matches
                    self.state.items = self.buildItems(from: matches, currentUserID: userID)
                    self.state.isLoading = false
                }
            } catch {
                if (error as? CancellationError) != nil { return }
                self.logger.error("Failed to observe matches: \(error.localizedDescription)")
                self.state.errorMessage = "We couldn't load matches right now. Please try again later."
            }
        }

        chatStreamTask?.cancel()
        if let chatThreadRepository {
            chatStreamTask = Task { [weak self] in
                guard let self else { return }

                do {
                    for try await threads in chatThreadRepository.streamThreads(for: userID) {
                        try Task.checkCancellation()
                        self.applyUnreadCounts(from: threads, currentUserID: userID)
                    }
                } catch {
                    if (error as? CancellationError) != nil { return }
                    self.logger.error("Failed to observe chat threads: \(error.localizedDescription)")
                }
            }
        } else {
            chatStreamTask = nil
        }
    }

    func stopObserving() {
        matchStreamTask?.cancel()
        matchStreamTask = nil
        chatStreamTask?.cancel()
        chatStreamTask = nil
    }

    func refresh() {
        guard let userID = currentUserID else { return }
        observeMatches(for: userID)
    }

    func updateUnreadCount(for matchID: String, count: Int) {
        unreadCounts[matchID] = count
        guard let userID = currentUserID else { return }
        state.items = buildItems(from: latestMatches, currentUserID: userID)
    }

    private func applyUnreadCounts(from threads: [ChatThread], currentUserID: String) {
        var nextCounts = unreadCounts

        for thread in threads {
            nextCounts[thread.matchID] = thread.unreadCountForUser(currentUserID)
        }

        let knownMatchIDs = Set(latestMatches.map { $0.id })
        var pruned: [String: Int] = [:]
        for (matchID, count) in nextCounts where knownMatchIDs.contains(matchID) {
            pruned[matchID] = count
        }

        unreadCounts = pruned
        state.items = buildItems(from: latestMatches, currentUserID: currentUserID)
    }

    private func ensureProfiles(for matches: [Match], currentUserID: String) async {
        let participantIDs = matches.flatMap { $0.participantIDs }
        let counterpartIDs = Set(participantIDs.filter { $0 != currentUserID })
        let missingIDs = counterpartIDs.filter { profileCache[$0] == nil }

        guard !missingIDs.isEmpty else { return }

        for id in missingIDs {
            if Task.isCancelled { return }
            do {
                let profile = try await profileRepository.fetchProfile(id: id)
                profileCache[id] = profile
            } catch {
                logger.error("Unable to fetch profile for match participant \(id): \(error.localizedDescription)")
            }
        }
    }

    private func buildItems(from matches: [Match], currentUserID: String) -> [MatchListItem] {
        var items: [MatchListItem] = []
        items.reserveCapacity(matches.count)

        for match in matches {
            let counterpartID = match.participantIDs.first { $0 != currentUserID }
            let profile = counterpartID.flatMap { profileCache[$0] }
            let unread = unreadCounts[match.id] ?? 0
            items.append(MatchListItem(id: match.id, match: match, counterpartProfile: profile, unreadCount: unread))
        }

        return items.sorted { $0.lastUpdatedAt > $1.lastUpdatedAt }
    }
}
