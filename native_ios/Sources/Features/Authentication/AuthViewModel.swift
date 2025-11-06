import Combine
import Foundation
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if os(iOS)

@available(iOS 17, *)
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var signedInUser: UserProfile?
    @Published var profileSummary: ProfileSummary?
    @Published var profileLoadError: String?

    private let authService: AuthProviding
    private let profileRepository: ProfileRepository
    private let logger = Logger.shared

    init(authService: AuthProviding = FirebaseAuthService.shared,
         profileRepository: ProfileRepository = FirestoreProfileRepository()) {
        self.authService = authService
        self.profileRepository = profileRepository
    }

    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true
        errorMessage = nil
        signedInUser = nil
        profileSummary = nil
        profileLoadError = nil

        defer { isLoading = false }

        do {
            let profile = try await authService.signInWithApple(idToken: idToken, nonce: nonce)
            signedInUser = profile
            _ = await loadProfileSummary(for: profile.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func handleError(_ error: Error) {
        errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

#if canImport(AuthenticationServices)
    @available(iOS 17, *)
    func signInWithSystemUI(anchor: ASPresentationAnchor) async {
        isLoading = true
        errorMessage = nil
        signedInUser = nil
        profileSummary = nil
        profileLoadError = nil

        defer { isLoading = false }

        do {
            let profile = try await authService.presentSignIn(from: anchor)
            signedInUser = profile
            _ = await loadProfileSummary(for: profile.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
#endif

    @discardableResult
    private func loadProfileSummary(for userID: String) async -> Bool {
        do {
            let summary = try await profileRepository.fetchProfile(id: userID)
            profileSummary = summary
            profileLoadError = nil
            return true
        } catch RepositoryError.notFound {
            profileSummary = nil
            profileLoadError = nil
            return true
        } catch {
            logger.error("Failed to load profile summary after sign-in: \(error.localizedDescription)")
            profileSummary = nil
            profileLoadError = "We signed you in, but couldn't load your profile yet."
            return false
        }
    }
}

#endif
