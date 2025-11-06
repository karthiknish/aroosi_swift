import Foundation

public struct SearchFilters: Equatable {
    public var query: String?
    public var city: String?
    public var minAge: Int?
    public var maxAge: Int?
    public var preferredGender: String?
    public var pageSize: Int?
    public var interests: Set<String>

    public init(query: String? = nil,
                city: String? = nil,
                minAge: Int? = nil,
                maxAge: Int? = nil,
                preferredGender: String? = nil,
                pageSize: Int? = nil,
                interests: Set<String> = []) {
        self.query = query?.nonEmpty
        self.city = city?.nonEmpty
        self.minAge = minAge
        self.maxAge = maxAge
        self.preferredGender = preferredGender?.nonEmpty
        self.pageSize = pageSize
        self.interests = SearchFilters.normalize(interests: interests)
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

    public func updating(interests: Set<String>) -> SearchFilters {
        var next = self
        next.interests = SearchFilters.normalize(interests: interests)
        return next
    }
}

private extension SearchFilters {
    static func normalize(interests: Set<String>) -> Set<String> {
        Set(
            interests
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
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
