import Foundation
import CryptoKit

@available(iOS 17.0, macOS 10.15, macCatalyst 13.0, *)
public final class DiskCacheStore: CacheStore {
    private let directoryURL: URL
    private let fileManager: FileManager
    private let expiration: TimeInterval?
    private let queue = DispatchQueue(label: "com.aroosi.cache.disk", qos: .utility)

    public init(name: String,
                expiration: TimeInterval? = nil,
                fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.expiration = expiration

        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.directoryURL = cachesDirectory.appendingPathComponent("com.aroosi.cache.\(name)", isDirectory: true)
        createDirectoryIfNeeded()
    }

    public func value(forKey key: String) -> Data? {
        queue.sync {
            let url = fileURL(for: key)
            guard fileManager.fileExists(atPath: url.path) else { return nil }

            if let expiration, isExpired(fileURL: url, expiration: expiration) {
                try? fileManager.removeItem(at: url)
                return nil
            }

            return try? Data(contentsOf: url)
        }
    }

    public func setValue(_ data: Data, forKey key: String) {
        queue.async {
            let url = self.fileURL(for: key)
            do {
                self.createDirectoryIfNeeded()
                try data.write(to: url, options: .atomic)
            } catch {
                Logger.shared.info("Failed to write cache value for key \(key): \(error.localizedDescription)")
            }
        }
    }

    public func removeValue(forKey key: String) {
        queue.async {
            let url = self.fileURL(for: key)
            try? self.fileManager.removeItem(at: url)
        }
    }

    public func removeAll() {
        queue.async {
            try? self.fileManager.removeItem(at: self.directoryURL)
            self.createDirectoryIfNeeded()
        }
    }

    private func createDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: directoryURL.path) else { return }
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    private func fileURL(for key: String) -> URL {
        let hash = sha256(key)
        return directoryURL.appendingPathComponent(hash, isDirectory: false)
    }

    @available(macOS 10.15, *)
    private func sha256(_ value: String) -> String {
        let data = Data(value.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func isExpired(fileURL: URL, expiration: TimeInterval) -> Bool {
        guard expiration > 0 else { return false }
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path) else { return false }
        guard let modificationDate = attributes[.modificationDate] as? Date else { return false }
        return Date().timeIntervalSince(modificationDate) > expiration
    }
}
