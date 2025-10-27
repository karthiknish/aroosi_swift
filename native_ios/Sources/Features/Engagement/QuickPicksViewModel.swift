import Foundation

@available(iOS 17, *)
@MainActor
final class QuickPicksViewModel: ObservableObject {
    struct State: Equatable {
        var recommendations: [QuickPickRecommendation] = []
        var currentIndex: Int = 0
        var compatibilityScores: [String: Int] = [:]
        var isLoading: Bool = false
        var isPerformingAction: Bool = false
        var errorMessage: String?
        var infoMessage: String?
        var likesUsed: Int = 0
        var dailyLimit: Int = 10
        var dayKey: String?

        var currentRecommendation: QuickPickRecommendation? {
            guard currentIndex < recommendations.count else { return nil }
            return recommendations[currentIndex]
        }

        var upcomingRecommendations: [QuickPickRecommendation] {
            guard currentIndex < recommendations.count else { return [] }
            return Array(recommendations.suffix(from: currentIndex + 1).prefix(3))
        }

        func compatibility(for id: String) -> Int? {
            compatibilityScores[id]
        }

        var canLikeCurrent: Bool {
            likesUsed < dailyLimit
        }
    }

    @Published private(set) var state = State()

    private let repository: QuickPicksRepository
    private let logger = Logger.shared

    init(repository: QuickPicksRepository? = nil) {
        if let repository {
            self.repository = repository
        } else if let remote = try? RemoteQuickPicksRepository() {
            self.repository = remote
        } else {
            self.repository = EmptyQuickPicksRepository()
        }
    }

    func load(dayKey: String? = nil) async {
        state.isLoading = true
        state.errorMessage = nil
        state.infoMessage = nil
        state.dayKey = dayKey

        do {
            let recommendations = try await repository.fetchQuickPicks(dayKey: dayKey)
            state.recommendations = recommendations
            state.currentIndex = 0
            state.compatibilityScores = [:]
            state.likesUsed = 0
            state.isLoading = false

            if recommendations.isEmpty {
                state.infoMessage = "No quick picks available. Check back later."
            } else {
                await loadCompatibilityScores(for: recommendations)
            }
        } catch {
            logger.error("Quick picks load failed: \(error.localizedDescription)")
            state.isLoading = false
            state.errorMessage = "Unable to load quick picks. Please try again later."
        }
    }

    func refresh() async {
        await load(dayKey: state.dayKey)
    }

    func likeCurrent() async {
        guard let recommendation = state.currentRecommendation else { return }
        guard state.canLikeCurrent else {
            state.infoMessage = "You've reached today's like limit."
            return
        }

        await perform(action: .like, for: recommendation)
        state.likesUsed += 1
    }

    func skipCurrent() async {
        guard let recommendation = state.currentRecommendation else { return }
        await perform(action: .skip, for: recommendation)
    }

    func dismissMessages() {
        state.errorMessage = nil
        state.infoMessage = nil
    }

    private func perform(action: QuickPickAction, for recommendation: QuickPickRecommendation) async {
        guard !state.isPerformingAction else { return }
        state.isPerformingAction = true
        defer { state.isPerformingAction = false }

        do {
            try await repository.act(on: recommendation.id, action: action)
            advance()
        } catch {
            logger.error("Quick pick action failed: \(error.localizedDescription)")
            state.errorMessage = "We couldn't complete that action. Please try again."
        }
    }

    private func advance() {
        let nextIndex = state.currentIndex + 1
        if nextIndex < state.recommendations.count {
            state.currentIndex = nextIndex
        } else {
            state.currentIndex = state.recommendations.count
            state.infoMessage = "You're all caught up for today!"
        }
    }

    private func loadCompatibilityScores(for recommendations: [QuickPickRecommendation]) async {
        var scores: [String: Int] = [:]
        for recommendation in recommendations {
            if Task.isCancelled { return }
            let score = (try? await repository.fetchCompatibilityScore(for: recommendation.id)) ?? 0
            scores[recommendation.id] = score
            state.compatibilityScores = scores
        }
    }
}

@available(iOS 17.0.0, *)
private struct EmptyQuickPicksRepository: QuickPicksRepository {
    func fetchQuickPicks(dayKey: String?) async throws -> [QuickPickRecommendation] { [] }
    func act(on userID: String, action: QuickPickAction) async throws {}
    func fetchCompatibilityScore(for userID: String) async throws -> Int { 0 }
}
