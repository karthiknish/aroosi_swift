import SwiftUI

#if os(iOS)
@available(iOS 17, *)
struct BlockedUsersView: View {
    @StateObject private var viewModel: SafetyCenterViewModel
    @State private var selectedTab: Tab = .blocked

    enum Tab: String, CaseIterable {
        case blocked = "Blocked Users"
        case reports = "My Reports"
    }

    @MainActor
    init(viewModel: SafetyCenterViewModel? = nil) {
        let resolvedViewModel = viewModel ?? SafetyCenterViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                TabView(selection: $selectedTab) {
                    blockedUsersContent.tag(Tab.blocked)
                    reportsContent.tag(Tab.reports)
                }
            }
            .background(AroosiColors.background)
            .navigationTitle("Safety Center")
            .toolbar { toolbar }
        }
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var blockedUsersContent: some View {
        if viewModel.state.isLoading && viewModel.state.blockedUsers.isEmpty {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AroosiColors.primary)
        } else if let message = viewModel.state.errorMessage, viewModel.state.blockedUsers.isEmpty && !viewModel.state.hasReports {
            VStack(spacing: 16) {
                Text(message)
                    .font(AroosiTypography.body())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AroosiColors.muted)
                Button("Retry") {
                    Task { await viewModel.refresh() }
                }
                .buttonStyle(.borderedProminent)
                .tint(AroosiColors.primary)
            }
            .padding(32)
        } else if viewModel.state.blockedUsers.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "hand.raised")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(AroosiColors.primary)
                Text("No blocked users")
                    .font(AroosiTypography.heading(.h3))
                Text("You haven't blocked anyone yet.")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            List {
                if let message = viewModel.state.errorMessage {
                    Section {
                        Text(message)
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.error)
                    }
                }

                Section {
                    ForEach(viewModel.state.blockedUsers) { user in
                        HStack(spacing: 16) {
                            AvatarView(url: user.avatarURL)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(AroosiTypography.body(weight: .semibold, size: 16))
                                if let date = user.blockedAt {
                                    Text("Blocked on \(date.formatted(date: .abbreviated, time: .omitted))")
                                        .font(AroosiTypography.caption())
                                        .foregroundStyle(AroosiColors.muted)
                                }
                            }

                            Spacer()

                            Button("Unblock") {
                                Task { await viewModel.unblock(user) }
                            }
                            .buttonStyle(.bordered)
                            .tint(AroosiColors.primary)
                            .disabled(viewModel.state.isPerformingAction)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable { await viewModel.refresh() }
        }
    }

    @ViewBuilder
    private var reportsContent: some View {
        if viewModel.state.isLoading && viewModel.state.submittedReports.isEmpty {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AroosiColors.primary)
        } else if let message = viewModel.state.errorMessage, viewModel.state.submittedReports.isEmpty && !viewModel.state.hasBlockedUsers {
            VStack(spacing: 16) {
                Text(message)
                    .font(AroosiTypography.body())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AroosiColors.muted)
                Button("Retry") {
                    Task { await viewModel.refresh() }
                }
                .buttonStyle(.borderedProminent)
                .tint(AroosiColors.primary)
            }
            .padding(32)
        } else if viewModel.state.submittedReports.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(AroosiColors.primary)
                Text("No reports submitted")
                    .font(AroosiTypography.heading(.h3))
                Text("You haven't reported any users yet.")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            List {
                if let message = viewModel.state.errorMessage {
                    Section {
                        Text(message)
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.error)
                    }
                }

                Section {
                    ForEach(viewModel.state.submittedReports) { report in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Report ID: \(report.id)")
                                    .font(AroosiTypography.caption())
                                    .foregroundStyle(AroosiColors.muted)
                                Spacer()
                                Text(report.status.displayName)
                                    .font(AroosiTypography.caption(weight: .semibold))
                                    .foregroundStyle(statusTint(for: report.status))
                            }
                            Text("Reason: \(report.reason)")
                                .font(AroosiTypography.body(weight: .medium))
                            if let details = report.details, !details.isEmpty {
                                Text(details)
                                    .font(AroosiTypography.caption())
                                    .foregroundStyle(AroosiColors.muted)
                            }
                            Text("Submitted: \(report.submittedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(AroosiTypography.caption())
                                .foregroundStyle(AroosiColors.muted)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable { await viewModel.refresh() }
        }
    }

    private func statusTint(for status: ReportStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .reviewed: return .blue
        case .resolved: return .green
        case .dismissed: return .gray
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            toolbarAction
        }
    }

    @ViewBuilder
    private var toolbarAction: some View {
        if viewModel.state.isRefreshing {
            ProgressView()
        } else {
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
}

@available(iOS 17, *)
private struct AvatarView: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AroosiColors.primary)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        Circle()
            .fill(AroosiColors.surfaceSecondary)
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundStyle(AroosiColors.muted)
            }
    }
}
#endif
