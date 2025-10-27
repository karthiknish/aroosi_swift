#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct FavoritesView: View {
    @StateObject private var viewModel: FavoritesViewModel

    @MainActor
    init(viewModel: FavoritesViewModel? = nil) {
        let resolvedViewModel = viewModel ?? FavoritesViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Favorites")
                .toolbar { refreshToolbar }
        }
        .tint(AroosiColors.primary)
        .task { viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading && viewModel.state.items.isEmpty {
            ProgressView("Loading favorites…")
                .progressViewStyle(.circular)
                .tint(AroosiColors.primary)
        } else if let error = viewModel.state.errorMessage, viewModel.state.items.isEmpty {
            VStack(spacing: 12) {
                Text(error)
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.text)
                    .multilineTextAlignment(.center)
                Button("Retry") { viewModel.refresh() }
                    .buttonStyle(.borderedProminent)
                    .tint(AroosiColors.primary)
            }
            .padding()
        } else if viewModel.state.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "heart.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(AroosiColors.muted)
                Text("You haven't added any favorites yet.")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
            }
            .padding()
        } else {
            List {
                ForEach(viewModel.state.items) { profile in
                    NavigationLink {
                        ProfileSummaryDetailView(profileID: profile.id)
                    } label: {
                        ProfileRow(profile: profile)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await viewModel.toggleFavorite(userID: profile.id) }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }

                if viewModel.state.nextCursor != nil {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AroosiColors.primary)
                        Spacer()
                    }
                    .task { viewModel.loadMore() }
                }
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 64)
            .scrollContentBackground(.hidden)
            .background(AroosiColors.background)
            .refreshable { viewModel.refresh() }
        }
    }

    private var refreshToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if viewModel.state.isLoading {
                ProgressView()
                    .tint(AroosiColors.primary)
            } else {
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

@available(iOS 17, *)
private struct ProfileRow: View {
    let profile: ProfileSummary

    var body: some View {
        HStack(spacing: 16) {
            avatar
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(AroosiTypography.body(weight: .semibold, size: 17))
                    .foregroundStyle(AroosiColors.text)
                if let location = profile.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var avatar: some View {
        Group {
            if let url = profile.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(AroosiColors.primary)
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
        .frame(width: 48, height: 48)
        .clipShape(Circle())
        .overlay { Circle().stroke(Color(.separator), lineWidth: 1) }
    }
}
#endif
