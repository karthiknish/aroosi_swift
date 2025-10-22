#if os(iOS)
import SwiftUI

@available(iOS 17, macOS 13, *)
struct MatchesView: View {
    let user: UserProfile
    @StateObject private var viewModel: MatchesViewModel

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    @MainActor
    init(user: UserProfile, viewModel: MatchesViewModel = MatchesViewModel()) {
        self.user = user
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Matches")
                .navigationBarTitleDisplayMode(.large)
        }
        .task(id: user.id) {
            viewModel.observeMatches(for: user.id)
        }
        .onDisappear {
            viewModel.stopObserving()
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
        .refreshable {
            viewModel.refresh()
        }
        .overlay(alignment: .center) {
            if viewModel.state.isLoading && viewModel.state.items.isEmpty {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
    }

    private func unavailableView(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func row(for item: MatchesViewModel.MatchListItem) -> some View {
        NavigationLink {
            ChatView(currentUser: user,
                     item: item,
                     onUnreadCountReset: { viewModel.updateUnreadCount(for: item.id, count: 0) })
        } label: {
            HStack(spacing: 16) {
                avatar(for: item)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title(for: item))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let preview = item.lastMessagePreview, !preview.isEmpty {
                        Text(preview)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(relativeDateString(for: item.lastUpdatedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if item.unreadCount > 0 {
                        Text("\(item.unreadCount)")
                            .font(.caption2.weight(.semibold))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundStyle(Color.accentColor)
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
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                    @unknown default:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
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

#Preview {
    if #available(iOS 17, *) {
        MatchesView(user: UserProfile(id: "user-123", displayName: "Test User", email: nil, avatarURL: nil))
    }
}
#endif
