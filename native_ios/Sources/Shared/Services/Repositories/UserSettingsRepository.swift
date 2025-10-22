import Foundation

@available(iOS 15.0, macOS 12.0, *)
public protocol UserSettingsRepository {
    func streamSettings(for userID: String) -> AsyncThrowingStream<UserSettings, Error>
    func updateSettings(_ settings: UserSettings) async throws
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 15.0, macOS 12.0, *)
public final class FirestoreUserSettingsRepository: UserSettingsRepository {
    private enum Constants {
        static let collection = "userSettings"
    }

    private let db: Firestore
    private let logger = Logger.shared

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func streamSettings(for userID: String) -> AsyncThrowingStream<UserSettings, Error> {
        AsyncThrowingStream { continuation in
            let listener = db.collection(Constants.collection)
                .document(userID)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.yield(with: .failure(self.mapError(error)))
                        return
                    }

                    guard let data = snapshot?.data(),
                          let settings = UserSettings(id: userID, data: data) else {
                        continuation.yield(UserSettings.default(userID: userID))
                        return
                    }

                    continuation.yield(settings)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    public func updateSettings(_ settings: UserSettings) async throws {
        let payload = settings.toDictionary()
        do {
            try await db.collection(Constants.collection)
                .document(settings.userID)
                .setData(payload, merge: true)
        } catch {
            throw mapError(error)
        }
    }

    private func mapError(_ error: Error) -> Error {
        if let firestoreError = error as NSError?,
           let code = FirestoreErrorCode.Code(rawValue: firestoreError.code) {
            switch code {
            case .permissionDenied:
                return RepositoryError.permissionDenied
            case .notFound:
                return RepositoryError.notFound
            case .unavailable, .deadlineExceeded:
                return RepositoryError.networkFailure
            default:
                break
            }
        }

        logger.error("Firestore user settings error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
}
#else
@available(iOS 15.0, macOS 12.0, *)
public final class FirestoreUserSettingsRepository: UserSettingsRepository {
    public init() {}

    public func streamSettings(for userID: String) -> AsyncThrowingStream<UserSettings, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: RepositoryError.unknown)
        }
    }

    public func updateSettings(_ settings: UserSettings) async throws {
        throw RepositoryError.unknown
    }
}
#endif
