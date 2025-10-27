import Foundation

public struct SearchFilters: Equatable {
    public var query: String?
    public var city: String?
    public var minAge: Int?
    public var maxAge: Int?
    public var preferredGender: String?
    public var pageSize: Int?

    public init(query: String? = nil,
                city: String? = nil,
                minAge: Int? = nil,
                maxAge: Int? = nil,
                preferredGender: String? = nil,
                pageSize: Int? = nil) {
        self.query = query?.nonEmpty
        self.city = city?.nonEmpty
        self.minAge = minAge
        self.maxAge = maxAge
        self.preferredGender = preferredGender?.nonEmpty
        self.pageSize = pageSize
    }

    public var trimmedQuery: String? {
        query?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
    }

    public func updating(query: String?) -> SearchFilters {
        var next = self
        next.query = query?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
        return next
    }

    public func updating(city: String?) -> SearchFilters {
        var next = self
        next.city = city?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
        return next
    }

    public func updating(minAge: Int?, maxAge: Int?) -> SearchFilters {
        var next = self
        next.minAge = minAge
        next.maxAge = maxAge
        return next
    }

    public func updating(preferredGender: String?) -> SearchFilters {
        var next = self
        next.preferredGender = preferredGender?.nonEmpty
        return next
    }

    public func updating(pageSize: Int?) -> SearchFilters {
        var next = self
        next.pageSize = pageSize
        return next
    }
}

public struct ProfileSearchPage {
    public enum Metadata: Equatable {
        case none
        case favorites
        case shortlist(notes: [String: String])
    }

    public let items: [ProfileSummary]
    public let nextCursor: String?
    public let metadata: Metadata

    public init(items: [ProfileSummary], nextCursor: String?, metadata: Metadata = .none) {
        self.items = items
        self.nextCursor = nextCursor
        self.metadata = metadata
    }

    public var hasMore: Bool { nextCursor != nil }
}
