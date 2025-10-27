import Foundation

@available(iOS 17, *)
@MainActor
final class FavoritesViewModel: ObservableObject {
    struct State: Equatable {
        var items: [ProfileSummary] = []
        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var errorMessage: String?
        var nextCursor: String?

        var isEmpty: Bool {
            !isLoading && items.isEmpty && errorMessage == nil
        }
    }

    @Published private(set) var state = State()

    private let profileRepository: ProfileRepository
    private let pageSize: Int
    private var loadTask: Task<Void, Never>?

    init(profileRepository: ProfileRepository = FirestoreProfileRepository(),
         pageSize: Int = 20) {
        self.profileRepository = profileRepository
        self.pageSize = pageSize
    }

    deinit {
        loadTask?.cancel()
    }

    func loadIfNeeded() {
        guard state.items.isEmpty else { return }
        refresh()
    }

    func refresh() {
        state.isLoading = true
        state.errorMessage = nil
        state.nextCursor = nil
        performLoad(reset: true)
    }

    func loadMore() {
        guard !state.isLoadingMore, !state.isLoading, state.nextCursor != nil else { return }
        state.isLoadingMore = true
        performLoad(reset: false)
    }

    func toggleFavorite(userID: String) async {
        do {
            try await profileRepository.toggleFavorite(userID: userID)
            state.items.removeAll { $0.id == userID }
        } catch {
            state.errorMessage = "We couldn't update your favorites right now."
        }
    }

    private func performLoad(reset: Bool) {
        loadTask?.cancel()
        loadTask = Task { @MainActor [weak self] in
            guard let self else { return }

            defer {
                self.state.isLoading = false
                self.state.isLoadingMore = false
            }

            do {
                let page = try await self.profileRepository.fetchFavorites(pageSize: self.pageSize,
                                                                           after: reset ? nil : self.state.nextCursor)
                if reset {
                    self.state.items = page.items
                } else {
                    self.state.items.append(contentsOf: page.items)
                }
                self.state.nextCursor = page.nextCursor
                self.state.errorMessage = nil
            } catch {
                if (error as? CancellationError) != nil { return }
                self.state.errorMessage = "We couldn't load favorites right now."
            }
        }
    }
}
