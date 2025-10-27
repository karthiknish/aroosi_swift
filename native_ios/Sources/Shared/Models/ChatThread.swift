import Foundation

public struct ChatThread: Equatable, Identifiable {
    public struct LastMessage: Equatable {
        public let authorID: String
        public let text: String
        public let sentAt: Date

        public init(authorID: String, text: String, sentAt: Date) {
            self.authorID = authorID
            self.text = text
            self.sentAt = sentAt
        }
    }

    public let id: String
    public let matchID: String
    public let participantIDs: [String]
    public let lastMessage: LastMessage?
    public let unreadCount: Int
    public let unreadCounts: [String: Int]
    public let lastActivityAt: Date

    public init(id: String,
                matchID: String,
                participantIDs: [String],
                lastMessage: LastMessage?,
                unreadCount: Int,
                unreadCounts: [String: Int] = [:],
                lastActivityAt: Date) {
        self.id = id
        self.matchID = matchID
        self.participantIDs = participantIDs
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.unreadCounts = unreadCounts
        self.lastActivityAt = lastActivityAt
    }

    public func unreadCountForUser(_ userID: String) -> Int {
        if let specific = unreadCounts[userID] {
            return specific
        }
        return unreadCount
    }
}

extension ChatThread.LastMessage {
    init?(data: [String: Any]) {
        guard let authorID = data["authorID"] as? String,
              let text = data["text"] as? String else {
            return nil
        }

        let sentAt = (data["sentAt"] as? Date) ?? Date()
        self.init(authorID: authorID, text: text, sentAt: sentAt)
    }

    func toDictionary() -> [String: Any] {
        [
            "authorID": authorID,
            "text": text,
            "sentAt": sentAt
        ]
    }
}

extension ChatThread {
    init?(id: String, data: [String: Any]) {
        guard let matchID = data["matchID"] as? String else { return nil }
        let participantIDs = data["participantIDs"] as? [String] ?? []
        let unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]
        let unreadCountValue = data["unreadCount"] as? Int ?? unreadCounts.values.reduce(0, +)
        let lastActivityAt = (data["lastActivityAt"] as? Date) ?? Date()

        var lastMessage: LastMessage?
        if let lastMessageData = data["lastMessage"] as? [String: Any] {
            lastMessage = LastMessage(data: lastMessageData)
        }

        self.init(id: id,
                  matchID: matchID,
                  participantIDs: participantIDs,
                  lastMessage: lastMessage,
                  unreadCount: unreadCountValue,
                  unreadCounts: unreadCounts,
                  lastActivityAt: lastActivityAt)
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "matchID": matchID,
            "participantIDs": participantIDs,
            "lastActivityAt": lastActivityAt
        ]

        if !unreadCounts.isEmpty {
            dict["unreadCounts"] = unreadCounts
        }

        let totalUnread = unreadCounts.isEmpty ? unreadCount : unreadCounts.values.reduce(0, +)
        dict["unreadCount"] = totalUnread

        if let lastMessage {
            dict["lastMessage"] = lastMessage.toDictionary()
        }

        return dict
    }
}
