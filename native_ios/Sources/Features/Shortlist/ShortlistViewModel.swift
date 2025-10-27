import Foundation

@available(iOS 17, *)
@MainActor
final class ShortlistViewModel: ObservableObject {
    struct State: Equatable {
        var entries: [ShortlistItem] = []
        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var errorMessage: String?
        var nextCursor: String?

        var isEmpty: Bool {
            !isLoading && entries.isEmpty && errorMessage == nil
        }
    }

    struct ShortlistItem: Identifiable, Equatable {
        let id: String
        var profile: ProfileSummary
        var note: String?
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
        guard state.entries.isEmpty else { return }
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

    func toggleShortlist(userID: String) async {
        do {
            let result = try await profileRepository.toggleShortlist(userID: userID)
            if result.action == .removed {
                state.entries.removeAll { $0.id == userID }
            }
        } catch {
            state.errorMessage = "We couldn't update your shortlist right now."
        }
    }

    func updateNote(for userID: String, note: String) async -> Bool {
        do {
            try await profileRepository.setShortlistNote(userID: userID, note: note)
            if let index = state.entries.firstIndex(where: { $0.id == userID }) {
                state.entries[index].note = note
            }
            
            // Show success toast for note saved
            ToastManager.shared.showSuccess("Note saved successfully!")
            
            return true
        } catch {
            state.errorMessage = "We couldn't save your note right now."
            return false
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
                let page = try await self.profileRepository.fetchShortlist(pageSize: self.pageSize,
                                                                           after: reset ? nil : self.state.nextCursor)
                let notes: [String: String]
                if case let .shortlist(map) = page.metadata {
                    notes = map
                } else {
                    notes = [:]
                }

                let items = page.items.map { profile in
                    ShortlistItem(id: profile.id,
                                  profile: profile,
                                  note: notes[profile.id])
                }

                if reset {
                    self.state.entries = items
                } else {
                    self.state.entries.append(contentsOf: items)
                }
                self.state.nextCursor = page.nextCursor
                self.state.errorMessage = nil
            } catch {
                if (error as? CancellationError) != nil { return }
                self.state.errorMessage = "We couldn't load your shortlist right now."
            }
        }
    }
}
