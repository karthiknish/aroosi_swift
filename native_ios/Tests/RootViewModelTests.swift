import XCTest

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
@testable import AroosiKit

@available(macOS 12.0, *)
@MainActor
final class RootViewModelTests: XCTestCase {
    func testBootstrapWhenUserSignedOut() async {
        let service = MockAuthService()
        let viewModel = RootViewModel(authService: service)

        await viewModel.bootstrap()

        guard case .signedOut = viewModel.state else {
            XCTFail("Expected signedOut state")
            return
        }
    }

    func testBootstrapWhenUserSignedIn() async {
        let service = MockAuthService(mockUser: UserProfile(id: "123", displayName: "Test", email: nil, avatarURL: nil))
        let viewModel = RootViewModel(authService: service)

        await viewModel.bootstrap()

        guard case let .signedIn(user) = viewModel.state else {
            XCTFail("Expected signedIn state")
            return
        }

        XCTAssertEqual(user.id, "123")
    }
}

private final class MockAuthService: AuthProviding {
    private let mockUser: UserProfile?

    init(mockUser: UserProfile? = nil) {
        self.mockUser = mockUser
    }

    func currentUser() async throws -> UserProfile? {
        mockUser
    }

    @available(iOS 13, macOS 10.15, *)
    func presentSignIn(from anchor: ASPresentationAnchor) async throws -> UserProfile {
        guard let user = mockUser else {
            throw NSError(domain: "Auth", code: 0)
        }
        return user
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile {
        guard let user = mockUser else {
            throw NSError(domain: "Auth", code: 0)
        }
        return user
    }
}
