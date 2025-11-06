import Foundation
import Combine

#if os(iOS)

/// Service for calculating compatibility scores between users
@available(iOS 17, *)
@MainActor
public final class CompatibilityService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var userResponse: CompatibilityResponse?
    @Published public private(set) var responseState = UserResponseState()
    @Published public private(set) var currentScore: CompatibilityScore?
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    private let repository: CompatibilityRepository
    private let analytics: AnalyticsService
    
    // MARK: - Initialization
    
    public init(
        repository: CompatibilityRepository = CompatibilityRepository(),
        analytics: AnalyticsService = AnalyticsService.shared
    ) {
        self.repository = repository
        self.analytics = analytics
    }
    
    // MARK: - Response Management
    
    /// Save or update a user's response to a specific question
    public func saveResponse(questionId: String, value: ResponseValue) {
        responseState.responses[questionId] = value
        analytics.track(AnalyticsEvent(
            name: "compatibility_question_answered",
            parameters: [
                "question_id": questionId,
                "progress": "\(responseState.progressPercentage)"
            ]
        ))
    }
    
    /// Submit completed questionnaire
    public func submitQuestionnaire(userId: String) async throws {
        isLoading = true
        error = nil
        
        do {
            let response = CompatibilityResponse(
                userId: userId,
                responses: responseState.responses,
                completedAt: Date()
            )
            
            try await repository.saveResponse(response)
            userResponse = response
            
            analytics.track(AnalyticsEvent(
                name: "compatibility_questionnaire_completed",
                parameters: [
                    "user_id": userId,
                    "total_questions": "\(responseState.responses.count)"
                ]
            ))
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            throw error
        }
    }
    
    /// Load user's existing response
    public func loadUserResponse(userId: String) async {
        isLoading = true
        error = nil
        
        do {
            if let response = try await repository.fetchResponse(userId: userId) {
                userResponse = response
                responseState.responses = response.responses
            }
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    // MARK: - Compatibility Calculation
    
    /// Calculate compatibility between two users
    public func calculateCompatibility(
        user1Response: CompatibilityResponse,
        user2Response: CompatibilityResponse
    ) -> CompatibilityScore {
        let categories = IslamicCompatibilityQuestions.getCategories()
        var categoryScores: [String: Double] = [:]
        var totalWeightedScore: Double = 0.0
        
        for category in categories {
            let categoryScore = calculateCategoryScore(
                category: category,
                user1Responses: user1Response.responses,
                user2Responses: user2Response.responses
            )
            categoryScores[category.id] = categoryScore
            totalWeightedScore += categoryScore * category.weight
        }
        
        // Normalize to 0-100 scale
        let overallScore = totalWeightedScore * 100
        
        let score = CompatibilityScore(
            userId1: user1Response.userId,
            userId2: user2Response.userId,
            overallScore: overallScore,
            categoryScores: categoryScores,
            calculatedAt: Date(),
            detailedBreakdown: generateDetailedBreakdown(categoryScores: categoryScores, categories: categories)
        )
        
        analytics.track(AnalyticsEvent(
            name: "compatibility_score_calculated",
            parameters: [
                "user1_id": user1Response.userId,
                "user2_id": user2Response.userId,
                "overall_score": "\(overallScore)",
                "compatibility_level": score.compatibilityLevel
            ]
        ))
        
        return score
    }
    
    /// Calculate compatibility score for a specific category
    private func calculateCategoryScore(
        category: IslamicCompatibilityCategory,
        user1Responses: [String: ResponseValue],
        user2Responses: [String: ResponseValue]
    ) -> Double {
        var totalScore: Double = 0.0
        var questionCount = 0
        
        for question in category.questions {
            if let questionScore = calculateQuestionScore(
                question: question,
                user1Answer: user1Responses[question.id],
                user2Answer: user2Responses[question.id]
            ), questionScore >= 0 {
                totalScore += questionScore
                questionCount += 1
            }
        }
        
        return questionCount > 0 ? totalScore / Double(questionCount) : 0.0
    }
    
    /// Calculate score for a single question
    private func calculateQuestionScore(
        question: CompatibilityQuestion,
        user1Answer: ResponseValue?,
        user2Answer: ResponseValue?
    ) -> Double? {
        guard let answer1 = user1Answer, let answer2 = user2Answer else {
            return nil // Invalid comparison
        }
        
        switch question.type {
        case .singleChoice, .yesNo:
            return compareSingleChoice(question: question, answer1: answer1, answer2: answer2)
        case .scale:
            return compareScale(question: question, answer1: answer1, answer2: answer2)
        case .multipleChoice:
            return compareMultipleChoice(question: question, answer1: answer1, answer2: answer2)
        }
    }
    
    /// Compare single choice answers
    private func compareSingleChoice(
        question: CompatibilityQuestion,
        answer1: ResponseValue,
        answer2: ResponseValue
    ) -> Double {
        guard case .single(let value1) = answer1,
              case .single(let value2) = answer2,
              let option1 = question.options.first(where: { $0.id == value1 }),
              let option2 = question.options.first(where: { $0.id == value2 }) else {
            return 0.0
        }
        
        // Direct value comparison
        if option1.value == option2.value {
            return 1.0
        }
        
        // Calculate similarity based on value difference
        let difference = abs(option1.value - option2.value)
        return max(0.0, 1.0 - difference)
    }
    
    /// Compare scale answers
    private func compareScale(
        question: CompatibilityQuestion,
        answer1: ResponseValue,
        answer2: ResponseValue
    ) -> Double {
        guard case .single(let value1) = answer1,
              case .single(let value2) = answer2,
              let option1 = question.options.first(where: { $0.id == value1 }),
              let option2 = question.options.first(where: { $0.id == value2 }) else {
            return 0.0
        }
        
        // Calculate similarity based on value difference
        let difference = abs(option1.value - option2.value)
        return max(0.0, 1.0 - difference)
    }
    
    /// Compare multiple choice answers (Jaccard similarity)
    private func compareMultipleChoice(
        question: CompatibilityQuestion,
        answer1: ResponseValue,
        answer2: ResponseValue
    ) -> Double {
        guard case .multiple(let values1) = answer1,
              case .multiple(let values2) = answer2 else {
            return 0.0
        }
        
        if values1.isEmpty && values2.isEmpty {
            return 1.0
        }
        
        // Calculate Jaccard similarity (intersection / union)
        let set1 = Set(values1)
        let set2 = Set(values2)
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        
        guard !union.isEmpty else { return 1.0 }
        
        return Double(intersection.count) / Double(union.count)
    }
    
    /// Generate detailed breakdown for analysis
    private func generateDetailedBreakdown(
        categoryScores: [String: Double],
        categories: [IslamicCompatibilityCategory]
    ) -> [String: Double] {
        var breakdown: [String: Double] = [:]
        
        for category in categories {
            if let score = categoryScores[category.id] {
                breakdown["\(category.id)_score"] = score
                breakdown["\(category.id)_weighted"] = score * category.weight
            }
        }
        
        return breakdown
    }
    
    // MARK: - Report Management
    
    /// Generate and save compatibility report
    public func generateReport(
        userId1: String,
        userId2: String
    ) async throws -> CompatibilityReport {
        isLoading = true
        error = nil
        
        do {
            guard let response1 = try await repository.fetchResponse(userId: userId1),
                  let response2 = try await repository.fetchResponse(userId: userId2) else {
                throw CompatibilityError.responsesNotFound
            }
            
            let score = calculateCompatibility(
                user1Response: response1,
                user2Response: response2
            )
            
            let report = CompatibilityReport(
                id: UUID().uuidString,
                userId1: userId1,
                userId2: userId2,
                scores: score,
                generatedAt: Date(),
                familyFeedback: nil,
                isShared: false
            )
            
            try await repository.saveReport(report)
            
            analytics.track(AnalyticsEvent(
                name: "compatibility_report_generated",
                parameters: [
                    "report_id": report.id,
                    "user1_id": userId1,
                    "user2_id": userId2,
                    "overall_score": "\(score.overallScore)"
                ]
            ))
            
            isLoading = false
            return report
        } catch {
            self.error = error
            isLoading = false
            throw error
        }
    }
    
    /// Fetch compatibility reports for a user
    public func fetchReports(userId: String) async throws -> [CompatibilityReport] {
        isLoading = true
        error = nil
        
        do {
            let reports = try await repository.fetchReports(userId: userId)
            
            analytics.track(AnalyticsEvent(
                name: "compatibility_reports_loaded",
                parameters: [
                    "user_id": userId,
                    "report_count": "\(reports.count)"
                ]
            ))
            
            isLoading = false
            return reports
        } catch {
            self.error = error
            isLoading = false
            throw error
        }
    }
    
    /// Share report with family member
    public func shareReport(reportId: String, withUserId: String) async throws {
        try await repository.shareReport(reportId: reportId, withUserId: withUserId)
        
        analytics.track(AnalyticsEvent(
            name: "compatibility_report_shared",
            parameters: [
                "report_id": reportId,
                "shared_with": withUserId
            ]
        ))
    }
    
    // MARK: - Progress Tracking
    
    /// Get current progress through questionnaire
    public var progress: Double {
        responseState.progressPercentage
    }
    
    /// Check if questionnaire is complete
    public var isComplete: Bool {
        responseState.isComplete
    }
    
    /// Reset questionnaire state
    public func resetQuestionnaire() {
        responseState = UserResponseState()
        analytics.track(event: "compatibility_questionnaire_reset")
    }
}

// MARK: - Errors

public enum CompatibilityError: LocalizedError {
    case responsesNotFound
    case invalidResponse
    case saveFailed
    
    public var errorDescription: String? {
        switch self {
        case .responsesNotFound:
            return "Could not find compatibility responses for one or both users"
        case .invalidResponse:
            return "The response data is invalid or incomplete"
        case .saveFailed:
            return "Failed to save compatibility data"
        }
    }
}

#endif
