import Foundation

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

public protocol AuthProviding {
    func currentUser() async throws -> UserProfile?
#if canImport(AuthenticationServices)
    @available(iOS 13, macOS 10.15, *)
    func presentSignIn(from anchor: ASPresentationAnchor) async throws -> UserProfile
#endif
    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile
}

public enum AuthProviderError: LocalizedError {
    case unsupportedSignIn

    public var errorDescription: String? {
        "Sign in with Apple is not supported on this platform."
    }
}

public extension AuthProviding {
#if canImport(AuthenticationServices)
    @available(iOS 13, macOS 10.15, *)
    func presentSignIn(from anchor: ASPresentationAnchor) async throws -> UserProfile {
        throw AuthProviderError.unsupportedSignIn
    }
#endif
}
