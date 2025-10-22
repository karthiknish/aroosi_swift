import Foundation
import Combine

@available(macOS 12.0, iOS 17, *)
@MainActor
final class RootViewModel: ObservableObject {
    enum State {
        case loading
        case signedOut
        case signedIn(UserProfile)
    }

    @Published private(set) var state: State = .loading

    private let authService: AuthProviding

    init(authService: AuthProviding = FirebaseAuthService.shared) {
        self.authService = authService
    }

    func bootstrap() async {
        do {
            if let user = try await authService.currentUser() {
                state = .signedIn(user)
            } else {
                state = .signedOut
            }
        } catch {
            Logger.shared.error("Failed to load auth state: \(error.localizedDescription)")
            state = .signedOut
        }
    }

    func handleOnboardingComplete() {
        Task {
            await bootstrap()
        }
    }
}
