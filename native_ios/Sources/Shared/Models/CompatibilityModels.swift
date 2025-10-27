import Foundation

// MARK: - Question Types

public enum QuestionType: String, Codable, Equatable {
    case singleChoice
    case multipleChoice
    case scale
    case yesNo
}

// MARK: - Question Option

public struct QuestionOption: Codable, Identifiable, Equatable {
    public let id: String
    public let text: String
    public let value: Double // Score value for this option (0.0-1.0)
    
    public init(id: String, text: String, value: Double) {
        self.id = id
        self.text = text
        self.value = value
    }
}

// MARK: - Compatibility Question

public struct CompatibilityQuestion: Codable, Identifiable, Equatable {
    public let id: String
    public let text: String
    public let type: QuestionType
    public let options: [QuestionOption]
    public let isRequired: Bool
    
    public init(
        id: String,
        text: String,
        type: QuestionType,
        options: [QuestionOption],
        isRequired: Bool = true
    ) {
        self.id = id
        self.text = text
        self.type = type
        self.options = options
        self.isRequired = isRequired
    }
}

// MARK: - Islamic Compatibility Category

public struct IslamicCompatibilityCategory: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let weight: Double // Weight of this category in overall score (0.0-1.0)
    public let questions: [CompatibilityQuestion]
    
    public init(
        id: String,
        name: String,
        description: String,
        weight: Double,
        questions: [CompatibilityQuestion]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.weight = weight
        self.questions = questions
    }
}

// MARK: - Compatibility Response

public struct CompatibilityResponse: Codable, Equatable {
    public let userId: String
    public let responses: [String: ResponseValue] // questionId -> selected answer(s)
    public let completedAt: Date
    
    public init(userId: String, responses: [String: ResponseValue], completedAt: Date) {
        self.userId = userId
        self.responses = responses
        self.completedAt = completedAt
    }
}

// MARK: - Response Value (supports single and multiple choice)

public enum ResponseValue: Codable, Equatable {
    case single(String)
    case multiple([String])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let singleValue = try? container.decode(String.self) {
            self = .single(singleValue)
        } else if let multipleValues = try? container.decode([String].self) {
            self = .multiple(multipleValues)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "ResponseValue must be either String or [String]"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let value):
            try container.encode(value)
        case .multiple(let values):
            try container.encode(values)
        }
    }
}

// MARK: - Compatibility Score

public struct CompatibilityScore: Codable, Equatable {
    public let userId1: String
    public let userId2: String
    public let overallScore: Double // 0.0-100.0
    public let categoryScores: [String: Double] // categoryId -> score
    public let calculatedAt: Date
    public let detailedBreakdown: [String: Double]?
    
    public init(
        userId1: String,
        userId2: String,
        overallScore: Double,
        categoryScores: [String: Double],
        calculatedAt: Date,
        detailedBreakdown: [String: Double]? = nil
    ) {
        self.userId1 = userId1
        self.userId2 = userId2
        self.overallScore = overallScore
        self.categoryScores = categoryScores
        self.calculatedAt = calculatedAt
        self.detailedBreakdown = detailedBreakdown
    }
    
    // MARK: - Computed Properties
    
    public var compatibilityLevel: String {
        switch overallScore {
        case 90...100:
            return "Excellent Match"
        case 80..<90:
            return "Strong Match"
        case 70..<80:
            return "Good Match"
        case 60..<70:
            return "Moderate Match"
        case 50..<60:
            return "Fair Match"
        default:
            return "Low Compatibility"
        }
    }
    
    public var compatibilityDescription: String {
        switch overallScore {
        case 90...100:
            return "Exceptional compatibility across all Islamic values and lifestyle preferences"
        case 80..<90:
            return "Strong alignment in key areas of Islamic practice and values"
        case 70..<80:
            return "Good compatibility with minor differences in some areas"
        case 60..<70:
            return "Moderate compatibility with some areas requiring discussion"
        case 50..<60:
            return "Fair compatibility that may need compromise and understanding"
        default:
            return "Significant differences that may require careful consideration"
        }
    }
    
    public var levelColor: String {
        switch overallScore {
        case 80...100:
            return "green"
        case 60..<80:
            return "blue"
        case 40..<60:
            return "yellow"
        default:
            return "red"
        }
    }
}

// MARK: - Family Feedback Approval Status

public enum FamilyFeedbackApprovalStatus: String, Codable, Equatable {
    case pending
    case approved
    case rejected
}

// MARK: - Family Feedback

public struct FamilyFeedback: Codable, Identifiable, Equatable {
    public let id: String
    public let reportId: String
    public let familyMemberName: String
    public let relationship: String
    public let feedback: String
    public let createdAt: Date
    public let approvalStatus: FamilyFeedbackApprovalStatus
    
    public init(
        id: String,
        reportId: String,
        familyMemberName: String,
        relationship: String,
        feedback: String,
        createdAt: Date,
        approvalStatus: FamilyFeedbackApprovalStatus = .pending
    ) {
        self.id = id
        self.reportId = reportId
        self.familyMemberName = familyMemberName
        self.relationship = relationship
        self.feedback = feedback
        self.createdAt = createdAt
        self.approvalStatus = approvalStatus
    }
}

// MARK: - Compatibility Report

public struct CompatibilityReport: Codable, Identifiable, Equatable {
    public let id: String
    public let userId1: String
    public let userId2: String
    public let scores: CompatibilityScore
    public let generatedAt: Date
    public let familyFeedback: [FamilyFeedback]?
    public let isShared: Bool
    
    public init(
        id: String,
        userId1: String,
        userId2: String,
        scores: CompatibilityScore,
        generatedAt: Date,
        familyFeedback: [FamilyFeedback]? = nil,
        isShared: Bool = false
    ) {
        self.id = id
        self.userId1 = userId1
        self.userId2 = userId2
        self.scores = scores
        self.generatedAt = generatedAt
        self.familyFeedback = familyFeedback
        self.isShared = isShared
    }
}

// MARK: - User Response State (for UI)

public struct UserResponseState: Equatable {
    public var responses: [String: ResponseValue] = [:]
    public var currentCategoryIndex: Int = 0
    public var currentQuestionIndex: Int = 0
    
    public var isComplete: Bool {
        // Check if all required questions are answered
        let allCategories = IslamicCompatibilityQuestions.getCategories()
        let totalRequiredQuestions = allCategories.flatMap { $0.questions }
            .filter { $0.isRequired }
            .count
        
        let answeredRequiredCount = responses.keys.count
        return answeredRequiredCount >= totalRequiredQuestions
    }
    
    public var progressPercentage: Double {
        let allCategories = IslamicCompatibilityQuestions.getCategories()
        let totalQuestions = allCategories.flatMap { $0.questions }.count
        guard totalQuestions > 0 else { return 0 }
        return Double(responses.count) / Double(totalQuestions) * 100
    }
    
    public init() {}
}
