#if os(iOS)
import AuthenticationServices
import SwiftUI
import UIKit

@available(iOS 17, *)
struct OnboardingView: View {
    let onComplete: () -> Void
    @StateObject private var contentViewModel: OnboardingViewModel
    @StateObject private var authViewModel: AuthViewModel

    @MainActor
    init(onComplete: @escaping () -> Void,
         contentViewModel: OnboardingViewModel? = nil,
         authViewModel: AuthViewModel? = nil) {
        self.onComplete = onComplete
        let resolvedContentViewModel = contentViewModel ?? OnboardingViewModel()
        let resolvedAuthViewModel = authViewModel ?? AuthViewModel()
        _contentViewModel = StateObject(wrappedValue: resolvedContentViewModel)
        _authViewModel = StateObject(wrappedValue: resolvedAuthViewModel)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let isLandscape = Responsive.isLandscape(width: width, height: height)
            let safeArea = proxy.safeAreaInsets
            
            NavigationStack {
                ScrollView {
                    VStack(spacing: Responsive.orientationSpacing(width: width, height: height, multiplier: isLandscape ? 0.8 : 1.0)) {
                        heroImage
                            .padding(.top, isLandscape ? 20 : Responsive.screenPadding(width: width).top)

                        contentCopy

                        actionButtons
                            .padding(.bottom, isLandscape ? 20 : Responsive.screenPadding(width: width).bottom)
                    }
                    .padding(Responsive.safeAreaPadding(width: width, height: height, safeArea: safeArea))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .refreshable {
                    contentViewModel.refresh()
                }
                .background(Color(UIColor.systemBackground).ignoresSafeArea())
                .navigationTitle("")
                .navigationBarHidden(true)
            }
        }
        if contentViewModel.state.isLoading {
            ProgressView()
                .progressViewStyle(.circular)
        }
        .onChange(of: authViewModel.signedInUser) { _, user in
            guard user != nil else { return }
            onComplete()
        }
    }

    private var heroImage: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            VStack(spacing: Responsive.spacing(width: width)) {
                if let imageURL = contentViewModel.state.content?.heroImageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color.blue)
                                .frame(maxWidth: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            AroosiAsset.onboardingHero
                                .resizable()
                                .scaledToFit()
                        @unknown default:
                            AroosiAsset.onboardingHero
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .frame(height: Responsive.mediaHeight(for: width, type: .banner))
                } else if contentViewModel.state.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                } else {
                    AroosiAsset.onboardingHero
                        .resizable()
                        .scaledToFit()
                        .frame(height: Responsive.mediaHeight(for: width, type: .banner))
                }
            }
        }
    }

    private var contentCopy: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            ResponsiveVStack(width: width) {
                Text(contentViewModel.state.content?.title ?? "Discover curated matches")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(contentViewModel.state.content?.tagline ?? "We are fetching the latest story for you.")
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.secondary)

                if let error = contentViewModel.state.errorMessage {
                    ResponsiveVStack(spacing: Responsive.spacing(width: width, multiplier: 0.5), width: width) {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.red)
                            .multilineTextAlignment(.center)
                        ResponsiveButton(
                            title: "Retry",
                            action: { contentViewModel.refresh() },
                            style: .outline,
                            width: width
                        )
                    }
                    .padding(.top, Responsive.spacing(width: width, multiplier: 0.5))
                }

                if let info = contentViewModel.state.infoMessage {
                    Text(info)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, Responsive.spacing(width: width, multiplier: 0.3))
                }

                if let profileError = authViewModel.profileLoadError {
                    Text(profileError)
                        .font(.caption)
                        .foregroundStyle(Color.orange)
                        .multilineTextAlignment(.center)
                }

                if let authError = authViewModel.errorMessage {
                    Text(authError)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button {
                Task { await startSystemSignIn() }
            } label: {
                Text(contentViewModel.state.content?.callToActionTitle ?? "Get Started")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
            }
            .disabled(authViewModel.isLoading || contentViewModel.state.isLoading)

            if authViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.blue)
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
