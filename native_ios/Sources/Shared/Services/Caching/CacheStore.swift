import Foundation

@available(iOS 17.0.0, *)
public protocol CacheStore {
    func value(forKey key: String) -> Data?
    func setValue(_ data: Data, forKey key: String)
    func removeValue(forKey key: String)
    func removeAll()
}
