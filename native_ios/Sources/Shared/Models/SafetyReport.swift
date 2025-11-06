import Foundation

@available(iOS 17.0.0, *)
public struct SafetyReport: Identifiable, Equatable {
    public let id: String
    public let reportedUserID: String
    public let reason: String
    public let details: String?
    public let submittedAt: Date
    public let status: ReportStatus

    public init(id: String,
                reportedUserID: String,
                reason: String,
                details: String?,
                submittedAt: Date,
                status: ReportStatus) {
        self.id = id
        self.reportedUserID = reportedUserID
        self.reason = reason
        self.details = details
        self.submittedAt = submittedAt
        self.status = status
    }
}

@available(iOS 17.0.0, *)
public enum ReportStatus: String, Equatable, CaseIterable {
    case pending
    case reviewed
    case resolved
    case dismissed

    public var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .reviewed:
            return "In Review"
        case .resolved:
            return "Resolved"
        case .dismissed:
            return "Dismissed"
        }
    }
}
