import Foundation

public struct UserProfile: Identifiable, Equatable {
    public let id: String
    public let displayName: String
    public let email: String?
    public let avatarURL: URL?

    public init(id: String, displayName: String, email: String?, avatarURL: URL?) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.avatarURL = avatarURL
    }
}
