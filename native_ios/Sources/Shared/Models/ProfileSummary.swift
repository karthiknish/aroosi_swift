import Foundation

public struct ProfileSummary: Equatable, Identifiable {
    public let id: String
    public var displayName: String
    public var age: Int?
    public var location: String?
    public var bio: String?
    public var avatarURL: URL?
    public var interests: [String]
    public var lastActiveAt: Date?

    public init(id: String,
                displayName: String,
                age: Int? = nil,
                location: String? = nil,
                bio: String? = nil,
                avatarURL: URL? = nil,
                interests: [String] = [],
                lastActiveAt: Date? = nil) {
        self.id = id
        self.displayName = displayName
        self.age = age
        self.location = location
        self.bio = bio
        self.avatarURL = avatarURL
        self.interests = interests
        self.lastActiveAt = lastActiveAt
    }
}

extension ProfileSummary {
    init?(id: String, data: [String: Any]) {
        guard let displayName = data["displayName"] as? String else {
            return nil
        }

        let age = data["age"] as? Int ?? (data["age"] as? NSNumber)?.intValue
        let location = data["location"] as? String
        let bio = data["bio"] as? String
        let interests = data["interests"] as? [String] ?? []
        let avatarURLString = data["avatarURL"] as? String
        let lastActiveTimestamp = data["lastActiveAt"] as? Date

        let avatarURL = avatarURLString.flatMap(URL.init(string:))

        self.init(
            id: id,
            displayName: displayName,
            age: age,
            location: location,
            bio: bio,
            avatarURL: avatarURL,
            interests: interests,
            lastActiveAt: lastActiveTimestamp
        )
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "displayName": displayName,
            "interests": interests
        ]

        if let age { dict["age"] = age }
        if let location { dict["location"] = location }
        if let bio { dict["bio"] = bio }
        if let avatarURL { dict["avatarURL"] = avatarURL.absoluteString }
        if let lastActiveAt { dict["lastActiveAt"] = lastActiveAt }

        return dict
    }
}
