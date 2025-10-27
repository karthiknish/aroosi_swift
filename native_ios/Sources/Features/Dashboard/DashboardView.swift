#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct DashboardView: View {
    let user: UserProfile
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var dashboardRoute: NavigationCoordinator.DashboardRoute?

    @MainActor
    init(user: UserProfile, viewModel: DashboardViewModel? = nil) {
        self.user = user
        let resolvedViewModel = viewModel ?? DashboardViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let width = proxy.size.width
                ScrollView {
                    VStack(spacing: Responsive.spacing(width: width, multiplier: 1.0)) {
                        if let info = viewModel.state.infoMessage {
                            InfoBanner(message: info, onDismiss: viewModel.dismissInfoMessage)
                        }
                        greetingSection(width: width)
                        statsSection(width: width)
                        quickActionsSection(width: width)
                        recentMatchesSection(width: width)
                        quickPicksSection(width: width)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Responsive.screenPadding(width: width))
                }
                .background(AroosiColors.groupedBackground)
                .refreshable { viewModel.refresh() }
                .overlay { loadingOverlay }
            }
            .background(AroosiColors.groupedBackground)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
        .background(AroosiColors.groupedBackground.ignoresSafeArea())
        .task(id: user.id) {
            viewModel.loadIfNeeded(for: user.id)
        }
        .onAppear { handlePendingRoute() }
        .onChange(of: coordinator.pendingRoute) { _ in
            handlePendingRoute()
        }
        .navigationDestination(item: $dashboardRoute) { destination in
            switch destination {
            case .quickPicks:
                QuickPicksView(user: user)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .culturalMatching:
                CulturalMatchingView(user: user)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .icebreakers:
                IcebreakersView(user: user)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .recentMatches:
                MatchesView(user: user)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
    }

    private func greetingSection(width: CGFloat) -> some View {
        let displayName = viewModel.state.profile?.displayName.nonEmpty ?? user.displayName
        let location = viewModel.state.profile?.location?.nonEmpty

        return VStack(alignment: .leading, spacing: 12) {
            Text("Salaam, \(displayName)")
                .font(AroosiTypography.heading(.h1))

            if let location {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }

            if let error = viewModel.state.errorMessage {
                Text(error)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statsSection(width: CGFloat) -> some View {
        let stackSpacing = Responsive.isLargeScreen(width: width) ? AroosiSpacing.lg : AroosiSpacing.md
        let content = Group {
            StatCard(title: "Matches",
                     value: viewModel.state.activeMatchesCount,
                     systemImage: "heart.fill",
                     tint: AroosiColors.primary)

            StatCard(title: "Unread",
                     value: viewModel.state.unreadMessagesCount,
                     systemImage: "bubble.left.and.bubble.right.fill",
                     tint: AroosiColors.secondary)
        }

        return Group {
            if Responsive.isLargeScreen(width: width) {
                HStack(spacing: stackSpacing) { content }
            } else {
                VStack(spacing: stackSpacing) { content }
            }
        }
    }

    private func quickActionsSection(width: CGFloat) -> some View {
        let isLarge = Responsive.isLargeScreen(width: width)
        let featureFlagService = FeatureFlagService.shared
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(AroosiTypography.heading(.h3))

            Group {
                NavigationLink {
                    SearchView(user: user)
                } label: {
                    ActionCard(title: "Discover Profiles",
                               subtitle: "Search by interests",
                               systemImage: "magnifyingglass")
                }

                NavigationLink {
                    MatchesView(user: user)
                } label: {
                    ActionCard(title: "View Matches",
                               subtitle: "Continue conversations",
                               systemImage: "heart")
                }

                NavigationLink {
                    CulturalMatchingView(user: user)
                } label: {
                    ActionCard(title: "Cultural Matches",
                               subtitle: "Shared values & traditions",
                               systemImage: "globe.asia.australia")
                }

                // Only show Icebreakers if feature flag is enabled
                if featureFlagService.isEnabled("ENABLE_ICEBREAKERS") {
                    NavigationLink {
                        IcebreakersView(user: user)
                    } label: {
                        ActionCard(title: "Daily Icebreakers",
                                   subtitle: "Share thoughtful answers",
                                   systemImage: "text.bubble")
                    }
                }
            }
            .modifier(AdaptiveStackModifier(isHorizontal: isLarge, spacing: 12))
        }
    }

    private func recentMatchesSection(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Matches")
                    .font(AroosiTypography.heading(.h3))
                Spacer()
                NavigationLink("See All") {
                    MatchesView(user: user)
                }
                .font(AroosiTypography.caption(weight: .semibold))
            }

            if viewModel.state.recentMatches.isEmpty {
                Text("No matches yet. We'll notify you when someone connects!")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.state.recentMatches) { item in
                        NavigationLink {
                            ChatView(currentUser: user,
                                     item: item,
                                     onUnreadCountReset: { viewModel.refresh() })
                        } label: {
                            MatchRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func quickPicksSection(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Picks")
                    .font(AroosiTypography.heading(.h3))
                Spacer()
                NavigationLink("See All") {
                    QuickPicksView(user: user)
                }
                .font(AroosiTypography.caption(weight: .semibold))
            }

            if viewModel.state.quickPicks.isEmpty {
                Text("We are preparing new introductions for you. Check back soon.")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.state.quickPicks) { profile in
                            QuickPickCard(profile: profile,
                                          isSending: viewModel.state.isSendingInterest(for: profile.id),
                                          isSent: viewModel.state.hasSentInterest(to: profile.id),
                                          onSendInterest: { viewModel.sendInterest(to: profile) })
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var loadingOverlay: some View {
        Group {
            if viewModel.state.isLoading {
                AroosiLoadingView(size: 40, color: AroosiColors.primary)
                    .padding()
            } else if let info = viewModel.state.infoMessage {
                Text(info)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

@available(iOS 17, *)
private extension DashboardView {
    func handlePendingRoute() {
        guard let route = coordinator.consumePendingRoute(for: .dashboard) else { return }
        guard case let .dashboard(destination) = route else { return }

        switch destination {
        case .recentMatches:
            coordinator.navigate(to: .matches)
        default:
            dashboardRoute = destination
        }
    }
}

@available(iOS 17, *)
private struct StatCard: View {
    let title: String
    let value: Int
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                Spacer()
            }

            Text("\(value)")
                .font(AroosiTypography.heading(.h2))

            Text(title)
                .font(AroosiTypography.caption())
                .foregroundStyle(AroosiColors.muted)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 17, *)
private struct ActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(AroosiColors.primary)
            Text(title)
                .font(AroosiTypography.body(weight: .semibold, size: 16))
                .foregroundStyle(AroosiColors.text)
            Text(subtitle)
                .font(AroosiTypography.caption())
                .foregroundStyle(AroosiColors.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .foregroundStyle(AroosiColors.text)
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 17, *)
private struct MatchRow: View {
    let item: MatchesViewModel.MatchListItem

    var body: some View {
        HStack(spacing: 16) {
            avatar
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.counterpartProfile?.displayName.nonEmpty ?? "Match")
                    .font(AroosiTypography.heading(.h3))
                if let preview = item.lastMessagePreview, !preview.isEmpty {
                    Text(preview)
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(item.lastUpdatedAt.relativeDescription())
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)

                if item.unreadCount > 0 {
                    Text("\(item.unreadCount)")
                        .font(.caption2.weight(.semibold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(AroosiColors.primary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var avatar: some View {
        Group {
            if let url = item.counterpartProfile?.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        AroosiAsset.avatarPlaceholder
                            .resizable()
                            .scaledToFill()
                    @unknown default:
                        AroosiAsset.avatarPlaceholder
                            .resizable()
                            .scaledToFill()
                    }
                }
            } else {
                AroosiAsset.avatarPlaceholder
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color(.separator), lineWidth: 1)
        }
    }
}

@available(iOS 17, *)
private struct QuickPickCard: View {
    let profile: ProfileSummary
    let isSending: Bool
    let isSent: Bool
    let onSendInterest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            avatar
                .frame(width: 72, height: 72)

            Text(profile.displayName)
                .font(AroosiTypography.body(weight: .semibold, size: 16))
                .lineLimit(1)

            if let location = profile.location?.nonEmpty {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }

            if !profile.interests.isEmpty {
                Text(profile.interests.prefix(3).joined(separator: ", "))
                    .font(AroosiTypography.caption(weight: .medium))
                    .foregroundStyle(AroosiColors.muted)
                    .lineLimit(2)
            }

            Button(action: onSendInterest) {
                if isSending {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if isSent {
                    Label("Interest Sent", systemImage: "checkmark.seal.fill")
                        .font(AroosiTypography.caption(weight: .semibold))
                } else {
                    Label("Send Interest", systemImage: "heart")
                        .font(AroosiTypography.caption(weight: .semibold))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AroosiColors.primary)
            .disabled(isSending || isSent)
        }
        .padding()
        .frame(width: 200, alignment: .leading)
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var avatar: some View {
        Group {
            if let url = profile.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        AroosiAsset.avatarPlaceholder
                            .resizable()
                            .scaledToFill()
                    @unknown default:
                        AroosiAsset.avatarPlaceholder
                            .resizable()
                            .scaledToFill()
                    }
                }
            } else {
                AroosiAsset.avatarPlaceholder
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color(.separator), lineWidth: 1)
        }
    }
}

@available(iOS 17, *)
private struct InfoBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AroosiColors.success)
            Text(message)
                .font(AroosiTypography.caption())
                .foregroundStyle(AroosiColors.text)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AroosiColors.muted)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(AroosiColors.success.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AdaptiveStackModifier: ViewModifier {
    let isHorizontal: Bool
    let spacing: CGFloat

    func body(content: Content) -> some View {
        Group {
            if isHorizontal {
                HStack(spacing: spacing) { content }
            } else {
                VStack(spacing: spacing) { content }
            }
        }
    }
}

#endif
