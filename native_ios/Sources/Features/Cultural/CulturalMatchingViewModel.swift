import Foundation

#if os(iOS)

@available(iOS 17, *)
@MainActor
final class CulturalMatchingViewModel: ObservableObject {
    struct State: Equatable {
        var profile: CulturalProfile?
        var recommendations: [CulturalRecommendation] = []
        var isLoading: Bool = false
        var isRefreshing: Bool = false
        var errorMessage: String?
        var lastUpdated: Date?

        var hasContent: Bool {
            profile != nil || !recommendations.isEmpty
        }
    }

    @Published private(set) var state = State()

    private let repository: CulturalRepository
    private let logger = Logger.shared
    private var currentUserID: String?

    init(repository: CulturalRepository = CulturalRepositoryFactory.makeDefaultRepository()) {
        self.repository = repository
    }

    func load(for userID: String) {
        guard currentUserID != userID || state.recommendations.isEmpty else { return }
        currentUserID = userID
        Task { await fetch(didRequestRefresh: false) }
    }

    func refresh() {
        Task { await fetch(didRequestRefresh: true) }
    }

    func dismissError() {
        state.errorMessage = nil
    }

    private func fetch(didRequestRefresh: Bool) async {
        guard currentUserID != nil else { return }
        if didRequestRefresh {
            state.isRefreshing = true
        } else {
            state.isLoading = true
        }
        state.errorMessage = nil

        do {
            async let profileTask = repository.fetchProfile(userID: nil)
            async let recommendationsTask = repository.fetchRecommendations(limit: 12)

            let (profile, recommendations) = try await (profileTask, recommendationsTask)
            state.profile = profile
            state.recommendations = recommendations
            state.lastUpdated = Date()
        } catch {
            logger.error("Failed to load cultural matches: \(error.localizedDescription)")
            state.errorMessage = "We couldn't load your cultural matches right now. Pull to refresh to try again."
        }

        state.isLoading = false
        state.isRefreshing = false
    }
}

@available(iOS 17, *)
@MainActor
final class CulturalCompatibilityViewModel: ObservableObject {
    struct State: Equatable {
        var report: CulturalCompatibilityReport?
        var isLoading: Bool = false
        var errorMessage: String?
    }

    @Published private(set) var state = State()

    private let repository: CulturalRepository
    private let logger = Logger.shared

    init(repository: CulturalRepository = CulturalRepositoryFactory.makeDefaultRepository()) {
        self.repository = repository
    }

    func load(primaryUserID: String, targetUserID: String) {
        Task { await fetch(primaryUserID: primaryUserID, targetUserID: targetUserID) }
    }

    func refresh(primaryUserID: String, targetUserID: String) {
        Task { await fetch(primaryUserID: primaryUserID, targetUserID: targetUserID) }
    }

    func dismissError() {
        state.errorMessage = nil
    }

    private func fetch(primaryUserID: String, targetUserID: String) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let report = try await repository.fetchCompatibilityReport(primaryUserID: primaryUserID,
                                                                        targetUserID: targetUserID)
            state.report = report
        } catch {
            logger.error("Failed to load cultural compatibility: \(error.localizedDescription)")
            state.errorMessage = "We couldn't load the compatibility report. Please try again later."
        }

        state.isLoading = false
    }
}

@available(iOS 17.0.0, *)
private enum CulturalRepositoryFactory {
    static func makeDefaultRepository() -> CulturalRepository {
        if let remote = try? RemoteCulturalRepository() {
            return remote
        }
        return FallbackCulturalRepository()
    }
}

@available(iOS 17.0.0, *)
private struct FallbackCulturalRepository: CulturalRepository {
    func fetchProfile(userID: String?) async throws -> CulturalProfile? { nil }
    func updateProfile(_ profile: CulturalProfile, userID: String?) async throws {}
    func fetchRecommendations(limit: Int) async throws -> [CulturalRecommendation] { [] }
    func fetchCompatibilityReport(primaryUserID: String, targetUserID: String) async throws -> CulturalCompatibilityReport {
        CulturalCompatibilityReport(overallScore: 0, insights: [], dimensions: [])
    }
}

#endif
