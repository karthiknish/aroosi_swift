import Foundation

@available(iOS 15.0, macOS 12.0, *)
public protocol MatchRepository {
    func fetchMatch(id: String) async throws -> Match
    func streamMatches(for userID: String) -> AsyncThrowingStream<[Match], Error>
    func updateMatch(_ match: Match) async throws
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 15.0, macOS 12.0, *)
public final class FirestoreMatchRepository: MatchRepository {
    private enum Constants {
        static let collection = "matches"
        static let participantIDsField = "participantIDs"
        static let lastUpdatedAtField = "lastUpdatedAt"
    }

    private let db: Firestore
    private let logger = Logger.shared

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func fetchMatch(id: String) async throws -> Match {
        let document = try await db.collection(Constants.collection).document(id).getDocument()
        guard document.exists else {
            throw RepositoryError.notFound
        }

        let data = normalize(document.data() ?? [:])
        guard let match = Match(id: document.documentID, data: data) else {
            throw RepositoryError.invalidData
        }

        return match
    }

    public func streamMatches(for userID: String) -> AsyncThrowingStream<[Match], Error> {
        AsyncThrowingStream { continuation in
            let listeners = ListenerStore()

            let query = db.collection(Constants.collection)
                .whereField(Constants.participantIDsField, arrayContains: userID)
                .order(by: Constants.lastUpdatedAtField, descending: true)

            let listener = query.addSnapshotListener { snapshot, error in
                if let error {
                    continuation.yield(with: .failure(self.mapError(error)))
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let matches = documents.compactMap { document -> Match? in
                    let data = normalize(document.data())
                    return Match(id: document.documentID, data: data)
                }

                continuation.yield(matches)
            }

            listeners.add(listener)

            continuation.onTermination = { _ in
                listeners.removeAll()
            }
        }
    }

    public func updateMatch(_ match: Match) async throws {
        do {
            try await db.collection(Constants.collection).document(match.id)
                .setData(match.toDictionary(), merge: true)
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

        logger.error("Firestore match error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
}

private func normalize(_ data: [String: Any]) -> [String: Any] {
    var normalized = data
    if let timestamp = data["lastUpdatedAt"] as? Timestamp {
        normalized["lastUpdatedAt"] = timestamp.dateValue()
    }

    if var participants = data["participants"] as? [String: Any] {
        for (key, value) in participants {
            guard var participantDict = value as? [String: Any] else { continue }
            if let joinedAt = participantDict["joinedAt"] as? Timestamp {
                participantDict["joinedAt"] = joinedAt.dateValue()
            }
            participants[key] = participantDict
        }
        normalized["participants"] = participants
    }

    return normalized
}
#else
@available(iOS 15.0, macOS 12.0, *)
public final class FirestoreMatchRepository: MatchRepository {
    public init() {}

    public func fetchMatch(id: String) async throws -> Match {
        throw RepositoryError.unknown
    }

    public func streamMatches(for userID: String) -> AsyncThrowingStream<[Match], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: RepositoryError.unknown)
        }
    }

    public func updateMatch(_ match: Match) async throws {
        throw RepositoryError.unknown
    }
}
#endif
