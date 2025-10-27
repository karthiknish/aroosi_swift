import Foundation

@available(iOS 17.0.0, *)
public protocol ConversationServicing {
    func ensureConversation(for match: Match,
                            participants: [String],
                            currentUserID: String) async throws -> String
}

public enum ConversationServiceError: LocalizedError {
    case missingParticipants
    case unsupported

    public var errorDescription: String? {
        switch self {
        case .missingParticipants:
            return "We could not start this conversation because no participants were provided."
        case .unsupported:
            return "Conversations are not supported on this platform."
        }
    }
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
public final class FirestoreConversationService: ConversationServicing {
    private enum Constants {
        static let conversations = "conversations"
        static let matchID = "matchID"
        static let participantIDs = "participantIDs"
        static let createdAt = "createdAt"
        static let lastActivityAt = "lastActivityAt"
        static let unreadCount = "unreadCount"
        static let unreadCounts = "unreadCounts"
    }

    private let db: Firestore
    private let matchRepository: MatchRepository
    private let logger = Logger.shared

    public init(db: Firestore = .firestore(),
                matchRepository: MatchRepository = FirestoreMatchRepository()) {
        self.db = db
        self.matchRepository = matchRepository
    }

    public func ensureConversation(for match: Match,
                                   participants: [String],
                                   currentUserID: String) async throws -> String {
        if let existing = match.conversationID, !existing.isEmpty {
            return existing
        }

        var participantSet = Set(participants)
        participantSet.insert(currentUserID)
        let uniqueParticipants = Array(participantSet).sorted()
        guard !uniqueParticipants.isEmpty else {
            throw ConversationServiceError.missingParticipants
        }

        let conversationRef = db.collection(Constants.conversations).document()
        let timestamp = Date()

        var unreadCounts: [String: Int] = [:]
        uniqueParticipants.forEach { unreadCounts[$0] = 0 }

        let payload: [String: Any] = [
            Constants.matchID: match.id,
            Constants.participantIDs: uniqueParticipants,
            Constants.createdAt: timestamp,
            Constants.lastActivityAt: timestamp,
            Constants.unreadCounts: unreadCounts,
            Constants.unreadCount: 0
        ]

        do {
            try await conversationRef.setData(payload)

            let updatedMatch = Match(id: match.id,
                                     participants: match.participants,
                                     status: match.status,
                                     lastMessagePreview: match.lastMessagePreview,
                                     lastUpdatedAt: timestamp,
                                     conversationID: conversationRef.documentID)

            try await matchRepository.updateMatch(updatedMatch)

            return conversationRef.documentID
        } catch {
            logger.error("Failed to ensure conversation for match \(match.id): \(error.localizedDescription)")
            throw mapError(error)
        }
    }

    private func mapError(_ error: Error) -> Error {
        if let firestoreError = error as NSError?,
           let codeValue = FirestoreErrorCode.Code(rawValue: firestoreError.code) {
            switch codeValue {
            case .permissionDenied:
                return RepositoryError.permissionDenied
            case .alreadyExists:
                return RepositoryError.alreadyExists
            case .unavailable, .deadlineExceeded:
                return RepositoryError.networkFailure
            default:
                break
            }
        }

        return RepositoryError.unknown
    }
}
#else
@available(iOS 17.0.0, *)
public final class FirestoreConversationService: ConversationServicing {
    public init() {}

    public func ensureConversation(for match: Match,
                                   participants: [String],
                                   currentUserID: String) async throws -> String {
        throw ConversationServiceError.unsupported
    }
}
#endif
