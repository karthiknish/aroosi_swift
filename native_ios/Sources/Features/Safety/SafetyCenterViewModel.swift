import Foundation

@available(iOS 17, *)
@MainActor
final class SafetyCenterViewModel: ObservableObject {
    struct State: Equatable {
        var blockedUsers: [BlockedUser] = []
        var isLoading = false
        var isRefreshing = false
        var errorMessage: String?
        var isPerformingAction = false

        var hasBlockedUsers: Bool {
            !blockedUsers.isEmpty
        }
    }

    @Published private(set) var state = State()

    private let repository: SafetyRepository

    init(repository: SafetyRepository = FirestoreSafetyRepository()) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard state.blockedUsers.isEmpty, !state.isLoading else { return }
        await load(force: false)
    }

    func refresh() async {
        await load(force: true)
    }

    func unblock(_ user: BlockedUser) async {
        guard !state.isPerformingAction else { return }
        state.isPerformingAction = true
        defer { state.isPerformingAction = false }

        do {
            try await repository.unblock(userID: user.id)
            state.blockedUsers.removeAll { $0.id == user.id }
        } catch {
            state.errorMessage = "Unable to unblock this user right now."
        }
    }

    private func load(force: Bool) async {
        if force {
            state.isRefreshing = true
        } else {
            state.isLoading = true
        }
        state.errorMessage = nil

        defer {
            state.isLoading = false
            state.isRefreshing = false
        }

        do {
            let users = try await repository.fetchBlockedUsers()
            state.blockedUsers = users
        } catch let error as RepositoryError {
            switch error {
            case .permissionDenied:
                state.errorMessage = "Sign in to manage blocked users."
            default:
                state.errorMessage = "Failed to load blocked users. Please try again."
            }
        } catch {
            state.errorMessage = "Failed to load blocked users. Please try again."
        }
    }
}
