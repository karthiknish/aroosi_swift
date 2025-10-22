import Foundation

@available(iOS 15.0, macOS 12.0, *)
public protocol ProfileRepository {
    func fetchProfile(id: String) async throws -> ProfileSummary
    func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error>
    func updateProfile(_ profile: ProfileSummary) async throws
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 15.0, macOS 12.0, *)
public final class FirestoreProfileRepository: ProfileRepository {
    private enum Constants {
        static let collection = "profiles"
        static let maxIDsPerBatch = 10
    }

    private let db: Firestore
    private let logger = Logger.shared

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func fetchProfile(id: String) async throws -> ProfileSummary {
        let document = try await db.collection(Constants.collection).document(id).getDocument()
        guard document.exists, let data = document.data() else {
            throw RepositoryError.notFound
        }

        guard let profile = ProfileSummary(id: document.documentID, data: normalize(data)) else {
            throw RepositoryError.invalidData
        }

        return profile
    }

    public func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            guard !userIDs.isEmpty else {
                continuation.yield([])
                continuation.finish()
                return
            }

            let batches = stride(from: 0, to: userIDs.count, by: Constants.maxIDsPerBatch).map { start -> [String] in
                let end = min(start + Constants.maxIDsPerBatch, userIDs.count)
                return Array(userIDs[start..<end])
            }

            let listeners = ListenerStore()

            for batch in batches {
                let listener = db.collection(Constants.collection)
                    .whereField(FieldPath.documentID(), in: batch)
                    .addSnapshotListener { snapshot, error in
                        if let error {
                            continuation.yield(with: .failure(self.mapError(error)))
                            return
                        }

                        guard let documents = snapshot?.documents else { return }

                        let profiles = documents.compactMap { document -> ProfileSummary? in
                            let data = document.data()
                            return ProfileSummary(id: document.documentID, data: normalize(data))
                        }

                        continuation.yield(profiles)
                    }

                listeners.add(listener)
            }

            continuation.onTermination = { _ in
                listeners.removeAll()
            }
        }
    }

    public func updateProfile(_ profile: ProfileSummary) async throws {
        let payload = profile.toDictionary()
        do {
            try await db.collection(Constants.collection).document(profile.id).setData(payload, merge: true)
        } catch {
            throw mapError(error)
        }
    }

    private func mapError(_ error: Error) -> Error {
        if let firestoreError = error as NSError?,
           let codeValue = FirestoreErrorCode.Code(rawValue: firestoreError.code) {
            switch codeValue {
            case .permissionDenied:
                return RepositoryError.permissionDenied
            case .notFound:
                return RepositoryError.notFound
            case .alreadyExists:
                return RepositoryError.alreadyExists
            case .unavailable, .deadlineExceeded:
                return RepositoryError.networkFailure
            default:
                break
            }
        }

        logger.error("Firestore profile error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
}

private func normalize(_ data: [String: Any]) -> [String: Any] {
    var normalized = data
    if let timestamp = data["lastActiveAt"] as? Timestamp {
        normalized["lastActiveAt"] = timestamp.dateValue()
    }
    return normalized
}
#else
@available(iOS 15.0, macOS 12.0, *)
public final class FirestoreProfileRepository: ProfileRepository {
    public init() {}

    public func fetchProfile(id: String) async throws -> ProfileSummary {
        throw RepositoryError.unknown
    }

    public func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: RepositoryError.unknown)
        }
    }

    public func updateProfile(_ profile: ProfileSummary) async throws {
        throw RepositoryError.unknown
    }
}
#endif
