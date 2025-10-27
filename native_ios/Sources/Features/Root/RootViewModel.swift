import Foundation
import Combine

#if canImport(FirebaseAuth)
import FirebaseAuth
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#endif

@available(iOS 17, *)
@MainActor
final class RootViewModel: ObservableObject {
    enum State {
        case loading
        case signedOut
        case signedIn(UserProfile)
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
            if let user = try await authService.currentUser() {
                state = .signedIn(user)
                featureFlags.setUserID(user.id)
            } else {
                state = .signedOut
                featureFlags.setUserID(nil)
            }
        } catch {
            Logger.shared.error("Failed to load auth state: \(error.localizedDescription)")
            state = .signedOut
        }

        registerAuthStateListenerIfNeeded()
        await featureFlags.refresh()
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
                    if let user = try await self.authService.currentUser() {
                        self.state = .signedIn(user)
                        self.featureFlags.setUserID(user.id)
                    } else {
                        self.state = .signedOut
                        self.featureFlags.setUserID(nil)
                    }
                    await self.featureFlags.refresh()
                } catch {
                    Logger.shared.error("Auth state listener error: \(error.localizedDescription)")
                    self.state = .signedOut
                    self.featureFlags.setUserID(nil)
                }
            }
        }
#endif
    }
}
