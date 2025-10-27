import Foundation

@available(iOS 17.0.0, *)
public struct BlockedUser: Identifiable, Equatable {
    public let id: String
    public let displayName: String
    public let avatarURL: URL?
    public let blockedAt: Date?

    public init(id: String,
                displayName: String,
                avatarURL: URL?,
                blockedAt: Date?) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.blockedAt = blockedAt
    }
}

@available(iOS 17.0.0, *)
public struct SafetyStatus: Equatable {
    public var isBlocked: Bool
    public var isBlockedBy: Bool
    public var canInteract: Bool

    public init(isBlocked: Bool = false,
                isBlockedBy: Bool = false,
                canInteract: Bool = true) {
        self.isBlocked = isBlocked
        self.isBlockedBy = isBlockedBy
        self.canInteract = canInteract
    }
}
