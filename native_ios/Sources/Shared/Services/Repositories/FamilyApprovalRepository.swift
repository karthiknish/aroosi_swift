import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
public final class FamilyApprovalRepository {
    private enum Constants {
        static let requestsCollection = "family_approval_requests"
        static let familyMembersCollection = "family_members"
    }
    
    private let db: Firestore
    private let logger = Logger.shared
    
    public init(db: Firestore = .firestore()) {
        self.db = db
    }
    
    // MARK: - Fetch Requests
    
    public func fetchReceivedRequests(userId: String) async throws -> [FamilyApprovalRequest] {
        let snapshot = try await db.collection(Constants.requestsCollection)
            .whereField("familyMemberId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? parseRequest(from: $0) }
    }
    
    public func fetchSentRequests(userId: String) async throws -> [FamilyApprovalRequest] {
        let snapshot = try await db.collection(Constants.requestsCollection)
            .whereField("requesterId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? parseRequest(from: $0) }
    }
    
    public func fetchAllRequests(userId: String) async throws -> [FamilyApprovalRequest] {
        // Optimized: Use Filter.or() instead of two separate queries
        let filter = Filter.orFilter([
            Filter.whereField("requesterId", isEqualTo: userId),
            Filter.whereField("familyMemberId", isEqualTo: userId)
        ])
        
        let snapshot = try await db.collection(Constants.requestsCollection)
            .whereFilter(filter)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> FamilyApprovalRequest? in
            try? parseRequest(from: document)
        }
    }
    
    public func fetchRequest(id: String) async throws -> FamilyApprovalRequest {
        let document = try await db.collection(Constants.requestsCollection)
            .document(id)
            .getDocument()
        
        guard document.exists, let request = try? parseRequest(from: document) else {
            throw RepositoryError.notFound
        }
        
        return request
    }
    
    // MARK: - Create Request
    
    public func createRequest(
        requesterId: String,
        targetUserId: String,
        message: String,
        familyMembers: [FamilyMember]
    ) async throws -> FamilyApprovalRequest {
        // Optimized: Use batch write instead of loop for better performance
        let batch = db.batch()
        var requestRefs: [DocumentReference] = []
        
        let approvalMembers = familyMembers.filter { $0.canApprove }
        guard !approvalMembers.isEmpty else {
            throw RepositoryError.invalidData
        }
        
        for member in approvalMembers {
            let requestData: [String: Any] = [
                "requesterId": requesterId,
                "targetUserId": targetUserId,
                "status": ApprovalStatus.pending.rawValue,
                "createdAt": FieldValue.serverTimestamp(),
                "message": message,
                "familyMemberId": member.id,
                "familyMemberName": member.name,
                "familyMemberRelation": member.relation.rawValue,
                "approved": false
            ]
            
            let docRef = db.collection(Constants.requestsCollection).document()
            batch.setData(requestData, forDocument: docRef)
            requestRefs.append(docRef)
        }
        
        // Commit all writes atomically
        try await batch.commit()
        
        // Return the first request (all have the same core data)
        let firstMember = approvalMembers[0]
        return FamilyApprovalRequest(
            id: requestRefs[0].documentID,
            requesterId: requesterId,
            targetUserId: targetUserId,
            status: .pending,
            createdAt: Date(),
            message: message,
            familyMemberId: firstMember.id,
            familyMemberName: firstMember.name,
            familyMemberRelation: firstMember.relation.rawValue,
            approved: false
        )
    }
    
    // MARK: - Respond to Request
    
    public func respondToRequest(
        requestId: String,
        decision: ApprovalDecision,
        response: String?
    ) async throws {
        let status = decision == .approve ? ApprovalStatus.approved : ApprovalStatus.rejected
        
        var updateData: [String: Any] = [
            "status": status.rawValue,
            "approved": decision == .approve,
            "respondedAt": FieldValue.serverTimestamp()
        ]
        
        if let response = response {
            updateData["response"] = response
        }
        
        try await db.collection(Constants.requestsCollection)
            .document(requestId)
            .updateData(updateData)
    }
    
    // MARK: - Cancel Request
    
    public func cancelRequest(requestId: String) async throws {
        try await db.collection(Constants.requestsCollection)
            .document(requestId)
            .updateData([
                "status": ApprovalStatus.cancelled.rawValue,
                "respondedAt": FieldValue.serverTimestamp()
            ])
    }
    
    // MARK: - Family Members
    
    public func fetchFamilyMembers(userId: String) async throws -> [FamilyMember] {
        let snapshot = try await db.collection(Constants.familyMembersCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt")
            .getDocuments()
        
        return snapshot.documents.compactMap { try? parseFamilyMember(from: $0) }
    }
    
    public func addFamilyMember(
        userId: String,
        name: String,
        relation: FamilyRelation,
        email: String?,
        phone: String?,
        canApprove: Bool = true
    ) async throws -> FamilyMember {
        let memberData: [String: Any] = [
            "userId": userId,
            "name": name,
            "relation": relation.rawValue,
            "email": email ?? NSNull(),
            "phone": phone ?? NSNull(),
            "canApprove": canApprove,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        let docRef = try await db.collection(Constants.familyMembersCollection)
            .addDocument(data: memberData)
        
        return FamilyMember(
            id: docRef.documentID,
            userId: userId,
            name: name,
            relation: relation,
            email: email,
            phone: phone,
            canApprove: canApprove,
            createdAt: Date()
        )
    }
    
    public func updateFamilyMember(member: FamilyMember) async throws {
        var updateData: [String: Any] = [
            "name": member.name,
            "relation": member.relation.rawValue,
            "canApprove": member.canApprove
        ]
        
        if let email = member.email {
            updateData["email"] = email
        }
        if let phone = member.phone {
            updateData["phone"] = phone
        }
        
        try await db.collection(Constants.familyMembersCollection)
            .document(member.id)
            .updateData(updateData)
    }
    
    public func deleteFamilyMember(memberId: String) async throws {
        try await db.collection(Constants.familyMembersCollection)
            .document(memberId)
            .delete()
    }
    
    // MARK: - Statistics
    
    public func fetchSummary(userId: String) async throws -> FamilyApprovalSummary {
        let requests = try await fetchAllRequests(userId: userId)
        let familyMembers = try await fetchFamilyMembers(userId: userId)
        
        let pending = requests.filter { $0.status == .pending }.count
        let approved = requests.filter { $0.isApproved }.count
        let rejected = requests.filter { $0.isRejected }.count
        
        return FamilyApprovalSummary(
            totalRequests: requests.count,
            pendingRequests: pending,
            approvedRequests: approved,
            rejectedRequests: rejected,
            familyMembers: familyMembers.count
        )
    }
    
    // MARK: - Parsing
    
    private func parseRequest(from document: DocumentSnapshot) throws -> FamilyApprovalRequest {
        guard let data = document.data() else {
            throw RepositoryError.invalidData
        }
        
        let requesterId = data["requesterId"] as? String ?? ""
        let targetUserId = data["targetUserId"] as? String ?? ""
        let statusString = data["status"] as? String ?? "pending"
        let status = ApprovalStatus(rawValue: statusString) ?? .pending
        let message = data["message"] as? String ?? ""
        let approved = data["approved"] as? Bool ?? false
        
        let createdTimestamp = data["createdAt"] as? Timestamp
        let createdAt = createdTimestamp?.dateValue() ?? Date()
        
        let respondedTimestamp = data["respondedAt"] as? Timestamp
        let respondedAt = respondedTimestamp?.dateValue()
        
        return FamilyApprovalRequest(
            id: document.documentID,
            requesterId: requesterId,
            targetUserId: targetUserId,
            status: status,
            createdAt: createdAt,
            message: message,
            familyMemberId: data["familyMemberId"] as? String,
            familyMemberName: data["familyMemberName"] as? String,
            familyMemberRelation: data["familyMemberRelation"] as? String,
            response: data["response"] as? String,
            respondedAt: respondedAt,
            approved: approved
        )
    }
    
    private func parseFamilyMember(from document: DocumentSnapshot) throws -> FamilyMember {
        guard let data = document.data() else {
            throw RepositoryError.invalidData
        }
        
        let userId = data["userId"] as? String ?? ""
        let name = data["name"] as? String ?? ""
        let relationString = data["relation"] as? String ?? "other"
        let relation = FamilyRelation(rawValue: relationString) ?? .other
        let canApprove = data["canApprove"] as? Bool ?? true
        
        let createdTimestamp = data["createdAt"] as? Timestamp
        let createdAt = createdTimestamp?.dateValue() ?? Date()
        
        return FamilyMember(
            id: document.documentID,
            userId: userId,
            name: name,
            relation: relation,
            email: data["email"] as? String,
            phone: data["phone"] as? String,
            canApprove: canApprove,
            createdAt: createdAt
        )
    }
}
#endif
