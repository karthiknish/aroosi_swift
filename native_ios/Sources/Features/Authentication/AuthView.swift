#if os(iOS)
import AuthenticationServices
import SwiftUI
import UIKit

@available(iOS 17, *)
struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AuthViewModel
    @ObservedObject private var offlineDataManager = OfflineDataManager.shared
    @State private var currentNonce: String?
    let onSignedIn: (UserProfile) -> Void

    @MainActor
    init(onSignedIn: @escaping (UserProfile) -> Void,
         viewModel: AuthViewModel? = nil) {
        self.onSignedIn = onSignedIn
        let resolvedViewModel = viewModel ?? AuthViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let width = proxy.size.width
                
                ResponsiveVStack(width: width) {
                    Text("Sign in with your Apple ID to continue")
                        .font(.body)
                        .multilineTextAlignment(.center)

                    SignInWithAppleButton(onRequest: { request in
                        configureRequest(request)
                    }, onCompletion: { result in
                        handleAuthorization(result)
                    })
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: Responsive.buttonHeight(for: width))
                    .disabled(viewModel.isLoading || !offlineDataManager.isOnline)

                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.blue)
                    }

                    if !offlineDataManager.isOnline {
                        Text("No internet connection. Please check your network and try again.")
                            .foregroundStyle(Color.orange)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .foregroundStyle(Color.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    if let profileError = viewModel.profileLoadError {
                        Text(profileError)
                            .foregroundStyle(Color.orange)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                }
                .padding(Responsive.screenPadding(width: width))
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sign In")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: viewModel.signedInUser) { _, user in
                guard let profile = user else { return }
                onSignedIn(profile)
                dismiss()
            }
        }
    }

    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        do {
            let nonce = try AppleSignInNonce.random()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = AppleSignInNonce.sha256(nonce)
        } catch {
            // If nonce generation fails, cancel the sign-in attempt
            viewModel.handleError(AuthError.invalidNonce)
            return
        }
    }

    private func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                viewModel.handleError(AuthError.invalidCredential)
                return
            }
            guard let nonce = currentNonce else {
                viewModel.handleError(AuthError.invalidNonce)
                return
            }
            guard let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                viewModel.handleError(AuthError.missingIdentityToken)
                return
            }

            currentNonce = nil
            Task {
                await viewModel.signInWithApple(idToken: token, nonce: nonce)
            }
        case let .failure(error):
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                return
            }
            viewModel.handleError(error)
        }
    }
}

private enum AuthError: LocalizedError {
    case invalidCredential
    case invalidNonce
    case missingIdentityToken

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "We couldn't validate the Apple ID credential."
        case .invalidNonce:
            return "Sign-in nonce was missing. Please try again."
        case .missingIdentityToken:
            return "Apple did not return an identity token."
        }
    }
}

#Preview {
    AuthView { _ in }
}
#endif
