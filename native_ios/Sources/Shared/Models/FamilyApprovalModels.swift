import Foundation

// MARK: - Family Approval Request

public struct FamilyApprovalRequest: Codable, Identifiable, Equatable {
    public let id: String
    public let requesterId: String
    public let targetUserId: String
    public var status: ApprovalStatus
    public let createdAt: Date
    public let message: String
    public let familyMemberId: String?
    public let familyMemberName: String?
    public let familyMemberRelation: String?
    public var response: String?
    public var respondedAt: Date?
    public var approved: Bool
    
    // Related user data (populated from joins)
    public var requesterProfile: ProfileSummary?
    public var targetUserProfile: ProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case id, requesterId, targetUserId, status, createdAt, message
        case familyMemberId, familyMemberName, familyMemberRelation
        case response, respondedAt, approved
        case requesterProfile, targetUserProfile
    }
    
    public init(
        id: String,
        requesterId: String,
        targetUserId: String,
        status: ApprovalStatus,
        createdAt: Date,
        message: String,
        familyMemberId: String? = nil,
        familyMemberName: String? = nil,
        familyMemberRelation: String? = nil,
        response: String? = nil,
        respondedAt: Date? = nil,
        approved: Bool = false,
        requesterProfile: ProfileSummary? = nil,
        targetUserProfile: ProfileSummary? = nil
    ) {
        self.id = id
        self.requesterId = requesterId
        self.targetUserId = targetUserId
        self.status = status
        self.createdAt = createdAt
        self.message = message
        self.familyMemberId = familyMemberId
        self.familyMemberName = familyMemberName
        self.familyMemberRelation = familyMemberRelation
        self.response = response
        self.respondedAt = respondedAt
        self.approved = approved
        self.requesterProfile = requesterProfile
        self.targetUserProfile = targetUserProfile
    }
    
    public var isPending: Bool {
        status == .pending
    }
    
    public var isApproved: Bool {
        status == .approved && approved
    }
    
    public var isRejected: Bool {
        status == .rejected || (status == .approved && !approved)
    }
    
    @available(iOS 15.0, *)
    public var formattedCreatedDate: String {
        if #available(macOS 12.0, *) {
            return createdAt.formatted(date: .abbreviated, time: .omitted)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: createdAt)
        }
    }
    
    @available(iOS 15.0, *)
    public var formattedRespondedDate: String? {
        if #available(macOS 12.0, *) {
            return respondedAt?.formatted(date: .abbreviated, time: .omitted)
        } else {
            guard let respondedAt = respondedAt else { return nil }
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: respondedAt)
        }
    }
}

// MARK: - Approval Status

public enum ApprovalStatus: String, Codable {
    case pending
    case approved
    case rejected
    case cancelled
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        }
    }
    
    public var icon: String {
        switch self {
        case .pending: return "clock"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .cancelled: return "slash.circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        case .cancelled: return "gray"
        }
    }
}

// MARK: - Family Member

public struct FamilyMember: Codable, Identifiable, Equatable {
    public let id: String
    public let userId: String
    public let name: String
    public let relation: FamilyRelation
    public let email: String?
    public let phone: String?
    public let canApprove: Bool
    public let createdAt: Date
    
    public init(
        id: String,
        userId: String,
        name: String,
        relation: FamilyRelation,
        email: String? = nil,
        phone: String? = nil,
        canApprove: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.relation = relation
        self.email = email
        self.phone = phone
        self.canApprove = canApprove
        self.createdAt = createdAt
    }
}

// MARK: - Family Relation

public enum FamilyRelation: String, Codable, CaseIterable {
    case father
    case mother
    case brother
    case sister
    case uncle
    case aunt
    case grandparent
    case guardian
    case other
    
    public var displayName: String {
        switch self {
        case .father: return "Father"
        case .mother: return "Mother"
        case .brother: return "Brother"
        case .sister: return "Sister"
        case .uncle: return "Uncle (Paternal/Maternal)"
        case .aunt: return "Aunt (Paternal/Maternal)"
        case .grandparent: return "Grandparent"
        case .guardian: return "Legal Guardian"
        case .other: return "Other Family Member"
        }
    }
    
    public var icon: String {
        switch self {
        case .father, .uncle, .grandparent: return "person.fill"
        case .mother, .aunt: return "person.fill"
        case .brother: return "person.2.fill"
        case .sister: return "person.2.fill"
        case .guardian: return "shield.fill"
        case .other: return "person.3.fill"
        }
    }
}

// MARK: - Approval Decision

public enum ApprovalDecision: String {
    case approve = "approved"
    case reject = "rejected"
    
    public var displayName: String {
        switch self {
        case .approve: return "Approve"
        case .reject: return "Reject"
        }
    }
    
    public var icon: String {
        switch self {
        case .approve: return "checkmark.circle.fill"
        case .reject: return "xmark.circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .approve: return "green"
        case .reject: return "red"
        }
    }
}

// MARK: - Create Request Data

public struct CreateFamilyApprovalRequestData: Codable {
    public let targetUserId: String
    public let message: String
    public let familyMemberIds: [String]
    
    public init(targetUserId: String, message: String, familyMemberIds: [String]) {
        self.targetUserId = targetUserId
        self.message = message
        self.familyMemberIds = familyMemberIds
    }
}

// MARK: - Respond to Request Data

public struct RespondToApprovalRequestData: Codable {
    public let requestId: String
    public let decision: String
    public let response: String?
    
    public init(requestId: String, decision: ApprovalDecision, response: String? = nil) {
        self.requestId = requestId
        self.decision = decision.rawValue
        self.response = response
    }
}

// MARK: - Family Approval Summary

public struct FamilyApprovalSummary: Codable, Equatable {
    public let totalRequests: Int
    public let pendingRequests: Int
    public let approvedRequests: Int
    public let rejectedRequests: Int
    public let familyMembers: Int
    
    public init(
        totalRequests: Int,
        pendingRequests: Int,
        approvedRequests: Int,
        rejectedRequests: Int,
        familyMembers: Int
    ) {
        self.totalRequests = totalRequests
        self.pendingRequests = pendingRequests
        self.approvedRequests = approvedRequests
        self.rejectedRequests = rejectedRequests
        self.familyMembers = familyMembers
    }
    
    public var approvalRate: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(approvedRequests) / Double(totalRequests)
    }
}
