import XCTest
@testable import AroosiKit

@available(iOS 17, *)
@MainActor
final class AuthenticationTests: XCTestCase {
    
    // MARK: - Sign In with Apple Tests
    
    func testSignInWithAppleSuccess() async throws {
        // Given
        let mockAuthService = MockAuthService()
        let mockProfileRepo = MockProfileRepository()
        let authViewModel = AuthViewModel(
            authService: mockAuthService,
            profileRepository: mockProfileRepo
        )
        
        let expectedUser = UserProfile(
            id: "test-user-123",
            displayName: "Test User",
            email: "test@example.com",
            avatarURL: nil
        )
        
        mockAuthService.resultToReturn = .success(expectedUser)
        mockProfileRepo.profileToReturn = ProfileSummary(
            id: expectedUser.id,
            displayName: expectedUser.displayName
        )
        
        // When
        await authViewModel.signInWithApple(idToken: "valid-token", nonce: "valid-nonce")
        
        // Then
        XCTAssertEqual(authViewModel.signedInUser?.id, expectedUser.id)
        XCTAssertEqual(authViewModel.signedInUser?.displayName, expectedUser.displayName)
        XCTAssertNil(authViewModel.errorMessage)
        XCTAssertFalse(authViewModel.isLoading)
    }
    
    func testSignInWithAppleFailure() async throws {
        // Given
        let mockAuthService = MockAuthService()
        let mockProfileRepo = MockProfileRepository()
        let authViewModel = AuthViewModel(
            authService: mockAuthService,
            profileRepository: mockProfileRepo
        )
        
        mockAuthService.resultToReturn = .failure(AuthError.invalidCredentials)
        
        // When
        await authViewModel.signInWithApple(idToken: "invalid-token", nonce: "invalid-nonce")
        
        // Then
        XCTAssertNil(authViewModel.signedInUser)
        XCTAssertNotNil(authViewModel.errorMessage)
        XCTAssertFalse(authViewModel.isLoading)
    }
    
    func testSignInWithAppleProfileLoadFailure() async throws {
        // Given
        let mockAuthService = MockAuthService()
        let mockProfileRepo = MockProfileRepository()
        let authViewModel = AuthViewModel(
            authService: mockAuthService,
            profileRepository: mockProfileRepo
        )
        
        let expectedUser = UserProfile(
            id: "test-user-123",
            displayName: "Test User",
            email: "test@example.com",
            avatarURL: nil
        )
        
        mockAuthService.resultToReturn = .success(expectedUser)
        mockProfileRepo.resultToReturn = .failure(RepositoryError.networkError)
        
        // When
        await authViewModel.signInWithApple(idToken: "valid-token", nonce: "valid-nonce")
        
        // Then
        XCTAssertNil(authViewModel.signedInUser)
        XCTAssertNotNil(authViewModel.profileLoadError)
        XCTAssertFalse(authViewModel.isLoading)
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOutSuccess() async throws {
        // Given
        let mockAuthService = MockAuthService()
        let mockProfileRepo = MockProfileRepository()
        let authViewModel = AuthViewModel(
            authService: mockAuthService,
            profileRepository: mockProfileRepo
        )
        
        // Set initial signed in state
        let user = UserProfile(id: "test-user", displayName: "Test", email: nil, avatarURL: nil)
        authViewModel.signedInUser = user
        
        // When
        try await authViewModel.signOut()
        
        // Then
        XCTAssertNil(authViewModel.signedInUser)
        XCTAssertNil(authViewModel.profileSummary)
    }
    
    func testSignOutFailure() async throws {
        // Given
        let mockAuthService = MockAuthService()
        mockAuthService.shouldFailSignOut = true
        let authViewModel = AuthViewModel(authService: mockAuthService)
        
        // When & Then
        do {
            try await authViewModel.signOut()
            XCTFail("Expected sign out to throw an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Account Deletion Tests
    
    func testDeleteAccountSuccess() async throws {
        // Given
        let mockAuthService = MockAuthService()
        let authViewModel = AuthViewModel(authService: mockAuthService)
        
        // When
        try await authViewModel.deleteAccount(password: nil, reason: "User request")
        
        // Then
        XCTAssertTrue(mockAuthService.deleteAccountCalled)
    }
    
    func testDeleteAccountFailure() async throws {
        // Given
        let mockAuthService = MockAuthService()
        mockAuthService.shouldFailDeleteAccount = true
        let authViewModel = AuthViewModel(authService: mockAuthService)
        
        // When & Then
        do {
            try await authViewModel.deleteAccount(password: nil, reason: "User request")
            XCTFail("Expected delete account to throw an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Session Management Tests
    
    func testCurrentUserSession() async throws {
        // Given
        let mockAuthService = MockAuthService()
        let expectedUser = UserProfile(id: "current-user", displayName: "Current", email: nil, avatarURL: nil)
        mockAuthService.currentUserToReturn = expectedUser
        
        // When
        let currentUser = try await mockAuthService.currentUser()
        
        // Then
        XCTAssertEqual(currentUser?.id, expectedUser.id)
        XCTAssertEqual(currentUser?.displayName, expectedUser.displayName)
    }
    
    func testNoCurrentUserSession() async throws {
        // Given
        let mockAuthService = MockAuthService()
        mockAuthService.currentUserToReturn = nil
        
        // When
        let currentUser = try await mockAuthService.currentUser()
        
        // Then
        XCTAssertNil(currentUser)
    }
}

// MARK: - Mock Classes

private class MockAuthService: AuthProviding {
    enum AuthResult {
        case success(UserProfile)
        case failure(Error)
    }
    
    var resultToReturn: AuthResult = .success(UserProfile(id: "default", displayName: "Default", email: nil, avatarURL: nil))
    var currentUserToReturn: UserProfile?
    var shouldFailSignOut = false
    var shouldFailDeleteAccount = false
    var deleteAccountCalled = false
    
    func currentUser() async throws -> UserProfile? {
        return currentUserToReturn
    }
    
    @available(iOS 13, macOS 10.15, *)
    func presentSignIn(from anchor: ASPresentationAnchor) async throws -> UserProfile {
        switch resultToReturn {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
    
    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile {
        switch resultToReturn {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
    
    func signOut() throws {
        if shouldFailSignOut {
            throw AuthError.signOutFailed
        }
    }
    
    func deleteAccount(password: String?, reason: String?) async throws {
        deleteAccountCalled = true
        if shouldFailDeleteAccount {
            throw AuthError.deleteAccountFailed
        }
    }
}

private class MockProfileRepository: ProfileRepository {
    enum ProfileResult {
        case success(ProfileSummary)
        case failure(Error)
    }
    
    var profileToReturn: ProfileSummary?
    var resultToReturn: ProfileResult = .success(ProfileSummary(id: "default", displayName: "Default"))
    
    func fetchProfile(id: String) async throws -> ProfileSummary {
        switch resultToReturn {
        case .success(let profile):
            return profile
        case .failure(let error):
            throw error
        }
    }
    
    func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
    
    func updateProfile(_ profile: ProfileSummary) async throws {}
    
    func fetchShortlist(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        ProfileSearchPage(items: [], nextCursor: nil)
    }
    
    func toggleShortlist(userID: String) async throws -> ShortlistToggleResult {
        ShortlistToggleResult(action: .added)
    }
    
    func setShortlistNote(userID: String, note: String) async throws {}
    
    func fetchFavorites(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        ProfileSearchPage(items: [], nextCursor: nil)
    }
    
    func toggleFavorite(userID: String) async throws {}
}

private enum AuthError: Error {
    case invalidCredentials
    case signOutFailed
    case deleteAccountFailed
}

private enum RepositoryError: Error {
    case networkError
    case notFound
}
