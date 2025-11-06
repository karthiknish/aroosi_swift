import Combine
import Foundation

#if os(iOS)
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@available(iOS 17, *)
@MainActor
final class RootViewModel: ObservableObject {
    struct Capabilities: Equatable {
        var canAccessAdmin: Bool
    }

    struct Session: Equatable {
        var user: UserProfile
        var capabilities: Capabilities
    }

    enum State {
        case loading
        case signedOut
        case signedIn(Session)
    }

    @Published private(set) var state: State = .loading

    private let authService: AuthProviding
    private let featureFlags: FeatureFlagService

#if canImport(FirebaseAuth)
    private var authStateListener: AuthStateDidChangeListenerHandle?
#endif

    init(authService: AuthProviding = FirebaseAuthService.shared,
         featureFlags: FeatureFlagService = .shared) {
        self.authService = authService
        self.featureFlags = featureFlags
    }

    func bootstrap() async {
        do {
            let current = try await authService.currentUser()
            await updateState(with: current)
        } catch {
            Logger.shared.error("Failed to load auth state: \(error.localizedDescription)")
            await updateState(with: nil)
        }

        registerAuthStateListenerIfNeeded()
    }

    func handleOnboardingComplete() {
        Task {
            await bootstrap()
        }
    }

    deinit {
#if canImport(FirebaseAuth)
        if let authStateListener {
            Auth.auth().removeStateDidChangeListener(authStateListener)
        }
#endif
    }

    private func registerAuthStateListenerIfNeeded() {
#if canImport(FirebaseAuth)
#if canImport(FirebaseCore)
        guard FirebaseApp.app() != nil else { return }
#endif
        guard authStateListener == nil else { return }

        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let current = try await self.authService.currentUser()
                    await self.updateState(with: current)
                } catch {
                    Logger.shared.error("Auth state listener error: \(error.localizedDescription)")
                    await self.updateState(with: nil)
                }
            }
        }
#endif
    }

    private func updateState(with user: UserProfile?) async {
        if let user {
            featureFlags.setUserID(user.id)
            await featureFlags.refresh()
            state = .signedIn(buildSession(for: user))
        } else {
            featureFlags.setUserID(nil)
            await featureFlags.refresh()
            state = .signedOut
        }
    }

    private func buildSession(for user: UserProfile) -> Session {
        let canAccessAdmin = evaluateAdminAccess(for: user)
        return Session(user: user, capabilities: Capabilities(canAccessAdmin: canAccessAdmin))
    }

    private func evaluateAdminAccess(for user: UserProfile) -> Bool {
        if let email = user.email?.lowercased(), email.hasSuffix("@aroosi.com") {
            return true
        }

        return featureFlags.isEnabled("ENABLE_ADMIN_DASHBOARD")
    }
}

#endif
