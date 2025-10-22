#if os(iOS)
import AuthenticationServices
import SwiftUI
import UIKit

@available(iOS 17, macOS 13, *)
struct OnboardingView: View {
    let onComplete: () -> Void
    @StateObject private var contentViewModel: OnboardingViewModel
    @StateObject private var authViewModel: AuthViewModel

    @MainActor
    init(onComplete: @escaping () -> Void,
         contentViewModel: OnboardingViewModel = OnboardingViewModel(),
         authViewModel: AuthViewModel = AuthViewModel()) {
        self.onComplete = onComplete
        _contentViewModel = StateObject(wrappedValue: contentViewModel)
        _authViewModel = StateObject(wrappedValue: authViewModel)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 32) {
                    heroImage
                        .padding(.top, 64)

                    contentCopy

                    actionButtons
                        .padding(.bottom, 48)
                }
                .padding(.horizontal, 32)
            }
            .background(Color(.systemBackground).ignoresSafeArea())

            if contentViewModel.state.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .task {
            if contentViewModel.state.content == nil && !contentViewModel.state.isLoading {
                contentViewModel.loadContent()
            }
        }
        .onChange(of: authViewModel.signedInUser) { _, user in
            guard user != nil else { return }
            onComplete()
        }
    }

    private var heroImage: some View {
        Group {
            if let url = contentViewModel.state.content?.heroImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image(systemName: "heart.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.accentColor)
                    @unknown default:
                        Image(systemName: "heart.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 280)
            } else if contentViewModel.state.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity)
            } else {
                Image(systemName: "heart.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.accentColor)
                    .frame(height: 160)
            }
        }
    }

    private var contentCopy: some View {
        VStack(spacing: 16) {
            Text(contentViewModel.state.content?.title ?? "Discover curated matches")
                .font(.largeTitle.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(contentViewModel.state.content?.tagline ?? "We are fetching the latest story for you.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let error = contentViewModel.state.errorMessage {
                VStack(spacing: 8) {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        contentViewModel.retry()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 8)
            }

            if let profileError = authViewModel.profileLoadError {
                Text(profileError)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }

            if let authError = authViewModel.errorMessage {
                Text(authError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button {
                Task { await startSystemSignIn() }
            } label: {
                Text(contentViewModel.state.content?.callToActionTitle ?? "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
            }
            .disabled(authViewModel.isLoading || contentViewModel.state.isLoading)

            if authViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
    }

    @MainActor
    private func startSystemSignIn() async {
#if canImport(AuthenticationServices)
        guard let anchor = presentationAnchor() else {
            authViewModel.errorMessage = "We couldn't present Sign in with Apple. Please try again."
            return
        }
        await authViewModel.signInWithSystemUI(anchor: anchor)
#else
        authViewModel.errorMessage = "Sign in with Apple is not supported on this platform."
#endif
    }

    @MainActor
    private func presentationAnchor() -> ASPresentationAnchor? {
#if canImport(UIKit)
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            return window
        }
        return nil
#else
        return nil
#endif
    }
}

#Preview {
    if #available(iOS 17, *) {
        OnboardingView(onComplete: {})
    }
}
#endif
