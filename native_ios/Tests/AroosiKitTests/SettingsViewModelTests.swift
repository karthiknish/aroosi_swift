import XCTest
@testable import AroosiKit

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testObserveLoadsProfileAndSettings() async {
        let profileRepository = ProfileRepositoryStub()
        let settingsRepository = UserSettingsRepositoryStub()
        let profile = ProfileSummary(id: "user-1", displayName: "Aisha")
        let settings = UserSettings(userID: "user-1", pushNotificationsEnabled: true, emailUpdatesEnabled: false, supportEmail: "help@example.com")
        profileRepository.profiles[profile.id] = profile

        let viewModel = SettingsViewModel(profileRepository: profileRepository,
                                          settingsRepository: settingsRepository)

        viewModel.observe(userID: "user-1")
        await Task.yield()
        settingsRepository.send(settings)
        await waitForState(viewModel) { state in
            state.settings == settings && state.profile == profile
        }

        XCTAssertEqual(viewModel.state.settings, settings)
        XCTAssertEqual(viewModel.state.profile, profile)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testUpdatePushNotificationsPersistsChanges() async {
        let profileRepository = ProfileRepositoryStub()
        let settingsRepository = UserSettingsRepositoryStub()
        let initial = UserSettings(userID: "user-1", pushNotificationsEnabled: false, emailUpdatesEnabled: false)
        settingsRepository.send(initial)

        let viewModel = SettingsViewModel(profileRepository: profileRepository,
                                          settingsRepository: settingsRepository)
        viewModel.observe(userID: "user-1")
        await waitForState(viewModel) { $0.settings != nil }

        viewModel.updatePushNotificationsEnabled(true)
        await waitForPersist(viewModel)

        XCTAssertTrue(viewModel.state.settings?.pushNotificationsEnabled ?? false)
        XCTAssertEqual(settingsRepository.updateCalls.last?.pushNotificationsEnabled, true)
    }

    func testUpdateFailureRevertsState() async {
        let profileRepository = ProfileRepositoryStub()
        let settingsRepository = UserSettingsRepositoryStub()
        settingsRepository.shouldFailUpdate = true
        let initial = UserSettings(userID: "user-1", pushNotificationsEnabled: false, emailUpdatesEnabled: false)
        settingsRepository.send(initial)

        let viewModel = SettingsViewModel(profileRepository: profileRepository,
                                          settingsRepository: settingsRepository)
        viewModel.observe(userID: "user-1")
        await waitForState(viewModel) { $0.settings != nil }

        viewModel.updatePushNotificationsEnabled(true)
        await waitForPersist(viewModel)

        XCTAssertEqual(viewModel.state.settings?.pushNotificationsEnabled, false)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    private func waitForState(_ viewModel: SettingsViewModel,
                              timeout: TimeInterval = 1,
                              predicate: @escaping (SettingsViewModel.State) -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if predicate(viewModel.state) { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for settings state to satisfy predicate")
    }

    private func waitForPersist(_ viewModel: SettingsViewModel,
                                 timeout: TimeInterval = 1) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !viewModel.state.isPersisting { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for settings persist to finish")
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

    func updateProfile(_ profile: ProfileSummary) async throws {}
}

@preconcurrency
private final class UserSettingsRepositoryStub: UserSettingsRepository {
    private var continuation: AsyncThrowingStream<UserSettings, Error>.Continuation?
    private var pendingSettings: [UserSettings] = []
    var updateCalls: [UserSettings] = []
    var shouldFailUpdate: Bool = false

    func streamSettings(for userID: String) -> AsyncThrowingStream<UserSettings, Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
            for settings in self.pendingSettings {
                continuation.yield(settings)
            }
            self.pendingSettings.removeAll()
        }
    }

    func updateSettings(_ settings: UserSettings) async throws {
        if shouldFailUpdate {
            throw RepositoryError.networkFailure
        }
        updateCalls.append(settings)
    }

    func send(_ settings: UserSettings) {
        if let continuation {
            continuation.yield(settings)
        } else {
            pendingSettings.append(settings)
        }
    }
}
