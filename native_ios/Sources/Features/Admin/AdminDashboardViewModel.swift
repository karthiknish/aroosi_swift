import Foundation

#if os(iOS)
@available(iOS 17, *)
@MainActor
final class AdminDashboardViewModel: ObservableObject {
    struct State: Equatable {
        var overview: AdminOverviewMetrics?
        var recentMembers: [AdminUserSummary] = []
        var topActiveMembers: [AdminUserSummary] = []
        var insights: [Insight] = []
        var isLoading = false
        var isRefreshing = false
        var errorMessage: String?

        var isBusy: Bool { isLoading && !isRefreshing }
        var hasContent: Bool { overview != nil || !recentMembers.isEmpty || !topActiveMembers.isEmpty }
    }

    struct Insight: Identifiable, Equatable {
        enum Accent: Equatable {
            case primary
            case secondary
            case caution
        }

        let id: String
        let title: String
        let value: String
        let detail: String
        let systemImage: String
        let accent: Accent
    }

    @Published private(set) var state = State()

    private let repository: AdminRepository
    private let lookbackDays: Int
    private let logger = Logger.shared

    private var hasLoadedOnce = false

    init(repository: AdminRepository = FirestoreAdminRepository(),
         lookbackDays: Int = 7) {
        self.repository = repository
        self.lookbackDays = max(1, lookbackDays)
    }

    var lookbackDaysLabel: String {
        "\(lookbackDays)d"
    }

    func loadIfNeeded() {
        guard !hasLoadedOnce else { return }
        Task { await load(force: false) }
    }

    func reload() {
        Task { await load(force: true) }
    }

    func refresh() async {
        await load(force: true)
    }

    private func load(force: Bool) async {
        if state.isLoading && !force { return }
        state.errorMessage = nil
        state.isLoading = !force
        state.isRefreshing = force

        do {
            async let overviewTask = repository.fetchOverviewMetrics(lookbackDays: lookbackDays)
            async let recentMembersTask = repository.fetchRecentMembers(limit: 12)
            async let activeMembersTask = repository.fetchTopActiveMembers(limit: 8, lookbackDays: lookbackDays)

            let (overview, recentMembers, activeMembers) = try await (overviewTask, recentMembersTask, activeMembersTask)

            state.overview = overview
            state.recentMembers = recentMembers
            state.topActiveMembers = activeMembers
            state.insights = makeInsights(overview: overview,
                                          recentMembers: recentMembers,
                                          activeMembers: activeMembers)
            hasLoadedOnce = true
        } catch {
            logger.error("Admin dashboard load failed: \(error.localizedDescription)")
            state.errorMessage = "We couldn't load the latest admin data. Pull to refresh or try again shortly."
        }

        state.isLoading = false
        state.isRefreshing = false
    }

    private func makeInsights(overview: AdminOverviewMetrics,
                              recentMembers: [AdminUserSummary],
                              activeMembers: [AdminUserSummary]) -> [Insight] {
        var insights: [Insight] = []
        let total = max(overview.totalMembers, 1)
        let engagementRatio = Double(overview.activeMembers) / Double(total)
        let engagementPercent = Int((engagementRatio * 100).rounded())

        insights.append(
            Insight(
                id: "engagement",
                title: "Weekly Engagement",
                value: "\(engagementPercent)% active",
                detail: "\(overview.activeMembers) of \(overview.totalMembers) members engaged in the last \(lookbackDays) days.",
                systemImage: "person.3.sequence",
                accent: engagementPercent >= 50 ? .primary : .caution
            )
        )

        let newPerDay = Double(overview.newMembers) / Double(lookbackDays)
        let formattedNewPerDay = String(format: "%.1f", newPerDay)
        insights.append(
            Insight(
                id: "growth",
                title: "New Members",
                value: "\(overview.newMembers) joined",
                detail: "Averaging \(formattedNewPerDay) signups per day over the last \(lookbackDays) days.",
                systemImage: "person.crop.circle.badge.plus",
                accent: overview.newMembers > 0 ? .secondary : .caution
            )
        )

        let conversationRatio = overview.activeMembers == 0 ? 0 : Double(overview.conversationsActive) / Double(overview.activeMembers)
        let conversationPercent = Int((conversationRatio * 100).rounded())
        insights.append(
            Insight(
                id: "conversations",
                title: "Conversation Health",
                value: "\(overview.conversationsActive) active",
                detail: "\(conversationPercent)% of active members participated in conversations this week.",
                systemImage: "bubble.left.and.bubble.right",
                accent: conversationPercent >= 40 ? .primary : .caution
            )
        )

        if let newest = recentMembers.first, let joined = newest.joinedAt {
            let relative = joined.relativeDescription(unitsStyle: .abbreviated)
            insights.append(
                Insight(
                    id: "latest",
                    title: "Latest Member",
                    value: newest.displayName,
                    detail: "Joined \(relative). Welcome them with a tailored onboarding push.",
                    systemImage: "sparkles",
                    accent: .secondary
                )
            )
        }

        if let mostActive = activeMembers.first, let lastActive = mostActive.lastActiveAt {
            let lastActiveText = lastActive.relativeDescription(unitsStyle: .abbreviated)
            insights.append(
                Insight(
                    id: "champion",
                    title: "Community Champion",
                    value: mostActive.displayName,
                    detail: "Most engaged member, active \(lastActiveText). Consider a spotlight story.",
                    systemImage: "star.circle",
                    accent: .primary
                )
            )
        }

        let flagged = Set((recentMembers + activeMembers).filter { $0.flagged }.map { $0.id })
        if !flagged.isEmpty {
            insights.append(
                Insight(
                    id: "flagged",
                    title: "Accounts Requiring Review",
                    value: "\(flagged.count) flagged",
                    detail: "Audit \(flagged.count == 1 ? "this profile" : "these profiles") to keep the community safe.",
                    systemImage: "exclamationmark.triangle.fill",
                    accent: .caution
                )
            )
        }

        return insights
    }
}
#endif
