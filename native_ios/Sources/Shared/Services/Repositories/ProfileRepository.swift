import Foundation

#if os(iOS)
@available(iOS 17.0.0, *)
public protocol ProfileRepository {
    func fetchProfile(id: String) async throws -> ProfileSummary
    func fetchProfileDetail(id: String) async throws -> ProfileDetail
    func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error>
    func updateProfile(_ profile: ProfileSummary) async throws
    func fetchShortlist(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage
    func toggleShortlist(userID: String) async throws -> ShortlistToggleResult
    func setShortlistNote(userID: String, note: String) async throws
    func fetchFavorites(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage
    func toggleFavorite(userID: String) async throws
}

@available(iOS 17.0.0, *)
public extension ProfileRepository {
    func fetchProfileDetail(id: String) async throws -> ProfileDetail {
        let summary = try await fetchProfile(id: id)
        return ProfileDetail(summary: summary,
                              about: summary.bio,
                              gallery: summary.avatarURL.map { [$0] } ?? [],
                              interests: summary.interests,
                              languages: [],
                              motherTongue: nil,
                              education: nil,
                              occupation: nil,
                              culturalProfile: nil,
                              preferences: nil,
                              familyBackground: nil,
                              personalityTraits: [],
                              isFavorite: false,
                              isShortlisted: false)
    }
}

#if os(iOS) && canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseAuth

@available(iOS 17.0.0, *)
public final class FirestoreProfileRepository: ProfileRepository {
    private enum Constants {
        static let collection = "profiles"
        static let maxIDsPerBatch = 10
        static let favoritesCollection = "favorites"
        static let shortlistCollection = "shortlist"
        static let shortlistNotesField = "notes"
    }

    private let db: Firestore
    private let logger = Logger.shared

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func fetchProfile(id: String) async throws -> ProfileSummary {
        let document = try await db.collection(Constants.collection).document(id).getDocument()
        guard document.exists, let data = document.data() else {
            throw RepositoryError.notFound
        }

        guard let profile = ProfileSummary(id: document.documentID, data: normalize(data)) else {
            throw RepositoryError.invalidData
        }

        return profile
    }

    public func fetchProfileDetail(id: String) async throws -> ProfileDetail {
        let document = try await db.collection(Constants.collection).document(id).getDocument()
        guard document.exists, let data = document.data() else {
            throw RepositoryError.notFound
        }

        let normalized = normalize(data)

        guard let summary = ProfileSummary(id: document.documentID, data: normalized) else {
            throw RepositoryError.invalidData
        }

        let currentUserID = Auth.auth().currentUser?.uid
        let favorite = try await isFavorite(userID: id, currentUserID: currentUserID)
        let shortlisted = try await isShortlisted(userID: id, currentUserID: currentUserID)

        return ProfileDetail.build(summary: summary,
                                    data: normalized,
                                    isFavorite: favorite,
                                    isShortlisted: shortlisted)
    }

    public func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            guard !userIDs.isEmpty else {
                continuation.yield([])
                continuation.finish()
                return
            }

            let batches = stride(from: 0, to: userIDs.count, by: Constants.maxIDsPerBatch).map { start -> [String] in
                let end = min(start + Constants.maxIDsPerBatch, userIDs.count)
                return Array(userIDs[start..<end])
            }

            let listeners = ListenerStore()

            for batch in batches {
                let listener = db.collection(Constants.collection)
                    .whereField(FieldPath.documentID(), in: batch)
                    .addSnapshotListener { snapshot, error in
                        if let error {
                            continuation.yield(with: .failure(self.mapError(error)))
                            return
                        }

                        guard let documents = snapshot?.documents else { return }

                        let profiles = documents.compactMap { document -> ProfileSummary? in
                            let data = document.data()
                            return ProfileSummary(id: document.documentID, data: normalize(data))
                        }

                        continuation.yield(profiles)
                    }

                listeners.add(listener)
            }

            continuation.onTermination = { _ in
                listeners.removeAll()
            }
        }
    }

    public func updateProfile(_ profile: ProfileSummary) async throws {
        let payload = profile.toDictionary()
        do {
            try await db.collection(Constants.collection).document(profile.id).setData(payload, merge: true)
        } catch {
            throw mapError(error)
        }
    }

    public func fetchShortlist(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw RepositoryError.permissionDenied
        }

        var query: Query = db.collection(Constants.collection)
            .document(currentUserID)
            .collection(Constants.shortlistCollection)
            .order(by: "addedAt", descending: true)
            .limit(to: pageSize)

        if let documentID {
            let snapshot = try await db.collection(Constants.collection)
                .document(currentUserID)
                .collection(Constants.shortlistCollection)
                .document(documentID)
                .getDocument()
            if snapshot.exists {
                query = query.start(afterDocument: snapshot)
            }
        }

        let snapshot = try await query.getDocuments()
        let profileIDs = snapshot.documents.compactMap { $0.documentID }
        let notesMap: [String: String] = snapshot.documents.reduce(into: [:]) { partial, doc in
            if let note = doc.data()["note"] as? String, !note.isEmpty {
                partial[doc.documentID] = note
            }
        }

        let profiles = try await fetchProfiles(userIDs: profileIDs)
        var items: [ProfileSummary] = []
        items.reserveCapacity(profiles.count)

        for profile in profiles {
            items.append(profile)
        }

        let nextCursor = snapshot.documents.count == pageSize ? snapshot.documents.last?.documentID : nil
        return ProfileSearchPage(items: items, nextCursor: nextCursor, metadata: .shortlist(notes: notesMap))
    }

    public func toggleShortlist(userID: String) async throws -> ShortlistToggleResult {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw RepositoryError.permissionDenied
        }

        let docRef = db.collection(Constants.collection)
            .document(currentUserID)
            .collection(Constants.shortlistCollection)
            .document(userID)

        let snapshot = try await docRef.getDocument()
        if snapshot.exists {
            try await docRef.delete()
            return ShortlistToggleResult(action: .removed)
        } else {
            try await docRef.setData([
                "addedAt": FieldValue.serverTimestamp()
            ], merge: true)
            return ShortlistToggleResult(action: .added)
        }
    }

    public func setShortlistNote(userID: String, note: String) async throws {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw RepositoryError.permissionDenied
        }

        let docRef = db.collection(Constants.collection)
            .document(currentUserID)
            .collection(Constants.shortlistCollection)
            .document(userID)

        if note.isEmpty {
            try await docRef.updateData(["note": FieldValue.delete()])
        } else {
            try await docRef.setData([
                "note": note,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        }
    }

    public func fetchFavorites(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw RepositoryError.permissionDenied
        }

        var query: Query = db.collection(Constants.collection)
            .document(currentUserID)
            .collection(Constants.favoritesCollection)
            .order(by: "addedAt", descending: true)
            .limit(to: pageSize)

        if let documentID {
            let snapshot = try await db.collection(Constants.collection)
                .document(currentUserID)
                .collection(Constants.favoritesCollection)
                .document(documentID)
                .getDocument()
            if snapshot.exists {
                query = query.start(afterDocument: snapshot)
            }
        }

        let snapshot = try await query.getDocuments()
        let ids = snapshot.documents.map { $0.documentID }
        let profiles = try await fetchProfiles(userIDs: ids)
        let nextCursor = snapshot.documents.count == pageSize ? snapshot.documents.last?.documentID : nil
        return ProfileSearchPage(items: profiles, nextCursor: nextCursor, metadata: .favorites)
    }

    public func toggleFavorite(userID: String) async throws {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw RepositoryError.permissionDenied
        }

        let docRef = db.collection(Constants.collection)
            .document(currentUserID)
            .collection(Constants.favoritesCollection)
            .document(userID)

        let snapshot = try await docRef.getDocument()
        if snapshot.exists {
            try await docRef.delete()
        } else {
            try await docRef.setData([
                "addedAt": FieldValue.serverTimestamp()
            ])
        }
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

        logger.error("Firestore profile error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }

    private func fetchProfiles(userIDs: [String]) async throws -> [ProfileSummary] {
        if userIDs.isEmpty { return [] }

        // Optimized: Use batch queries with 'in' operator instead of sequential fetches
        var profiles: [ProfileSummary] = []
        profiles.reserveCapacity(userIDs.count)
        
        // Firestore 'in' queries support up to 10 items per batch
        let batchSize = 10
        
        for i in stride(from: 0, to: userIDs.count, by: batchSize) {
            let end = min(i + batchSize, userIDs.count)
            let batchIds = Array(userIDs[i..<end])
            
            do {
                let snapshot = try await db.collection(Constants.collection)
                    .whereField(FieldPath.documentID(), in: batchIds)
                    .getDocuments()
                
                for document in snapshot.documents {
                    let data = document.data()
                    guard let profile = ProfileSummary(id: document.documentID, data: normalize(data)) else {
                        logger.error("Failed to parse profile \(document.documentID)")
                        continue
                    }
                    profiles.append(profile)
                }
            } catch {
                logger.error("Failed to fetch profile batch: \(error.localizedDescription)")
            }
        }

        return profiles
    }

    private func isFavorite(userID: String, currentUserID: String?) async throws -> Bool {
        guard let currentUserID else { return false }
        let docRef = db.collection(Constants.collection)
            .document(currentUserID)
            .collection(Constants.favoritesCollection)
            .document(userID)
        let snapshot = try await docRef.getDocument()
        return snapshot.exists
    }

    private func isShortlisted(userID: String, currentUserID: String?) async throws -> Bool {
        guard let currentUserID else { return false }
        let docRef = db.collection(Constants.collection)
            .document(currentUserID)
            .collection(Constants.shortlistCollection)
            .document(userID)
        let snapshot = try await docRef.getDocument()
        return snapshot.exists
    }
}

private func normalize(_ data: [String: Any]) -> [String: Any] {
    var normalized = data
    if let timestamp = data["lastActiveAt"] as? Timestamp {
        normalized["lastActiveAt"] = timestamp.dateValue()
    }
    return normalized
}
#endif
#else
@available(iOS 17.0.0, *)
public protocol ProfileRepository {
    func fetchProfile(id: String) async throws -> ProfileSummary
    func fetchProfileDetail(id: String) async throws -> ProfileDetail
    func updateProfile(_ profile: ProfileSummary) async throws
    func fetchShortlist(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage
    func toggleShortlist(userID: String) async throws -> ShortlistToggleResult
    func setShortlistNote(userID: String, note: String) async throws
    func fetchFavorites(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage
    func toggleFavorite(userID: String) async throws
}

@available(iOS 15.0, macOS 10.15, *)
public protocol ProfileRepositoryWithStreaming: ProfileRepository {
    func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error>
}

@available(iOS 17.0.0, *)
public extension ProfileRepository {
    func fetchProfileDetail(id: String) async throws -> ProfileDetail {
        let summary = try await fetchProfile(id: id)
        return ProfileDetail(summary: summary,
                              about: summary.bio,
                              gallery: summary.avatarURL.map { [$0] } ?? [],
                              interests: summary.interests,
                              languages: [],
                              motherTongue: nil,
                              education: nil,
                              occupation: nil,
                              culturalProfile: nil,
                              preferences: nil,
                              familyBackground: nil,
                              personalityTraits: [],
                              isFavorite: false,
                              isShortlisted: false)
    }
}

@available(iOS 15.0, macOS 10.15, *)
public final class FirestoreProfileRepository: ProfileRepositoryWithStreaming {
    public init() {}

    public func fetchProfile(id: String) async throws -> ProfileSummary {
        throw RepositoryError.unsupportedPlatform
    }

    public func fetchProfileDetail(id: String) async throws -> ProfileDetail {
        throw RepositoryError.unsupportedPlatform
    }

    public func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: RepositoryError.unsupportedPlatform)
        }
    }

    public func updateProfile(_ profile: ProfileSummary) async throws {
        throw RepositoryError.unsupportedPlatform
    }

    public func fetchShortlist(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        throw RepositoryError.unsupportedPlatform
    }

    public func toggleShortlist(userID: String) async throws -> ShortlistToggleResult {
        throw RepositoryError.unsupportedPlatform
    }

    public func setShortlistNote(userID: String, note: String) async throws {
        throw RepositoryError.unsupportedPlatform
    }

    public func fetchFavorites(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        throw RepositoryError.unsupportedPlatform
    }

    public func toggleFavorite(userID: String) async throws {
        throw RepositoryError.unsupportedPlatform
    }
}
#endif
