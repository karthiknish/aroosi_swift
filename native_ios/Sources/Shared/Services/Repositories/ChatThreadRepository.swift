import Foundation

#if os(iOS)

@available(iOS 17.0.0, *)
public protocol ChatThreadRepository {
    func fetchThread(id: String) async throws -> ChatThread
    func upsertThread(_ thread: ChatThread) async throws
}

@available(iOS 15.0, macOS 10.15, *)
public protocol ChatThreadRepositoryWithStreaming: ChatThreadRepository {
    func streamThreads(for userID: String) -> AsyncThrowingStream<[ChatThread], Error>
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
public final class FirestoreChatThreadRepository: ChatThreadRepositoryWithStreaming {
    private enum Constants {
        static let collection = "conversations"
        static let participantIDsField = "participantIDs"
        static let lastActivityAtField = "lastActivityAt"
    }

    private let db: Firestore
    private let logger = Logger.shared

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func fetchThread(id: String) async throws -> ChatThread {
        let document = try await db.collection(Constants.collection).document(id).getDocument()
        guard document.exists else {
            throw RepositoryError.notFound
        }

        let data = normalize(document.data() ?? [:])
        guard let thread = ChatThread(id: document.documentID, data: data) else {
            throw RepositoryError.invalidData
        }

        return thread
    }

    public func streamThreads(for userID: String) -> AsyncThrowingStream<[ChatThread], Error> {
        AsyncThrowingStream { continuation in
            let listeners = ListenerStore()

            let query = db.collection(Constants.collection)
                .whereField(Constants.participantIDsField, arrayContains: userID)
                .order(by: Constants.lastActivityAtField, descending: true)

            let listener = query.addSnapshotListener { snapshot, error in
                if let error {
                    continuation.yield(with: .failure(self.mapError(error)))
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let threads = documents.compactMap { document -> ChatThread? in
                    let data = normalize(document.data())
                    return ChatThread(id: document.documentID, data: data)
                }

                continuation.yield(threads)
            }

            listeners.add(listener)

            continuation.onTermination = { _ in
                listeners.removeAll()
            }
        }
    }

    public func upsertThread(_ thread: ChatThread) async throws {
        do {
            try await db.collection(Constants.collection).document(thread.id)
                .setData(thread.toDictionary(), merge: true)
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

        logger.error("Firestore chat thread error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
}

private func normalize(_ data: [String: Any]) -> [String: Any] {
    var normalized = data

    if let timestamp = data["lastActivityAt"] as? Timestamp {
        normalized["lastActivityAt"] = timestamp.dateValue()
    }

    if var lastMessage = data["lastMessage"] as? [String: Any] {
        if let sentAt = lastMessage["sentAt"] as? Timestamp {
            lastMessage["sentAt"] = sentAt.dateValue()
        }
        normalized["lastMessage"] = lastMessage
    }

    return normalized
}
#else
@available(iOS 17.0.0, *)
public final class FirestoreChatThreadRepository: ChatThreadRepository {
    public init() {}

    public func fetchThread(id: String) async throws -> ChatThread {
        throw RepositoryError.unknown
    }

    public func streamThreads(for userID: String) -> AsyncThrowingStream<[ChatThread], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: RepositoryError.unknown)
        }
    }

    public func upsertThread(_ thread: ChatThread) async throws {
        throw RepositoryError.unknown
    }
}
#endif
#endif
