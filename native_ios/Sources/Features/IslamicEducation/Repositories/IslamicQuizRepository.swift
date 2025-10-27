import Foundation
import Combine

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17, *)
public protocol IslamicQuizRepository {
    func fetchQuizzes(category: QuizCategory?, difficulty: QuizDifficulty?) async throws -> [IslamicQuiz]
    func fetchQuiz(by id: String) async throws -> IslamicQuiz
    func saveQuizResult(_ result: IslamicQuizResult) async throws
    func getUserQuizResults(userId: String) async throws -> [IslamicQuizResult]
    func getUserQuizProfile(userId: String) async throws -> UserIslamicQuizProfile
    func updateUserQuizProfile(_ profile: UserIslamicQuizProfile) async throws
    func getQuizzesByCategory(_ category: QuizCategory) async throws -> [IslamicQuiz]
    func getFeaturedQuizzes() async throws -> [IslamicQuiz]
}

@available(iOS 17, *)
public final class FirebaseIslamicQuizRepository: IslamicQuizRepository {
    private let db = Firestore.firestore()
    private let logger = Logger.shared
    
    // Collection references
    private let quizzesCollection = "islamic_quizzes"
    private let resultsCollection = "islamic_quiz_results"
    private let profilesCollection = "islamic_quiz_profiles"
    
    public init() {
        logger.info("[FirebaseIslamicQuizRepository] Initialized")
    }
    
    // MARK: - Quiz Fetching
    
    public func fetchQuizzes(category: QuizCategory? = nil, difficulty: QuizDifficulty? = nil) async throws -> [IslamicQuiz] {
        logger.info("Fetching quizzes with category: \(category?.rawValue ?? "all"), difficulty: \(difficulty?.rawValue ?? "all")")
        
        var query: Query = db.collection(quizzesCollection)
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
        
        if let category = category {
            query = query.whereField("category", isEqualTo: category.rawValue)
        }
        
        if let difficulty = difficulty {
            query = query.whereField("difficulty", isEqualTo: difficulty.rawValue)
        }
        
        let snapshot = try await query.getDocuments()
        let quizzes = try snapshot.documents.compactMap { document in
            try document.data(as: IslamicQuiz.self)
        }
        
        logger.info("Fetched \(quizzes.count) quizzes")
        return quizzes
    }
    
    public func fetchQuiz(by id: String) async throws -> IslamicQuiz {
        logger.info("Fetching quiz by ID: \(id)")
        
        let document = try await db.collection(quizzesCollection).document(id).getDocument()
        
        guard let quiz = try document.data(as: IslamicQuiz.self) else {
            throw IslamicQuizError.quizNotFound
        }
        
        return quiz
    }
    
    public func getQuizzesByCategory(_ category: QuizCategory) async throws -> [IslamicQuiz] {
        return try await fetchQuizzes(category: category, difficulty: nil)
    }
    
    public func getFeaturedQuizzes() async throws -> [IslamicQuiz] {
        logger.info("Fetching featured quizzes")
        
        let snapshot = try await db.collection(quizzesCollection)
            .whereField("isActive", isEqualTo: true)
            .whereField("isFeatured", isEqualTo: true)
            .order(by: "featuredOrder")
            .limit(to: 10)
            .getDocuments()
        
        let quizzes = try snapshot.documents.compactMap { document in
            try document.data(as: IslamicQuiz.self)
        }
        
        logger.info("Fetched \(quizzes.count) featured quizzes")
        return quizzes
    }
    
    // MARK: - Quiz Results
    
    public func saveQuizResult(_ result: IslamicQuizResult) async throws {
        logger.info("Saving quiz result for user: \(result.userId), quiz: \(result.quizId)")
        
        try await db.collection(resultsCollection)
            .document(result.id)
            .setData(from: result)
        
        // Update user profile
        await updateUserProfileWithResult(result)
        
        logger.info("Quiz result saved successfully")
    }
    
    public func getUserQuizResults(userId: String) async throws -> [IslamicQuizResult] {
        logger.info("Fetching quiz results for user: \(userId)")
        
        let snapshot = try await db.collection(resultsCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "completedAt", descending: true)
            .getDocuments()
        
        let results = try snapshot.documents.compactMap { document in
            try document.data(as: IslamicQuizResult.self)
        }
        
        logger.info("Fetched \(results.count) quiz results for user: \(userId)")
        return results
    }
    
    // MARK: - User Profile Management
    
    public func getUserQuizProfile(userId: String) async throws -> UserIslamicQuizProfile {
        logger.info("Fetching quiz profile for user: \(userId)")
        
        let document = try await db.collection(profilesCollection)
            .document(userId)
            .getDocument()
        
        if let profile = try document.data(as: UserIslamicQuizProfile.self) {
            return profile
        } else {
            // Create new profile if it doesn't exist
            let newProfile = UserIslamicQuizProfile(userId: userId)
            try await updateUserQuizProfile(newProfile)
            return newProfile
        }
    }
    
    public func updateUserQuizProfile(_ profile: UserIslamicQuizProfile) async throws {
        logger.info("Updating quiz profile for user: \(profile.userId)")
        
        let updatedProfile = UserIslamicQuizProfile(
            userId: profile.userId,
            totalQuizzesTaken: profile.totalQuizzesTaken,
            totalQuizzesPassed: profile.totalQuizzesPassed,
            averageScore: profile.averageScore,
            favoriteCategories: profile.favoriteCategories,
            strongestCategories: profile.strongestCategories,
            weakestCategories: profile.weakestCategories,
            certificatesEarned: profile.certificatesEarned,
            lastQuizDate: profile.lastQuizDate,
            currentStreak: profile.currentStreak,
            longestStreak: profile.longestStreak,
            totalStudyTime: profile.totalStudyTime,
            achievements: profile.achievements,
            preferredDifficulty: profile.preferredDifficulty,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
        
        try await db.collection(profilesCollection)
            .document(profile.userId)
            .setData(from: updatedProfile)
        
        logger.info("Quiz profile updated successfully")
    }
    
    // MARK: - Private Helper Methods
    
    private func updateUserProfileWithResult(_ result: IslamicQuizResult) async {
        do {
            var profile = try await getUserQuizProfile(userId: result.userId)
            
            // Update basic statistics
            profile.totalQuizzesTaken += 1
            if result.passed {
                profile.totalQuizzesPassed += 1
                profile.certificatesEarned.append(result.quizId)
            }
            
            // Update average score
            let totalScore = profile.averageScore * Double(profile.totalQuizzesTaken - 1) + Double(result.score)
            profile.averageScore = totalScore / Double(profile.totalQuizzesTaken)
            
            // Update last quiz date and streak
            profile.lastQuizDate = result.completedAt
            profile.currentStreak = calculateStreak(from: profile.lastQuizDate)
            profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
            
            // Update study time
            profile.totalStudyTime += result.timeTaken / 60 // Convert to minutes
            
            // Update category performance
            await updateCategoryPerformance(&profile, result: result)
            
            // Check for new achievements
            profile.achievements = checkForAchievements(profile: profile, result: result)
            
            // Save updated profile
            try await updateUserQuizProfile(profile)
            
            logger.info("User profile updated with quiz result")
            
        } catch {
            logger.error("Failed to update user profile: \(error.localizedDescription)")
        }
    }
    
    private func updateCategoryPerformance(_ profile: inout UserIslamicQuizProfile, result: IslamicQuizResult) async {
        // Get the quiz to determine its category
        do {
            let quiz = try await fetchQuiz(by: result.quizId)
            
            // Update strongest categories
            let currentScore = profile.strongestCategories[quiz.category] ?? 0.0
            let newScore = (currentScore + Double(result.score)) / 2.0
            profile.strongestCategories[quiz.category] = newScore
            
            // Update weakest categories if score is low
            if result.score < 60 {
                let weakScore = profile.weakestCategories[quiz.category] ?? 100.0
                let newWeakScore = (weakScore + Double(result.score)) / 2.0
                profile.weakestCategories[quiz.category] = newWeakScore
            }
            
            // Update favorite categories (based on attempt frequency)
            if !profile.favoriteCategories.contains(quiz.category) {
                profile.favoriteCategories.append(quiz.category)
            }
            
        } catch {
            logger.error("Failed to update category performance: \(error.localizedDescription)")
        }
    }
    
    private func calculateStreak(from lastDate: Date?) -> Int {
        guard let lastDate = lastDate else { return 1 }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(lastDate, inSameDayAs: now) {
            return 1 // Same day, maintain streak
        } else if calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return 2 // Yesterday, increment streak
        } else {
            return 1 // More than a day ago, reset streak
        }
    }
    
    private func checkForAchievements(profile: UserIslamicQuizProfile, result: IslamicQuizResult) -> [QuizAchievement] {
        var achievements = profile.achievements
        
        // Check for various achievements
        if profile.totalQuizzesTaken == 1 {
            achievements.append(QuizAchievement(
                title: "First Steps",
                description: "Completed your first Islamic quiz",
                icon: "star.circle",
                requirement: .quizzesTaken(count: 1)
            ))
        }
        
        if profile.totalQuizzesTaken == 10 {
            achievements.append(QuizAchievement(
                title: "Dedicated Learner",
                description: "Completed 10 Islamic quizzes",
                icon: "book.circle",
                requirement: .quizzesTaken(count: 10)
            ))
        }
        
        if profile.totalQuizzesPassed == 5 {
            achievements.append(QuizAchievement(
                title: "Successful Student",
                description: "Passed 5 Islamic quizzes",
                icon: "checkmark.circle",
                requirement: .quizzesPassed(count: 5)
            ))
        }
        
        if result.score == 100 {
            achievements.append(QuizAchievement(
                title: "Perfect Score",
                description: "Achieved 100% on a quiz",
                icon: "crown",
                requirement: .perfectScores(count: 1)
            ))
        }
        
        if profile.currentStreak == 7 {
            achievements.append(QuizAchievement(
                title: "Week Warrior",
                description: "Maintained a 7-day quiz streak",
                icon: "flame",
                requirement: .streakDays(days: 7)
            ))
        }
        
        return achievements
    }
}

// MARK: - Error Types

public enum IslamicQuizError: LocalizedError {
    case quizNotFound
    case profileNotFound
    case saveFailed
    case fetchFailed
    
    public var errorDescription: String? {
        switch self {
        case .quizNotFound:
            return "The requested quiz could not be found."
        case .profileNotFound:
            return "User quiz profile could not be found."
        case .saveFailed:
            return "Failed to save quiz result. Please try again."
        case .fetchFailed:
            return "Failed to fetch quiz data. Please check your connection."
        }
    }
}

#endif
