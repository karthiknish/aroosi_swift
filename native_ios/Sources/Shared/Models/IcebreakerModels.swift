import Foundation

@available(iOS 17.0.0, *)
public struct IcebreakerQuestion: Identifiable, Equatable {
    public let id: String
    public let text: String
    public let category: String?
    public let weight: Int
    public let active: Bool

    public init(id: String,
                text: String,
                category: String?,
                weight: Int,
                active: Bool) {
        self.id = id
        self.text = text
        self.category = category
        self.weight = weight
        self.active = active
    }
}

@available(iOS 17.0.0, *)
public struct IcebreakerAnswer: Identifiable, Equatable {
    public let id: String
    public let questionId: String
    public let userId: String
    public let answer: String
    public let createdAt: Date
    public let updatedAt: Date?

    public init(id: String,
                questionId: String,
                userId: String,
                answer: String,
                createdAt: Date,
                updatedAt: Date?) {
        self.id = id
        self.questionId = questionId
        self.userId = userId
        self.answer = answer
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@available(iOS 17.0.0, *)
public struct IcebreakerItem: Identifiable, Equatable {
    public let id: String
    public let text: String
    public var currentAnswer: String
    public var isAnswered: Bool

    public init(id: String,
                text: String,
                currentAnswer: String = "",
                isAnswered: Bool = false) {
        self.id = id
        self.text = text
        self.currentAnswer = currentAnswer
        self.isAnswered = isAnswered
    }
}
