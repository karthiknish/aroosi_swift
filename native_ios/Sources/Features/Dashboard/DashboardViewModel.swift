import Foundation

#if os(iOS)
typealias DashboardMatchListItem = MatchesViewModel.MatchListItem
#else
struct DashboardMatchListItem: Identifiable, Equatable, Hashable {
    let id: String
    let match: Match
    let counterpartProfile: ProfileSummary?
    let unreadCount: Int

    var lastMessagePreview: String? { match.lastMessagePreview }
    var lastUpdatedAt: Date { match.lastUpdatedAt }

    static func == (lhs: DashboardMatchListItem, rhs: DashboardMatchListItem) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
#endif

#if os(iOS)

@available(iOS 17.0.0, *)
@MainActor
public final class DashboardViewModel: ObservableObject {
    struct State: Equatable {
        var profile: ProfileSummary?
        var activeMatchesCount: Int = 0
        var unreadMessagesCount: Int = 0
        var recentMatches: [DashboardMatchListItem] = []
        var quickPicks: [ProfileSummary] = []
        var isLoading: Bool = false
        var isRefreshing: Bool = false
        var errorMessage: String?
        var infoMessage: String?
        var sentInterestIDs: Set<String> = []
        var sendingInterestIDs: Set<String> = []

        func hasSentInterest(to profileID: String) -> Bool {
            sentInterestIDs.contains(profileID)
        }

        func isSendingInterest(for profileID: String) -> Bool {
            sendingInterestIDs.contains(profileID)
        }
    }

    @Published private(set) var state = State()

    private let profileRepository: ProfileRepository
    private let matchRepository: MatchRepositoryWithStreaming
    private let chatThreadRepository: ChatThreadRepository?
    private let searchRepository: ProfileSearchRepository
    private let quickPicksRepository: QuickPicksRepository
    private let interestRepository: InterestRepositoryWithStreaming
    private let matchCreationService: MatchCreationService?
    private let safetyRepository: SafetyRepository
    private let pageSize: Int

    private var currentUserID: String?
    private var profileTask: Task<Void, Never>?
    private var matchStreamTask: Task<Void, Never>?
    private var threadStreamTask: Task<Void, Never>?
    private var quickPicksTask: Task<Void, Never>?

    private var profileCache: [String: ProfileSummary] = [:]
    private var unreadCounts: [String: Int] = [:]
    private var latestMatches: [Match] = []
    private var safetyStatusCache: [String: SafetyStatus] = [:]

    init(profileRepository: ProfileRepository = FirestoreProfileRepository(),
         matchRepository: MatchRepositoryWithStreaming = FirestoreMatchRepository(),
         chatThreadRepository: ChatThreadRepository? = FirestoreChatThreadRepository(),
         searchRepository: ProfileSearchRepository = FirestoreProfileSearchRepository(),
         quickPicksRepository: QuickPicksRepository? = nil,
         interestRepository: InterestRepositoryWithStreaming = FirestoreInterestRepository(),
         matchCreationService: MatchCreationService? = nil,
         safetyRepository: SafetyRepository = FirestoreSafetyRepository(),
         pageSize: Int = 8) {
        self.profileRepository = profileRepository
        self.matchRepository = matchRepository
        self.chatThreadRepository = chatThreadRepository
        self.searchRepository = searchRepository
        if let quickPicksRepository {
            self.quickPicksRepository = quickPicksRepository
        } else if let remote = try? RemoteQuickPicksRepository() {
            self.quickPicksRepository = remote
        } else {
            self.quickPicksRepository = EmptyQuickPicksRepository()
        }
        self.interestRepository = interestRepository
        self.matchCreationService = matchCreationService
        self.safetyRepository = safetyRepository
        self.pageSize = pageSize
    }

    deinit {
        profileTask?.cancel()
        matchStreamTask?.cancel()
        threadStreamTask?.cancel()
        quickPicksTask?.cancel()
    }

    func loadIfNeeded(for userID: String) {
        guard currentUserID != userID || state.profile == nil else { return }
        load(for: userID)
    }

    func load(for userID: String) {
        cancelTasks()
        currentUserID = userID
        profileCache.removeAll()
        unreadCounts.removeAll()
        latestMatches.removeAll()
        state = State(isLoading: true)

        fetchProfile(for: userID)
        observeMatches(for: userID)
        observeThreads(for: userID)
        fetchQuickPicks(for: userID, force: true)
    }

    func refresh() {
        guard let userID = currentUserID else { return }
        state.isRefreshing = true
        fetchProfile(for: userID)
        fetchQuickPicks(for: userID, force: true, completion: { [weak self] in
            self?.state.isRefreshing = false
        })
    }

    func sendInterest(to profile: ProfileSummary) {
        guard let currentUserID = currentUserID,
              profile.id != currentUserID,
              !state.isSendingInterest(for: profile.id),
              !state.hasSentInterest(to: profile.id) else { return }

        state.sendingInterestIDs.insert(profile.id)
        state.infoMessage = nil
        state.errorMessage = nil

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.state.sendingInterestIDs.remove(profile.id) }

            do {
                try await self.interestRepository.sendInterest(from: currentUserID, to: profile.id)
                self.state.sentInterestIDs.insert(profile.id)
                self.state.infoMessage = "Interest sent to \(profile.displayName)."
            } catch let repositoryError as RepositoryError where repositoryError == .alreadyExists {
                self.state.sentInterestIDs.insert(profile.id)
                self.state.infoMessage = "You've already sent interest to \(profile.displayName)."
            } catch {
                self.state.errorMessage = "We couldn't send interest right now. Please try again later."
            }
        }
    }

    func dismissInfoMessage() {
        state.infoMessage = nil
    }

    private func fetchProfile(for userID: String) {
        profileTask?.cancel()
        profileTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let profile = try await self.profileRepository.fetchProfile(id: userID)
                self.state.profile = profile
            } catch RepositoryError.notFound {
                self.state.profile = nil
            } catch {
                self.state.errorMessage = "We couldn't load your profile right now."
            }
        }
    }

    private func observeMatches(for userID: String) {
        matchStreamTask?.cancel()
        matchStreamTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                for try await matches in self.matchRepository.streamMatches(for: userID) {
                    try Task.checkCancellation()
                    await self.ensureProfiles(for: matches, excluding: userID)
                    self.latestMatches = matches
                    self.state.activeMatchesCount = matches.count
                    self.state.recentMatches = self.buildItems(from: matches, currentUserID: userID)
                    self.state.isLoading = false
                }
            } catch {
                if (error as? CancellationError) != nil { return }
                self.state.errorMessage = "We couldn't load your matches right now."
            }
        }
    }

    private func observeThreads(for userID: String) {
        threadStreamTask?.cancel()
        guard let chatThreadRepository else {
            state.unreadMessagesCount = 0
            return
        }

        threadStreamTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                for try await threads in chatThreadRepository.streamThreads(for: userID) {
                    try Task.checkCancellation()
                    self.applyUnreadCounts(from: threads, currentUserID: userID)
                }
            } catch {
                if (error as? CancellationError) != nil { return }
            }
        }
    }

    private func fetchQuickPicks(for userID: String,
                                 force: Bool,
                                 completion: (() -> Void)? = nil) {
        quickPicksTask?.cancel()
        quickPicksTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { completion?() }

            do {
                var recommendations = try await self.quickPicksRepository.fetchQuickPicks(dayKey: nil)
                recommendations.removeAll { $0.id == userID }

                if recommendations.isEmpty {
                    let page = try await self.searchRepository.searchProfiles(
                        filters: SearchFilters(pageSize: self.pageSize),
                        pageSize: self.pageSize,
                        cursor: nil
                    )
                    
                    var filtered: [QuickPickRecommendation] = []
                    for rec in page.items.filter({ $0.id != userID }) {
                        let status = try await self.safetyRepository.status(for: rec.id)
                        if status.canInteract {
                            filtered.append(QuickPickRecommendation(id: rec.id, profile: rec))
                        }
                    }
                    recommendations = filtered
                }

                self.state.quickPicks = Array(recommendations.prefix(self.pageSize)).map { $0.profile }
                self.state.isLoading = false
                if !force, self.state.quickPicks.isEmpty {
                    self.state.infoMessage = "No recommendations yet. Check back soon."
                }
            } catch {
                if (error as? CancellationError) != nil { return }
                self.state.errorMessage = "We couldn't load recommendations right now."
                self.state.isLoading = false
            }
        }
    }

    private func ensureProfiles(for matches: [Match], excluding userID: String) async {
        let counterpartIDs = Set(matches.compactMap { match in
            match.participantIDs.first { $0 != userID }
        })

        let missingIDs = counterpartIDs.filter { profileCache[$0] == nil }
        guard !missingIDs.isEmpty else { return }

        for id in missingIDs {
            if Task.isCancelled { return }
            do {
                let profile = try await profileRepository.fetchProfile(id: id)
                profileCache[id] = profile
                
                // Cache safety status
                let status = try await safetyRepository.status(for: id)
                safetyStatusCache[id] = status
            } catch {
                profileCache[id] = nil
            }
        }
        state.recentMatches = buildItems(from: latestMatches, currentUserID: userID)
    }

    private func buildItems(from matches: [Match], currentUserID: String) -> [DashboardMatchListItem] {
        var items: [DashboardMatchListItem] = []
        items.reserveCapacity(matches.count)

        for match in matches {
            let counterpartID = match.participantIDs.first { $0 != currentUserID }
            guard let id = counterpartID else { continue }
            
            // Skip if interaction not allowed
            let status = safetyStatusCache[id] ?? SafetyStatus()
            guard status.canInteract else { continue }
            
            let profile = profileCache[id]
            let unread = unreadCounts[match.id] ?? 0
            let item = DashboardMatchListItem(id: match.id,
                                              match: match,
                                              counterpartProfile: profile,
                                              unreadCount: unread)
            items.append(item)
        }

        return Array(items.sorted { $0.lastUpdatedAt > $1.lastUpdatedAt }.prefix(3))
    }

    private func applyUnreadCounts(from threads: [ChatThread], currentUserID: String) {
        var nextCounts: [String: Int] = [:]
        for thread in threads {
            nextCounts[thread.matchID] = thread.unreadCountForUser(currentUserID)
        }

        unreadCounts = nextCounts
        state.unreadMessagesCount = nextCounts.values.reduce(0, +)
        state.recentMatches = buildItems(from: latestMatches, currentUserID: currentUserID)
    }

    private func cancelTasks() {
        profileTask?.cancel()
        profileTask = nil
        matchStreamTask?.cancel()
        matchStreamTask = nil
        threadStreamTask?.cancel()
        threadStreamTask = nil
        quickPicksTask?.cancel()
        quickPicksTask = nil
    }
}

@available(iOS 17, macOS 10.15, macCatalyst 13.0, *)
private struct EmptyQuickPicksRepository: QuickPicksRepository {
    func fetchQuickPicks(dayKey: String?) async throws -> [QuickPickRecommendation] { [] }
    func act(on userID: String, action: QuickPickAction) async throws {}
    func fetchCompatibilityScore(for userID: String) async throws -> Int { 0 }
}
#endif
