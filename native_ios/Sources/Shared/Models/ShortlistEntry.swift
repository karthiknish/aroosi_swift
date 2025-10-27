import Foundation

public struct ShortlistEntry: Identifiable, Equatable {
    public enum Action {
        case added
        case removed
    }

    public let id: String
    public var profile: ProfileSummary
    public var note: String?

    public init(id: String, profile: ProfileSummary, note: String? = nil) {
        self.id = id
        self.profile = profile
        self.note = note
    }
}

public struct ShortlistToggleResult: Equatable {
    public let action: ShortlistEntry.Action

    public init(action: ShortlistEntry.Action) {
        self.action = action
    }
}
