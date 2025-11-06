import SwiftUI

#if os(iOS)
@available(iOS 17, *)
struct AdminDashboardView: View {
    let user: UserProfile

    @StateObject private var viewModel: AdminDashboardViewModel
    @EnvironmentObject private var coordinator: NavigationCoordinator

    @State private var showingError = false

    private var state: AdminDashboardViewModel.State { viewModel.state }

    init(user: UserProfile, viewModel: AdminDashboardViewModel? = nil) {
        self.user = user
        let resolvedViewModel = viewModel ?? AdminDashboardViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    overviewSection
                    insightsSection
                    activeMembersSection
                    recentMembersSection
                    if !state.hasContent && !state.isBusy {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(AroosiColors.groupedBackground)
            .refreshable { await viewModel.refresh() }
            .overlay(alignment: .center) { loadingOverlay }
            .toolbar { toolbarContent }
            .navigationTitle("Admin")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { viewModel.loadIfNeeded() }
        .onChange(of: state.errorMessage) { message in
            showingError = message != nil
        }
        .alert("Unable to Load", isPresented: $showingError) {
            Button("Dismiss", role: .cancel) { showingError = false }
            Button("Retry") { viewModel.reload() }
        } message: {
            Text(state.errorMessage ?? "")
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                viewModel.reload()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(state.isLoading)
        }
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if state.isBusy {
            AroosiLoadingView(size: 48, color: AroosiColors.primary)
        }
    }

    @ViewBuilder
    private var overviewSection: some View {
        if let overview = state.overview {
            VStack(alignment: .leading, spacing: 12) {
                Text("Overview")
                    .font(AroosiTypography.heading(.h3))
                    .foregroundStyle(AroosiColors.text)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                    AdminMetricCard(title: "Total Members",
                                    value: formatCount(overview.totalMembers),
                                    subtitle: "All time",
                                    systemImage: "person.3.fill",
                                    tint: AroosiColors.primary)

                    AdminMetricCard(title: "Active Members",
                                    value: formatCount(overview.activeMembers),
                                    subtitle: "Last \(viewModel.lookbackDaysLabel)",
                                    systemImage: "bolt.horizontal.fill",
                                    tint: AroosiColors.accent)

                    AdminMetricCard(title: "New",
                                    value: formatCount(overview.newMembers),
                                    subtitle: "Last \(viewModel.lookbackDaysLabel)",
                                    systemImage: "person.crop.circle.badge.plus",
                                    tint: AroosiColors.secondary)

                    AdminMetricCard(title: "Matches",
                                    value: formatCount(overview.matchesCreated),
                                    subtitle: "Last \(viewModel.lookbackDaysLabel)",
                                    systemImage: "heart.circle.fill",
                                    tint: AroosiColors.primaryDark)

                    AdminMetricCard(title: "Conversations",
                                    value: formatCount(overview.conversationsActive),
                                    subtitle: "Last \(viewModel.lookbackDaysLabel)",
                                    systemImage: "bubble.left.and.bubble.right.fill",
                                    tint: AroosiColors.info)
                }
            }
        } else if state.isBusy {
            placeholderMetrics
        }
    }

    private var placeholderMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(AroosiTypography.heading(.h3))
                .foregroundStyle(AroosiColors.text)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AroosiColors.surfaceSecondary.opacity(0.5))
                        .frame(height: 120)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(.circular)
                        )
                }
            }
        }
    }

    @ViewBuilder
    private var insightsSection: some View {
        if !state.insights.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Insights")
                    .font(AroosiTypography.heading(.h3))
                    .foregroundStyle(AroosiColors.text)

                VStack(spacing: 12) {
                    ForEach(state.insights) { insight in
                        insightCard(insight)
                    }
                }
            }
        }
    }

    private func insightCard(_ insight: AdminDashboardViewModel.Insight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.systemImage)
                .font(.title3)
                .foregroundStyle(insightColor(for: insight))
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.title)
                        .font(AroosiTypography.body(weight: .semibold, size: 16))
                    Spacer()
                    Text(insight.value)
                        .font(AroosiTypography.caption(weight: .semibold))
                        .foregroundStyle(insightColor(for: insight))
                }
                Text(insight.detail)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
        }
        .padding(16)
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func insightColor(for insight: AdminDashboardViewModel.Insight) -> Color {
        switch insight.accent {
        case .primary: return AroosiColors.primary
        case .secondary: return AroosiColors.secondary
        case .caution: return AroosiColors.warning
        }
    }

    @ViewBuilder
    private var activeMembersSection: some View {
        if !state.topActiveMembers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(title: "Top Active Members", buttonTitle: "View Matches") {
                    coordinator.navigate(to: .matches)
                }

                VStack(spacing: 12) {
                    ForEach(state.topActiveMembers.prefix(5)) { member in
                        AdminMemberRow(summary: member, subtitle: subtitle(for: member, isRecent: false))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recentMembersSection: some View {
        if !state.recentMembers.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(title: "Recent Signups", buttonTitle: "View Home") {
                    coordinator.navigate(to: .home)
                }

                VStack(spacing: 12) {
                    ForEach(state.recentMembers.prefix(6)) { member in
                        AdminMemberRow(summary: member, subtitle: subtitle(for: member, isRecent: true))
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(AroosiTypography.heading(.h3))
                .foregroundStyle(AroosiColors.text)
            Spacer()
            Button(action: action) {
                Text(buttonTitle)
                    .font(AroosiTypography.caption(weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(AroosiColors.primary)
        }
    }

    private func subtitle(for member: AdminUserSummary, isRecent: Bool) -> String {
        var components: [String] = []
        if let location = member.location, !location.isEmpty {
            components.append(location)
        }
        if isRecent, let joinedAt = member.joinedAt {
            components.append("Joined \(joinedAt.relativeDescription(unitsStyle: .abbreviated))")
        } else if let lastActive = member.lastActiveAt {
            components.append("Active \(lastActive.relativeDescription(unitsStyle: .abbreviated))")
        }
        if member.flagged {
            components.append("⚠️ Flagged")
        }
        return components.joined(separator: " • ")
    }

    private func formatCount(_ value: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(AroosiColors.muted)
            Text("No dashboard data yet")
                .font(AroosiTypography.body(weight: .semibold, size: 16))
                .foregroundStyle(AroosiColors.text)
            Text("As members engage, key metrics and insights will appear here automatically.")
                .font(AroosiTypography.caption())
                .multilineTextAlignment(.center)
                .foregroundStyle(AroosiColors.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

@available(iOS 17, *)
private struct AdminMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                Spacer()
            }

            Text(value)
                .font(AroosiTypography.heading(.h2))
                .foregroundStyle(AroosiColors.text)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AroosiTypography.caption(weight: .semibold))
                    .foregroundStyle(AroosiColors.muted)
                Text(subtitle)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

@available(iOS 17, *)
private struct AdminMemberRow: View {
    let summary: AdminUserSummary
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            avatar
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(summary.displayName)
                    .font(AroosiTypography.body(weight: .semibold, size: 16))
                    .foregroundStyle(AroosiColors.text)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }

                if let email = summary.email {
                    Text(email)
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }

            Spacer()

            if let completion = completionValue {
                Gauge(value: completion, in: 0...100) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(Int(completion))%")
                        .font(AroosiTypography.caption(weight: .semibold))
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(AroosiColors.primary)
                .frame(width: 44, height: 44)
            }
        }
        .padding(16)
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = summary.avatarURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .clipShape(Circle())
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(AroosiColors.primary.opacity(0.2))
            .overlay {
                Text(String(summary.displayName.prefix(1)))
                    .font(AroosiTypography.body(weight: .bold, size: 18))
                    .foregroundStyle(AroosiColors.primary)
            }
    }

    private var completionValue: Double? {
        guard let raw = summary.profileCompletion else { return nil }
        let normalized = raw <= 1 ? raw * 100 : raw
        return min(max(normalized, 0), 100)
    }
}
#endif
