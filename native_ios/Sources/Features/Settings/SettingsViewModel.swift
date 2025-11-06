#if os(iOS)
import Foundation

@available(iOS 17, *)
@MainActor
final class SettingsViewModel: ObservableObject {
    struct State: Equatable {
        var profile: ProfileSummary?
        var settings: UserSettings?
        var isLoading: Bool = false
        var isPersisting: Bool = false
        var errorMessage: String?
        var isPerformingAccountAction: Bool = false
        var dangerErrorMessage: String?
    }

    @Published private(set) var state = State()

    private let profileRepository: ProfileRepository
    private let settingsRepository: UserSettingsRepository
    private let authService: AuthProviding
    private let logger = Logger.shared

    private var currentUserID: String?
    private var settingsTask: Task<Void, Never>?

    init(profileRepository: ProfileRepository = FirestoreProfileRepository(),
         settingsRepository: UserSettingsRepository = FirestoreUserSettingsRepository(),
         authService: AuthProviding = FirebaseAuthService.shared) {
        self.profileRepository = profileRepository
        self.settingsRepository = settingsRepository
        self.authService = authService
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

    func signOut() async -> Bool {
        state.isPerformingAccountAction = true
        defer { state.isPerformingAccountAction = false }

        do {
            try authService.signOut()
            state.dangerErrorMessage = nil
            return true
        } catch {
            logger.error("Failed to sign out: \(error.localizedDescription)")
            state.dangerErrorMessage = makeAuthErrorMessage(error)
            return false
        }
    }

    func deleteAccount(password: String?, reason: String?) async -> Bool {
        state.isPerformingAccountAction = true
        defer { state.isPerformingAccountAction = false }

        do {
            try await authService.deleteAccount(password: password, reason: reason)
            state.dangerErrorMessage = nil
            return true
        } catch {
            logger.error("Failed to delete account: \(error.localizedDescription)")
            state.dangerErrorMessage = makeAuthErrorMessage(error)
            return false
        }
    }

    func clearDangerError() {
        state.dangerErrorMessage = nil
    }

    func clearErrors() {
        state.errorMessage = nil
        state.dangerErrorMessage = nil
    }

    private func makeAuthErrorMessage(_ error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return "Something went wrong. Please try again."
    }
}

#endif
