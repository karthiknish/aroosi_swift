import Foundation

@available(iOS 17.0.0, *)
public protocol AdminRepository {
    func fetchOverviewMetrics(lookbackDays: Int) async throws -> AdminOverviewMetrics
    func fetchRecentMembers(limit: Int) async throws -> [AdminUserSummary]
    func fetchTopActiveMembers(limit: Int, lookbackDays: Int) async throws -> [AdminUserSummary]
}

@available(iOS 17.0.0, *)
public struct AdminOverviewMetrics: Equatable {
    public let totalMembers: Int
    public let activeMembers: Int
    public let newMembers: Int
    public let matchesCreated: Int
    public let conversationsActive: Int

    public init(totalMembers: Int,
                activeMembers: Int,
                newMembers: Int,
                matchesCreated: Int,
                conversationsActive: Int) {
        self.totalMembers = totalMembers
        self.activeMembers = activeMembers
        self.newMembers = newMembers
        self.matchesCreated = matchesCreated
        self.conversationsActive = conversationsActive
    }
}

@available(iOS 17.0.0, *)
public struct AdminUserSummary: Identifiable, Equatable {
    public let id: String
    public let displayName: String
    public let email: String?
    public let location: String?
    public let avatarURL: URL?
    public let joinedAt: Date?
    public let lastActiveAt: Date?
    public let profileCompletion: Double?
    public let flagged: Bool

    public init(id: String,
                displayName: String,
                email: String?,
                location: String?,
                avatarURL: URL?,
                joinedAt: Date?,
                lastActiveAt: Date?,
                profileCompletion: Double?,
                flagged: Bool) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.location = location
        self.avatarURL = avatarURL
        self.joinedAt = joinedAt
        self.lastActiveAt = lastActiveAt
        self.profileCompletion = profileCompletion
        self.flagged = flagged
    }
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
public final class FirestoreAdminRepository: AdminRepository {
    private enum Constants {
        static let usersCollection = "users"
        static let matchesCollection = "matches"
        static let conversationsCollection = "conversations"
        static let createdAtField = "createdAt"
        static let lastActiveAtField = "lastActiveAt"
        static let avatarField = "avatarURL"
        static let profileImageField = "profileImage"
        static let profileCompletionField = "profileCompletion"
        static let flaggedField = "isFlagged"
        static let locationField = "location"
        static let displayNameField = "displayName"
        static let emailField = "email"
    }

    private let db: Firestore
    private let logger = Logger.shared

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func fetchOverviewMetrics(lookbackDays: Int) async throws -> AdminOverviewMetrics {
        let now = Date()
        let since = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: now) ?? now.addingTimeInterval(TimeInterval(-lookbackDays * 86_400))
        let timestamp = Timestamp(date: since)

        async let totalMembers = count(query: db.collection(Constants.usersCollection))
        async let activeMembers = count(query: db.collection(Constants.usersCollection)
            .whereField(Constants.lastActiveAtField, isGreaterThanOrEqualTo: timestamp))
        async let newMembers = count(query: db.collection(Constants.usersCollection)
            .whereField(Constants.createdAtField, isGreaterThanOrEqualTo: timestamp))
        async let matchesCreated = count(query: db.collection(Constants.matchesCollection)
            .whereField(Constants.createdAtField, isGreaterThanOrEqualTo: timestamp))
        async let conversationsActive = count(query: db.collection(Constants.conversationsCollection)
            .whereField("lastActivityAt", isGreaterThanOrEqualTo: timestamp))

        do {
            return try await AdminOverviewMetrics(
                totalMembers: totalMembers,
                activeMembers: activeMembers,
                newMembers: newMembers,
                matchesCreated: matchesCreated,
                conversationsActive: conversationsActive
            )
        } catch {
            logger.error("Failed to fetch admin overview: \(error.localizedDescription)")
            throw mapError(error)
        }
    }

    public func fetchRecentMembers(limit: Int) async throws -> [AdminUserSummary] {
        do {
            let snapshot = try await db.collection(Constants.usersCollection)
                .order(by: Constants.createdAtField, descending: true)
                .limit(to: limit)
                .getDocuments()
            return snapshot.documents.compactMap(makeSummary(from:))
        } catch {
            logger.error("Failed to fetch recent members: \(error.localizedDescription)")
            throw mapError(error)
        }
    }

    public func fetchTopActiveMembers(limit: Int, lookbackDays: Int) async throws -> [AdminUserSummary] {
        let now = Date()
        let since = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: now) ?? now.addingTimeInterval(TimeInterval(-lookbackDays * 86_400))
        let timestamp = Timestamp(date: since)

        do {
            let snapshot = try await db.collection(Constants.usersCollection)
                .whereField(Constants.lastActiveAtField, isGreaterThanOrEqualTo: timestamp)
                .order(by: Constants.lastActiveAtField, descending: true)
                .limit(to: limit)
                .getDocuments()
            return snapshot.documents.compactMap(makeSummary(from:))
        } catch {
            logger.error("Failed to fetch active members: \(error.localizedDescription)")
            throw mapError(error)
        }
    }

    private func count(query: Query) async throws -> Int {
        do {
            if #available(iOS 13.0, *) {
                let snapshot = try await query.count.getAggregation(source: .server)
                return snapshot.count.intValue
            } else {
                let snapshot = try await query.getDocuments()
                return snapshot.documents.count
            }
        } catch {
            if isUnsupportedAggregation(error: error) {
                let snapshot = try await query.getDocuments()
                return snapshot.documents.count
            }
            throw error
        }
    }

    private func makeSummary(from document: QueryDocumentSnapshot) -> AdminUserSummary? {
        let data = document.data()
        let displayName = (data[Constants.displayNameField] as? String)?.nonEmpty ?? "Member"
        let email = (data[Constants.emailField] as? String)?.nonEmpty
        let location = (data[Constants.locationField] as? String)?.nonEmpty
            ?? (data["city"] as? String)?.nonEmpty
        let avatarURL = (data[Constants.avatarField] as? String)?.url ?? (data[Constants.profileImageField] as? String)?.url
        let joinedAt = ((data[Constants.createdAtField] as? Timestamp)
            ?? (data["joinedAt"] as? Timestamp)
            ?? (data["created_at"] as? Timestamp))?.dateValue()
        let lastActiveAt = ((data[Constants.lastActiveAtField] as? Timestamp)
            ?? (data["lastSeenAt"] as? Timestamp))?.dateValue()
        let completionNumber = data[Constants.profileCompletionField] as? NSNumber
        let completion = completionNumber?.doubleValue ?? (data[Constants.profileCompletionField] as? Double)
        let flagged = (data[Constants.flaggedField] as? Bool) ?? false

        return AdminUserSummary(
            id: document.documentID,
            displayName: displayName,
            email: email,
            location: location,
            avatarURL: avatarURL,
            joinedAt: joinedAt,
            lastActiveAt: lastActiveAt,
            profileCompletion: completion,
            flagged: flagged
        )
    }

    private func isUnsupportedAggregation(error: Error) -> Bool {
        guard let nsError = error as NSError?,
              let code = FirestoreErrorCode.Code(rawValue: nsError.code) else {
            return false
        }
        return code == .unimplemented
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

        logger.error("Firestore admin repository error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
}

private extension String {
    var url: URL? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: trimmed)
    }
}

#else

@available(iOS 17.0.0, *)
public final class FirestoreAdminRepository: AdminRepository {
    public init() {}

    public func fetchOverviewMetrics(lookbackDays: Int) async throws -> AdminOverviewMetrics {
        throw RepositoryError.unknown
    }

    public func fetchRecentMembers(limit: Int) async throws -> [AdminUserSummary] {
        throw RepositoryError.unknown
    }

    public func fetchTopActiveMembers(limit: Int, lookbackDays: Int) async throws -> [AdminUserSummary] {
        throw RepositoryError.unknown
    }
}

#endif
