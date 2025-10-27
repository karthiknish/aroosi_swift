import XCTest
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
@testable import AroosiKit

@available(macOS 13.0, iOS 17.0, *)
@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testObserveLoadsProfileAndSettings() async {
        let profileRepository = ProfileRepositoryStub()
        let settingsRepository = UserSettingsRepositoryStub()
        let authService = AuthServiceStub()
        let subscriptionRepository = SubscriptionRepositoryStub()
        let profile = ProfileSummary(id: "user-1", displayName: "Aisha")
        let settings = UserSettings(userID: "user-1", pushNotificationsEnabled: true, emailUpdatesEnabled: false, supportEmail: "help@example.com")
        profileRepository.profiles[profile.id] = profile

        let viewModel = SettingsViewModel(profileRepository: profileRepository,
                                          settingsRepository: settingsRepository,
                                          authService: authService,
                                          subscriptionRepository: subscriptionRepository)

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
        let authService = AuthServiceStub()
        let subscriptionRepository = SubscriptionRepositoryStub()
        let initial = UserSettings(userID: "user-1", pushNotificationsEnabled: false, emailUpdatesEnabled: false)
        settingsRepository.send(initial)

        let viewModel = SettingsViewModel(profileRepository: profileRepository,
                                          settingsRepository: settingsRepository,
                                          authService: authService,
                                          subscriptionRepository: subscriptionRepository)
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
        let authService = AuthServiceStub()
        let subscriptionRepository = SubscriptionRepositoryStub()
        settingsRepository.shouldFailUpdate = true
        let initial = UserSettings(userID: "user-1", pushNotificationsEnabled: false, emailUpdatesEnabled: false)
        settingsRepository.send(initial)

        let viewModel = SettingsViewModel(profileRepository: profileRepository,
                                          settingsRepository: settingsRepository,
                                          authService: authService,
                                          subscriptionRepository: subscriptionRepository)
        viewModel.observe(userID: "user-1")
        await waitForState(viewModel) { $0.settings != nil }

        viewModel.updatePushNotificationsEnabled(true)
        await waitForPersist(viewModel)

        XCTAssertEqual(viewModel.state.settings?.pushNotificationsEnabled, false)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testSignOutFailureSetsDangerError() async {
        let profileRepository = ProfileRepositoryStub()
        let settingsRepository = UserSettingsRepositoryStub()
        let authService = AuthServiceStub()
        let subscriptionRepository = SubscriptionRepositoryStub()
        authService.shouldFailSignOut = true
        settingsRepository.send(UserSettings(userID: "user-1", pushNotificationsEnabled: false, emailUpdatesEnabled: false))

        let viewModel = SettingsViewModel(profileRepository: profileRepository,
                                          settingsRepository: settingsRepository,
                                          authService: authService,
                                          subscriptionRepository: subscriptionRepository)

        let success = await viewModel.signOut()

        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.state.dangerErrorMessage)
    }

    func testDeleteAccountSuccessClearsDangerError() async {
        let profileRepository = ProfileRepositoryStub()
        let settingsRepository = UserSettingsRepositoryStub()
        let authService = AuthServiceStub()
        let subscriptionRepository = SubscriptionRepositoryStub()
        settingsRepository.send(UserSettings(userID: "user-1", pushNotificationsEnabled: false, emailUpdatesEnabled: false))

        let viewModel = SettingsViewModel(profileRepository: profileRepository,
                                          settingsRepository: settingsRepository,
                                          authService: authService,
                                          subscriptionRepository: subscriptionRepository)

        let success = await viewModel.deleteAccount(password: "pass123", reason: "testing")

        XCTAssertTrue(success)
        XCTAssertNil(viewModel.state.dangerErrorMessage)
        XCTAssertEqual(authService.deleteAccountInvocations.last?.password, "pass123")
        XCTAssertEqual(authService.deleteAccountInvocations.last?.reason, "testing")
    }

    func testDeleteAccountFailureSetsDangerError() async {
        let profileRepository = ProfileRepositoryStub()
        let settingsRepository = UserSettingsRepositoryStub()
        let authService = AuthServiceStub()
        let subscriptionRepository = SubscriptionRepositoryStub()
        authService.deleteAccountResult = .failure(TestError.operationFailed)
        settingsRepository.send(UserSettings(userID: "user-1", pushNotificationsEnabled: false, emailUpdatesEnabled: false))

        let viewModel = SettingsViewModel(profileRepository: profileRepository,
                                          settingsRepository: settingsRepository,
                                          authService: authService,
                                          subscriptionRepository: subscriptionRepository)

        let success = await viewModel.deleteAccount(password: nil, reason: nil)

        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.state.dangerErrorMessage)
    }

    func testObserveLoadsSubscriptionStatus() async {
        let profileRepository = ProfileRepositoryStub()
        let settingsRepository = UserSettingsRepositoryStub()
        let authService = AuthServiceStub()
        let subscriptionRepository = SubscriptionRepositoryStub()
        let expectedStatus = SubscriptionStatus(planIdentifier: "gold",
                                               planName: "Gold",
                                               isActive: true,
                                               isTrial: false,
                                               renewsAutomatically: true,
                                               expiresAt: Date().addingTimeInterval(86_400),
                                               managementURL: URL(string: "https://example.com/manage"))
        subscriptionRepository.status = expectedStatus

        let viewModel = SettingsViewModel(profileRepository: profileRepository,
                                          settingsRepository: settingsRepository,
                                          authService: authService,
                                          subscriptionRepository: subscriptionRepository)

        viewModel.observe(userID: "user-1")
        await waitForState(viewModel) { !$0.isLoadingSubscription }

        XCTAssertEqual(viewModel.state.subscriptionStatus, expectedStatus)
        XCTAssertFalse(viewModel.state.isLoadingSubscription)
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

private enum TestError: Error {
    case operationFailed
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

    func fetchShortlist(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        ProfileSearchPage(items: [], nextCursor: nil)
    }

    func toggleShortlist(userID: String) async throws -> ShortlistToggleResult {
        ShortlistToggleResult(action: .added)
    }

    func setShortlistNote(userID: String, note: String) async throws {}

    func fetchFavorites(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        ProfileSearchPage(items: [], nextCursor: nil)
    }

    func toggleFavorite(userID: String) async throws {}
}

@preconcurrency
private final class AuthServiceStub: AuthProviding {
    var shouldFailSignOut = false
    var deleteAccountResult: Result<Void, Error> = .success(())
    var deleteAccountInvocations: [(password: String?, reason: String?)] = []

    func currentUser() async throws -> UserProfile? { nil }

    @available(iOS 13, macOS 10.15, *)
    func presentSignIn(from anchor: ASPresentationAnchor) async throws -> UserProfile {
        throw TestError.operationFailed
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile {
        throw TestError.operationFailed
    }

    func signOut() throws {
        if shouldFailSignOut {
            throw TestError.operationFailed
        }
    }

    func deleteAccount(password: String?, reason: String?) async throws {
        deleteAccountInvocations.append((password, reason))
        switch deleteAccountResult {
        case .success:
            break
        case .failure(let error):
            throw error
        }
    }
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

@available(macOS 13.0, iOS 17.0, *)
@preconcurrency
private final class SubscriptionRepositoryStub: SubscriptionRepository {
    var status: SubscriptionStatus = SubscriptionStatus(planIdentifier: "free",
                                                         planName: "Free",
                                                         isActive: false,
                                                         isTrial: false,
                                                         renewsAutomatically: false,
                                                         expiresAt: nil,
                                                         managementURL: nil)
    var manageURL: URL? = URL(string: "https://example.com/manage")
    var shouldThrow = false

    func fetchStatus(for userID: String) async throws -> SubscriptionStatus {
        if shouldThrow {
            throw TestError.operationFailed
        }
        return status
    }

    func managementURL(for userID: String) -> URL? {
        manageURL
    }
}
