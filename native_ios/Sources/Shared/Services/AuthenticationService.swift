import Foundation
import Combine
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if os(iOS)
import AuthenticationServices
#endif

#if canImport(FirebaseAuth)
/// A wrapper around FirebaseAuthService that provides a simpler, observable authentication state
/// for use with SwiftUI views via @EnvironmentObject
@available(iOS 17.0, macOS 10.15, macCatalyst 13.0, *)
public class AuthenticationService: ObservableObject {
    public static let shared = AuthenticationService()
    
    /// Published current user state for SwiftUI observation
    @Published public private(set) var currentUser: AuthUser?
    
    private let firebaseAuth = FirebaseAuthService.shared
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Set up auth state listener
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user.map { AuthUser(uid: $0.uid, email: $0.email) }
        }
        
        // Initialize current user
        if let user = Auth.auth().currentUser {
            currentUser = AuthUser(uid: user.uid, email: user.email)
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Public Methods
    
    #if os(iOS)
    @available(iOS 17, *)
    public func signInWithApple(from anchor: ASPresentationAnchor) async throws -> UserProfile {
        let profile = try await firebaseAuth.presentSignIn(from: anchor)
        return profile
    }
    #endif
    
    public func signInWithApple(idToken: String, nonce: String) async throws {
        let profile = try await firebaseAuth.signInWithApple(idToken: idToken, nonce: nonce)
        currentUser = AuthUser(uid: profile.id, email: profile.email)
    }
    
    public func signOut() {
        do {
            try firebaseAuth.signOut()
            currentUser = nil
        } catch {
            Logger.shared.error("Failed to sign out: \(error)")
        }
    }
    
    public func deleteAccount(password: String? = nil, reason: String? = nil) async throws {
        try await firebaseAuth.deleteAccount(password: password, reason: reason)
        currentUser = nil
    }
}
#else
// Fallback implementation for platforms without Firebase Auth
@available(iOS 17.0, macOS 10.15, macCatalyst 13.0, *)
public class AuthenticationService: ObservableObject {
    public static let shared = AuthenticationService()
    
    @Published public private(set) var currentUser: AuthUser?
    
    private init() {}
    
    public func signInWithApple(idToken: String, nonce: String) async throws {
        throw AuthError.unsupportedPlatform
    }
    
    public func signOut() {
        Logger.shared.info("Sign out called on unsupported platform")
    }
    
    public func deleteAccount() async throws {
        throw AuthError.unsupportedPlatform
    }
}
#endif

/// Get full user profile from repository if needed
#if canImport(FirebaseAuth)
public func getCurrentProfile() async throws -> UserProfile? {
    try await FirebaseAuthService.shared.currentUser()
}
#endif

// MARK: - Auth User Model

/// Simple user model for authentication state
public struct AuthUser {
    public let uid: String
    public let email: String?
    
    public init(uid: String, email: String?) {
        self.uid = uid
        self.email = email
    }
}
