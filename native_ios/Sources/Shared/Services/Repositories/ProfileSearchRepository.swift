import Foundation

@available(iOS 17.0.0, *)
public protocol ProfileSearchRepository {
    func searchProfiles(filters: SearchFilters,
                        pageSize: Int,
                        cursor: String?) async throws -> ProfileSearchPage
}

#if os(iOS)
#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
public final class FirestoreProfileSearchRepository: ProfileSearchRepository {
    private enum Constants {
        static let usersCollection = "users"
        static let profilesCollection = "profiles"
        static let lastActiveField = "lastActiveAt"
        static let ageField = "age"
        static let genderField = "preferredGender"
        static let locationField = "location"
        static let isActiveField = "isActive"
        static let interestsField = "interests"
        static let maxPageSize = 50
    }

    private let db: Firestore
    private let logger = Logger.shared
    private var cursorCache: [String: DocumentSnapshot] = [:]

    private struct CollectionSearchResult {
        let profiles: [ProfileSummary]
        let lastSnapshot: DocumentSnapshot?
        let hasMore: Bool
    }

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func searchProfiles(filters: SearchFilters,
                               pageSize: Int,
                               cursor: String?) async throws -> ProfileSearchPage {
        let limit = min(max(pageSize, 1), Constants.maxPageSize)

        do {
            // Search both collections and merge results
            let usersResult = try await searchInCollection(
                collectionName: Constants.usersCollection,
                filters: filters,
                limit: limit,
                cursor: cursor
            )
            
            let profilesResult = try await searchInCollection(
                collectionName: Constants.profilesCollection,
                filters: filters,
                limit: limit,
                cursor: cursor
            )
            
            // Merge and deduplicate profiles
            var allProfiles = usersResult.profiles + profilesResult.profiles
            
            // Remove duplicates (keep the one from users collection if same ID exists)
            var seenIDs = Set<String>()
            var uniqueProfiles: [ProfileSummary] = []
            
            for profile in allProfiles {
                if !seenIDs.contains(profile.id) {
                    seenIDs.insert(profile.id)
                    uniqueProfiles.append(profile)
                }
            }
            
            // Sort by last active date
            uniqueProfiles.sort { profile1, profile2 in
                switch (profile1.lastActiveAt, profile2.lastActiveAt) {
                case (nil, nil): return false
                case (nil, _): return false
                case (_, nil): return true
                case (let date1?, let date2?): return date1 > date2
                }
            }
            
            // Apply text search filter if needed
            if let queryString = filters.trimmedQuery?.lowercased(), !queryString.isEmpty {
                uniqueProfiles = uniqueProfiles.filter { profile in
                    let name = profile.displayName.lowercased()
                    if name.contains(queryString) { return true }

                    if let location = profile.location?.lowercased(), location.contains(queryString) {
                        return true
                    }

                    return profile.interests.contains { $0.lowercased().contains(queryString) }
                }
            }

            if !filters.interests.isEmpty {
                let required = filters.interests.map { $0.lowercased() }
                uniqueProfiles = uniqueProfiles.filter { profile in
                    let profileInterests = Set(profile.interests.map { $0.lowercased() })
                    return required.allSatisfy { profileInterests.contains($0) }
                }
            }
            
            // Limit results
            if uniqueProfiles.count > limit {
                uniqueProfiles = Array(uniqueProfiles.prefix(limit))
            }

            let hasMoreResults = usersResult.hasMore || profilesResult.hasMore
            var nextCursor: String?

            if hasMoreResults {
                let cursorKey = UUID().uuidString

                if let lastUsersSnapshot = usersResult.lastSnapshot {
                    cursorCache[cacheKey(for: cursorKey, collection: Constants.usersCollection)] = lastUsersSnapshot
                }

                if let lastProfilesSnapshot = profilesResult.lastSnapshot {
                    cursorCache[cacheKey(for: cursorKey, collection: Constants.profilesCollection)] = lastProfilesSnapshot
                }

                if cursorCache.keys.contains(where: { $0.hasPrefix(cursorKey) }) {
                    nextCursor = cursorKey
                }
            }

            return ProfileSearchPage(items: uniqueProfiles, nextCursor: nextCursor)
        } catch {
            throw mapError(error)
        }
    }
    
    private func searchInCollection(collectionName: String,
                                   filters: SearchFilters,
                                   limit: Int,
                                   cursor: String?) async throws -> CollectionSearchResult {
        var query: Query = db.collection(collectionName)
            .whereField(Constants.isActiveField, isEqualTo: true)
            .order(by: Constants.lastActiveField, descending: true)
            .limit(to: limit)

        if let minAge = filters.minAge {
            query = query.whereField(Constants.ageField, isGreaterThanOrEqualTo: minAge)
        }

        if let maxAge = filters.maxAge {
            query = query.whereField(Constants.ageField, isLessThanOrEqualTo: maxAge)
        }

        if let gender = filters.preferredGender, !gender.isEmpty {
            query = query.whereField(Constants.genderField, isEqualTo: gender)
        }

        if let city = filters.city, !city.isEmpty {
            query = query.whereField(Constants.locationField, isEqualTo: city)
        }

        if let firstInterest = filters.interests.sorted().first {
            query = query.whereField(Constants.interestsField, arrayContains: firstInterest)
        }

        if let cursor,
           let snapshot = cursorCache.removeValue(forKey: cacheKey(for: cursor, collection: collectionName)) {
            query = query.start(afterDocument: snapshot)
        }

        let snapshot = try await query.getDocuments()
        var profiles: [ProfileSummary] = []
        profiles.reserveCapacity(snapshot.documents.count)

        for document in snapshot.documents {
            var data = document.data()
            if let timestamp = data[Constants.lastActiveField] as? Timestamp {
                data[Constants.lastActiveField] = timestamp.dateValue()
            }

            guard let profile = ProfileSummary(id: document.documentID, data: data) else { continue }
            profiles.append(profile)
        }
        let lastSnapshot = snapshot.documents.last
        let hasMore = snapshot.documents.count == limit
        
        return CollectionSearchResult(profiles: profiles,
                                      lastSnapshot: lastSnapshot,
                                      hasMore: hasMore)
    }

    private func cacheKey(for cursor: String, collection: String) -> String {
        "\(cursor)::\(collection)"
    }

    private func mapError(_ error: Error) -> Error {
        if let firestoreError = error as NSError?,
           let code = FirestoreErrorCode.Code(rawValue: firestoreError.code) {
            switch code {
            case .permissionDenied:
                return RepositoryError.permissionDenied
            case .notFound:
                return RepositoryError.notFound
            case .alreadyExists:
                return RepositoryError.alreadyExists
            case .unavailable, .deadlineExceeded:
                return RepositoryError.networkFailure
            default:
                break
            }
        }

        logger.error("Firestore search error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
}
#endif
#else
@available(iOS 17.0.0, *)
public final class FirestoreProfileSearchRepository: ProfileSearchRepository {
    public init() {}

    public func searchProfiles(filters: SearchFilters,
                               pageSize: Int,
                               cursor: String?) async throws -> ProfileSearchPage {
        throw RepositoryError.unsupportedPlatform
    }
}
#endif
