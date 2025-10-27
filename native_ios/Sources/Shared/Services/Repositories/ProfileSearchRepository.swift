import Foundation

@available(iOS 17.0.0, *)
public protocol ProfileSearchRepository {
    func searchProfiles(filters: SearchFilters,
                        pageSize: Int,
                        cursor: String?) async throws -> ProfileSearchPage
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
public final class FirestoreProfileSearchRepository: ProfileSearchRepository {
    private enum Constants {
        static let collection = "profiles"
        static let lastActiveField = "lastActiveAt"
        static let ageField = "age"
        static let genderField = "preferredGender"
        static let locationField = "location"
        static let maxPageSize = 50
    }

    private let db: Firestore
    private let logger = Logger.shared
    private var cursorCache: [String: DocumentSnapshot] = [:]

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func searchProfiles(filters: SearchFilters,
                               pageSize: Int,
                               cursor: String?) async throws -> ProfileSearchPage {
        let limit = min(max(pageSize, 1), Constants.maxPageSize)

        var query: Query = db.collection(Constants.collection)
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

        if let cursor, let snapshot = cursorCache.removeValue(forKey: cursor) {
            query = query.start(afterDocument: snapshot)
        }

        do {
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

            if let queryString = filters.trimmedQuery?.lowercased(), !queryString.isEmpty {
                profiles = profiles.filter { profile in
                    let name = profile.displayName.lowercased()
                    if name.contains(queryString) { return true }

                    if let location = profile.location?.lowercased(), location.contains(queryString) {
                        return true
                    }

                    return profile.interests.contains { $0.lowercased().contains(queryString) }
                }
            }

            if profiles.count > limit {
                profiles = Array(profiles.prefix(limit))
            }

            var nextCursor: String?
            if snapshot.documents.count == limit, let lastSnapshot = snapshot.documents.last {
                let token = UUID().uuidString
                cursorCache[token] = lastSnapshot
                nextCursor = token
            }

            return ProfileSearchPage(items: profiles, nextCursor: nextCursor)
        } catch {
            throw mapError(error)
        }
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
#else
@available(iOS 17.0.0, *)
public final class FirestoreProfileSearchRepository: ProfileSearchRepository {
    public init() {}

    public func searchProfiles(filters: SearchFilters,
                               pageSize: Int,
                               cursor: String?) async throws -> ProfileSearchPage {
        throw RepositoryError.unknown
    }
}
#endif
