import Foundation

@available(iOS 17.0.0, *)
public typealias FeatureFlagKey = String

@available(iOS 17.0.0, *)
public protocol FeatureFlagRemoteStore {
    func fetchFlags() async throws -> [FeatureFlagKey: Bool]
}

@available(iOS 17.0.0, *)
public protocol FeatureFlagOverriding {
    func setOverride(_ value: Bool, for key: FeatureFlagKey)
    func removeOverride(for key: FeatureFlagKey)
    func removeAllOverrides()
}

@available(iOS 17.0.0, *)
public final class FeatureFlagService: FeatureFlagOverriding {
    public static let shared = FeatureFlagService()

    private let logger = Logger.shared
    private let queue = DispatchQueue(label: "com.aroosi.swift.feature-flags", qos: .utility)
    private let environmentFlags: [FeatureFlagKey: Bool]
    private let remoteStore: FeatureFlagRemoteStore?

    private var overrides: [FeatureFlagKey: Bool] = [:]
    private var remoteFlags: [FeatureFlagKey: Bool] = [:]
    private var currentUserID: String?

    public init(configProvider: AppConfigProviding = DefaultAppConfigProvider(),
                remoteStore: FeatureFlagRemoteStore? = nil) {
        if let config = try? configProvider.load() {
            self.environmentFlags = FeatureFlagService.normalize(config.environment.featureFlags)
        } else {
            self.environmentFlags = [:]
        }
        if let remoteStore {
            self.remoteStore = remoteStore
        } else {
            self.remoteStore = FeatureFlagService.makeDefaultRemoteStore()
        }
    }

    public func isEnabled(_ key: FeatureFlagKey) -> Bool {
        let normalized = key.lowercased()
        return queue.sync {
            if let override = overrides[normalized] { return override }
            if let remote = remoteFlags[normalized] { return remote }
            return environmentFlags[normalized] ?? false
        }
    }

    public func setOverride(_ value: Bool, for key: FeatureFlagKey) {
        let normalized = key.lowercased()
        queue.async { [weak self] in
            self?.overrides[normalized] = value
        }
    }

    public func removeOverride(for key: FeatureFlagKey) {
        let normalized = key.lowercased()
        queue.async { [weak self] in
            self?.overrides.removeValue(forKey: normalized)
        }
    }

    public func removeAllOverrides() {
        queue.async { [weak self] in
            self?.overrides.removeAll()
        }
    }

    public func refresh() async {
        guard let remoteStore else { return }
        do {
            let fetched = FeatureFlagService.normalize(try await remoteStore.fetchFlags())
            queue.async { [weak self] in
                self?.remoteFlags = fetched
            }
            logger.info("Feature flags refreshed for user \(currentUserID ?? "anonymous")")
        } catch {
            logger.error("Failed to refresh feature flags: \(error.localizedDescription)")
        }
    }

    public func setUserID(_ userID: String?) {
        queue.async {
            self.currentUserID = userID
        }
    }

    private static func makeDefaultRemoteStore() -> FeatureFlagRemoteStore? {
#if canImport(FirebaseFirestore)
        guard FirebaseApp.app() != nil else { return nil }
        return FirestoreFeatureFlagStore()
#else
        return nil
#endif
    }

    private static func normalize(_ flags: [FeatureFlagKey: Bool]) -> [FeatureFlagKey: Bool] {
        var normalized: [FeatureFlagKey: Bool] = [:]
        for (key, value) in flags {
            normalized[key.lowercased()] = value
        }
        return normalized
    }
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseCore

@available(iOS 17.0.0, *)
public final class FirestoreFeatureFlagStore: FeatureFlagRemoteStore {
    private let db: Firestore
    private let logger = Logger.shared

    private enum Constants {
        static let collection = "feature_flags"
        static let document = "global"
    }

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func fetchFlags() async throws -> [FeatureFlagKey: Bool] {
        let snapshot = try await db.collection(Constants.collection)
            .document(Constants.document)
            .getDocument()

        guard let data = snapshot.data() else { return [:] }

        var result: [FeatureFlagKey: Bool] = [:]
        for (key, value) in data {
            let normalized = key.lowercased()
            if let bool = value as? Bool {
                result[normalized] = bool
            } else if let string = value as? String {
                let boolValue = (string as NSString).boolValue
                result[normalized] = boolValue
            } else if let number = value as? NSNumber {
                result[normalized] = number.boolValue
            } else {
                logger.info("Unsupported feature flag value for key \(key). Skipping.")
            }
        }
        return result
    }
}
#endif

@available(iOS 17.0.0, *)
extension FeatureFlagService: @unchecked Sendable {}
