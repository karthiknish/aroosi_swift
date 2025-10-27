import SwiftUI

#if os(iOS)
@available(iOS 17, *)
struct BlockedUsersView: View {
    @StateObject private var viewModel: SafetyCenterViewModel

    @MainActor
    init(viewModel: SafetyCenterViewModel? = nil) {
        let resolvedViewModel = viewModel ?? SafetyCenterViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .background(AroosiColors.background)
                .navigationTitle("Blocked Users")
                .toolbar { toolbar }
        }
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading && viewModel.state.blockedUsers.isEmpty {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AroosiColors.primary)
        } else if let message = viewModel.state.errorMessage, viewModel.state.blockedUsers.isEmpty {
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
        } else {
            List {
                if let message = viewModel.state.errorMessage {
                    Section {
                        Text(message)
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.error)
                    }
                }

                if viewModel.state.blockedUsers.isEmpty {
                    Section {
                        VStack(alignment: .center, spacing: 12) {
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
                    }
                } else {
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
            }
            .listStyle(.insetGrouped)
            .refreshable { await viewModel.refresh() }
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
