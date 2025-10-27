import Foundation

@available(iOS 17.0.0, *)
public struct Interest: Equatable, Identifiable, Codable {
    public enum Status: String, Codable, Equatable {
        case pending
        case accepted
        case rejected
        case matched
        case expired
    }
    
    public let id: String
    public let fromUserId: String
    public let toUserId: String
    public let status: Status
    public let createdAt: Date
    public let updatedAt: Date?
    public let message: String?
    
    public init(id: String,
                fromUserId: String,
                toUserId: String,
                status: Status = .pending,
                createdAt: Date,
                updatedAt: Date? = nil,
                message: String? = nil) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.message = message
    }
}

@available(iOS 17.0.0, *)
public enum InterestResponse {
    case accept(message: String?)
    case reject(message: String?)
    
    var status: Interest.Status {
        switch self {
        case .accept:
            return .accepted
        case .reject:
            return .rejected
        }
    }
    
    var message: String? {
        switch self {
        case .accept(let message), .reject(let message):
            return message
        }
    }
}

@available(iOS 17.0.0, *)
extension Interest {
    init(id: String, data: [String: Any]) throws {
        guard let fromUserId = data["fromUserId"] as? String,
              let toUserId = data["toUserId"] as? String,
              let statusString = data["status"] as? String,
              let status = Status(rawValue: statusString),
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            throw RepositoryError.invalidData
        }
        
        let updatedAt = data["updatedAt"] as? Timestamp
        let message = data["message"] as? String
        
        self.init(
            id: id,
            fromUserId: fromUserId,
            toUserId: toUserId,
            status: status,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAt?.dateValue(),
            message: message
        )
    }
    
    func toData() -> [String: Any] {
        var data: [String: Any] = [
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let updatedAt = updatedAt {
            data["updatedAt"] = Timestamp(date: updatedAt)
        }
        
        if let message = message {
            data["message"] = message
        }
        
        return data
    }
}
