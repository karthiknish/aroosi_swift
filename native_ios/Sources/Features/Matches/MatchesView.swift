#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct MatchesView: View {
    let user: UserProfile
    @StateObject private var viewModel: MatchesViewModel
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var activeConversation: MatchesViewModel.MatchListItem?
    @State private var pendingRoute: NavigationCoordinator.MatchesRoute?

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    @MainActor
    init(user: UserProfile, viewModel: MatchesViewModel? = nil) {
        self.user = user
        let resolvedViewModel = viewModel ?? MatchesViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Matches")
                .navigationBarTitleDisplayMode(.large)
        }
        .tint(AroosiColors.primary)
        .task(id: user.id) {
            viewModel.observeMatches(for: user.id)
        }
        .onDisappear {
            viewModel.stopObserving()
        }
        .onAppear { handlePendingRoute() }
        .onChange(of: coordinator.pendingRoute) { _ in
            handlePendingRoute()
        }
        .onChange(of: viewModel.state.items) { _ in
            resolvePendingConversationIfNeeded()
        }
        .navigationDestination(item: $activeConversation) { item in
            MatchDetailView(currentUser: user,
                            item: item,
                            onUnreadCountReset: { viewModel.updateUnreadCount(for: item.id, count: 0) })
        }
    }

    @ViewBuilder
    private var content: some View {
        List {
            if let error = viewModel.state.errorMessage {
                unavailableView(
                    title: "Unable to Load",
                    message: error,
                    systemImage: "exclamationmark.triangle"
                )
            } else if viewModel.state.isEmpty {
                unavailableView(
                    title: "No Matches Yet",
                    message: "We will let you know when someone connects with you.",
                    systemImage: "heart"
                )
            } else {
                ForEach(viewModel.state.items) { item in
                    row(for: item)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AroosiColors.background)
        .refreshable {
            viewModel.refresh()
        }
        .overlay(alignment: .center) {
            if viewModel.state.isLoading && viewModel.state.items.isEmpty {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AroosiColors.primary)
            }
        }
    }

    private func unavailableView(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(AroosiColors.primary)

            Text(title)
                .font(AroosiTypography.heading(.h3))
                .multilineTextAlignment(.center)

            Text(message)
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func row(for item: MatchesViewModel.MatchListItem) -> some View {
        NavigationLink {
            MatchDetailView(currentUser: user,
                            item: item,
                            onUnreadCountReset: { viewModel.updateUnreadCount(for: item.id, count: 0) })
        } label: {
            HStack(spacing: 16) {
                avatar(for: item)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title(for: item))
                        .font(AroosiTypography.heading(.h3))
                        .foregroundStyle(AroosiColors.text)

                    if let preview = item.lastMessagePreview, !preview.isEmpty {
                        Text(preview)
                            .font(AroosiTypography.body(weight: .regular, size: 15))
                            .foregroundStyle(AroosiColors.muted)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(relativeDateString(for: item.lastUpdatedAt))
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)

                    if item.unreadCount > 0 {
                        Text("\(item.unreadCount)")
                            .font(.caption2.weight(.semibold))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(AroosiColors.primary.opacity(0.2))
                            .foregroundStyle(AroosiColors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
    }

    private func avatar(for item: MatchesViewModel.MatchListItem) -> some View {
        Group {
            if let url = item.counterpartProfile?.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
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
        .frame(width: 48, height: 48)
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color(.separator), lineWidth: 1)
        }
    }

    private func title(for item: MatchesViewModel.MatchListItem) -> String {
        if let name = item.counterpartProfile?.displayName, !name.isEmpty {
            return name
        }
        return "Match"
    }

    private func relativeDateString(for date: Date) -> String {
        MatchesView.relativeFormatter.localizedString(for: date, relativeTo: .now)
    }
}

@available(iOS 17, *)
private extension MatchesView {
    func handlePendingRoute() {
        guard let route = coordinator.consumePendingRoute(for: .matches) else { return }
        guard case let .matches(destination) = route else { return }

        switch destination {
        case .conversation(let matchID, _):
            if let item = viewModel.state.items.first(where: { $0.id == matchID }) {
                activeConversation = item
                pendingRoute = nil
            } else {
                pendingRoute = destination
                viewModel.refresh()
            }
        case .shortlist:
            coordinator.open(.profile(.shortlist))
        }
    }

    func resolvePendingConversationIfNeeded() {
        guard case let .conversation(matchID, _) = pendingRoute else { return }
        guard let item = viewModel.state.items.first(where: { $0.id == matchID }) else { return }
        activeConversation = item
        pendingRoute = nil
    }
}

#Preview {
    if #available(iOS 17, *) {
        MatchesView(user: UserProfile(id: "user-123", displayName: "Test User", email: nil, avatarURL: nil))
        .environmentObject(NavigationCoordinator())
    }
}
#endif
