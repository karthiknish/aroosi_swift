#if os(iOS)
import SwiftUI

@available(iOS 17, macOS 13, *)
struct MatchDetailView: View {
    let currentUser: UserProfile
    let item: MatchesViewModel.MatchListItem

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                destinationContent
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
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
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text(title)
                .font(.title2.weight(.semibold))

            if let counterpart = item.counterpartProfile {
                profileMetadata(for: counterpart)
            } else {
                Text("We will add more details once this profile is available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private var destinationContent: some View {
        if let conversationID = item.match.conversationID {
            chatPlaceholder(conversationID: conversationID)
        } else if let profile = item.counterpartProfile {
            profileDetail(profile)
        } else {
            Text("Stay tuned for more information about this match.")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func chatPlaceholder(conversationID: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Chat Coming Soon")
                .font(.headline)

            Text("We are wiring up conversations for \(title).")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label("Conversation", systemImage: "bubble.left.and.bubble.right")
                    .font(.subheadline.weight(.medium))

                Text(conversationID)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func profileDetail(_ profile: ProfileSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile Snapshot")
                .font(.headline)

            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
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
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let lastActive = profile.lastActiveAt {
                Text("Last active \(lastActive.relativeDescription())")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func gridRow(symbol: String, title: String, value: String) -> some View {
        GridRow {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.medium))
            Text(value)
                .font(.body)
                .foregroundStyle(.secondary)
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
        MatchDetailView(currentUser: UserProfile(id: "user-1", displayName: "You", email: nil, avatarURL: nil), item: item)
    }
}
#endif
