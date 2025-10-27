import Foundation

public struct Match: Equatable, Identifiable {
    public enum Status: String, Equatable {
        case pending
        case active
        case closed
        case blocked
    }

    public struct Participant: Equatable {
        public let userID: String
        public let isInitiator: Bool

        public init(userID: String, isInitiator: Bool) {
            self.userID = userID
            self.isInitiator = isInitiator
        }
    }

    public let id: String
    public let participants: [Participant]
    public let status: Status
    public let lastMessagePreview: String?
    public let lastUpdatedAt: Date
    public let conversationID: String?

    public init(id: String,
                participants: [Participant],
                status: Status,
                lastMessagePreview: String? = nil,
                lastUpdatedAt: Date,
                conversationID: String? = nil) {
        self.id = id
        self.participants = participants
        self.status = status
        self.lastMessagePreview = lastMessagePreview
        self.lastUpdatedAt = lastUpdatedAt
        self.conversationID = conversationID
    }

    public var participantIDs: [String] {
        participants.map { $0.userID }
    }
}

extension Match.Participant {
    init(userID: String, data: [String: Any]) {
        let isInitiator = data["isInitiator"] as? Bool ?? false
        self.init(userID: userID, isInitiator: isInitiator)
    }

    func toDictionary() -> [String: Any] {
        ["isInitiator": isInitiator]
    }
}

extension Match {
    init?(id: String, data: [String: Any]) {
        guard let statusRaw = data["status"] as? String,
              let status = Status(rawValue: statusRaw) else {
            return nil
        }

        let lastMessagePreview = data["lastMessagePreview"] as? String
        let lastUpdatedAt = (data["lastUpdatedAt"] as? Date) ?? Date()

        let conversationID = data["conversationId"] as? String

        var participants: [Participant] = []
        if let participantMap = data["participants"] as? [String: Any] {
            for (userID, participantData) in participantMap {
                guard let participantDict = participantData as? [String: Any] else { continue }
                participants.append(Participant(userID: userID, data: participantDict))
            }
        }

        self.init(id: id,
                  participants: participants,
                  status: status,
                  lastMessagePreview: lastMessagePreview,
                  lastUpdatedAt: lastUpdatedAt,
                  conversationID: conversationID)
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "status": status.rawValue,
            "lastUpdatedAt": lastUpdatedAt
        ]

        if let lastMessagePreview {
            dict["lastMessagePreview"] = lastMessagePreview
        }

        if let conversationID {
            dict["conversationId"] = conversationID
        }

        let participantEntries = Dictionary(uniqueKeysWithValues: participants.map { participant in
            (participant.userID, participant.toDictionary())
        })
        dict["participants"] = participantEntries

        dict["participantIDs"] = participantIDs
        return dict
    }
}
