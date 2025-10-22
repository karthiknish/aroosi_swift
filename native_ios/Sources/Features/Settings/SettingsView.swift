#if os(iOS)
import SwiftUI

@available(iOS 17, macOS 13, *)
struct SettingsView: View {
    let user: UserProfile
    @StateObject private var viewModel: SettingsViewModel

    @MainActor
    init(user: UserProfile, viewModel: SettingsViewModel = SettingsViewModel()) {
        self.user = user
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                accountSection
                preferencesSection
                supportSection
            }
            .navigationTitle("Settings")
            .overlay(alignment: .top) {
                if viewModel.state.errorMessage != nil {
                    errorBanner
                }
            }
            .overlay(alignment: .center) {
                if viewModel.state.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .toolbar {
                if viewModel.state.isPersisting {
                    ProgressView()
                }
            }
            .refreshable { viewModel.refresh() }
        }
        .task {
            viewModel.observe(userID: user.id)
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
    }

    private var preferencesSection: some View {
        Section("Preferences") {
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
    }

    private var supportSection: some View {
        Section("Support") {
            if let email = viewModel.state.settings?.supportEmail,
               let url = URL(string: "mailto:\(email)") {
                Link(destination: url) {
                    Label("Email Support", systemImage: "envelope")
                }
            }

            if let phone = viewModel.state.settings?.supportPhoneNumber,
               let url = URL(string: "tel:\(phone)") {
                Link(destination: url) {
                    Label("Call Support", systemImage: "phone")
                }
            }
        }
    }

    private var errorBanner: some View {
        VStack {
            if let message = viewModel.state.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.red.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.top, 8)
            }
            Spacer()
        }
    }
}

#Preview {
    if #available(iOS 17, *) {
        SettingsView(user: UserProfile(id: "user-1", displayName: "Aisha", email: "aisha@example.com", avatarURL: nil))
    }
}
#endif
