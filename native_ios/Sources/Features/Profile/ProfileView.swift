#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct ProfileView: View {
    let user: UserProfile
    @StateObject private var viewModel: ProfileViewModel
    @State private var isPresentingEdit = false
    @State private var showLogoutConfirmation = false
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @EnvironmentObject private var authService: AuthenticationService
    @State private var activeRoute: NavigationCoordinator.ProfileRoute?

    @MainActor
    init(user: UserProfile, viewModel: ProfileViewModel? = nil) {
        self.user = user
        let resolvedViewModel = viewModel ?? ProfileViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
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
        .onAppear { handlePendingRoute() }
        .onChange(of: coordinator.pendingRoute) { _ in
            handlePendingRoute()
        }
        .sheet(isPresented: $isPresentingEdit) {
            if let profile = viewModel.state.profile {
                EditProfileView(userID: user.id, profile: profile) {
                    viewModel.refresh()
                }
                .presentationDetents([.large])
            }
        }
        .sheet(isPresented: $viewModel.state.showingMediaUpload) {
            MediaUploadView(uploadedMediaURLs: $viewModel.state.profileMediaURLs)
                .presentationDetents([.medium, .large])
        }
        .navigationDestination(item: $activeRoute) { destination in
            switch destination {
            case .favorites:
                FavoritesView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .shortlist:
                ShortlistView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .culturalProfile:
                CulturalMatchingView(user: user)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .familyApproval:
                FamilyApprovalView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .editProfile:
                EmptyView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ScrollView {
                VStack(spacing: Responsive.spacing(width: width, multiplier: 1.0)) {
                    header
                    detailsSection
                    savedListsSection
                    logoutSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Responsive.screenPadding(width: width))
            }
            .background(AroosiColors.background)
            .refreshable { viewModel.refresh() }
            .overlay(alignment: .center) {
                if viewModel.state.isLoading && !viewModel.state.hasContent {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AroosiColors.primary)
                }
            }
            .overlay(alignment: .center) {
                if let error = viewModel.state.errorMessage, !viewModel.state.hasContent {
                    errorView(message: error)
                }
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if let profile = viewModel.state.profile {
            VStack(spacing: 0) {
                // Gradient Header Card
                ZStack(alignment: .top) {
                    // Gradient Background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AroosiColors.primary.opacity(0.3),
                            AroosiColors.primary.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    
                    // Content
                    VStack(spacing: 16) {
                        avatar(for: profile)
                            .padding(.top, 24)

                        VStack(spacing: 6) {
                            Text(profile.displayName.isEmpty ? user.displayName : profile.displayName)
                                .font(AroosiTypography.heading(.h2))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            if let email = user.email, !email.isEmpty {
                                Text(email)
                                    .font(AroosiTypography.body())
                                    .foregroundStyle(AroosiColors.muted)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
                
                // Quick Actions
                quickActionsSection
                    .padding(.top, 16)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 12) {
                avatarPlaceholder
                Text(user.displayName)
                    .font(AroosiTypography.heading(.h2))
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "pencil",
                label: "Edit profile",
                action: { isPresentingEdit = true }
            )
            
            QuickActionButton(
                icon: "lock.shield",
                label: "Privacy",
                action: { /* Navigate to privacy settings */ }
            )
            
            QuickActionButton(
                icon: "questionmark.circle",
                label: "Support",
                action: { /* Navigate to support */ }
            )
        }
    }

    @ViewBuilder
    private var detailsSection: some View {
        if let profile = viewModel.state.profile {
            VStack(spacing: 20) {
                if let bio = profile.bio, !bio.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(AroosiTypography.heading(.h3))
                        Text(bio)
                            .font(AroosiTypography.body())
                            .foregroundStyle(AroosiColors.text)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AroosiColors.surfaceSecondary)
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
                .background(AroosiColors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        } else if viewModel.state.isLoading {
            EmptyView()
        } else {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.exclam")
                    .font(.system(size: 40))
                    .foregroundStyle(AroosiColors.primary)
                Text("We couldn't find your profile yet.")
                    .font(AroosiTypography.heading(.h3))
                Text("Pull to refresh or try again later.")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
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

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AroosiColors.primary)
                .frame(width: 24, height: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AroosiTypography.caption(weight: .medium))
                    .foregroundStyle(AroosiColors.muted)
                Text(value)
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.text)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var savedListsSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                FavoritesView()
            } label: {
                listRow(icon: "heart.fill", title: "Favorites", subtitle: "Profiles you've saved")
            }
            .buttonStyle(.plain)

            NavigationLink {
                ShortlistView()
            } label: {
                listRow(icon: "bookmark", title: "Shortlist", subtitle: "Profiles with personal notes")
            }
            .buttonStyle(.plain)

            NavigationLink {
                CulturalMatchingView(user: user)
            } label: {
                listRow(icon: "globe.asia.australia", title: "Cultural Matches", subtitle: "Shared values & traditions")
            }
            .buttonStyle(.plain)
            
            NavigationLink {
                FamilyApprovalView()
            } label: {
                listRow(icon: "person.2.fill", title: "Family Approval", subtitle: "Get your family's input on matches")
            }
            .buttonStyle(.plain)

            NavigationLink {
                IcebreakersView(user: user)
            } label: {
                listRow(icon: "text.bubble", title: "Daily Icebreakers", subtitle: "Update your conversation starters")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func listRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AroosiColors.primary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AroosiTypography.heading(.h3))
                Text(subtitle)
                    .font(AroosiTypography.body(weight: .regular, size: 15))
                    .foregroundStyle(AroosiColors.muted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(AroosiColors.warning)
            Text("Profile Unavailable")
                .font(AroosiTypography.heading(.h3))
            Text(message)
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding()
    }
    
    @ViewBuilder
    private var logoutSection: some View {
        Button(action: {
            showLogoutConfirmation = true
        }) {
            Text("Log out")
                .font(AroosiTypography.body(weight: .semibold, size: 16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AroosiColors.error)
                .cornerRadius(12)
        }
        .padding(.top, 8)
        .confirmationDialog("Are you sure you want to log out?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Log out", role: .destructive) {
                performLogout()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func performLogout() {
        do {
            try authService.signOut()
            // Navigation will be handled by auth state change
        } catch {
            // Show error alert if needed
        }
    }
}

// MARK: - Quick Action Button

@available(iOS 17.0.0, *)
private struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(AroosiTypography.caption(weight: .semibold))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AroosiColors.borderPrimary, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

@available(iOS 17, *)
private extension ProfileView {
    func handlePendingRoute() {
        guard let route = coordinator.consumePendingRoute(for: .profile) else { return }
        guard case let .profile(destination) = route else { return }

        switch destination {
        case .editProfile:
            isPresentingEdit = true
        case .favorites, .shortlist, .culturalProfile, .familyApproval:
            activeRoute = destination
        }
    }
}

#Preview {
    if #available(iOS 17, *) {
        ProfileView(user: UserProfile(id: "user-1", displayName: "Aisha", email: "aisha@example.com", avatarURL: nil))
        .environmentObject(NavigationCoordinator())
    }
}
#endif
