@testable import AroosiKit
import XCTest

@available(iOS 17, macOS 13, *)
final class EnvironmentConfigLoaderTests: XCTestCase {
    func testLoadFeatureFlagsIncludesEnablePrefix() throws {
        let loader = EnvironmentConfigLoader(environmentVariables: [
            "AROOSI_ENV": "development",
            "API_BASE_URL": "https://example.com",
            "FEATURE_FLAG_SHOW_DEBUG_MENUS": "false",
            "ENABLE_ICEBREAKERS": "true"
        ])

        let config = try loader.load()

        XCTAssertEqual(config.featureFlags["show_debug_menus"], false)
        XCTAssertEqual(config.featureFlags["enable_icebreakers"], true)
        XCTAssertEqual(config.environment, .development)
    }
}
