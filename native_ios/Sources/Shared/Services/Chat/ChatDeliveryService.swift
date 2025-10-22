import Foundation

@available(iOS 15.0, macOS 12.0, *)
public protocol ChatDeliveryServicing {
    func handleMessageSent(conversationID: String,
                           senderID: String,
                           participants: [String],
                           sentAt: Date) async throws

    func markConversationRead(conversationID: String, userID: String) async throws
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 15.0, macOS 12.0, *)
public final class FirestoreChatDeliveryService: ChatDeliveryServicing {
    private enum Constants {
        static let conversations = "conversations"
        static let unreadCounts = "unreadCounts"
        static let lastActivityAt = "lastActivityAt"
        static let legacyUnreadCount = "unreadCount"
    }

    private let db: Firestore
    private let logger = Logger.shared

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func handleMessageSent(conversationID: String,
                                  senderID: String,
                                  participants: [String],
                                  sentAt: Date) async throws {
        let conversationRef = db.collection(Constants.conversations).document(conversationID)

        do {
            let snapshot = try await conversationRef.getDocument()
            var unreadCounts = snapshot.data()?[Constants.unreadCounts] as? [String: Int] ?? [:]

            for participant in participants {
                if participant == senderID {
                    unreadCounts[participant] = 0
                } else {
                    unreadCounts[participant] = (unreadCounts[participant] ?? 0) + 1
                }
            }

            let totalUnread = unreadCounts.values.reduce(0, +)

            try await conversationRef.setData([
                Constants.unreadCounts: unreadCounts,
                Constants.lastActivityAt: sentAt,
                Constants.legacyUnreadCount: totalUnread
            ], merge: true)
        } catch {
            throw mapError(error)
        }
    }

    public func markConversationRead(conversationID: String, userID: String) async throws {
        let conversationRef = db.collection(Constants.conversations).document(conversationID)

        do {
            let snapshot = try await conversationRef.getDocument()
            var unreadCounts = snapshot.data()?[Constants.unreadCounts] as? [String: Int] ?? [:]
            unreadCounts[userID] = 0
            let totalUnread = unreadCounts.values.reduce(0, +)

            try await conversationRef.setData([
                Constants.unreadCounts: unreadCounts,
                Constants.legacyUnreadCount: totalUnread,
                Constants.lastActivityAt: FieldValue.serverTimestamp()
            ], merge: true)
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

        logger.error("Firestore chat delivery error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
}
#else
@available(iOS 15.0, macOS 12.0, *)
public final class FirestoreChatDeliveryService: ChatDeliveryServicing {
    public init() {}

    public func handleMessageSent(conversationID: String,
                                  senderID: String,
                                  participants: [String],
                                  sentAt: Date) async throws {
        throw NSError(domain: "ChatDeliveryService", code: -1)
    }

    public func markConversationRead(conversationID: String, userID: String) async throws {
        throw NSError(domain: "ChatDeliveryService", code: -1)
    }
}
#endif
