import Foundation

@available(iOS 17.0.0, *)
public struct AppConfig: Equatable {
    public let environment: EnvironmentConfig
    public let secrets: Secrets

    public init(environment: EnvironmentConfig, secrets: Secrets) {
        self.environment = environment
        self.secrets = secrets
    }
}

@available(iOS 17.0.0, *)
public protocol AppConfigProviding {
    func load() throws -> AppConfig
}

@available(iOS 17.0.0, *)
public struct DefaultAppConfigProvider: AppConfigProviding {
    private let environmentLoader: EnvironmentConfigLoading
    private let secretsLoader: SecretsLoading

    public init(environmentLoader: EnvironmentConfigLoading = EnvironmentConfigLoader(),
                secretsLoader: SecretsLoading = DotenvSecretsLoader()) {
        self.environmentLoader = environmentLoader
        self.secretsLoader = secretsLoader
    }

    public func load() throws -> AppConfig {
        let environmentConfig = try environmentLoader.load()
        let secrets = try secretsLoader.load()
        return AppConfig(environment: environmentConfig, secrets: secrets)
    }
}
