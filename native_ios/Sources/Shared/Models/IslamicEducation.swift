import Foundation

// MARK: - Education Category

public enum EducationCategory: String, Codable, CaseIterable {
    case islamicMarriage = "islamic_marriage"
    case familyValues = "family_values"
    case relationshipAdvice = "relationship_advice"
    case islamicEthics = "islamic_ethics"
    case afghanCulture = "afghan_culture"
    case general
    
    public var displayName: String {
        switch self {
        case .islamicMarriage: return "Islamic Marriage"
        case .familyValues: return "Family Values"
        case .relationshipAdvice: return "Relationship Advice"
        case .islamicEthics: return "Islamic Ethics"
        case .afghanCulture: return "Afghan Culture"
        case .general: return "General"
        }
    }
}

// MARK: - Content Type

public enum EducationContentType: String, Codable {
    case article
    case video
    case infographic
    case quiz
    case guide
}

// MARK: - Difficulty Level

public enum DifficultyLevel: String, Codable {
    case beginner
    case intermediate
    case advanced
    
    public var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Islamic Educational Content

public struct IslamicEducationalContent: Codable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let category: EducationCategory
    public let contentType: EducationContentType
    public let content: EducationContent
    public let difficultyLevel: DifficultyLevel
    public let estimatedReadTime: Int // minutes
    public let createdAt: Date
    public let updatedAt: Date
    public let author: String?
    public let tags: [String]?
    public let isFeatured: Bool
    public let viewCount: Int
    public let likeCount: Int
    public let bookmarkCount: Int
    public let quiz: EducationalQuiz?
    public let relatedContent: [String]?
    
    public init(
        id: String,
        title: String,
        description: String,
        category: EducationCategory,
        contentType: EducationContentType,
        content: EducationContent,
        difficultyLevel: DifficultyLevel,
        estimatedReadTime: Int,
        createdAt: Date,
        updatedAt: Date,
        author: String? = nil,
        tags: [String]? = nil,
        isFeatured: Bool = false,
        viewCount: Int = 0,
        likeCount: Int = 0,
        bookmarkCount: Int = 0,
        quiz: EducationalQuiz? = nil,
        relatedContent: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.contentType = contentType
        self.content = content
        self.difficultyLevel = difficultyLevel
        self.estimatedReadTime = estimatedReadTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.author = author
        self.tags = tags
        self.isFeatured = isFeatured
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.bookmarkCount = bookmarkCount
        self.quiz = quiz
        self.relatedContent = relatedContent
    }
}

// MARK: - Education Content

public struct EducationContent: Codable, Equatable {
    public let sections: [ContentSection]
    public let quranicVerses: [QuranicVerse]?
    public let hadiths: [Hadith]?
    public let images: [ContentImage]?
    public let videos: [ContentVideo]?
    public let keyTakeaways: [String]?
    public let references: [String]?
    
    public init(
        sections: [ContentSection],
        quranicVerses: [QuranicVerse]? = nil,
        hadiths: [Hadith]? = nil,
        images: [ContentImage]? = nil,
        videos: [ContentVideo]? = nil,
        keyTakeaways: [String]? = nil,
        references: [String]? = nil
    ) {
        self.sections = sections
        self.quranicVerses = quranicVerses
        self.hadiths = hadiths
        self.images = images
        self.videos = videos
        self.keyTakeaways = keyTakeaways
        self.references = references
    }
}

// MARK: - Content Section

public struct ContentSection: Codable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let content: String
    public let order: Int
    
    public init(id: String, title: String, content: String, order: Int) {
        self.id = id
        self.title = title
        self.content = content
        self.order = order
    }
}

// MARK: - Quranic Verse

public struct QuranicVerse: Codable, Identifiable, Equatable {
    public let id: String
    public let surahNumber: Int
    public let surahName: String
    public let verseNumber: Int
    public let arabicText: String
    public let transliteration: String?
    public let translation: String
    public let context: String?
    
    public init(
        id: String,
        surahNumber: Int,
        surahName: String,
        verseNumber: Int,
        arabicText: String,
        transliteration: String? = nil,
        translation: String,
        context: String? = nil
    ) {
        self.id = id
        self.surahNumber = surahNumber
        self.surahName = surahName
        self.verseNumber = verseNumber
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.translation = translation
        self.context = context
    }
}

// MARK: - Hadith

public struct Hadith: Codable, Identifiable, Equatable {
    public let id: String
    public let arabicText: String
    public let translation: String
    public let narrator: String
    public let source: String
    public let reference: String
    public let grade: HadithGrade
    public let context: String?
    
    public init(
        id: String,
        arabicText: String,
        translation: String,
        narrator: String,
        source: String,
        reference: String,
        grade: HadithGrade,
        context: String? = nil
    ) {
        self.id = id
        self.arabicText = arabicText
        self.translation = translation
        self.narrator = narrator
        self.source = source
        self.reference = reference
        self.grade = grade
        self.context = context
    }
}

public enum HadithGrade: String, Codable {
    case sahih
    case hasan
    case daif
    
    public var displayName: String {
        switch self {
        case .sahih: return "Sahih (Authentic)"
        case .hasan: return "Hasan (Good)"
        case .daif: return "Daif (Weak)"
        }
    }
}

// MARK: - Content Media

public struct ContentImage: Codable, Identifiable, Equatable {
    public let id: String
    public let url: URL
    public let caption: String?
    public let altText: String?
    
    public init(id: String, url: URL, caption: String? = nil, altText: String? = nil) {
        self.id = id
        self.url = url
        self.caption = caption
        self.altText = altText
    }
}

public struct ContentVideo: Codable, Identifiable, Equatable {
    public let id: String
    public let url: URL
    public let thumbnailURL: URL?
    public let title: String
    public let duration: Int // seconds
    
    public init(id: String, url: URL, thumbnailURL: URL? = nil, title: String, duration: Int) {
        self.id = id
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.title = title
        self.duration = duration
    }
}

// MARK: - Educational Quiz

public struct EducationalQuiz: Codable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let questions: [QuizQuestion]
    public let passingScore: Int // percentage
    
    public init(id: String, title: String, description: String, questions: [QuizQuestion], passingScore: Int) {
        self.id = id
        self.title = title
        self.description = description
        self.questions = questions
        self.passingScore = passingScore
    }
}

public struct QuizQuestion: Codable, Identifiable, Equatable {
    public let id: String
    public let text: String
    public let options: [QuizOption]
    public let correctOptionId: String
    public let explanation: String?
    
    public init(id: String, text: String, options: [QuizOption], correctOptionId: String, explanation: String? = nil) {
        self.id = id
        self.text = text
        self.options = options
        self.correctOptionId = correctOptionId
        self.explanation = explanation
    }
}

public struct QuizOption: Codable, Identifiable, Equatable {
    public let id: String
    public let text: String
    
    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

// MARK: - Afghan Cultural Tradition

public struct AfghanCulturalTradition: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let category: String
    public let significance: String
    public let modernPractice: String?
    public let relatedVerses: [QuranicVerse]?
    public let images: [ContentImage]?
    
    public init(
        id: String,
        name: String,
        description: String,
        category: String,
        significance: String,
        modernPractice: String? = nil,
        relatedVerses: [QuranicVerse]? = nil,
        images: [ContentImage]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.significance = significance
        self.modernPractice = modernPractice
        self.relatedVerses = relatedVerses
        self.images = images
    }
}
