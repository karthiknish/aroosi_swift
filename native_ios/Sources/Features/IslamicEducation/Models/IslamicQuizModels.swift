import Foundation

// MARK: - Islamic Quiz Models

@available(iOS 17, *)
public struct IslamicQuiz: Identifiable, Codable {
    public let id: String
    public let title: String
    public let description: String
    public let category: QuizCategory
    public let difficulty: QuizDifficulty
    public let questions: [IslamicQuizQuestion]
    public let timeLimit: Int? // in minutes, nil for no limit
    public let passingScore: Int // percentage
    public let createdAt: Date
    public let updatedAt: Date
    public let isActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        category: QuizCategory,
        difficulty: QuizDifficulty,
        questions: [IslamicQuizQuestion],
        timeLimit: Int? = nil,
        passingScore: Int = 70,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.questions = questions
        self.timeLimit = timeLimit
        self.passingScore = passingScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
    }
}

@available(iOS 17, *)
public struct IslamicQuizQuestion: Identifiable, Codable {
    public let id: String
    public let question: String
    public let options: [String]
    public let correctAnswerIndex: Int
    public let explanation: String?
    public let reference: String? // Quranic verse or Hadith reference
    public let category: QuizCategory
    public let difficulty: QuizDifficulty
    public let arabicText: String? // Original Arabic text
    public let transliteration: String? // Arabic transliteration
    
    public init(
        id: String = UUID().uuidString,
        question: String,
        options: [String],
        correctAnswerIndex: Int,
        explanation: String? = nil,
        reference: String? = nil,
        category: QuizCategory,
        difficulty: QuizDifficulty,
        arabicText: String? = nil,
        transliteration: String? = nil
    ) {
        self.id = id
        self.question = question
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
        self.explanation = explanation
        self.reference = reference
        self.category = category
        self.difficulty = difficulty
        self.arabicText = arabicText
        self.transliteration = transliteration
    }
}

@available(iOS 17, *)
public struct IslamicQuizResult: Identifiable, Codable {
    public let id: String
    public let userId: String
    public let quizId: String
    public let quizTitle: String
    public let answers: [String: Int] // questionId: selectedAnswerIndex
    public let score: Int // percentage
    public let totalQuestions: Int
    public let correctAnswers: Int
    public let timeTaken: Int // in seconds
    public let completedAt: Date
    public let passed: Bool
    public let certificateEarned: Bool
    
    public init(
        id: String = UUID().uuidString,
        userId: String,
        quizId: String,
        quizTitle: String,
        answers: [String: Int],
        score: Int,
        totalQuestions: Int,
        correctAnswers: Int,
        timeTaken: Int,
        completedAt: Date = Date(),
        passed: Bool,
        certificateEarned: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.quizId = quizId
        self.quizTitle = quizTitle
        self.answers = answers
        self.score = score
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.timeTaken = timeTaken
        self.completedAt = completedAt
        self.passed = passed
        self.certificateEarned = certificateEarned
    }
}

@available(iOS 17, *)
public struct UserIslamicQuizProfile: Codable {
    public let userId: String
    public var totalQuizzesTaken: Int
    public var totalQuizzesPassed: Int
    public var averageScore: Double
    public var favoriteCategories: [QuizCategory]
    public var strongestCategories: [QuizCategory: Double] // category: average score
    public var weakestCategories: [QuizCategory: Double] // category: average score
    public var certificatesEarned: [String] // quiz IDs
    public var lastQuizDate: Date?
    public var currentStreak: Int // consecutive days with quiz activity
    public var longestStreak: Int
    public var totalStudyTime: Int // in minutes
    public var achievements: [QuizAchievement]
    public var preferredDifficulty: QuizDifficulty
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        userId: String,
        totalQuizzesTaken: Int = 0,
        totalQuizzesPassed: Int = 0,
        averageScore: Double = 0.0,
        favoriteCategories: [QuizCategory] = [],
        strongestCategories: [QuizCategory: Double] = [:],
        weakestCategories: [QuizCategory: Double] = [:],
        certificatesEarned: [String] = [],
        lastQuizDate: Date? = nil,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalStudyTime: Int = 0,
        achievements: [QuizAchievement] = [],
        preferredDifficulty: QuizDifficulty = .beginner,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.userId = userId
        self.totalQuizzesTaken = totalQuizzesTaken
        self.totalQuizzesPassed = totalQuizzesPassed
        self.averageScore = averageScore
        self.favoriteCategories = favoriteCategories
        self.strongestCategories = strongestCategories
        self.weakestCategories = weakestCategories
        self.certificatesEarned = certificatesEarned
        self.lastQuizDate = lastQuizDate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalStudyTime = totalStudyTime
        self.achievements = achievements
        self.preferredDifficulty = preferredDifficulty
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Quiz Categories and Difficulties

@available(iOS 17, *)
public enum QuizCategory: String, CaseIterable, Codable {
    case quran = "quran"
    case hadith = "hadith"
    case fiqh = "fiqh"
    case aqidah = "aqidah"
    case seerah = "seerah"
    case islamicHistory = "islamic_history"
    case prophets = "prophets"
    case companions = "companions"
    case prayer = "prayer"
    case zakat = "zakat"
    case fasting = "fasting"
    case hajj = "hajj"
    case family = "family"
    case ethics = "ethics"
    case islamicNames = "islamic_names"
    
    public var displayName: String {
        switch self {
        case .quran: return "Quran"
        case .hadith: return "Hadith"
        case .fiqh: return "Fiqh (Jurisprudence)"
        case .aqidah: return "Aqidah (Creed)"
        case .seerah: return "Seerah (Prophet's Life)"
        case .islamicHistory: return "Islamic History"
        case .prophets: return "Prophets"
        case .companions: return "Companions"
        case .prayer: return "Prayer (Salah)"
        case .zakat: return "Zakat (Charity)"
        case .fasting: return "Fasting (Sawm)"
        case .hajj: return "Hajj (Pilgrimage)"
        case .family: return "Family Life"
        case .ethics: return "Islamic Ethics"
        case .islamicNames: return "Islamic Names"
        }
    }
    
    public var icon: String {
        switch self {
        case .quran: return "book.closed"
        case .hadith: return "quote.bubble"
        case .fiqh: return "scalemass"
        case .aqidah: return "star.circle"
        case .seerah: return "person.crop.circle"
        case .islamicHistory: return "clock"
        case .prophets: return "crown"
        case .companions: return "person.3"
        case .prayer: return "hands.pray"
        case .zakat: return "hand.raised"
        case .fasting: return "moon"
        case .hajj: return "location.circle"
        case .family: return "house"
        case .ethics: return "heart"
        case .islamicNames: return "textformat.abc"
        }
    }
    
    public var color: String {
        switch self {
        case .quran: return "green"
        case .hadith: return "blue"
        case .fiqh: return "purple"
        case .aqidah: return "orange"
        case .seerah: return "red"
        case .islamicHistory: return "indigo"
        case .prophets: return "yellow"
        case .companions: return "pink"
        case .prayer: return "teal"
        case .zakat: return "cyan"
        case .fasting: return "mint"
        case .hajj: return "brown"
        case .family: return "rose"
        case .ethics: return "emerald"
        case .islamicNames: return "lime"
        }
    }
}

@available(iOS 17, *)
public enum QuizDifficulty: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case scholar = "scholar"
    
    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .scholar: return "Scholar"
        }
    }
    
    public var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "blue"
        case .advanced: return "orange"
        case .scholar: return "red"
        }
    }
    
    public var pointsMultiplier: Double {
        switch self {
        case .beginner: return 1.0
        case .intermediate: return 1.5
        case .advanced: return 2.0
        case .scholar: return 3.0
        }
    }
}

// MARK: - Quiz Achievements

@available(iOS 17, *)
public struct QuizAchievement: Identifiable, Codable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let earnedAt: Date
    public let category: QuizCategory?
    public let requirement: AchievementRequirement
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        icon: String,
        earnedAt: Date = Date(),
        category: QuizCategory? = nil,
        requirement: AchievementRequirement
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.earnedAt = earnedAt
        self.category = category
        self.requirement = requirement
    }
}

@available(iOS 17, *)
public enum AchievementRequirement: Codable {
    case quizzesTaken(count: Int)
    case quizzesPassed(count: Int)
    case perfectScores(count: Int)
    case categoryMaster(category: QuizCategory, score: Int)
    case streakDays(days: Int)
    case totalStudyTime(minutes: Int)
    case allCategoriesCompleted
    case difficultyCompleted(difficulty: QuizDifficulty)
}
