#if canImport(FirebaseFirestore)
import FirebaseFirestore
import Foundation

@available(iOS 15.0, macOS 12.0, *)
final class ListenerStore: @unchecked Sendable {
    private let lock = NSLock()
    private var registrations: [ListenerRegistration] = []

    func add(_ registration: ListenerRegistration) {
        lock.lock()
        registrations.append(registration)
        lock.unlock()
    }

    func removeAll() {
        lock.lock()
        let current = registrations
        registrations.removeAll()
        lock.unlock()

        current.forEach { $0.remove() }
    }
}
#endif
