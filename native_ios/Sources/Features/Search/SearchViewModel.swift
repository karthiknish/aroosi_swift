import Foundation

@available(iOS 17, *)
@MainActor
final class SearchViewModel: ObservableObject {
    struct State: Equatable {
        var query: String = ""
        var items: [ProfileSummary] = []
        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var hasMore: Bool = false
        var errorMessage: String?
        var infoMessage: String?
        var sentInterestIDs: Set<String> = []
        var sendingInterestIDs: Set<String> = []

        var isEmpty: Bool {
            !isLoading && !isLoadingMore && items.isEmpty && errorMessage == nil
        }

        func isSendingInterest(for profileID: String) -> Bool {
            sendingInterestIDs.contains(profileID)
        }

        func hasSentInterest(to profileID: String) -> Bool {
            sentInterestIDs.contains(profileID)
        }
    }

    @Published private(set) var state = State()

    private let searchRepository: ProfileSearchRepository
    private let interestRepository: InterestRepository
    private let matchCreationService: MatchCreationService
    private let pageSize: Int
    private var searchTask: Task<Void, Never>?
    private var activeFilters: SearchFilters
    private var nextCursor: String?
    private var currentUserID: String?

    init(searchRepository: ProfileSearchRepository = FirestoreProfileSearchRepository(),
         interestRepository: InterestRepository = FirestoreInterestRepository(),
         matchCreationService: MatchCreationService = MatchCreationService(),
         pageSize: Int = 20,
         filters: SearchFilters = SearchFilters()) {
        self.searchRepository = searchRepository
        self.interestRepository = interestRepository
        self.matchCreationService = matchCreationService
        self.pageSize = pageSize
        self.activeFilters = filters.updating(pageSize: pageSize)
    }

    var currentFilters: SearchFilters {
        activeFilters
    }

    func configure(userID: String) {
        let shouldRefresh = currentUserID != userID || state.items.isEmpty
        currentUserID = userID
        if shouldRefresh {
            refresh()
        }
    }

    func updateQuery(_ query: String) {
        state.query = query
    }

    func submitSearch() {
        refresh()
    }

    func refresh() {
        performSearch(resetCursor: true)
    }

    func loadMore() {
        guard state.hasMore, !state.isLoadingMore else { return }
        performSearch(resetCursor: false)
    }

    func sendInterest(to profile: ProfileSummary) {
        guard let currentUserID = currentUserID,
              profile.id != currentUserID,
              !state.sendingInterestIDs.contains(profile.id),
              !state.sentInterestIDs.contains(profile.id) else { return }

        state.sendingInterestIDs.insert(profile.id)
        state.errorMessage = nil

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.state.sendingInterestIDs.remove(profile.id) }

            do {
                try await self.interestRepository.sendInterest(from: currentUserID, to: profile.id)
                self.state.sentInterestIDs.insert(profile.id)
                self.state.infoMessage = "Interest sent to \(profile.displayName)."
            } catch {
                self.state.errorMessage = "We couldn't send interest right now. Please try again later."
            }
        }
    }

    func dismissInfoMessage() {
        state.infoMessage = nil
    }

    func apply(filters: SearchFilters) {
        activeFilters = filters.updating(pageSize: pageSize)
        refresh()
    }

    func resetFilters() {
        activeFilters = SearchFilters().updating(pageSize: pageSize)
        refresh()
    }

    private func performSearch(resetCursor: Bool) {
        searchTask?.cancel()

        if resetCursor {
            nextCursor = nil
            state.isLoading = true
            state.errorMessage = nil
            state.infoMessage = nil
        } else {
            state.isLoadingMore = true
        }

        let filters = activeFilters
            .updating(pageSize: pageSize)
            .updating(query: state.query)

        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                self.state.isLoading = false
                self.state.isLoadingMore = false
                self.searchTask = nil
            }

            do {
                let page = try await self.searchRepository.searchProfiles(
                    filters: filters,
                    pageSize: self.pageSize,
                    cursor: resetCursor ? nil : self.nextCursor
                )

                let filteredItems = page.items.filter { $0.id != self.currentUserID }

                if resetCursor {
                    self.state.items = filteredItems
                } else {
                    var existing = self.state.items
                    let existingIDs = Set(existing.map { $0.id })
                    for item in filteredItems where !existingIDs.contains(item.id) {
                        existing.append(item)
                    }
                    self.state.items = existing
                }

                self.nextCursor = page.nextCursor
                self.state.hasMore = page.hasMore
                self.state.errorMessage = nil

                if self.state.items.isEmpty {
                    if let query = filters.trimmedQuery, !query.isEmpty {
                        self.state.infoMessage = "No results for \"\(query)\" yet. Try adjusting your search."
                    } else {
                        self.state.infoMessage = "No profiles to show yet. Pull to refresh to try again."
                    }
                } else {
                    self.state.infoMessage = nil
                }
            } catch {
                if (error as? CancellationError) != nil { return }
                self.state.errorMessage = "We couldn't load profiles right now. Please try again later."
            }
        }
    }
    
    // MARK: - Like/Pass Actions
    
    func likeProfile(_ profile: ProfileSummary) {
        guard let currentUserID = currentUserID else { return }
        
        Task {
            state.sendingInterestIDs.insert(profile.id)
            
            do {
                try await interestRepository.sendInterest(
                    from: currentUserID,
                    to: profile.id
                )
                state.sentInterestIDs.insert(profile.id)
            } catch {
                // Silently fail - user can retry
            }
            
            state.sendingInterestIDs.remove(profile.id)
        }
    }
    
    func passProfile(_ profile: ProfileSummary) {
        // Track pass action for analytics/algorithm
        // For now, just remove from current view
        state.items.removeAll { $0.id == profile.id }
    }
}
