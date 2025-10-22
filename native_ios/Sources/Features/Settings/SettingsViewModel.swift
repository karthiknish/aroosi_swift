import Foundation

@available(macOS 12.0, iOS 17, *)
@MainActor
final class SettingsViewModel: ObservableObject {
    struct State: Equatable {
        var profile: ProfileSummary?
        var settings: UserSettings?
        var isLoading: Bool = false
        var isPersisting: Bool = false
        var errorMessage: String?
    }

    @Published private(set) var state = State()

    private let profileRepository: ProfileRepository
    private let settingsRepository: UserSettingsRepository
    private let logger = Logger.shared

    private var currentUserID: String?
    private var settingsTask: Task<Void, Never>?

    init(profileRepository: ProfileRepository = FirestoreProfileRepository(),
         settingsRepository: UserSettingsRepository = FirestoreUserSettingsRepository()) {
        self.profileRepository = profileRepository
        self.settingsRepository = settingsRepository
    }

    deinit {
        settingsTask?.cancel()
    }

    func observe(userID: String) {
        currentUserID = userID
        state.isLoading = true
        state.errorMessage = nil

        settingsTask?.cancel()
        settingsTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await settings in self.settingsRepository.streamSettings(for: userID) {
                    try Task.checkCancellation()
                    self.state.settings = settings
                    self.state.isLoading = false
                }
            } catch {
                if (error as? CancellationError) != nil { return }
                self.logger.error("Failed to stream settings: \(error.localizedDescription)")
                self.state.errorMessage = "We couldn't load your settings right now."
                self.state.isLoading = false
            }
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let profile = try await self.profileRepository.fetchProfile(id: userID)
                self.state.profile = profile
            } catch {
                self.logger.error("Failed to load profile for settings: \(error.localizedDescription)")
            }
        }
    }

    func refresh() {
        guard let userID = currentUserID else { return }
        observe(userID: userID)
    }

    func updatePushNotificationsEnabled(_ isEnabled: Bool) {
        guard var settings = state.settings else { return }
        let previous = settings
        settings.pushNotificationsEnabled = isEnabled
        state.settings = settings
        persist(settings, previous: previous)
    }

    func updateEmailUpdatesEnabled(_ isEnabled: Bool) {
        guard var settings = state.settings else { return }
        let previous = settings
        settings.emailUpdatesEnabled = isEnabled
        state.settings = settings
        persist(settings, previous: previous)
    }

    private func persist(_ settings: UserSettings, previous: UserSettings) {
        state.isPersisting = true
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.settingsRepository.updateSettings(settings)
                self.state.isPersisting = false
            } catch {
                self.logger.error("Failed to update settings: \(error.localizedDescription)")
                self.state.errorMessage = "We couldn't update your settings. Please try again."
                self.state.settings = previous
                self.state.isPersisting = false
            }
        }
    }
}
