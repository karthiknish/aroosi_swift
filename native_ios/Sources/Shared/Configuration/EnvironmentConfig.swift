import Foundation

public enum AppEnvironment: String, Codable, Equatable {
    case development
    case staging
    case production

    public init(rawValue: String, default defaultValue: AppEnvironment) {
        self = AppEnvironment(rawValue: rawValue.lowercased()) ?? defaultValue
    }
}

public struct EnvironmentConfig: Equatable {
    public let environment: AppEnvironment
    public let apiBaseURL: URL
    public let analyticsWriteKey: String?
    public let firebaseProjectID: String?
    public let featureFlags: [String: Bool]

    public init(environment: AppEnvironment,
                apiBaseURL: URL,
                analyticsWriteKey: String? = nil,
                firebaseProjectID: String? = nil,
                featureFlags: [String: Bool] = [:]) {
        self.environment = environment
        self.apiBaseURL = apiBaseURL
        self.analyticsWriteKey = analyticsWriteKey
        self.firebaseProjectID = firebaseProjectID
        self.featureFlags = featureFlags
    }
}

public protocol EnvironmentConfigLoading {
    func load() throws -> EnvironmentConfig
}

public enum EnvironmentConfigError: Error, LocalizedError {
    case missingAPIBaseURL
    case invalidURL(String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIBaseURL:
            return "API base URL is missing. Provide API_BASE_URL in the environment configuration."
        case .invalidURL(let value):
            return "The provided API base URL is invalid: \(value)."
        }
    }
}

public struct EnvironmentConfigLoader: EnvironmentConfigLoading {
    private enum Keys {
        static let environment = "AROOSI_ENV"
        static let apiBaseURL = "API_BASE_URL"
        static let analyticsWriteKey = "ANALYTICS_WRITE_KEY"
        static let firebaseProjectID = "FIREBASE_PROJECT_ID"
    }

    private let environmentVariables: [String: String]
    private let defaultEnvironment: AppEnvironment

    public init(environmentVariables: [String: String] = ProcessInfo.processInfo.environment,
                defaultEnvironment: AppEnvironment = .development) {
        self.environmentVariables = environmentVariables
        self.defaultEnvironment = defaultEnvironment
    }

    public func load() throws -> EnvironmentConfig {
        let environmentString = environmentVariables[Keys.environment] ?? defaultEnvironment.rawValue
        let environment = AppEnvironment(rawValue: environmentString, default: defaultEnvironment)

        guard let apiBaseURLString = environmentVariables[Keys.apiBaseURL], !apiBaseURLString.isEmpty else {
            throw EnvironmentConfigError.missingAPIBaseURL
        }

        guard let apiBaseURL = URL(string: apiBaseURLString) else {
            throw EnvironmentConfigError.invalidURL(apiBaseURLString)
        }

        let analyticsWriteKey = environmentVariables[Keys.analyticsWriteKey]
        let firebaseProjectID = environmentVariables[Keys.firebaseProjectID]
        let featureFlags = loadFeatureFlags(for: environment)

        return EnvironmentConfig(
            environment: environment,
            apiBaseURL: apiBaseURL,
            analyticsWriteKey: analyticsWriteKey,
            firebaseProjectID: firebaseProjectID,
            featureFlags: featureFlags
        )
    }

    private func loadFeatureFlags(for environment: AppEnvironment) -> [String: Bool] {
        let featureFlagPrefix = "FEATURE_FLAG_"
        let enablePrefix = "ENABLE_"
        var flags: [String: Bool] = [:]

        for (key, value) in environmentVariables {
            if key.hasPrefix(featureFlagPrefix) {
                let normalizedKey = key.replacingOccurrences(of: featureFlagPrefix, with: "").lowercased()
                let boolValue = (value as NSString).boolValue
                flags[normalizedKey] = boolValue
                continue
            }

            if key.hasPrefix(enablePrefix) {
                let normalizedKey = key.lowercased()
                let boolValue = (value as NSString).boolValue
                flags[normalizedKey] = boolValue
            }
        }

        // Common defaults per environment can be defined here if needed.
        if environment == .development {
            flags["show_debug_menus"] = flags["show_debug_menus"] ?? true
        }

        return flags
    }
}
