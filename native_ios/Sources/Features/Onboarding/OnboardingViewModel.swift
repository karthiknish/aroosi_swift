import Foundation

#if os(iOS)

@available(iOS 17, *)
@MainActor
final class OnboardingViewModel: ObservableObject {
    struct State: Equatable {
        var content: OnboardingContent?
        var isLoading: Bool = false
        var errorMessage: String?
        var infoMessage: String?
    }

    @Published private(set) var state = State()

    private let repository: OnboardingContentRepository
    private let fallbackProvider: OnboardingFallbackContentProviding
    private let logger = Logger.shared
    private var loadTask: Task<Void, Never>?

    init(repository: OnboardingContentRepository = FirestoreOnboardingContentRepository(),
         fallbackProvider: OnboardingFallbackContentProviding = SecretsOnboardingFallbackContentProvider()) {
        self.repository = repository
        self.fallbackProvider = fallbackProvider
    }

    deinit {
        loadTask?.cancel()
    }

    func loadIfNeeded() {
        guard state.content == nil else { return }
        performLoad(force: false)
    }

    func loadContent() {
        performLoad(force: true)
    }

    func refresh() {
        performLoad(force: true)
    }

    func retry() {
        refresh()
    }

    private func performLoad(force: Bool) {
        if state.isLoading {
            guard force else { return }
            loadTask?.cancel()
        }

        state.isLoading = true
        state.errorMessage = nil
        state.infoMessage = nil

        loadTask = Task { @MainActor [weak self] in
            guard let self else { return }

            defer {
                self.state.isLoading = false
                self.loadTask = nil
            }

            do {
                let content = try await repository.fetchContent()
                self.state.content = content
                self.state.errorMessage = nil
                self.state.infoMessage = nil
            } catch RepositoryError.notFound {
                self.logger.error("Onboarding content not found in backend")
                self.applyFallbackOrError(message: "We couldn't load onboarding content right now.")
            } catch {
                self.logger.error("Failed to load onboarding content: \(error.localizedDescription)")
                self.applyFallbackOrError(message: "We couldn't load onboarding content right now.")
            }
        }
    }

    private func applyFallbackOrError(message: String) {
        if let fallback = fallbackProvider.fallbackContent() {
            state.content = fallback
            state.errorMessage = nil
            state.infoMessage = "We're showing saved highlights while we reconnect."
        } else {
            state.errorMessage = message
        }
    }
}

protocol OnboardingFallbackContentProviding {
    func fallbackContent() -> OnboardingContent?
}

@available(iOS 17, *)
struct SecretsOnboardingFallbackContentProvider: OnboardingFallbackContentProviding {
    private let secretsLoader: SecretsLoading

    init(secretsLoader: SecretsLoading = DotenvSecretsLoader()) {
        self.secretsLoader = secretsLoader
    }

    func fallbackContent() -> OnboardingContent? {
        guard let secrets = try? secretsLoader.load() else { return nil }

        guard let titleRaw = secrets["ONBOARDING_TITLE"], !titleRaw.isEmpty,
              let taglineRaw = secrets["ONBOARDING_TAGLINE"], !taglineRaw.isEmpty else {
            return nil
        }

        let callToAction = secrets["ONBOARDING_CTA"].flatMap { !$0.isEmpty ? $0 : nil } ?? "Get Started"
        let heroURL = secrets["ONBOARDING_HERO_URL"].flatMap { url -> URL? in
            guard !url.isEmpty else { return nil }
            return URL(string: url)
        }

        return OnboardingContent(title: titleRaw,
                                 tagline: taglineRaw,
                                 heroImageURL: heroURL,
                                 callToActionTitle: callToAction)
    }
}

#endif
