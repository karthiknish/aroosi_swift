import Foundation

@available(iOS 17.0.0, *)
public struct CulturalProfile: Equatable, Codable {
    public var religion: String?
    public var religiousPractice: String?
    public var motherTongue: String?
    public var languages: [String]
    public var familyValues: String?
    public var marriageViews: String?
    public var traditionalValues: String?
    public var familyApprovalImportance: String?
    public var religionImportance: Int
    public var cultureImportance: Int
    public var familyBackground: String?
    public var ethnicity: String?

    public init(religion: String? = nil,
                religiousPractice: String? = nil,
                motherTongue: String? = nil,
                languages: [String] = [],
                familyValues: String? = nil,
                marriageViews: String? = nil,
                traditionalValues: String? = nil,
                familyApprovalImportance: String? = nil,
                religionImportance: Int = 5,
                cultureImportance: Int = 5,
                familyBackground: String? = nil,
                ethnicity: String? = nil) {
        self.religion = religion
        self.religiousPractice = religiousPractice
        self.motherTongue = motherTongue
        self.languages = languages
        self.familyValues = familyValues
        self.marriageViews = marriageViews
        self.traditionalValues = traditionalValues
        self.familyApprovalImportance = familyApprovalImportance
        self.religionImportance = religionImportance
        self.cultureImportance = cultureImportance
        self.familyBackground = familyBackground
        self.ethnicity = ethnicity
    }
}

@available(iOS 17.0.0, *)
public struct FamilyApprovalRequestModel: Identifiable, Equatable, Codable {
    public enum Status: String, Codable {
        case pending
        case approved
        case rejected
        case cancelled
    }

    public var id: String
    public var requesterId: String
    public var targetUserId: String
    public var status: Status
    public var createdAt: Date
    public var message: String
    public var familyMemberId: String?
    public var familyMemberName: String?
    public var familyMemberRelation: String?
    public var response: String?
    public var respondedAt: Date?
    public var approved: Bool

    public init(id: String,
                requesterId: String,
                targetUserId: String,
                status: Status,
                createdAt: Date,
                message: String,
                familyMemberId: String? = nil,
                familyMemberName: String? = nil,
                familyMemberRelation: String? = nil,
                response: String? = nil,
                respondedAt: Date? = nil,
                approved: Bool = false) {
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
    }
}

@available(iOS 17.0.0, *)
public struct SupervisedConversationModel: Identifiable, Equatable, Codable {
    public enum Status: String, Codable {
        case active
        case paused
        case completed
        case terminated
    }

    public var id: String
    public var participant1Id: String
    public var participant2Id: String
    public var supervisorId: String
    public var status: Status
    public var createdAt: Date
    public var conversationId: String?
    public var rules: [String]?
    public var timeLimit: Int?
    public var topicRestrictions: [String]?
    public var lastActivity: Date?

    public init(id: String,
                participant1Id: String,
                participant2Id: String,
                supervisorId: String,
                status: Status,
                createdAt: Date,
                conversationId: String? = nil,
                rules: [String]? = nil,
                timeLimit: Int? = nil,
                topicRestrictions: [String]? = nil,
                lastActivity: Date? = nil) {
        self.id = id
        self.participant1Id = participant1Id
        self.participant2Id = participant2Id
        self.supervisorId = supervisorId
        self.status = status
        self.createdAt = createdAt
        self.conversationId = conversationId
        self.rules = rules
        self.timeLimit = timeLimit
        self.topicRestrictions = topicRestrictions
        self.lastActivity = lastActivity
    }
}

@available(iOS 17.0.0, *)
public struct CulturalRecommendation: Identifiable, Equatable {
    public struct CompatibilityBreakdown: Equatable {
        public var religion: Int
        public var language: Int
        public var values: Int
        public var family: Int

        public init(religion: Int, language: Int, values: Int, family: Int) {
            self.religion = religion
            self.language = language
            self.values = values
            self.family = family
        }
    }

    public let id: String
    public let profile: ProfileSummary
    public let compatibilityScore: Int
    public let breakdown: CompatibilityBreakdown
    public let matchingFactors: [String]
    public let culturalHighlights: [String]

    public init(id: String,
                profile: ProfileSummary,
                compatibilityScore: Int,
                breakdown: CompatibilityBreakdown,
                matchingFactors: [String] = [],
                culturalHighlights: [String] = []) {
        self.id = id
        self.profile = profile
        self.compatibilityScore = compatibilityScore
        self.breakdown = breakdown
        self.matchingFactors = matchingFactors
        self.culturalHighlights = culturalHighlights
    }
}

@available(iOS 17.0.0, *)
public struct CulturalCompatibilityReport: Equatable {
    public struct Dimension: Identifiable, Equatable {
        public var id: String { key }
        public let key: String
        public let label: String
        public let score: Int
        public let description: String?

        public init(key: String, label: String, score: Int, description: String? = nil) {
            self.key = key
            self.label = label
            self.score = score
            self.description = description
        }
    }

    public let overallScore: Int
    public let insights: [String]
    public let dimensions: [Dimension]

    public init(overallScore: Int, insights: [String], dimensions: [Dimension]) {
        self.overallScore = overallScore
        self.insights = insights
        self.dimensions = dimensions
    }
}
