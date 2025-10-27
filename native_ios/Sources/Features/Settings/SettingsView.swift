#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct SettingsView: View {
    let user: UserProfile
    @StateObject private var viewModel: SettingsViewModel
    @State private var showSignOutDialog = false
    @State private var showDeleteAccountSheet = false
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @Environment(\.openURL) private var openURL
    @State private var activeRoute: NavigationCoordinator.SettingsRoute?

    @MainActor
    init(user: UserProfile, viewModel: SettingsViewModel? = nil) {
        self.user = user
        let resolvedViewModel = viewModel ?? SettingsViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                accountSection
                preferencesSection
                safetySection
                supportSection
                dangerSection
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.custom(20))
            .scrollContentBackground(.hidden)
            .background(AroosiColors.groupedBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .top) {
                if viewModel.state.errorMessage != nil {
                    errorBanner
                }
            }
            .overlay(alignment: .center) {
                if viewModel.state.isLoading || viewModel.state.isPerformingAccountAction {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .toolbar {
                if viewModel.state.isPersisting || viewModel.state.isPerformingAccountAction {
                    ProgressView()
                }
            }
            .refreshable { viewModel.refresh() }
            .confirmationDialog("Sign out of Aroosi?", isPresented: $showSignOutDialog, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    showSignOutDialog = false
                    Task {
                        let success = await viewModel.signOut()
                        if success {
                            showSignOutDialog = false
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to continue using Aroosi.")
            }
            .sheet(isPresented: $showDeleteAccountSheet) {
                DeleteAccountSheet(
                    isPresented: $showDeleteAccountSheet,
                    isProcessing: viewModel.state.isPerformingAccountAction,
                    errorMessage: viewModel.state.dangerErrorMessage,
                    onConfirm: { password, reason in
                        await viewModel.deleteAccount(password: password, reason: reason)
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .tint(AroosiColors.primary)
        .task {
            viewModel.observe(userID: user.id)
        }
        .onChange(of: showDeleteAccountSheet) { isPresented in
            if !isPresented {
                viewModel.clearDangerError()
            }
        }
        .onAppear { handlePendingRoute() }
        .onChange(of: coordinator.pendingRoute) { _ in
            handlePendingRoute()
        }
        .navigationDestination(item: $activeRoute) { destination in
            switch destination {
            case .contactSupport:
                SupportCenterView(user: user)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .blockedUsers:
                BlockedUsersView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .privacy:
                DataUsagePolicyView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .appInfo:
                AppStoreInfoView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            HStack {
                Text("Name")
                Spacer()
                Text(viewModel.state.profile?.displayName ?? user.displayName)
                    .foregroundStyle(.secondary)
            }

            if let email = user.email, !email.isEmpty {
                HStack {
                    Text("Email")
                    Spacer()
                    Text(email)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            NavigationLink {
                NotificationPreferencesView(userID: user.id)
            } label: {
                HStack {
                    Label("Notification Preferences", systemImage: "bell.fill")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.settings?.pushNotificationsEnabled ?? false },
                set: { viewModel.updatePushNotificationsEnabled($0) }
            )) {
                Text("Push Notifications")
            }
            .disabled(viewModel.state.settings == nil)

            Toggle(isOn: Binding(
                get: { viewModel.state.settings?.emailUpdatesEnabled ?? false },
                set: { viewModel.updateEmailUpdatesEnabled($0) }
            )) {
                Text("Email Updates")
            }
            .disabled(viewModel.state.settings == nil)
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }

    private var supportSection: some View {
        Section("Support & Legal") {
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope.fill")
            }

            NavigationLink {
                if #available(iOS 17, *) {
                    AboutView()
                }
            } label: {
                Label("About Aroosi", systemImage: "info.circle.fill")
            }

            NavigationLink {
                if #available(iOS 17, *) {
                    TermsOfServiceView()
                }
            } label: {
                Label("Terms of Service", systemImage: "doc.text.fill")
            }

            NavigationLink {
                if #available(iOS 17, *) {
                    PrivacyPolicyView()
                }
            } label: {
                Label("Privacy Policy", systemImage: "lock.shield.fill")
            }

            NavigationLink {
                if #available(iOS 17, *) {
                    SafetyGuidelinesView()
                }
            } label: {
                Label("Safety Guidelines", systemImage: "shield.fill")
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }

    private var safetySection: some View {
        Section("Safety") {
            NavigationLink {
                BlockedUsersView()
            } label: {
                Label("Blocked Users", systemImage: "hand.raised")
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }

    private var dangerSection: some View {
        Section("Danger Zone") {
            Button {
                viewModel.clearDangerError()
                showSignOutDialog = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(AroosiColors.warning)
            }
            .disabled(viewModel.state.isPerformingAccountAction)

            Button(role: .destructive) {
                viewModel.clearDangerError()
                showDeleteAccountSheet = true
            } label: {
                Label("Delete Account", systemImage: "trash")
            }
            .disabled(viewModel.state.isPerformingAccountAction)
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }

    private var errorBanner: some View {
        VStack {
            if let message = viewModel.state.errorMessage ?? viewModel.state.dangerErrorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.red.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.top, 8)
                    .onTapGesture {
                        viewModel.clearErrors()
                    }
            }
            Spacer()
        }
    }
}

@available(iOS 17, *)
private extension SettingsView {
    func handlePendingRoute() {
        guard let route = coordinator.consumePendingRoute(for: .settings) else { return }
        guard case let .settings(destination) = route else { return }

        switch destination {
        case .contactSupport, .blockedUsers, .privacy:
            activeRoute = destination
        }
    }
}

#Preview {
    if #available(iOS 17, *) {
        SettingsView(user: UserProfile(id: "user-1", displayName: "Aisha", email: "aisha@example.com", avatarURL: nil))
        .environmentObject(NavigationCoordinator())
    }
}
@available(iOS 17, *)
private struct DeleteAccountSheet: View {
    @Binding var isPresented: Bool
    let isProcessing: Bool
    let errorMessage: String?
    let onConfirm: @MainActor (_ password: String?, _ reason: String?) async -> Bool

    @State private var password: String = ""
    @State private var reason: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Deleting your account will:")
                            .font(AroosiTypography.body(weight: .semibold, size: 16))
                        bullet("Remove your profile, matches, and messages")
                        bullet("Erase all uploaded media")
                    }
                    .padding(.vertical, 4)

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.error)
                            .padding(.vertical, 4)
                    }
                }

                Section("Confirmation") {
                    SecureField("Password (if you signed up with email)", text: $password)
                    TextField("Reason for leaving (optional)", text: $reason, axis: .vertical)
                        .lineLimit(3...5)
                        .textInputAutocapitalization(.sentences)
                    Text("We share feedback with our team to improve Aroosi.")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .disabled(isProcessing)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Delete", role: .destructive) {
                        Task {
                            let success = await onConfirm(password.nilIfEmpty, reason.nilIfEmpty)
                            if success {
                                isPresented = false
                            }
                        }
                    }
                    .disabled(isProcessing)
                }
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(AroosiTypography.caption())
        .foregroundStyle(AroosiColors.muted)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
#endif
