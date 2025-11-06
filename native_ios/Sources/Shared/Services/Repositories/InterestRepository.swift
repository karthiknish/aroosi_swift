import Foundation

#if os(iOS)

@available(iOS 17.0.0, *)
public protocol InterestRepository {
    func sendInterest(from userID: String, to targetUserID: String) async throws
    func checkForMutualInterest(userID: String, targetID: String) async throws -> [Interest]
    func respondToInterest(id: String, response: InterestResponse) async throws
    func updateInterestStatuses(userID: String, targetID: String, status: Interest.Status) async throws
}

@available(iOS 15.0, macOS 10.15, *)
public protocol InterestRepositoryWithStreaming: InterestRepository {
    func streamPendingInterests(for userID: String) -> AsyncThrowingStream<[Interest], Error>
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
public final class FirestoreInterestRepository: InterestRepositoryWithStreaming {
    private enum Constants {
        static let collection = "interests"
        static let fromUserField = "fromUserId"
        static let toUserField = "toUserId"
        static let statusField = "status"
        static let createdAtField = "createdAt"
    }

    private let db: Firestore
    private let logger = Logger.shared

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func sendInterest(from userID: String, to targetUserID: String) async throws {
        // Check if interest already exists
        let existingInterests = try await checkForExistingInterest(from: userID, to: targetUserID)
        if !existingInterests.isEmpty {
            throw RepositoryError.alreadyExists
        }
        
        let payload: [String: Any] = [
            Constants.fromUserField: userID,
            Constants.toUserField: targetUserID,
            Constants.statusField: "pending",
            Constants.createdAtField: FieldValue.serverTimestamp()
        ]

        do {
            _ = try await db.collection(Constants.collection).addDocument(data: payload)
            
            // Check for mutual interest and potentially create match
            let mutualInterests = try await checkForMutualInterest(userID: userID, targetID: targetUserID)
            if !mutualInterests.isEmpty {
                // Mutual interest detected - update both interests to matched
                try await updateInterestStatuses(userID: userID, targetID: targetUserID, status: .matched)
                
                // Trigger match creation (this will be handled by MatchCreationService)
                NotificationCenter.default.post(
                    name: .mutualInterestDetected,
                    object: (userID: userID, targetID: targetUserID)
                )
            }
        } catch {
            throw mapError(error)
        }
    }
    
    public func checkForMutualInterest(userID: String, targetID: String) async throws -> [Interest] {
        let query = db.collection(Constants.collection)
            .whereField(Constants.fromUserField, isEqualTo: targetID)
            .whereField(Constants.toUserField, isEqualTo: userID)
            .whereField(Constants.statusField, isEqualTo: "pending")
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { document in
            try? Interest(id: document.documentID, data: document.data())
        }
    }
    
    public func respondToInterest(id: String, response: InterestResponse) async throws {
        let documentRef = db.collection(Constants.collection).document(id)
        
        let updateData: [String: Any] = [
            Constants.statusField: response.status.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let message = response.message {
            var dataWithMessage = updateData
            dataWithMessage["message"] = message
            try await documentRef.updateData(dataWithMessage)
        } else {
            try await documentRef.updateData(updateData)
        }
    }
    
    public func updateInterestStatuses(userID: String, targetID: String, status: Interest.Status) async throws {
        // Update interest from userID to targetID
        let fromQuery = db.collection(Constants.collection)
            .whereField(Constants.fromUserField, isEqualTo: userID)
            .whereField(Constants.toUserField, isEqualTo: targetID)
        
        let fromSnapshot = try await fromQuery.getDocuments()
        for document in fromSnapshot.documents {
            try await document.reference.updateData([
                Constants.statusField: status.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
        
        // Update interest from targetID to userID
        let toQuery = db.collection(Constants.collection)
            .whereField(Constants.fromUserField, isEqualTo: targetID)
            .whereField(Constants.toUserField, isEqualTo: userID)
        
        let toSnapshot = try await toQuery.getDocuments()
        for document in toSnapshot.documents {
            try await document.reference.updateData([
                Constants.statusField: status.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }
    
    public func streamPendingInterests(for userID: String) -> AsyncThrowingStream<[Interest], Error> {
        AsyncThrowingStream { continuation in
            let query = db.collection(Constants.collection)
                .whereField(Constants.toUserField, isEqualTo: userID)
                .whereField(Constants.statusField, isEqualTo: "pending")
                .order(by: Constants.createdAtField, descending: true)
            
            let listener = query.addSnapshotListener { snapshot, error in
                if let error = error {
                    continuation.finish(throwing: self.mapError(error))
                    return
                }
                
                guard let snapshot = snapshot else {
                    continuation.finish(throwing: RepositoryError.unknown)
                    return
                }
                
                do {
                    let interests = try snapshot.documents.compactMap { document in
                        try Interest(id: document.documentID, data: document.data())
                    }
                    continuation.yield(interests)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    private func checkForExistingInterest(from userID: String, to targetUserID: String) async throws -> [Interest] {
        let query = db.collection(Constants.collection)
            .whereField(Constants.fromUserField, isEqualTo: userID)
            .whereField(Constants.toUserField, isEqualTo: targetUserID)
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { document in
            try? Interest(id: document.documentID, data: document.data())
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

        logger.error("Firestore interest error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
}
#else
@available(iOS 17.0.0, *)
public final class FirestoreInterestRepository: InterestRepository {
    public init() {}

    public func sendInterest(from userID: String, to targetUserID: String) async throws {
        throw RepositoryError.unknown
    }
}
#endif
#endif

// MARK: - Notification Extensions
import Foundation

public extension Notification.Name {
    static let mutualInterestDetected = Notification.Name("mutualInterestDetected")
}
