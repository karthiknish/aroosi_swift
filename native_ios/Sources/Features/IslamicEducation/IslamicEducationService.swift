import Foundation
import Combine

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
@MainActor
public final class IslamicEducationService: ObservableObject {
    @Published public private(set) var featuredContent: [IslamicEducationalContent] = []
    @Published public private(set) var userProgress: [String: UserContentProgress] = [:]
    @Published public private(set) var bookmarkedContent: [IslamicEducationalContent] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    private let repository: IslamicEducationRepository
    private let analytics: AnalyticsService
    private var cancellables = Set<AnyCancellable>()
    
    // In-memory cache
    private var contentCache: [String: IslamicEducationalContent] = [:]
    private var categoryCache: [EducationCategory: [IslamicEducationalContent]] = [:]
    private var lastFetchTime: [String: Date] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    public init(
        repository: IslamicEducationRepository = IslamicEducationRepository(),
        analytics: AnalyticsService = .shared
    ) {
        self.repository = repository
        self.analytics = analytics
    }
    
    // MARK: - Content Loading
    
    public func loadFeaturedContent(forceRefresh: Bool = false) async {
        guard !isLoading || forceRefresh else { return }
        
        if !forceRefresh, let cached = getCachedFeatured() {
            featuredContent = cached
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let content = try await repository.fetchFeaturedContent()
            featuredContent = content
            lastFetchTime["featured"] = Date()
            
            analytics.track(AnalyticsEvent(
                name: "islamic_education_featured_loaded",
                parameters: [
                    "count": "\(content.count)"
                ]
            ))
        } catch {
            self.error = error
            Logger.shared.error("Failed to load featured content: \(error)")
        }
        
        isLoading = false
    }
    
    public func loadContent(for category: EducationCategory, forceRefresh: Bool = false) async -> [IslamicEducationalContent] {
        if !forceRefresh, let cached = getCachedCategory(category) {
            return cached
        }
        
        do {
            let content = try await repository.fetchContentByCategory(category)
            categoryCache[category] = content
            lastFetchTime[category.rawValue] = Date()
            
            analytics.track(AnalyticsEvent(
                name: "islamic_education_category_loaded",
                parameters: [
                    "category": category.rawValue,
                    "count": "\(content.count)"
                ]
            ))
            
            return content
        } catch {
            Logger.shared.error("Failed to load category \(category): \(error)")
            return []
        }
    }
    
    public func getContent(id: String) async -> IslamicEducationalContent? {
        // Check cache first
        if let cached = contentCache[id] {
            return cached
        }
        
        do {
            let content = try await repository.fetchContent(id: id)
            contentCache[id] = content
            return content
        } catch {
            Logger.shared.error("Failed to fetch content \(id): \(error)")
            return nil
        }
    }
    
    public func searchContent(query: String) async -> [IslamicEducationalContent] {
        guard !query.isEmpty else { return [] }
        
        do {
            let results = try await repository.searchContent(query: query)
            
            analytics.track(AnalyticsEvent(
                name: "islamic_education_search",
                parameters: [
                    "query": query,
                    "results_count": "\(results.count)"
                ]
            ))
            
            return results
        } catch {
            Logger.shared.error("Failed to search content: \(error)")
            return []
        }
    }
    
    // MARK: - User Progress
    
    public func loadUserProgress(userId: String) async {
        do {
            userProgress = try await repository.fetchUserProgress(userId: userId)
        } catch {
            Logger.shared.error("Failed to load user progress: \(error)")
        }
    }
    
    public func markAsViewed(contentId: String, userId: String) async {
        do {
            try await repository.markContentAsViewed(contentId: contentId, userId: userId)
            
            // Update local progress
            if userProgress[contentId] == nil {
                userProgress[contentId] = UserContentProgress(
                    contentId: contentId,
                    viewedAt: Date(),
                    completed: false,
                    completedAt: nil,
                    quizScore: nil
                )
            }
            
            analytics.track(AnalyticsEvent(
                name: "islamic_education_content_viewed",
                parameters: [
                    "content_id": contentId
                ]
            ))
        } catch {
            Logger.shared.error("Failed to mark content as viewed: \(error)")
        }
    }
    
    public func markAsCompleted(contentId: String, userId: String, quizScore: Int? = nil) async {
        do {
            try await repository.markContentAsCompleted(contentId: contentId, userId: userId, quizScore: quizScore)
            
            // Update local progress
            userProgress[contentId] = UserContentProgress(
                contentId: contentId,
                viewedAt: userProgress[contentId]?.viewedAt ?? Date(),
                completed: true,
                completedAt: Date(),
                quizScore: quizScore
            )
            
            analytics.track(AnalyticsEvent(
                name: "islamic_education_content_completed",
                parameters: [
                    "content_id": contentId,
                    "quiz_score": "\(quizScore ?? 0)"
                ]
            ))
        } catch {
            Logger.shared.error("Failed to mark content as completed: \(error)")
        }
    }
    
    public func isCompleted(contentId: String) -> Bool {
        userProgress[contentId]?.completed ?? false
    }
    
    public func getProgress(for contentId: String) -> UserContentProgress? {
        userProgress[contentId]
    }
    
    public func getCompletionRate() -> Double {
        guard !userProgress.isEmpty else { return 0.0 }
        let completed = userProgress.values.filter { $0.completed }.count
        return Double(completed) / Double(userProgress.count)
    }
    
    // MARK: - Bookmarks
    
    public func loadBookmarks(userId: String) async {
        do {
            bookmarkedContent = try await repository.fetchBookmarks(userId: userId)
            
            analytics.track(AnalyticsEvent(
                name: "islamic_education_bookmarks_loaded",
                parameters: [
                    "count": "\(bookmarkedContent.count)"
                ]
            ))
        } catch {
            Logger.shared.error("Failed to load bookmarks: \(error)")
        }
    }
    
    public func toggleBookmark(contentId: String, userId: String) async -> Bool {
        do {
            let isBookmarked = try await repository.toggleBookmark(contentId: contentId, userId: userId)
            
            // Update local bookmarks
            if isBookmarked {
                if let content = await getContent(id: contentId) {
                    bookmarkedContent.append(content)
                }
            } else {
                bookmarkedContent.removeAll { $0.id == contentId }
            }
            
            analytics.track(AnalyticsEvent(
                name: "islamic_education_bookmark_toggled",
                parameters: [
                    "content_id": contentId,
                    "bookmarked": "\(isBookmarked)"
                ]
            ))
            
            return isBookmarked
        } catch {
            Logger.shared.error("Failed to toggle bookmark: \(error)")
            return false
        }
    }
    
    public func isBookmarked(contentId: String, userId: String) async -> Bool {
        do {
            return try await repository.isBookmarked(contentId: contentId, userId: userId)
        } catch {
            return false
        }
    }
    
    // MARK: - Likes
    
    public func toggleLike(contentId: String, userId: String) async -> Bool {
        do {
            let isLiked = try await repository.toggleLike(contentId: contentId, userId: userId)
            
            // Update cache
            if var content = contentCache[contentId] {
                content = IslamicEducationalContent(
                    id: content.id,
                    title: content.title,
                    description: content.description,
                    category: content.category,
                    contentType: content.contentType,
                    content: content.content,
                    difficultyLevel: content.difficultyLevel,
                    estimatedReadTime: content.estimatedReadTime,
                    createdAt: content.createdAt,
                    updatedAt: content.updatedAt,
                    author: content.author,
                    tags: content.tags,
                    isFeatured: content.isFeatured,
                    viewCount: content.viewCount,
                    likeCount: (content.likeCount ?? 0) + (isLiked ? 1 : -1),
                    bookmarkCount: content.bookmarkCount,
                    quiz: content.quiz,
                    relatedContent: content.relatedContent
                )
                contentCache[contentId] = content
            }
            
            analytics.track(AnalyticsEvent(
                name: "islamic_education_like_toggled",
                parameters: [
                    "content_id": contentId,
                    "liked": "\(isLiked)"
                ]
            ))
            
            return isLiked
        } catch {
            Logger.shared.error("Failed to toggle like: \(error)")
            return false
        }
    }
    
    // MARK: - Recommendations
    
    public func getRecommendedContent(for category: EducationCategory, limit: Int = 5) async -> [IslamicEducationalContent] {
        let content = await loadContent(for: category)
        
        // Sort by engagement metrics
        let sorted = content.sorted { lhs, rhs in
            let lhsScore = (lhs.viewCount ?? 0) + (lhs.likeCount ?? 0) * 2 + (lhs.bookmarkCount ?? 0) * 3
            let rhsScore = (rhs.viewCount ?? 0) + (rhs.likeCount ?? 0) * 2 + (rhs.bookmarkCount ?? 0) * 3
            return lhsScore > rhsScore
        }
        
        return Array(sorted.prefix(limit))
    }
    
    public func getRelatedContent(to contentId: String) async -> [IslamicEducationalContent] {
        guard let content = await getContent(id: contentId) else { return [] }
        
        // First try explicit related content IDs
        if let relatedIds = content.relatedContent, !relatedIds.isEmpty {
            var related: [IslamicEducationalContent] = []
            for id in relatedIds {
                if let relatedContent = await getContent(id: id) {
                    related.append(relatedContent)
                }
            }
            if !related.isEmpty {
                return related
            }
        }
        
        // Fallback to same category content
        let categoryContent = await loadContent(for: content.category)
        return categoryContent
            .filter { $0.id != contentId }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - Cache Management
    
    private func getCachedFeatured() -> [IslamicEducationalContent]? {
        guard let lastFetch = lastFetchTime["featured"],
              Date().timeIntervalSince(lastFetch) < cacheExpiration,
              !featuredContent.isEmpty else {
            return nil
        }
        return featuredContent
    }
    
    private func getCachedCategory(_ category: EducationCategory) -> [IslamicEducationalContent]? {
        guard let lastFetch = lastFetchTime[category.rawValue],
              Date().timeIntervalSince(lastFetch) < cacheExpiration,
              let cached = categoryCache[category],
              !cached.isEmpty else {
            return nil
        }
        return cached
    }
    
    public func clearCache() {
        contentCache.removeAll()
        categoryCache.removeAll()
        lastFetchTime.removeAll()
    }
    
    // MARK: - Quiz Submission
    
    public func submitQuizAnswers(contentId: String, userId: String, answers: [String: String]) async -> QuizResult? {
        guard let content = await getContent(id: contentId),
              let quiz = content.quiz else {
            return nil
        }
        
        var correctCount = 0
        var totalQuestions = quiz.questions.count
        
        for (questionId, selectedOptionId) in answers {
            if let question = quiz.questions.first(where: { $0.id == questionId }),
               question.correctOptionId == selectedOptionId {
                correctCount += 1
            }
        }
        
        let score = Int((Double(correctCount) / Double(totalQuestions)) * 100)
        let passed = score >= quiz.passingScore
        
        // Mark as completed if passed
        if passed {
            await markAsCompleted(contentId: contentId, userId: userId, quizScore: score)
        }
        
        analytics.track(AnalyticsEvent(
            name: "islamic_education_quiz_submitted",
            parameters: [
                "content_id": contentId,
                "score": "\(score)",
                "passed": "\(passed)",
                "correct_count": "\(correctCount)",
                "total_questions": "\(totalQuestions)"
            ]
        ))
        
        return QuizResult(
            score: score,
            correctCount: correctCount,
            totalQuestions: totalQuestions,
            passed: passed
        )
    }
}

// MARK: - Quiz Result

public struct QuizResult: Equatable {
    public let score: Int
    public let correctCount: Int
    public let totalQuestions: Int
    public let passed: Bool
    
    public var percentage: Double {
        Double(score)
    }
    
    public init(score: Int, correctCount: Int, totalQuestions: Int, passed: Bool) {
        self.score = score
        self.correctCount = correctCount
        self.totalQuestions = totalQuestions
        self.passed = passed
    }
}
#endif
