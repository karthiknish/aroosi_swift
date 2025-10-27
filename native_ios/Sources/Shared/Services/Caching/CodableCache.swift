import Foundation

@available(iOS 17.0.0, *)
public final class CodableCache<T: Codable> {
    private let store: CacheStore
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(store: CacheStore,
                decoder: JSONDecoder = JSONDecoder(),
                encoder: JSONEncoder = JSONEncoder()) {
        self.store = store
        self.decoder = decoder
        self.encoder = encoder
    }

    public func value(forKey key: String) -> T? {
        guard let data = store.value(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    public func setValue(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else { return }
        store.setValue(data, forKey: key)
    }

    public func removeValue(forKey key: String) {
        store.removeValue(forKey: key)
    }

    public func removeAll() {
        store.removeAll()
    }
}
