import Combine
import Foundation

@available(macOS 12.0, iOS 17, *)
@MainActor
final class ProfileViewModel: ObservableObject {
    struct State: Equatable {
        var profile: ProfileSummary?
        var isLoading: Bool = false
        var errorMessage: String?

        var hasContent: Bool {
            profile != nil
        }
    }

    @Published private(set) var state = State()

    private let profileRepository: ProfileRepository
    private let logger = Logger.shared

    private var currentUserID: String?
    private var profileTask: Task<Void, Never>?

    init(profileRepository: ProfileRepository = FirestoreProfileRepository()) {
        self.profileRepository = profileRepository
    }

    deinit {
        profileTask?.cancel()
    }

    func observeProfile(for userID: String) {
        currentUserID = userID
        state.isLoading = true
        state.errorMessage = nil

        profileTask?.cancel()
        profileTask = Task { [weak self] in
            guard let self else { return }

            do {
                var receivedUpdate = false
                for try await profiles in self.profileRepository.streamProfiles(userIDs: [userID]) {
                    try Task.checkCancellation()
                    if let profile = profiles.first(where: { $0.id == userID }) {
                        self.state.profile = profile
                        self.state.isLoading = false
                        receivedUpdate = true
                    }
                }

                if !receivedUpdate {
                    let profile = try await self.profileRepository.fetchProfile(id: userID)
                    self.state.profile = profile
                    self.state.isLoading = false
                }
            } catch {
                if (error as? CancellationError) != nil { return }

                self.logger.error("Failed to observe profile: \(error.localizedDescription)")

                do {
                    let profile = try await self.profileRepository.fetchProfile(id: userID)
                    self.state.profile = profile
                    self.state.errorMessage = nil
                    self.state.isLoading = false
                } catch {
                    self.state.errorMessage = "We couldn't load your profile right now. Pull to retry."
                    self.state.isLoading = false
                }
            }
        }
    }

    func stopObserving() {
        profileTask?.cancel()
        profileTask = nil
    }

    func refresh() {
        guard let userID = currentUserID else { return }
        observeProfile(for: userID)
    }
}
