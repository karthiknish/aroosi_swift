import Foundation

@available(iOS 17.0.0, *)
public protocol ChatDeliveryServicing {
    func handleMessageSent(conversationID: String,
                           senderID: String,
                           participants: [String],
                           sentAt: Date) async throws

    func markConversationRead(conversationID: String, userID: String) async throws
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
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
            let existingCounts = snapshot.data()?[Constants.unreadCounts] as? [String: Int] ?? [:]
            let unreadCounts = ChatUnreadCounter.updatedCounts(afterSendingFrom: senderID,
                                                               participants: participants,
                                                               existing: existingCounts)
            let totalUnread = ChatUnreadCounter.totalUnread(from: unreadCounts)

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
            let existingCounts = snapshot.data()?[Constants.unreadCounts] as? [String: Int] ?? [:]
            let unreadCounts = ChatUnreadCounter.clearedCounts(for: userID, existing: existingCounts)
            let totalUnread = ChatUnreadCounter.totalUnread(from: unreadCounts)

            try await conversationRef.setData([
                Constants.unreadCounts: unreadCounts,
                Constants.legacyUnreadCount: totalUnread
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

@available(iOS 17.0.0, *)
enum ChatUnreadCounter {
    static func updatedCounts(afterSendingFrom senderID: String,
                              participants: [String],
                              existing: [String: Int]) -> [String: Int] {
        var counts = existing
        let allParticipants = Set(participants + [senderID])

        for participant in allParticipants {
            if participant == senderID {
                counts[participant] = 0
            } else {
                counts[participant] = (counts[participant] ?? 0) + 1
            }
        }

        // Remove stale entries for users no longer in the conversation
        for key in counts.keys where !allParticipants.contains(key) {
            counts.removeValue(forKey: key)
        }

        return counts
    }

    static func clearedCounts(for userID: String, existing: [String: Int]) -> [String: Int] {
        var counts = existing
        counts[userID] = 0
        return counts
    }

    static func totalUnread(from counts: [String: Int]) -> Int {
        counts.values.reduce(0, +)
    }
}
#else
@available(iOS 17.0.0, *)
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
