#if os(iOS)
import AuthenticationServices
import SwiftUI
import UIKit

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AuthViewModel
    @State private var currentNonce: String?
    let onSignedIn: (UserProfile) -> Void

    @MainActor
    init(onSignedIn: @escaping (UserProfile) -> Void,
         viewModel: AuthViewModel = AuthViewModel()) {
        self.onSignedIn = onSignedIn
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Sign in with your Apple ID to continue")
                        .font(.body)
                        .multilineTextAlignment(.center)

                    SignInWithAppleButton(.signIn) { request in
                        configureRequest(request)
                    } onCompletion: { result in
                        handleAuthorization(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .disabled(viewModel.isLoading)

                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }

                if let message = viewModel.errorMessage {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.opacity)
                }

                if let profileError = viewModel.profileLoadError {
                    Text(profileError)
                        .foregroundColor(.orange)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.opacity)
                }

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
        let nonce = AppleSignInNonce.random()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleSignInNonce.sha256(nonce)
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
