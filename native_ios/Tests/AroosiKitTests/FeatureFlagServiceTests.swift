@testable import AroosiKit
import XCTest

@available(iOS 15.0, macOS 12.0, *)
final class FeatureFlagServiceTests: XCTestCase {
    func testEnvironmentFlagReturnsDefault() {
        let config = makeConfig(featureFlags: ["test_flag": true])
        let service = FeatureFlagService(configProvider: StubConfigProvider(config: config), remoteStore: nil)

        XCTAssertTrue(service.isEnabled("test_flag"))
        XCTAssertFalse(service.isEnabled("missing_flag"))
    }

    func testOverridesTakePrecedence() {
        let config = makeConfig(featureFlags: ["alpha": false])
        let service = FeatureFlagService(configProvider: StubConfigProvider(config: config), remoteStore: nil)

        XCTAssertFalse(service.isEnabled("alpha"))
        service.setOverride(true, for: "alpha")
        XCTAssertTrue(service.isEnabled("alpha"))
        service.removeOverride(for: "alpha")
        XCTAssertFalse(service.isEnabled("alpha"))
    }

    func testRemoteFlagsOverrideEnvironment() async {
        let config = makeConfig(featureFlags: ["beta": false])
        let remoteStore = FeatureFlagRemoteStoreStub(flags: ["beta": true, "gamma": true])
        let service = FeatureFlagService(configProvider: StubConfigProvider(config: config), remoteStore: remoteStore)

        await service.refresh()

        XCTAssertTrue(service.isEnabled("beta"))
        XCTAssertTrue(service.isEnabled("gamma"))
    }

    func testOverridesPersistAfterRefresh() async {
        let config = makeConfig(featureFlags: ["delta": false])
        let remoteStore = FeatureFlagRemoteStoreStub(flags: ["delta": false])
        let service = FeatureFlagService(configProvider: StubConfigProvider(config: config), remoteStore: remoteStore)

        service.setOverride(true, for: "delta")
        await service.refresh()

        XCTAssertTrue(service.isEnabled("delta"))
    }

    private func makeConfig(featureFlags: [String: Bool]) -> AppConfig {
        let environment = EnvironmentConfig(environment: .development,
                                            apiBaseURL: URL(string: "https://example.com")!,
                                            featureFlags: featureFlags)
        return AppConfig(environment: environment, secrets: Secrets(values: [:]))
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct StubConfigProvider: AppConfigProviding {
    let config: AppConfig

    func load() throws -> AppConfig { config }
}

@available(iOS 15.0, macOS 12.0, *)
private final class FeatureFlagRemoteStoreStub: FeatureFlagRemoteStore {
    var flags: [FeatureFlagKey: Bool]

    init(flags: [FeatureFlagKey: Bool]) {
        self.flags = flags
    }

    func fetchFlags() async throws -> [FeatureFlagKey: Bool] {
        flags
    }
}
