import Foundation

public struct ChatMessage: Identifiable, Equatable {
    public enum MessageType: String, Codable {
        case text
        case image
        case voice
        case system
        case unknown
    }

    public let id: String
    public let conversationID: String
    public let authorID: String
    public let text: String
    public let sentAt: Date
    public let type: MessageType
    public let imageURL: URL?
    public let audioURL: URL?
    public let audioDuration: TimeInterval?
    public let reactions: [String: [String]]

    public init(id: String,
                conversationID: String,
                authorID: String,
                text: String,
                sentAt: Date,
                type: MessageType = .text,
                imageURL: URL? = nil,
                audioURL: URL? = nil,
                audioDuration: TimeInterval? = nil,
                reactions: [String: [String]] = [:]) {
        self.id = id
        self.conversationID = conversationID
        self.authorID = authorID
        self.text = text
        self.sentAt = sentAt
        self.type = type
        self.imageURL = imageURL
        self.audioURL = audioURL
        self.audioDuration = audioDuration
        self.reactions = reactions
    }
}

extension ChatMessage {
    init?(id: String, conversationID: String, data: [String: Any]) {
        guard let authorID = data["authorID"] as? String,
              let rawText = data["text"] as? String else {
            return nil
        }

        let sentAt = (data["sentAt"] as? Date) ?? Date()
        let typeRaw = (data["type"] as? String) ?? MessageType.text.rawValue
        let type = MessageType(rawValue: typeRaw) ?? .unknown

        var imageURL: URL?
        if let imageString = data["imageUrl"] as? String {
            imageURL = URL(string: imageString)
        }

        var audioURL: URL?
        if let audioString = data["audioUrl"] as? String {
            audioURL = URL(string: audioString)
        }

        var audioDuration: TimeInterval?
        if let duration = data["duration"] as? TimeInterval {
            audioDuration = duration
        } else if let durationInt = data["duration"] as? Int {
            audioDuration = TimeInterval(durationInt)
        } else if let durationDouble = data["duration"] as? Double {
            audioDuration = durationDouble
        }

        var reactions: [String: [String]] = [:]
        if let rawReactions = data["reactions"] as? [String: Any] {
            for (emoji, value) in rawReactions {
                if let identifiers = value as? [String] {
                    reactions[emoji] = identifiers
                }
            }
        }

        self.init(id: id,
                  conversationID: conversationID,
                  authorID: authorID,
                  text: rawText,
                  sentAt: sentAt,
                  type: type,
                  imageURL: imageURL,
                  audioURL: audioURL,
                  audioDuration: audioDuration,
                  reactions: reactions)
    }

    func toDictionary() -> [String: Any] {
        var payload: [String: Any] = [
            "authorID": authorID,
            "text": text,
            "sentAt": sentAt,
            "conversationID": conversationID
        ]
        if type != .text { payload["type"] = type.rawValue }
        if let imageURL { payload["imageUrl"] = imageURL.absoluteString }
        if let audioURL { payload["audioUrl"] = audioURL.absoluteString }
        if let audioDuration { payload["duration"] = audioDuration }
        if !reactions.isEmpty { payload["reactions"] = reactions }
        return payload
    }
}
