#if os(iOS)
import AuthenticationServices
import UIKit

@available(iOS 17, *)
public final class SystemSignInPresenter {
    public enum PresentationError: LocalizedError {
        case missingAnchor

        public var errorDescription: String? {
            switch self {
            case .missingAnchor:
                return "We couldn't find a window to present Sign in with Apple."
            }
        }
    }

    private let authService: AuthProviding

    public init(authService: AuthProviding = FirebaseAuthService.shared) {
        self.authService = authService
    }

    public func presentSignIn(from viewController: UIViewController) async throws -> UserProfile {
        guard let anchor = presentationAnchor(from: viewController) else {
            throw PresentationError.missingAnchor
        }
        return try await authService.presentSignIn(from: anchor)
    }

    private func presentationAnchor(from viewController: UIViewController) -> ASPresentationAnchor? {
        if let window = viewController.view.window {
            return window
        }

        if let window = viewController.viewIfLoaded?.window {
            return window
        }

        if let window = viewController.view.windowScene?.keyWindow {
            return window
        }

        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
#endif
