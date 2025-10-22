#if os(iOS)
import SwiftUI

@available(iOS 17, macOS 13, *)
struct ProfileView: View {
    let user: UserProfile
    @StateObject private var viewModel: ProfileViewModel

    @MainActor
    init(user: UserProfile, viewModel: ProfileViewModel = ProfileViewModel()) {
        self.user = user
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
        }
        .task(id: user.id) {
            viewModel.observeProfile(for: user.id)
        }
        .onDisappear {
            viewModel.stopObserving()
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                detailsSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { viewModel.refresh() }
        .overlay(alignment: .center) {
            if viewModel.state.isLoading && !viewModel.state.hasContent {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .overlay(alignment: .center) {
            if let error = viewModel.state.errorMessage, !viewModel.state.hasContent {
                errorView(message: error)
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if let profile = viewModel.state.profile {
            VStack(spacing: 16) {
                avatar(for: profile)

                VStack(spacing: 6) {
                    Text(profile.displayName.isEmpty ? user.displayName : profile.displayName)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)

                    if let location = profile.location, !location.isEmpty {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let lastActive = profile.lastActiveAt {
                        Text("Active \(lastActive.relativeDescription())")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 12) {
                avatarPlaceholder
                Text(user.displayName)
                    .font(.title2.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var detailsSection: some View {
        if let profile = viewModel.state.profile {
            VStack(spacing: 20) {
                if let bio = profile.bio, !bio.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        Text(bio)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                VStack(spacing: 0) {
                    if let age = profile.age {
                        infoRow(icon: "calendar", title: "Age", value: "\(age)")
                    }
                    if let location = profile.location, !location.isEmpty {
                        Divider()
                        infoRow(icon: "mappin.and.ellipse", title: "Location", value: location)
                    }
                    if let email = user.email, !email.isEmpty {
                        Divider()
                        infoRow(icon: "envelope", title: "Email", value: email)
                    }
                    if !profile.interests.isEmpty {
                        Divider()
                        infoRow(icon: "star", title: "Interests", value: profile.interests.joined(separator: ", "))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        } else if viewModel.state.isLoading {
            EmptyView()
        } else {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.exclam")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)
                Text("We couldn't find your profile yet.")
                    .font(.headline)
                Text("Pull to refresh or try again later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private func avatar(for profile: ProfileSummary) -> some View {
        avatarImage(url: profile.avatarURL)
            .frame(width: 120, height: 120)
    }

    private var avatarPlaceholder: some View {
        avatarImage(url: user.avatarURL)
            .frame(width: 120, height: 120)
    }

    private func avatarImage(url: URL?) -> some View {
        Group {
            if let url {
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
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color(.separator), lineWidth: 1)
        }
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.orange)
            Text("Profile Unavailable")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding()
    }
}

#Preview {
    if #available(iOS 17, *) {
        ProfileView(user: UserProfile(id: "user-1", displayName: "Aisha", email: "aisha@example.com", avatarURL: nil))
    }
}
#endif
