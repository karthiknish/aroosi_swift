#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct MatchDetailView: View {
    let currentUser: UserProfile
    let item: MatchesViewModel.MatchListItem
    let onUnreadCountReset: () -> Void

    init(currentUser: UserProfile,
         item: MatchesViewModel.MatchListItem,
         onUnreadCountReset: @escaping () -> Void = {}) {
        self.currentUser = currentUser
        self.item = item
        self.onUnreadCountReset = onUnreadCountReset
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                conversationSection
                profileSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(AroosiColors.background)
    }

    private var title: String {
        if let name = item.counterpartProfile?.displayName, !name.isEmpty {
            return name
        }
        return "Match"
    }

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 12) {
            avatarView

            Text(title)
                .font(AroosiTypography.heading(.h2))

            if let counterpart = item.counterpartProfile {
                profileMetadata(for: counterpart)
            } else {
                Text("This profile will appear once connection details sync from the match.")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Label("Conversation", systemImage: "bubble.left.and.bubble.right")
                    .font(AroosiTypography.heading(.h3))
                Spacer()
                Text(item.match.lastUpdatedAt.relativeDescription())
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }

            VStack(alignment: .leading, spacing: 8) {
                if let preview = item.match.lastMessagePreview, !preview.isEmpty {
                    Text(preview)
                        .font(AroosiTypography.body())
                        .foregroundStyle(AroosiColors.text)
                        .lineLimit(2)
                } else {
                    Text("No messages yet. Be the first to say salaam.")
                        .font(AroosiTypography.body())
                        .foregroundStyle(AroosiColors.muted)
                }

                if let conversationID = item.match.conversationID, !conversationID.isEmpty {
                    Text("ID: \(conversationID)")
                        .font(.caption.monospaced())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            NavigationLink {
                ChatView(currentUser: currentUser,
                         item: item,
                         onUnreadCountReset: onUnreadCountReset)
            } label: {
                Label(item.match.conversationID == nil ? "Open Chat & Start Conversation" : "Open Chat",
                      systemImage: "paperplane.fill")
                    .font(.callout.weight(.semibold))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(AroosiColors.primary)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var profileSection: some View {
        if let profile = item.counterpartProfile {
            profileDetail(profile)
        }
    }

    private func profileDetail(_ profile: ProfileSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile Snapshot")
                .font(AroosiTypography.heading(.h3))

            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.text)
            }

            Grid(horizontalSpacing: 16, verticalSpacing: 12) {
                if let age = profile.age {
                    gridRow(symbol: "calendar", title: "Age", value: "\(age)")
                }
                if let location = profile.location, !location.isEmpty {
                    gridRow(symbol: "mappin.and.ellipse", title: "Location", value: location)
                }
                if !profile.interests.isEmpty {
                    gridRow(symbol: "star", title: "Interests", value: profile.interests.joined(separator: ", "))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func profileMetadata(for profile: ProfileSummary) -> some View {
        VStack(spacing: 4) {
            if let location = profile.location, !location.isEmpty {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }

            if let lastActive = profile.lastActiveAt {
                Text("Last active \(lastActive.relativeDescription())")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
        }
    }

    private func gridRow(symbol: String, title: String, value: String) -> some View {
        GridRow {
            Label(title, systemImage: symbol)
                .font(AroosiTypography.body(weight: .semibold, size: 16))
                .foregroundStyle(AroosiColors.text)
            Text(value)
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
        }
    }

    private var avatarView: some View {
        Group {
            if let avatar = item.counterpartProfile?.avatarURL {
                AsyncImage(url: avatar) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "heart.circle.fill")
                            .resizable()
                            .scaledToFit()
                    @unknown default:
                        Image(systemName: "heart.circle.fill")
                            .resizable()
                            .scaledToFit()
                    }
                }
            } else {
                Image(systemName: "heart.circle.fill")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color(.separator), lineWidth: 1)
        }
    }
}

#Preview {
    if #available(iOS 17, *) {
        let summary = ProfileSummary(id: "user-2", displayName: "Nadia", age: 28, location: "San Francisco", bio: "Adventurer", interests: ["Cuisine", "Travel"])
        let match = Match(
            id: "match-1",
            participants: [
                Match.Participant(userID: "user-1", isInitiator: true),
                Match.Participant(userID: "user-2", isInitiator: false)
            ],
            status: .active,
            lastMessagePreview: "Salaam!",
            lastUpdatedAt: .now,
            conversationID: "conversation-1"
        )
        let item = MatchesViewModel.MatchListItem(id: match.id, match: match, counterpartProfile: summary, unreadCount: 3)
        MatchDetailView(currentUser: UserProfile(id: "user-1", displayName: "You", email: nil, avatarURL: nil),
                        item: item,
                        onUnreadCountReset: {})
    }
}
#endif
