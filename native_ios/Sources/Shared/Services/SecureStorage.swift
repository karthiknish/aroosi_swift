import Foundation
import Security

public protocol SecureStoring {
    func set(_ value: Data, forKey key: String) throws
    func value(forKey key: String) throws -> Data?
    func removeValue(forKey key: String) throws
}

public enum SecureStorageError: Error, LocalizedError {
    case itemNotFound
    case unhandledStatus(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Requested item was not found in secure storage."
        case .unhandledStatus(let status):
            return "Keychain operation failed with status: \(status)."
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
public final class KeychainSecureStorage: SecureStoring {
    public static let shared = KeychainSecureStorage(service: Bundle.main.bundleIdentifier ?? "com.aroosi.secure")

    private let service: String
    private let accessGroup: String?

    public init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    public func set(_ value: Data, forKey key: String) throws {
        let query = baseQuery(forKey: key)
        let attributes: [String: Any] = [
            kSecValueData as String: value
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw SecureStorageError.unhandledStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw SecureStorageError.unhandledStatus(status)
        }
    }

    public func value(forKey key: String) throws -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw SecureStorageError.unhandledStatus(status)
        }
    }

    public func removeValue(forKey key: String) throws {
        let query = baseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)

        if status == errSecItemNotFound {
            throw SecureStorageError.itemNotFound
        }

        guard status == errSecSuccess else {
            throw SecureStorageError.unhandledStatus(status)
        }
    }

    private func baseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        #if !targetEnvironment(simulator)
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        #endif

        return query
    }
}

public extension SecureStoring {
    func set(_ value: String, forKey key: String, encoding: String.Encoding = .utf8) throws {
        guard let data = value.data(using: encoding) else {
            throw SecureStorageError.unhandledStatus(errSecParam)
        }
        try set(data, forKey: key)
    }

    func string(forKey key: String, encoding: String.Encoding = .utf8) throws -> String? {
        guard let data = try value(forKey: key) else { return nil }
        return String(data: data, encoding: encoding)
    }
}
