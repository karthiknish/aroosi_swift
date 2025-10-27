import Foundation

@available(iOS 17, *)
@MainActor
final class IcebreakersViewModel: ObservableObject {
    struct State: Equatable {
        var items: [IcebreakerItem] = []
        var isLoading: Bool = false
        var isRefreshing: Bool = false
        var errorMessage: String?
        var savingIdentifiers: Set<String> = []
        var isFeatureEnabled: Bool = false

        var completionProgress: Double {
            guard !items.isEmpty else { return 0 }
            let answered = items.filter { $0.isAnswered }.count
            return Double(answered) / Double(items.count)
        }
    }

    @Published private(set) var state = State()

    private let repository: IcebreakerRepository
    private let logger = Logger.shared
    private let featureFlagService: FeatureFlagService
    private var currentUserID: String?

    init(repository: IcebreakerRepository = FirestoreIcebreakerRepository(),
         featureFlagService: FeatureFlagService = .shared) {
        self.repository = repository
        self.featureFlagService = featureFlagService
        self.state.isFeatureEnabled = featureFlagService.isEnabled("ENABLE_ICEBREAKERS")
    }

    func load(for userID: String) {
        currentUserID = userID
        Task { await fetch(didRequestRefresh: false) }
    }

    func refresh() {
        Task { await fetch(didRequestRefresh: true) }
    }

    func submit(answer: String, for questionID: String) async {
        guard let currentUserID else { return }
        
        // Check if feature is enabled
        guard featureFlagService.isEnabled("ENABLE_ICEBREAKERS") else {
            state.errorMessage = "Icebreaker feature is currently disabled."
            return
        }
        
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else {
            state.errorMessage = "Answers must be at least 10 characters."
            return
        }

        state.savingIdentifiers.insert(questionID)

        do {
            try await repository.submitAnswer(trimmed, to: questionID, userID: currentUserID)
            state = stateAfterSaving(questionID: questionID, answer: trimmed)
        } catch {
            logger.error("Failed to submit icebreaker answer: \(error.localizedDescription)")
            state.errorMessage = "We couldn't save your answer. Please try again."
        }

        state.savingIdentifiers.remove(questionID)
    }

    func dismissError() {
        state.errorMessage = nil
    }

    private func fetch(didRequestRefresh: Bool) async {
        guard let currentUserID else { return }
        
        // Check if feature is enabled
        guard featureFlagService.isEnabled("ENABLE_ICEBREAKERS") else {
            state.errorMessage = "Icebreaker feature is currently disabled."
            state.isLoading = false
            state.isRefreshing = false
            return
        }

        if didRequestRefresh {
            state.isRefreshing = true
        } else {
            state.isLoading = true
        }
        state.errorMessage = nil

        do {
            let items = try await repository.fetchDailyIcebreakers(for: currentUserID)
            state.items = items
        } catch {
            logger.error("Failed to load icebreakers: \(error.localizedDescription)")
            state.errorMessage = "We couldn't load today's icebreakers. Pull to refresh to try again."
        }

        state.isLoading = false
        state.isRefreshing = false
    }

    private func stateAfterSaving(questionID: String, answer: String) -> State {
        var newState = state
        if let index = newState.items.firstIndex(where: { $0.id == questionID }) {
            newState.items[index].currentAnswer = answer
            newState.items[index].isAnswered = true
        }
        return newState
    }
}
