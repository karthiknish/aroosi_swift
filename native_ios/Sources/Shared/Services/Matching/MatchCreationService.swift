import Foundation
import Combine

#if os(iOS)

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17, *)
@MainActor
public final class MatchCreationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var isCreatingMatch = false
    @Published public private(set) var lastCreatedMatch: Match?
    @Published public private(set) var error: Error?
    
    // MARK: - Dependencies
    private let matchRepository: MatchRepository
    private let conversationService: ConversationServicing
    private let logger = Logger.shared
    
    // MARK: - Initialization
    public init(
        matchRepository: MatchRepository = FirestoreMatchRepository(),
        conversationService: ConversationServicing = FirestoreConversationService()
    ) {
        self.matchRepository = matchRepository
        self.conversationService = conversationService
        
        // Listen for mutual interest notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMutualInterestDetected(_:)),
            name: .mutualInterestDetected,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Create a match between two users
    public func createMatch(between user1: String, and user2: String) async throws -> Match {
        guard !isCreatingMatch else {
            throw MatchCreationError.alreadyInProgress
        }
        
        guard user1 != user2 else {
            throw MatchCreationError.sameUser
        }
        
        // Check if match already exists
        if let existingMatch = try await findExistingMatch(between: user1, and: user2) {
            logger.info("Match already exists between \(user1) and \(user2)")

            let resolvedMatch = try await reactivateIfNeeded(existingMatch, user1: user1, user2: user2)
            lastCreatedMatch = resolvedMatch
            return resolvedMatch
        }
        
        isCreatingMatch = true
        error = nil
        
        defer {
            isCreatingMatch = false
        }
        
        do {
            let match = try await createNewMatch(between: user1, and: user2)
            lastCreatedMatch = match
            logger.info("Successfully created match: \(match.id)")
            return match
        } catch {
            self.error = error
            logger.error("Failed to create match: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Check if a match exists between two users
    public func matchExists(between user1: String, and user2: String) async throws -> Bool {
        let existingMatch = try await findExistingMatch(between: user1, and: user2)
        return existingMatch != nil
    }
    
    // MARK: - Private Methods
    
    @objc private func handleMutualInterestDetected(_ notification: Notification) {
        guard let userInfo = notification.object as? (userID: String, targetID: String) else {
            return
        }
        
        Task {
            do {
                _ = try await createMatch(between: userInfo.userID, and: userInfo.targetID)
            } catch {
                logger.error("Auto-match creation failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func createNewMatch(between user1: String, and user2: String) async throws -> Match {
        // Create match participants
        let participants = [
            Match.Participant(userID: user1, isInitiator: true),
            Match.Participant(userID: user2, isInitiator: false)
        ]
        
        // Create initial match
        let match = Match(
            id: UUID().uuidString,
            participants: participants,
            status: .active,
            lastUpdatedAt: Date()
        )
        
        // Save match to database
        try await matchRepository.updateMatch(match)
        
        // Create conversation for the match
        let conversationID = try await conversationService.ensureConversation(
            for: match,
            participants: [user1, user2],
            currentUserID: user1
        )
        
        // Update match with conversation ID
        let updatedMatch = Match(
            id: match.id,
            participants: match.participants,
            status: match.status,
            lastUpdatedAt: Date(),
            conversationID: conversationID
        )
        
        try await matchRepository.updateMatch(updatedMatch)
        
        return updatedMatch
    }
    
    private func findExistingMatch(between user1: String, and user2: String) async throws -> Match? {
        try await matchRepository.findMatch(between: user1, and: user2)
    }

    private func reactivateIfNeeded(_ match: Match, user1: String, user2: String) async throws -> Match {
        switch match.status {
        case .active:
            return match
        case .blocked:
            throw MatchCreationError.matchAlreadyExists
        case .pending, .closed:
            break
        }

        let conversationID: String
        if let existingConversationID = match.conversationID {
            conversationID = existingConversationID
        } else {
            conversationID = try await conversationService.ensureConversation(
                for: match,
                participants: [user1, user2],
                currentUserID: user1
            )
        }

        let updatedMatch = Match(id: match.id,
                                 participants: match.participants,
                                 status: .active,
                                 lastMessagePreview: match.lastMessagePreview,
                                 lastUpdatedAt: Date(),
                                 conversationID: conversationID)

        try await matchRepository.updateMatch(updatedMatch)
        return updatedMatch
    }
}

// MARK: - Error Types

public enum MatchCreationError: Error, LocalizedError {
    case alreadyInProgress
    case sameUser
    case matchAlreadyExists
    case conversationCreationFailed
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .alreadyInProgress:
            return "Match creation is already in progress"
        case .sameUser:
            return "Cannot create a match with yourself"
        case .matchAlreadyExists:
            return "A match already exists between these users"
        case .conversationCreationFailed:
            return "Failed to create conversation for the match"
        case .unknown:
            return "An unknown error occurred while creating the match"
        }
    }
}

#else
@available(iOS 17, *)
@MainActor
public final class MatchCreationService: ObservableObject {
    public init() {}
    
    public func createMatch(between user1: String, and user2: String) async throws -> Match {
        throw MatchCreationError.unknown
    }
    
    public func matchExists(between user1: String, and user2: String) async throws -> Bool {
        false
    }
}
#endif
#endif
