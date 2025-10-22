import Foundation

@available(iOS 15.0, macOS 12.0, *)
public protocol ChatMessageRepository {
    func streamMessages(conversationID: String) -> AsyncThrowingStream<[ChatMessage], Error>
    func sendMessage(conversationID: String,
                     authorID: String,
                     text: String,
                     sentAt: Date) async throws -> ChatMessage
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 15.0, macOS 12.0, *)
public final class FirestoreChatMessageRepository: ChatMessageRepository {
    private enum Constants {
        static let conversations = "conversations"
        static let messages = "messages"
        static let sentAt = "sentAt"
        static let authorID = "authorID"
        static let text = "text"
        static let lastActivityAt = "lastActivityAt"
        static let lastMessage = "lastMessage"
    }

    private let db: Firestore
    private let logger = Logger.shared

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func streamMessages(conversationID: String) -> AsyncThrowingStream<[ChatMessage], Error> {
        AsyncThrowingStream { continuation in
            let listeners = ListenerStore()
            let query = db.collection(Constants.conversations)
                .document(conversationID)
                .collection(Constants.messages)
                .order(by: Constants.sentAt, descending: false)

            let listener = query.addSnapshotListener { snapshot, error in
                if let error {
                    continuation.yield(with: .failure(self.mapError(error)))
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let messages = documents.compactMap { document -> ChatMessage? in
                    let data = self.normalizeMessage(document.data())
                    return ChatMessage(id: document.documentID,
                                       conversationID: conversationID,
                                       data: data)
                }

                continuation.yield(messages)
            }

            listeners.add(listener)

            continuation.onTermination = { _ in
                listeners.removeAll()
            }
        }
    }

    public func sendMessage(conversationID: String,
                            authorID: String,
                            text: String,
                            sentAt: Date) async throws -> ChatMessage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RepositoryError.invalidData }

        let messageID = UUID().uuidString
        let payload: [String: Any] = [
            Constants.authorID: authorID,
            Constants.text: trimmed,
            Constants.sentAt: sentAt
        ]

        let conversationRef = db.collection(Constants.conversations).document(conversationID)
        let messageRef = conversationRef.collection(Constants.messages).document(messageID)

        do {
            try await messageRef.setData(payload)

            let lastMessageData: [String: Any] = [
                Constants.authorID: authorID,
                Constants.text: trimmed,
                Constants.sentAt: sentAt
            ]

            try await conversationRef.setData([
                Constants.lastActivityAt: sentAt,
                Constants.lastMessage: lastMessageData
            ], merge: true)
        } catch {
            throw mapError(error)
        }

        return ChatMessage(id: messageID,
                           conversationID: conversationID,
                           authorID: authorID,
                           text: trimmed,
                           sentAt: sentAt)
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

        logger.error("Firestore chat message error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
    private func normalizeMessage(_ data: [String: Any]) -> [String: Any] {
        var normalized = data

        if let timestamp = data[Constants.sentAt] as? Timestamp {
            normalized[Constants.sentAt] = timestamp.dateValue()
        }

        return normalized
    }
}
#else
@available(iOS 15.0, macOS 12.0, *)
public final class FirestoreChatMessageRepository: ChatMessageRepository {
    public init() {}

    public func streamMessages(conversationID: String) -> AsyncThrowingStream<[ChatMessage], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: RepositoryError.unknown)
        }
    }

    public func sendMessage(conversationID: String,
                            authorID: String,
                            text: String,
                            sentAt: Date) async throws -> ChatMessage {
        throw RepositoryError.unknown
    }
}
#endif
