import SwiftUI

#if os(iOS)
@available(iOS 17, *)
struct SupportCenterView: View {
    @StateObject private var viewModel: SupportCenterViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    init(user: UserProfile, viewModel: SupportCenterViewModel? = nil) {
        if let viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: SupportCenterViewModel(user: user))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                infoSection
                contactSection
                diagnosticsSection
                helpLinksSection
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("We're here to help.")
                    .font(AroosiTypography.body(weight: .semibold, size: 16))
                Text("Send us a message and we'll get back within 24 hours.")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
            .padding(.vertical, 4)

            if let success = viewModel.state.successMessage {
                Banner(message: success, style: .success)
                    .onTapGesture { viewModel.dismissMessages() }
            } else if let error = viewModel.state.errorMessage {
                Banner(message: error, style: .error)
                    .onTapGesture { viewModel.dismissMessages() }
            }
        }
    }

    private var contactSection: some View {
        Section("Details") {
            TextField("Your email (optional)", text: Binding(
                get: { viewModel.state.email },
                set: { viewModel.updateEmail($0) }
            ))
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)

            Picker("Category", selection: Binding(
                get: { viewModel.state.category },
                set: { viewModel.updateCategory($0) }
            )) {
                ForEach(SupportContactRequest.Category.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }

            TextField("Subject (optional)", text: Binding(
                get: { viewModel.state.subject },
                set: { viewModel.updateSubject($0) }
            ))
            .textInputAutocapitalization(.sentences)

            TextEditor(text: Binding(
                get: { viewModel.state.message },
                set: { viewModel.updateMessage($0) }
            ))
            .frame(minHeight: 160)
            .overlay {
                if viewModel.state.message.isEmpty {
                    Text("How can we help?")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var diagnosticsSection: some View {
        Section("Diagnostics") {
            Toggle(isOn: Binding(
                get: { viewModel.state.includeDiagnostics },
                set: { viewModel.updateIncludeDiagnostics($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Include diagnostics")
                    Text("This shares basic app info to resolve your issue faster.")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }

            Button {
                launchMailFallback()
            } label: {
                Label("Email support@aroosi.app", systemImage: "envelope")
            }
        }
    }

    private var helpLinksSection: some View {
        Section("Help Articles") {
            NavigationLink {
                PolicyDetailView(title: "Safety Guidelines", url: URL(string: "https://www.aroosi.app/safety")!)
            } label: {
                Label("Safety Guidelines", systemImage: "hand.raised")
            }

            NavigationLink {
                PolicyDetailView(title: "Privacy Policy", url: URL(string: "https://www.aroosi.app/privacy")!)
            } label: {
                Label("Privacy Policy", systemImage: "shield")
            }

            NavigationLink {
                PolicyDetailView(title: "Terms of Service", url: URL(string: "https://www.aroosi.app/terms")!)
            } label: {
                Label("Terms of Service", systemImage: "doc.plaintext")
            }

            NavigationLink {
                PolicyDetailView(title: "End User License Agreement", url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            } label: {
                Label("End User License Agreement", systemImage: "doc.badge.plus")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            submitButton
        }

        ToolbarItem(placement: .cancellationAction) {
            Button("Close") { dismiss() }
        }
    }

    @ViewBuilder
    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            if viewModel.state.isSubmitting {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            } else {
                Text("Submit")
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(AroosiColors.primary)
        .disabled(viewModel.state.isSubmitting)
    }

    private func launchMailFallback() {
        let subject = viewModel.state.subject.nilIfEmpty ?? "Aroosi Support: \(viewModel.state.category.rawValue)"
        let body = viewModel.state.message.nilIfEmpty ?? ""
        let email = viewModel.state.email.nilIfEmpty ?? ""
        let mailto = "mailto:support@aroosi.app?subject=\(subject.urlEncoded)&body=\(body.urlEncoded)"
            + (email.isEmpty ? "" : "&cc=\(email.urlEncoded)")
        if let url = URL(string: mailto) {
            openURL(url)
        }
    }
}

@available(iOS 17, *)
private struct SupportBanner: View {
    enum Style {
        case success
        case error

        var tint: Color {
            switch self {
            case .success: return AroosiColors.success
            case .error: return AroosiColors.error
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.seal"
            case .error: return "exclamationmark.triangle"
            }
        }
    }

    let message: String
    let style: Style

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.icon)
                .foregroundStyle(style.tint)
                .font(.system(size: 18, weight: .semibold))
            Text(message)
                .font(AroosiTypography.caption())
                .foregroundStyle(AroosiColors.muted)
        }
        .padding()
        .background(style.tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }

    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
#endif
