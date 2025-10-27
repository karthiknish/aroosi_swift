#if os(iOS)
import AuthenticationServices
import Foundation

@available(iOS 17, *)
final class AppleSignInCoordinator: NSObject {
    private enum CoordinatorError: LocalizedError {
        case signInInProgress
        case missingPresentationAnchor
        case missingNonce
        case missingIdentityToken
        case invalidCredential

        var errorDescription: String? {
            switch self {
            case .signInInProgress:
                return "A sign-in request is already in progress."
            case .missingPresentationAnchor:
                return "Unable to locate a presentation window for Sign in with Apple."
            case .missingNonce:
                return "Unable to verify the request nonce. Please try again."
            case .missingIdentityToken:
                return "Apple did not provide an identity token."
            case .invalidCredential:
                return "We couldn't validate the Apple credential."
            }
        }
    }

    private let authService: AuthProviding
    private var continuation: CheckedContinuation<UserProfile, Error>?
    private var currentNonce: String?
    private weak var presentationAnchor: ASPresentationAnchor?
    private var authorizationController: ASAuthorizationController?

    init(authService: AuthProviding) {
        self.authService = authService
    }

    func signIn(from anchor: ASPresentationAnchor) async throws -> UserProfile {
        if continuation != nil {
            throw CoordinatorError.signInInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.presentationAnchor = anchor

            let request = ASAuthorizationAppleIDProvider().createRequest()
            
            do {
                let nonce = try AppleSignInNonce.random()
                self.currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = AppleSignInNonce.sha256(nonce)

                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = self
                controller.presentationContextProvider = self
                self.authorizationController = controller
                controller.performRequests()
            } catch {
                // If nonce generation fails, propagate the error
                continuation.resume(throwing: error)
                self.continuation = nil
            }
        }
    }

    private func finish(with result: Result<UserProfile, Error>) {
        guard let continuation = continuation else { return }
        self.continuation = nil
        self.currentNonce = nil
        self.presentationAnchor = nil
        self.authorizationController = nil

        switch result {
        case .success(let profile):
            continuation.resume(returning: profile)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(with: .failure(CoordinatorError.invalidCredential))
            return
        }

        guard let nonce = currentNonce else {
            finish(with: .failure(CoordinatorError.missingNonce))
            return
        }

        guard let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            finish(with: .failure(CoordinatorError.missingIdentityToken))
            return
        }

        Task {
            do {
                let profile = try await authService.signInWithApple(idToken: token, nonce: nonce)
                finish(with: .success(profile))
            } catch {
                finish(with: .failure(error))
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        finish(with: .failure(error))
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let anchor = presentationAnchor else {
            finish(with: .failure(CoordinatorError.missingPresentationAnchor))
            return ASPresentationAnchor()
        }
        return anchor
    }
}
#endif
