import Foundation

@available(iOS 17.0.0, *)
public protocol SafetyRepository {
    func fetchBlockedUsers() async throws -> [BlockedUser]
    func block(userID: String) async throws
    func unblock(userID: String) async throws
    func report(userID: String, reason: String, details: String?) async throws
    func status(for userID: String) async throws -> SafetyStatus
    func fetchSubmittedReports() async throws -> [SafetyReport]
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseAuth

@available(iOS 17.0.0, *)
public final class FirestoreSafetyRepository: SafetyRepository {
    private enum Constants {
        static let blocksCollection = "blocks"
        static let reportsCollection = "reports"
    }

    private let db: Firestore
    private let logger = Logger.shared
    private let profileRepository: ProfileRepository

    public init(db: Firestore = .firestore(),
                profileRepository: ProfileRepository? = nil) {
        self.db = db
        if let profileRepository = profileRepository {
            self.profileRepository = profileRepository
        } else {
            if #available(iOS 15.0, macOS 10.15, *) {
                self.profileRepository = FirestoreProfileRepository()
            } else {
                // Fallback for older versions - would need a non-streaming implementation
                fatalError("ProfileRepository requires iOS 15.0+ or macOS 10.15+")
            }
        }
    }

    public func fetchBlockedUsers() async throws -> [BlockedUser] {
        let currentUserID = try currentUserIdentifier()

        let snapshot = try await db.collection(Constants.blocksCollection)
            .whereField("blockerId", isEqualTo: currentUserID)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        var blocked: [BlockedUser] = []
        blocked.reserveCapacity(snapshot.documents.count)

        for document in snapshot.documents {
            let data = document.data()
            guard let blockedID = data["blockedUserId"] as? String else { continue }
            let blockedAt = (data["createdAt"] as? Timestamp)?.dateValue()

            let profile = try? await profileRepository.fetchProfile(id: blockedID)
            let displayName = profile?.displayName ?? data["blockedUserName"] as? String ?? "Member"
            let avatarURL = profile?.avatarURL

            blocked.append(BlockedUser(id: blockedID,
                                       displayName: displayName,
                                       avatarURL: avatarURL,
                                       blockedAt: blockedAt))
        }

        return blocked
    }

    public func block(userID: String) async throws {
        let currentUserID = try currentUserIdentifier()
        guard currentUserID != userID else { return }

        let docRef = db.collection(Constants.blocksCollection)
            .document("\(currentUserID)_\(userID)")

        do {
            try await docRef.setData([
                "blockerId": currentUserID,
                "blockedUserId": userID,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)
        } catch {
            throw mapError(error)
        }
    }

    public func unblock(userID: String) async throws {
        let currentUserID = try currentUserIdentifier()
        guard currentUserID != userID else { return }

        let query = db.collection(Constants.blocksCollection)
            .whereField("blockerId", isEqualTo: currentUserID)
            .whereField("blockedUserId", isEqualTo: userID)

        let snapshot = try await query.getDocuments()
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }

    public func report(userID: String, reason: String, details: String?) async throws {
        let currentUserID = try currentUserIdentifier()
        guard currentUserID != userID else { return }

        _ = try await db.collection(Constants.reportsCollection).addDocument(data: [
            "reporterId": currentUserID,
            "reportedUserId": userID,
            "reason": reason,
            "description": details ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "status": "pending"
        ])
    }

    public func status(for userID: String) async throws -> SafetyStatus {
        let currentUserID = try currentUserIdentifier()

        async let blockedSnapshot = db.collection(Constants.blocksCollection)
            .whereField("blockerId", isEqualTo: currentUserID)
            .whereField("blockedUserId", isEqualTo: userID)
            .limit(to: 1)
            .getDocuments()

        async let blockedBySnapshot = db.collection(Constants.blocksCollection)
            .whereField("blockerId", isEqualTo: userID)
            .whereField("blockedUserId", isEqualTo: currentUserID)
            .limit(to: 1)
            .getDocuments()

        let (blocked, blockedBy) = try await (blockedSnapshot, blockedBySnapshot)
        let isBlocked = !blocked.documents.isEmpty
        let isBlockedBy = !blockedBy.documents.isEmpty
        return SafetyStatus(isBlocked: isBlocked,
                            isBlockedBy: isBlockedBy,
                            canInteract: !(isBlocked || isBlockedBy))
    }

    public func fetchSubmittedReports() async throws -> [SafetyReport] {
        let currentUserID = try currentUserIdentifier()

        let snapshot = try await db.collection(Constants.reportsCollection)
            .whereField("reporterId", isEqualTo: currentUserID)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        var reports: [SafetyReport] = []
        reports.reserveCapacity(snapshot.documents.count)

        for document in snapshot.documents {
            let data = document.data()
            guard let reportedUserID = data["reportedUserId"] as? String else { continue }
            let reason = data["reason"] as? String ?? ""
            let details = data["description"] as? String
            let submittedAt = (data["createdAt"] as? Timestamp)?.dateValue()
            let status = ReportStatus(rawValue: data["status"] as? String ?? "") ?? .pending

            reports.append(SafetyReport(id: document.documentID,
                                        reportedUserID: reportedUserID,
                                        reason: reason,
                                        details: details,
                                        submittedAt: submittedAt ?? Date(),
                                        status: status))
        }

        return reports
    }

    private func currentUserIdentifier() throws -> String {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw RepositoryError.permissionDenied
        }
        return userID
    }

    private func mapError(_ error: Error) -> Error {
        if let firestoreError = error as NSError?,
           let codeValue = FirestoreErrorCode.Code(rawValue: firestoreError.code) {
            switch codeValue {
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

        logger.error("Firestore safety error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
}
#else
@available(iOS 17.0.0, *)
public final class FirestoreSafetyRepository: SafetyRepository {
    public init() {}

    public func fetchBlockedUsers() async throws -> [BlockedUser] { [] }
    public func block(userID: String) async throws {}
    public func unblock(userID: String) async throws {}
    public func report(userID: String, reason: String, details: String?) async throws {}
    public func status(for userID: String) async throws -> SafetyStatus { SafetyStatus() }
    public func fetchSubmittedReports() async throws -> [SafetyReport] { [] }
}
#endif
