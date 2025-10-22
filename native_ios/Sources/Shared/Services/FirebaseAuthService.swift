import Foundation
import FirebaseAuth

#if os(iOS)
import AuthenticationServices
#endif

public final class FirebaseAuthService: AuthProviding {
    public static let shared = FirebaseAuthService()

#if os(iOS)
    @available(iOS 17, *)
    private lazy var appleSignInCoordinator = AppleSignInCoordinator(authService: self)
#endif

    private init() {}

    public func currentUser() async throws -> UserProfile? {
        guard let user = Auth.auth().currentUser else {
            return nil
        }
        return makeProfile(from: user)
    }

#if os(iOS)
    @available(iOS 17, *)
    public func presentSignIn(from anchor: ASPresentationAnchor) async throws -> UserProfile {
        try await appleSignInCoordinator.signIn(from: anchor)
    }
#endif

    public func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile {
        do {
            let credential = OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: nonce, fullName: nil)
            let authResult = try await Auth.auth().signIn(with: credential)
            return makeProfile(from: authResult.user)
        } catch {
            throw mapError(error)
        }
    }

    private func makeProfile(from user: FirebaseAuth.User) -> UserProfile {
        let displayName: String
        if let name = user.displayName, !name.isEmpty {
            displayName = name
        } else if let email = user.email, let prefix = email.split(separator: "@").first {
            displayName = String(prefix)
        } else {
            displayName = "Member"
        }

        return UserProfile(
            id: user.uid,
            displayName: displayName,
            email: user.email,
            avatarURL: user.photoURL
        )
    }

    private func mapError(_ error: Error) -> Error {
        let nsError = error as NSError
        let authError = AuthErrorCode(_nsError: nsError)

        switch authError.code {
        case .invalidCredential, .invalidUserToken, .invalidCustomToken:
            return AuthError.invalidCredential
        case .userDisabled:
            return AuthError.accountDisabled
        case .userNotFound:
            return AuthError.userNotFound
        case .networkError:
            return AuthError.networkFailure
        default:
            return error
        }
    }
}

extension FirebaseAuthService {
    public enum AuthError: LocalizedError {
        case invalidCredential
        case accountDisabled
        case userNotFound
        case networkFailure

        public var errorDescription: String? {
            switch self {
            case .invalidCredential:
                return "The provided Apple credential was rejected. Please try again."
            case .accountDisabled:
                return "This account has been disabled. Contact support for assistance."
            case .userNotFound:
                return "We couldn't find an account linked to this Apple ID."
            case .networkFailure:
                return "We couldn't reach the server. Check your connection and try again."
            }
        }
    }
}
