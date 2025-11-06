import Foundation
import Combine

#if os(iOS)
#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17, *)
@MainActor
public final class IslamicQuizService: ObservableObject {
    @Published public private(set) var availableQuizzes: [IslamicQuiz] = []
    @Published public private(set) var featuredQuizzes: [IslamicQuiz] = []
    @Published public private(set) var userResults: [IslamicQuizResult] = []
    @Published public private(set) var userProfile: UserIslamicQuizProfile?
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    private let repository: IslamicQuizRepository
    private let analytics: AnalyticsService
    private var cancellables = Set<AnyCancellable>()
    
    // Quiz session state
    @Published public private(set) var currentQuizSession: QuizSession?
    @Published public private(set) var isQuizActive = false
    
    public init(
        repository: IslamicQuizRepository = FirebaseIslamicQuizRepository(),
        analytics: AnalyticsService = .shared
    ) {
        self.repository = repository
        self.analytics = analytics
    }
    
    // MARK: - Quiz Loading
    
    public func loadAvailableQuizzes(category: QuizCategory? = nil, difficulty: QuizDifficulty? = nil) async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            availableQuizzes = try await repository.fetchQuizzes(category: category, difficulty: difficulty)
            
            analytics.track(AnalyticsEvent(
                name: "islamic_quizzes_loaded",
                parameters: [
                    "category": category?.rawValue ?? "all",
                    "difficulty": difficulty?.rawValue ?? "all",
                    "count": "\(availableQuizzes.count)"
                ]
            ))
            
        } catch {
            self.error = error
            analytics.track(AnalyticsEvent(
                name: "islamic_quizzes_load_failed",
                parameters: [
                    "error": error.localizedDescription,
                    "category": category?.rawValue ?? "all"
                ]
            ))
        }
        
        isLoading = false
    }
    
    public func loadFeaturedQuizzes() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            featuredQuizzes = try await repository.getFeaturedQuizzes()
            
            analytics.track(AnalyticsEvent(
                name: "islamic_featured_quizzes_loaded",
                parameters: [
                    "count": "\(featuredQuizzes.count)"
                ]
            ))
            
        } catch {
            self.error = error
            analytics.track(AnalyticsEvent(
                name: "islamic_featured_quizzes_load_failed",
                parameters: [
                    "error": error.localizedDescription
                ]
            ))
        }
        
        isLoading = false
    }
    
    public func loadQuiz(by id: String) async throws -> IslamicQuiz {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let quiz = try await repository.fetchQuiz(by: id)
            
            analytics.track(AnalyticsEvent(
                name: "islamic_quiz_loaded",
                parameters: [
                    "quiz_id": id,
                    "category": quiz.category.rawValue,
                    "difficulty": quiz.difficulty.rawValue
                ]
            ))
            
            return quiz
            
        } catch {
            analytics.track(AnalyticsEvent(
                name: "islamic_quiz_load_failed",
                parameters: [
                    "quiz_id": id,
                    "error": error.localizedDescription
                ]
            ))
            throw error
        }
    }
    
    // MARK: - User Profile Management
    
    public func loadUserProfile(userId: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            userProfile = try await repository.getUserQuizProfile(userId: userId)
            
            analytics.track(AnalyticsEvent(
                name: "islamic_quiz_profile_loaded",
                parameters: [
                    "user_id": userId,
                    "total_quizzes": "\(userProfile?.totalQuizzesTaken ?? 0)",
                    "average_score": "\(userProfile?.averageScore ?? 0.0)"
                ]
            ))
            
        } catch {
            self.error = error
            analytics.track(AnalyticsEvent(
                name: "islamic_quiz_profile_load_failed",
                parameters: [
                    "user_id": userId,
                    "error": error.localizedDescription
                ]
            ))
        }
        
        isLoading = false
    }
    
    public func loadUserResults(userId: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            userResults = try await repository.getUserQuizResults(userId: userId)
            
            analytics.track(AnalyticsEvent(
                name: "islamic_quiz_results_loaded",
                parameters: [
                    "user_id": userId,
                    "results_count": "\(userResults.count)"
                ]
            ))
            
        } catch {
            self.error = error
            analytics.track(AnalyticsEvent(
                name: "islamic_quiz_results_load_failed",
                parameters: [
                    "user_id": userId,
                    "error": error.localizedDescription
                ]
            ))
        }
        
        isLoading = false
    }
    
    // MARK: - Quiz Session Management
    
    public func startQuizSession(quiz: IslamicQuiz, userId: String) {
        currentQuizSession = QuizSession(
            quiz: quiz,
            userId: userId,
            startTime: Date(),
            answers: [:]
        )
        isQuizActive = true
        
        analytics.track(AnalyticsEvent(
            name: "islamic_quiz_session_started",
            parameters: [
                "quiz_id": quiz.id,
                "quiz_title": quiz.title,
                "category": quiz.category.rawValue,
                "difficulty": quiz.difficulty.rawValue,
                "user_id": userId
            ]
        ))
    }
    
    public func submitAnswer(questionId: String, answerIndex: Int) {
        guard var session = currentQuizSession else { return }
        
        session.answers[questionId] = answerIndex
        currentQuizSession = session
        
        analytics.track(AnalyticsEvent(
            name: "islamic_quiz_answer_submitted",
            parameters: [
                "question_id": questionId,
                "answer_index": "\(answerIndex)",
                "quiz_id": session.quiz.id
            ]
        ))
    }
    
    public func completeQuizSession() async throws -> IslamicQuizResult {
        guard var session = currentQuizSession else {
            throw IslamicQuizError.noActiveSession
        }
        
        let endTime = Date()
        let timeTaken = Int(endTime.timeIntervalSince(session.startTime))
        
        // Calculate score
        var correctAnswers = 0
        for (questionId, answerIndex) in session.answers {
            if let question = session.quiz.questions.first(where: { $0.id == questionId }) {
                if answerIndex == question.correctAnswerIndex {
                    correctAnswers += 1
                }
            }
        }
        
        let score = Int((Double(correctAnswers) / Double(session.quiz.questions.count)) * 100)
        let passed = score >= session.quiz.passingScore
        
        // Create result
        let result = IslamicQuizResult(
            userId: session.userId,
            quizId: session.quiz.id,
            quizTitle: session.quiz.title,
            answers: session.answers,
            score: score,
            totalQuestions: session.quiz.questions.count,
            correctAnswers: correctAnswers,
            timeTaken: timeTaken,
            passed: passed,
            certificateEarned: passed
        )
        
        // Save result
        try await repository.saveQuizResult(result)
        
        // Update user profile
        await loadUserProfile(userId: session.userId)
        
        // Clear session
        currentQuizSession = nil
        isQuizActive = false
        
        analytics.track(AnalyticsEvent(
            name: "islamic_quiz_session_completed",
            parameters: [
                "quiz_id": session.quiz.id,
                "score": "\(score)",
                "passed": passed ? "true" : "false",
                "time_taken": "\(timeTaken)",
                "correct_answers": "\(correctAnswers)",
                "total_questions": "\(session.quiz.questions.count)"
            ]
        ))
        
        return result
    }
    
    public func cancelQuizSession() {
        guard let session = currentQuizSession else { return }
        
        analytics.track(AnalyticsEvent(
            name: "islamic_quiz_session_cancelled",
            parameters: [
                "quiz_id": session.quiz.id,
                "time_spent": "\(Int(Date().timeIntervalSince(session.startTime)))",
                "questions_answered": "\(session.answers.count)"
            ]
        ))
        
        currentQuizSession = nil
        isQuizActive = false
    }
    
    // MARK: - Quiz Categories
    
    public func getQuizzesByCategory(_ category: QuizCategory) async {
        await loadAvailableQuizzes(category: category, difficulty: nil)
    }
    
    public func getQuizzesByDifficulty(_ difficulty: QuizDifficulty) async {
        await loadAvailableQuizzes(category: nil, difficulty: difficulty)
    }
    
    // MARK: - Statistics and Insights
    
    public func getUserStatistics(userId: String) -> QuizStatistics? {
        guard let profile = userProfile else { return nil }
        
        return QuizStatistics(
            totalQuizzesTaken: profile.totalQuizzesTaken,
            totalQuizzesPassed: profile.totalQuizzesPassed,
            averageScore: profile.averageScore,
            passRate: profile.totalQuizzesTaken > 0 ? Double(profile.totalQuizzesPassed) / Double(profile.totalQuizzesTaken) * 100 : 0,
            currentStreak: profile.currentStreak,
            longestStreak: profile.longestStreak,
            totalStudyTime: profile.totalStudyTime,
            certificatesEarned: profile.certificatesEarned.count,
            favoriteCategories: profile.favoriteCategories,
            strongestCategories: profile.strongestCategories,
            achievements: profile.achievements
        )
    }
    
    public func getRecommendedQuizzes(userId: String) async -> [IslamicQuiz] {
        guard let profile = userProfile else { return [] }
        
        // Recommend based on user's preferred difficulty and favorite categories
        var recommended: [IslamicQuiz] = []
        
        // Get quizzes from favorite categories
        for category in profile.favoriteCategories {
            let categoryQuizzes = availableQuizzes.filter { $0.category == category }
            recommended.append(contentsOf: categoryQuizzes)
        }
        
        // Get quizzes of preferred difficulty
        let difficultyQuizzes = availableQuizzes.filter { $0.difficulty == profile.preferredDifficulty }
        recommended.append(contentsOf: difficultyQuizzes)
        
        // Remove duplicates and limit to 10
        recommended = Array(Set(recommended)).prefix(10).sorted { $0.difficulty.pointsMultiplier < $1.difficulty.pointsMultiplier }
        
        analytics.track(AnalyticsEvent(
            name: "islamic_quiz_recommendations_generated",
            parameters: [
                "user_id": userId,
                "recommendations_count": "\(recommended.count)",
                "based_on_categories": "\(profile.favoriteCategories.count)",
                "based_on_difficulty": profile.preferredDifficulty.rawValue
            ]
        ))
        
        return recommended
    }
}

// MARK: - Supporting Models

@available(iOS 17, *)
public struct QuizSession {
    let quiz: IslamicQuiz
    let userId: String
    let startTime: Date
    var answers: [String: Int] // questionId: answerIndex
}

@available(iOS 17, *)
public struct QuizStatistics {
    let totalQuizzesTaken: Int
    let totalQuizzesPassed: Int
    let averageScore: Double
    let passRate: Double
    let currentStreak: Int
    let longestStreak: Int
    let totalStudyTime: Int
    let certificatesEarned: Int
    let favoriteCategories: [QuizCategory]
    let strongestCategories: [QuizCategory: Double]
    let achievements: [QuizAchievement]
    
    public var formattedAverageScore: String {
        String(format: "%.1f%%", averageScore)
    }
    
    public var formattedPassRate: String {
        String(format: "%.1f%%", passRate)
    }
    
    public var formattedStudyTime: String {
        let hours = totalStudyTime / 60
        let minutes = totalStudyTime % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Error Extensions

extension IslamicQuizError {
    static let noActiveSession = NSError(
        domain: "IslamicQuizError",
        code: 1001,
        userInfo: [NSLocalizedDescriptionKey: "No active quiz session found"]
    ) as Error
}

#endif
#endif
