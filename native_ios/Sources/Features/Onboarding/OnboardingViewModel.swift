import Foundation

@available(macOS 12.0, iOS 17, *)
@MainActor
final class OnboardingViewModel: ObservableObject {
    struct State: Equatable {
        var content: OnboardingContent?
        var isLoading: Bool = false
        var errorMessage: String?
    }

    @Published private(set) var state = State()

    private let repository: OnboardingContentRepository
    private let logger = Logger.shared

    init(repository: OnboardingContentRepository = FirestoreOnboardingContentRepository()) {
        self.repository = repository
    }

    func loadContent() {
        state.isLoading = true
        state.errorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                let content = try await repository.fetchContent()
                self.state.content = content
                self.state.errorMessage = nil
            } catch RepositoryError.notFound {
                self.logger.error("Onboarding content not found in backend")
                self.state.errorMessage = "We couldn't load onboarding content right now."
            } catch {
                self.logger.error("Failed to load onboarding content: \(error.localizedDescription)")
                self.state.errorMessage = "We couldn't load onboarding content right now."
            }

            self.state.isLoading = false
        }
    }

    func retry() {
        loadContent()
    }
}
