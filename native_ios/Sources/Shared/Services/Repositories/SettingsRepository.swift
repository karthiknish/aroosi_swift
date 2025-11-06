import Foundation

@available(iOS 17.0.0, *)
protocol SettingsRepository {
    func fetchSettings(for userID: String) async throws -> UserSettings
    func updateSettings(_ settings: UserSettings, userID: String) async throws
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
final class DefaultSettingsRepository: SettingsRepository {
    private enum Constants {
        static let collection = "userSettings"
    }

    private let db: Firestore
    private let logger = Logger.shared

    init(db: Firestore = .firestore()) {
        self.db = db
    }

    func fetchSettings(for userID: String) async throws -> UserSettings {
        let snapshot = try await db.collection(Constants.collection)
            .document(userID)
            .getDocument()

        guard let data = snapshot.data(),
              let settings = UserSettings(id: userID, data: data) else {
            return UserSettings.default(userID: userID)
        }

        return settings
    }

    func updateSettings(_ settings: UserSettings, userID: String) async throws {
        var next = settings
        next.userID = userID

        do {
            try await db.collection(Constants.collection)
                .document(userID)
                .setData(next.toDictionary(), merge: true)
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

        logger.error("Settings repository error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
}
#else

@available(iOS 17.0.0, *)
final class DefaultSettingsRepository: SettingsRepository {
    func fetchSettings(for userID: String) async throws -> UserSettings {
        UserSettings.default(userID: userID)
    }

    func updateSettings(_ settings: UserSettings, userID: String) async throws {}
}

#endif
