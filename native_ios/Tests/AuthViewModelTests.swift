import XCTest

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(AppKit)
import AppKit
#endif
@testable import AroosiKit

@available(macOS 12.0, *)
@MainActor
final class AuthViewModelTests: XCTestCase {
    func testSignInSuccessPublishesUser() async {
        let expectedUser = UserProfile(id: "abc", displayName: "Tester", email: "test@example.com", avatarURL: nil)
        let profileSummary = ProfileSummary(id: expectedUser.id, displayName: "Tester")
        let service = MockAuthService(result: .success(expectedUser))
        let profileRepository = ProfileRepositoryMock(result: .success(profileSummary))
        let viewModel = AuthViewModel(authService: service, profileRepository: profileRepository)

        await viewModel.signInWithApple(idToken: "token", nonce: "nonce")

        XCTAssertEqual(viewModel.signedInUser, expectedUser)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.profileSummary, profileSummary)
        XCTAssertNil(viewModel.profileLoadError)
    }

    func testSignInPropagatesServiceError() async {
        let service = MockAuthService(result: .failure(NSError(domain: "", code: -1)))
        let profileRepository = ProfileRepositoryMock(result: .success(ProfileSummary(id: "abc", displayName: "Tester")))
        let viewModel = AuthViewModel(authService: service, profileRepository: profileRepository)

        await viewModel.signInWithApple(idToken: "token", nonce: "nonce")

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.signedInUser)
        XCTAssertNil(viewModel.profileSummary)
        XCTAssertNil(viewModel.profileLoadError)
    }

    func testSignInSuccessHandlesMissingProfile() async {
        let expectedUser = UserProfile(id: "abc", displayName: "Tester", email: nil, avatarURL: nil)
        let service = MockAuthService(result: .success(expectedUser))
        let profileRepository = ProfileRepositoryMock(result: .notFound)
        let viewModel = AuthViewModel(authService: service, profileRepository: profileRepository)

        await viewModel.signInWithApple(idToken: "token", nonce: "nonce")

        XCTAssertEqual(viewModel.signedInUser, expectedUser)
        XCTAssertNil(viewModel.profileSummary)
        XCTAssertNil(viewModel.profileLoadError)
    }

    func testProfileLoadFailurePreventsCompletion() async {
        let expectedUser = UserProfile(id: "abc", displayName: "Tester", email: nil, avatarURL: nil)
        let service = MockAuthService(result: .success(expectedUser))
        let profileRepository = ProfileRepositoryMock(result: .failure(TestError.failed))
        let viewModel = AuthViewModel(authService: service, profileRepository: profileRepository)

        await viewModel.signInWithApple(idToken: "token", nonce: "nonce")

        XCTAssertNil(viewModel.signedInUser)
        XCTAssertNil(viewModel.profileSummary)
        XCTAssertEqual(viewModel.profileLoadError, "We signed you in, but couldn't load your profile yet.")
    }

    func testSystemUISignInSuccess() async {
#if canImport(AuthenticationServices)
        if #available(iOS 17, macOS 13, *) {
            let expectedUser = UserProfile(id: "abc", displayName: "Tester", email: nil, avatarURL: nil)
            let profileSummary = ProfileSummary(id: expectedUser.id, displayName: "Tester")
            let service = MockAuthService(result: .success(expectedUser))
            let profileRepository = ProfileRepositoryMock(result: .success(profileSummary))
            let viewModel = AuthViewModel(authService: service, profileRepository: profileRepository)

            await viewModel.signInWithSystemUI(anchor: makePresentationAnchor())

            XCTAssertEqual(viewModel.signedInUser, expectedUser)
            XCTAssertEqual(viewModel.profileSummary, profileSummary)
            XCTAssertNil(viewModel.errorMessage)
        }
#endif
    }

    func testSystemUISignInFailureSetsError() async {
#if canImport(AuthenticationServices)
        if #available(iOS 17, macOS 13, *) {
            let service = MockAuthService(result: .failure(TestError.failed))
            let profileRepository = ProfileRepositoryMock(result: .notFound)
            let viewModel = AuthViewModel(authService: service, profileRepository: profileRepository)

            await viewModel.signInWithSystemUI(anchor: makePresentationAnchor())

            XCTAssertNotNil(viewModel.errorMessage)
            XCTAssertNil(viewModel.signedInUser)
        }
#endif
    }
}

private final class MockAuthService: AuthProviding {
    enum Result {
        case success(UserProfile)
        case failure(Error)
    }

    private let result: Result

    init(result: Result) {
        self.result = result
    }

    func currentUser() async throws -> UserProfile? { nil }

    @available(iOS 13, macOS 10.15, *)
    func presentSignIn(from anchor: ASPresentationAnchor) async throws -> UserProfile {
        switch result {
        case let .success(profile):
            return profile
        case let .failure(error):
            throw error
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile {
        switch result {
        case let .success(profile):
            return profile
        case let .failure(error):
            throw error
        }
    }
}

private enum TestError: Error {
    case failed
}

@preconcurrency
private final class ProfileRepositoryMock: ProfileRepository {
    enum Result {
        case success(ProfileSummary)
        case notFound
        case failure(Error)
    }

    private let result: Result

    init(result: Result) {
        self.result = result
    }

    func fetchProfile(id: String) async throws -> ProfileSummary {
        switch result {
        case let .success(profile):
            return profile
        case .notFound:
            throw RepositoryError.notFound
        case let .failure(error):
            throw error
        }
    }

    func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func updateProfile(_ profile: ProfileSummary) async throws {}
}

#if canImport(AuthenticationServices)
@available(iOS 13, macOS 13, *)
private func makePresentationAnchor() -> ASPresentationAnchor {
#if canImport(UIKit)
    return UIWindow()
#elseif canImport(AppKit)
    return NSWindow()
#else
    fatalError("Unsupported platform for ASPresentationAnchor")
#endif
}
#endif
